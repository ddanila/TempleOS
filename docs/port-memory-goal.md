# Bounded-memory self-hosting goal

## Current status (2026-10-09)

Current validator candidate: avoid overlap scans beyond the maximum prior
fixup/range end, and reuse a cursor for ordered data ranges while restarting on
backward references. Unsorted ranges retain the original full scan. This uses
no heap allocation or scratch array. The expanded pre-change validator baseline
passes 56 i386 cases, including reversed ranges, backward/duplicate fixups and
named-pointer boundaries. Original two-generation bootstrap and all 56 optimized
validator cases pass (486,-fpu). All 40 native loader cases also pass. Both the
optimized validator and saved pre-change binary pass the same 176-case corpus,
including all 120 named-pointer record permutations. All 40 portable loader
cases also pass. The fresh thirteen-module cross-build passes in
`build/i386-validator-scan-cross` (551,080 flat-kernel bytes; 386 audit). Emitted
direct-call loader stack usage passes at 16,300/16,384 bytes including the
6,144-byte caller/guard reserve; indirect callbacks still require runtime checks.
Normal cross-built 8 MiB startup passes in 44.67 seconds with all nine checks.
The paired full-native-provider-footprint comparison passes arithmetic/DolDoc
in `build/i386-validator-scan-paired-footprint`: startup improves from 69.25 to
59.02 seconds (10.23 seconds saved). This is diagnostic cross-kernel evidence
with reused native providers and a narrow margin. The 16 MiB diagnostic boot
passes, including publication checks. All 980 delivered source/documentation
files match. The fresh all-seven-provider rebuild is running in
`build/i386-validator-scan-all-providers-16m`, at 16 MiB on TCG/486,-fpu with
14,400-second per-module limits. Its queue freezes Kernel/Compiler/Adam/tool
source hashes and checks them before and after the run. Two installed native
generations and their timing still require qualification. Evidence:
`build/i386-validator-scan-*`; baseline checkpoint:
`build/checkpoints/2026-10-09-validator-scan/manifest.json`.
The dependent two-generation queue is live. After it passes, a sequential
queue checks all four installed images at 8 MiB against the 60-second startup
budget and refreshes floating-point, saved-assembly and provider cancellation,
lifetime, reentrancy and recovery regressions. Queued checks are not passing
evidence. Queue log: `build/i386-validator-scan-final-checks-queue.log`.
The bucket-overflow results below predate this validator change.

Current startup candidate: bucket-local loader overflow fallback retains the
512-slot scratch size. Clean full-native-footprint profiling measures 72.45
seconds: console loading takes about 28.88 seconds, root kernel headers 8.07,
and root user headers 27.48. The expanded differential regression fails before
the loader change at return 602. The first bootstrap rejected a `continue`
statement in the portable branch; an explicit else branch now replaces it.
The portable-branch correction passes the original two-generation bootstrap.
Native test compilation rejects memory/immediate OR; register-based marking
now replaces it, and the fresh original two-generation bootstrap passes.
All 40 native loader cases pass, including six export counts (1, 128, 512,
513, 742, 1025), duplicate rejection without writes and differential lookup.
All 40 portable-index cases also pass. The fresh thirteen-module cross-build
passes in `build/i386-bucket-overflow-cross` (547,792 flat-kernel bytes; 386
instruction audit). Normal cross-built 8 MiB startup passes in 45.41 seconds,
with all nine retained-state/VGA checks. The sequential paired cross-kernel boot
comparison passes arithmetic/DolDoc with identical seven native provider payloads in
`build/i386-bucket-overflow-paired-footprint`. Static analysis
shows 145 console buckets overflow, leaving 1,569 of 5,427 reference records
indexed (about 29% fewer full scans). Paired startup improves from 75.86 to
69.48 seconds (6.38 seconds saved), still above the 60-second gate. This is
diagnostic cross-kernel evidence; native generation timing remains unqualified.
Evidence: `build/i386-bucket-overflow-*`; pre-change checkpoint:
`build/checkpoints/2026-10-09-bucket-overflow/manifest.json`.
The memory-candidate results below predate this loader change.

Current work: the adjacent-span allocator lets both installed self-built
generations rebuild and boot at 8 MiB, but qualification fails because their
kernel and flat boot image differ by 64 bytes; the other twelve modules match.
A fixed-size string initializer overread explains those differences. The fix
passes the original bootstrap rebuild, thirteen-module i386 cross-build, six
initializer regressions and exact persisted array-byte audit. Normal cross-built
8 MiB startup passes in 47.21 seconds with nine runtime/VGA checks and no
build-provider startup load. The interrupted native rebuild preserved ConsoleRuntime (2,240,021 bytes).
Recovery also published CompilerRuntime (1,882,552 bytes), then CompilerProbe
publication failed because the 16 MiB disk had only 645 free sectors for a
2,511-sector output. Filesystem audits show no orphaned allocations.
A 32 MiB recovery disk preserves the boot area and all 1,090 files exactly,
with 33,405 free sectors. All five resumed provider build commands pass at 16 MiB RAM on TCG/486,-fpu.
The combined audit passes for all seven persisted native providers in
`build/i386-string-padding-providers-capacity32-16m`. Two-generation
qualification has started in `build/i386-string-padding-generations-capacity32-16m`.
Generation-one installation and its 8 MiB functional boot pass; startup takes
75.065 seconds and fails the separate 60-second budget. Generation-one
flat-kernel build/link/install commands pass, but the independent 8 MiB
boot rejects DocAllocationCheck with heap exhaustion (8,755-byte request;
8,256-byte largest free block). The generation runner is terminal failed;
generation two did not start.

A backing-padding candidate now returns unused worst-case alignment slack to
its arena before publishing each page extent. The focused reserve regression
fails before the change (return 481) and passes afterward in both native and
portable-source modes. The refreshed original two-generation bootstrap passes.
The accounting check and complete native/portable heap suites also pass. A fresh
thirteen-module port cross-build passes, including the 386 instruction audit
(547,392 flat-kernel bytes). Cross-built 8 MiB startup passes in 46.99 seconds,
with all nine retained-state/VGA checks and no build-provider startup load.
The 16 MiB diagnostic boot passes, including 22 publication and 28 program
publication cases. All 980 delivered source/documentation files match. A native
MemoryRuntime rebuild passes at 16 MiB on TCG/486,-fpu (341,006 bytes;
153 function exports), with persisted output/export validation in
`build/i386-backing-padding-native-memory-16m`. Recovery of the native installed
8 MiB boot with all native providers remains unqualified. The native MemoryRuntime
installation passes exact byte preservation and independent 8 MiB arithmetic/
DocAllocationCheck in `build/i386-backing-padding-native-memory-install`. The queue
passes the flat-kernel build/link/install and independent 8 MiB arithmetic/DolDoc
boot using verified cross-built retained inputs. These are development probes,
not complete seven-provider/two-generation qualification. A dependent diagnostic
probe has repacked the new native boot/kernel and MemoryRuntime with the six
prior native providers, preserving the new boot area and all other files. Its
8 MiB full-footprint arithmetic/DolDoc boot passes in
`build/i386-backing-padding-full-footprint-probe`. Startup is 72.91 seconds,
exceeding the unchanged 60-second gate. Profile startup before expensive fresh
seven-provider/two-generation qualification. This
checks the full native provider footprint before expensive fresh qualification.
It remains mixed-generation diagnostic evidence. Queue log:
`build/i386-backing-padding-install-queue.log`. Evidence is preserved in
`build/checkpoints/2026-10-09-backing-padding/manifest.json`.


The remaining gates are byte-identical installed self-built generations,
installed 8 MiB startup within 60 seconds (previously about 74 seconds), and
refreshing the broader regression evidence for the final candidate. Evidence:
`build/i386-string-padding-*`; checkpoint:
`build/checkpoints/2026-10-09-string-padding/manifest.json`.
Earlier dated entries are historical snapshots.

## Candidate history

