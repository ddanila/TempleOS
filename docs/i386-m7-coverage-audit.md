# M7 requirement-to-test audit

The two-pass frontend publication candidate passes 16 MiB no-FPU diagnostics:
28 program and 22 class publication cases, nine interactive commands, exact VGA.
Evidence: `build/i386-frontend-journal-diag-b-v69-16m/result.json`.
Its 8 MiB boot still fails with request 0xECD; subsequent parser tracing is not
qualified by that result. Current-source full builds, generations and release
remain open.

The exact-size class-journal candidate passes 16 MiB no-FPU diagnostics:
22 publication cases across both phases, including constrained scratch with
512 unrelated parser allocations; nine interactive commands and exact VGA.
Evidence: `build/i386-class-journal-diag-b-v69-16m/result.json`.
Its 8 MiB startup still fails. The subsequent tracing source is a separate,
unqualified snapshot; this diagnostic pass does not qualify that edit.

Saved bare/mixed assembly payload execution now passes 13 commands on
486,-fpu / 16 MiB. Both persisted, single-export, relocation-free modules execute
and restore interrupt state; source bytes and exports are validated. Evidence:
`build/i386-bare-assembly-saved-execution-c-v69/result.json`. This direct payload
check does not prove general native module loading or close the 8 MiB boot gate.

Current bare assembly candidate: focused assembly and opcode ownership tests
pass, but 8 MiB normal startup fails with compiler heap exhaustion. The fresh
static loader audit passes at 16300 / 16384 bytes. Six-provider rebuild is running. The 16 MiB no-FPU diagnostic startup passes
in 203.718 seconds with nine commands and exact VGA checkpoints; see
`build/i386-bare-assembly-diag-b-v69-16m/result.json`. Evidence:
`build/i386-bare-assembly-boot-b-v69-8m/result.json`,
`build/i386-bare-assembly-green-b-v69/result.json`, and
`build/i386-bare-assembly-loader-stack-b-v69/result.json`.
This candidate is not qualified for the 8 MiB startup gate.

Additional isolated resource evidence: original Bible compression and source-volume
packaging pass; native full-text expansion rejects with OutMem at 16 MiB.
Two caught failures with restored IRQ flags, subsequent arithmetic and a small
file read pass seven commands with exact VGA. Evidence:
`build/i386-bible-package-prototype-v69/native-read-oom-c-result.json`.
The resource patch is not applied to the current candidate. Full Bible/God
workflows and exact resource heap recovery remain open.

Previous v69 evidence (2026-10-07; predates the bare assembly candidate): fresh cross image and 386 instruction audit
pass; normal 8 MiB no-FPU startup passes in 54.917 seconds. Direct, single-line
macro and original bitmap aggregate compilation/persistence/HolyC behavior
pass, with exact audits of all initializer words. Static loader usage remains
16300 / 16384 bytes. Evidence: `build/i386-current-v69-checkpoint/result.json`.
Diagnostic startup passes at 16 MiB in 193.835 seconds, including
both native file-loader phases. The full six-provider guest rebuild is running;
current-source generations, install/release and complete OS parity remain open.

Current compiler source checkpoint (2026-10-07): the exhausted-macro snapshot
regression is fixed and all three native lexer suites plus both original
bootstrap generations pass. Evidence:
`build/i386-lex-snapshot-fix-checkpoint/result.json`. Cross-v67 rejected a kernel/compiler helper boundary; that placement is corrected
and the focused gates pass at compiler version 69 / probe 17. Cross-v68 linked the retained modules but rejected the old packaging import
contract. Exact contracts and version labels are corrected; old-version and
renamed-import mutations still reject. Cross-v69 is building;
scanner integration and full current-source native generations remain open.

