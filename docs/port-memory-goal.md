# Bounded-memory self-hosting goal

Current source candidate: `i386-retired-boundary-atomic-cross`. Bootstrap,
cross-build, 386 audit and 964-file source audit pass. Normal 8 MiB startup
passes in 59.52 seconds with all nine runtime/VGA checks; the timing margin is
small. Fresh diagnostics/F64/assembly checks pass. The previous
collection snapshot passes 16 MiB publication/ownership diagnostics but its
native build still cannot allocate the 2275963-byte packed-module buffer.
Retired collection is effective, but saves only 146632 bytes. The next work is
bounded serialization without changing the 16 MiB rebuild profile.

Previous snapshot outcome: 8 MiB boot and focused regressions pass, but the accelerated
full retained build fails with OutMem and flat-kernel installation rejects
32 MiB disks. Those earlier runs are terminal; their running descriptions are historical. See the final section for precise remaining failures.

Deliver reliable 386/VGA boot and native rebuilding while preserving HolyC,
DolDoc, existing stack limits, public APIs, and ownership/unwind behavior.

Acceptance requires current-source evidence for:

1. Normal startup at 8 MiB, retained function/static state, and VGA restoration.
2. Complete native HolyC/DolDoc provider builds at 16 MiB.
3. Two successive self-hosted generations and successful installation/boot,
   with reproducibility checks at the scope supported by the build manifests.
4. Publication, software floating-point, saved assembly, optimizer and backend
   regression checks on QEMU without an FPU.
5. Selective diagnostics restored and the verified configuration documented.

## Current experiment — optimizer scratch prefix

The failed baseline is `build/i386-output-phase-boot-v69-8m/result.json`.
It rejects a 4,096-byte allocation; the exact caller remains unproven.
`OptPass012Core` accesses the first stack and resets `ptr2`; it does not access
`stk2`. The private frontend optimizer now requests storage through `ptr2`
(2,056 bytes), while the public optimizer continues to allocate and retain a
complete 4,096-byte `CPrsStk`. Borrowed stacks keep the original contract.
The first stack still has all 255 I64 slots. Exceptions retain control ownership.
Normal output-phase logging is selective again.

The optimizer-prefix candidate passed two-generation bootstrap, native cross-build,
386 audit, and the 16 MiB diagnostic suite (50 publication cases and nine
runtime/VGA commands). Evidence is under `build/i386-optimizer-prefix-*`.
Normal 8 MiB startup still fails: request 4,116 bytes, used `0x65B1F0`, heap
`0x65C200`, largest block `0xF60`. No boot recovery or full-build recovery is proven.

## Next experiment — ordinary ownership record prefix

Ordinary parser allocations now omit `requested`, which is accessed only for
records with a non-null executable-buffer owner. Executable records retain the
full layout; all records retain next/last, payload and owner fields. This saves
eight arena bytes per ordinary record on i386, without changing payload sizes.
The parser memory probe adds 64 live 37-byte allocations with a 5,632-byte total
budget, distinct endpoint contents, reverse release, and exact heap restoration.
Existing failure/unwind probes remain. Bootstrap and native qualification are
required before claiming this candidate passes; evidence will use the
`i386-parser-record-prefix` build prefix.

## Current results — ordinary ownership record prefix

`build/i386-parser-record-prefix-cross` passes two-generation bootstrap and the
386 instruction audit. `build/i386-parser-record-prefix-boot-8m/result.json`
passes normal startup in 58.93 seconds, all nine retained-code/static and VGA
commands, and the interactive startup budget on `486,-fpu`.
`build/i386-parser-record-prefix-float-16m/result.json` passes all 16 runtime
integer/F64 commands. Full 16 MiB diagnostics pass all 50 publication cases and nine runtime/VGA
commands. `memory-contract-check.json` verifies optimizer, new parser-memory
budget, emitter and backend markers in both phases.
`build/i386-parser-record-prefix-float-8m/result.json` passes 16 runtime
integer/F64 commands; `build/i386-parser-record-prefix-bare-8m/result.json`
passes 13 saved-source/AOT assembly commands and interrupt-state restoration.