Current adjacent-span coalescing candidate: before reserving another small-allocation
page batch, consolidate cached free spans into an address-ordered list and merge
adjacent spans. Preserve requested sizes, eight-byte alignment and heap ownership.
The new regression fails before this change at return 143 (`0x8F`) and passes
afterward, including the 386 instruction audit. Both complete heap suites
(native and portable-source fixtures), refreshed original two-generation bootstrap,
and thirteen-module cross-build pass. Normal 8 MiB startup takes 47.85 seconds;
16 MiB startup diagnostics pass. Native MemoryRuntime rebuild and persisted
export audit pass at 16 MiB on TCG/486,-fpu. A development image using that native
MemoryRuntime with the prior native providers and current cross-built flat kernel
passes arithmetic and `DocAllocationCheck` at 8 MiB. This mixed-provenance probe
is not complete self-host qualification. The fresh all-seven-provider rebuild
passes its complete persisted-output audit at 16 MiB. The two-generation runner
is active; two installed self-built generations and their startup timing remain
unqualified. Artifacts: `build/i386-adjacent-span-merge-*`; checkpoint:
`build/checkpoints/2026-10-08-adjacent-span-merge/manifest.json`.

Current cached-span reuse candidate: public small allocations can split a larger
exact-size cached span before growing another backing batch, preserving the
requested rounding, eight-byte alignment and task ownership. Refreshed original
two-generation bootstrap and thirteen-module cross-build pass. The dedicated
`tools/test-i386.py --heap --heap-cache --qmp-stdio` fixture passes in the 386
guest with its instruction audit: fill one small batch, free one larger span,
allocate a smaller span without additional pages, preserve neighboring data
and ownership, and destroy the heap with exact page recovery. The portable-source variant also passes. The same fixture rejects the
previous allocator at return 135 (`0x87`), detecting additional page growth.
Normal 8 MiB startup passes in 47.90 seconds. The 16 MiB diagnostic startup and nine runtime/VGA commands pass. The
full seven-provider native rebuild passes its persisted export audit at 16 MiB
on TCG/486,-fpu (`i386-cache-span-reuse-all-providers-16m/result.json`).
The initial host audit used the wrong reference directory; audit-only recovery
with the cross-build `exports` directory validates the existing guest outputs.
The two-generation pipeline fails at `gen1-install`: its 8 MiB retained-provider
boot rejects `DocAllocationCheck`, before native flat-kernel rebuilding. The
backing request is `0x2433` (9,267 bytes), with used `0x657990`, capacity
`0x65A600`, largest block `0x5A0` (1,440 bytes), and `0x1FA5` (8,101)
live allocations. Public allocation exhaustion reports request `0x2A8`
(680 bytes). Evidence: `i386-cache-span-reuse-generations-16m/gen1-install/boot/debug.log`.
Cached-span reuse alone does not satisfy the installed-memory gate.
Installed self-built generations and the 60-second installed startup gate
remain unqualified. Candidate artifacts use `build/i386-cache-span-reuse-*`.

Current kernel export-setup candidate: all 72 index/address bindings are
preserved by the source transformation. The refreshed two-generation bootstrap
and thirteen-module cross-build pass, including the 386 instruction audit.
The cross-built flat kernel is 547,280 bytes, 2,144 bytes smaller than the
Console export-setup candidate. Normal 8 MiB startup passes in 47.95 seconds
with nine retained-state/storage/VGA checks, no build-provider startup load,
and the 60-second budget (`i386-kernel-export-setup-boot-8m/result.json`).
The disk also passes its 980-file delivered-source audit
(`i386-kernel-export-setup-source-audit/result.json`). The full seven-provider
native rebuild now passes all seven providers at 16 MiB on `486,-fpu` under
TCG, including persisted export audits and one reused build-provider load
(`i386-kernel-export-setup-all-providers-16m/result.json`). The two-generation
installation pipeline fails at `gen1-selfhost`; installed self-built boot
remains unqualified. The seven native
modules also pass the production executable/data classification and 386
instruction audit, alongside the other cross-built disk modules
(`i386-kernel-export-setup-native-isa-audit/result.json`). This does not qualify
the installed self-built flat kernel. The generation-one retained-module
installation and 8 MiB no-FPU functional boot checks pass; startup takes
74.75 seconds, exceeding the 60-second goal. The generation-one native flat kernel compiles and installs, but its
8 MiB boot rejects `DocAllocationCheck`: the 8,755-byte request exceeds
the largest free block of 5,504 bytes (8,099 live allocations, heap capacity
`0x658E00`). The 512-byte reservation saving is insufficient. Two complete
self-built generations remain unqualified (`i386-kernel-export-setup-generations-16m/gen1-install/result.json`
and `gen1-install/boot/result.json`). ConsoleRuntime now passes its completed native
persistence/export/allocation-wrapper audit: 2,240,021 bytes, 650 exports and
byte-identical output to the previous qualified native Console candidate
(`i386-kernel-export-setup-console-partial-audit/result.json`). CompilerRuntime also passes its completed native persistence/export audit:
1,881,920 bytes, 453 exports and byte-identical output to the previous
qualified native Compiler candidate
(`i386-kernel-export-setup-compiler-partial-audit/result.json`). CompilerProbe also passes its native persistence/export audit: 1,285,621 bytes,
197 exports and byte-identical output to the previous qualified probe
(`i386-kernel-export-setup-probe-partial-audit/result.json`). FileRuntime also passes its native persistence/export audit: 390,335 bytes,
134 exports and byte-identical output to the previous qualified file provider
(`i386-kernel-export-setup-file-partial-audit/result.json`). MemoryRuntime also passes its native persistence/export audit: 334,252 bytes,
151 exports and byte-identical output to the previous qualified memory provider
(`i386-kernel-export-setup-memory-partial-audit/result.json`). BuildRuntime and Startup also pass the completed full-build audit. The direct native Kernel measurement passes its
persistence and export contract: 552,400 payload bytes, a 776-byte saving
(`i386-kernel-export-setup-native-kernel/result.json`). Installed boot remains
unqualified. A static estimate with unchanged boot helpers gives a 553,056-byte
flat image and a 553,472-byte sector-rounded reservation, 512 bytes below
the previous native Kernel estimate. This is not installed-boot evidence
(`i386-kernel-export-setup-native-kernel/reservation-estimate.json`). The 16 MiB
no-FPU diagnostic suite also passes its publication and nine runtime/VGA
checks (`i386-kernel-export-setup-diag-16m/result.json`). The 8 MiB
software-F64/retained-static regression also passes
(`i386-kernel-export-setup-float-8m/result.json`). Saved assembly also
passes compilation, persistence and interrupt-state restoration at 16 MiB
(`i386-kernel-export-setup-bare-16m/result.json`). Public Kill after
compiler module-control activation also passes at 16 MiB: child retirement,
absent cancelled output, successful subsequent build, one provider load and
matching filesystem bitmap (`i386-kernel-export-setup-cancel-16m/result.json`).
Provider service-version rejection and in-guest repair/retry also pass at
16 MiB: two rejections, two successful builds, one provider load and
byte-identical restoration (`i386-kernel-export-setup-recovery-version-16m/result.json`).
The wrong-target rejection/repair variant also passes the same two-rejection,
two-build and byte-identical restoration contract
(`i386-kernel-export-setup-recovery-target-16m/result.json`). The
missing-import variant passes the same rejection/repair/reuse contract
(`i386-kernel-export-setup-recovery-import-16m/result.json`). Provider
lifetime also passes first use in a child, two natural child exits, three
child/parent builds, one provider load and second-child public pool recovery
at 16 MiB (`i386-kernel-export-setup-lifetime-16m/result.json`). Recursive acquisition during initialization also passes: one nested rejection,
two successful builds and one cached provider load at 16 MiB
(`i386-kernel-export-setup-reentrant-16m/result.json`). Installed self-built
boot remains unverified.
The current diagnostic log also passes unchanged production assertions for
branch recovery, optimizer/emitter/backend completion, all 44 expression cases,
parser memory/token ownership and two-phase in-memory native bundle, loader
and allocator execution (`i386-kernel-export-setup-diagnostic-core-audit.json`).
This is not the entire comprehensive suite or installed-generation evidence.
The current persistence probes pass both 16 MiB no-FPU boots: native bundle,
loader and allocator disk publication, reuse after reboot, strict structural
audits, unchanged module hashes and prompt/VGA checks. This is not installed
self-built-generation acceptance
(`i386-kernel-export-setup-persisted-probes-16m/result.json`).
The strict production host auditors accept four current persisted native
fixtures and reject all 52 damaged variants (13 per module); this verifies
host rejection behavior, not guest execution
(`i386-kernel-export-setup-native-audit-regression.json`).
Evidence is under `build/i386-kernel-export-setup-*`. Earlier candidate results
below retain their original source scope.

