# Task settings dependency

The unchanged Budget loader reaches `SettingsPush` in `BgtMain.HC` line 182
(`build/i386-budget-native-load-v5`). The original settings stack preserves
nested task/document/window fields, directory, palette, song and animation tasks,
autocomplete and sound. Its pop path also restores window state twice around a
refresh. These dependencies are part of the contract; a field-only stack is not
a complete implementation.

A first executable original-system reference checks nested stack order and
restoration of terminal attributes, scroll offsets, title, document cursor
visibility, window bounds, working directory and VGA palette. All eight checks
pass with unchanged inputs (`build/i386-task-settings-reference-v3`). Sound,
autocomplete, task suspension, failure cleanup and cross-task behavior remain
outside this fixture. The native fixture is rejected earlier at the missing public `DirCur` binding
(`build/i386-task-settings-native-red`); this is a prerequisite of the
settings contract as well as of the original implementation. C1–C5 remain open.

ConsoleRuntime 142 now exports the shared original `DirCur` body. Original
and native current-directory copy checks pass; see
[current-directory evidence](i386-dir-cur.md). This resolves that fixture
prerequisite, not the settings stack itself.

ConsoleRuntime 144 also exports hardware-backed palette get/set services. The
original and native 16-color DAC reference, restoration and interrupt-state
checks pass; see [VGA palette evidence](i386-vga-palette.md). Autocomplete and
the full settings lifecycle remain to be implemented.

The original `CTaskSettings` declaration and `TSF_SAME_SONG` flag are now
shared through `Kernel/TaskSettingsTypes.HH`, making the complete record
available to native callers. The reference record is 392 bytes on the original
64-bit system and 368 bytes on i386; the native pointer slots are four bytes,
while the non-pointer fields retain their original widths. The independent
architecture-specific layout and field checks pass on the original and native
systems (`build/i386-task-settings-record-reference-v2`,
`build/i386-task-settings-record-native-v2`) with unchanged inputs. The first
comparison incorrectly required equal offsets across architectures and is
retained at `build/i386-task-settings-record-native`. Both bootstrap generations
and the cross-build/386 audit pass (`build/rebuild-test`,
`build/i386-task-settings-record-cross`); the concurrent native run does not
qualify startup timing. The settings fixture on the preceding image reaches the
missing `SettingsPush` binding (`build/i386-task-settings-native-red-v2`), and
the stack, autocomplete and task lifecycle remain open.

A second original-system reference exercises the task portion of the stack:
song and animation tasks are suspended and detached on push, replacement
tasks are killed on pop, saved tasks are resumed, and `TSF_SAME_SONG` preserves
the active song task. All seven checks pass with unchanged inputs
(`build/i386-task-settings-tasks-reference-v1`). This records task lifecycle
behavior without claiming audio-output, autocomplete, failure-cleanup or native
settings-stack coverage. The executable is
`tools/test-i386-task-settings-tasks.py`.

The autocomplete control's task-death dependency is now available through
the shared original `BirthWait` and `DeathWait` services. Their ordinary and
user-task `send_exit` contracts pass on original and native systems; see
[task wait evidence](i386-birth-death-wait.md). Autocomplete itself and the
settings stack are still incomplete.

The original autocomplete state records and `ac`/`acd` globals are now
available, but the unchanged source load next rejects `FOpen`; dictionary
assets are also absent from the tested native image. See
[autocomplete state evidence](i386-autocomplete-state.md). The actual task,
initialization and settings stack remain open.

The complete original `SettingsPush`, `SettingsPop2` and `SettingsPop` bodies
are now shared byte-for-byte through `Adam/TaskSettingsCore.HC`; the original
`TaskSettings.HC` retains its help index and includes that core. Original-system
runs using the extracted source pass the nested-restoration mask 255 and the
task-lifecycle mask 127 with unchanged inputs
(`build/i386-task-settings-shared-original` and
`build/i386-task-settings-tasks-shared-original`). Both runners accept
`--shared` to repeat these checks against the current source. These checks do
not cover autocomplete, audio waveform, cross-task behavior or failure cleanup.
Both bootstrap generations and the 386 cross-build/audit pass
(`build/rebuild-test`, `build/i386-task-settings-shared-cross`). The native
stack remains unbound pending its full dependencies, including the
real autocomplete lifecycle and drive initialization; Budget and C1–C5 remain
open.

The current native image compiles the complete shared settings bodies when an
explicitly throwing autocomplete test provider is supplied
(`build/i386-settings-compile-v1`; runner `tools/test-i386-settings-compile.py`).
The probe never executes settings and does not implement autocomplete. A new
remote-task fixture checks nested stack order and restoration of another
spawned task's attributes, scrolling and title on the pinned original and the
shared original implementation (mask 31, unchanged inputs;
`build/i386-task-settings-remote-original-v1`,
`build/i386-task-settings-remote-shared-v1`; runner
`tools/test-i386-task-settings-remote.py`). The current native image rejects
`SettingsPush` before executing the fixture
(`build/i386-task-settings-remote-native-red-v1`). This is not complete
cross-task, autocomplete, failure-cleanup or settings-stack qualification.

