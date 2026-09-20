# Task-owned wait registration

Native tasks now have one private pointer to a borrowed CI386TaskWait record.
A blocking call owns that record on its stack and records its wait kind, resource
and cancellation callback before it can switch tasks. Sleep, join, queued ATA acquisition, message and raw-keyboard reads use this
registration; their successful, cancelled and failed-block returns clear it.
Nested waits are rejected. Task attachment, finishing and reaping reject a live
registration so its stack cannot be freed while another task can still find it.
The public CTask layout is unchanged.

`I386TaskCancelWait(task)` masks IRQs, finds the registration and invokes its
callback. Callbacks must preserve the registration and never switch tasks. A
recursion guard prevents nested dispatch. Accepted cancellation is marked until
the waiting call resumes; repeated cancellation does not touch its resource or
invoke its callback again. The direct sleep/join cancellation APIs mark the same
record, so direct and routed cancellation remain coherent. Completion that has
already occurred wins: the callback returns FALSE and normal cleanup proceeds.

The registration deliberately outlives removal from a resource queue. Cancelling
a join releases its target pin, but the cancelled call still has to return before
its own registration disappears. It can return after the target is reaped and
reused. The registration is not permission to jump over file/compiler cleanup,
and an empty slot alone does not prove that exception delivery is safe.

The common dispatcher is retained through ConsoleRuntime's fifth service entry,
`cancel_wait(task)`, avoiding another resident implementation in the constrained
bootstrap. Sleep registers a kernel-lifetime callback; join callers must retain
their code for the whole wait. CompilerProbe invokes the loaded dispatcher with
null and nonwaiting tasks in its worker diagnostic. The task corpus exercises
actual registered cancellation and completion races.

Extending the private task record changes the native lifecycle contract. Module
versions are advanced together to reject stale native consumers: CompilerRuntime 43,
FileRuntime 22, MemoryRuntime 7, ConsoleRuntime 10 and CompilerProbe 15. Console
services now occupy 28 bytes; the diagnostic configuration occupies 76 bytes.

Tests cover direct/routed cancellation, recursion rejection, repeated cancellation
with a failure-sentinel callback, preserved flags/deadlines/IF, registration
visibility until resumption, finish/reap guards, nested-wait rejection, completed
targets and target reuse before cancelled joins return. The private layout change
also requires task heap, symbol, exception, ATA, input and message regressions.

ATA and message registration is described in
[resource wait registration](i386-resource-wait-registration.md); FileRuntime is
now version 23. [Keyboard wait registration](i386-keyboard-wait-registration.md)
adds the raw input path through ConsoleRuntime 11. Establishing ownership
of a dedicated retained task service, respecting pending-break locking, and arranging
cleanup and original exception/message/job/popup delivery remain required. This
is not public Break or a complete interruption coordinator.

Validation results and bootstrap size are recorded in `port-progress.md` after
execution.
