# Bootstrap-to-desktop transition experiments

The production image still starts its retained bootstrap console. The original
HomeSys preflight creates two User terminals, but hiding that console is only
a geometry experiment. Normal boot must hand over to the Users with correct
rendering, input, task and resource lifetimes.

`docs/patches/i386-managed-bootstrap-prototype.patch` preserves a disposable
candidate: create the bootstrap through managed Spawn with its existing64KiB
stack, give hidden Adam the original service-task window inhibition, and set
non-raw console mode before typing the welcome. Production sources remain
unchanged while the current-source native module chain is pinned.

The emitted native Kernel is542593 bytes, SHA256
0d096a89cdb2a3accd28765eaff37e36185cfaa90e28ee4e39d03560ac3e7d49
(`bootstrap-managed-kernel-prototype-v1`). Guest linking/install succeeds, but
without explicit non-raw initialization the first boot stalls during welcome
output. `bootstrap-managed-boot-capture-v1` preserves registers and64MiB RAM.
Its independent decoder proves display_flags is zero, the keyboard-output ring
is uninitialized, and DocType -> DocDump -> Print -> PutS calls a null node's
callback slot, reading BIOS vector F000FF53. Managed Spawn preserves the original
raw task default; bootstrap startup had relied on the private worker's implicit
non-raw initialization.

Adding Raw(FALSE) before ConsoleDocumentStart restores exact managed-pointer
welcome/42/DocAllocationCheck13 at64MiB (`bootstrap-managed-raw-init-v1`). The
same candidate passes actual User255 at8MiB with all pixel checkpoints and fresh42
(`bootstrap-managed-raw-user-8m-v1`). Its mixed native-Kernel/cross-provider386
instruction audit passes. These are candidate checks, not native generations.

The first two retirement fixtures do not establish Exit behavior: one times out
while a child waits, and another blocks before targeted Exit is observed. They
remain preserved and excluded from retirement acceptance. A shared COMMAND OK
from the configured Once also cannot acknowledge the bootstrap's Adam call.

The third fixture captures the bootstrap's self-address before transition and
logs BOOT EXIT START directly after Adam("StartUpTasks;") returns. With the
original kernel, Exit then rejects with exception Task
(`bootstrap-retirement-before-v3`): private workers have no managed task record.
The managed candidate reaches that same point, and a surviving User confirms
TaskValidate on the captured literal address is false. Its unchanged83-word
geometry export still matches the original, but actual arithmetic42 no longer
renders (`bootstrap-retirement-candidate-v3`). This is an explicit red handoff
result, not successful desktop qualification. Two inherited references also
keep the finished bootstrap storage pinned; physical reaping is not claimed.

GraphicsFrame currently records the bootstrap as graphics_owner and requires
TaskValidate(graphics_owner). WinMgr assigns only the persistent canvas to itself;
the second frame canvas still refers to the bootstrap. The separate
`docs/patches/i386-bootstrap-graphics-owner-prototype.patch` makes the graphics
lifetime owner the immortal kernel root and assigns both canvas views to the
active manager. It preserves the liveness checks. The120-byte-larger cross-built
ConsoleRuntime passes compilation, complete386 instruction audit and guest
replacement/independent8MiB welcome/42/DocAllocationCheck13
(`bootstrap-graphics-owner-cross-v1`, `bootstrap-graphics-owner-instruction-v1`,
`bootstrap-graphics-owner-install-v1`). It is explicitly cross-built, despite
reusing the functional retained-module installer. The fresh retirement workflow also retires the bootstrap and preserves geometry,
but still fails visible42 (`bootstrap-retirement-graphics-v1`). This change is
therefore insufficient for a usable handoff. A separate live-bootstrap User
control reproduces the clipped result with stored answer42 and horizontal scroll1;
see [i386-user-scalar-cursor.md](i386-user-scalar-cursor.md). Normal boot, full
raster/input, physical reaping and resource qualification remain open.