Latest qualified startup candidate: `i386-managed-build-yield-cross`.
Its thirteen-module cross-build, strict thirty-import provider audit, 386
instruction audit and 980-file source audit pass. Normal 8 MiB startup passes
in 49.78 seconds with all nine retained-state/VGA checks and no provider load.
Active-compiler public Kill now passes at 16 MiB: retirement, no cancelled
output, subsequent build, one cached provider load and an independent volume
audit all succeed. Saved assembly also passes all thirteen commands at 16 MiB
(`build/i386-managed-build-yield-bare-16m/result.json`), including persistence
and interrupt-state restoration. The sixteen-command software F64 regression
also passes at 8 MiB (`build/i386-managed-build-yield-float-8m/result.json`).
The 16 MiB diagnostic suite passes all fifty publication cases and nine
retained-state/VGA checks without loading the build provider. Malformed service
version, wrong-target and missing-import rejection/repair all pass on this
candidate. Provider lifetime across natural child exit and child/parent reuse
also passes, including exact public task-pool recovery. Recursive acquisition
during initialization is rejected safely; its guest-built BuildRuntime fixture
passes a fresh boot and two cached builds. The largest provider, ConsoleRuntime,
now builds and persists at 16 MiB with its export/allocation-wrapper audits
passing (2,266,385 bytes). CompilerRuntime persistence also passes its layout
and export contract (1,881,920 bytes, 453 exports); both outputs match the
earlier native module bytes.
Full seven-provider qualification passes in
`i386-managed-build-yield-all-providers-16m` at 16 MiB on TCG/486,-fpu,
including all persisted export contracts and one reused provider load.
The two-generation runner in `i386-managed-build-yield-generations-16m`
passes its 980-file input-source/volume audit but fails generation-one installed
boot at 8 MiB: a 4 KiB allocation for keyboard startup exhausts the heap after
startup source initialization. Successive installed generations remain unproven.
The shared export-setup candidate passes bootstrap and its thirteen-module
cross-build. Normal 8 MiB startup passes in 47.85 seconds with all nine
retained-state/VGA checks and no build-provider load
(`build/i386-console-export-setup-boot-8m/result.json`). Its cross-built Console
payload is 2,043,552 bytes, 272 bytes smaller than the previous candidate.
Console native persistence now passes its layout, 650-export contract and
allocation-wrapper audit (`i386-console-export-setup-console-partial-audit`).
Its payload is 2,057,184 bytes, 18,984 bytes smaller than the previous native
candidate. Its executable/data classification and 386 instruction audit also
pass (`i386-console-export-setup-console-isa-audit`), with other modules still
cross-built in that audit. Current Compiler native persistence now also passes
its layout and 453-export contract, with byte-identical output to the previous
native candidate (`i386-console-export-setup-compiler-partial-audit`).
CompilerProbe persistence also passes its layout and 197-export contract,
with byte-identical output to the previous native candidate
(`i386-console-export-setup-probe-partial-audit`). The complete seven-provider
native rebuild now passes at 16 MiB on TCG/486,-fpu, including persisted layouts,
export contracts, Console allocation wrappers and one reused build-provider load
(`i386-console-export-setup-all-providers-16m/result.json`). All six outputs
other than Console are byte-identical to the previous native candidate.
The current seven native modules also pass executable/data classification and
386 instruction auditing with the cross-built flat kernel
(`i386-console-export-setup-native-isa-audit/result.json`). The two-generation
runner now passes generation-one retained installation and its 8 MiB boot,
including `6*7` and `DocAllocationCheck`
(`i386-console-export-setup-generations-16m/gen1-install/result.json`).
This clears the previous keyboard-startup allocation failure for the current
native providers. Installed startup took 73.94 seconds: the functional
installation check passes, but this does not qualify the 60-second startup
budget for installed native providers. The cross-built normal boot remains
qualified at 47.85 seconds. Generation-one native Kernel persistence passes its layout and 265-export
contract (`i386-console-export-setup-gen1-kernel-partial-audit/result.json`).
The run completes all flat-component builds, boot-image construction and
installation, but generation-one self-built-kernel boot fails
`DocAllocationCheck` at 8 MiB. Startup and keyboard creation succeed; the
probe requests 8,755 bytes with 15,008 unused arena bytes including headers and a largest free
span of 4,992 bytes. The native-kernel heap capacity is `0x658C00`,
4 KiB below the retained-install boot capacity. The pipeline is terminal
FAIL at `gen1-selfhost`; no second generation was launched. Preserve this
evidence and improve memory headroom without changing RAM or stack limits.
Two complete installed self-built generations remain unverified.
The shared export-setup candidate also passes public compiler-phase Kill and
subsequent build at 16 MiB, the sixteen-command software F64 regression at
8 MiB, and all thirteen saved-assembly commands at 16 MiB. Evidence is under
`build/i386-console-export-setup-{cancel-16m,float-8m,bare-16m}/result.json`.
All three malformed-provider cases pass: service version, wrong target and
missing import (`build/i386-console-export-setup-recovery-*-16m/result.json`).
Each verifies two rejections, in-guest repair, two successful builds, one
cached provider load and byte-identical provider restoration.
The current 16 MiB diagnostic suite passes all fifty publication cases and
nine retained-state/VGA checks with zero provider loads
(`build/i386-console-export-setup-diag-16m/result.json`). Diagnostic startup
takes 207.18 seconds; the normal-startup time gate is qualified separately.
Provider lifetime also passes at 16 MiB: first use in a child, two natural
child exits, three successful child/parent builds, one provider load and exact
second-child public pool recovery
(`build/i386-console-export-setup-lifetime-16m/result.json`).
Recursive acquisition during initialization passes on a fresh boot with a
guest-built fixture: one nested rejection, one provider load and two cached
successful builds (`build/i386-console-export-setup-reentrant-16m/result.json`).
The original persistence-enabled probes pass two boots at 16 MiB: native
bundle/loader/allocator modules are written, reloaded and executed, then
executed from the previous boot and replaced with identical bytes
(`build/i386-console-export-setup-persisted-probes-16m/result.json`).
All twenty single-disk persisted-module host audits pass. Four current-source
linkage audits now check exact export/call contracts and callback relocations;
`tools/test-i386-native-audits.py` accepts the four real fixtures and rejects
fifty-two damaged variants. This does not qualify installed self-built
generations or the entire comprehensive suite.

Earlier qualified runtime snapshot: `i386-lazy-orchestration-cross`.
Bootstrap, thirteen-module cross-build, 386 instruction audit and the 980-file
source audit pass. Normal 8 MiB startup passes in 48.02 seconds with all nine
retained-state/VGA checks and no build-provider loading. The sixteen-command
8 MiB F64 regression and full 16 MiB diagnostics pass. Saved assembly and
persistence pass thirteen commands at the 16 MiB native-build profile; the same
fixture's 8 MiB persistence attempt cannot allocate the build provider.

BuildRuntime first-use rebuilding passes under TCG/486,-fpu at 16 MiB: Startup
and BuildRuntime are persisted with the expected export sets and exactly one
provider load reused across both commands. The full seven-provider rebuild
passes in `build/i386-lazy-orchestration-all-providers-16m`: all seven persisted
module layouts/export contracts, ConsoleRuntime allocation-wrapper calls and
one cached provider load pass at 16 MiB on TCG/486,-fpu. This qualifies the
earlier frozen source only. Two installed thirteen-module generations remain
unproven. Lazy provider API-version rejection and in-guest repair/retry pass at 16 MiB
(`i386-lazy-provider-recovery-v3-16m`): two rejected attempts, two successful
builds, one provider load, identical output copies and unchanged input disk.
Provider lifetime across natural public child-task exit also passes
(`i386-lazy-provider-lifetime-16m`): first-use in a child, two child exits,
three identical child/parent outputs, one load, and second-child public pool
restoration. Synchronous initializer reentrancy also passes with a guest-built wrapper
on a fresh boot (`i386-lazy-provider-reentrant-v2-16m`): one nested rejection,
one outer provider load and two successful identical Startup builds. Forced
cancellation and faulted cleanup lifetime still need final acceptance coverage. The previous integration
image persisted its 2.3 MB ConsoleRuntime, but its remaining KVM run was
interrupted by an execution-environment change. KVM is currently unavailable.

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

### Queued staging cancellation verified

