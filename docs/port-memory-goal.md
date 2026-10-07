# Bounded-memory self-hosting goal

Latest qualified full-image candidate: `i386-frontend-root-header-phases-cross`.
Bootstrap, cross-build, 386 boot instruction audit and the 965-file delivered
source audit pass. Normal 8 MiB startup passes in 47.55 seconds with all nine
retained-state/VGA checks. Focused 8 MiB F64/assembly regressions and full
16 MiB diagnostics pass. Native bounded serialization now passes byte identity,
short/error writes and thrown-exception cleanup in root and worker phases.
The six-provider rebuild still uses the whole-buffer file path: task-owned
staged output and two installed native generations remain unproven.

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

## Bounded serializer foundation — contract verified

`ModuleWriteCore.HC` now emits the existing T32M layout using caller-owned
scratch of 1–4096 bytes and borrowed payload bytes. It validates metadata
before invoking the sink, normalizes relocation and pointer slots even across
chunk boundaries, and stops immediately on short or failed writes. It allocates
no heap and does not mutate its inputs. `ModuleCheck.HC` shares its existing
validation rules between contiguous buffers and borrowed payload access.

Evidence on the current foundation sources:

- `build/i386-module-check/result.json`: PASS, 46 validator cases executed as
  audited i386 code.
- `build/i386-module-writer-green-zeroed/result.json`: PASS, actual HolyC writer
  compared with the existing contiguous packer at six scratch sizes, 30
  injected short/error writes and 11 invalid requests. Input hashes are pinned.
- `build/i386-module-writer-red-zeroed/guest/debug.log`: controlled stub fails
  at `FAIL module-writer 10`, the first output check after successful oracle
  construction. This is a behavior failure, rather than a compile timeout.

The writer fixture explicitly initializes every raw record; earlier runs that
relied on uninitialized fields are superseded. Writer execution here uses the
original host HolyC environment, not the native i386 compiler. It does not prove
native bounded-memory rebuilding, disk staging, or atomic file publication.
The full-image results above apply to the preceding qualified snapshot.

Next retain the frontend's name/type/ownership/layout checks while constructing
compact metadata and borrowed payload spans, integrate bounded output with
task-owned disk staging and cleanup, then qualify native writer execution and
real short-write/unwind/publication behavior. Keep the existing contiguous
packing API. Only then run all six native providers at 16 MiB and two installed
self-hosted generations, followed by the current-source 8 MiB/no-FPU gates.

### Borrowed payload spans

The writer core now provides a validated, sorted span view and a binary-search
byte reader. Code, globals and literal storage can remain in their original
allocations; alignment holes return zero. Validation rejects overlapping spans,
missing storage, empty spans and out-of-range lengths without U32 wraparound.
The reader requires a validated view whose borrowed storage remains alive.

`build/i386-module-writer-borrowed-spans/result.json` passes the existing 47
writer cases using three borrowed spans, plus ten span checks covering invalid
views and an interior alignment hole. Source and binary inputs are pinned.
This remains host HolyC core evidence. Frontend metadata construction and
task-owned disk staging are still pending; the native 16 MiB blocker is not
yet resolved. The previous 47-case runs remain historical foundation evidence.

### Frontend bounded metadata path — integration candidate

The frontend now shares its existing function/global selection and layout checks
between contiguous packing and an internal bounded-output entry point. The
new path allocates records, strings and borrowed-span metadata, rather than a
second complete payload. Metadata allocations are released after normal sink
completion or failure. Existing service entry points keep their signatures.
Top-level assembly bundles currently reject bounded output; disk staging,
exception cleanup and public runtime binding remain to be integrated.

`build/i386-frontend-bounded-bootstrap.log` passes the two-generation bootstrap.
`build/i386-frontend-bounded-cross.log` passes cross-compilation and the 386 boot
instruction audit (96 BIOS / 209 protected-mode instructions). This establishes
compilation, not native bounded-writer execution or memory-budget acceptance.
The 16 MiB diagnostic run `build/i386-frontend-bounded-diag-16m` is terminal
FAIL: phase-zero native formatter checks stop with `FAIL native kernel`, after
the preceding native file check passed. This candidate is not qualified.
Native byte identity,
allocation/failure cleanup, then staged file publication are the next gates.