Current packaging checkpoint v66 (2026-10-07): all twelve native modules are
byte-identical to v64; the image now includes the full Adam source tree and
uses a 32 MiB disk for rebuild space. Normal 8 MiB no-FPU startup passes in
46.188 seconds with all nine interactive/VGA checks. The full six-module guest
rebuild rejected at stage 3 in a macro-expanded scanner bitmap initializer
in `build/i386-retained-full-v66`; it is not qualified. The isolated native
snapshot-boundary regression reproduces the exhausted macro transition failure
(`build/i386-lex-snapshot-boundary-red-checkpoint/result.json`).
The earlier v64 rebuild rejection exposed eight omitted Adam dependencies;
source closure is now checked before packaging. Evidence:
`build/doc-layout-runtime-cross-v66/result.json`,
`build/doc-layout-runtime-boot-v66-8m/result.json`,
`build/i386-source-package-closure-v65/result.json` and
`build/i386-source-image-capacity-v66/result.json`. Disk capacity does not
change the 8 MiB interactive / 16 MiB rebuild RAM requirements.

Latest qualified v64 normal and diagnostic startup source (2026-10-07): compiler ABI 68, console ABI 66 and
memory ABI 22. Cross-v64 and both bootstrap generations pass. Its 8 MiB
486,-fpu startup passes nine retained static/function/literal and exact VGA
checks in 45.780 seconds. Mixed symbol deletion and explicit 64 KiB parent
ownership pass at 8 MiB in the earlier v54 integration; default-stack parent
ownership passes at 16 MiB. The default-stack 8 MiB allocation failure remains
open. The v54 guest rebuild covers Startup and MemoryRuntime only; full current
source generations and release qualification are not established.

Diagnostic v64 passes in 177.620 seconds at 16 MiB, including the isolated
memory phases, dual-heap backing accounting, worker disk-include/IRQ tests,
both native file-loader phases, probe/task release and all nine interactive
commands with exact VGA restoration. The v63 worker failure exposed overlapping
loader scratch frames exceeding its unchanged 16 KiB stack. Separating loader
preflight and compaction removes 9256 overlapping bytes. The same compiled-code
checker rejects v63 at 25556 bytes and accepts v64 at 16300 bytes, including a
6144-byte caller/parser allowance. This static direct-call check and the runtime
pass qualify this regression; neither proves whole-OS stack safety. Evidence:
`build/doc-layout-runtime-boot-v64-8m/result.json`,
`build/parser-placement-diagnostic-v64-16m/result.json` and
`build/i386-loader-stack-checkpoint/result.json`.

Current-source feature gaps remain independent of rebuild qualification.
`Kernel/I386/PublicSound.HH` exposes `Snd` and `SndRst`, and
`Kernel/I386/SoundRuntime.HC` implements note output/reset; the original
`Adam/ASnd.HC` music-string `Play` and `CurSongTask` workflow is not integrated
by these providers. Speaker waveform passes cannot establish that workflow.
`ConsoleRuntime.HC` includes `Adam/Gr/GrFloodFillCore.HC`, whose
`GrFloodFillRay` allocates `sizeof(CFFRay)*0x80000`: seven I64 fields give
29360128 bytes (28 MiB), exceeding the entire 8 MiB interactive profile.
The routine immediately writes `f->x` after allocation without a failure
check, so the regression must also cover allocation failure before any pixel
change and verify restoration of the DC flags, brush and secondary color.
Its bounded-memory integration and allocation-failure recovery need focused
original-behavior tests before claiming complete graphics usability. Compiling
these functions into a retained module does not establish runtime coverage.

The packaged and generation evidence below belongs to the older source epoch;
it does not qualify the changed graphics, compiler and memory sources above.

Historical qualification (2026-10-06): the ABI 47 scope-v1 candidate is integrated
into the main working tree. The remote checkpoint remains ABI 40 because this
session cannot write to `.git`. All 825 Kernel/Compiler/Adam source files match
the frozen candidate. A fresh original bootstrap, cross-build and 386 boot
audit pass; the cross-built normal image matches the candidate byte for byte.
The integrated runtime suite passes 513 commands, 13 allocation cases and
20 exact-heap development cycles at QEMU TCG `486,-fpu` / 8 MiB.

