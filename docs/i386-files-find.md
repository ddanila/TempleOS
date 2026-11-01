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
