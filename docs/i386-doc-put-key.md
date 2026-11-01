# Complete original document input integration

The target is the entire original `Adam/DolDoc/DocPutKey.HC` dispatch, including
its application/tool shortcuts. The current native `DocPutKey` in
`Kernel/I386/DocumentRuntime.HC` is a retained basic editing wrapper. Sharing
original character primitives and undo has not replaced this wrapper. The
existing message-driven chooser oracle remains an end-to-end integration gate.

## Public behavior oracle

`tests/guest/i386-doc-put-key-reference/PutKey.HC` runs the same six public-API
cases on both targets. Each expects mask 63, checking the input action and exact
text, callback behavior, unlocked return, caller document/display preservation
and exact heap recovery:

| Case | Independent expectation |
| --- | --- |
| Consuming user callback | Called once before document locking, with exact document/data/key/scan; returning TRUE suppresses editing. |
| Fallthrough user callback | Same callback contract; FALSE permits insertion of X before AB. |
| Default output document | A null document argument edits the caller's current output document. |
| Ordinary insertion | X before AB produces XAB. |
| Overstrike | Insert scan toggles overstrike; X replaces A, producing XB. |
| Undo dispatch | With an explicitly seeded snapshot, typing then Alt-Backspace restores AB and consumes the snapshot. |

The first original run passed the first five cases but exposed an invalid undo
setup assumption (mask 57). A fresh document does not guarantee an immediate
unforced snapshot: original timing is relative to its last timestamp. The final
fixture seeds the snapshot explicitly and uses `SCF_ALT|SC_BACKSPACE`, rather
than a modifier-only synthetic scan code. It does not change the expected text
or weaken the undo assertion.

`build/i386-c4-put-key-seeded-reference/result.json` passes six masks of 63 on
the qualified current x64 rebuild, with unchanged inputs. Reproduce with fresh
output directories:

```
python3 tools/test-i386-doc-put-key-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-doc-put-key.py build/i386-c2-undo-qualified-cross/kernel.img --out build/NEW-native
```

On Console 106 the fixture compiles and the first call, PKCheck(0), throws the
explicit PutKey assertion. `build/i386-c2-put-key-contract-red/result.json`
records failure with unchanged inputs. The retained wrapper does not invoke
user_put_key, so it cannot meet callback interception semantics. The runner
stops at that first rejection; no native success is claimed for later cases.

The fixture sets DONT_SWAP_OUT to avoid incidental scheduling. It does not
qualify yielding, concurrent ownership, incoming locks, invalid signatures,
keyboard-description mode or exceptional callbacks. Those need separate cases.
The real chooser test additionally covers form actions and message delivery;
these direct input cases do not replace it.

## Full dependency work

Review and integrate complete services before replacing the public dispatcher.
Do not prune shortcuts, insert no-op branches, or add an Enter-only chooser
handler to pass the current tests.

| Dependency family in original DocPutKey | Canonical source and next work |
| --- | --- |
| Editing, clipboard and undo | DocChar.HC, DocClipboardCore.HC and DocUndoCore.HC are shared with bounded contracts. Route the original dispatcher through these services and retain their regressions. |
| Key descriptions and names | Kernel/KeyDev.HC KeyDescSet and Kernel/SerialDev/Keyboard.HC Char2KeyName now share complete bodies with Console 107; [bounded paired contracts and the control-name bug fix](i386-key-description.md) preserve formatted description and handler identity. Full description-mode dispatcher routing remains open. |
| Tree/plain-text transformations | DocRecalcLib.HC DocCollapse and DocPlain.HC DocEntryToggle/DocFlagsToggle now share full bodies in Console 108; [paired transformation contracts](i386-doc-transform.md) cover tree flags, exact text, entry round-trips, undo bytes/rings and cleanup. UI and exceptional/foreign-owner paths remain open. |
| Find, matching and go-to | DocFind.HC read-only search/pair/function-selection bodies now share with Console 109; [paired search contracts](i386-editor-search.md) cover exact positions, boundaries, selection/filtering and cleanup. Complete replacement and go-to bodies now compile in the optional provider; [fourteen paired replacement/navigation/metadata contracts](i386-editor-replace.md) pass on original and native. Prompted replacement/go-to workflows remain open. Existing Console dependencies resolve through a permanent export table in the optional provider, preserving the minimal budget. [the complete class-form wrappers](i386-class-form.md) now compile in Console 111’s optional provider, but real numeric accept remains red (12 instead of 42). The strengthened original oracle also checks the live edited tag before cancellation. [The measured provider boundary](i386-editor-provider.md) preserves the minimal startup budget. |
| Autocomplete | Adam/AutoComplete services ACMan, ACFillIn, ACDDef, ACDFillin and AutoComplete; requires actual symbol/dictionary behavior and task integration. |
| Files and directory context | DocWrite prompt path, DirContextNew/Del, DirFile, FileFind, AdamFile, PopUpFile and file/directory pickers; [twelve original directory-context contracts](i386-directory-context.md) now pass, including nested restoration and rollback after partial directory progress. Native DirContextNew remains unbound; current bounded file adapters do not prove these workflows. |
| Macro editing and replay | DocMacro.HC, sys_macro_task/head and PostMsgWait; existing strip/replay services are prerequisites, not qualification of EdMacroUtil. |
| Desktop tools | FileMgr, FindWiz, EdCodeTools, EdInsWidgetWiz, WinBorder and Ed; require real UI/tool execution and document/window restoration. |
| God and graphics tools | GodDoodle, GodSong, GodWord, GodBiblePassage, GodBitsIns, god FIFO/event time and EdSpriteEd/Ins; these overlap the required C3 application/service work. |