Both native generations pass installation, guest-built kernel construction,
independent boot and installed-image audits in
`build/key-arrival-candidate/build/key-arrival-scope-native-generations-v1`.
All 12 modules, the 501912-byte flat kernel and the boot area match across
generations; whole-disk hashes differ. The flat kernel SHA-256 is
`899e2368cfeb9e15c6d79852f9b14c58496a137be9922e75906fff5e97592fb8`.

Deterministic packaging and the independent packaged-image audit pass. The
package is `build/key-arrival-integrated-native-package-v1`, SHA-256
`de8114d5437b341d0b7c8cc0f62c79d134ed39e95e11602c78638796a155d0c0`.
Its workstation, three-boot DolDoc, large-source and speaker workflows pass
in `build/key-arrival-integrated-packaged-workflows-v1`. That aggregate failed
because the resource invocation omitted QMP stdio. The corrected focused
resource test passes 20 cycles with exact heap recovery in
`build/key-arrival-integrated-packaged-resource-v2`. The corrected complete
aggregate in `build/key-arrival-integrated-packaged-workflows-v2` passes all
five jobs. The source image is unchanged and all 197 pinned inputs still match.

Focused frozen-candidate evidence also covers both undo injection modes,
large-source round trips, inherited-forward compiler scope, timed-message
filter routes, public messages, macro allocation/registration recovery,
20 debugger jobs and byte-exact binary/styled DolDoc exchange with original
TempleOS. Playback scheduling, raw queue wrap/overflow/cancellation timing,
final release qualification, commit and publication remain open. Physical
hardware verification is deferred; manual observation is optional exploratory
feedback. Historical results below belong to their named source epochs.
See [PLAN.md](../PLAN.md).

## Historical coverage checkpoints

The following results belong to the named earlier images and source epochs.
Their pending statements do not describe the current qualification queue.

Current filesystem integration checkpoint (2026-10-05): promoted main remains
file ABI 40; the ABI-46 public cache/write-parent candidate has a fully native
installed twelve-module image and independent 386/bitmap audit in
`build/public-resident-write-parent-selfhost` and `...-selfhost-audit`.
Its second native generation and installed no-FPU workstation are running.
Fresh three-boot DolDoc persistence and captured speaker-output checks now run
on that installation in `...-installed-doldoc-session` and `...-installed-speaker`.
The three-boot DolDoc workflow and captured speaker output now pass. A fresh
pinned resource profile also passes twenty cycles, measuring 1352496 live
baseline and 1356112 peak bytes. These are ABI-46 installed results.
ABI-47 integrates public Cd and passes focused
original/native cache, compiler/DolDoc, write and exact heap-recovery contracts;
its workstation and native-generation chain remain pending. Historical greens
below cannot substitute for these current-source installed workflow checks.

Current optimized-source checkpoint: all twelve modules are guest-built in
`build/i386-heap-seek-selfhost`, with installed 386/boot/RedSea/keyword audits
passing. Its no-FPU 8 MiB full workstation passes 513 commands, exact VGA
and 20 exact shared-heap recovery cycles: startup 33.014209438 seconds and
long-document visible update 0.372473826 seconds. All six second-generation
retained providers reproduce their installed first-generation bytes exactly;
installation and independent boot pass. Second-generation flat construction and installed audits pass in
`build/i386-heap-seek-gen2-selfhost` and its audit directory; generation
comparison passes all twelve modules, flat kernel and installed boot bytes.
The current resource profile passes 20 cycles with 1352496-byte live baseline,
1356112-byte live peak and 1356800-byte reserved peak; its arena fits 8 MiB. The current fully native
three-boot DolDoc session passes in
`build/i386-heap-seek-selfhost-doldoc-session`: persistence, exact VGA,
filesystem integrity and 0.216-second interrupt recovery. All three
33-second boots pass the startup budget. Captured speaker tone/off/reset
checks pass in `build/i386-heap-seek-selfhost-speaker`. Older rows below retain their
historical evidence and must not override this checkpoint. CPU-trap
continuation/stepping/register inspection, complete API parity and release
qualification remain open.

