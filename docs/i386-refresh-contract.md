# Original Refresh and frame-cadence contract

The desktop compatibility goal requires the original public Refresh API, not
application calls to private presentation helpers. Ordinary console/document
views must make progress as well as custom shown documents. The native Console-86
worker had automatic custom-document/control rendering but did not publish
Refresh. Console 87 now integrates the public API, scoped waits and manager-cycle
accounting; see [native implementation and evidence](i386-native-refresh.md).
Its default transcript/editor path still uses the retained bridge.

## Pinned original baseline

`tools/test-i386-refresh-reference.py` captures six cases from the pinned
original. `build/i386-c1-refresh-reference/result.json` passes with unchanged
inputs and masks `[7,7,15,15,15,15]`:

| Case | Required observation |
| --- | --- |
| Refresh(0,FALSE) with no active frame | Returns without advancing the update count; restores idle state; no pump request |
| Refresh(0,TRUE) with no active frame | Returns without advancing the count and publishes the pump-only request; restores idle state |
| Refresh(1,FALSE) | At least one manager update; restores the previous non-idle state; retains the put-document identity |
| Refresh(2,FALSE), initially idle and without full-refresh flag | At least two updates; restores idle and cleared full-refresh state |
| Refresh(2,FALSE), initially full-refresh | At least two updates; preserves the prior full-refresh flag and put-document identity |
| Refresh(1,TRUE) after a far-future manager wake deadline | Forces progress rather than waiting for that deadline; restores ordinary task/document state |

These tests run through the original normal desktop, without a custom frame
presenter. They establish ordinary-return behavior. They do not qualify active
frame synchronization, actual input pumping, interruption, document replacement
or owner retirement while Refresh waits. The pump-only case checks the request
publication, not the complete resulting keyboard/mouse event workflow.

The original implementation keeps REFRESH_IN_PROGRESS around GrUpdateScrn,
clears JUST_PUMP_MSGS when deciding whether to draw, and advances winmgr.updates
at the end of its non-pump iteration. Native uploads currently increment the
same internal counter from multiple presentation paths, so publishing the API
alone would not establish original manager-iteration semantics.

## Native visual gate

```
python3 tools/test-i386-refresh-document.py IMAGE --out OUT
```

The application selects a dynamic shown document, waits with Refresh(2), then
changes A to B and waits with Refresh(2) again. Independent full-window glyph
observations and at least two tag evaluations per phase are required. Neither
phase calls DocRecalc or a frame presenter. Cleanup restores the legacy console
and the final arithmetic command checks continued input/execution. On Console 86 the result is red in
`build/i386-c2-refresh-document-red/result.json`, with unchanged pinned inputs:
the ARView definition fails on the missing Refresh identifier. Both later
visual/wait phases and the final arithmetic command remain unexecuted. A parser
rejection does not count as functional frame evidence.

## Implementation and qualification order

1. Capture active-frame sync, pump-only consumption, interrupted waits and
   document/owner lifetime in additional original/native tests. Avoid depending
   on the original uninitialized old_full_refresh local for count 0/1 when the
   document was already marked full-refresh; specify any repair explicitly.
2. Share the public wait behavior and add native resource scopes for temporary
   idle/full-refresh state. Borrow the selected document/owner across waits;
   replacement or termination must unwind safely. Qualify forced Exit and retry.
3. Integrate normal manager cadence with ordinary views. Distinguish manager
   completed iterations from unrelated raw/explicit uploads, prevent double
   counting, and bracket in-progress state through normal/exception/Exit paths.
   Pump-only iterations must process the required events without pretending a
   full frame completed. Preserve actual output and frame leases rather than
   incrementing counters solely to satisfy a waiter.
4. Expose the required public API/state with versioned native exports and verify
   the visual gate plus ordinary-view waits. Test force wake, raw/debug entry,
   held frames, focus/view changes, cancellation, exact heaps and subsequent
   input/rendering. Repeat existing automatic refresh/recovery and minimal
   startup gates on the final image.

The retained transcript/editor bridge is an intermediate compatibility path;
passing a Refresh test through it does not qualify original stdout/input/Adam
roles or complete desktop composition. Mouse/control events, ODE work, cursor
composition and the full bundled application inventory remain required C2/C3/C4
work. Full native generations and release profiles remain C5 work.

## Shared cleanup repair and active-frame oracle

The final lifetime fixture holds the manager's final-screen callback while
REFRESH_IN_PROGRESS is set. A second task calls Refresh(0,FALSE); it must remain
idle and blocked until that actual frame is released, then return after the
in-progress flag clears. Probe state is explicitly initialized. This uses the
frame hook rather than assuming every document tag evaluation occurs in a
screen refresh.

The second case pauses WinMgr, starts an independent two-frame waiter using a
parent-owned put document, and aborts it through a one-shot task-end callback
that throws to its outer catch. The pinned original leaves TASKf_IDLE and
DOCf_DO_FULL_REFRESH set. The shared repair restores both before the outer catch.

`Adam/RefreshCore.HC` now holds the original wait/pump/force logic, with common
idempotent restoration on ordinary return and exceptions. The original WinMgr
includes this core. It restores the document flag only when Refresh changed it
for a count greater than one; count 0/1 no longer uses an uninitialized saved
flag. At that repair checkpoint native scope hooks were reserved for committed Exit
and document/owner borrowing. Console 87 now supplies them with public exports
and retained-view cadence in the linked native implementation.
The ordinary transcript/editor and manager-cycle gaps remain open.

| Artifact under build/ | System | Observations |
| --- | --- | --- |
| i386-c1-refresh-modes-pinned/result.json | Pinned original | [7,7,15,15,15,15], pass |
| i386-c4-refresh-modes-control/result.json | Original with current shared cleanup overlay | Same six masks, pass |
| i386-c1-refresh-lifetime-reference-pinned/result.json | Pinned original | [15,3], frame synchronization passes; interrupted flags leak as expected |
| i386-c4-refresh-cleanup-final/result.json | Original with current shared cleanup overlay | [15,0], frame synchronization passes and interrupted flags restore |

The full original compiler/kernel self-rebuild and reboot also pass in
`build/rebuild-test/result.json`, with matching source hashes.

All four reports retain unchanged inputs. Control overlays pin the three changed
source inputs and record their actual hashes in the system-source map; they
remain original-system controls, not native-port qualification.

```
python3 tools/test-i386-refresh-reference.py --out OUT
python3 tools/test-i386-refresh-reference.py --cleanup-control --out OUT
python3 tools/test-i386-refresh-lifetime-reference.py --out OUT
python3 tools/test-i386-refresh-lifetime-reference.py --cleanup-control --out OUT
```

## Development native-build observation

The earlier Console-84 development flat-kernel attempt in
`build/i386-c2-managed-refresh-native-kernel-retry` terminates on the 2400-second
command observation limit while still compiling the first kernel module. Its
guest log contains continued module output, without a terminal allocation or
compiler rejection. No installed boot or native generation is qualified by that
attempt. A new attempt uses the pinned Console-86 cross-built source disk in
`build/i386-c2-refresh-native-kernel` with a 10800-second per-command limit,
16 MiB build RAM and 486,-fpu TCG. It is still a development flat-kernel build
with cross-built retained modules, not full C5 qualification. Its guest source
image predates the shared Refresh repair above.
