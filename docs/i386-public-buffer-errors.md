# Failed normal buffer ownership

The C4 failure contract invokes the delivered normal `CmpBuf` API, without
replacing its parser or backend. Run it with a fresh output directory:

```sh
python3 tools/test-i386-public-buffer-errors.py IMAGE --out OUT
```

Ten inputs fail after an incomplete first expression, completed expression,
completed function, initialized global, imported call, partial function body,
pending goto label, completed inline assembly, a failed `#exe` block, and a
completed function containing inline assembly. Each
must return NULL, report errors and no warnings, preserve its borrowed source
and the outer control queue, and restore both caller heap counters exactly.
Each case then compiles a fresh valid expression and releases its packet.
That per-case recovery check establishes packet creation, not execution.
After the worker task exits and its test-owned global diagnostic is restored,
backing usage/allocation counts and heap integrity must return exactly to their
pre-spawn values. The kernel output cache is initialized separately as described
below. A final console arithmetic
expression separately checks the rendered result 42. The runner checks recovery
and filesystem integrity before reporting a failed ownership comparison.

## Preserved failing evidence

`build/i386-buffer-errors-baseline-v1/result.json` tests the unchanged
`f03fd4bdb8a741a327c3256e0c19e63399e03cbb` image from
`build/i386-dollar-error-cross-v2/kernel.img`. Input hashes remained unchanged.
All five cases satisfy NULL/error/warning/source/queue checks and create a fresh
successful packet, but retain these bytes in each reported task heap counter:

| Partial compilation | Data delta | Code delta |
| --- | ---: | ---: |
| Incomplete first expression | 5888 | 5888 |
| Completed expression | 10528 | 10528 |
| Completed function | 11256 | 11256 |
| Initialized global | 10736 | 10736 |
| Imported call | 11392 | 11392 |

These are raw counter observations, not independently attributed allocation
sizes; the counters must not be added together as separate physical storage.
Every case reports two compiler errors. Task kill/validation succeeds but exact
backing restoration fails. V1 stops at the ownership mismatch before its final
arithmetic/filesystem checks; it does not establish those checks.

The strengthened runner repeats exactly the same 48 raw records in
`build/i386-buffer-errors-baseline-v2/result.json`. It additionally verifies
console arithmetic result 42, that only `/Probe/BufferErrors.HC` changed in the
filesystem, and that its allocation bitmap matches reachable extents. All
pinned inputs remain unchanged. The overall result remains FAIL because caller
heap comparisons and the then-cold total backing check fail; recovery does not erase those failures.

## Production cleanup

`CmpJoinCore.HC` keeps the complete existing parsing and packing algorithm.
Its absorbed compiler-error branch now releases code graphs before their symbol
tables, unwinds saved `#exe` hash contexts before deleting owned tables, frees
unresolved call/assembler records and partial packet payloads, unlinks child
packets and releases pending stream blocks. `CmpBufCore.HC` then releases its
owned compiler control on failure as well as success. The input stays borrowed.

`CmpCodeAbort` uses the existing complete `COCRelease` implementation with a
quiet instruction destructor. It releases code-control frames acquired above
the join boundary and the failed root graph without invoking label diagnostics.
An `IC_ASM` record owns its packet buffer: explicit ORG is forbidden inside a
function. `CmpAbortPacketDel` takes buffer ownership explicitly. Remaining
queued children are consumed header views: their bytes and records
already belong to the compiled function or parent packet, so they release only
the header, matching the existing `Cmp` cleanup policy. The root packet has no
allocated result buffer before packing.
This avoids deriving ownership from an architecture-specific address value.

The native lazy join calls the same resident code-graph destructor through a
typed callback appended to `CI386JitSupport`. No public vector is added or
renumbered. `IntermediateOpcodes.HH` contains the byte-for-byte original opcode
definitions extracted from `CompilerA.HH`, so the resident helper can identify
`IC_ASM` without copying its numeric value. The existing ordinary `COCDel`,
control destructor, parser bodies and successful join/packing body are unchanged.

## Expanded evidence

The canonical ten-case comparison is
`build/i386-buffer-errors-baseline-v8/result.json` against the unchanged d39/f03
image and `build/i386-buffer-errors-after-v7/result.json` against the final image.
The identical fixture reports before deltas of 5888, 10528, 11256, 10736, 11392,
7680, 7192, 11792, 6040 and 11136 in each reported heap counter; every after delta
is zero. Both preserve NULL returns, two errors, zero warnings, input/queue and
subsequent packet creation. With output ownership isolated, both correctly
reclaim task backing after exit: the old defect is retention during the caller's
lifetime, not a proven task-teardown leak. Adam's diagnostic-owner heap also
returns exactly to its baseline, and every FixSet output is validated.

