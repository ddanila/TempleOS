# Derived-control lifetime and automatic update work

The original WinMgr performs a ring-wide derived-value pass before selecting and
rendering windows. Its controls run as the manager, with the target task's lock
held and interrupts disabled. The initial native worker omits this prepass:
`build/i386-c1-auto-derived-reference/result.json` observes mask 3 on the pinned
original, while `build/i386-c2-auto-derived-red-final/result.json` rejects native
mask 0. Both checks sleep without calling geometry or presentation helpers.

## Cleanup candidate

Console version 85 registers a derived update in the existing native render
scope stack before taking the target task lock. The scope borrows the target
owner, so its committed retirement requests cancellation of a yielding updater
before reclaiming the target. It retains the saved interrupt flags and a pointer
to the lexical lock-ownership flag. Normal return, caught exceptions and forced
Exit share idempotent lock release. Forced Exit drains the scope before task
storage disappears; owner-driven cancellation uses the existing WinMgr unwind
policy when the borrower is the real manager.

`Kernel/TaskWindowCore.HC` keeps the shared original geometry/control/invalidation
order. Its default scope hooks are empty for the original system. The native
wrapper is included after the common render scopes are available; earlier
window APIs retain a forward declaration. No public CTask or private service
layout changes accompany version 85.

## Lifecycle acceptance

```
python3 tools/test-i386-control-derived-lifecycle.py IMAGE --out OUT
```

The explicit component fixture pauses normal WinMgr after boot. Independent
owner/updater tasks exercise normal return, a caught derived callback exception,
callback Exit, updater kill, owner Exit and owner kill. Each case requires mask
63: live target and updater context with IRQs disabled in the callback, released
target lock (or retired target), automatically retired updater, expected control
flow, exact parent heap and reusable graphics/text presentation. The control
allocation remains parent-owned and the owner detaches it in its one-shot end
callback; the fixture frees it only after both tasks stop. This avoids making
arbitrary bare-task control ownership a hidden prerequisite of this test.

The first prototype left its control linked during owner destruction, so its
heap/reap observations were confounded. It is not the authoritative regression.
The corrected fixture checks state before its defensive cleanup, which clears
a leaked target lock and stops surviving tasks. That cleanup cannot turn a
failed observation into a passing one.

Existing window component checks cover geometry, control-derived screen bounds,
normal/exception IRQ restoration, task-lock release, visibility and frame pixels.
The explicit lifecycle fixture does not qualify automatic ring scheduling,
control-list mutation during callbacks, contention on a lock held by another
yielding updater, or complete bare-task control disposal. Those remain explicit
integration/lifetime work.

## Next integration

Enable a ring-wide prepass only after the cleanup gates pass. Snapshot numeric
task identities in the original predecessor order, admit each live target to a
protected update, and release the snapshot on return, exceptions or Exit. A
callback may retire/reorder tasks; do not follow retained task pointers after it
returns. Covered and hidden tasks still require derived updates, as in the
original. Apply original per-window failure isolation to a failing prepass too.
Qualify the automatic callback contract and owner/worker recovery on the final
image. Add contention and callback-list mutation contracts before claiming the
whole control path complete. C1–C5 remain open.

## Candidate evidence

`build/i386-c4-derived-scope-cross/kernel.img` passes the original bootstrap,
native cross-build and the 386 boot audit. All 1471 recorded source/build inputs
matched after compilation. The normal 8 MiB startup result is
`build/i386-c4-derived-scope-startup/result.json`: 9 commands, 49.91 seconds,
manager enabled, zero build-provider loads. The 64 MiB window/graphics/text-frame
regression passes 24 submissions including manager-pause setup in
`build/i386-c4-derived-scope-frames64/result.json`.

An additional 8 MiB component experiment
(`build/i386-c4-derived-scope-frames`) cannot compile WindowServiceCheck.HC:
the parser requests 0x3633 bytes after physical heap exhaustion. The earlier
passing component checkpoint also used 64 MiB. This experiment does not replace
or contradict the passing 8 MiB normal-startup gate, and is not claimed as
component qualification at 8 MiB.

The final corrected checker rejects mask 61 on forced callback Exit in
`build/i386-c4-derived-lifecycle-red-final/result.json`; its prior normal and
caught-exception cases pass. The cleanup candidate passes all 20 commands and
all six mask-63 lifecycle cases in
`build/i386-c4-derived-lifecycle-final/result.json`. Both result sets retain
unchanged pinned inputs. This establishes explicit derived-update lifetime
cleanup; the automatic mask-3 contract remains open until the prepass is wired.

The existing automatic A/B refresh regression also passes all 9 commands with
unchanged pinned inputs in `build/i386-c4-derived-scope-auto/result.json`.