The six-provider native rebuild remains running at 16 MiB under TCG on
`486,-fpu`, in `build/i386-parser-record-prefix-retained-16m`. Its current
process must be checked before resuming or restarting. Neither full rebuilding
nor successive native generations/install acceptance follows from the passes
above. The build was launched with:

```sh
python3 tools/test-i386-retained-build.py \
  --disk build/i386-parser-record-prefix-cross/kernel.img \
  --out build/i386-parser-record-prefix-retained-16m \
  --reference-exports build/i386-parser-record-prefix-cross/exports \
  --accel tcg --cpu 486,-fpu --qmp-stdio --command-timeout 14400
```

The native-build harness now opts into detection of complete `BUILD MODULE
REJECT` lines since the current command began, avoiding hours of waiting after a
terminal guest failure. It records running/failure state and disk hashes.
`python3 tools/test-i386-command-rejection.py` passes three host tests covering
current rejection, stale/partial output, and opt-in/line-boundary behavior.

## Continuing native qualification

The retained rebuild is still live and compiling ConsoleRuntime/DolDoc. An older
bare-assembly build process was found still waiting after its already recorded
OutMem rejection; it was stopped after checking its exact PID, command line,
and rejection log. Its evidence remains in
`build/i386-bare-assembly-full-build-oom-v69/stopped-live-process.json`.

A separate development run in `build/i386-parser-record-prefix-flat-development`
compiles the six flat-kernel components and exercises installation/8 MiB boot
using the cross-built retained runtime. This can expose kernel/installer defects
early but **does not count as full self-hosting**. Both runs use `486,-fpu`, TCG,
and 16 MiB for native compilation. Check live processes before restarting either.

After the six retained providers pass, run the complete qualification:

```sh
python3 tools/test-i386-native-generations.py \
  --repository . \
  --retained-build build/i386-parser-record-prefix-retained-16m \
  --stage-listing build/i386-parser-record-prefix-cross/kernel-stage.lst \
  --out build/i386-parser-record-prefix-generations \
  --accel tcg --cpu 486,-fpu --qmp-stdio --build-command-timeout 14400
```

This runner requires all six guest-built providers, installs and boots them,
builds/installs the flat kernel, repeats with the resulting guest runtime,
and compares all twelve modules, linked kernel and installed boot area.
The command timeout now propagates to flat builds as well as retained builds.
Flat builds opt into explicit module-rejection detection too. Python syntax
checks and the three rejection-log regression tests pass for these harness changes;
the ongoing native tests remain the required end-to-end evidence.

## Source identity and accelerated qualification

The immutable cross-built input passes `audit-i386-delivered-source.py`: all
963 source/doc files covered by that auditor match the current repository.
Evidence: `build/i386-parser-record-prefix-cross/delivered-source-audit.json`.
The two-generation runner now runs that auditor on its retained-build input and
both installed generations, in addition to binary/boot-area comparisons.

KVM access is available after the permissions change (API version 12). Separate
accelerated runs use the same 16 MiB limit and `486,-fpu` CPU setting:

- `build/i386-parser-record-prefix-retained-kvm-16m`: all six retained providers.
- `build/i386-parser-record-prefix-flat-development-kvm`: development-only flat
  kernel build/install with cross-built retained inputs.

Both use fresh disk copies. The existing TCG runs remain active; KVM availability
does not replace the 386 executable audit or the already passed TCG no-FPU
regressions. Neither accelerated run is yet recorded as passing. The complete
generation runner supports `--accel kvm` for the long compiler runs too; use the
qualified retained-build directory for whichever run actually passes.

## Terminal results and next fixes

