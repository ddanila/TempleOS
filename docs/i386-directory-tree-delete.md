# Directory tree cleanup

The original `DirEntryDel`, `DirEntryDel2`, `DirTreeDel`, and `DirTreeDel2`
implementation is shared in `Kernel/BlkDev/DirTreeDeleteCore.HC` and exported
by ConsoleRuntime 192. Expanding the original include reproduces the previous
source byte for byte. The `2` variants free `user_data`; the other variants
leave it owned by the caller. Tree deletion follows both sibling and child
links. These routines are prerequisites for original `FilesFind` consumers;
they do not implement directory enumeration, copy, or file streams.

The original fixture checks null inputs, single entries, nested and sibling
entries, preserved user data and exact caller-heap recovery. It passes mask 127
with unchanged inputs on the pinned original
(`build/i386-dir-tree-delete-original-v2`). The previous native image rejects
the fixture at its first missing deletion binding
(`build/i386-dir-tree-delete-native-red-v2`); no native cases ran there.
Both original rebuild generations pass (`build/i386-dir-tree-delete-rebuild.log`),
and the 386 cross-build and instruction audit pass
(`build/i386-dir-tree-delete-cross`). The build is not a reproducibility pass.
The same fixture passes mask 127 on the new native image at 64 MiB, with
unchanged inputs and a byte-identical delivered fixture
(`build/i386-dir-tree-delete-native-v1`). It does not exercise allocation
failure, corrupted trees, `FilesFind`, or cross-task ownership; the concurrent
run does not qualify startup timing.