Also audit bare no-argument calls and globals: a function-call regex alone misses
PlaySysMacro, picker/tool invocations and global state. Private provider aliases
must preserve the original service contract and resource ownership. Compile the
full body, then require direct input, actual chooser, normal editor, GetStr and
TimeClock workflows on the delivered normal image. C1–C5 remain incomplete.

## Callback, undo and overstrike components (2026-11-01)

The native wrapper now resolves a null argument through `DocPut`, invokes
`user_put_key` before locking and honors consumption, marks undo dirty for the
original scan-code set and invokes `DocCaptureUndo`. It handles the original
Alt-Backspace undo dispatch and unmodified Insert overstrike toggle; the
retained plain-text editor replaces an existing character when overstrike is
set. These are components of the original dispatcher, not its complete menu,
selection, character-entry or shortcut behavior.

The pinned original and native at both 64 and 8 MiB pass the six-case fixture
with exact text, callback/lock state, roles and allocation balance
(`build/i386-doc-put-key-reference-explicit-v1`,
`build/i386-doc-put-key-core-native-v2`,
`build/i386-doc-put-key-core-native-8m-v1`). The native baseline with the
current welcome-screen runner failed the callback case before the change
(`build/i386-doc-put-key-current-native-red-v2`); an earlier run timed out at
the outdated initial-screen expectation. The fixture now compares the 64-bit
overstrike flag explicitly with zero. Before that correction, the same
original fixture returned 63 while native returned 61 despite producing the
expected overstruck text (`build/i386-doc-put-key-current-reference-v1`,
`build/i386-doc-put-key-inspect-v1`). The direct assignment of that bit-32
expression to `Bool` therefore remains a separate observed compiler
compatibility difference; the explicit comparison does not qualify it.

Both bootstrap generations, the full cross-build/386 audit and the 16 MiB
startup diagnostic pass (`build/i386-doc-put-key-core-rebuild-v2.log`,
`build/i386-doc-put-key-core-cross-v2`,
`build/i386-doc-put-key-core-diagnostics-v1`). The isolated 8 MiB startup
completed all nine functional/VGA checks but took 61.091 seconds and missed the
60-second gate (`build/i386-doc-put-key-core-startup-v1`). Two attempts to run
the older typed-dollar runner timed out while typing its long second
definition, before a behavioral verdict (`build/i386-doc-put-key-core-dollar-
v1`, `build/i386-doc-put-key-core-dollar-v2`); its prior coverage is not
requalified by this change. Full original `DocPutKey` and C1–C5 remain open.

The original actionable-character branch is now shared with the native
wrapper. A 13-case terminal-menu comparison passes against the original,
including action and cancellation values and exact serialized menu documents;
see [terminal-menu evidence](i386-term-right-menu.md). This exercises Space on
selected buttons and does not complete the original key dispatcher.

## Direct entry-action comparison (2026-11-01)

A seven-case `DocPutKey` fixture compares Space/left-expression and
Enter/right-expression messages, Shift-Space and Ctrl-Space suppression,
left/right callbacks and collapsible-entry toggling. It checks callback lock
state, final document lock and roles, message values and task-heap balance.
The pinned original, the rebuilt original with the shared action helper, and
native at both 64 and 8 MiB all return seven masks of 127 with unchanged inputs
(`build/i386-doc-key-action-reference-v2`,
`build/i386-doc-key-action-rebuilt-v1`,
`build/i386-doc-key-action-native-64m-v1`,
`build/i386-doc-key-action-native-8m-v1`). The first reference fixture used
unsupported ternary syntax and stopped in the debugger before its verdict
(`build/i386-doc-key-action-reference-v1`). The comparison does not exercise
mouse selection, macros, links, arbitrary editor shortcuts or complete original
`DocPutKey`; those and C1–C5 remain open.

