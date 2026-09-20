# ATA and message wait registration

Queued ATA acquisition and blocking message reads now publish a borrowed
CI386TaskWait on the waiting task. The existing common dispatcher can cancel
these waits without knowing which resource queue owns them. Direct and routed
cancellation mark the same record; repeated dispatch skips the resource callback.
The record stays on the waiting stack until the call resumes and returns, so
existing finish/reap guards continue to protect that stack. Nested blocking
acquisitions and message reads reject an existing registration.

ATA cancellation only removes a queued acquisition. A grant that already made
the task channel owner wins over cancellation; active transfers are not aborted.
FIFO survivors, channel ownership, I/O lock counts, public flags, deadlines and IF
retain their existing behavior. FileRuntime advances from version 22 to 23 so an
older retained module cannot silently omit registration. Its table remains 40
bytes; the task and public record layouts do not change.

Message cancellation detaches the queue waiter and its borrowed cancellation
flag, preserving queued messages. The task registration remains marked cancelled
until normal return, which checks only that stack state before clearing the task
slot. A queue can therefore be freed and reused, or acquire a replacement reader,
before the old reader resumes; repeated routed cancellation does not inspect the
old queue. Message-read output stays unchanged on cancellation. A send or close
that wakes the reader does not consume data, so cancellation can still win before
the reader runs.

The task and message corpora alternate direct and common-dispatch cancellation.
They check registration visibility, nested-wait rejection, repeated cancellation,
normal-return clearing, preservation of flags/deadlines/IF, queue order and
ownership, grant-before-cancel, and queue reuse or replacement readers before a
cancelled read returns. The ATA task suite checks the integrated disk path.

Raw keyboard still needs task registration. A dedicated retained task service,
pending-break locking, outer file/compiler cleanup and original exception,
message, job and popup behavior remain required. A cleared registration alone is
not evidence that jumping to exception delivery is safe. This change does not
publish public Break or complete M4.

Validation: both x64 rebuild generations, native tasks/messages/ATA-task suites,
and the full boot/console/rejection suite pass. Exact input hashes, memory sizes
and boot timings are recorded in [port progress](port-progress.md).
