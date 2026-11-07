# Window borders in synchronous frames

The original GrUpdateTaskWin renders on WinMgr. Its TextBorder call passes Fs,
which supplies the full-screen origin and clipping bounds. Native rendering also
supports synchronous frames on a caller task. Passing that caller's Fs applies
its window origin a second time and clips screen-coordinate borders against the
caller's window.

GrUpdateTaskWinCore now selects this coordinate task through
GR_TASK_WIN_BORDER_TASK. The original build defaults to Fs; the native adapter
selects sys_winmgr_task. This changes only the coordinate/clipping argument to
TextBorder. It does not change callback identity, document ownership, task
borrowing, graphics leases or failure cleanup.

The focused test uses the actual GrUpdateTaskWin, a parked target window at
(10..20,15..25), and a caller window at (3..52,4..29). It captures every text cell
inside a real frame callback, checks border characters, attributes, interior fill
and all untouched cells, then restores the frame. The original callback runs on
WinMgr; the native callback runs synchronously on the offset caller. The host
also independently constructs and compares all 4,800 expected cell values.

The first original fixture stopped at a function-pointer initializer syntax
error, before execution. Separating declaration and assignment fixes the fixture.
Original v2 passes all cells; original v3 additionally passes the independent
host comparison. The unchanged native baseline fails with 4,735 of 4,800 matching
cells and confirms caller execution. All 65 differing cells are preserved in
build/i386-window-border-context-native-baseline-v1. Input hashes remain unchanged.
The baseline predates the host comparison but exports the complete cell buffer.
A separate host audit reproduces every baseline cell by applying the caller
origin (3,4) and caller clipping bounds before the normal interior fill; all
4,800 cells exactly match that predicted defect (shifted-origin-audit.json).

The prior chooser frame control showed that ordinary and forced-refresh frames
converge on identical interior text cells. This coordinate defect is a separate
cause of stray borders. Full chooser visual qualification still requires checking
the delivered image and remaining graphics against the original. C1–C5 remain
open.

Both bootstrap generations pass in build/rebuild-window-border-v1-verified.
The native cross-build in build/i386-window-border-cross-v1 passes its 386
instruction audit, and all 1,736 production hashes match bootstrap exactly.
The corrected native run, build/i386-window-border-context-native-v1, passes all
4,800 guest and host cell checks. Its complete cell buffer is byte-identical to
original-v3. Caller identity remains distinct from WinMgr. Concluding arithmetic
pixels, filesystem checks and independently reverified input pins pass.

The 8 MiB normal boot also passes all 307,200 welcome pixels in
build/i386-window-border-cross-v1/welcome8. Concurrent execution does not qualify
an isolated startup-time budget. The first chooser and 16 MiB diagnostic runs
were terminated by signal 15; the source of the signal is not established.
Their processes are absent and terminal-audit.json records the incomplete scope.
Fresh runs are recorded in the cross-build's restarted-checks.json. Neither
incomplete run is counted as a complete workflow/diagnostic pass.

The interrupted chooser run did complete its first return and all three frame
captures. Its settled ordinary/forced popup interiors have zero differences
between actual working pixels and independently rasterized text cells. Total
layer differences fall from the previous control's 4,324/4,283 to 439/457;
remaining differences are outside that interior, at the title and border controls.
Ordinary versus forced captures still differ in fifteen title cells and zero
interior cells. See build/i386-pick-dir-border-v1/layer-analysis.json,
settled-interior-audit.json and residual-cells.json. These captures establish the
specific border improvement, not complete FileMgr visual qualification or all
three post-fix chooser returns.
