# PopUpFile compatibility checkpoint

The original `PopUpFile` wrapper is shared through
`Adam/DolDoc/PopUpFileCore.HC` and exported by native ConsoleRuntime 181. It
uses the existing popup task, queued input, and `ExeFile2` services; its
warning and synchronous branches remain present.

The pinned-original and native 64 MiB fixtures pass mask 31 with unchanged
inputs (`build/i386-popup-file-original-v3`,
`build/i386-popup-file-native-v1`). They exercise asynchronous creation,
queued execution with default and explicit extensions, an output task pointer,
retirement and caller popup ownership. The executed source writes a marker to
a writable drive so it can be observed across the independent servant scope.
These checks do not qualify the warning dialog, synchronous interactive
continuation, full servant startup or cancellation under every condition.

At 8 MiB the same candidate reaches task creation and fails with `OutMem`
(`build/i386-popup-file-native-8m-v1`). The logged failed allocation is
267,527 bytes; the conventional task arena is 487,424 bytes, with 276,016
bytes in use and a largest free block of 210,608 bytes at failure. This guest
also ran alongside diagnostics, so its startup time is not a timing gate.
The failure remains open and is not evidence of a completed minimal profile.

Both original bootstrap generations and the full native cross-build/386 audit
pass (`build/i386-popup-file-rebuild-v1.log`,
`build/i386-popup-file-full-cross-v1`). The 16 MiB diagnostic passes its
nine final behavior and VGA checks (`build/i386-popup-file-diagnostics-v1`).
The pre-change native control rejected
the missing binding before executing the fixture
(`build/i386-popup-file-native-red-v1`). Two earlier original fixtures tried
to observe a variable private to the caller, which was not visible in the
servant; the original guest entered its debugger and timed out
(`build/i386-popup-file-original-v1`, `build/i386-popup-file-original-v2`).
The marker-based fixture corrected that observation error. Full terminal,
application and C1–C5 qualification remain open.
