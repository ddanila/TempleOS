# Native message queues

`Kernel/I386/Message.HH` and `Message.HC` provide a bounded message transport
for the native scheduler. Each queue stores 16 records containing I64 `type`,
`arg1` and `arg2`, preserving the argument widths used by TempleOS messages.
Initialize persistent queue storage with a zero scheduler field and a live
initialized scheduler. An already associated queue cannot be initialized again.

Send accepts types 1–63 and never blocks. Full, closed or invalid queues reject
the send without replacing retained messages. The producer owns retry/drop
policy. Successful sends wake a pending reader without switching the current
task. Send/Close are usable from maskable IRQ context; all operations save IF,
mask interrupts during queue access and restore incoming IF. One CPU is assumed;
NMI access and arbitrary metadata corruption are outside the contract.

Read takes an output record, a U64 type mask (default all nonzero types), and a
wait flag. Like ScanMsg, it removes unmatched messages while searching for a
match. It returns the selected type, or zero for unavailable/invalid input,
without modifying the output on a zero return. An empty worker read may block;
root and nonblocking reads return immediately. One reader may be pending, and
competing readers cannot take its messages. Predicate checking, registration and
blocking remain under one interrupt mask; spurious wakes recheck the queue.
Output storage must be writable and outside the queue record.

Close rejects future sends, retains queued messages for draining, and wakes a
pending reader. Once a closed queue is empty, reads return zero. Close does not
wait for a blocked reader to resume. Keep the queue and scheduler alive until all
readers/producers have returned; for a worker, join/observe its completion before
reclaiming the record. Cancellation, queue reuse and automatic task-owned queue
allocation remain pending.

`python3 tools/test-i386.py --messages` runs a separate native fixture. It checks
full-queue rejection, wraparound, FIFO order, complete 64-bit payloads, mask-based
discard including type 63, invalid arguments, nonblocking reads and draining
closed queues. An input broker then receives live QMP keyboard events, converts
them into type/character/scan messages, and sends them to a second blocked worker.
The consumer verifies all nine events and IF restoration. An unrelated wake
returns it to waiting. After the final message it blocks on the empty queue;
close wakes it to finish, and both worker records are reaped.

This is explicit queue delivery on QEMU 486/8 MiB. The queue is not yet attached
to the full public CTask/CJob structures. TaskMsg/ScanMsg/GetMsg wrappers, focus
and popup routing, job execution, per-task ownership and input-loss recovery
remain pending before it can replace the original public message path.

## Task-addressed inboxes

A native task now has a `messages` pointer. `I386MsgAttach` binds an empty,
initialized, open queue to a live task in the same scheduler. Both associations
must be unused; finished/finishing tasks and queues with a pending reader are
rejected. Once attached, only the recipient may read the queue. Explicit generic
queues remain available when no recipient is attached.

`I386TaskMsgSend(task,type,arg1,arg2)` sends through that inbox. It preserves IF
and rejects tasks without a live owner/inbox or tasks already finished. Direct
queue sends also reject a finished recipient. Callers must retain valid task and
queue records; these APIs do not validate stale pointers into reclaimed memory.

Completion does not automatically close the inbox. Reap, and consequently owned
task destruction, rejects any task with an attached inbox. Close wakes a waiting
recipient; after it has returned, `I386MsgDetach` clears both associations and
discards remaining queued messages. Detach requires a closed queue without a
pending reader, and may be performed by the recipient itself or by another task
after recipient completion. The record remains closed and cannot be reinitialized.
The caller owns its allocation and may reclaim it after all users have returned.

The message fixture sends live keyboard events by recipient task. It verifies
that root cannot steal queued messages, unmatched messages are discarded by the
recipient's key-event mask, duplicate attachment and premature detach fail, and
reaping is blocked until detach. A second worker returns with an open inbox and
unread data; sends/reaping fail, then external close/detach discards the data and
allows reaping. The full task suite also passes with the enlarged native record.
Automatic inbox allocation and the complete public CTask/CJob interfaces remain
pending.

## Heap-backed inbox ownership

`Inbox.HH` / `Inbox.HC` add `I386InboxAlloc(task,heap)` and
`I386InboxFree(inbox)`. Allocation uses the supplied native heap, initializes an
empty queue and attaches it to the live task. A missing/finished/finishing task,
existing inbox, invalid heap or exhausted arena fails without attaching anything.
The helper frees its allocation if queue setup cannot complete.

The returned `CI386OwnedInbox` contains the queue and its heap ownership metadata.
Free accepts a live owned record, validates its allocation size, and requires no
pending reader. It permits the recipient's own cleanup or cleanup from another
task after recipient completion. It closes the queue if necessary, detaches it,
discards unread messages and returns the block to its original heap. A rejected
foreign cleanup of a live recipient leaves its queue open and attached.

Use the ownership helper for the full lifecycle: do not manually detach an owned
inbox and then pass it to Free. Keep the heap, inbox and task records alive until
cleanup completes, and retain no queue pointers after a successful free. These
are task-context operations under a saved interrupt mask, with the raw heap's
validation/latency limits. They do not run allocation in IRQ handlers or add an
inbox automatically to every Spawn call.

The native message suite exercises exhausted allocation, duplicate attachment,
rejected live-task cleanup, completion with unread data and full arena reclamation
across repeated cycles. A third recipient frees its own inbox with IF enabled;
its association is cleared and IF restored before normal task completion. The
existing live keyboard broker/consumer path continues to pass.

## Native focus selection

`Focus.HH` / `Focus.HC` route messages through one selected recipient stored in
`CI386Scheduler.focus`. `I386FocusSet(s,task)` requires a live, non-finishing task
in that scheduler with an open attached inbox. Null clears focus; invalid
selections preserve the previous target. Selecting the same valid task is safe.
`I386FocusMsgSend` reads the selection and submits the task-addressed message
under one saved interrupt mask. Missing, closed or finished recipients reject
publication through the existing send checks. No task switch occurs in send.

Reap now also rejects the selected focus task, even if its inbox has already
been detached. A completed recipient remains a valid referenced record until
focus is moved or cleared. Completion does not choose a replacement implicitly.
Inbox cleanup and focus cleanup are separate: closing/detaching a selected inbox
makes sends fail, while clearing focus releases the remaining task-lifetime hold.
Keep the scheduler live and modify focus only through the setter.

The message fixture switches between root and the keyboard consumer, checks
that messages reach only the selected inbox, verifies empty/invalid selections,
and then routes all live QMP events through focus. After consumer completion and
inbox detach, reaping remains blocked until focus is cleared. The full task suite
also passes with the enlarged scheduler record.

This is native recipient selection, not full window focus. Focus notifications,
popup/parent selection, ownership of releases across a focus change, and graphics
activation are pending. Each message currently goes to the recipient selected at
publication time, consistent with the existing keyboard broker's use of a global
focus task.