The native ATA/task fixture now holds the disk lease in the root task while a
worker prepares a staging resource and blocks attempting its reservation.
Live destruction rejects the active resource. Cancelling the queued wait lets
the worker return with failed, still-owned staging state; reaping then restores
the exact heap counters without disturbing the root lease or leaving a waiter.
The complete ATA command trace and both full backing disks remain checked.
`build/i386-ata-tasks-test/result.json` and `ata-task-check.json` are terminal
PASS on 486 with 8 MiB. The fixture includes and pins WaitCancel.HC; its initial
missing-implementation compilation failure is superseded. This covers queued
wait cancellation, not public Kill or cancellation during a transfer. The
six-provider early-resource build remains live; no memory recovery is claimed.

### Early resource result — contiguous readback remains the blocker

The early-resource rebuild is now terminal FAIL in
`build/i386-task-stage-early-resource-retained-kvm-16m/result.json`.
ConsoleRuntime completes serialization and compiler unwind, then rejects the
2,287,183-byte stage-8 readback allocation. Heap use is `0x687B38`, capacity
`0xD7B400`, and largest free block `0x1D9D40`. Both worker and QEMU processes
have exited. Preparing the small staging record earlier did not recover the
required contiguous region; do not repeat this experiment or increase the
acceptance memory profile.

Next architecture work must remove the whole-module readback requirement:

1. Add bounded random reads of sealed, cleanly unwound staging output. Check
   offsets and lengths before I/O, retain ownership on failure, and preserve
   cancellation and complete lease cleanup. Test sector crossings, final bytes,
   short/error reads and queued cancellation before BuildModule integration.
2. Reuse `I386ModuleValidParts` with staged code reads and bounded metadata.
   Header arithmetic must be validated before allocating or reading metadata.
   Read failures must reject the unit even if the byte callback returns zero;
   cache sectors to avoid one disk transaction for every relocation byte.
3. Publish validated staged data without a whole-image heap buffer. Preserve
   data-before-directory flush ordering and existing replacement semantics.
   If a directory write or flush can have published an extent, cleanup must
   never free that potentially referenced extent. Keep ambiguous ownership
   quarantined until authoritative recovery determines publication state.
   Test faults before publication, during directory write/flush, and during
   old-extent reclamation; verify whole disks, bitmap and retry behavior.
4. Integrate the bounded path into BuildModule, restore the independent 8-MiB
   startup/retained-state/F64/assembly gates, then rerun all six providers at
   16 MiB and two installed native generations. Avoid adding permanently
   resident staging support without measuring its startup cost; lazy loading
   remains an option with explicit code lifetime and installation coverage.

The existing complete-buffer validation/publication path remains useful for
small assembly units, but cannot qualify the largest provider within this
fragmented heap. No native-generation or current-candidate 8-MiB pass is claimed.

### Bounded staged reads — native foundation verified

Task staging now supplies `read_range` through its private borrowed method
table. It accepts only owned READY units, nonzero buffers/lengths, lengths up
to 4096, and subtraction-checked ranges within the unit. Successful random
reads keep READY for repeated validation; short/error reads set FAILED while
retaining the extent for cleanup. The transport shares the existing lease and
IRQ restoration path with whole-unit reads and allocates no readback buffer.

Native evidence: `build/i386-ata-tasks-test/result.json` and
`ata-task-check.json` pass on 486/8 MiB. Eight invalid state/range requests
issue no extra ATA commands. A 17-byte read at offset 507 crosses a sector,
and offset 1024 reads the final byte of a 1025-byte unit. Two injected transport
faults reject both a no-data error and a partial read, preserve ownership,
release the lease, reject further reads and restore exact heap counters after
cleanup. Complete command tracing and full backing-disk comparison pass.
Original two-generation bootstrap and all 253 host lifecycle assertions also
pass (`build/rebuild-test/result.json`,
`build/i386-task-stage-range-contract/result.json`). The initial attempt was
rejected by the stale-bootstrap source guard, not an executed red contract.

BuildModule has not switched to bounded validation/publication yet. The
current full-image 8-MiB gate, cancellation during a range read, publication
faults, six native providers and installed generations remain required.

### Staged validation core — host contract verified

`Kernel/I386/ModuleStageCheck.HC` validates header arithmetic before reading
metadata, reads metadata in chunks no larger than 4096, and passes the existing
`I386ModuleValidParts` rules a 512-byte cached code reader. The caller supplies
only metadata storage; the validator never allocates or reads a whole code
image. Transport failure is independently latched so zero returned after a
failed read cannot be accepted as a zero relocation. Successful validation
retains READY and ownership for the forthcoming publication step.

`tools/test-i386-module-stage.py --validation --out <fresh-directory>` executes
the actual shared core with pinned sources. The final host contract passes all
46 assertions under `build/i386-stage-validation-contract-v5/result.json`:
12 malformed header variants, insufficient metadata capacity, invalid state,
bad relocation/name bytes, four read failure positions, cached relocation
reads crossing a sector, and metadata spanning two chunks. Removing the
explicit cache failure check is rejected at assertion 11 under
`build/i386-stage-validation-mutant-v2`. Earlier attempts with an uninitialized
counter and a conditional expression in the fixture are superseded; the final
fixture initializes counters and uses ordinary if/else branches.

This core is not yet linked into a resident provider or BuildModule. Next
qualify it as native i386 code, then implement fault-tested bounded publication
and switch BuildModule to metadata-only validation. No native rebuild,
publication, installed-generation or full-image memory pass follows from this
host contract.

### Staged validation — native contract and disk connection verified

The same Validation.HC contract now runs inside the native ATA/task corpus.
It uses small fixture copy/set helpers and a native assertion counter rather
than host exception/reporting calls. All 46 checks pass as i386 code on
486/8 MiB, including cached relocation reads and injected reader failures.
The host form also passes all 46 under
`build/i386-stage-validation-shared-host/result.json`.

The disk fixture additionally writes a valid 1025-byte, zero-record module,
unwinds its stage and validates it through the real `read_range` transport
using only nine bytes of metadata storage. That metadata crosses a sector
boundary. Full backing disks and the complete ATA command sequence are checked.
Terminal evidence: `build/i386-ata-tasks-test/result.json` and
`ata-task-check.json`, final runner log
`build/i386-stage-validation-native-v6.log`. Real-disk relocation validation
is not claimed by this zero-record connection test; relocation/cache failures
are covered by the shared native mock-reader contract.

The expanded corpus exceeded its old transfer reservation. The explicit
test-only limit is now 800 sectors (400 KiB), heap at 0x74000, segment records
at 0x80000, and patterned test data starting at sector 1024. The test initially
needed an explicit fixture ISO overlay; a later trace expectation omitted the
second sector of the metadata tail. These harness failures are superseded by
the final pass. OS memory acceptance remains 8 MiB boot / 16 MiB rebuild.

Next implement bounded publication with ownership retained across ambiguous
directory write/flush failures, then integrate the validated staged path into
BuildModule. The resident footprint and complete native-generation gates still
need qualification; native validation alone does not recover the memory goal.

### Publication ownership core — host failure contract verified

`ModulePublishCore.HC` is an allocation-free transaction core with PREPARED,
UNCERTAIN, COMMITTED and DONE states. It flushes staged data before publication,
sets UNCERTAIN before calling the directory writer, and retains the staging
extent on ambiguous write/flush failure. Recovery flushes pending writes before
an exact old/new directory-slot observation. Confirmed old state returns to
PREPARED, permitting staging abort; conflicting or failed observations retain
UNCERTAIN. Confirmed new state clears the caller's owned-block field before
reclaiming the old extent. Failed/thrown reclamation retains COMMITTED for
idempotent retry; repeated DONE calls perform no I/O.

Caller obligations: hold the complete-operation disk lease; retain the stable
record and owned-block field; quarantine ambiguous shared volume state; observe
the exact saved old/new slot (return neither on read failure/conflict); and make
old-extent reclamation idempotent through its final flush. Task cleanup must
refuse to release the staged extent while UNCERTAIN and retain the record while
COMMITTED reclamation remains unfinished. These obligations are not yet wired
to RedSea or task reaping.

Host evidence: `build/i386-stage-publication-contract-v2/result.json` passes
33 assertions covering initial flush rejection, directory writes failing
before/after modification, flush failure before/after persistence, failed
recovery flush, old/new/conflicting/failed observations, reclamation retry and
thrown write/reclaim callbacks. The contract exposed a null-pointer guard in
the first attempt; the explicit guard is now fixed. A mutation that delays
UNCERTAIN until after the write is rejected at assertion 6 under
`build/i386-stage-publication-late-mutant`.

