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
