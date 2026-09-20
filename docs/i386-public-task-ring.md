# Native public live-task ring

The native scheduler maintains `CTask.next_task` and `CTask.last_task` as a
circular, doubly linked list of attached live tasks. The boot root initially
links to itself. A successfully attached worker is appended before the root;
failed construction never publishes the worker. Initialization and attachment
reject records that already contain public links without modifying the list.

Blocked tasks remain in this list. Yield, block and finish select the next
eligible task in public list order. Reordering that list therefore changes
round-robin dispatch, as required by the original scheduler/window ordering.
Wakeup makes a task eligible without changing its public position. The private
`CI386Task.next/last` queue still records runnable membership for idle checks and
internal lifecycle checks, but its insertion order no longer controls dispatch.
The root cannot privately block, but public task flags can suspend it. Selection
idles until an IRQ makes a task eligible when all are suspended. See
[task eligibility](i386-task-eligibility.md). This does not yet implement the
complete public `Yield` scheduling contract.

Task and compiler cleanup callbacks run while the exiting task is still linked,
including callbacks that yield. Finish detaches both public links before switching
away. Reap rejects a task that still has either public link; file, symbol and
heap destruction therefore observe an already detached task. Existing interrupt
masking protects attachment and detachment. Record layouts and module interfaces
are unchanged.

## Verification

Run the bootstrap rebuild before the native suites:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --tasks
python3 tools/test-i386.py --task-heaps
python3 tools/test-i386.py --messages
python3 tools/test-i386.py --except-tasks
python3 tools/test-i386.py --task-symbols
python3 tools/test-i386.py --ata-tasks
python3 tools/build-i386-kernel.py --test
```

The task corpus checks reciprocal links and exact membership through attachment,
blocking, reverse-order wakeups, interrupt-driven wakeup, finish, reap and record
reuse. It also rejects stale links during root initialization, attachment and
reaping. The task-heap corpus checks failed-spawn isolation, membership inside
cleanup callbacks, and detachment before file/symbol destruction.
Both scheduler rounds wake task 2 before task 1. The first dispatches 1 then 2
in attachment order; the second reorders only the public links while both tasks
are blocked and dispatches 2 then 1. This distinguishes actual public-order
scheduling from merely maintaining a second list beside the private queue.
Message, exception, compiler-ownership and ATA suites exercise consumers whose
waits and cleanup cross task switches. Scheduling order must not alter resource
ownership or the FIFO order of device wait queues.

Native compiler probes traverse the public fields through typed `Fs`, checking
root-only and worker membership and neighboring task signatures. The interactive
console checks reciprocal links with another live task present.

## Remaining integration

Public `Yield` still needs wake-time eligibility and original public message/job
services. Parent/child/sibling links, saved-register
state and pending-break delivery are separate contracts. `BreakUnlock` cannot
deliver a native break merely by writing the public `rip` field: the native
context and any active waiters must be handled consistently before unwinding.
These remain prerequisites for the original document-locking workflow; see
[DolDoc integration](i386-doldoc-integration.md).
