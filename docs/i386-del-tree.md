# Recursive deletion

FileMgr's complete source advances past CopyTree on candidate v6 and rejects
`DelTree` at line 270. `tools/test-i386-del-tree.py` tests the original provider
from `Adam/ABlkDev/ADskA.HC` using only fresh fixture directories.

The fixture deletes a whole tree containing two files, a nested directory and
an empty directory. It then deletes `*.TXT` recursively from a second tree,
requiring the unmatched binary file and directories to survive. It also checks
a nonexistent match and the caller's directory. Exact expected results are
`2,0,0,2,0,0,1,1,1,1,0,1`; the surviving binary is exactly `00 7f 80 ff`.

* `build/i386-del-tree-original-v2/result.json`: vector and survivor bytes pass
  on the pinned original; inputs unchanged.
* `build/i386-del-tree-native-v1/result.json`: candidate v6 rejects missing
  DelTree at fixture line 14, before mutations; inputs unchanged.

The first original control expected whole-tree count 5 and failed only that
assertion, returning 2. `RedSeaFilesDel` increments its result only for entries
without RS_ATTR_DIR, so the corrected oracle counts files, not removed
directories. The failed control is retained. The native baseline used that
first oracle but stopped before executing any behavior or comparing results.

Native success additionally requires exactly the fixture and surviving binary
as new files, every preexisting file's bytes/attributes/timestamps unchanged,
a structurally valid filesystem and fresh rendered arithmetic. Those checks
have not yet passed.

```
python3 tools/test-i386-del-tree.py --out build/del-tree-original
python3 tools/test-i386-del-tree.py build/IMAGE/kernel.img --out build/del-tree-native
```

Candidate v8 shares the exact original DelTreeDirs, DelTreeFiles and DelTree
bodies through `Adam/ABlkDev/DelTreeCore.HC`, included before native media-path
aliases. It exports the original public signature and default flags through
console interface 220. The candidate remains under
`build/i386-public-tables-candidate-v8/source`; validation is pending while the
ongoing native build pins main's core inputs. Other flags, fault cleanup,
mounted-media variants and complete FileMgr/C1–C5 qualification remain open.

The native runner now initializes the pre-run filesystem snapshot used by its
postconditions. This host-only correction was found by the CopyTree candidate
run; the original guest fixture and expected deletion behavior are unchanged.
