# Original directory chooser

`tools/test-i386-pick-dir.py` drives the actual `PopUpPickDir` / `FileMgr`
workflow. A read-only observer waits for the focused popup's FileMan document
to select the expected directory. The host captures its screen, sends Escape
to accept the current directory, repeats with an explicit nested directory,
and sends Shift+Escape to cancel a third invocation.

The independent oracle requires the two exact absolute directory names and an
allocated empty string on cancellation, including their NUL terminators. Each
case requires caller output/display/border documents, popup pointer and working
directory restoration (mask 127). Returned strings are freed by the caller.
The fixture directory contains a nested marker file; native success also checks
all preexisting filesystem bytes/attributes/dates, exactly the two fixture
additions, filesystem structure and fresh rendered arithmetic.

* `build/i386-pick-dir-original-v3/result.json`: all three names and masks pass
  on the pinned original; execution inputs unchanged. Screenshots show the
  actual picker and selected directory before each key.
* `build/i386-pick-dir-native-v3/result.json`: the link candidate rejects the
  missing PopUpPickDir at fixture line 35, before workflow execution; inputs
  unchanged. Native chooser behavior has not passed.
* `build/i386-filemgr-load-probe-v1/result.json`: separately loading the complete
  delivered FileMgr source rejects missing CopyTree at line 269; inputs
  unchanged. Its original provider is `Adam/ABlkDev/ADskA.HC`.

The first fixture used an invalid C conditional expression. Both systems
rejected it; the original run was explicitly stopped after the native compiler
identified the syntax error, and its screenshot confirms the same error. The
corrected v2 reference passed. V3 additionally waits for a rendered screenshot
and explicitly checks the FileMan document identity. Earlier evidence is kept.

```
python3 tools/test-i386-pick-dir.py --out build/pick-dir-original
python3 tools/test-i386-pick-dir.py build/IMAGE/kernel.img --out build/pick-dir-native
```

Candidate v5 shares the exact original PopUpPickDir body through
`Adam/DolDoc/DocPickDirCore.HC`, includes it in the native console, and declares
its default argument through a public binding (console interface 217). This
plain source snapshot is under `build/i386-public-tables-candidate-v5/source`;
its implementation is now applied to main as part of cumulative candidate v8.
Its two bootstrap generations and cross-build pass; all 1,369 delivered
source/document files match the snapshot
(`build/i386-public-tables-chooser-source-audit-v1.json`). Runtime validation
continues through the missing FileMgr dependencies. It does not provide or replace FileMgr and cannot
by itself qualify the directory picker. File selection, navigation, editing,
copy/move/delete operations, exceptional cleanup and full FileMgr/C1–C5
qualification remain open.

The [CopyTree regression](i386-copy-tree.md) now records the original recursive
copy and overlap-rejection behavior required by FileMgr.

The driver now verifies delivered FileMgr against the pinned original and
loads the complete file before invoking the chooser. The updated original
control (`build/i386-pick-dir-original-v4/result.json`) passes unchanged. The
v6 candidate gets past CopyTree and rejects DelTree at FileMgr line 270
(`build/i386-pick-dir-candidate-v1/result.json`), before any chooser workflow.

The [DelTree comparison](i386-del-tree.md) now records original whole-tree
and recursive wildcard deletion, return counts and surviving file bytes.

Candidate v8 gets past DelTree and rejects the missing Fmt at FileMgr line 387
(`build/i386-pick-dir-candidate-v2/result.json`, inputs unchanged). The chooser
workflow is still unqualified.

Interface 229 now provides the original Fmt; its sixteen original/native RAM
formatting checks pass (see [formatting evidence](i386-format.md)). Loading the
complete FileMgr on this image gets past Fmt and rejects RedSeaISO at line 407
(`build/i386-pick-dir-format-v1/result.json`, unchanged inputs). No chooser
workflow has yet run successfully on the native image.

