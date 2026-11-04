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


## Full streamed copy and move

The complete original CopySingle, Copy and Move bodies are now shared and
retained by the native console. CopySingle uses the real CFile block stream,
including its 128-block buffer, final exact size/date/attribute update and
conversion through CopySingleZ when filename attributes differ. Copy uses the
actual FilesFind tree and directory context; Move retains the original
copy-then-delete behavior. It is distinct from the existing FileMove service.
The native public bindings and unchanged default destination `"."` are present.

Both original rebuild generations, full native cross-build/386 audit and
1228-file delivered-source audit pass (`build/i386-copy-move-cross-v2`). The
same contract passes on rebuilt original and native KVM with unchanged inputs
(`build/i386-copy-move-reference-v3`, `build/i386-copy-move-native-v1`). It covers
66313-byte copies across the 128-block chunk boundary, wildcard copying into
an existing directory, empty files, omitted destination, exact uncompressed
size and 64-bit datetime, compressed conversion and decoded bytes, onto-self
rejection, missing sources, copy-delete moves, and five repeated missing-source
calls with exact caller-heap recovery. The final native extent/bitmap audit
passes, and a post-execution audit confirms all 1228 delivered source/doc files
remain unchanged. This is RedSea coverage; complete FAT32 paths, every filter,
cross-volume operation and general error/rollback behavior remain unqualified.

The initial native build exposed a cross-compiler default-string limitation.
The host constant evaluator now returns an owned literal appended to its
small host-result thunk and preserves the miscellaneous-data flag. The normal
declaration parser copies that data into default-argument metadata, and the
existing AOT call path emits a target literal, rather than a host address.
Scalar folding and rejection of arbitrary pointer/runtime expressions remain
unchanged. The host regression passes mask 8191, including integer/F64 bits,
empty and concatenated/escaped strings, ownership and copied lifetime
(`build/i386-copy-string-host-constants-v1`). Four protected-mode cases cover
omitted/empty defaults, explicit override, forward declaration/definition and
a wide return. All 249 function cases and five deliberate faults pass the
instruction audit and actual execution (`build/i386-copy-string-functions-v1`).

The full function corpus had outgrown its existing 384 KiB stage even before
the four additions. It now runs as two complete bounded streams, preserving
all records and all five faults, the existing transfer limit, 8 MiB RAM and
first heap arena at 0x70000. Actual loaded sizes are 378474 and 56374 bytes.
The first attempt stopped at the old fixed 245-case count; the next stopped
at the transfer-size guard. No instruction or memory-bound check was weakened.

Reference fixture v1 stopped during parsing at exception tags longer than
eight bytes. V2 exposed an incorrect test expectation that a compressed file's
stored size equals its decoded size; v3 instead checks compressed attributes,
64-bit date and decoded bytes, while retaining exact size checks for ordinary
and empty files. The implementation was unchanged for these fixture fixes.

The unchanged right-click callback now compiles past Copy/Move/Del and reaches
the missing MountFile at line 76, with unchanged inputs and no callback
execution (`build/i386-copy-terminal-callback-probe-v1`). Actual terminal
construction, autocomplete/settings and C1-C5 remain open. The final copy-image
full WinMgr/welcome 64 MiB KVM suite is running at
`build/i386-copy-workstation64-kvm-v1`; no pass is claimed yet.
