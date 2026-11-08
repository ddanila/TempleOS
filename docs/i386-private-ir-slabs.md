# Private frontend IR storage groups

Compiler ABI 101 groups private frontend instruction storage while preserving
public `I386ICAdd` allocations and every instruction field offset. The private
node prefix remains 108 bytes and each node retains its 20-byte code-lifetime
record. A slot is 128 bytes. A separate 40-byte header owns each physical group
and has distinct lifetime kind 9; kind 7 remains the parser pass stack and kind 8
the segmented output header. The private compiler control appends one pool pointer.

Allocation prefers 160 slots, but scans the validated arena under IRQ exclusion
and reduces the group to fit the available span. If even a two-slot group cannot
fit, allocation tries the existing individual 128-byte compact-node payload.
There is no fixed total instruction count. A full group occupies 20536 physical
bytes, compared with 23040 bytes for 160 individual compact allocations. Partially
used groups can cost more than individual nodes; their lifecycle matters as much
as the header savings.

Each slot still enters the control's code ownership queue as kind 1 (live) or
kind 4 (retired). A retired optimizer operand remains readable until the existing
graph disposal rules allow collection. Freed slots become kind 0, leave that
queue, and enter an intrusive free-slot list. Allocation reuses those slots before
issuing more, without reusing retired operands. Only an empty group is physically
freed. Standalone public instructions retain the complete 216-byte node plus
20-byte lifetime, with a normal exact bootstrap heap allocation.

`I386ICLifetime` now receives the control. An interior pointer is admitted only
through one of that control's registered groups, at an issued slot boundary,
with matching physical allocation size, control, node pointer and live/retired
kind. It never treats bytes immediately preceding an arbitrary pointer as proof
of allocation. Public standalone nodes retain their previous size checks. A
private slot is not itself a bootstrap heap allocation and must never be passed
to `I386HeapFree`.

Instruction release and graph discard collect empty groups after slot iteration,
so saved next-record pointers cannot be invalidated mid-walk. Direct retired-node
collection also removes empty headers: frontend pop calls that path without a
later graph discard, and completed publication requires an empty code queue.
Whole-control teardown drains slot records before releasing group headers,
including detached and saved graphs. These operations require no scratch memory.

## Evidence from the rejected first storage policy

The first executable candidate did not reuse freed slots. Its unchanged 8 MiB
lexer contract regressed from final code-storage failure to a 128-byte compact
instruction allocation in `PublicLexTokens.HC`. A hardware breakpoint at the
failure return of `I386ICAddBytes` captured memory before exception cleanup.

`build/i386-ir-slabs-heap-capture-v3/slab-census.json` reconciles every bootstrap
block with the heap counters and every issued slot with its lifetime record.
It found 15 groups for the failing control: 1787 issued slots, 1668 live/retired
slots, 119 freed slots occupying 15232 bytes, and no unissued slots. The arena had
664 free span bytes, largest span 128. This demonstrated retained dead-slot cost;
it was not evidence that the preferred group size alone was too large.

The capture driver, disassembly, memory image and GDB commands/log are preserved
under `build/capture-ir-slabs-heap.py`, `build/i386-ir-slabs-cross-v3` and
`build/i386-ir-slabs-heap-capture-v3`. The rejected candidate's complete source
patch and test source are retained alongside it. Its full 16 MiB diagnostic run
also exposed an empty-header cleanup gap at the subsequent root-header load.
The revised policy reuses freed slots and collects empty headers at the direct
retired-collection boundary; it does not weaken publication's empty-queue check.

## Ownership validation

`tests/guest/i386-task-symbols/PrivateSlab.HC` extends the complete task-symbol
suite with both IRQ states and checks for:

- More than 160 private nodes with fewer physical allocations, foreign-control
  and interior-pointer rejection, and retained borrowed tree operands.
- 150 slot reuses with no additional heap allocation or issued-slot growth, while
  the retained retired operand keeps its address and value.
