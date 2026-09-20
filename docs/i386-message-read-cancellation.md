# Native message-read cancellation

`I386MsgCancelRead(queue, task)` cancels one registered blocking read. It leaves
queued messages, recipient attachment and the queue's open/closed state intact.
The cancelled read returns zero without changing the caller's output record.

The queue borrows a pointer to a Boolean on the reader's stack while a read is
registered. Cancellation sets that Boolean, removes both registration pointers
and clears the awaiting-message bit owned by the read. Private runnable membership
is restored when needed. All changes happen with IRQs masked, and wake does not
switch tasks. Suspension, unrelated task flags, wake deadlines and caller IF are
preserved. Null, foreign, finished and nonwaiting tasks cannot cancel a read.

After waking, the read checks its local Boolean before accessing the queue. Thus
an unbound queue can be freed/reused, or another reader can register, before the
cancelled task resumes. The old call neither reads the reused queue nor clears
the replacement reader's registration. Every ordinary read exit also clears the
borrowed pointer, preventing later access to an expired stack frame.

A send or close wakes a reader but does not finish its read. Cancellation can
still win before it resumes; queued messages remain available for a subsequent
read. This differs from ATA ownership transfer or completed join/expired sleep,
where completion is already final before the task resumes.

Six native scenarios cover blocked and spuriously woken readers, attached and
unbound queues, send/close before cancellation, output and IF preservation,
suspension/bit-31/wide deadlines, repeated/invalid cancellation, exact queue
allocation reuse/overwrite and a replacement reader. Existing inbox lifecycle,
message filtering and real keyboard/broker/focus delivery remain in the corpus.
The expanded runner uses the existing 384-sector profile below its first heap
at 0x40000.

This changes the private CI386MsgQueue layout; it is not the public TempleOS
Msg/GetMsg contract. The queue remains a component linked by the message runner,
not the interactive kernel. Raw keyboard wait cancellation, popup/job semantics,
a coordinated pending-break protocol and cleanup before exception delivery are
still required. Cancellation permits ordinary caller cleanup; it does not make
an arbitrary jump out of a suspended call safe.

Validation results are recorded in `port-progress.md` after execution.
