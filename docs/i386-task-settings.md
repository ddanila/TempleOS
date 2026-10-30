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
outside this fixture. The native red check is running at
`build/i386-task-settings-native-red`. C1–C5 remain open.