- Direct retired collection leaving an empty code queue and original heap totals.
- A saved live outer tree surviving inner instruction release and restoration.
- A three-slot adaptive group, exhaustion without partial ownership, and cleanup
  with no additional arena space available.
- Individual-node fallback when the only fitting hole cannot hold a group.
- Whole-control unwind of live, retired and saved graphs, exact heap/counter
  recovery and IRQ-state preservation.

The harness links the actual native emitter implementation to satisfy its
segmented-output teardown dependency. The revised suite passes at
`build/i386-ir-slabs-task-symbols-v6`. Both original bootstrap generations and
the strict full-image build pass at `build/rebuild-test` and
`build/i386-ir-slabs-cross-v5`. Local compiled frontend frame measurements retain
3608 bytes for the descriptor, a 3808-byte frame/argument delta and an 8216-byte
preflight reservation; this remains local evidence, not a bound on arbitrary
recursive parsing or callbacks.

These ownership checks are separate from complete workflow qualification; the
following runtime receipts establish the component results.

## Fixed catalog buffers and the 8 MiB contract

The reuse/collection policy passed both diagnostic phases, but its 8 MiB lexer
run still failed on a 547-byte parser allocation in `LexDispatchCore.HC`. The
second capture (`build/i386-ir-slabs-heap-capture-v4`) has no freed slots and only
1536 unissued slot bytes. Its larger retained cost is the unassembler catalog:
the complete 1833-entry storage needs 131976 bytes but occupied a 263168-byte page
block with 263132 bytes of public capacity. All 1833 names and instruction
encodings match the original catalog, apart from the existing per-record native
entry-number normalization.

The preceding baseline snapshot used a 132096-byte page block for the same
catalog. Normal page allocation can retain an optional larger returned block or
reserve; a different allocation layout can therefore increase its capacity even
when requested data is unchanged. The comparison and complete record validation
are reproducible with `build/i386-ir-slabs-cross-v5/audit-catalog-capacity.py`.

`NativeUAsmTablesInit` now resolves the already retained `I386CAllocExact` provider
and uses it for both fixed lookup arrays and the opcode records. All final sizes
are known; catalog validation, record loops, counts, masks, publication order and
failure cleanup remain intact. Public `MAlloc`/`CAlloc` behavior is unchanged.
The original pointer-free `UAsmTables.DATA` is byte-identical.

The native capacity fixture checks public `MSize` results independently of the
allocator's header layout: each buffer must cover its requested bytes with less
than one native page of spare capacity. At 8 MiB the requested/capacity pairs are
3696/4060, 3636/4060 and 131976/132060. This removes 131072 bytes of excess catalog
capacity compared with the captured oversized block; it is not a controlled
measurement of total VM heap savings.

With the combined changes, the unchanged normal lexer contract passes at both
8 and 16 MiB: 24 exact original result words, one API publication, caller heap
recovery, arithmetic and volume/input checks. The 48-state backend contract
retains the original trace and zero caller heap growth. All 25 diagnostic
source-compiler stages retain their preceding semantic records. Both complete
TCG welcome/diagnostic rasters and both metadata/F64 allocation-fault, unwind and
retry phases pass. The same 1532-byte inline assembly fixture executes at 8 MiB
TCG 486,-fpu, including the independent rel32 boundary check and all pixel
checkpoints. The original twelve-case disassembly contract and new catalog
capacity checks pass at 8 MiB as well.

Current evidence is `build/i386-ir-slabs-cross-v5`, matching lexer/backend/source
compiler/boot/assembly v5 receipts, task-symbols v6 and unassemble-capacity v6.
The final audit checks current source, tool, bootstrap, image and module pins,
exact semantic records and publication counts, local frames and retained rejected
candidate evidence. The normal 8 MiB token-load resource frontier is resolved.
Full normal compiler delivery, fault/concurrency coverage, isolated performance,
native generations, 684 workflows and complete C1–C5 gates remain open;
qualification stays 2/686.