Run with `tools/test-i386-module-stage.py --publication --out <fresh-directory>`.
This proves the shared host lifecycle, not native directory mutation, disk
fault handling or BuildModule memory recovery. Next add the RedSea slot
transport and native fault tests, integrate task cleanup, and connect bounded
validation/publication to BuildModule before full memory qualification.

### RedSea publication transport — native disk fault contract verified

`RedSeaPublication.HC` connects the ownership core to a resolved directory slot.
It saves the exact old/new 64-byte entries, verifies the old entry again before
writing, preserves neighboring entries, and observes exact old/new state during
recovery. Initialization rejects directories, invalid extents and overlapping
old/new data. Committed old extents use owned, idempotent bitmap clearing and a
final flush. Recovery uses a persistent private mounted view; a blocked callback
never borrows a stack mount, and the shared volume remains quarantined until
explicit recovery/remount. The caller must hold the complete disk lease and
resolve a valid regular-file slot; this helper does not yet resolve paths or
grow directories.

Native terminal evidence: `build/i386-ata-tasks-test/result.json` and
`ata-task-check.json` pass on 486/8 MiB, final log
`build/i386-redsea-publication-native-v4.log`. Coverage includes one empty-slot
creation, one replacement, and five faults: initial data flush, directory write
before mutation, successful directory mutation reported as failure, directory
flush failure, and old-extent reclamation flush failure. Tests check quarantine,
old/new ownership, abort eligibility, recovery and exact bitmap state. They
verify neighboring entries before safely restoring fixture metadata; complete
ATA tracing and full backing-disk comparisons pass, alongside existing staged
read/validation/cancellation checks.

The test-only boot reservation is now 864 sectors (432 KiB), heap at 0x7C000 and
segment records at 0x88000; patterned data still starts at sector 1024. The
larger corpus exceeded the previous reservation. The creation fixture's direct
string indexing entered the bootstrap debugger; using a pointer variable fixed
that fixture expression. These attempts are superseded by the final pass.

The publication record is currently owned by the test caller, not TaskFiles.
Task cleanup must be integrated to block staged-extent release while UNCERTAIN
and retain pending old reclamation while COMMITTED. Native conflicting-slot,
partial-reclamation and interrupted-task cases, path/slot preparation including
directory growth, and BuildModule integration remain required. No complete
native build or current-source 8-MiB startup recovery is claimed.

### Task-owned publication cleanup — native and full-image checkpoint

Staging now has an optional registered publication cleanup resource. Release
resolves that resource before inspecting the staging block, including when
the block is already zero but old-extent reclamation remains unfinished.
`TaskModulePublication.HC` allocates a heap-owned publication record, registers
its callback before initialization, and retains it across failed recovery.
UNCERTAIN and COMMITTED cleanup obtains the complete disk lease directly,
recovers through the persistent private mount, and frees the record only after
confirmed old state or completed new-state reclamation. Unpublished preparation
can abort safely. Publication callback code must have kernel lifetime while a
record refers to it; the creator/provider is currently compiled into the native
test corpus, while the release hook is integrated into FileRuntime.

Native terminal evidence is `build/i386-ata-tasks-test/result.json` and
`ata-task-check.json`, final log
`build/i386-task-publication-worker-native-v2.log`. Four cleanup attempts defer
while the root holds the disk lease, then four task-resource cleanups recover
the publication after that lease is released. Tests inspect the resulting
directory and exact bitmap before restoring fixture state, proving cleanup
does not free the published fresh extent. A worker also exits after a directory
write changes disk state but reports failure. TaskDestroy recovers its
heap-owned publication after worker completion, restores exact heap counters,
and leaves the fresh extent referenced and reserved. Whole disks and complete
ATA command traces pass. The test-only transfer is now 896 sectors (448 KiB),
heap at 0x80000 and segment records at 0x8C000, with data at sector 1024.

File-service version is now 50, still 120 bytes, to guard the changed private
staging layout against mixed provider versions. Original two-generation
bootstrap, `build/i386-task-publication-cross`, 96 BIOS / 209 protected-mode
instruction audits and the 976-file delivered-source audit pass.
`build/i386-task-publication-diag-16m/result.json` passes full diagnostic
startup and storage/presentation/runtime/VGA checks. The fresh 8-MiB image
is terminal FAIL in `build/i386-task-publication-boot-8m/result.json`: a 4096-byte
request with heap used `0x657B10`, capacity `0x65B400` and largest span `0x7E0`,
before the retained-state acceptance commands. No 8-MiB recovery is claimed.

Next provide path/slot preparation including directory growth, wire the
publication creator into a provider with explicit code lifetime, and replace
BuildModule's whole-image readback/publication with metadata-only validation
and staged ownership transfer. Then restore startup footprint and qualify six
native providers plus two installed generations. Public Kill and cancellation
during publication, conflicting native slots and partial reclamation still
need targeted coverage; ordinary finished-worker recovery is now verified.

The lazy-provider recovery regression can be run with:

```sh
python3 tools/test-i386-build-provider-recovery.py \
  --disk build/i386-lazy-orchestration-cross/kernel.img \
  --out build/i386-lazy-provider-recovery-v3-16m
```

It mutates only a disposable copy, rejects a provider service-version mismatch,
repairs the provider in the running guest, and requires successful retry and
reuse with independently inspected persisted outputs. The v3 run passes at 16 MiB under TCG/486,-fpu. Two rejected attempts are
followed by two successful builds, with one provider load. The provider is
restored byte for byte, output export contracts match the installed reference,
and the input disk is unchanged. This is not evidence for cancellation,
reentrant acquisition, or general allocation reclamation.

The same recovery runner also accepts `--fault wrong-target` and
`--fault missing-import`. Wrong-target recovery passes under the same 16 MiB
TCG/486,-fpu profile (`build/i386-lazy-provider-wrong-target-16m/result.json`).
Unresolved-import recovery also passes in
`build/i386-lazy-provider-missing-import-v2-16m/result.json`. Both cases verify
two rejected attempts, guest repair, two successful builds, one provider load,
matching persisted output contracts, and an unchanged input disk.

Provider code lifetime after normal public task exit has a separate regression:

```sh
python3 tools/test-i386-build-provider-lifetime.py \
  --disk build/i386-lazy-orchestration-cross/kernel.img \
  --out build/i386-lazy-provider-lifetime-16m
```

The run passes under TCG/486,-fpu at 16 MiB. It verifies first-use inside a
child, natural child retirement, reuse from a second child and the parent,
three identical persisted Startup modules, one provider load, and public
task-pool restoration after the second child. It does not prove forced cancellation or global kernel-heap
reclamation.

Recursive acquisition during initialization has a disposable provider fixture:

```sh
python3 tools/test-i386-build-provider-reentrant.py \
  --disk build/i386-lazy-orchestration-cross/kernel.img \
  --out build/i386-lazy-provider-reentrant-v2-16m
```

The v2 run passes at 16 MiB under TCG/486,-fpu. It guest-builds and installs
a disposable copy of the real provider with its initializer renamed directly
and a recursive wrapper appended, then boots afresh. The initializer must observe a rejected
nested acquisition before it publishes its services, and two builds must reuse
one cached load. This targets synchronous initializer reentrancy, not forced
cancellation or concurrent scheduler interleavings.

For forced-cancellation qualification, the useful public checkpoint is a live
child whose compiler-control chain was empty on entry and whose `last_cc`
moves away from its empty-chain sentinel (`&child->next_cc`) inside
I386BuildModule. The console exposes CCmpCtrl opaquely,
so the fixture deliberately does not inspect its private flags. BuildModule registers its
staging resource before opening that control. The focused Kill fixture
must observe that checkpoint before requesting cancellation, verify retirement
and absence of a published output, then rebuild successfully and independently
inspect the volume. Merely killing a queued child or sleeping before entering
the builder does not qualify active staging cleanup. The current natural-exit
fixture does not cover this case. Boot-module builds disable generated execution
break polling; public Kill uses its own task termination policy, so a Break
fixture cannot stand in for Kill coverage.

The active-compiler public Kill regression is now implemented:

```sh
python3 tools/test-i386-build-provider-cancel.py \
  --disk build/i386-lazy-orchestration-cross/kernel.img \
  --out build/i386-lazy-provider-cancel-v5-16m
```

