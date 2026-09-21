# Native resize, controls and window visibility

The retained console now provides the original `TaskValidate`, `WinInside`,
`WinHorz`, `WinVert`, `TaskDerivedValsUpdate`, `CtrlFindUnique`, `CtrlsUpdate`,
`CtrlInside` and `WinZBufUpdate` services. Native startup publishes their
headers and the original 80-column / 60-row constants.

The full original `CCtrl` record and its constants are shared through
`Kernel/ControlTypes.HH`. Native task attachment initializes each control-list
sentinel, including root and worker tasks. Reaping rejects a task with attached
controls before releasing its symbol table or heaps; callers must detach the
controls first. Control construction, drawing, scrollbar installation and mouse
routing remain separate integration work.

Both architectures share the original resize bounds rules, control lookup and
coordinate updates, and hit testing. Resizing still preserves requested spans
when a window lies past a screen edge. The task update acquires the original
task lock, recomputes geometry, calls control updates and invalidates visibility
when the window is shown. Shared exception cleanup releases the lock and
restores the incoming interrupt state. Resize wrappers also restore their
outer interrupt state when a callback throws. Geometry remains changed after a
callback failure, so cleanup requests a visibility refresh.

The original visibility calculation is shared. Each visible task receives a
z number in public task-ring order; the cell map and uncovered-window bitmap
record which windows remain visible. The cell map is cleared before filling so
hiding or shrinking the last visible window cannot leave stale owners. The
original border expansion and clipping rules remain intact.

Native graphics startup transactionally allocates the 9600-byte cell map and
8192-byte bitmap with the existing screen resources. Its console presentation
owner anchors the actual public task ring. Presentation refreshes visibility
every frame, covering task
removal and direct field changes as well as resize invalidation. The retained
scan does not yield; keyboard/timer interrupts remain enabled when the caller
entered with them enabled. The native scheduler is single-CPU and cooperative,
and its IRQ wakeup path does not mutate the public task ring.

The shared corpus includes fourteen resize/control/recovery groups and six
visibility groups. Visibility tests call the real public updater with isolated,
guarded buffers and a temporarily rewired, interrupt-protected task ring.
They cover overlapping windows, hidden windows, border clipping, bitmap bits
and restoration. Native diagnostic probes verify control sentinels in boot and
worker tasks and deferred task destruction until controls are detached.

These are providers for original DolDoc recalculation. They do not install the
complete original window manager or provide an editable document. Sprite
rendering, document construction/formatting/layout, editor input and the
save/reboot/reopen workflow remain required by the editing-session goal.

Validation passed in two original x64 rebuild/reboot generations, the original
cross-build guest, and native QEMU/486 at 8 MiB. The full native run covers
221 commands / 284 input lines, the fourteen service and six visibility groups,
two control-lifetime rejections, existing VGA comparisons, recovery and all
17 module rejections. ConsoleRuntime 24 retains 275968 bytes; visibility
resources add 18384 heap bytes to the existing graphics allocation. Normal
startup measured 40.173 seconds. See [port progress](port-progress.md) for the
remaining editing-session requirements.
