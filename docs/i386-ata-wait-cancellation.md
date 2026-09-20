# Queued ATA acquisition cancellation

`I386AtaChannelCancelWait(channel, task)` removes a pending acquisition from its
physical channel's FIFO. The waiter lives on the acquiring task's stack. IRQs
remain masked while the routine validates private wake eligibility, restores
runnable membership, unlinks the waiter and clears its queued flag. Wake cannot
switch tasks, so the stack record is detached before the task can resume.

The resumed `I386AtaChannelAcquire` returns FALSE. It never owned the channel,
and normal caller cleanup can release borrowed file/compiler references. The
operation preserves the current owner, lock counts, FIFO order of surviving
waiters, public suspension/message flags, wake deadline and caller IF. A task
already granted ownership cannot be cancelled through this operation, including
when it has not yet resumed. Invalid, foreign, finished and nonqueued tasks fail
without modifying the queue. Pending waiters can be removed from a poisoned gate.

FileRuntime ABI 21 appends `cancel_wait(task)` to its 40-byte service table. It
searches the module's two physical channels. Code stays in the retained module;
the resident kernel only gains the service pointer. The loader validates the new
callback address and rejects the old ABI before invoking services.

The task corpus covers head, middle, tail and complete removal, poisoned queues,
blocked and spuriously woken waiters, suspension and a 64-bit wake deadline,
IF preservation, grant-before-cancel, FIFO survivor execution, task destruction,
heap reclamation and channel reuse. The kernel diagnostic probe calls the loaded
service with null and nonwaiting tasks in root and worker phases; actual queued
cancellation is exercised by the dedicated task corpus.

This is a prerequisite for original Break handling, not its implementation.
Active ATA operations and owners are not aborted. Sleep, joins, public message
waits, popup propagation, file/compiler reference cleanup and exception unwinding
still need a coordinated interruption contract. In particular, future Break must
not jump over cleanup merely because the ATA stack waiter has been detached.

Validation results are recorded in `port-progress.md` after execution.