Its initial run is pending. It observes the module compiler control before Kill,
requires retirement without returning from the build, checks that no cancelled
output exists, then builds Startup and audits the writable volume. It does not
qualify cancellation during owned-extent writes or publication.

The current unqualified candidate adds cooperative managed-Yield checkpoints
after frontend setup and between completed BuildModule commands. Cancellation
v5 confirmed a Kill request against an active compiler control but timed out
while the child continued compiling. The MemoryRuntime binding of I386SchedYield
performs pending public task exit; the build provider now imports that existing
binding and calls it outside parser calls and disk leases. Its import audit
requires thirty imports. Bootstrap is running under the
`i386-managed-build-yield` prefix. Existing lazy-orchestration runtime passes and
the still-live seven-provider run describe the earlier frozen source snapshot;
new-source cancellation, normal startup, complete rebuilding and installed
successive generations remain unqualified.

Managed-Yield saved-assembly qualification is terminal PASS at 16 MiB
(`build/i386-managed-build-yield-bare-16m/result.json`) on TCG/486,-fpu.
All thirteen commands pass, including bare and block PUSHFD/CLI/POPFD,
persisted relocation-free module execution, included HolyC interrupt-state
restoration and exact VGA checkpoints. This qualifies the current candidate's
saved-assembly behavior; it does not prove the full seven-provider rebuild or
successive installed generations.

Managed-Yield F64 context qualification is terminal PASS at 8 MiB
(`build/i386-managed-build-yield-float-8m/result.json`) on TCG/486,-fpu.
All sixteen commands pass: runtime integer/F64 conversion, truncation,
arithmetic, modulus, sqrt/abs, comparison and retained floating static state.
Exact VGA checkpoints pass; startup is 49.47 seconds. This is focused software
floating-point coverage, not exhaustive IEEE conformance. Current-source
16 MiB startup/publication diagnostics and malformed-provider service-version
recovery are running; neither is yet qualified. Full rebuilding and installed
generations remain open.

Managed-Yield provider service-version recovery is terminal PASS at 16 MiB
(`build/i386-managed-build-yield-recovery-version-16m/result.json`). Two
malformed-version acquisitions are rejected; in-guest repair restores the
provider byte identically; two subsequent native Startup builds succeed using
one cached provider load. Wrong-target and missing-import rejection/repair
runs are now live for this same source candidate. This result does not qualify
full rebuilding or successive installed generations.

Managed-Yield 16 MiB diagnostics are terminal PASS
(`build/i386-managed-build-yield-diag-16m/result.json`): all 22 class-publication
and 28 program-publication cases, nine retained-state/VGA commands and zero
build-provider loads. Diagnostic startup takes 223.41 seconds; the 60-second
gate applies to normal 8 MiB startup, which already passes independently.
Wrong-target and missing-import provider rejection/repair are also terminal
PASS in `i386-managed-build-yield-recovery-wrong-target-16m` and
`i386-managed-build-yield-recovery-missing-import-16m`: each rejects twice,
restores the provider byte identically, then completes two builds using one
cached provider load. All three malformed-provider cases now pass on the
current candidate. Full seven-provider rebuilding and two successive installed
self-built generations remain unverified.

Managed-Yield provider lifetime is terminal PASS at 16 MiB
(`build/i386-managed-build-yield-lifetime-16m/result.json`). First acquisition
occurs in a child; two children exit naturally; another child and the parent
reuse the same cached provider. All three persisted Startup outputs are byte
identical and match the installed export contract. The second child's public
task-pool used/reserved counts return exactly to their pre-spawn values, with
one provider load and the input disk unchanged. This covers natural exit and
public task-pool recovery, not all kernel-heap ownership or faulted cleanup.
Recursive-initialization testing and full current-source native rebuilding
remain live; two successive installed generations remain unverified.

Managed-Yield recursive provider initialization is terminal PASS at 16 MiB
(`build/i386-managed-build-yield-reentrant-16m/result.json`). The guest compiles
and installs a disposable copy of the current BuildRuntime with a recursive
initializer wrapper, then boots afresh. Nested acquisition is rejected once
before the outer provider is published; two subsequent Startup builds reuse
one cached provider and produce identical modules with the reference export
contract. The input disk remains unchanged. This also demonstrates native
compilation/persistence of the current BuildRuntime implementation with the
fixture wrapper; it does not replace the exact seven-provider rebuild gate.
Full native rebuilding and two installed self-built generations remain open.

The earlier frozen lazy-orchestration seven-provider run has persisted
ConsoleRuntime at 16 MiB and advanced to CompilerRuntime. The independent
`build/i386-lazy-orchestration-all-providers-16m/console-persisted-audit.json`
passes: 2,266,385 bytes, 6,606 records, 649 exports, exact reference export set,
and required document allocation-wrapper calls. This is evidence for that
older source snapshot only. The full run remains live; current managed-Yield
ConsoleRuntime persistence and complete seven-provider rebuilding remain
unqualified, as do successive installed generations.

The earlier frozen lazy-orchestration run also persists CompilerRuntime at
16 MiB. `build/i386-lazy-orchestration-all-providers-16m/compiler-persisted-audit.json`
passes the retained-module record layout and reference export contract:
1,881,920 bytes, 4,092 records, 453 exports; only the two cross-build division
boundary markers are absent, as allowed by the existing native-build contract.
This qualifies that older CompilerRuntime output only. The full run remains
live, as does current managed-Yield ConsoleRuntime packing; complete current
seven-provider rebuilding and successive installed generations remain open.

Current managed-Yield ConsoleRuntime persistence is independently qualified at
16 MiB on TCG/486,-fpu:
`build/i386-managed-build-yield-all-providers-16m/console-persisted-audit.json`
passes with 2,266,385 bytes, 6,606 records, 649 exports, exact reference export
set and required document allocation-wrapper calls. Its module bytes are
identical to the earlier lazy-orchestration native output. This proves the
largest provider's bounded build/persistence on the current source, not the
complete seven-provider run or installed generations; the full run remains live.

Installed-heap capture follow-up (same kernel export-setup image, 8 MiB,
TCG/486,-fpu): after `6*7`, the validated physical block chain has 8,283
blocks, including 205 free blocks totaling 27,520 bytes with headers and a
14,640-byte largest free payload. After the rejected `DocAllocationCheck`,
the capture has 205 free blocks totaling 18,744 bytes with headers and a
5,864-byte largest free payload. Exactly one changed retained block remains:
span 8,776, requested 8,755, at physical address 8,242,880. These are
post-command captures, not the instantaneous failure trace. Artifacts are
`build/i386-kernel-export-setup-installed-heap-snapshot/heap-layout.json`
and `build/i386-kernel-export-setup-installed-heap-failure-snapshot/heap-layout-comparison.json`.
The public allocator caches small allocations by exact size and obtains
16-page batches when no suitable cached span exists. Investigate retained
batch utilization before changing backing placement or reservation; preserve
public allocation rounding, task ownership and document failure atomicity.

Heap-suite packaging follow-up: the aggregate runner exceeded its fixed BIOS
transfer size after the allocator grew. `--heap` now runs the same arena and
public assertions in separate core/public fixtures plus the new cache fixture,
then records an aggregate result. Dedicated core assertions pass both normal
and portable-source paths; the full public/region/backing fixture passes the
normal path and its 386 instruction audit. The portable public fixture and
actual default aggregation run pass; the default portable-source aggregate
command also passes. Both aggregate commands preserve all arena/public/cache
assertions in bounded runners. The first public split omitted
its shared Hash helper and stopped in the guest compiler debugger; that wiring
error is fixed. These harness changes do not modify the frozen candidate OS.

Current adjacent-span coalescing candidate also passes saved assembly at 16 MiB
on TCG/486,-fpu: all thirteen commands, persisted bare/block assembly modules,
and interrupt-state restoration. Evidence:
`build/i386-adjacent-span-merge-bare-16m/result.json`.
This is a focused regression pass; complete provider rebuilding and both
installed self-built generations remain unqualified.

Current adjacent-span coalescing candidate also passes the sixteen-command
software F64 and retained-static-state regression at 8 MiB on TCG/486,-fpu.
Evidence: `build/i386-adjacent-span-merge-float-8m/result.json`.
This does not qualify installed self-built generations.