The [RedSea ISO reference](i386-redsea-iso.md) now covers original explicit and
default stage2 calls, generated descriptors/catalog and mounted exact file
round trips. Native RedSeaISO and its 386 boot-loader adaptation remain missing.

Interface 230 now passes the original/native RedSeaISO creation checks for
explicit and omitted stage2. Complete FileMgr loading moves to missing
DVDImageWrite at line 425 (`build/i386-pick-dir-redsea-iso-v1/result.json`,
unchanged inputs). The complete chooser remains unqualified.

Interface 231 provides the original DVD image services. Actual ATAPI reads to
FAT32 and non-optical write rejection match the reference (see
[DVD image evidence](i386-dvd-image.md)); successful burning remains unqualified.
Complete FileMgr loading advances to missing SettingsPush at line 588
(`build/i386-pick-dir-dvd-image-v1/result.json`, unchanged inputs).

With `--load-settings`, the chooser driver now loads the complete real
autocomplete and settings libraries into Adam, verifies their bundled bytes,
and pins their sources. Both loads return successfully. The unchanged FileMgr
then rejects `Cd2DirEntry` at line 592 with `Invalid lval`
(`build/i386-pick-dir-settings-v1`, unchanged inputs and independent terminal
pin audit). This message is also emitted for an unresolved identifier by
PrsExpressionCore; the native runtime currently has no Cd2DirEntry binding or
body. Its original recursive directory lookup is the next dependency. No
chooser workflow executes, and automatic startup-library loading remains open.

The [directory lookup reference](i386-cd-dir-entry.md) now passes twelve
original checks; the native baseline rejects the missing function before
executing them.

Interface 232 now supplies the unchanged original Cd2DirEntry. Its twelve
native checks match the reference (see [lookup evidence](i386-cd-dir-entry.md)).
With the real settings libraries loaded, complete FileMgr compilation next
rejects WinCursorPosSet at line 619
(`build/i386-pick-dir-cd-dir-entry-v1`, unchanged inputs). No chooser workflow
has executed on this candidate.

## First complete native chooser run (2026-11-07)

Interface 233 supplies the complete original WinCursorPosSet body, with sixteen
original/native checks and an exact coordinate/viewport record (see
[cursor evidence](i386-win-cursor-pos.md)). Both bootstrap generations pass.
The complete unchanged FileMgr now compiles after explicit real autocomplete
and settings library loading into Adam.

`build/i386-pick-dir-win-cursor-v1/result.json` passes all three native cases:
Escape returns C:/Probe/PickScope for the default directory, Escape returns
C:/Probe/PickScope/Nested for an explicit directory, and Shift-Escape returns an
allocated empty string. All three restoration masks are 127, matching the
original control: non-null result and expected bytes, unchanged caller put,
display and border documents, restored popup pointer, and restored working
directory. Actual keyboard events drive the popup. Final arithmetic pixels,
filesystem validation and all input hashes pass; terminal-audit.json
independently verifies pins, masks and returned bytes. FileMgr remains identical
to the pinned original.

Visual qualification is still open. Inspection of picker-0.png and picker-1.png
shows overlapping tree text and underlying console text within the native popup.
The original control's picker-0.png has clean distinct rows and selection.
Inventories and background desktops differ, so this is a recorded visual defect,
not an exact whole-frame differential measurement. The capture and
visual-observation.txt are preserved beside the result. The cause has not been
isolated. Selection/restoration success alone does not close the chooser UI,
full FileMgr, mouse interaction, navigation/file operations or C1–C5.

[Frame-layer diagnosis](i386-picker-render.md) now captures initial, ordinary
additional-frame and forced-refresh states. The persistent overlay is entirely
transparent. Ordinary and forced captures have identical popup-interior text
cells, while graphics/border artifacts remain. The first screenshot is also
transitional (two document updates). The evidence does not support forcing full
refresh as the fix; visual qualification and graphics-path isolation remain open.
