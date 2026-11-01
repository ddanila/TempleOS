# Original single-file conversion copy

`CopySingleZ` is the original whole-file conversion path used by `CopySingle`
when source and destination filename attributes differ. Its complete body is
shared from `Kernel/BlkDev/CopySingleZCore.HC` by the original kernel and the
native console. The native binding uses the existing public `FileFind`,
`FileRead`, `FileWrite`, filename-attribute and diagnostic implementations;
it does not replace the stream-based `CopySingle` or the higher-level `Copy`
and `Move` routines.

The paired fixture writes a known plain file, converts it to `.Z` and back,
checks expanded bytes and compression attributes, compares source and final
file timestamps, verifies a missing source leaves the destination intact, and
cleans up. It passes mask 255 on the pinned original and current original
rebuild (`build/i386-copy-single-z-reference-final` and
`build/i386-copy-single-z-rebuilt-final-v2`), and on the native image at 8 and
64 MiB (`build/i386-copy-single-z-native-8m-v2` and
`build/i386-copy-single-z-native-64m-v2`). All runner inputs remained
unchanged. The test uses original `Del` and native `FileDel` only to clean up;
it does not establish their general equivalence. It does not cover all file
attributes, large/empty files, allocation or I/O failures, directories,
wildcards, streaming, resident files, or every compression form.

The first native runs reached mask 255 but their screen assertions waited for
an exact transcript that omitted the original routine's progress and missing
file messages. Those runs were interrupted after inspection; the final fixture
uses the original `Silent` service during the operation and restores its prior
state. The first cross-build rejected an incorrectly ordered file-read alias;
the final build uses the existing native formatter read bridge. Both original
bootstrap generations and the full native cross-build/386 audit pass
(`build/i386-copy-single-z-cross-v2`).

The full `CopySingle`, `Copy`, `Move`, `Del`, block-device mounting, terminal
right-click callback, user desktop and C1–C5 remain unqualified. This conversion
path is a prerequisite, not an implementation of those operations.

The isolated 8 MiB startup run passed all nine functional and exact-VGA
checks, but its 62.402-second startup exceeded the 60-second gate
(`build/i386-copy-single-z-startup-8m`). The timing gate remains open.
