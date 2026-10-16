# Original terminal right-click menu

ConsoleRuntime 133 shares the complete original PopUpTermRight body, extracted
byte-for-byte from DocTerm.HC. Its ten action constants live in a shared guarded
header. The native public binding is appended at index 327; existing bindings
and the eleven-word data mask stay unchanged. The function still constructs the
entire document, runs original PopUpMenu in a real popup task, deletes its menu
document and returns the selection.

The fixture selects each of the ten action values, the Cancel button, and
Shift-Esc, and an explicitly covered popup. A helper task waits for the popup's real DocEd session, selects the
requested button entry and posts a keyboard message. This tests the actual
chooser/servant path; it does not claim mouse navigation or execution of the
right-click callback's selected file operation. Each case requires eleven
buttons, progressing window-manager updates and restoration of caller put/display
documents and popup owner. Three
saved menu buffers cover text, null and empty headers.

The first fixture selected every entry carrying a left-expression flag. The
original representation has additional non-button entries with those flags,
so it counted 22 entries and stalled at the second selection. The initial
120-second failure and the deliberately stopped tracing run are preserved in
`build/i386-c2-term-right-menu-reference` and
`build/i386-c2-term-right-menu-reference-trace`. Restricting selection to
DOCT_BTTN repairs the fixture without changing production menu behavior.

The corrected pinned-original and rebuilt-original runs pass all thirteen cases
(mask 8191), with unchanged inputs and identical saved menu hashes:

- `build/i386-c2-term-right-menu-reference-covered/result.json`
- `build/i386-c2-term-right-menu-rebuilt-covered/result.json`

The first native integration times out after selecting its first button in
`build/i386-c2-term-right-menu-native`. Traces show the 677-byte menu capture,
file write and key posting all finish, but `winmgr.updates` stays at 56 across a
one-second sleep. The popup remains unfocused and idle in Refresh. The tracing
artifacts are `build/i386-c2-term-right-menu-native-trace` and
`build/i386-c2-term-right-menu-native-refresh-trace`; the latter was stopped after
confirming the stall. The preceding Console 132 image rejects PopUpTermRight
in `build/i386-c2-term-right-menu-native-red`.

The window manager previously chose the document path based on shown documents,
then rejected the frame if all those documents were covered. It skipped the
legacy presenter as well, so no completed frame advanced Refresh. The candidate
now tries the legacy presenter after a declined document frame. That presenter
rechecks live coverage under its own presentation lease; a real completed frame
is still required before incrementing updates. Original servant startup remains
absent, so this does not qualify popup placement or visibility.

Fresh bootstrap and the refreshed cross-build pass, including the 386 audit,
with all 1530 source and 24 build inputs unchanged in
`build/i386-c2-term-right-menu-refresh-cross/input-audit.json`. The nine-command
visible dynamic-document regression passes in
`build/i386-c2-term-right-menu-visible-refresh`; the fifteen-command ordinary
Refresh modes regression passes in `build/i386-c2-term-right-menu-refresh-modes`,
both with unchanged inputs.

The full native menu gate still fails in
`build/i386-c2-term-right-menu-native-covered`. Refresh now advances from 68 to
83, but the first button is not activated. Public native DocPutKey still uses
DocBasicEditCore, which lacks the complete original action dispatch. The full
original DocPutKey dependency graph remains required; no reduced button handler
is substituted. The separate `--refresh-only` case uses ShiftEsc on an explicitly
covered popup to isolate frame progress and restoration from button activation.
Its original control passes in `build/i386-c2-term-right-menu-refresh-reference`.
The pre-fix image fails in `build/i386-c2-term-right-menu-refresh-red`, with the
update counter fixed at 55. The corrected image passes all four commands in
`build/i386-c2-term-right-menu-refresh-native`: the counter advances from 57 to
71, ShiftEsc returns cancellation, and caller roles are restored. Both execution
input sets remain unchanged. `control-comparison.json` in the refreshed cross
build confirms WindowManager.HC is the only changed source and ConsoleRuntime
the only changed module. The isolated 8 MiB startup gate passes in 58.406789 seconds in
`build/i386-c2-term-right-menu-startup`, including all nine behavior/VGA checks,
no build-provider loads and all four input hashes verified. The C5 launcher and
guest were paused together during this gate and resumed afterward. The 16 MiB
diagnostics pass in `build/i386-c2-term-right-menu-diagnostics`: startup
226.308863 seconds, all 128 immediate-push, 22 publication and 28 program cases,
both memory phases, nine behavior/VGA commands, no build-provider loads and
all four input hashes verified.

```sh
python3 tools/test-i386-term-right-menu.py --out ORIGINAL
python3 tools/test-i386-term-right-menu.py --shared --out REBUILT
python3 tools/test-i386-term-right-menu.py IMAGE --reference ORIGINAL --out NATIVE
# Separate covered-popup refresh contract (does not qualify button activation):
python3 tools/test-i386-term-right-menu.py --refresh-only --out REFRESH_ORIGINAL
python3 tools/test-i386-term-right-menu.py IMAGE --refresh-only --reference REFRESH_ORIGINAL --out REFRESH_NATIVE
```

TermRightClickLink and original DocTermNew/UserStartUp integration remain open.
The callback needs full Copy/Move/Delete, file-input and mount services, among
other dependencies; this menu does not replace those operations. All 686
inventory entries and C1–C5 remain unqualified.
