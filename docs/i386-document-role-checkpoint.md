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

## Terminal palette and prompt compatibility repair

The failed return frame was entirely black: the terminal's retained surface
initialized black-on-white, but its task text attribute remained zero. Original
DocRecalc uses the window task attribute as its default, so restoring that value
after the rich fixture rendered black-on-black. Terminal creation now publishes
the surface's palette into the task attribute after successful allocation. This
happens once, not at each frame or output operation; applications can still change
the task colors normally. No public layout/export/service-version change occurs.

A diagnostic control on the old image explicitly setting 0xF0 restores the
expected return frame byte-for-byte. Its subsequent input assertion exposes a
separate harness assumption: original DOCT_PMT selects green prompt input and
that color remains in effect across subsequent ordinary text/newlines. The
pinned-original oracle in `build/i386-c1-terminal-prompt-output-reference`
passes all seven cells for `6*7;42>` with attributes 0xF2, in addition to the
existing A/B callback/cell/glyph checks; inputs remain unchanged.

The harness now accepts explicit per-command typing/return color maps for custom
startup sessions. The terminal fixture uses the original green expectations for
the continued command, result and next prompt, preserving exact full-screen
comparison. The first color-map attempt used x/y keys instead of row/column and
correctly failed; its corrected typing map then exposed the inherited output
color. These are superseded fixture attempts, not additional OS fixes.

Current fixed candidate: `build/i386-c2-terminal-palette-cross/kernel.img`.
Original two-generation bootstrap, cross-build and limited 386 boot audit pass;
all 1473 source/build input hashes match. Normal 8 MiB startup passes nine
commands in 48.998 seconds with WinMgr enabled and zero build-provider loads.
Key-device checks pass 21 commands with unchanged pinned inputs; output-routing
checks pass ten commands at 8 MiB; automatic window-error isolation passes
fourteen commands. Terminal-return and held-frame checks are recorded below
when their runs finish.

The larger unpaused editor/help/navigation regression runs separately on the
pinned preceding Console-88 image (`build/i386-c2-document-role-private-views`),
so it isolates view-ownership integration before this palette repair. It has
not yet qualified the current image. Complete C2/C4, ordinary cursor/input roles,
full application workflows and C5 native release generations remain open.

The final existing-terminal run in
`build/i386-c2-terminal-palette-return-final/result.json` passes all nine
commands, exact A/B/return/input/output frames and arithmetic, with unchanged
inputs. `build/i386-c2-terminal-palette-frame/result.json` passes all fourteen
held-frame/manager-restart commands, also with unchanged inputs. These supersede
the earlier return/color-map failures above; the complete desktop remains open.

The fixed image also passes both nine-command same put/display-role and partial
stdout A/B regressions in `build/i386-c2-terminal-palette-put-display` and
`build/i386-c2-terminal-palette-stdout`, each with unchanged pinned inputs.
