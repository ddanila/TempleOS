# Directory enumeration reference

`FilesFind` must return the original directory tree or flattened list, not
just print a listing. The fixture creates `FindProbe` on writable RedSea media
with two root files and one child directory containing a third file. It checks
single-file lookup and its full name and size; name-sorted files-only output;
a recursive tree with a parent link; depth-first flattened output; and a
missing-file result. Each of the five cases also checks exact caller-heap
recovery after `DirTreeDel`.

The pinned original passes all five cases (mask 1023) with unchanged inputs
(`build/i386-files-find-original-v2`). Its writable RAM drive B maps to C in
the native test. This reference does not cover FAT, cluster ordering, every
filter or wildcard, multi-drive behavior, allocation failures, exceptions or
concurrent directory mutation.

The current native image rejects the missing `FilesFind` binding before setup
or any case executes (`build/i386-files-find-native-red`); its inputs were
unchanged. The native sorting, flattening and cleanup helpers alone do not
implement traversal, public block I/O or the RedSea/FAT lookup paths.

```sh
python3 tools/test-i386-files-find.py --out ORIGINAL
python3 tools/test-i386-files-find.py IMAGE --out NATIVE
```


## Retained native enumeration

The complete original FilesFind2/FilesFind, RedSeaFilesFind, FAT32FilesFind and
IsDir routines are now shared and retained in the native media unit. The
original file-utility flags are shared through FileUtilityFlags.HH and exposed
to native callers. FilesFind returns real trees/lists and uses the existing
sort/flatten/cleanup helpers; it does not synthesize a printed listing.

The fresh pinned-original comparison passes mask 1023
(`build/i386-copy-files-find-reference-v1`). The native TCG comparison passes
all five cases with exact caller-heap recovery and all VGA checkpoints, with
unchanged inputs (`build/i386-copy-files-find-native-v1`). The native copy/move
contract additionally exercises cluster-ordered enumeration and wildcard
copying through this API, followed by an independent extent/bitmap audit
(`build/i386-copy-move-native-v1`). Rebuilds, full cross-build/386 audit and
1228-file source audit pass (`build/i386-copy-move-cross-v2`). Complete FAT32
path dispatch, all filter combinations, failures and concurrent mutation remain
open. Full desktop and C1-C5 qualification are not established by these cases.