## Form Tab transition (2026-11-01)

The native wrapper now follows the original `EdCharIns` form-Tab conditions:
Tab on an eligible form entry advances through `DocFormFwd`; overstrike Tab in
a form also advances, while overstrike Tab outside a form does not insert.
The actual advance is shared with the original editor through
`DocCharFormAdvanceCore.HC`. The remaining original character and key dispatch
is not replaced by this component.

Eight direct cases pass on the pinned original, rebuilt original and native at
64 and 8 MiB (`build/i386-doc-form-tab-reference-v1`,
`build/i386-doc-form-tab-rebuilt-v1`,
`build/i386-doc-form-tab-native-64m-v1`,
`build/i386-doc-form-tab-native-8m-v1`). They cover eligible links, skipped
entries, end-of-form recovery, ordinary Tab insertion, overstrike and Shift,
with document locks, roles and heap balance. The preceding native image fails
the first navigation case (`build/i386-doc-form-tab-native-red-v1`). The full
13-case terminal-menu regression also passes (`build/i386-doc-form-tab-menu-v1`).
These are direct input and menu tests, not a complete keyboard-driven chooser.

Both bootstrap generations, full cross-build/386 audit and 16 MiB diagnostic
pass (`build/i386-doc-form-tab-rebuild-v1.log`,
`build/i386-doc-form-tab-cross-v1`, `build/i386-doc-form-tab-diagnostics-v1`).
The isolated 8 MiB run completes all nine functional/VGA checks in 61.157
seconds and misses the 60-second gate (`build/i386-doc-form-tab-startup-v1`).
Full original document input and C1–C5 remain open.

## Chooser keyboard navigation and retained editor (2026-11-01)

The real chooser fixture now queues Tab, Shift-Tab and a Down key release as
well as the existing left/right action, Down, cancellation and unlocked callback
cases. The pinned and rebuilt original both return
`[11,12,22,-1,17,22,22,11,1]` with unchanged inputs
(`build/i386-menu-keyup-reference-v1`,
`build/i386-doced-keydown-rebuilt-reference-v1`). The preceding native image
passes the two Tab cases in isolation but times out on Down in the complete
fixture (`build/i386-menu-tab-only-native-v1`,
`build/i386-menu-tab-native-64m-v1`).

Form Up/Down now call the original line movers. The retained non-form editor
continues using its own line mover because its renderer does not populate the
layout coordinates those original functions need. The retained editor now
handles navigation on key down and forwards the scan code for printable input.
An earlier candidate applying the original line mover to all documents passed
the chooser at 8 and 64 MiB but failed the separate physical editor check;
that candidate was superseded (`build/i386-doced-keydown-menu-8m-v2`,
`build/i386-doced-keydown-menu-64m-v2`,
`build/i386-doced-keydown-physical-v1`). This is an integration boundary,
not completion of original document input, rendering or C1–C5. Mouse interaction,
full popup rendering and file-selection workflows remain unqualified.

The final candidate passes the complete queued chooser fixture at 64 and 8 MiB
(`build/i386-doced-keydown-menu-64m-v3`,
`build/i386-doced-keydown-menu-8m-v3`). Both bootstrap generations and the
full cross-build/386 audit pass (`build/i386-doced-keydown-rebuild-v3.log`,
`build/i386-doced-keydown-cross-v3`). The first physical editor run timed out
after the editor interaction because the test expected cleared console history; the expected editor screen had
already matched (`build/i386-doced-keydown-physical-v2`). A corrected run also
matched the editor and return screens but timed out while typing its long
serialization-check command (`build/i386-doced-keydown-physical-v5`). With
retained history and short serialization commands, the physical vertical
navigation, saved cursor and cleanup check passes
(`build/i386-doced-keydown-physical-v6`). The 16 MiB diagnostic and
terminal-menu regression pass
(`build/i386-doced-keydown-diagnostics-v2`,
`build/i386-doced-keydown-term-menu-v1`). The isolated 8 MiB run passes all
nine functional/VGA checks but takes 61.398 seconds and misses the 60-second gate
(`build/i386-doced-keydown-startup-v1`).

## Form document-boundary navigation (2026-11-01)

The original Home/End selection traversal now lives in
`DocKeyBoundaryCore.HC` and is shared by original `DocPutKey` and the native
form path, including the original form-forward/backward adjustment. Form
Ctrl-Up/Down follow the original fallthrough to those same boundaries. The
retained non-form editor still uses its separate navigation until its layout is
integrated. Selection flag traversal is shared original code but is not
independently qualified by the chooser cases below.

