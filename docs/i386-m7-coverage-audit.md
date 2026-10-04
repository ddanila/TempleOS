# M7 requirement-to-test audit

This audit follows the six numbered outcomes in [PLAN.md](../PLAN.md#final-goal-a-fully-working-templeos-on-a-pc-compatible-machine).
Passing a component corpus or finding a public function does not prove the
complete user workflow. Human observation and physical hardware remain optional.

The first task-owned-terminal runtime is compiler 59, console 36 and memory 17 in
`build/i386-terminals-kernel-pointer/kernel.img` (SHA-256
`6051ee26f0405f92e4dc2682c9738ce5c30141c68a6a11d4e35156cad0e2f5d0`).
Ordinary keyboard, explicit debugger and named-exception inspection checks pass
on that image. Its two-terminal workflow and intentional keyboard-loss check also pass: separate
definitions/history, programmatic focus, exit/refocus and parent public-heap
recovery. The newer Ctrl-Alt-N image in `build/i386-terminal-hotkeys-kernel`
(SHA-256 `444bfb1b7ee9de7e0ac6e4b609b2fd066798c649a9baec47a989165e81657229`)
passes build/audit, hardware Ctrl-Alt-N cycling and ordinary keyboard checks.
The heading-fix image `build/i386-terminal-documents-kernel/kernel.img`
(SHA-256 `58ab899923d48879c927e24be06c986436fb1ed4da04a9918ba5219c83dd060e`)
passes the two-editor contract: independent live text documents, focus cycling,
editing/save, named terminal restoration, exit/refocus, exact parent public-heap
recovery and independent persisted-byte verification. Root document-editing
regression passes 169 commands with exact VGA. The idle Ctrl-Alt-C contract now has matching
baseline failure and candidate pass in `build/i386-terminal-idle-break-editor-{red,green}`.
Candidate image `a9a664ae3111a362526057187d1d47bde9e82ef0bb42503abf752d870438a5f8`
survives two breaks, supports editor sessions after each, retains definitions
and passes normal terminal cleanup. Existing interrupt regression passes all 16 commands. The first background
compiler/editor workflow passes visible/file/cleanup checks; the stricter
completion-during-editor oracle also passes in
`build/i386-terminal-background-live-session` (14 commands, 56.00-second startup). Forced editor-task cleanup passes on memory-18 image 201cb474. The broader
cancellation corpus found unpublished CH_SHIFT_ESC during setup; shared-header
publication is under verification. Killing a debugger task leaves DbgBusy in the
survivor on the baseline; the chained task cleanup fix now passes the frozen
workflow on image 9812e5d5. Explicit and named-exception regressions also pass.

The preceding memory-17 registration-fix image passes the full 513-command
workstation suite in `build/i386-public-macro-registration-workstation`, including
20 document cycles with exact heap recovery, a 55.56-second startup and
0.315-second long-document update. It predates debugger/terminal changes.
The newest completed fully guest-built epoch is compiler 59, memory 17 and
console 35 in `build/i386-debug-exception-selfhost`: all six retained providers
and six flat modules were guest-built, installed and independently booted.
`build/i386-debug-exception-selfhost-audit` passes all twelve executable ranges,
installed payload and filesystem checks. Its 487344-byte flat image leaves
80 bytes in the boot area. It predates task-owned terminals, Kill and debugger
cleanup. The earlier memory-16/console-33 result remains historical evidence.
Current-source two-generation reproducibility and release qualification remain
open. The older 95-file local bundle is historical evidence, not a current release.

| Required outcome | Executable test and independent oracle | Current status / missing evidence |
| --- | --- | --- |
| 1: Legacy BIOS cold boot, ordinary prompt, no mandatory diagnostics | `i386-kernel-input.py` rejects diagnostic markers during normal boot and matches every VGA pixel. `audit-i386-boot.py` checks classified BIOS/protected-mode ranges. ISO preparation plus `verify-iso.py` independently compares all filesystem bytes and boot metadata. | Ordinary boot works. Published-artifact download, verification and smoke boot remain open. Preparation now uses the immutable original snapshot, with only `main` needed. |
| 2: Edit/compile/execute, definitions, errors, allocation failure, I64/software F64 | Full workstation groups cover native compilation, public allocation API, math, retained definitions and recovery with exact VGA; the three-boot document session executes and corrects programs through the editor. `test-i386-mutations.py` checks selected incorrect guest answers. | Previous guest-built generations pass. Optimized cross-image integration passes all 513 commands with exact heap recovery. Guest flat development three-boot integration also passes; complete current-source promotion remains open. Mutation coverage is selected, not exhaustive. |
| 2: Source-linked syntax diagnostics usable in the guest | `test-i386-doldoc-session.py`: the multiline syntax error case returns to the editor, selects line 2, corrects the source and re-executes it; exact VGA verifies the selected line and corrected answers. Debug-log line metadata supplements the visible oracle. | Previous generations pass. Pass on the optimized guest flat development image as well. Repeat after fully guest-built promotion; this does not prove general runtime exception inspection. |
| 2: Public task services and cooperative work in multiple terminals | Public task/message contracts plus `test-i386-terminals.py`, terminal hotkey/document/background/idle-break/kill workflows; exact VGA, saved bytes and parent heap recovery. | Two-terminal isolation, Ctrl-Alt-N, simultaneous text editors, background HolyC compilation, idle-break recovery, forced editor-task exit and debugger-task exit pass on their recorded snapshots. The revised public Kill corpus passes 69 commands/nine cases on memory 18 (startup timing fails). Creation hotkeys, broader window ordering and exhaustive private-resource/failure coverage remain open. |
| 2: On-machine debugging and runtime exception inspection | Explicit Dbg/G, named exception/source and forced-debugger-exit checkers use independent VGA and observable state/continuation. | All three pass on cleanup image 9812e5d5. Zero-valued exception classification passes on image 0a90d205. Active/prior debugger-mode state is under verification. Saved registers, exact instruction-line mapping, breakpoints/stepping, simultaneous debugger sessions and broader resource/error recovery remain open. |
| 3: Executable DolDoc with graphics, save/reboot/reopen/re-execute | `test-i386-doldoc-session.py` runs three writable boots with exact VGA and saved-byte comparisons; its independent RedSea walker audits all reachable extents and bitmap bits. Sprite and formatted/binary execution cases cover selected records. `test-i386-doc-style-compat.py` uses original x64 TempleOS as a bidirectional file-format oracle. | Previous generations and the optimized guest flat development image pass the tested workflow and record surface. Repeat after fully guest-built promotion; broad original record/API parity remains a separate inventory. |
| 3: VGA, keyboard, mouse, timer/disk and speaker together | Workstation groups inspect exact VGA, injected PS/2 events and guest PIT/IRQ results. `test-i386-speaker-output.py` independently analyses 440/880 Hz PCM and observes zero audio emission during off/reset intervals. | Both previous guest generations pass audio. Repeat on the newly promoted image; register checks alone are insufficient. |
| 4: Guest rebuild/install/cold boot for two generations | `test-i386-retained-build.py`, `test-i386-retained-install.py`, `test-i386-selfhost-install.py` and generation/installed-image audits compare persisted modules, flat image and boot bytes. | Compiler-59/memory-17/console-35 passes all twelve guest-built modules, installation, independent boot and 386/filesystem audit in `build/i386-debug-exception-selfhost` and `-audit` (487344 bytes). Memory-18 cleanup snapshot 9812e5d5 is rebuilding retained providers. Current-source two-generation reproducibility remains open. |
| 5: 8 MiB interactive, 16 MiB rebuild, bounded allocations | Workstation resource cycles require exact shared-heap recovery; `test-i386-resource-profile.py` records live/reserved peaks and checks the arena against installed RAM. Heap corpora exercise corruption, exhaustion, foreign pointers, coalescing and public ownership. | Focused optimized heap/loader corpora pass. Requalify all resource bounds on the full new candidate and include measurements in the release report. |
| 5: Startup and edit/interrupt latency budgets | `check-i386-startup-budget.py` enforces 60 seconds. The workstation long-document visible-update case and three-boot interrupt-to-recovery case enforce one second. | Previous guest-built startup fails at 73–74 seconds. The optimized cross-image full suite passes at 50.501 seconds with a 0.314-second visible update. The guest flat development session has 50.506–53.144-second boots and 0.271-second interrupt recovery, with cross-built retained modules. Fully guest-built timing remains open. Promotion must require both visible-latency measurements, not merely the suite's pass label. |
| 5: No FPU, 386 executable regions, pinned environment | No-FPU QEMU execution plus boot/installed/JIT/inline-assembly audits cover their classified ranges; command manifests record CPU, RAM, accelerator and devices. | New flat development image passes installed 386/RedSea audit. Complete current-source live JIT coverage and a consolidated environment record (host, QEMU, BIOS hash, pinned machine/storage/peripherals) remain open. Emulator evidence does not certify a physical 386. |
| 6: Reviewable published result and x64 regression | `test-rebuild.py` boots rebuilt x64 compiler/kernel and rebuilds again. Packaging checks source/image evidence; the standalone verifier checks files, decompressed image and audio independently. | Fresh x64 regression passes. A single fresh/resumable qualification command, matching full evidence, published versioned artifacts and downloaded-artifact smoke test remain open. The local bundle is an earlier-source candidate, not a published release. |

Next implementation order: finish measuring the optimized fully guest-built
image, then close public task/terminal and debugging behavior using failing
visible tests. Keep these failures in the qualification report; a publication
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
