# Document-role integration checkpoint (2026-10-15)

Console 88 is a development candidate for C2/C4, not a fully qualified desktop.
Memory remains version 25; public exports and the private console service table
are unchanged from Console 87.

## Renderer selection and stdout

A document may serve as both put_doc and display_doc. Pointer equality therefore
cannot distinguish an ordinary document view from a retained private editor.
The manager now uses explicit scoped ownership for editor/help/picker views.
Their focused retained presentation suppresses automatic document composition.
Scopes restore editor document pointers and release view ownership on ordinary
return, exception and committed Exit. This is not proof of complete editor undo,
foreign-owner document or arbitrary callback-resource lifetime handling.

Plain terminal documents retain their incremental text projection. Rich entry
kinds, callback tags, nondefault text attributes, selected formatting flags and
custom output hooks select document rendering. Partial dollar-format output
selects that path before callbacks run; the selection remains sticky because the
old text projection can become stale. Public string output uses DocPrintPartial;
output to another document no longer also writes into the root terminal.
System window-error reports explicitly target the retained root console.

## Executable checks

Run on fresh output directories:

```sh
python3 tools/test-i386-put-display-refresh.py IMAGE --out OUT1
python3 tools/test-i386-stdout-document.py IMAGE --out OUT2
python3 tools/test-i386-terminal-document-refresh.py IMAGE --out OUT3
```

Matching `*-reference.py` runners and guest fixtures capture original-system
behavior. The same-role and existing-terminal fixtures check A/B glyph pixels
and dynamic callback progress. The stdout fixture checks split dollar-format
state, red A followed by black B, document roles and restored-console isolation.
All native fixtures continue with arithmetic after restoring their view.

Original reference runs passed in `build/i386-c1-put-display-reference`,
`build/i386-c1-stdout-document-reference` and
`build/i386-c1-terminal-document-reference`, with inputs unchanged during each
run. Two reference report descriptions were subsequently clarified; those older
reports do not pin the current wrapper bytes. Previous Console-87 native runs
failed their first A observation. The timeout/harness subsequently changed;
those red reports likewise describe their pinned inputs, not current checkers.

Current candidate: `build/i386-c2-document-roles-cross-fixed/kernel.img`.
Original bootstrap, cross-build and the limited 386 loader instruction audit
pass. Python compilation and `git diff --check` pass. Native visual results are
listed below after execution; build success alone is insufficient.

The input harness adds `--keep-window-manager` for component sessions. Use it
with document-editing, help and file-navigation groups to qualify private views
under the live manager. These regressions, current 8 MiB startup, error routing,
key-device behavior and Refresh lifetime/frame regressions remain open for this
candidate. Persistent graphics admission, full cursor/input/event semantics and
application workflows also remain open. C1–C5 are not complete.

## Earlier development native build

`build/i386-c2-refresh-native-kernel/result.json` now reports pass. It builds six
flat modules on a pinned Console-86 image, installs the 571240-byte flat kernel,
and boots independently at 8 MiB (`486,-fpu`); the build used 16 MiB. Retained
modules are cross-built development inputs. Flat SHA-256:
`3c2d804d2d7c191934cba79ef81c342ec6b8404ffff93ba132ffecced5fe9ae1`.
This is neither a current Console-88 rebuild nor two full native generations.

## Native checkpoint results

- `build/i386-c2-checkpoint-put-display-refresh/result.json`: pass.
- `build/i386-c2-checkpoint-stdout-document/result.json`: pass.
- `build/i386-c2-checkpoint-terminal-document-refresh/result.json`: fail.

All three reports confirm unchanged inputs. The terminal-document run reaches
both independent A/B frame observations, returns through `DOC AUTO end` and
logs `COMMAND OK`, but times out checking the restored console framebuffer.
Its final `6*7` command is therefore not submitted. This is an open terminal
return/input integration gate, not a passing terminal qualification. Inspect the
captured return frame and reconcile document/model/presentation state before
changing expectations; do not substitute a fresh document for this fixture.

Next: repair/qualify that return path, then run unpaused editor/help/navigation,
minimal startup and stdout/error/Refresh regressions on current sources.
