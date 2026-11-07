# File-search wizard workflow

`tools/test-i386-find-wizard.py` follows the original Shift-Ctrl-F route through
wizard acceptance, directory selection and the separate interactive result
task. It uses complete original `Find.HC` and `FileMgr.HC`, with delivered-source
hash checks. This extends the cancellation-only wizard coverage in
`docs/i386-doc-search-keys.md`.

The fixture supplies an explicit document different from `DocPut`, accepts the
wizard after formatting its real string fields and checkboxes, and checks that
only `DocPut` receives the settings. The wizard is identified by its exact
first-field format, three data fields, four checkboxes and initially checked
recursion setting. The host cancels the real directory picker in the first
case and accepts the selected root directory in the second.

Both cases check the entire copied search record, unchanged explicit-document
record, caller put/display/border/popup roles, lock release and working
directory. The actual result task is discovered through its document and
command-prompt state; no search routine or popup is mocked or replaced.

The fixed search is `n"eedle`, with case matching and whole labels enabled,
recursion left enabled and mask `*.TXT`. The dataset contains:

| File | Contents | Expected matches |
| --- | --- | --- |
| `A.TXT` | `n"eedle one`, `N"EEDLE mixed`, `n"eedlex` | First line only |
| `Nested/B.TXT` | `n"eedle two` | First line |
| `Skip.BIN` | `n"eedle excluded` | None |

The quote in the needle exercises the wizard's `%Q` quoting when constructing
the real popup command. The host checks two exact `PL:` file/line links and
corresponding text, then verifies a fresh rendered `42` after typing `6*7` in
the result window. Shift-Esc closes the real result task. Native runs also
execute fresh arithmetic in the restored caller and audit every preexisting
file tuple, fixture additions and filesystem allocation bitmap.

The original `build/i386-find-wizard-original-v1` passes both masks 63,
returns the two links in nested-file then root-file order, renders `42` and
closes the result task. Its saved `wizard-results.DD` includes the two result
lines, result count 2, elapsed time and the interactive prompt. Elapsed time
must be treated explicitly in any document comparison; it is not deterministic.

Run the original or native control with:

```sh
python3 tools/test-i386-find-wizard.py --out OUT
python3 tools/test-i386-find-wizard.py IMAGE --out OUT
```

This is public shortcut dispatch with programmatic form editing and physical
picker/terminal input. It does not qualify physical Shift-Ctrl-F entry here,
physical form editing, pixel-equivalent windows, heap balance, replacement
menus or failure/interruption cleanup. Optional applications are explicitly
loaded in native Adam before the test; default startup loading remains open.
The complete `Find.HC`, DocPutKey and desktop inventory entries remain
unqualified.

The initial native v1 attempt stopped during setup: loading FileMgr in Adam
rejected `GrPrint` at original source line 574. The corrected runner loads
FileMgr in the caller, as the earlier real-picker contracts do, and Find in
Adam so the detached result task can resolve it. It checks nested command
rejections immediately rather than trusting an outer `COMMAND OK` alone.

With those scopes, native v2 passes both caller masks 63 and both real picker
paths, then raises the fixture's `WizTask` exception because no interactive
task retains the search links. The independent handoff contract in
`docs/i386-terminal-handoff.md` confirms the underlying document replacement:
the old native UserTaskCont loses preexisting output when it creates its
terminal instance. The wizard failure audit verifies unchanged input hashes,
all original file tuples and all four fixture additions. No file-search pass
is inferred from the successful form/picker phases.

## Native result window preserved

`build/i386-find-wizard-native-v4` passes on the normal-boot
`build/i386-terminal-handoff-cross-v2/kernel.img`. Both caller masks are 63;
the nested-file then root-file links and corresponding text match the original
byte-for-byte after only `T:/Probe/WizardScope` to `C:/Probe/WizardScope`
normalization. The result task renders fresh 42, exits on Shift-Esc, and the
caller executes arithmetic afterward. Its terminal audit verifies every input
hash, original file tuple and fixture addition independently of the runner.

The original elapsed-time/result-count line and current-directory prompt are
still absent from the native document; native displays `> ` instead. Those
are explicit remaining terminal-output differences. The test qualifies the
preserved result body and interactive task, not the complete result transcript
or full Find application. Post-result-close caller document roles and exact
popup heap reclamation are not separately asserted by this fixture.
