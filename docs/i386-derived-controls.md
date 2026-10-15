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