Formatter localization adds phase markers around packing, loading and negative
execution checks without changing their assertions. The trace bootstrap passes
(`build/i386-frontend-bounded-format-trace-bootstrap.log`). The trace cross-build passes;
`i386-frontend-bounded-format-trace-diag-16m` is terminal FAIL. Its last
markers show packing, loading and negative-input execution completed. The
failure is afterward, at optional target formatting or heap restoration. The frontend integration remains
uncommitted until this regression is understood.

A follow-up logs the target-format flag and heap counters after image release,
keeping the original restoration assertion. Its sequential bootstrap/cross/
diagnostic job uses the `i386-frontend-bounded-format-memory` prefix. Inspect
the live job before restarting; no native bounded-path pass is claimed.

The memory trace diagnostics are terminal FAIL. `NATIVE FORMAT NEGATIVE DONE`
reports a false target-format flag; `NATIVE FORMAT MEMORY` reports exact heap
restoration (`0x6C5BA8` bytes and `0x17E` allocations both before/after). The
failure is later in the enclosing probe, not these checks. A cleanup trace
now distinguishes module release, each scalar-root removal and final heap
restoration. Its pipeline uses `i386-frontend-bounded-format-cleanup`.

Cleanup trace diagnostics are terminal FAIL: module release and all six scalar
root removals succeed, but final counters are `0x6C1C28` / `0x11D`, versus
`0x6BF9E0` / `0x11C` before the probe. One allocation spanning `0x2248`
(8776) bytes remains. A bounded stack-only heap snapshot now identifies new
blocks at this failure boundary; it leaves the original assertion intact.
The next pipeline uses `i386-frontend-bounded-format-block`.

The block-identification run is terminal FAIL. It identifies a new payload at
`0x857D18`, requested `0x2233` (8755) bytes, spanning `0x2248` (8776) bytes.
This request equals an 8192-byte public backing region plus
`sizeof(CI386BackingRegion)` and 511 bytes of alignment in
`I386MemBackingGrow`. This is strong evidence of cached backing storage, but
the owner must still be confirmed from the backing pool's owned list.
`I386TaskCodeRelease` trims cached pages only when total live heap bytes reach
zero; additional empty page blocks can remain while unrelated code is live.
Next confirm owned-region/page counters and add a regression for releasing a
fully free page block while preserving live allocations in other blocks. Any
fix must retain public heap layout, live pointer identity and allocator safety;
do not relax the existing exact-restoration assertions.

The existing `tests/guest/i386-heap/BackingAccounting.HC` explicitly tests the
observed case: temporary small allocations grow a backing region while another
allocation stays live, and the cache remains after release. It accepts only
verified owned backing cache; physical and public payload leaks, damaged
accounting and private compiler-arena leaks are rejected. Thus the raw heap
assertion in the formatter subprobe conflicts with the established accounting
contract already used by the enclosing compiler probe. The earlier description
of a confirmed leak was premature: the extra block is not yet proven leaked.

The formatter now uses the existing `I386BackingCheckSave/Restored` contract.
This confirms backing ownership and unchanged live public bytes, subtracts only
validated owned backing allocations, and still requires exact physical totals
for a separate private compiler arena. No allocator policy or target memory
limit changes. The `i386-frontend-bounded-format-accounting` pipeline must
verify this correction before claiming the candidate passes.

Focused accounting qualification passes on the current candidate:
`build/i386-backing-accounting-test/result.json` and
`build/i386-backing-accounting-source-test/result.json` both report PASS.
The actual `BackingAccountingTest` executes as i386 code at 8 MiB with both
assembly and portable heap validators. It covers retained page cache, live
payload preservation, deliberate physical/public/private leaks and damaged
backing accounting. Logs are `build/i386-frontend-bounded-backing-accounting*`.
The accounting-corrected bootstrap and cross-build also pass; the full native
diagnostic run remains pending until its process reaches a terminal result.

The accounting-corrected candidate passes the full 16 MiB diagnostics:
`build/i386-frontend-bounded-format-accounting-diag-16m/result.json`. Both
formatter phases emit `NATIVE FORMAT BACKING RESTORED`; publication/program
and nine runtime/VGA checks complete. The previously suspected allocation
leak is verified backing cache. This does not yet exercise bounded output.

The next candidate exposes bounded unit writing through the internal export
enumerator, preserving the public compiler-services layout. Its native unit
probe compares three scratch sizes byte-for-byte against contiguous output
and tests short/error writes at beginning, middle and end with exact temporary
heap restoration. The fixture retains functions, globals, static storage and
mutable string-literal pointers. Qualification is pending.

