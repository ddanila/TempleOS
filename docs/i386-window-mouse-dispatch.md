# Managed document mouse dispatch

The native managed WinMgr previously synchronized mouse state and rendered
windows without dispatching retained-document clicks. The strict Budget mouse
control exposes that gap at its first row selection. The implementation adds
scheduled document cursor/action dispatch using the original WinMgr rules;
there is no Budget-specific handler or synthetic document-cursor assignment.

The PS/2 decoder body is shared between the kernel and console observer. The
observer runs with IRQs masked and only decodes integer packet state and writes
a fixed 64-record queue. It neither allocates, yields, evaluates floating point
nor invokes UI callbacks. Adjacent motion records with unchanged buttons may
coalesce; button transitions and their positions/timestamps remain immutable.
Overflow discards the queued batch, records a loss and resynchronizes gestures
only after a released-button state. Queue storage is private; public device and
service layouts remain unchanged.

The console is initialized before PS/2 hardware setup. The observer therefore
seeds its decoder lazily from installed hardware. Logical synchronization also
initializes coordinates when hardware becomes available, before the first
packet; it does not treat that initialization as motion. A stopped intermediate
VM proves the ordering defect: hardware installed=1/packets=7 while the early
observer still had installed=0/packets=0. A separate fresh-boot check compares
hardware and logical coordinates at (320,240) before sending any mouse input.

The scheduled managed worker applies the shared logical coordinate transform
and original WinQueIPMsgs recognizer to queued history. Packet timestamps retain
the normal 350 ms double-click rule across rendered frames. Current public
position/button/keyboard state is not overwritten by historical packets; only
the recognizer's gesture fields are published back to the public mouse state.
The worker selects visible document windows, honors mouse inhibition and control
hit regions, focuses through WinCursorPosSet, and posts the original Space,
Enter, Escape and Shift-Escape actions. Existing standalone/legacy document paths
remain responsible for their own mouse input.

Window/document borrows protect cursor/action work across yielding operations.
WinCursorPosSet additionally tracks its acquired document lock in the existing
native cleanup stack. A tag callback that exits its worker must release the
parent-owned lock before the worker is reclaimed. The scope starts only after
WinInside validates the target, preserving NULL returns for dead targets, hidden
windows and coordinates outside the window. Caller-owned locks remain owned by
the caller. Common code also releases an acquired lock if a signature check or
exception prevents normal completion.

The shared helpers are parameterized rather than relying on C preprocessor
cleanup directives. The original recognizer receives explicit mouse snapshots,
clock and posting operation; the original WinMgr uses its normal globals and
TaskMsg wrapper. The native caller supplies queued state and NativePostMsg.
DocMousePressCore/DocMouseReleaseCore retain the original entry-action and border
rules. MousePositionCore retains the original scale, offset, grid and clipping
arithmetic. The extra classic-system control uses the current shared WinMgr
sources with pinned original binaries/other sources; it is a regression control,
not a replacement for the unmodified original reference.

The focused commands are:

```
python3 tools/test-i386-mouse-event-queue.py IMAGE --out FRESH_QUEUE_OUT
python3 tools/test-i386-win-cursor-exit.py IMAGE --out FRESH_CURSOR_OUT
python3 tools/test-i386-budget-mouse.py IMAGE --reference ORIGINAL --out FRESH_MOUSE_OUT
```

The queue contract checks empty-pop preservation, motion coalescing, immutable
edges, both-button ordering, repeated wraparound, exact capacity/overflow, guard
bytes, no task heap allocation and initial logical/hardware agreement. The cursor
contract covers actual callback Exit, child reclamation, parent lock release,
continued document use, exact caller heap recovery and inactive-target behavior.
The Budget contract retains its full original mouse workflow, 112-byte storage,
report/live identities, real native cold reopening and mouse abort requirements.

This is document mouse dispatch. Control callback/capture, wheel handling,
window-border dragging/resizing, top-level menu navigation, settled pointer/raster
fidelity and repeated-use resources still require their own implementation and
qualification. No C1–C5 milestone or complete Budget acceptance follows from
these component controls. Existing bootstrap generations are classic rebuilds;
C5 still requires two successive native generations with the full suite.

## Verified checkpoint

The final image is `build/i386-window-mouse-cross-v3/kernel.img`. The full
unchanged Budget workflow in `build/budget-mouse-native-v3` passes 1023/63,
including actual shutdown/cold boot without Install or reseeding, unchanged
cold-reopen file bytes/attributes/dates, 1884 preserved prior files and fresh
arithmetic 42 after both returns. It matches the canonical unmodified original
`build/budget-mouse-original-v3`. The additional shared-source classic control
`build/budget-mouse-shared-classic-v1` also passes 1023/63.

The queue contract fails before the logical boot-position fix with mask 255
and hardware/logical (320,240)/(0,0); final
`build/window-mouse-queue-fixed-v3` passes 511 and agrees at (320,240).
`fixed-v2` already produced 511 but its Python observer accidentally replaced
the filesystem snapshot variable with initial mouse bytes. That receipt remains
failed. The corrected observer uses distinct variables; its guest fixture,
inputs and runtime are unchanged, and an independent snapshot comparison proves
that both runs preserve existing files and add only their two probe files.

The cursor callback-Exit contract fails 75/7 before cleanup. An intermediate
scope placement releases the lock (255) but changes dead-target behavior (API
6); the final placement passes 255/7 in
`build/window-cursor-exit-fixed-v2`. The existing public cursor regression passes
all sixteen cases and exact coordinates in
`build/window-mouse-cursor-regression-v1`. Control retirement passes 255 three
times and explicit derived cleanup passes 63 six times on the final image.
The existing mouse-state behavior/pixel assertions pass at 64 and 8 MiB using
KVM and exactly two expected existing unused-parameter warnings. The 8 MiB run
starts in 65.97 seconds under concurrent testing; this is functional evidence,
not a pass of the separate isolated 60-second minimal startup gate.

The existing unflagged DocEd comparison is still a strict failure:
`build/window-mouse-doced-regression-v1` repeats the previously recorded active
113, return 95 and client differences 524/609 exactly. No expected masks or
pixel comparisons were relaxed. This is the retained zero-flag editor route,
not a newly passing original editor implementation.

`build/window-mouse-audit-v1/audit.py` rechecks the raw exports, event sequence,
source pins, filesystem preservation, mechanical source provenance and 188
rejected storage/form/menu/identity/target corruptions. The image pins 1857
production sources and 26 helpers. Among sixteen modules only ConsoleRuntime
changes; the 454392-byte kernel and public ABI versions Compiler 104, Console
264 and Memory 41 remain unchanged. Both classic bootstrap generations pass and
match current source pins. They do not satisfy C5 native-generation acceptance.
Inventory receipts are append-only; qualification remains 2/686.