The actual chooser fixture now exercises End, End followed by Home, Ctrl-Down,
and End followed by Ctrl-Up. The pinned original and rebuilt original return
`[11,12,22,-1,17,22,22,11,22,11,22,11,1]`
(`build/i386-menu-boundary-reference-v1`,
`build/i386-menu-boundary-rebuilt-v1`). The previous native image times out on
the first End case with inputs unchanged
(`build/i386-menu-boundary-native-red-v1`). The candidate passes the entire
fixture at 8 and 64 MiB (`build/i386-menu-boundary-native-8m-v1`,
`build/i386-menu-boundary-native-64m-v1`), and its physical non-form vertical
editor test passes (`build/i386-doc-key-boundary-physical-v1`). Both bootstrap
generations, full cross-build and 386 audit pass
(`build/i386-doc-key-boundary-rebuild-v4.log`,
`build/i386-doc-key-boundary-cross-v4`). Earlier cross-build attempts exposed a
stale version manifest, an unavailable `BEqu`, and unsupported local `#undef`
(`build/i386-doc-key-boundary-cross-v1.log`,
`build/i386-doc-key-boundary-cross-v2`,
`build/i386-doc-key-boundary-cross-v3`); these were corrected in the candidate.
Full original input, selection, mouse and popup rendering remain unqualified,
and C1–C5 remain open.

The 16 MiB startup diagnostic and terminal-menu regression pass
(`build/i386-doc-key-boundary-diag-v1`,
`build/i386-doc-key-boundary-term-v1`). The isolated 8 MiB run completes all
nine functional/VGA checks in 61.196 seconds, missing the 60-second gate
(`build/i386-doc-key-boundary-startup-v1`).

## Form horizontal navigation and selection (2026-11-01)

Form Left/Right now dispatch to the original `EdCursorLeft` and `EdCursorRight`
functions, including their Ctrl and Shift behavior. The native bit-setting
adapter now accepts the full integer truth value: the original functions pass
the Shift mask (0x200), which was truncated by the adapter's `Bool` argument.
This also corrects the adapter used by the shared boundary traversal. The
retained non-form editor continues to use its existing mover pending layout
integration.

Eight direct form cases check left/right movement, skipped entries, Shift
selection, selection clearing, Ctrl movement, cursor position, locks, roles
and heap balance. The pinned original, rebuilt original, and native at 8 and
64 MiB return eight masks of 31 (`build/i386-doc-form-horizontal-reference-v2`,
`build/i386-doc-form-horizontal-rebuilt-v1`,
`build/i386-doc-form-horizontal-native-8m-v2`,
`build/i386-doc-form-horizontal-native-64m-v2`). The first original fixture
assumed Ctrl-Left stayed on its current entry; the actual unlaid-out entry
coordinates lead to the first entry (`build/i386-doc-form-horizontal-reference-v1`).
The previous native image fails the first Right case
(`build/i386-doc-form-horizontal-native-red-v1`), and the first candidate fails
Shift selection on both memory profiles
(`build/i386-doc-form-horizontal-native-8m-v1`,
`build/i386-doc-form-horizontal-native-64m-v1`).

The actual chooser adds Right and Down-then-Left. The pinned and rebuilt
original and revised native image pass (`build/i386-menu-horizontal-reference-v1`,
`build/i386-menu-horizontal-rebuilt-v1`,
`build/i386-menu-horizontal-native-64m-v2`); the previous native image times
out on Down-then-Left (`build/i386-menu-horizontal-native-v1`). Both bootstrap
generations, full cross-build and 386 audit pass
(`build/i386-doc-form-horizontal-rebuild-v2.log`,
`build/i386-doc-form-horizontal-cross-v2`). These checks do not qualify full
selection, non-form original layout, mouse input or C1–C5.

The revised image also passes the physical non-form editor check, the 16 MiB
startup diagnostic and the existing six-case dollar-parser contract
(`build/i386-doc-form-horizontal-physical-v2`,
`build/i386-doc-form-horizontal-diag-v1`,
`build/i386-doc-form-horizontal-dollar-v3`). The parser runner now packages
the identical fixture and checks the guest copy: its first retry expected the
old startup screen, and its second timed out typing the transfer helper before
any parser case (`build/i386-doc-form-horizontal-dollar-v1`,
`build/i386-doc-form-horizontal-dollar-v2`).
The isolated 8 MiB startup run passes all nine functional/VGA checks but takes
61.748 seconds, above the 60-second gate
(`build/i386-doc-form-horizontal-startup-v1`).