The native-unit candidate bootstrap and cross-build pass. Its live diagnostics
emit `NATIVE BOUNDED UNIT 0000000000000000 0000000000000333`: phase zero
completed byte identity at three scratch sizes and six injected short/error
sinks, including exact temporary physical-heap recovery. Full phase-one and
runtime/VGA qualification is pending; inspect the
`i386-frontend-bounded-native-unit` pipeline before editing its source inputs.

Before disk integration, extend this to thrown sink exceptions and control
unwind. Current metadata/selection allocations use direct heap allocation;
a thrown sink can bypass their normal release path, so exception ownership
is not yet qualified. Disk staging also needs task-owned cleanup across
cancellation/kill; anonymous sector allocation alone is insufficient. The
target file must remain unpublished until staged validation and clean compiler
unwind complete. These remain required integration work, not waived gates.

Native bounded-unit qualification is terminal PASS at 16 MiB:
`build/i386-frontend-bounded-native-unit-diag-16m/result.json`. Both root and
worker phases emit `NATIVE BOUNDED UNIT`, completing three byte-identical
outputs and six short/error write failures with exact temporary-heap recovery.
All existing publication/program/runtime/VGA checks complete.

A tests-first follow-up injects `Write` exceptions at the first, middle and
last sink calls, requiring the original exception, no additional sink calls,
and exact temporary-heap recovery while the compilation control stays alive.
The expected-red pipeline uses `i386-frontend-bounded-exception-red`; the
production cleanup fix has not been applied yet.

The exception red run is terminal behavior FAIL after successful bootstrap
and cross-build. `FAIL bounded sink cleanup 2 0` shows the first injected
`Write` exception was caught, but 752 bytes / six allocations remain
(`0x6C4ED0` versus `0x6C4BE0`, `0x17C` versus `0x176`). This is a genuine
temporary allocation leak, unlike the separately verified backing cache.

The fix catches sink exceptions in the metadata writer, releases records,
strings and spans, then rethrows the original exception. The unit wrapper
also releases function/global selection arrays and literal descriptors before
rethrowing. The unchanged tests now qualify the fix under the
`i386-frontend-bounded-exception-green` prefix. Task-kill ownership and disk
staging remain separate required work.

The exception-green bootstrap and cross-build pass. The live diagnostic run
emits `NATIVE BOUNDED UNIT` in phase zero after all three byte-identity, six
short/error and three thrown-sink checks. Each injected `Write` exception
propagates and temporary heap totals recover exactly while the control stays
alive. Full worker/runtime qualification is still pending. Preserve this
run's source inputs until its process is terminal.

## Native bounded frontend — exception cleanup qualified

`build/i386-frontend-bounded-exception-green-diag-16m/result.json` is terminal
PASS. Root and worker phases both emit `NATIVE BOUNDED UNIT`, proving three
byte-identical buffer sizes, six short/error sink cases and three thrown-sink
cases per phase. The original exceptions propagate, no extra sink calls occur,
and temporary heap bytes/allocation counts recover exactly with the compiler
control still alive. All 22 publication, 28 program and nine runtime/VGA checks
complete. Bootstrap and i386 cross-build/boot instruction audit pass as well.

The internal export enumerator adds `I386FrontendModuleWriteUnit`; existing
compiler-service structure size and contiguous packing signatures stay intact.
The implementation is integrated into the compiler runtime, but BuildModule
still uses the original whole-buffer file path. Native bounded output alone
does not resolve the full six-provider 16 MiB rebuild blocker.

Next qualify the current source at 8 MiB (startup timing, F64 and assembly),
then implement task-owned staged output and cancellation/kill cleanup before
switching BuildModule. Top-level assembly bundles currently reject bounded
output. Complete six-provider native rebuilding and two installed generations
remain required; earlier full-image 8 MiB results are historical.

## Current 8 MiB regression — bounded runtime footprint

`build/i386-frontend-bounded-exception-green-boot-8m/result.json` is terminal
FAIL before interactive acceptance. Startup requests 4096 bytes; heap used
`0x659ED0`, size `0x65BA00`, largest free span `0xE40`. The sequential F64
and assembly checks were not launched after this failure. The 16 MiB bounded
frontend pass does not qualify 8 MiB startup.

The next candidate narrows serializer and frontend loop indices to U32, whose
ranges are bounded by existing layout validation. Payload totals and overflow
checks stay wide; no stack limits, features or memory profiles are relaxed.
The bounded writer's offsets and intersections are within validated U32 module
size, and scratch is capped at 4096 bytes. Qualification uses the
`i386-frontend-bounded-u32` prefix.