The intermediate native candidate in
`build/i386-buffer-errors-after-v2/result.json` restores eight caller cases but
retains 24 bytes after inline assembly and fails backing restoration. Its packet
helper compared against `I64_MAX`, while the native target uses `U32_MAX` as
`INVALID_PTR`. That failure is retained. Explicit buffer ownership replaces the
incorrect marker comparison.

Completed x64 fixups intentionally retain child header views that borrow the
function's code bytes and the parent's transferred records. Failure cleanup
releases those surviving headers as `Cmp` already does; it does not follow their
borrowed fields. Packets still owned by `IC_ASM` are released before their IR
nodes. The fixup implementation and its existing post-state remain unchanged.
The tenth case completes a function containing assembly before a later error.

The original x64 probe invokes the actual rebuilt `Cmp` entry point, which calls
its internal `CmpBuf`. Each source includes the normal kernel declarations so
function/import cases reach their intended parser states. It uses the RAM drive,
waits for the Adam server before triggering errors, captures diagnostics, and
checks source-file/queue preservation, exact caller heaps and subsequent valid
file compilation. It does not establish native task-backing recovery.

```sh
python3 tools/test-buffer-errors-original.py --out OUT
```

`build/buffer-errors-original-before-v7/result.json` retains 883536–887592 bytes
per reported counter, including the declarations. The current
`build/buffer-errors-original-after-v7/result.json` restores all ten counters
exactly. All cases preserve their two-error/zero-warning summaries and the entire
81,920-byte diagnostic buffers are byte-identical before/after. Earlier x64
attempts are preserved: the hidden CmpBuf symbol was not callable directly,
boot-disk writes failed, missing server startup entered the boot debugger, and
sources without kernel declarations did not reach function/import bodies. Those
attempts do not qualify the corrected workflow.

## Global output ownership

`FixSet` replaces `dbg.fix_file_line` using `AStrNew`, so the last error location
belongs to Adam and intentionally outlives a compiling worker. The fixture
preserves the original pointer, validates each new `FL:` diagnostic, releases
the test's final diagnostic and restores the original pointer. It compares the
diagnostic owner's logical heap counter before/after as well as global backing.

A separate kernel-owned allocation explains the initial 38,416-byte backing
change. `NativeRawPutChar` lazily allocates a 38,400-byte `text.raw_scrn_image`
from the kernel heap; its heap header adds 16 bytes. It intentionally survives
task exit. Releasing FixSet's string does not release this screen cache. Earlier
receipts that leave the cache cold are not evidence of a post-exit task leak.

The final fixture initializes this cache through public `RawPutChar(0)` and
warms only the diagnostic allocator before its backing baseline. It records the
cold state, requires two warmup cycles to have identical raw backing counters,
and verifies that the kernel's cache pointer stays unchanged through the test.
It restores the raw cursor/format flags after warmup and keeps the same default
spawned-task compiler path. No failing compiler call is warmed. Per-call worker
heap comparisons remain immediate and exact; no estimated allocations are
subtracted and no escaped literal code is freed.

## Build and regression audit

`build/i386-buffer-abort-cross-v7/final-verification-audit.json` verifies all
1,849 source/26 helper pins, sixteen modules, two original x64 bootstrap
generations, unchanged parser/success/fixup bodies, identical expanded fixtures,
raw records, diagnostic buffers and the before/after comparisons. The final
image passes the fourteen successful buffer cases, the full assembly contract,
all 46 prior compiler-error rows and ten DolDoc boundary cases. Six saved buffer
packets also execute independently as ELF32. ABI remains
Compiler104/Console264/Memory41, with 691 console exports and 22 mask words.

## Remaining scope

This contract covers absorbed compiler errors in normal buffer compilation.
OOM, arbitrary exceptions, failures during setup/map writing/packing, invalid
assembly and nested join exceptions, partial function-header construction,
failures during assembly fixup or optimization,
cancellation and concurrency remain unqualified. Reusing a caller-owned failed
`CmpJoin` control also needs its own state oracle. Full module/file workflows,
desktop/apps and native C5 release generations remain open. No startup,
performance or new low-memory qualification is claimed. C1–C5 remain active and
bundled qualification remains 2/686.
