# Recursive directory copying

The full original FileMgr include requires `CopyTree` at line 269. Its provider
is the pair `CopyTree2` / `CopyTree` in `Adam/ABlkDev/ADskA.HC`.
`tools/test-i386-copy-tree.py` records their original behavior before porting.

The fixture creates a source containing a text file, a nested binary file with
NUL/high bytes, and an empty directory. It copies that tree, attempts copies to
the same directory and a descendant, then copies the empty directory. It checks
exact source/destination bytes, destination empty-directory existence, absence
of the rejected descendant, and preservation of the caller's directory.

The independent expected vector is `5,0,0,1,0,1,1`: first copy count 5, both
rejected copy counts 0, copied empty directory present, forbidden descendant
absent, caller directory preserved, empty-tree copy count 1. Despite the
original comment describing a file count, each recursive helper invocation
starts at 1; the observed results are preserved rather than replaced with a
more conventional count.

* `build/i386-copy-tree-original-v2/result.json`: exact vector and all four
  file captures pass on the pinned original; inputs unchanged.
* `build/i386-copy-tree-native-v1/result.json`: the link candidate rejects
  missing CopyTree at fixture line 17; inputs unchanged. Native behavior has
  not passed.

Native success additionally requires exact persisted paths/bytes for the four
source/destination files and fixture, every preexisting file's bytes/attributes/
timestamps unchanged, a valid filesystem and fresh rendered arithmetic.

```
python3 tools/test-i386-copy-tree.py --out build/copy-tree-original
python3 tools/test-i386-copy-tree.py build/IMAGE/kernel.img --out build/copy-tree-native
```

Candidate v6 extracts both functions byte-for-byte into
`Adam/ABlkDev/CopyTreeCore.HC`, includes that same body from original ADskA and
the native console, and exposes the original signature/default through console
interface 218. It includes the preceding chooser candidate changes. The source
snapshot is `build/i386-public-tables-candidate-v6/source`. The corrected
cumulative v8 implementation is now applied to main after the native build's
terminal input audit.

Wildcard/no-mask variants, fault cleanup, metadata policy, existing destination
merges and complete FileMgr/C1–C5 qualification remain open.

Candidate v6 passes both bootstrap generations, the 386 instruction audit
(96 BIOS / 332 protected-mode instructions), and all 1,370 delivered source/
document comparisons (`build/i386-public-tables-copy-tree-source-audit-v1.json`).
Its runtime test `build/i386-copy-tree-candidate-v1/result.json` fails while
reading the copied nested binary file. Disk inspection finds the copied bytes,
but original-provider directory creation produced non-retained directory
records, also rejected by the filesystem verifier. The CopyTree include was
after MediaPathRuntime aliases and therefore bypassed normal DirMk dispatch.
Candidate v7 moves the unchanged shared body before those aliases. This fix
passes the fresh v3 runtime run below; neither the runtime oracle nor verifier
was relaxed.

V7 run `build/i386-copy-tree-candidate-v2/result.json` passes the guest byte/
count comparisons and fresh arithmetic, then fails in the host runner because
its pre-run filesystem snapshot variable was not initialized. The runner and
related DelTree driver now capture that snapshot before packaging. An
independent post-run check passes against the immutable source image and
working disk (`supplemental-filesystem-audit.json` beside that failed result),
including unchanged preexisting files, exact new files and strict filesystem
structure. The failed result is not rewritten. Fresh complete run
`build/i386-copy-tree-candidate-v3/result.json` passes, including all 1,740
preexisting files unchanged and exact added files, with unchanged inputs.
