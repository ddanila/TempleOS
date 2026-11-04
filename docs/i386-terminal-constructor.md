# Complete terminal constructor

The resident native console includes the unchanged original
`TermRightClickLinkCore.HC` and `DocTermNewCore.HC`, before the mapped-media
implementation aliases. Public headers bind `DocTermNew` through `_DOC_TERM_NEW`.
The console ABI is version 205 with 574 bindings. The callback retains all
original include, Adam include, copy/move/delete, type/editor, mount, plain and
input-file actions; it calls actual services rather than dependency stubs.

`tools/test-i386-terminal-constructor.py` executes the same constructor contract
on rebuilt original and native systems. Both pass mask 1023:

- A new task-owned document serves both put and display, with the original
  4096-entry limit, Term description and non-null right-click callback.
- The drive-derived border contains five callbacks referencing that document
  and one data entry referencing the current task title.
- The actual editor menu is loaded, including File/Save and File/Exit.
- Both scroll controls reference the task's scroll states and retain their
  drawing, input and derived-value callbacks; existing controls are reused.
- Raw mode is disabled even when explicitly enabled before construction.

The fixture restores previous task documents/menu/raw state and removes its
new objects before returning. The native test keeps the real window manager
running and successfully executes another arithmetic command afterward. It
qualifies constructor execution and object bindings, not exact heap recovery,
right-click actions, visible terminal behavior or autocomplete.

Evidence: `build/i386-terminal-constructor-reference-v1/result.json` and
`build/i386-terminal-constructor-native-v1/result.json`, with unchanged input pins.
The two-generation original rebuild passes in
`build/terminal-constructor-rebuild-v1.log`. The full-content native build passes
the 386 instruction audit and its independent source audit matches all 1,252
packaged candidate source/documentation files
(`build/i386-terminal-constructor-cross-v1/source-audit.json`). This is not a full
release qualification or a clean-revision reproducibility claim.

The 8 MiB normal-startup smoke test passes in 41.57 seconds with live WinMgr,
original welcome, constructor symbol lookup and exact framebuffer checkpoints
(`build/i386-terminal-constructor-minimal8-v1/result.json`). This is a bounded
smoke test, not the entire minimal-profile regression suite.

The unchanged real-service MakeAC load advances past DocTermNew and rejects
missing KbdMsEvtTime at ACTask.HC line 230
(`build/i386-terminal-constructor-autocomplete-v1/result.json`, input pins
unchanged). No autocomplete task is explicitly activated. That failed probe
identifies the next service dependency rather than qualifying autocomplete.
