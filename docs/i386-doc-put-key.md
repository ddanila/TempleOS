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
| Key descriptions and names | Kernel/KeyDev.HC KeyDescSet and Kernel/SerialDev/Keyboard.HC Char2KeyName; preserve formatted description and handler identity, not just returned key text. |
| Tree/plain-text transformations | DocRecalcLib.HC DocCollapse and DocPlain.HC DocEntryToggle/DocFlagsToggle; cover tree state, serialized text and undo-ring preservation. |
| Find, matching and go-to | DocFind.HC; preserve directional matching, selection, find state and interactive prompts. |
| Autocomplete | Adam/AutoComplete services ACMan, ACFillIn, ACDDef, ACDFillin and AutoComplete; requires actual symbol/dictionary behavior and task integration. |
| Files and directory context | DocWrite prompt path, DirContextNew/Del, DirFile, FileFind, AdamFile, PopUpFile and file/directory pickers; current bounded file adapters do not prove these workflows. |
| Macro editing and replay | DocMacro.HC, sys_macro_task/head and PostMsgWait; existing strip/replay services are prerequisites, not qualification of EdMacroUtil. |
| Desktop tools | FileMgr, FindWiz, EdCodeTools, EdInsWidgetWiz, WinBorder and Ed; require real UI/tool execution and document/window restoration. |
| God and graphics tools | GodDoodle, GodSong, GodWord, GodBiblePassage, GodBitsIns, god FIFO/event time and EdSpriteEd/Ins; these overlap the required C3 application/service work. |

Also audit bare no-argument calls and globals: a function-call regex alone misses
PlaySysMacro, picker/tool invocations and global state. Private provider aliases
must preserve the original service contract and resource ownership. Compile the
full body, then require direct input, actual chooser, normal editor, GetStr and
TimeClock workflows on the delivered normal image. C1–C5 remain incomplete.
