# Current-directory copy dependency

The original settings stack uses `DirCur` to snapshot a task's current drive
and directory. The original body is shared through
`Kernel/BlkDev/DirCurCore.HC` and exported by ConsoleRuntime 142. It returns an
allocated copy owned by the requested memory task and leaves the source path
unchanged; null directory pointers return null.

The pinned original passes five checks covering root and subdirectory paths,
default and explicit task/owner arguments, and independence of allocated
copies (`build/i386-dir-cur-reference`). Both original bootstrap generations
and the cross-build/386 audit pass (`build/rebuild-test`,
`build/i386-dir-cur-cross`). The native 64 MiB contract passes all five checks and continuation input
with unchanged inputs (`build/i386-dir-cur-native-64m`); this concurrent run
does not qualify startup timing. Cross-task ownership and the complete original
drive lifecycle remain outside this focused check; the settings stack and
C1–C5 remain open.
