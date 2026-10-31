# ExeFile compatibility checkpoint

The original `ExeFile` implementation is shared unchanged through
`Compiler/ExeFileCore.HC` and exported by native ConsoleRuntime 178. It applies
the original default extension, formats the include command and calls the
existing `ExePutS`. The original `CCF_CMD_LINE` definition is shared with the
native public execution header. This supplies one dependency of the original
terminal right-click callback; that callback and the complete compiler and
application workflows remain open.

The pinned original passes the three-check fixture with unchanged inputs
(`build/i386-exefile-reference-v2`). It checks a default extension, an explicit
`.HC` extension with `CCF_CMD_LINE`, their source side effects, and preservation
of the current directory. Before this change the native image rejected the
fixture at the missing `ExeFile` binding (`build/i386-exefile-native-red-v1`).
The corrected native image passes the same mask at 64 MiB and 8 MiB, with
unchanged inputs, unchanged delivered fixtures and matching VGA checkpoints
(`build/i386-exefile-native-v4`, `build/i386-exefile-native-8m-v1`). The 8 MiB
run overlapped diagnostics and does not qualify the startup timing gate.

Both original bootstrap generations and the full native cross-build and 386
instruction audit pass (`build/i386-exefile-rebuild-v4.log`,
`build/i386-exefile-full-cross-v4`, `build/i386-exefile-rebuild-v5.log`).
The final image and the prior tested image have identical kernel and module
hashes, though their source-containing disks differ. The 16 MiB diagnostic also passes its
nine final behavior and VGA checks (`build/i386-exefile-diagnostics-v2`). The initial original fixture used a hard
coded C: drive on a T: reference system and timed out
(`build/i386-exefile-reference-v1`); it was corrected to the boot-drive alias.
The first native integration omitted an export-table slot and failed during
boot (`build/i386-exefile-native-v1`). After correcting the table, the next
fixture reached a missing public `CCF_CMD_LINE` definition and was rejected
(`build/i386-exefile-native-v2`); the shared definition resolved that gap.
These results do not cover all compile flags, exception paths or arbitrary
source programs and do not qualify C1–C5.