Current adjacent-span coalescing candidate passes public compiler cancellation
and provider lifetime/reuse regressions at 16 MiB on TCG/486,-fpu. Both complete
with successful follow-up commands and persisted-output audits. Evidence:
`build/i386-adjacent-span-merge-cancel-16m/result.json` and
`build/i386-adjacent-span-merge-lifetime-16m/result.json`.
Checkpoint now preserves these focused results; full native rebuilding and
two installed self-built generations remain unqualified.

Current adjacent-span coalescing service-version recovery passes at 16 MiB:
bad provider rejection, in-guest repair and subsequent compilation without
reboot. Evidence:
`build/i386-adjacent-span-merge-recovery-version-16m/result.json`.
Full provider rebuilding and installed self-built generations remain open.

Current adjacent-span coalescing provider recovery also passes wrong-target
and missing-import rejection, in-guest repair, retry and reuse at 16 MiB.
Each case observes two rejections, two successful builds, one provider load,
and byte-identical restoration. Evidence:
`build/i386-adjacent-span-merge-recovery-{target,import}-16m/result.json`.
All three recovery cases now pass; full native rebuilding and both installed
self-built generations remain unqualified.

Current adjacent-span coalescing recursive provider initialization passes at
16 MiB on TCG/486,-fpu. The guest-built fixture is installed and tested after
fresh boot: one nested-acquisition rejection, one provider load and two
successful builds. Evidence:
`build/i386-adjacent-span-merge-reentrant-16m/result.json`.
The current all-provider rebuild remains live; two complete installed
self-built generations and their startup timing remain unqualified.

Current adjacent-span coalescing native ConsoleRuntime has completed at 16 MiB
on TCG/486,-fpu and passes its persisted layout, reference-export-set and
allocation-wrapper audit: 2,240,021 bytes, 6,401 records, 650 exports.
Evidence: `build/i386-adjacent-span-merge-console-partial-audit/result.json`.
The original all-provider session has advanced to CompilerRuntime; this partial
pass does not qualify the remaining providers or installed generations.

Current adjacent-span coalescing native CompilerRuntime completes at 16 MiB
on TCG/486,-fpu and passes persisted layout/reference-export auditing:
1,881,920 bytes, 4,092 records, 453 exports.
Evidence: `build/i386-adjacent-span-merge-compiler-partial-audit/result.json`.
The same all-provider session has advanced to CompilerProbe. Remaining
providers and both installed self-built generations remain unqualified.

Current adjacent-span coalescing native CompilerProbe completes at 16 MiB
on TCG/486,-fpu and passes persisted layout/reference-export auditing:
1,285,621 bytes, 3,637 records, 197 exports.
Evidence: `build/i386-adjacent-span-merge-probe-partial-audit/result.json`.
The same all-provider session has advanced to FileRuntime. Remaining
providers and both installed self-built generations remain unqualified.

Current adjacent-span coalescing native FileRuntime completes at 16 MiB
on TCG/486,-fpu and passes persisted layout/reference-export auditing:
390,335 bytes, 898 records, 134 exports.
Evidence: `build/i386-adjacent-span-merge-file-partial-audit/result.json`.
The same all-provider session has advanced to MemoryRuntime. Remaining
providers and both installed self-built generations remain unqualified.

Current adjacent-span coalescing native MemoryRuntime in the complete provider
sequence passes persisted layout/reference-export auditing at 16 MiB:
340,346 bytes, 1,047 records, 153 exports, byte-identical to the focused rebuild.
Evidence: `build/i386-adjacent-span-merge-memory-partial-audit/result.json`.
Five provider commands have completed; BuildRuntime is running. The full
provider audit and both installed self-built generations remain unqualified.

Current adjacent-span coalescing complete seven-provider rebuild passes at
16 MiB on TCG/486,-fpu. All persisted layouts/reference export sets and Console
allocation wrappers pass; build support loads once and is reused. Evidence:
`build/i386-adjacent-span-merge-all-providers-16m/result.json`.
The two-generation build/install/boot runner is active in
`build/i386-adjacent-span-merge-generations-16m`; installed generations and
their normal startup timing remain unqualified.

Current adjacent-span coalescing retained-provider installation passes its
8 MiB functional boot, including arithmetic and DocAllocationCheck. This closes
the prior DolDoc allocation failure for this image. Startup takes 74.19
seconds, exceeding the 60-second normal-startup requirement; functional PASS
does not qualify that timing gate. Evidence:
`build/i386-adjacent-span-merge-generations-16m/gen1-install/boot/result.json`.
The runner has advanced to gen1-selfhost; two complete self-built generations
remain unqualified. Preserve sources while it runs.

Current adjacent-span coalescing generation one passes guest kernel rebuilding
at 16 MiB, installation, and functional boot at 8 MiB on TCG/486,-fpu.
The 553,184-byte guest-built flat image matches the installed payload; all
thirteen modules, boot metadata/padding, 386 executable instruction ranges,
filesystem allocation, and 980 delivered source files pass their audits.
Arithmetic, DocAllocationCheck and VGA checks pass. Installed startup takes
73.74 seconds, so the unchanged 60-second timing gate remains unqualified.
Evidence: `build/i386-adjacent-span-merge-generations-16m/gen1-selfhost/result.json`,
its `boot/result.json`, `gen1-audit/result.json`, and `gen1-source-audit/result.json`.
The same runner has advanced to gen2-retained-build. Preserve source inputs
until it finishes; generation two and installed startup timing remain open.

The original adjacent-span two-generation process handle disappeared during
gen2-retained-build without a terminal result. Its running manifests are not
completion evidence; generation-one audited passes remain valid and preserved.
All original source and qualification-input hashes were rechecked and match.
A fresh full qualification uses
`build/i386-adjacent-span-merge-generations-recovery-16m`, preserving the old
output directory. No guest or harness source was changed for recovery.
Both-generation acceptance and the installed 60-second startup gate remain open.

The recovery run repeats generation-one self-build/install/8 MiB functional
boot and all thirteen-module, boot-image, filesystem, 386 instruction and
980-file source audits successfully. Its flat image and all module hashes
match the original generation-one audit. Startup takes 74.14 seconds, still
above the unchanged 60-second gate. Evidence lives under
`build/i386-adjacent-span-merge-generations-recovery-16m/gen1-selfhost`,
`gen1-audit`, and `gen1-source-audit`. The runner is live at
gen2-retained-build; keep source inputs frozen.

The recovery generation-two retained rebuild passes all seven providers at 16 MiB on TCG/486,-fpu. The persisted outputs are byte-identical to the generation-one installed providers, with one BuildRuntime load. Generation-two installation and flat-kernel self-build remain pending; the 60-second installed startup gate remains open.

The recovery generation-two retained installation and 8 MiB functional boot pass, including arithmetic and DocAllocationCheck. Startup takes 73.88 seconds, exceeding the unchanged 60-second target. The native flat-kernel self-build and final generation audits remain pending.

The recovery two-generation pipeline terminates at generation-identity with FAIL. Generation-two native self-build, 8 MiB functional boot, installed-image audit and 980-file delivered-source audit pass, but Kernel.t32m and GuestBoot.bin differ by 64 bytes across generations; the other twelve modules match. The difference lies after short strings in the fixed-size internal-type name arrays. PrsVarInit2Core copies the destination array length from the shorter string buffer, reading beyond the string. Bound the copy and zero-fill the remainder, add regression coverage, and repeat generation qualification. The 60-second startup gate also remains open.

The fixed-size string initializer now zero-fills the destination and copies at most the available string bytes. The refreshed original compiler/kernel bootstrap rebuild and thirteen-module i386 cross-build pass, including the 386 boot instruction audit (`build/i386-string-padding-bootstrap.log` and `build/i386-string-padding-cross/result.json`). The unfixed guest regression returns 2 instead of 0 for zero padding; fixed-candidate coverage adds empty strings, truncation and padding alongside aggregate initializers. Guest regression and full generation requalification remain pending; the 60-second installed startup gate is unchanged.

The fixed-candidate initializer regression passes all six cases (truncated, empty and padded strings; direct, macro and bitmap aggregate initializers), with persisted source/module/export validation and 25 VGA command checks on TCG/486,-fpu at 16 MiB. Evidence: `build/i386-string-padding-fixed/result.json`. This qualifies the targeted initializer behavior; it does not yet establish two-generation identity or installed startup timing.