- `build/i386-parser-record-prefix-retained-kvm-16m/result.json`: FAIL in
  `DocRecalcCore.HC`, source line `0x480` (1152), request `0x1014` (4116),
  heap used `0xD75698` / size `0xD7C200`, largest block `0xD18` (3352).
  The earlier failure was at line `0x43A`; smaller parser records help but do
  not yet make the whole module fit. The explicit rejection detector worked.
- `build/i386-parser-record-prefix-flat-development-kvm/result.json`: all six
  flat modules and boot linking completed, producing a 544,288-byte kernel,
  but `I386InstallBootImage` returned 0. Both disks have 65,536 sectors; the
  installer in `InstallBootArea.HC` requires exactly 32,768. The target's full
  reserved boot area remains blank. A captured VGA frame records the zero.
- Both redundant TCG development/build runs were stopped after preserving their
  partial evidence. They are not passes. No native generations were launched.

Next: regression-test and fix the installer's 16 MiB-only disk guard while
preserving blank-target validation and boot-sector-last publication; make the
harness reject explicit zero answers promptly. For compiler memory, inspect
private frontend IR storage/lifetimes: i386 emits machine code outside the
original 131-byte IC body union, while optimizer tree links occupy much less.
Any compact private representation must preserve full public IC allocations,
node/tree pointers, retirement, unwind and inline-assembly behavior. This is an
investigation direction, not an implemented or qualified compact-IR change.

## Compact IR and installer candidate

`I386InstallBootArea` and `I386InstallBootImageArea` now require enough sectors
for the 2048-sector boot reservation, rather than exactly a 16 MiB disk.
The blank-target check, filesystem boundary and flush/boot-sector-last order
remain intact. `test-i386-install-area.py` runs the actual HolyC transport core
with fake ATA: the old code fails at the 32 MiB case (`i386-install-area-red`),
and the changed code passes 20 cases (`i386-install-area-green`) covering
16/32/64 MiB, source/target bounds, alias/blank guards and interrupted writes/flush.
Real ATA installation remains to be requalified.

`test-i386-command-zero-rejection.py` passes on QEMU/KVM with a known old image:
zero is rejected when explicitly configured as an error answer, while ordinary
zero and one answers still pass. Both retained and flat-build harnesses opt in;
this prevents a completed failed install from consuming the full timeout.

Private frontend IR now allocates through the optimizer tree-link union member,
aligned for its ownership trailer. The unused original machine-code buffer tail
is omitted only for this private path; native machine bytes live in `CI386Out`.
Public `I386ICAdd` allocations remain full-sized. Size-aware lifetime lookup is
used by discard, retirement and branch optimization; linked node addresses and
all used field offsets stay unchanged. The public optimizer probe now writes
and verifies a canary in the final byte of the public IC body.

The fresh bootstrap uses `build/i386-compact-ir-bootstrap.log`. No compact-IR
native pass or full-build recovery has yet been established.

## Compact-IR first qualification and cleanup refinement

The first compact-IR image (`build/i386-compact-ir-cross`) passes cross-build
and the 386 audit. Its 16 MiB diagnostic test passes, including the public IC
body canary, optimizer/branch/ownership probes, 50 publication cases and nine
runtime/VGA checks. At 8 MiB all nine behavior checks pass, but startup took
60.642 seconds against the 60-second gate, so that report correctly remains FAIL.

`build/i386-compact-ir-flat-development-kvm/result.json` PASSES: six flat
components built at 16 MiB, a 544,288-byte boot image installed on a 32 MiB disk,
and the result booted at 8 MiB. This uses cross-built retained modules and
therefore remains development evidence, not complete self-hosting.

The first compact-IR six-provider KVM rebuild remains live under
`build/i386-compact-ir-retained-kvm-16m`; its eventual evidence is scoped to
that snapshot. The worktree now refines discard: it finds a node's existing
ownership record instead of adding a full arena size scan for each free.
Record ownership/link checks and heap-free validation remain. Fresh qualification
for this refinement starts with `build/i386-compact-ir-owner-bootstrap.log`;
it is not covered by the preceding image's results.