The U32-index candidate passes bootstrap and all 57 host writer cases, but
8 MiB startup still fails (4096-byte request, largest span `0xE48`). The
compiler runtime shrinks only eight bytes; function-level measurements show
most operations still promote through wide bounds/intermediates. This is not
a memory-budget pass. The next candidate narrows validated emission offsets
and name lengths, and casts already-checked function/global/code span bounds
to U32 at loop comparisons. Wide payload sizing and overflow checks remain.
Qualification uses `i386-frontend-bounded-offsets`.

The narrowed-offset candidate also fails 8 MiB startup and emits the same
1798691-byte compiler module as the prior exception-green candidate. These
ineffective counter refinements are removed. The next structural candidate
uses the bounded serializer for contiguous frontend output via a memory sink,
removing the separate payload-copy/fixup path. Public signatures, format, wide
layout checks and the independent raw-packer oracle remain intact. Contiguous
output now borrows spans as well; this adds a small temporary span array and
512-byte stack buffer, whose cleanup is covered by native diagnostics.
Qualification uses `i386-frontend-shared-writer`.

The shared-writer candidate passes bootstrap, 57 writer contracts and cross
compilation; it saves about 1.6 KiB but still fails 8 MiB startup later, with
a 4116-byte request and largest free span `0x5A0`. The runtime's net growth
since the last passing snapshot is roughly 24 KiB. No 8 MiB pass is claimed.

The next candidate first compiles PublicKernel.HH atomically, then compiles
the unchanged complete PublicUser.HH atomically. The first control releases
its temporary parser metadata before the remaining headers are parsed. The
PublicUser guard is still committed only by the complete second transaction;
all declarations remain available and user-terminal header loading is unchanged.
No parser stack limits or required declarations are reduced. Qualification
uses `i386-frontend-root-header-phases`.

## Phased root headers — 8 MiB recovery

`build/i386-frontend-root-header-phases-boot-8m/result.json` is terminal PASS:
startup completes in 47.55 seconds, and all nine retained function/static/
literal and exact VGA-restoration commands pass on `486,-fpu`. Both
`ROOT KERNEL HEADERS ok` and `ROOT USER HEADERS ok` appear. The current
bootstrap and cross-build/386 boot audit pass, and the delivered-source audit
verifies all 965 files. This is a material timing margin versus the earlier
59.52-second snapshot; no memory profile or parser stack limit is changed.

The current source still needs unified-serializer native diagnostics and the
focused F64/assembly gates. Their sequential job uses
`i386-frontend-root-header-phases-float-8m`, `-bare-8m` and `-diag-16m`.
Preserve Kernel/Compiler inputs until the job is terminal. Do not substitute
the preceding exception-green 16 MiB pass for this refactored snapshot.
Disk staging and complete native self-hosted rebuilding remain pending.

The phased-header candidate's focused 8 MiB regressions are terminal PASS:
`build/i386-frontend-root-header-phases-float-8m/result.json` and
`build/i386-frontend-root-header-phases-bare-8m/result.json`. Runtime software
F64 behavior and retained static state, saved bare/block assembly persistence
and IRQ-state restoration pass on the source-pinned snapshot. Full 16 MiB
diagnostics are running under the same prefix; their result remains pending.

## Shared writer and phased startup — qualified checkpoint

`build/i386-frontend-root-header-phases-diag-16m/result.json` is terminal PASS:
22 class-publication cases, 28 program-publication cases, both native bounded
unit phases and nine runtime/VGA commands complete on `486,-fpu`. The
current-source 8 MiB boot, F64 and assembly results above are also terminal
PASS. The shared serializer's contiguous path is exercised by the native
packer/loader/file/compiler probes, not merely the host core fixture.

Root startup first publishes core kernel headers, releases their temporary
compiler control, then atomically publishes the complete remaining user
headers. This retains the declaration set and public layouts while lowering
peak transient memory. The complete user-header guard remains the completion
marker. Contiguous packing shares the borrowed-span writer through an in-memory
sink; the original raw serializer remains the independent contract oracle.

