# Block-backed file stream dependency

The unchanged autocomplete source first requires `FOpen`, then uses `FBlkRead`
and `FClose` for dictionary blocks. The complete original file-stream bodies
are shared through `Kernel/BlkDev/CFileStreamCore.HC`: open modes, cluster
buffering, block reads and writes, and close-time directory updates remain the
original implementation. This extraction does not yet bind the native block,
cluster and directory-context dependencies or export the stream APIs.

A ten-check original reference covers contiguous RedSea preallocation, write,
close, reopen, explicit and sequential reads, end-of-file and bounds,
read-only write rejection, a zero-count read, contiguous mode, and a `w+`
update followed by whole-file verification. The pinned original and rebuilt
original with the shared source both pass with unchanged inputs
(`build/i386-cfile-stream-reference-v4`,
`build/i386-cfile-stream-shared-original`). A zero-count read returns success
without changing the current block position; the earlier contrary expectation
is preserved in `build/i386-cfile-stream-reference-v2`.

Both original bootstrap generations and the cross-build/386 audit pass
(`build/rebuild-test`, `build/i386-cfile-stream-source-cross`). The native
fixture rejects at the missing `FOpen` binding before any case runs
(`build/i386-cfile-stream-native-red`). FAT, fragmentation, growth,
concurrency, error cleanup, the native implementation and C1–C5 remain open.
