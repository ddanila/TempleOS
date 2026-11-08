# Reclaiming fully cached pages from live native task heaps

MemoryRuntime 41 adds an internal `I386MemHeapCollect` operation. It coalesces
cached small-allocation spans, finds page blocks whose complete allocatable body
is free, unlinks those spans and returns their page blocks to the public pool.
Live objects remain at their original addresses. Heap used-byte accounting does
not change; reserved-byte accounting falls by the returned page extents.

The operation masks interrupts, rejects locked heaps/pools, saves page and cache
links before returning a page, and stops reading its header before backing-region
trimming can release the arena allocation. It performs no scratch allocation.
The existing `I386MemHeapTrim` contract is unchanged: that operation still rejects
nonempty heaps.

Public `MemoryFree` and the compiler task-code release callback collect after
freeing a large, independently paged allocation (rounded span at least 1024).
Their existing provider notification then releases empty backing regions. Ordinary
small frees retain their size-bucket caching behavior; this policy does not claim
that no empty cached page can remain after later small frees. Collection is
internal: public heap record layouts, page rounding, allocation capacities and the
73-entry memory export table are unchanged. Compiler/Console interfaces remain
100/258. Only Kernel and MemoryRuntime module bytes change from the preceding
checkpoint.

## Evidence leading to the change

The pre-change stopped snapshot in `build/i386-window-heap-capture-v1` contains
188416 bytes of wholly cached page blocks in root heap `0x2c794c` and 24576 bytes
in compiler-caller heap `0x307c7c`. Two other live heaps have no wholly free block.
The snapshot auditor now accepts repeated `--task-heap ADDRESS` arguments. It
validates each native heap's signature, unlocked state, bidirectional page list,
unique/nonoverlapping cached spans within page bodies, total reserved bytes, and
used + cached + 24 bytes of page/header overhead per block. It identifies fully
cached blocks after address-adjacent coalescing; it does not infer that fragmented
free bytes are movable live allocations. Exact baseline reproduction adds:

```sh
--task-heap 0x2c794c --task-heap 0x307c7c \
--task-heap 0x6f5034 --task-heap 0x701024
```

The extended baseline receipt is
`build/i386-window-heap-capture-v1/census-with-task-heaps.json`. A deliberately
corrupted nested used-byte counter is rejected without writing a success report.

## New 8 MiB frontier

The unchanged 24-case normal public lexer contract now compiles the numeric,
character, punctuation, identifier, define and conditional helpers beyond the
former numeric-emitter failure. It still fails before publishing the lexer API,
now at `PARSER CODE STORAGE REJECT C:/Compiler/I386/PublicLexTokens.HC`.

A second stopped capture, before error cleanup, records a 14880-byte code-storage
request. Emission has completed and live IR has already been released. The
segmented output contains all 14880 bytes in 30 chunks; `planned` has returned to
zero after backend completion. The bootstrap arena has 344000 free span bytes
across 192 blocks, but its largest free span is 11376 bytes. Unlike the preceding
528-free-byte capture, this failure is constrained by contiguity. Making the final
executable contiguous remains necessary; scatterable scratch output alone does
not meet that requirement.

The second capture and its driver are preserved at
`build/i386-cache-collect-heap-capture-v1` and
`build/capture-cache-collect-heap.py`. Its CompilerRuntime hash remains
`cfe84a0cf6156463a154a651eb6a6dbc59c6c36df44a166d3603a761d0d1103b`;
the physical snapshot hash is
`93ec9667655a00fedb3470c191e5f22416f2cf627a2898ed48ed18222645c2d8`.
Reproduce the nested census with:

```sh
python3 tools/audit-i386-heap-snapshot.py \
  build/i386-cache-collect-heap-capture-v1/physical.bin \
  --heap 0x102530 --output-owner 0x7304f8 \
  --task-heap 0x2c83dc --task-heap 0x30870c \
  --task-heap 0x6f6034 --task-heap 0x702024 \
  --report build/i386-cache-collect-heap-capture-v1/census-with-task-heaps.json
```

These captures describe different functions and lifetime boundaries; their used
and free totals are not a controlled same-point measurement of bytes saved. The
second root heap still has 73728 wholly cached bytes, consistent with the policy
of retaining later small frees. The next resource change must address durable
code contiguity without reducing the grammar or contract.

## Validation

`build/i386-cache-collect-source-v1` passes the native guest-source cache suite,
including nine new assertion groups covering partial live heaps, live payloads,
exact page/counter recovery, repeated collection, locked/null rejection and IRQ
preservation. The existing independent merge-order tests still pass. The public
allocator and task-heap suites pass at `build/i386-cache-collect-public-v1` and
`build/i386-cache-collect-task-heaps-v1`. Both original bootstrap generations and
the strict full 64 MiB cross-build pass; artifacts are in `build/rebuild-test` and
`build/i386-cache-collect-cross-v1`. The v2 cross-build pins the revised input
runner; both complete image hashes and all module bytes match v1 exactly. The
normal lexer16 contract passes 24 exact result words with one publication. The
backend passes 48 state words, the original trace and zero caller heap growth;
all 25 diagnostic source-compiler stages retain the preceding semantic records.
Both TCG welcome/diagnostic frames match all 307200 pixels. Both metadata and F64
allocation-fault/unwind/retry phases complete with their warm recovery checks.
The public memory-layout check retains six classes and 43 original x64 fields.
Five inventory guards pass.

Two assembly attempts reached COMMAND OK for the WinMgr-pause command but timed
out on its final raster. The previous setup could suspend the cooperative worker
while a frame held the presentation lease. Both shared input-runner pause sites
now wait for the public SEMA_REFRESH_IN_PROGRESS bit to clear, then suspend with
no intervening yield. The revised setup passes the same packaged assembly fixture
at 8 MiB TCG 486,-fpu: six commands, the 1532-byte assembly block, independent rel32
opcode/displacement checks across offsets 509..513, character immediates and every
pixel checkpoint. The fixture SHA is unchanged; its result is
`build/i386-cache-collect-inline-asm-v3-packaged/result.json`. The v1/v2 failures
remain preserved. This corrects test setup; it does not change public Suspend
semantics or qualify general suspension of a resource-owning worker.

The final receipt is
`build/i386-cache-collect-cross-v2/final-verification-audit.json`. It checks current
source/tool/bootstrap/image/module pins, v1/v2 image equivalence, semantic records,
heap captures and explicit retained failures. Compiler frame evidence carries
forward only because CompilerRuntime is byte-identical. Concurrent functional
startup observations do not qualify the isolated C5 performance gate.

No complete workflow or C1–C5 milestone is newly qualified by this resource
change. The normal 8 MiB compiler remains incomplete; qualification stays 2/686.
