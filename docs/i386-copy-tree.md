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
snapshot is `build/i386-public-tables-candidate-v6/source`; validation is in
progress, and core changes are not yet applied to main while the existing
native build pins its inputs.

Wildcard/no-mask variants, fault cleanup, metadata policy, existing destination
merges and complete FileMgr/C1–C5 qualification remain open.