Next implement a task-owned disk staging record and bounded write/read/abort
operations, with tests for short I/O, flush failure, cancellation, kill and
cleanup retry. BuildModule must validate staged bytes after clean compiler
unwind before publishing its target. Preserve small assembly-bundle support
through the existing contiguous path where appropriate. Then qualify all six
providers at 16 MiB and two installed native generations with source/binary/
boot-area identity and current-source 8 MiB/no-FPU gates. No such native
rebuild/generation acceptance is claimed by this checkpoint.


## Allocation-free staging lifecycle contract

`ModuleStageCore.HC` now separates sequential bounded writes, flush/seal,
clean compiler unwind, exact readback and release. It retains ownership on
short/error writes, failed flush/read and failed release; release can retry
and successful release is idempotent. Writes are limited to 4,096 bytes and
readback requires the exact declared module size after a clean unwind.
Thrown transport exceptions propagate to the caller without dropping ownership.
The transport must register ownership before initialization and before its
first disk mutation. This core performs no disk allocation or target publication.

`build/i386-module-stage-pinned/result.json` proves 253 host HolyC assertions:
six chunk sizes, short/error/thrown writes at four positions, invalid requests,
flush failure, dirty unwind, read failure and release retry. The alternate core
that returns zero on every write is rejected at assertion 2 in
`build/i386-module-stage-pinned-red/guest/debug.log`; its runner exits nonzero.
Both runs use the actual core source in a bootstrap TempleOS guest, not a Python
implementation. The runner pins the core, header, fixture and bootstrap inputs,
requires exactly one 253-check completion marker and rejects failure markers.

Earlier `i386-module-stage-lifecycle` output reported an invalid large counter
and was erroneously accepted by the initial minimum-count checker. That result
is superseded and must not be used as acceptance evidence. Explicit counter
initialization alone did not fix reporting. Executing and reporting from a
function, with an in-guest exact-count condition, produces 253 for the real core
and 2 for the broken writer; the checker now requires the exact count.

This is a transport-independent contract only. Task-owned RedSea reservation,
partial bitmap mutation recovery, cancellation/kill cleanup and BuildModule
integration remain required. Then run the six-provider 16 MiB rebuild and two
installed native generations; their acceptance has not been established.


## Owned RedSea reservation and partial cleanup

`I386RedSeaAllocOwned` uses the same allocation scan as the existing allocator,
but requires a registered zero ownership field and stores the chosen starting
sector before the first bitmap mutation. The field survives failed writes and
cannot be overwritten by a second reservation. `I386RedSeaReleaseOwned` permits
already-clear bits when releasing an exclusively owned, unreferenced range;
ordinary `I386RedSeaFree` retains its strict double-free rejection. Neither
owned API clears the caller's ownership record or performs its final flush.
The caller must retain ownership until clearing and flushing both succeed.

The caller must hold the complete metadata I/O session exclusively. A failed
bitmap operation still invalidates the mounted view. Any remount for cleanup
must remain private/quarantined until all owned reservations are resolved;
these APIs do not authorize exposing the remounted volume to other allocators.
They provide the disk primitive, not task ownership registration or recovery.