## Real autocomplete lifecycle comparison (2026-11-05)

The complete original settings bodies now execute successfully on the current
native runtime after loading the real autocomplete and settings libraries.
`tools/test-i386-settings-lifecycle.py` combines the existing nested-fields,
song/animation and remote-task contracts with actual dictionary initialization
and autocomplete preservation/restart/stop checks. It asserts that the shared
settings core still contains the complete pinned-original bodies. No provider
replaces AutoComplete, task handling, the palette, or directory operations.

In `build/i386-settings-lifecycle-v1`, the fresh pinned-original reference and
native v2 both return `[255,127,31,63,95293]` with unchanged inputs. Native v2
loads both libraries through actual AdamFile jobs; the contracts then execute
in the child console against inherited public bindings. SettingsPop recreates
an autocomplete task that was active at push and restores an inactive state by
killing a replacement task. Existing field, palette, window, directory,
song/animation, TSF_SAME_SONG and remote-task assertions also pass. The native
filesystem audit passes at 64 MiB KVM `486,-fpu`. The reference uses the pinned
original and the previously verified original word-list archive.

The v1 native pass loaded settings directly in the user namespace; v2 adds the
Adam-publication/child-inheritance check and null-safe failure recording in the
fixture. Its earlier exact driver/fixture are frozen beside the v1 result.
Evidence directories `build/i386-settings-lifecycle-reference-v2` and
`build/i386-settings-lifecycle-native-v2` are inside the settings-lifecycle
checkout. These runs do not establish automatic boot loading, source-statistics
initialization, audio waveforms, allocation/break cleanup or whole settings/UI
qualification. Public bindings become available after explicit real-library
loading; the default native startup still needs integration.

The Budget load driver now supports already bundled original files and explicit
real-library loading. With both libraries loaded in Adam, unchanged Budget
compiles past SettingsPush and AutoComplete, then rejects MenuPush at
BgtMain.HC line 187 (`build/i386-budget-settings-load-v1/result.json`, inputs
unchanged). No app fixture is added; installation and application execution do
not run after that rejection. Menu stack bindings are the next dependency.

## Budget after menu-stack bindings (2026-11-06)

With Console 212, build/i386-budget-menu-load-v2 loads the actual autocomplete
and settings libraries into Adam, then compiles the unchanged bundled Budget
source past MenuPush. It next rejects PutExcept in BgtMain.HC (reported at
line 218, immediately after the call). Inputs remain unchanged. Installation
and application workflows are not reached. The earlier v1 run saw the same
rejection but its input audit failed because the inventory was edited during
execution; v2 is the unchanged-input evidence.

PutExcept is a real exception-reporting service, including caller diagnostics
and the catch flag; providing a dummy declaration would not satisfy this
dependency. Full Budget and C1-C5 qualification remain open.

## Original PutExcept service (2026-11-06)

Console 213 exposes the complete original PutExcept body through
Kernel/PutExceptCore.HC, shared with Kernel/KExcept.HC. Its default TRUE
argument sets the current task's catch flag after reporting; FALSE preserves
propagation. The original format passes eight caller values to six %P fields;
the extraction preserves that behavior exactly. Existing export indices remain
unchanged, with the new service appended.

The pinned original in build/i386-put-except-reference-v2 and native 64 MiB KVM
comparison in build/i386-put-except-native-v1 both pass mask 31 with unchanged
inputs. The fixture checks default acceptance, explicit rejection, an actual
handled throw and a nested throw propagated to an outer handler. Four actual
reports match the independently constructed 521-byte DolDoc record, including
six clickable AD links per report and the terminating document byte. Caller
addresses are controlled (1 through 8); arbitrary symbolized stacks, every
formatting case and whole application workflows are not claimed.

Both original bootstrap generations pass in build/rebuild-test/result.json.
The full-content cross build in build/i386-put-except-cross-v1 passes its
386 audit (96 BIOS and 332 protected-mode instructions); all 1368 delivered
source/doc files match the candidate in
build/i386-put-except-source-audit-v1.json. These checks do not close C1-C5.

The 16 MiB diagnostic boot also passes through DONE native kernel startup
and matches all 307200 welcome pixels in
build/i386-put-except-diagnostic-v1/screen-oracle.json.

Budget now compiles its complete Load.HC and returns from Install.HC in
build/i386-budget-put-except-load-v1, with unchanged inputs and an adjacent
fresh arithmetic command. The installation checker fails because /Budget
exists but its accounts file does not. Install.HC requests Accts.DD.Z while
the full native image delivers /Apps/Budget/Accts.DD; the resulting working
image still has only the original eleven application files and no accounts
copy under /Budget. Compression-name resolution/packaging is the next issue
to investigate; a successful include is not a successful installation or
Budget workflow. No application qualification is claimed.