## Automatic ring prepass candidate (Console 86)

The resident manager now runs the derived pass before view admission on every
iteration, including iterations without a custom shown document. This preserves
updates for hidden and covered tasks. It snapshots task numbers in predecessor
order, starting at the manager's predecessor and ending with the manager itself.
Each number is resolved again before entering the protected derived update. New
members join the next pass; disappeared members are skipped. The common list
scope releases the temporary numbers on exceptions and forced Exit as well as
normal completion. Failures retain the offending task number for the existing
worker report/unwind path. Full original general-error/debug policy is still
separate work.

The original spin wait remains the default in the shared core. The native hook
restores the caller's IRQ state, yields to the lock holder, then masks IRQs before
retrying. A waiting scope borrows the target but does not claim its lock; its
cancellation must not release another updater's lock. The new contention fixture
checks canceled and successful waiters, callback ordering, exact parent heap and
presentation reuse. Version 85 times out in the first contested call in
`build/i386-c4-derived-contention-red/result.json` with unchanged pinned inputs.

The automatic ring fixture attaches controls to two hidden tasks and a pass-end
marker to the manager. It checks predecessor order and completion in one pass,
then moves the first target to the bottom from its callback. This specifically
rejects a live-pointer walk that skips the second target. Setup briefly suspends
the manager while attaching controls, then resumes ordinary OS scheduling;
there is no app call to derived-value or presentation helpers during observation.
Cleanup checks task locks, manager identity, exact parent heap and frame reuse.

The matching pinned-original probe records `[15,13]` in
`build/i386-c1-auto-derived-ring-reference/result.json`, with unchanged inputs:
normal hidden-task updates succeed, but moving the first target makes the
original live-pointer loop skip the second in that pass. Native qualification
requires the safer snapshot behavior (mask 63 in both complete cases), while
preserving the original ordinary predecessor order and callback context. This
is a deliberate lifetime/traversal improvement, not a claim that the original
handles callback ring mutation safely.

```
python3 tools/test-i386-control-derived-contention.py IMAGE --out OUT
python3 tools/test-i386-auto-control-derived.py IMAGE --out OUT
python3 tools/test-i386-auto-derived-ring.py IMAGE --out OUT
python3 tools/test-i386-auto-derived-ring-reference.py --out OUT
```

Control-list mutation/reentrant derived updates, full bare-task control disposal,
ODE/events and mouse/cursor/stdout integration remain open. Completing these
prepass contracts does not close C2, C4, or any complete C1–C5 milestone.

## Console-86 final-image evidence

`build/i386-c2-automatic-derived-cross/kernel.img` is the final image. Bootstrap,
cross-build and the 386 boot audit pass. All 1471 recorded source/build inputs
match. The result files below retain their fixture/input provenance:

| Result path under build/ | Scope | Result |
| --- | --- | --- |
| i386-c2-automatic-derived-simple/result.json | First automatic control callback/width gate, 7 commands | pass |
| i386-c4-derived-contention-final/result.json | Canceled/successful contended waiters, 16 commands | pass |
| i386-c2-automatic-derived-ring/result.json | Hidden tasks, predecessor order and one-pass callback reordering, 21 commands | pass |
| i386-c2-automatic-derived-lifecycle-final/result.json | Actual manager owner-driven cancellation and actual death/restart, exact parent **and manager** live heap, 17 commands | pass |
| i386-c2-automatic-derived-explicit/result.json | All six explicit lifecycle cases, 20 commands | pass |
| i386-c2-automatic-derived-worker/result.json | Existing document-callback cancellation/restart, 14 commands | pass |
| i386-c2-automatic-derived-error/result.json | Existing document-callback error isolation/report/cooldown, 14 commands | pass |
| i386-c2-automatic-derived-document/result.json | Automatic full-window A/B document glyphs, 9 commands | pass |
| i386-c2-automatic-derived-frames/result.json | Windows/graphics/text frames at 64 MiB, 24 submissions including pause setup | pass |
| i386-c2-automatic-derived-startup/result.json | Normal 8 MiB startup, 9 commands, 48.64 seconds, manager enabled and zero build-provider loads | pass |

The automatic-derived lifecycle fixture records the manager's live heap while
paused before the scenario. After owner cancellation/replacement or actual
manager restart, it requires the same live-byte count on the healthy manager.
This checks temporary pass-snapshot recovery as well as the parent-owned control
allocation. It does not establish bounded peak memory for arbitrary callbacks.
The earlier lifecycle prototype lacks this manager-heap assertion; the final
17-command artifact above is authoritative for that stronger claim.

These are component/integration gates. Complete native generations using the
full desktop/application set are not qualified by these cross-built tests. The
older Console-84 development native-kernel attempt remains separate evidence.
