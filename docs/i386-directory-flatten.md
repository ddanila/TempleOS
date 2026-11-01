# Directory tree flattening

The original `DirFilesFlatten` implementation is shared in
`Kernel/BlkDev/DirFilesFlattenCore.HC` and made available by ConsoleRuntime 193.
Expanding the include reproduces the previous source byte for byte; the shared
body also matches the pinned original revision. It flattens depth-first sibling
and child lists, and deletes directory entries when `FUF_JUST_FILES` is set.
This is one dependency of `FilesFind`; enumeration and sorting are separate.

The original fixture executes the exact shared body under a private name on the
pinned original, because the original helper is not a public interactive API.
It checks empty input, depth-first ordering, clearing child links, removal of
directories, returned tail position, and exact caller-heap recovery. All five
checks pass with unchanged inputs (`build/i386-dir-flatten-original-v5`). The
previous native image rejects the missing binding before running any case
(`build/i386-dir-flatten-native-red-v3`). Both original rebuild generations pass
(`build/i386-dir-flatten-rebuild.log`); their binary differences mean this is
not a reproducibility pass.
The 386 cross-build and instruction audit pass (`build/i386-dir-flatten-cross`),
and the native 64 MiB fixture passes the same five checks with unchanged inputs
and byte-identical delivered fixture (`build/i386-dir-flatten-native-v1`). The
run was concurrent and does not qualify startup timing. Allocation failure,
corrupt trees, sorting and actual filesystem enumeration remain untested.