The current-source original two-generation bootstrap passes in
`build/rebuild-test/result.json`. The focused native 486/8 MiB allocation run
passes in `build/i386-owned-reservation-green/result.json`, including failures
at both bitmap-write positions, retained ownership, failed partial clearing,
retry and byte-exact restoration of both bitmap sectors. Its manifest pins the
HolyC fixture, allocator, volume, I/O and ATA sources. A controlled alternate
core that records ownership only after bitmap mutation is rejected with case
0 result 0x16 (the fixture's assertion 22) in
`build/i386-redsea-alloc-test/runner.log`; the runner exits nonzero.
`--redsea-alloc-core` allows this mutation without changing production sources.

Native delete and replace regressions pass in their `build/i386-redsea-*-test`
results. The create regression fails with case 0 result 2. A run using the
previous committed allocator also fails with the same result, recorded in
`build/i386-owned-reservation-create-baseline.log`; no create-regression pass
is claimed. Its full-directory validation expectation needs investigation.
The initial pre-implementation run timed out without a compiled module and
is not the authoritative mutation-test evidence.

TaskFiles ownership registration, private remount/retry policy, task kill and
cancel cleanup, chunk transport and BuildModule integration remain next.
The standalone allocation run and x64 bootstrap do not qualify a new full
8 MiB startup image, the six native provider builds or installed generations.


## Task-owned staging and BuildModule integration candidate

The working candidate now registers a staging cleanup resource in TaskFiles.
Directory replacement is rejected while that resource owns the state; clones
start without inheriting it. Destruction calls its cleanup and retains the
state if clearing or flushing fails. Disk access acquires/releases one complete
operation lease per chunk. Cleanup may remount a private view after bitmap
failure, but never republishes that view to other allocators. Active operations
prevent live-state cleanup; finished-task resources remain available to reaping.
No file-state borrow spans the disk acquisition.

BuildModule resolves its canonical target before compiling. It queries the
unit size, writes through a 512-byte scratch buffer, seals the extent, unwinds
the compiler, then reads and validates the module before releasing the extent
and publishing the target. A zero-write, still-open result on a unit no larger
than 64 KiB permits the existing contiguous top-level assembly path. I/O failures
cannot use that fallback. The lifecycle resides in the file provider; the unit
borrows its emit/seal/unwind/readback methods. Counters are U32 after the public
I64 size has passed the existing 32-byte/4-MiB bounds.

Evidence for `i386-task-stage-compact-cross`:

- Original two-generation bootstrap and cross-build pass; the 386 boot audit
  still covers 96 BIOS and 209 protected-mode instructions.
- `build/i386-task-stage-compact-contract/result.json` passes all 253 host HolyC
  assertions. The native ATA/task test and its `ata-task-check.json` pass:
  1,025-byte readback in 17-byte chunks, dirty/unsealed worker-exit cleanup,
  failed cleanup flush with retained ownership, private retry, restored bitmap,
  exact full-disk comparison and the complete command sequence.
- The expanded native corpus required a 320-KiB transfer, heap at 0x60000 and
  segment scratch at 0x70000. Seeded ATA test data starts at sector 768 to keep
  it clear of the image. Its bitmap now accounts for existing local files as
  well as directories/data. Earlier fixture failures are superseded.
- The first integrated image passes full 16-MiB diagnostics, but its 8-MiB boot
  fails a 9,480-byte allocation. Sharing the lifecycle restores boot, but the
  retained-function check fails a 4,116-byte allocation. The compact image also
  boots but rejects the retained static function's 537-byte payload allocation.
  Its focused 8-MiB F64 and assembly runs fail too. No new 8-MiB qualification
  is claimed; the previously qualified phased-header image remains the baseline.
- The six-provider 16-MiB native rebuild is terminal FAIL under
  `build/i386-task-stage-compact-retained-kvm-16m`. ConsoleRuntime reaches
  stage 8 after serialization and compiler unwind, but its 2,286,999-byte
  readback allocation is rejected: heap used 6,845,832 of 14,136,320 bytes,
  largest free block 1,894,424 bytes. The harness rejects the explicit failure
  promptly. All provider and installed-generation gates remain unproven.

The measured resident cost is material: FileRuntime grows from 373,926 to
398,793 bytes and ConsoleRuntime from 2,134,031 to 2,141,928 bytes. Counter
narrowing and moving target normalization to the caller recover only 336 bytes
in FileRuntime. Do not keep tuning those as if they removed the startup cost.
Next inspect the native packing outcome and restore the complete 8-MiB gate.
A structural candidate is loading staging support only for a rebuild, with
explicit kernel-lifetime ownership while tasks may reference its cleanup code;
that would need source/install/generation coverage for the additional module.
Cancellation/kill injection is still required in addition to the verified
ordinary worker-exit cleanup. Two installed native generations remain required.


### Early staging resource candidate

The next candidate prepares the task resource before entering the compiler and
reserves its on-disk extent only after the unit size is known. Zero-byte creation
prepares an unowned, unwritten resource; its reserve method enforces the existing
size bounds before initialization/allocation. Cleanup can release a prepared
resource without touching the disk. This tests whether a late small allocation
was pinning the fragmented region needed for post-unwind readback. It is not a
measured recovery yet. Bootstrap, cross-build, 386 instruction audit, the 969-file delivered-source
audit and both host/native staging contracts pass under
`i386-task-stage-early-resource`. The fresh six-provider 16-MiB rebuild is
running under `i386-task-stage-early-resource-retained-kvm-16m`; inspect its
live handle and terminal result before restarting. The source and installed-generation
acceptance gates remain open, including the independent 8-MiB regression.


The early-resource corpus now exceeds the previous 320-KiB transfer. Its
explicit test-only reservation is 352 KiB, heap at 0x68000 and segment scratch
at 0x74000, still before seeded ATA data at sector 768. Native prepared-state
checks reject writes before reservation and reject a second reservation.