## Refined candidate checkpoint

- `build/i386-compact-ir-owner-cross`: bootstrap, cross-build, 386 audit and
  963-file delivered-source audit pass.
- `build/i386-compact-ir-owner-boot-8m/result.json`: PASS, 57.84-second startup,
  all nine runtime/static/VGA checks, within the unchanged 60-second budget.
- `build/i386-compact-ir-owner-diag-16m/result.json`: PASS, 50 publication cases
  and nine commands; `memory-contract-check.json` verifies both-phase public
  IC body, optimizer, parser memory, emitter and backend markers.
- `build/i386-compact-ir-owner-float-8m/result.json`: PASS, 16 commands.
- `build/i386-compact-ir-owner-bare-8m/result.json`: PASS, 13 commands.
- `build/i386-install-area-green-pinned/result.json`: PASS, 20 fake-ATA cases,
  with the core/header, fixture, tools and original bootstrap binaries pinned.
- `build/i386-command-zero-rejection/result.json`: PASS, negative VGA assertion
  detected and ordinary zero/one results accepted.

The earlier compact-IR full rebuild is terminal: stage 5, module size 0,
`Compiler` exception. Stage 5 follows the pack-size query; the final source-line
context is not proof of a syntax error. DocRecalc body/output completion is
preserved in `build/i386-compact-ir-retained-kvm-16m/doc-recalc-completed.json`.
There is no module-pack or full-build pass yet. Next isolate the failed packing
validation; do not relax relocation/type/ownership checks merely to accept it.
The refined rebuild in `build/i386-compact-ir-owner-retained-kvm-16m` is now
terminal too: its `result.json` records the same stage-5, zero-size rejection.
The input disk SHA-256 remains unchanged, so no provider was persisted.

## Pack rejection attribution in progress

`Compiler/I386/FrontendPublish.HC` now reports the failing validation and the
function/global name for module-source builds. Relocation, ownership, type,
dimension, pointer-resolution and serialization checks remain enforced; the
failure path allocates no memory. Initial invalid-context requests still return
zero without dereferencing their context.

The fresh two-generation bootstrap passes; its log is
`build/i386-pack-attribution-bootstrap.log`. The fresh cross-build also passes,
including the 386 audit (96 BIOS and 209 protected-mode instructions); see
`build/i386-pack-attribution-cross.log`.

The six-provider native rebuild is running at 16 MiB under KVM, CPU
`486,-fpu`, in `build/i386-pack-attribution-retained-kvm-16m`. It uses the
fresh cross-built image and a 14400-second per-command timeout. There is no
full native build pass yet; poll this run to obtain attributed packing evidence
before changing packing behavior. The earlier 8 MiB runtime/diagnostic passes
apply to the previous candidate, not this instrumentation snapshot.


### Instrumented snapshot qualification

- `build/i386-pack-attribution-cross/delivered-source-audit.json`: PASS, all
  963 delivered source/doc files match the candidate.
- `build/i386-pack-attribution-boot-8m/result.json`: PASS, normal startup in
  57.29 seconds within the unchanged 60-second budget, all nine commands and
  exact VGA restoration, CPU `486,-fpu` at 8 MiB.
- `build/i386-pack-attribution-diag-16m/result.json`: PASS, 22 class and
  28 program publication cases plus nine runtime/VGA commands.
  `memory-contract-check.json` pins the log and requires both-phase optimizer
  (including public IC-body canary), parser-memory, emitter and backend markers.
- `build/i386-pack-attribution-float-8m/result.json`: PASS, 16 commands.
- `build/i386-pack-attribution-bare-8m/result.json`: PASS, 13 commands,
  interrupt restoration and persisted block/bare assembly payloads.
