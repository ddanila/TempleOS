# Popup cancellation and menu chooser baseline

Console 90 passes the initial 18-command popup lifetime gate in
`build/i386-c2-popup-lifetime/result.json`: live previous-owner restoration,
retired-owner rejection, recovered caller cancellation, committed caller kill,
unpublished output preservation, exact Root caller heap and reusable graphics.
The caller in that first cancellation test exits immediately after its catch;
that is insufficient evidence for a recovered caller that continues working.

## Live caller exposes a pending-result bug

The expanded checker keeps the recovered caller alive until after its child has
retired. It inspects the caller's waiting/done rings and heap before allowing that
caller to exit. Console 90 returns mask 191 instead of 255 in
`build/i386-c2-popup-live-caller-red/result.json`, with unchanged pinned inputs.
Its captured `startup-command-22.ppm` shows 191. All earlier lifetime bits and the
live caller heap pass; bit 64 (empty request queues) is missing. The final
arithmetic command is not submitted after the failed frame assertion.

The old cleanup retired the child but forgot the in-flight request. Aborting the
child then posted a result into the recovered master's done queue, where a later
JobResScan could consume it. Caller retirement eventually removed it and hid the
problem from the first test.

## Request ownership repair

Console 91 keeps the public TaskExe signature and behavior. A private owned-submit
variant publishes an optional request slot at queue insertion, before suspension
can unwind the call. PopUp uses it when the submitting caller is its synchronous
master; async handoff retains its original free-on-completion policy.

JobDel clears matching popup ownership before freeing a request, including normal
JobResScan consumption. Cancellation unlinks/deletes an already completed owned
request, or detaches the master and marks a queued/dispatched request for worker
cleanup without a late wake, focus change or result publication. Cleanup does
not yield. Successful async handoff detaches both child and request ownership.
Public layouts, 229 exports, Memory 25 and the 48-byte private service table are
unchanged. Foreign-master and arbitrary output-pointer owner lifetimes remain
outside this qualification.

```sh
python3 tools/test-i386-popup-lifetime.py IMAGE --out OUT
```

The final 24-command gate requires masks 63 for recovered cancellation and
committed kill, then 255 for the surviving caller's empty queues and recovered
heap. It also checks previous-owner behavior, output storage, task retirement,
presentation reuse and continued input. Final candidate results follow below.

## Original ownership difference

The pinned original returns [0,1] in
`build/i386-c1-popup-owner-reference/result.json`: it loses a still-live previous
popup owner but leaves null when that owner retires. The rebuilt original repeats
[0,1] in `build/i386-c4-popup-owner-current-reference`. Both retain unchanged
inputs. The native contract intentionally restores a live previous owner,
validated by identity, while rejecting a retired one. This is a cleanup repair,
not evidence that every original popup ownership mode is compatible.

## Real menu interaction baseline

`build/i386-c1-menu-chooser-reference-final/result.json` passes the actual
original DocEd/DocMenu path, without an interposed chooser. Explicit observations
are [11,12,22,-1,17,1]: first left/right values, second-entry selection, ShiftEsc
cancel, callback value and callback-unlocked state. Each case additionally checks
MSG_CMD where applicable, put/display restoration, end callback, border source,
break-to-ShiftEsc flag and document unlock. All fixture/checker inputs are
unchanged. The extracted MenuChooser.HC is the source used by both runners.

The earlier inline fixture also passes; its first file-backed version uses the
wrong C: drive and times out before chooser observations. The final reference
uses the boot-root :: path. This fixture repair does not alter chooser behavior.

`build/i386-c2-menu-chooser-console91-red/result.json` rejects the missing native DocMenu
call before fixture transfer or any chooser cases. The future passing native
runner requires exact guest fixture bytes. Mouse interaction, bound data editing,
no-action restart, popup placement/lifetime and complete chooser rendering remain
open. Next integrate the complete entry-action/menu/list dependencies, preserving
the original behavior, before binding the full GetStr path. C1–C5 remain open.

## Qualified Console-91 checkpoint

`build/i386-c2-popup-live-caller-green/result.json` passes all 24 commands with
unchanged inputs, including the live-caller mask 255 and final arithmetic.
The ordinary 13-command popup execution gate also passes with unchanged inputs
in `build/i386-c2-popup-live-caller-execution`.

Original bootstrap, cross-build and limited 386 boot audit pass in
`build/i386-c2-popup-live-caller-cross`; all 1475 source/build hashes match.
The nine-command normal 8 MiB startup gate passes in 48.698 seconds, WinMgr enabled,
without build-provider loading (`build/i386-c2-popup-live-caller-startup`).
Actual worker jobs pass 24 commands at 64 MiB with exact fixture bytes in
`build/i386-c2-popup-live-caller-jobs`; self-directed jobs pass 21 commands at
8 MiB in `build/i386-c2-popup-live-caller-self-jobs`. Existing 8 MiB spawned-worker
capacity, general foreign-master/callback/output-owner cases, full servant
startup and menu/GetStr integration remain open. No milestone closes here.
