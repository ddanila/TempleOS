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