- The native provider build is terminal FAIL; see the attributed duplicate
  function rejection and source fix below.


### Attributed provider failure and source fix

`build/i386-pack-attribution-retained-kvm-16m/result.json` is terminal FAIL.
All 647 ConsoleRuntime functions completed, then the pack-size query rejected
`duplicate-function NativeRandPitRead`. The source disk is unchanged (SHA-256
`9303c43c7a4ae70afbda1e2cbccfc328248538c329fc1b612817b069cffc60d2`); no module
was persisted. This is neither an OutMem nor a relocation/type failure.

RasterRuntime renamed and included PitRead.HC, then DocumentReport included
that implementation again while the rename macro was still active. The source
now shares a guarded `ConsolePitRead.HC` helper, uses an explicit implementation-name macro instead of aliasing I386PitRead,
and calls the same private reader explicitly from both users. The kernel's
separate I386PitRead name and port-read behavior remain unchanged. Duplicate export
validation remains enforced. Fresh bootstrap/cross-build and native rebuilding
are required to qualify this source fix; the previous green evidence applies
to the instrumented snapshot before this fix.


The first shared-helper cross-build (`build/i386-console-pit-shared-cross`)
is terminal FAIL: HolyC does not support `#undef`, so that wrapper was rejected.
The corrected wrapper uses `I386_PIT_READ_FUNCTION`, a name-selection macro
consumed only by PitRead.HC, and no unsupported directive. Fresh qualification
uses the `i386-console-pit-name` prefix; no failed image is used as a rebuild
input. The original two-generation bootstrap passed but must be refreshed for
this correction.


### Corrected PIT helper checkpoint

- `build/i386-console-pit-name-bootstrap.log`: PASS, two-generation original
  compiler/kernel rebuild.
- `build/i386-console-pit-name-cross`: PASS, cross-build and 386 audit
  (96 BIOS / 209 protected-mode instructions), 539856-byte flat kernel.
- `build/i386-console-pit-name-cross/delivered-source-audit.json`: PASS,
  all 964 packaged source/doc files match, including the new console helper.
- `build/i386-console-pit-name-retained-kvm-16m/result.json`: terminal FAIL;
  packing validation succeeds, but the output buffer allocation fails at
  16 MiB. See the memory trace and candidate below.
- `build/i386-console-pit-name-boot-8m/result.json`: PASS, 59.13-second
  normal startup within the unchanged 60-second gate, all nine runtime/static
  commands and exact VGA restoration. The timing margin remains small.
- `build/i386-console-pit-name-diag-16m/result.json`: PASS, 22 class and
  28 program publication cases plus nine runtime/VGA commands. Its
  `memory-contract-check.json` pins both-phase optimizer/public-body canary,
  parser-memory, emitter and backend completion markers.
- `build/i386-console-pit-name-float-8m/result.json`: PASS, 16 commands.
- `build/i386-console-pit-name-bare-8m/result.json`: PASS, 13 commands,
  interrupt restoration and persisted block/bare assembly modules.

The duplicate source definition has been removed. Full native module
serialization/rebuild and two installed native self-hosted generations remain
unproven.


The failed attributed build has 647 function-start and 647 function-done
markers. Only `NativeRandPitRead` repeats (twice), confirming the demonstrated
duplicate is the only repeated compiled function in that source snapshot. This
log inspection does not establish that every remaining pack validation passes;
the corrected native provider run must still reach and pass packing.


## Post-pop retired-node collection candidate

The corrected PIT provider run completes 646 functions and obtains a valid
pack-size query of 2275963 bytes (`0x22BA7B`). It then fails allocating that
contiguous output buffer, at stage 5. The trace reports heap usage 12563360
of 14139904 bytes, largest free span 430792 bytes, and 67378 allocations.
The source disk remains unchanged (SHA-256
`b9d90630149525996ba2800f1ef62ee675c77e1f03b298d229982eba4239c2a0`).
This proves the duplicate rejection is resolved, not that serialization passes.

