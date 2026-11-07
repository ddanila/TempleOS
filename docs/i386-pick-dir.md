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