This audit follows the six numbered outcomes in [PLAN.md](../PLAN.md#final-goal-a-fully-working-templeos-on-a-pc-compatible-machine).
Passing a component corpus or finding a public function does not prove the
complete user workflow. Human observation and physical hardware remain optional.

The heap-scan qualification snapshot is compiler 59, memory 18 and console
36 in `build/i386-heap-scan-kernel/kernel.img` (SHA-256
`38fbbde26954101563a481fc2655157d7459dc7c40c06c3bd611318ba1c94bbd`).
It passes the original two-generation rebuild, cross-build and 386 boot audit.
Both portable and assembly heap corpora pass, including corruption rejection
without arena/control mutation. Its portable size lookup now combines lookup
with complete validation. Guest compilation, installation and independent boot pass in
`build/i386-heap-scan-flat`; the flat image remains 487344 bytes (80 bytes spare).
The installed 386/filesystem audit passes in
`build/i386-heap-scan-flat-cross-retained-audit`. Normal no-FPU TCG keyboard/VGA and the 60-second startup gate pass at
56.216 seconds. A controlled before/after speed benefit remains unproven. This development image uses cross-built retained providers and
cannot prove full self-hosting.

All six retained providers now build inside that guest in
`build/i386-heap-scan-retained`; export-set and console allocation-wrapper
checks pass. Installation, exact installed bytes and independent 8 MiB no-FPU
boot pass in `build/i386-heap-scan-retained-install`. All six flat modules
now build/install using those guest-built providers in `build/i386-heap-scan-selfhost`;
independent 8 MiB no-FPU boot passes. The installed twelve-module instruction
and filesystem audit passes in `build/i386-heap-scan-selfhost-audit`. Target
SHA-256 is `66819bf5b517d80a937bee1491022eea6988d021c7ad5edbbf64bff61c02e7ba`.
Its no-FPU TCG keyboard/VGA check passes, but startup is 65.149 seconds and
`build/i386-heap-scan-selfhost-startup-budget.json` fails the 60-second gate.
The completed profile attributes 140/150 public-header and 340/367 startup-source
samples to boot-kernel heap operations; it is not a timing benchmark. Complete workflow qualification
and a second native generation remain open.

The newer formatter-extraction source revision 2470ed94 passes the original
two-generation rebuild, all 17 original formatter cases, and cross-build/386
instruction audit in `build/i386-format-core-kernel` (no boot test). Native
formatter/User integration remains open; this refactor baseline must not be
confused with the older images' runtime evidence.

The newer assembly heap scan passes both heap variants and the cross-built
513-command workstation suite in `build/i386-heap-asm-scan-cross-workstation`,
including exact VGA and 20 cycles with exact heap recovery. Startup passes at
46.073 seconds and visible-update latency is 0.255 seconds. Its guest flat
build/install and image audit pass with 487072 flat bytes (352 spare), using
cross-built retained providers. All twelve modules now build/install natively in `build/i386-heap-asm-scan-selfhost`,
with independent 8 MiB boot and installed instruction/filesystem audit passing.
Its target is 9c74ad0a; ordinary 8 MiB no-FPU TCG keyboard/VGA and startup
now pass at 53.687 seconds. Its full workstation suite passes 513 commands, exact VGA and 20 document
cycles with exact heap recovery; startup passes at 53.786 seconds and visible
update at 0.260 seconds. The three-boot DolDoc workflow passes 107/56/15 commands with exact VGA,
persistent programs and revisions, and matching filesystem extents/bitmap.
Interrupt recovery is 0.271 seconds. Actual speaker verification passes in
`build/i386-heap-asm-scan-selfhost-speaker`: captured 440/880 Hz PCM and zero
new audio during settled off/reset intervals, with the source unchanged. The
second-generation retained build initially failed from contiguous-space exhaustion.
The larger-first retry in `build/i386-heap-asm-scan-gen2-largest-first` passes
all six providers with exact installed-byte equality and a consistent filesystem.
Installation and independent 8 MiB no-FPU boot pass in
`build/i386-heap-asm-scan-gen2-largest-first-install`. The native flat rebuild and installed-image audit now pass; all twelve modules
and linked boot bytes match the first generation exactly. Whole disk layout
differs. Second-generation workstation qualification passes 513 commands with exact VGA
and heap recovery, 54.770-second startup and 0.370-second long-document update.
Three-boot persistence passes 107/56/15 commands with exact VGA, retained
programs/revisions and consistent filesystem extents; all boots are below
60 seconds and interrupt recovery is 0.268 seconds. Audio verification passes captured 440/880 Hz tones and off/reset silence on
target 44ed8c88. Both generations pass the existing workflows; full OS
compatibility and release qualification remain pending. Full
two-generation and release qualification remain open.

Recorded component passes cover independent terminals, Ctrl-Alt-N, concurrent
editors, background compilation during editing, idle Ctrl-Alt-C recovery,
forced editor/debugger exit, and the 69-command public Kill contract. Debugger
coverage includes explicit entry/return, named and zero-valued exceptions,
source attribution, active mode and prior-mode restoration after normal or
forced exit. These passes belong to the individual image snapshots recorded
in PLAN.md and the workflow document; they are not a consolidated current-image
release pass. The mode-image full workstation suite passes in
`build/i386-debug-mode-workstation`: 513 commands, exact VGA, 20 document
cycles with exact heap recovery, 58.326-second startup and 0.317-second visible
update. Both measured budgets pass on that cross-built snapshot. The preceding cleanup-image attempt failed
at a test that redeclared debugger G; the distinct-name forward-call regression
passes, and the full fixture has been corrected.

The cleanup fully guest-built workstation suite now passes all 513 commands,
exact VGA and 20 document cycles with exact heap recovery. Its visible-update
latency is 0.258 seconds, but startup fails the gate at 64.995 seconds. Evidence
is in `build/i386-terminal-debug-cleanup-selfhost-workstation` and its budget
report; this predates the subsequent heap and formatter changes.

The preceding cleanup fully guest-built epoch is compiler 59, memory 18,
console 36 in `build/i386-terminal-debug-cleanup-selfhost`: six retained
providers and six flat modules were guest-built, installed and independently
booted. `build/i386-terminal-debug-cleanup-selfhost-audit` verifies all twelve
executable ranges, installed payload and filesystem. Its 487344-byte flat image
has 80 bytes spare. It includes terminals, Kill and debugger task cleanup,
but predates zero-exception/mode restoration, heap scan and formatter extraction.
No-FPU TCG keyboard/exact-VGA passes, but startup at 65.445 seconds fails
the 60-second budget. Its full workstation suite is running. The earlier compiler-59,
memory-17/console-35 selfhost result is historical evidence. Current-source
two-generation reproducibility and release qualification remain open; the older
95-file local bundle is not a current release.

| Required outcome | Executable test and independent oracle | Current status / missing evidence |
| --- | --- | --- |
| 1: Legacy BIOS cold boot, ordinary prompt, no mandatory diagnostics | `i386-kernel-input.py` rejects diagnostic markers during normal boot and matches every VGA pixel. `audit-i386-boot.py` checks classified BIOS/protected-mode ranges. ISO preparation plus `verify-iso.py` independently compares all filesystem bytes and boot metadata. | Ordinary boot works. Published-artifact download, verification and smoke boot remain open. Preparation now uses the immutable original snapshot, with only `main` needed. |
| 2: Edit/compile/execute, definitions, errors, allocation failure, I64/software F64 | Full workstation groups cover native compilation, public allocation API, math, retained definitions and recovery with exact VGA; the three-boot document session executes and corrects programs through the editor. `test-i386-mutations.py` checks selected incorrect guest answers. | Previous guest-built generations pass. Optimized cross-image integration passes all 513 commands with exact heap recovery. Guest flat development three-boot integration also passes; complete current-source promotion remains open. Mutation coverage is selected, not exhaustive. |
| 2: Source-linked syntax diagnostics usable in the guest | `test-i386-doldoc-session.py`: the multiline syntax error case returns to the editor, selects line 2, corrects the source and re-executes it; exact VGA verifies the selected line and corrected answers. Debug-log line metadata supplements the visible oracle. | Previous generations pass. Pass on the optimized guest flat development image as well. Repeat after fully guest-built promotion; this does not prove general runtime exception inspection. |
| 2: Public task services and cooperative work in multiple terminals | Public task/message contracts plus `test-i386-terminals.py`, terminal hotkey/document/background/idle-break/kill workflows; exact VGA, saved bytes and parent heap recovery. | Two-terminal isolation, Ctrl-Alt-N, simultaneous text editors, background HolyC compilation, idle-break recovery, forced editor-task exit and debugger-task exit pass on their recorded snapshots. The revised public Kill corpus passes 69 commands/nine cases on memory 18 (startup timing fails). Creation hotkeys, broader window ordering and exhaustive private-resource/failure coverage remain open. |
| 2: On-machine debugging and runtime exception inspection | Explicit Dbg/G, named exception/source and forced-debugger-exit checkers use independent VGA and observable state/continuation. | All three pass on cleanup image 9812e5d5. Zero-valued exception classification passes on image 0a90d205. Active/prior debugger-mode state and forced-exit restoration pass on image 3354b498 (13/14 commands). Saved registers, exact instruction-line mapping, breakpoints/stepping, simultaneous debugger sessions and broader resource/error recovery remain open. |
| 3: Executable DolDoc with graphics, save/reboot/reopen/re-execute | `test-i386-doldoc-session.py` runs three writable boots with exact VGA and saved-byte comparisons; its independent RedSea walker audits all reachable extents and bitmap bits. Sprite and formatted/binary execution cases cover selected records. `test-i386-doc-style-compat.py` uses original x64 TempleOS as a bidirectional file-format oracle. | Previous generations and the optimized guest flat development image pass the tested workflow and record surface. Repeat after fully guest-built promotion; broad original record/API parity remains a separate inventory. |
| 3: VGA, keyboard, mouse, timer/disk and speaker together | Workstation groups inspect exact VGA, injected PS/2 events and guest PIT/IRQ results. `test-i386-speaker-output.py` independently analyses 440/880 Hz PCM and observes zero audio emission during off/reset intervals. | Both current native generations (9c74ad0a and 44ed8c88) pass captured audio and off/reset silence; register checks alone are insufficient. |
| 4: Guest rebuild/install/cold boot for two generations | `test-i386-retained-build.py`, `test-i386-retained-install.py`, `test-i386-selfhost-install.py` and generation/installed-image audits compare persisted modules, flat image and boot bytes. | Compiler-59/memory-17/console-35 passes all twelve guest-built modules, installation, independent boot and 386/filesystem audit in `build/i386-debug-exception-selfhost` and `-audit` (487344 bytes). Memory-18 cleanup snapshot 9812e5d5 is rebuilding retained providers. Current-source two-generation reproducibility remains open. |
| 5: 8 MiB interactive, 16 MiB rebuild, bounded allocations | Workstation resource cycles require exact shared-heap recovery; `test-i386-resource-profile.py` records live/reserved peaks and checks the arena against installed RAM. Heap corpora exercise corruption, exhaustion, foreign pointers, coalescing and public ownership. | Focused optimized heap/loader corpora pass. Requalify all resource bounds on the full new candidate and include measurements in the release report. |
| 5: Startup and edit/interrupt latency budgets | `check-i386-startup-budget.py` enforces 60 seconds. The workstation long-document visible-update case and three-boot interrupt-to-recovery case enforce one second. | Previous guest-built startup fails at 73–74 seconds. The optimized cross-image full suite passes at 50.501 seconds with a 0.314-second visible update. The guest flat development session has 50.506–53.144-second boots and 0.271-second interrupt recovery, with cross-built retained modules. Fully guest-built timing remains open. Promotion must require both visible-latency measurements, not merely the suite's pass label. |
| 5: No FPU, 386 executable regions, pinned environment | No-FPU QEMU execution plus boot/installed/JIT/inline-assembly audits cover their classified ranges; command manifests record CPU, RAM, accelerator and devices. | New flat development image passes installed 386/RedSea audit. Complete current-source live JIT coverage and a consolidated environment record (host, QEMU, BIOS hash, pinned machine/storage/peripherals) remain open. Emulator evidence does not certify a physical 386. |
| 6: Reviewable published result and x64 regression | `test-rebuild.py` boots rebuilt x64 compiler/kernel and rebuilds again. Packaging checks source/image evidence; the standalone verifier checks files, decompressed image and audio independently. | Fresh x64 regression passes. A single fresh/resumable qualification command, matching full evidence, published versioned artifacts and downloaded-artifact smoke test remain open. The local bundle is an earlier-source candidate, not a published release. |

Next implementation order: finish the live workstation/provider/flat builds,
check native boot-area fit and startup timing, then close the remaining
terminal and debugger behavior with failing visible tests. Keep these failures in the qualification report; a publication
probe turning green is only the first step toward its associated behavior gate.

The optimized fully guest-built installed image now passes its 386 executable,
boot and RedSea audits, but its normal no-FPU TCG startup is 71.383183 seconds
(`build/i386-retained-startup-u32-keyboard-budget.json`: fail). The existing
60-second target remains in force. This is the pre-delay source epoch; preserve
that distinction when running further qualification.

The optimized fully guest-built installed image also completes the full
8 MiB no-FPU workstation suite: 513 commands, 576 lines, exact VGA and 20
exact shared-heap recovery cycles (`build/i386-retained-startup-u32-workstation-tcg/result.json`).
Its 70.498169-second startup still fails the unchanged budget; the visible
long-document update is 0.264459 seconds. This remains the pre-delay source epoch.

Expression `#if` is a newly identified compiler gap. The indexed-loader native
build rejected `#if sizeof(U8 *)==4` at `ModuleLoad.HC:60`; lexer tests that skip
conditional blocks do not establish frontend evaluation of these directives.
The current native-builder selection uses a supported explicit define while
this required compiler-coverage work stays open.

The invocation-local loader index passes 40 no-FPU loader cases and a differential
1/128/512/513-export fixture. Its compact builder also compiles with the native
frontend: six guest-built flat modules install and boot, the 486,088-byte flat
image passes its 386 executable audit, and normal startup takes 46.971996 seconds
on 8 MiB no-FPU TCG. See
`build/i386-symbol-index-frontend-native-development/result.json` and
`build/i386-symbol-index-frontend-native-keyboard/budget.json`. Retained runtime
inputs in this image are cross-built; the full guest-built budget remains open.
The focused native inline-assembly test fails on the old compiler and passes
on the updated compiler, including a block larger than 256 bytes and ordinary
HolyC execution afterward. This establishes those operand forms, not complete
original assembler coverage. A 1,509-keystroke fixture attempt also timed out
during document teardown on both images; retain that observation for a focused
resource/teardown test. The final compiler fixture uses one text entry.

The expression-conditional JIT contract now has an executable baseline:
`tools/test-i386-native-conditionals.py`, with failure recorded in
`build/i386-native-conditionals-before-final/result.json`. Source preparation
passes, and inclusion produces `Compilation failed`; the current lexer rejects
expression `KW_IF`. The positive and recovery assertions are not yet executed.
AOT conditions and allocation-failure cleanup require additional evidence.

Public file compatibility also remains incomplete: an attempted public
`FileWrite` call produces an undefined-identifier error. The working private
writer and `DocWrite` do not prove the original `FileWrite(filename,buffer,size,
cdt,attr)` contract. Audit `FileRead` publication and ownership as part of the
planned public file migration, and add failing signature/behavior tests before
implementing the missing bindings.

The loader-index development image now passes the full 513-command no-FPU
workstation suite with 50.241406-second startup, a 0.261061-second long-document
update and 20 exact shared-heap recovery cycles. Its retained inputs remain
cross-built. All six retained modules have subsequently rebuilt and installed
natively, and the flat kernel rebuilt with those providers installs and boots
independently. All twelve modules are now guest-built at that loader checkpoint;
its no-FPU TCG timing/workstation qualification has started.

Expression conditionals now pass focused JIT and executed AOT contracts:
`build/i386-native-conditionals-source-mode-jit/result.json` and
`build/i386-native-conditionals-source-mode-aot/result.json`. The same source
returns 98 under JIT and 99 from its loaded guest-built AOT module, with all 41
loader cases passing. Nested lookahead distinguishes source mode independently
of temporary backend staging flags. Error recovery preserves prior definitions.
This does not establish allocation-failure/owned-heap cleanup or final native
compiler-provider installation; those remain open. The raw lexer and its
original marker compatibility contract still pass.

The all-twelve-module native loader checkpoint now passes the 386 executable
audit, including its native division template, and normal keyboard/VGA boot
on 8 MiB no-FPU TCG in 56.381575 seconds. Its startup budget passes. The full
workstation run remains active. This source epoch predates the final conditional
frontend; current-source two-generation and release qualification remain open.

Latest timing evidence: cleanup/zero-case functional checks record 62.19–72.05-second starts. `build/i386-debug-zero-startup-budget.json` fails the 60-second budget. These observations do not yet establish the cause; startup qualification remains open.

Latest mode-image observations pass startup at 59.439/59.375 seconds; the first has a formal budget pass. Earlier over-budget observations remain valid. The cleanup-image full workstation run failed at command-105: its private G definition conflicts with the newly published debugger G. Full current-source workstation qualification remains open.


The newer formatter integration passes 41 original/native formatting cases on
both the cross-built image and an image with a console rebuilt inside the port.
See `build/i386-native-formatter-installed-41/result.json` and PLAN.md for exact
artifact hashes. Its native console passes instruction audit and byte-preserving
installation/8 MiB boot checks. This is a mixed-provider image; full workstation
and updated native boot-kernel size checks are still running. User creation,
full debugger and release reproducibility remain open.

The formatter snapshot's full workstation regression subsequently passes in
`build/i386-native-formatter-workstation/result.json`: 513 commands, 576 lines,
exact VGA checkpoints and 20 resource cycles with exact shared-task heap
recovery. Startup is 47.03001209674403 seconds on 8 MiB 486,-fpu. The native
boot-kernel build remains active; updated all-native image qualification is open.

The formatter kernel compaction now has measured native evidence: 487272 flat
bytes (152 spare), 386 instruction audit, and 41 formatter cases passing on an
8 MiB no-FPU boot. See `build/i386-formatter-binding-table-boot-41/result.json`.
This still uses cross-built helpers/providers. The next User oracle has 16
original passing cases covering partial input, double percent formatting and
long startup input; native User remains absent at its availability check.

Current explicit API gap: public FileWrite is undefined on the promoted
CPU-trap main image. The retained file service has a write callback and
DocWrite can save documents, but those do not prove original FileWrite
compatibility. Boot payload-rejection fixtures fail before publication for
this reason (`build/cpu-trap-main-payload-rejection-v3`). Add original
signature/return-value/byte persistence/error tests before binding it.