Inspection identifies a missed private collection boundary: output discard
runs while a saved code header still defers retired optimizer aliases, and
frontend pop removes that header without retrying collection. The candidate
now retries the existing conservative collector after the private pop/header
release. It frees only when every remaining ownership record is retired;
active IR, miscellaneous records and saved headers still defer collection.
Public code-header freeing semantics, node layouts and services are unchanged.
A module-source pack-query marker reports heap usage/allocation count plus
retired/live/header counts without allocating diagnostic scratch. The size of
the resulting memory improvement is not measured yet.

Fresh bootstrap is running in `build/i386-retired-boundary-bootstrap.log`.
After bootstrap/cross-build, run existing ownership/public-body diagnostics,
8 MiB startup, the native provider build and then installed generations. Do not
raise the memory profile or remove packing checks to accept the output buffer.

Additional actual-consumer evidence on the previous PIT-helper snapshot:

- `build/i386-console-pit-consumer-check/result.json`: FAIL at 8 MiB while
  compiling the full DocReportCheck fixture, before calling the PIT consumer;
  allocation request 4096 bytes. This is an extra compilation-memory limit,
  not proof of a timer/report failure. The fixture's full IRQ-off/task/display/
  heap assertions are not qualified at 8 MiB by this run.
- `build/i386-console-pit-consumer-direct-8m/result.json`: PASS, five commands
  exercising the existing 25-ms timed report and timer-assisted RandU16 paths,
  IRQ preservation and console continuation. Disk/manifest, runner, local
  harness and fixture are pinned. This narrower result does not replace the
  full fixture qualification or the native rebuild requirement.


The first retired-boundary cross-build is terminal FAIL: the pack-memory marker
referenced KernelHex, which is not imported by CompilerRuntime. The corrected
marker formats its bounded 32-bit counters on the stack and uses the existing
KernelLog binding. It adds no runtime import or service-layout change. Fresh
qualification uses the `i386-retired-boundary-text` prefix.


### Atomic private boundary refinement

The first collection image passes all nine 8 MiB runtime/VGA checks but FAILS
the timing gate: `build/i386-retired-boundary-text-boot-8m/result.json` records
60.96 seconds against 60 seconds. The six-provider native build remains live
in `build/i386-retired-boundary-text-retained-kvm-16m`, and the 16 MiB diagnostic
run is live in `build/i386-retired-boundary-text-diag-16m`. These runs use the
previous collection snapshot, not the refinement below.

Private pop now keeps pop, validated header release and retired collection in
one IRQ-preserving atomic boundary. The existing pop/header operations validate
ownership; this removes the added redundant whole-arena owner scan between
header release and collection. The collector's all-retired rule and public
header semantics remain unchanged. This timing refinement is unqualified until
fresh startup/diagnostic evidence; it does not widen the startup gate.
Fresh bootstrap/cross-build use the `i386-retired-boundary-atomic` prefix.


### Measured collection outcome and next architecture

`build/i386-retired-boundary-text-retained-kvm-16m/result.json` is terminal
FAIL at the output-buffer allocation. Pack-query telemetry shows heap usage
12416728 bytes, 66393 allocations, zero retired/live IR records and zero saved
headers. This saves 146632 bytes and 985 allocations against the PIT-helper
snapshot. The largest free span grows from 430792 to 538648 bytes, still below
the unchanged 2275963-byte module requirement. Collection works but does not
solve the need for a second complete module-sized allocation.

The atomic refinement passes bootstrap, cross-build, 386 audit and the 964-file
source audit. `build/i386-retired-boundary-atomic-boot-8m/result.json` passes
at 59.52 seconds with nine runtime/static/VGA commands. The earlier non-atomic
collection image's 16 MiB diagnostics pass 22 class and 28 program publication
cases plus nine commands; this is comparative evidence, not qualification of
the refined compiler. Fresh refined diagnostics, F64 and assembly checks pass under the
`i386-retired-boundary-atomic` prefix. Full report-fixture compilation still
exceeds 8 MiB; the corrected combined consumer test passes at 16 MiB, as
recorded below. Earlier running descriptions above are historical.