The fixed initializer candidate passes normal 8 MiB startup in 47.21 seconds, all nine retained-state/storage/presentation VGA checks, and zero BuildRuntime startup loads (`build/i386-string-padding-boot-8m/result.json`). The fresh seven-provider native rebuild is running at 16 MiB under TCG/486,-fpu. The initializer checkpoint is `build/checkpoints/2026-10-09-string-padding/manifest.json`; installed-generation identity and the installed 60-second boot gate remain open.

An additional binary-data audit confirms the persisted AOT fixtures contain exactly the expected fixed-size arrays: one truncated `x` byte, sixteen zero bytes, and `x` followed by sixty-three zero bytes, each in its unique declared-size data range (`build/i386-string-padding-fixed/persisted-array-audit.json`). This complements included-source runtime checks and persisted module export validation.

The first fixed-initializer seven-provider run terminates at the 3,600-second ConsoleRuntime command limit while still compiling GrPutChar, before publication; no guest rejection is reported. Its result is FAIL due to timeout and is preserved under `build/i386-string-padding-all-providers-16m`. The coordinator stops before generation qualification. A fresh complete retry uses a 14,400-second per-module limit under `build/i386-string-padding-all-providers-long-16m`; memory, CPU, acceptance scope and startup budget remain unchanged.


### Recovery output capacity failure (2026-10-09)

The six-provider recovery is terminal FAIL after CompilerRuntime was persisted
(1,882,552 bytes). CompilerProbe compilation completes, but stage 5 output
reservation rejects its 1,285,621-byte output: 2,511 sectors are required and
only 645 sectors remain free, also the largest contiguous run. Both the
interrupted source and recovery disk pass the reachable-extent bitmap audit;
no orphaned allocation is inferred. This is disk capacity exhaustion, not a
16 MiB RAM failure. The generation coordinator stops before qualification.
Evidence: `build/i386-string-padding-providers-recovery-16m/result.json` and
`reservation-failure-audit.json`. Next qualify sufficient build-disk capacity
while preserving the 8 MiB boot and 16 MiB rebuild RAM gates.

## Host audit regression refreshed (2026-10-09)

The current production host audits accept four previously persisted guest-built
fixtures (bundle, loader, allocator and file) and reject all 52 independently
damaged variants. This qualifies audit rejection behavior only; these historical
fixtures do not establish current-candidate guest execution or native generation
reproducibility. Evidence: `build/i386-string-padding-host-native-audits/result.json`.
The capacity32 native rebuild remains live, compiling CompilerProbe at 16 MiB.

## Published recovery providers audited (2026-10-09)

ConsoleRuntime (2,240,021 bytes, 650 exports) and CompilerRuntime (1,882,552
bytes, 453 exports) pass persisted-module and current cross-reference export
contract audits on an independent copy of the terminal recovery image. Native
bytes need not match cross-built modules; native generation identity remains a
separate pending gate. Evidence:
`build/i386-string-padding-published-provider-audit/result.json`.

## Installed startup profiling leads (2026-10-09)

Static analysis of the preserved native providers counts 6,401 ConsoleRuntime
records and 742 combined function/data exports, exceeding the 512-slot symbol
index and selecting full-scan resolution. The unchanged validator performs
57,154,893 nested record visits for that valid module. CompilerRuntime has
4,092 records, 464 combined exports (index fits), and 23,726,719 nested validator
visits. These are static counts, not elapsed-time measurements. Use installed
startup phase timings to determine which path to optimize; preserve complete
validation, duplicate/overlap rejection, stack limits and memory ownership.
Evidence: `build/i386-string-padding-loader-scan-analysis.json`. Current
qualification sources remain unchanged.

## Sequential final-candidate regression refresh queued (2026-10-09)

After two-generation qualification and the separate four installed 8 MiB
interactive/60-second startup checks finish, refresh the current cross-built
candidate's 16 MiB publication diagnostics, 8 MiB software floating point,
16 MiB saved assembly, cancellation/lifetime/reentrant provider behavior, and
service-version/wrong-target/missing-import repair cases. The queue uses one
QEMU instance at a time and preserves independent result files. Queued work
is not passing evidence. Protocols are checkpointed; logs:
`build/i386-string-padding-installed-acceptance-capacity32-8m.log` and
`build/i386-string-padding-regression-refresh.log`.

## CompilerProbe publication passes on the recovery disk (2026-10-09)

The capacity32 recovery run completed the CompilerProbe build command and
advanced to FileRuntime (`qemu/checkpoint.json`: `startup-command-01`). The
previous failure at output reservation is no longer reproduced with the larger
disk; RAM remains 16 MiB on TCG/486,-fpu. This is command-level success only.
Persisted provider bytes and export contracts remain pending the final audit,
along with MemoryRuntime, BuildRuntime, Startup and generation qualification.

## FileRuntime recovery build command passes (2026-10-09)

The capacity32 recovery harness completed FileRuntime and advanced to
MemoryRuntime (`startup-command-02`), following CompilerProbe's successful
build command. RAM remains 16 MiB, with no build rejection in this run.
The combined persisted-provider audit and self-built generations remain pending.

## MemoryRuntime recovery build command passes (2026-10-09)

The capacity32 recovery harness completed MemoryRuntime and advanced to
BuildRuntime (`startup-command-03`), following CompilerProbe and FileRuntime.
RAM remains 16 MiB on TCG/486,-fpu. BuildRuntime, Startup, the combined
persisted-output audit and self-built generation qualification remain pending.

## Capacity32 provider build and audit pass (2026-10-09)

All five resumed commands passed, and all seven persisted native providers pass
the combined layout/function-export contract audit. The 32 MiB disk resolved
the earlier reservation failure without raising the 16 MiB rebuild RAM limit.
Generation-one installation is running. The installed generations, byte identity,
60-second startup budget and broader regression refresh remain unqualified.
Evidence: `build/i386-string-padding-providers-capacity32-16m/result.json`;
the original five-command result and QEMU result are preserved separately.

## Generation-one installed boot passes functionality, misses startup budget (2026-10-09)

All seven native providers install with exact persisted bytes, and the 8 MiB
TCG/486,-fpu boot passes arithmetic, DolDoc allocation and exact VGA checks.
Official startup is 75.065 seconds, exceeding the 60-second goal. Host marker
observations estimate 8.672 seconds in root kernel-header processing and
29.327 seconds in root user-header processing; these phase estimates are not
authoritative acceptance timings. Profile header parsing alongside module
validation/resolution before choosing an optimization. Generation-one flat-kernel
self-host rebuilding is live; generation identity remains pending. Evidence:
`build/i386-string-padding-generations-capacity32-16m/gen1-install/boot/result.json`
and `build/i386-string-padding-capacity32-startup-observations.log`.

## Generation-one self-built 8 MiB allocation failure (2026-10-09)

All eight native flat-kernel build/link/install commands pass. The independent
8 MiB TCG/486,-fpu boot reaches the command loop and passes arithmetic, then
DocAllocationCheck throws OutMem: request 8,755 bytes, heap used 6,637,216,
limit 6,655,488, largest free block 8,256 bytes. The generation runner is
terminal failed; generation two and the dependent acceptance/regression queues
did not start. Preserve this candidate and compare the self-built heap layout
with the prior adjacent-span boot before changing allocation behavior. Do not
raise RAM or weaken the DolDoc check. Evidence:
`build/i386-string-padding-generations-capacity32-16m/gen1-selfhost/boot/debug.log`
and the terminal generation result; failure evidence is checkpointed.

## Compiler footprint causality and backing-padding candidate (2026-10-09)

A diagnostic copy with only the previous CompilerRuntime passes 8 MiB DolDoc
allocation. Adding 632 inert payload bytes to that same old compiler reproduces
the exact failing request, heap usage and largest block. Thus the loaded-size
increase is sufficient to trigger the failure independently of initializer
behavior. These old-compiler probes retain the initializer bug and cannot qualify
a release. The correct initializer must remain.

The failed backing request is 8,192 page bytes plus a 52-byte region record and
511 alignment bytes. Current backing allocation retains unused alignment slack.
Investigate shrinking the owned backing allocation to its actual aligned extent,
with a regression first. Preserve page/batch rounding, alignment, ownership,
reserve retention and safe trim order. Evidence: the two
`build/i386-string-padding-*-compiler*-probe/result.json` files and
`build/i386-string-padding-selfhost-memory-comparison.json`.
