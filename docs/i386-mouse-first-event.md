# First mouse event and VGA upload

The native window-manager consumer started at `(0,0)` while the public logical
pointer started at `(320,240)`. Its first button change therefore emitted a
spurious move message. `NativeMouseSync` now publishes the initial logical state
through the ordinary event queue, allowing WinMgr to consume it during startup.
Console ABI 267 versions this change; the public raw `MouseGet` API is unchanged.

`tools/test-i386-mouse-first-event.py` compares the unchanged original with native
managed and raw clients. No physical mouse movement precedes the first left and
right presses. Eight phases cover both buttons, releases, a no-op, an IRQ-masked
press/reset pair, and two actual position changes. Six exact messages, their
order/client coordinates, initial state, mode, IF, caller and heap restoration
must match. Each phase observes messages after 600 ms, before the host barrier.
Trace timing is retained but is not part of byte equality.

The old ABI 266 image fails both modes with an extra initial move:
`build/mouse-first-event-native-before-v1` and
`build/mouse-first-event-raw-native-before-v1`. The initial-publication candidate
fixes this, but the earlier fixture without trace work twice missed the right
press in managed mode (`mouse-first-event-native-v1` and `-v2`). Raw passed.
Diagnostic traces showed only two managed frames per 600 ms, compared with 18 in
the original. The diagnostic fixture alone changed scheduling enough to pass;
that result did not resolve the earlier failure.

`I386VgaSplitRows` now assembles four reversed logical bytes before each aligned
32-bit VGA store, reducing full-frame device stores from 153600 to 38400. Rows
are 80 bytes and their starts are aligned. Range/pointer validation, byte order,
plane selection and final map mask are preserved. The VGA contract checks every
byte of all four hardware planes against an independent bit oracle, all 256
logical byte values, untouched partial-upload boundaries, invalid input
rejection, allocation guards and 307200 displayed pixels. It passes in
`build/vga-wide-contract-v1` on the 486 without requiring an FPU.

The full candidate is `build/i386-vga-wide-cross-v1/kernel.img`. It pins 1860
sources and 26 helpers and has the same 457416-byte bare kernel. Only the
ConsoleRuntime module differs from the preceding initial-publication candidate.
Two source-matching classic bootstrap generations pass in `build/rebuild-test`;
these are not C5 native generations. The build's 386 instruction audit passes.

Original diagnostic references are `mouse-first-event-original-v2` and
`mouse-first-event-raw-original-v2`. Candidate diagnostic receipts are
`mouse-first-event-vga-wide-v1` and `mouse-first-event-raw-vga-wide-v1`, both pass.
Managed frames increase to four or five per 600 ms. Crucially, the retained
earlier fixture without diagnostics also passes both modes in
`mouse-first-event-vga-wide-without-trace-v2` and
`mouse-first-event-raw-vga-wide-without-trace-v2`, against its original v1
references. The isolated runner is preserved under
`build/mouse-first-event-audit-v1/without-trace.py`. The audit rejects all 54
single-value corruptions in the current fixed oracle and checks build provenance.

The 544-value MsSet comparison plus 32 delivered low-half button values passes
in `mouse-set-vga-wide-v1`. The 8 MiB 486,-fpu KVM picker and mouse-state pixel
workflows pass in `mouse-vga-wide-picker-v1` and `mouse-vga-wide-state-v1`.
Help passes in `mouse-vga-wide-help-v2`, but its first run timed out waiting for
the first selection acknowledgement (`mouse-vga-wide-help-v1`). That
intermittent failure remains evidence, not a passing whole Help reliability gate.

The unchanged `Demo/MsgLoop.HC` investigation remains unfinished. Original
normal/Shift-Escape runs restore the heap exactly when the harness holds one
compiler statement context (`msg-loop-original-v5`, `msg-loop-shift-original-v2`).
The native prior candidate fails exact output (`msg-loop-native-before-v1`):
its header link disappears, held-button keyboard scans omit the original upper
32-bit mouse flags, and document insertion/order differs. Original serialized
insertion order also varies across runs. Do not qualify this application from
record counts, reorder records, or weaken the exact output oracle to hide this.
The in-progress harness is not part of this checkpoint.

Qualification remains 2/686. Complete timing/speed and initial-state coverage,
ms_hard, missing devices, IRQ/FIFO/loss/focus/callback permutations, legacy
transitions, the existing held-click console and unflagged DocEd failures, full
original desktop/apps/raster/resources, and C1–C5 acceptance remain open. This
checkpoint does not establish original frame rate. A single-job normal 8 MiB
KVM 486,-fpu startup reaches live WinMgr and exact welcome/42 pixels in
53.207 seconds (`build/mouse-vga-wide-startup-8m-v1`), with no other QEMU
process at invocation. This passes the current 60-second baseline subgate,
not full original-desktop/all-app/resource C5 acceptance.
