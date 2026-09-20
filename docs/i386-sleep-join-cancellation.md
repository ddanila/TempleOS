# Native sleep and join cancellation

`I386SleepCancel(queue, task)` detaches a queued stack waiter while IRQs are
masked, restoring private runnable membership without switching tasks. Remaining
ticks stay nonzero, so the resumed `I386SleepTicks` returns FALSE. Expiry sets
remaining ticks to zero and removes the waiter; cancellation after expiry returns
FALSE and the sleep still succeeds. No waiter-layout or timer-rate change is
needed. Public flags, wake deadlines and caller IF remain unchanged.

`I386SchedCancelJoin(scheduler, task)` unlinks the task from its target's join list
and clears both join links before allowing it to resume. The waiting call checks
its own join registration before dereferencing the target and returns FALSE when
cancelled. Once detached, the target can finish and be reaped, even if suspension
or another public wait condition delays the cancelled task. If the target has
already finished, cancellation fails: the join registration continues to pin the
target until the normal successful join returns and removes it.

Both operations reject null, foreign, finished and nonwaiting tasks. Wake only
changes private runnable membership. Neither operation clears public suspension,
message flags or wake deadlines. The masked critical section covers both wake
and unlinking, so no resumed task can retain a dangling queue record.

The native task corpus exercises head, middle, tail and complete removal,
blocked and spuriously woken tasks, IF preservation, bit-31/public suspension,
wide wake deadlines, timer expiry and target completion before cancellation,
repeated cancellation rejection, target reaping/reuse before cancelled joins
return, stack/task destruction and heap reclamation. Existing timer/exception
coverage continues to exercise sleep expiry under real PIT interrupts. The
expanded task corpus uses the existing 640-sector transfer profile, ending at
0x60000 where its heap starts. Its temporary segment-test records move to
0x70000/0x70100, beyond the test heap, to avoid overlapping loaded code.

These internal operations do not implement public Break or task killing. A
coordinated interruption path must still arrange caller cleanup, pending-break
state, message/job/popup behavior and exception delivery. Removing a wait does
not authorize skipping file/compiler cleanup or aborting active I/O. The join
helper remains separate from the resident scheduler core; sleep runs in the
kernel's existing timer queue. Sleep's failed-block path shares the cancellation
unlink operation. Startup and diagnostic module lookup now reuse the existing
RedSea path resolver, including its intermediate-directory validation, to avoid
duplicating directory walks in the constrained bootstrap image.

Validation results are recorded in `port-progress.md` after execution.
