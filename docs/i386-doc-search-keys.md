# Ctrl-F and Shift-Ctrl-F dispatch

Native public `DocPutKey` now restores the original Ctrl-F find/replace and
Shift-Ctrl-F file-search dispatch. Both final API and physical shortcut tests
match the pinned original, including distinct form identity, cancellation,
replacement ALL/cancel, metadata and caller-state restoration. This is a
bounded C2/C4 checkpoint; complete editor and file-search qualification remain
open.

The pinned original `Adam/DolDoc/DocPutKey.HC` routes Ctrl-F to
`EdFindReplace(doc)` and Shift-Ctrl-F to `FindWiz`. The latter operates on
`DocPut`, not the explicit argument passed to `DocPutKey`. Alt suppresses
both routes. Dispatch follows the control character even without the Ctrl
scan flag. Metadata strings are `Edit/Find & Replace` and `Cmd /Search Files`.

`tools/test-i386-doc-search-keys.py` exercises the public dispatcher with the
complete original forms and replacement menu. Its fixture observes the actual
caller form, formats the first string field through `DocDataFmt`, and posts
Esc or ShiftEsc. For replacement ALL it selects the real menu button before
posting Esc. The observer retires when dispatch returns, so a missing native
route produces a state mismatch instead of leaving a waiting helper task.

The nine action cases are:

1. Accept a form changing the find string from `cat` to `dog`; cursor moves to
   column 4 in `cat dog cat dog`.
2. Cancel that edited form; both search record and cursor remain unchanged.
3. Accept replacement and choose ALL; text becomes `DOG dog DOG dog`.
4. Accept replacement and cancel its menu; text remains unchanged.
5. Open and cancel the Shift-Ctrl-F file-search form.
6. Alt-Ctrl-F suppression.
7. Alt-Shift-Ctrl-F suppression.
8. Accept the edited search form with an incoming document lock.
9. Accept with the Ctrl character but without the Ctrl scan flag.

Each action checks seven bits: expected form/menu counts and form identity, entire search
record, complete text line, cursor for non-replacement cases, incoming lock,
caller document/popup roles, and unchanged key description. Replacement
cursor positions are logged, not asserted. Four metadata cases check exact
strings, search-record preservation, cursor/lock and caller document roles.

The original control `build/i386-doc-search-keys-original-v2` passes all nine
127 masks and all four 15 metadata masks with unchanged inputs. This records
API dispatch and real form/menu behavior, not physical shortcut entry or
keyboard editing of fields. File-search execution, wizard acceptance and its
directory picker, heap balance, exception cleanup, visual comparison, default
editor routing and full DocPutKey qualification remain open.

Run the original control with:

```sh
python3 tools/test-i386-doc-search-keys.py --out OUT
```

Run against a native image with:

```sh
python3 tools/test-i386-doc-search-keys.py IMAGE --out OUT
```

The unchanged native F3 image fails this new dispatch test at
`build/i386-doc-search-keys-native-baseline-v1`: action masks are
`116,126,122,126,126,127,127,116,116` and metadata masks are `14,14,15,15`.
No forms or menus open. Alt guards pass; accepted-search text/cursor updates,
replacement and the two descriptions are missing. Fresh `6*7` pixels and the
filesystem audit pass. An independent terminal audit verifies all preexisting
file tuples, the sole fixture addition and the complete delivered original
`Find.HC` bytes. This is a dispatch failure, not a hung observer.

`tools/test-i386-doc-search-editor.py` composes the same contract with a
physical-key wrapper. Cases 0–4 and 7 run in focused `DocEd(DOF_DONT_HOME)`
sessions. A nonconsuming callback confirms Ctrl-F arrival; an observer waits
for the real form/menu to close and the editor to await input before the host
sends Esc. Alt guards, the absent Ctrl scan flag and metadata remain API cases.
The original `build/i386-doc-search-editor-original-v1` passes, with exports
byte-identical to the API original. Field formatting and menu selection still
use the fixture driver; this is physical shortcut coverage, not physical field
editing. No default zero-flag editor or visual qualification is implied.

The native change restores both original Ctrl-F branches. It calls the existing
complete original editor service and resolves `FindWiz` through `CallExtStr`,
as other resident document shortcuts resolve task-loaded applications. The
runner loads the complete delivered original `Adam/Opt/Utils/Find.HC`; default
startup loading of optional applications remains a separate requirement.

## Remaining file-search workflow oracles

The complete original `Find.HC` also defines these required workflows. The
count-only `FileOcc` coverage in `docs/i386-file-occ.md` and wizard cancellation
above do not qualify them:

| Workflow | Required independent observations |
| --- | --- |
| Wizard accept | Edit both strings, toggles and file mask; verify transfer to the caller's search record, default recurse/mask, real directory picker and cancellation after form acceptance. |
| Wizard search | Select a directory; observe the separate result task, exact file/line links and text, escaped query strings, flags and continued interactive task; close it and check caller focus/roles/resources. |
| Recursive search and flags | Controlled nested files with exact counts for recursion, case, whole labels and one-sided boundaries; exact output order/links and unchanged input bytes. Invalid flags must throw the original `FUF` exception. |
| Replace / skip / ALL | Real menu decisions over multiple matches and files; verify exact resulting file bytes, output and decision propagation. ALL persists across the remaining files. |
| Abort all / abort file / skip file | Check count and stopping boundary separately from writes. Original abort paths clear the current file's write flag; skip-file stops scanning but retains prior accepted replacements for that file. Earlier files must remain intact. |
| Edit from search | The original writes the current document, opens the real editor, rereads the file and resumes scanning; verify save/reopen, resumed position, task restoration and files. |
| Failure and cleanup | Missing/unreadable/write-failing files, cancelled forms/pickers and interrupted result tasks; compare original exceptions, live tasks, documents, directory, silent state and allocations. |

These are source-derived requirements, not observed passes. Full application
loading at normal startup and interactions with Home keyboard plug-ins also
remain open. The source, public API and application inventory entries stay
unqualified until their complete workflows have evidence.

The native API comparison `build/i386-doc-search-keys-native-v1` passes all
thirteen masks and matches the original exports exactly. Its terminal audit
revalidates input hashes, every preexisting file tuple, fixture bytes and fresh
`6*7` pixels. The F3 regression `build/i386-doc-find-search-v1` and scheduling/
lock regression `build/i386-doc-yield-search-v1` also pass with exact reference
exports and independent terminal audits.

The first native physical fixture include was rejected with two warnings,
before any physical case executed (`build/i386-doc-search-editor-native-v1`).
It declared `sk_forms` and `sk_menus` as extern before later definitions. The
corrected composition moves the existing initialized globals before the
prelude and removes those extern declarations; assertions and key sequences
are unchanged. The original v2 control passes with the same exported bytes.
This records the fixture compilation boundary rather than claiming that the
initial run exercised native editor behavior. Native acceptance of that
forward-declaration form remains unqualified.

The final fixture additionally verifies the exact first-field format and counts
all data and checkbox entries: the editor form has `Find        :%s`, three
data fields and six checkboxes; the wizard has `FIND        :%s`, three data
fields and four checkboxes. This prevents a wrong route to the other form from
passing the cancellation case. Both final original controls
(`build/i386-doc-search-keys-original-v3` and
`build/i386-doc-search-editor-original-v3`) pass the stronger assertions.
Earlier runs retain their frozen fixture and runner for reproducibility.

## Final native evidence

| Check | Evidence | Result |
| --- | --- | --- |
| API with form identity | `build/i386-doc-search-keys-native-v2` | Nine action masks 127, four metadata masks 15; exact original exports. |
| Physical shortcuts with form identity | `build/i386-doc-search-editor-native-v3` | Six real key receipts and closed-form/menu observations; same thirteen masks and exports. |
| Old-image negative control | `build/i386-doc-search-keys-native-baseline-v2` | Same seven action and two metadata failures as v1; stronger fixture does not hide the missing dispatch. |
| Bootstrap | `build/rebuild-doc-search-keys-v1-verified` | Two rebuilt generations pass; full copy preserved and all 1,737 production hashes verified. |
| Native export | `build/i386-doc-search-keys-cross-v1` | Full 64 MiB disk, 386 audit 96 BIOS/332 protected-mode instructions; post-export source audit passes. |
| Minimal normal startup | `build/i386-doc-search-keys-cross-v1/welcome8` | Exact 307,200-pixel welcome at 8 MiB. |
| Full diagnostics | `build/i386-doc-search-keys-cross-v1/diagnostic16` | Both program-probe, code-heap-ownership and file-break-cleanup phases; startup complete and exact welcome at 16 MiB. |

Terminal audits independently check source/test hashes, original export bytes,
every preexisting file tuple, fixture additions and fresh rendered arithmetic.
`diagnostic16-audit.json` also rechecks all production source hashes after the
run. These concurrent functional runs do not establish isolated 60-second
startup timing or C5's two installed native release generations. All 686
inventory entries retain their unqualified status.
