# Original Refresh and frame-cadence contract

The desktop compatibility goal requires the original public Refresh API, not
application calls to private presentation helpers. Ordinary console/document
views must make progress as well as custom shown documents. The native Console-86
worker has automatic custom-document/control rendering but does not yet publish
Refresh. Its default transcript/editor path still uses the retained bridge.

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