Next implement bounded packing with these requirements:

1. Build a validated module layout once, retaining compact metadata and borrowed
   code/global spans. Preserve all existing function-name, relocation, type,
   ownership, dimension and pointer-resolution checks. Keep the contiguous
   `program_pack_unit` API and output format unchanged.
2. Emit payload, records and strings through a bounded writer, normalizing
   relocation and stored-pointer sites exactly as the current serializer does.
   Handle padding and fixups crossing writer-block boundaries. Do not allocate
   a second whole payload while the compilation control is live.
3. Separate staging from final publication. A possible transport is a private
   disk extent: serialize while the control owns source spans, unwind the
   control, then read/validate the staged module with the freed memory and use
   the existing file-publication path. Verify disk capacity, staging ownership,
   task cancellation, interrupted writes/flushes and cleanup before committing
   to this transport. Keep the old target untouched until validation and
   compiler cleanup succeed. Internal module exports can supply capabilities
   without changing existing service-field offsets or HolyC/DolDoc APIs.
4. Tests first: compare bounded output byte-for-byte with the current serializer
   for multiple functions, statics, literal pools, local/named pointers and
   relocations. Exercise short/error writes, block-boundary fixups, invalid
   layouts, allocation failure, unwind failure and staging cleanup. Record
   peak scratch memory; a mock transport alone does not qualify mounted ATA.
5. Qualify the real six-provider build at 16 MiB on the final current-source
   image, then run the complete installed two-generation pipeline and all
   source/386/binary identity audits. Preserve the 8 MiB startup gate and
   no-FPU ownership/public-body/optimizer/backend/F64/assembly regressions.

Do not rerun the same whole-buffer build expecting collection alone to make it
pass; the allocation requirement exceeds both free total memory and its largest
span. No atomic-refinement native full-build or native-generation pass exists.


### Final atomic-boundary qualification checkpoint

- `build/i386-retired-boundary-atomic-diag-16m/result.json`: PASS, 22 class and
  28 program publication cases plus nine commands. Its memory-contract manifest
  pins both-phase optimizer/public-body canary, parser-memory, emitter and
  backend markers.
- `build/i386-retired-boundary-atomic-float-8m/result.json`: PASS, 16 commands.
- `build/i386-retired-boundary-atomic-bare-8m/result.json`: PASS, 13 commands
  and persisted bare/block assembly payloads with interrupt restoration.
- `build/i386-retired-boundary-atomic-consumer-check/result.json`: FAIL, the
  full report fixture cannot compile at 8 MiB (allocation request 2056 bytes,
  largest free span 1376). The existing 8 MiB startup/retention gate passes,
  but this more complex fixture is not covered by that pass.
- `build/i386-retired-boundary-atomic-consumer-check-16m/result.json`: terminal
  FAIL after the report-state check passed; the subsequent ad-hoc random fixture
  used unsupported declaration-in-for syntax. This is a harness error and is
  not reported as a combined consumer pass.
- `build/i386-retired-boundary-atomic-consumer-corrected-16m/result.json`:
  PASS, five commands. The unchanged DocReportCheck fixture checks 25-ms
  reports with IRQ on/off, exact task/display flags and public-heap usage.
  Corrected random-sampling syntax checks 64 timer-assisted calls and IRQ
  preservation; console continuation returns 42. The actual image, manifest,
  runner, local harness and report fixture are pinned.

All test processes at this checkpoint are terminal. No full native six-provider
or installed native-generation pass exists. The measured non-atomic provider
failure remains the bounded-writer baseline; the final atomic frontend is
qualified for focused checks only, with a small startup timing margin.
