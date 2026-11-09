# Managed control mouse dispatch

The managed WinMgr now invokes control callbacks for physical PS/2 button edges
before document actions. Previously it reserved control hit regions but never
called their callbacks. The original eight-phase control fixture completes all
inputs on the old native image, restores its caller/heap (mask 15), but records
zero callbacks. That strict failure remains preserved.

The scheduled dispatcher uses CtrlInside and the original control queue order,
self/focus control inhibition and border-relative callback coordinates. Ordinary
press/release callbacks follow the current hit region. Captured left/right
callbacks repeat while held, continue outside that region and receive an outside
release. Control-owned gestures suppress later document actions from the shared
double-click recognizer. Capture continues across hit/inhibition changes, matching
the original held-button loop; those changes themselves need additional tests.

Between frames capture retains a task number and control address, then resolves
the task and validates queue membership before dereferencing the control. It
holds no window or heap alive between frames. Each active hit/click callback
borrows the owner through the existing native cleanup stack. A yielding custom
hit callback is followed by a membership check; arbitrary explicit Free/reuse of
control storage during a callback is not qualified. Throw, Exit and owner
retirement unwind the borrow through the existing WinMgr recovery/cleanup paths.
Reset/overflow recovery cancels capture along with document gestures.

## Original comparison and strict native control

```
python3 tools/test-i386-control-mouse.py --out FRESH_ORIGINAL
python3 tools/test-i386-control-mouse.py IMAGE --reference ORIGINAL --out FRESH_NATIVE
python3 tools/test-i386-control-mouse-lifetime.py IMAGE --out FRESH_LIFETIME
```

The canonical matched controls are `build/control-mouse-original-v4`,
`build/control-mouse-native-before-v2` and
`build/control-mouse-native-fixed-v2`. The final image is
`build/i386-control-mouse-cross-v1/kernel.img`. Both passing controls have exactly
two ordinary callbacks per phase for left/right normal and border coordinates,
repeated captured down callbacks with a monotone bounded drag and exactly one
outside release, and no callbacks under either control inhibition flag. Every
record checks callback task, live owner and enabled IRQs. Caller document roles,
child drain and exact caller heap recovery pass. The fixed native
control preserves every existing file tuple and renders fresh arithmetic 42.
Callback rates/counts while held depend on scheduling and are not a timing oracle.

The host observes the actual logical pointer and sends relative PS/2 events.
Original hardware scaling is 0.5, while native decoder movement currently has
unit gain. The final observer waits for a changed/settled observation before
computing the next correction. This accommodates the real original scale without
repeatedly injecting against a stale native observer. That default motion-gain
difference remains open; these are control-coordinate/callback comparisons.

Original v1 assumed only two possible drag coordinates, rejecting legitimate
intermediate PS/2 packets. V2 corrects the path oracle. Fixed native v1 exposes
an observer defect: repeated relative events before scheduled-state observation
cause physical overshoot and backtracking. Its callback coordinate (388,198)
corresponds to observed screen position (468,262), rather than a fabricated
callback coordinate. Original v3 sends only one move and stops halfway because
of original 0.5 hardware scaling. Final v4 uses settled feedback; the guest
fixture is unchanged throughout these controls. All failed receipts and exact
runner snapshots remain retained, with no failed receipt relabeled as passing.

## Callback lifetime

`build/control-mouse-lifetime-fixed-v4` passes five masks 255 on actual captured
control clicks: throw; Exit recovered by WinMgr's existing end callback; committed
Exit with that callback deliberately cleared; and owner retirement during a
yielding callback with either committed or recovering cancellation. Checks cover
actual worker identity/replacement as appropriate, subsequent frame progress,
released physical button, child reap, detached caller-owned control/canary and
exact controller heap recovery. Existing end-callback recovery policy is retained.
The final run finishes fresh arithmetic 42 and preserves all file tuples.

Earlier lifetime probes failed before callback entry. Their child window did
not set DISPLAYf_NOT_RAW, so NativeWindowNeeded rejected managed input while it
had focus. The final fixture explicitly creates a focused, frontmost managed
window and exports/checks its flags, inhibition, focus and hit admission before
every click. A blocking wrapper also keeps the root command active during the
probe. These changes correct probe setup, not production dispatch. That probe does not qualify raw-focus controls; the later input checkpoint is
linked below.

## Build, regression and audit

`build/control-mouse-budget-regression-v1` passes the unchanged full Budget
mouse workflow (1023/63), including actual shutdown/cold reopening without
Install/reseeding, exact report/live/form/menu/cursor/storage state, 1885 preserved
prior files, unchanged cold file tuples and fresh 42 after both returns.
The extra preserved file is the new private control helper.

`build/control-mouse-audit-v1/audit.py` independently rechecks raw exports,
physical input sequences, exact geometry, input hashes, file preservation and
102 rejected callback/identity/IRQ/edge/geometry/restoration corruptions.
All 1858 production and 26 helper pins match the image and both successful
classic bootstrap generations. Among sixteen modules only ConsoleRuntime
changes; the 454392-byte kernel and public ABI versions 104/264/41 stay unchanged.
The extracted recognizer's trailing blank line is removed in the same rebuilt
source set. These classic generations do not satisfy C5 native rebuild acceptance.

No complete C1–C5 milestone follows. Qualification remains 2/686. Raw-focus and
non-document controls, custom hit callbacks, capture mutation/explicit storage
reuse, simultaneous buttons, wheel input, border moving/resizing, top menus,
default hardware motion gain, pointer/full-frame rendering and repeated-use
resources remain open. The existing zero-flag editor/console input gaps and
isolated 8 MiB/60-second startup gate are unchanged.

## Later raw-focus input checkpoint

Raw-focus control callbacks now have an original/native eight-phase comparison
and a passing implementation that admits input independently of managed graphics.
The managed, five lifetime and Budget mouse/cold regressions still pass. See
[raw input evidence and limits](i386-raw-control-input.md). Raw document input,
control drawing, explicit legacy-scope controls and complete C2 remain open.
