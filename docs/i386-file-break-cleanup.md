# Break recovery from a queued compiler include

A cancelled disk include may produce a normal parser/allocation error before
returning to a command-input checkpoint. CompilerRuntime 45 checks that case in
its existing catch boundary. If an ordinary unlocked break is pending and the
same resource-readiness predicate passes, it records 'Break' as the exception to
deliver. It does not throw from inside the catch: first it unwinds the private
compiler control back to the caller's saved boundary, then consumes the request
and rethrows to the outer handler. Failed cleanup leaves the request pending.
Other exception kinds retain their original handling.

The readiness test still rejects an active wait, disk ownership, extra borrowed
lifetime references, busy/failed compiler cleanup, inbox ownership, break locking
and Shift-Escape mode. Each active compiler control contributes one known
reference that this boundary can release; a file borrow contributes another and
must return normally before the error can become a break. The general task poll
retains its stricter no-active-controls rule.

A worker-phase diagnostic holds a real RedSea complete-operation lease in the
parent, then runs a compiler include in a child. The child queues behind the
parent's ATA ownership with its file context borrowed and compiler control live.
Immediate and lock-delayed requests cancel that queue entry through the common
wait callback. Before resuming the child, the test checks that the parent still
owns the channel and the child's file borrow and lifetime reference still exist.
It then releases the parent's lease and lets normal file error handling return.

The child's outer catch requires 'Break', no live wait, no I/O or file borrow,
no active compiler controls, no pending flag, and preserved IF. After the catch,
compiler heap totals and references must return to their baseline and the
private function must remain unpublished. The same child then reads the original
file successfully and compiles/executes 6*7. Task destruction must return the
parent's heap totals, references and channel state to baseline. Both IF-clear and
IF-set inputs are covered. Probe code and child callbacks remain loaded until
all children finish and are reaped; normal boot does not run this diagnostic.

This covers real file/compiler cleanup rather than only injected ownership
counters. It still does not implement focused keyboard break requests,
interruption of non-returning code, original message/job/popup semantics or the
DolDoc editor. Those remain required for the editing-session goal.

Validation passed both x64 rebuild generations and the full native kernel suite,
including both queued-file cases, the earlier compiler-break corpus, console and
module rejection checks. Exact hashes, sizes and timings are recorded in
[port progress](port-progress.md).
