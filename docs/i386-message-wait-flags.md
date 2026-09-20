# Native message waits and public task flags

The native queue component now maintains `TASKf_AWAITING_MSG` alongside its
private reader registration. An empty blocking read sets the bit with interrupts
masked before blocking. An accepted send or queue close clears it before waking
the registered reader. Rejected sends do not change wait state. Suspension and
unrelated task flags are preserved.

An attached recipient's public wait bit is cleared even when it has not entered
the private reader. This supports the original flag-then-yield waiting pattern.
Only a registered queue reader receives a private scheduler wake; message arrival
must not release a task blocked on some unrelated condition. Unbound queues also
clear the registered reader's bit. The operation retains the existing single-CPU
interrupt masking and never preempts the current task.

A generic scheduler wake leaves the public wait bit set, so the reader remains
ineligible until a send or close satisfies the message-side wake condition. When
the reader runs, it still applies its mask: unmatched messages are discarded and
an empty queue establishes the wait again. Closing preserves queued messages for
draining and releases an empty reader to return zero. A returning reader clears
the bit it owns before removing its waiter registration.

The native message suite covers bound and unbound queues, generic wakeups,
unmatched messages, data queued before close, empty close, suspended recipients,
public waits without a private reader, rejected operations, unrelated bit-31
preservation and IF restoration. Its existing QMP keyboard corpus still passes
events through the IRQ, broker, focus target and consumer, with checks that
message returns and final close leave no awaiting-message bit behind. Owned
inbox lifetime and reclamation checks remain in the same suite.

Run `python3 tools/test-rebuild.py`, then `python3 tools/test-i386.py --messages`.
This component is exercised by the dedicated runner; the current interactive
kernel console reads keyboard input directly and does not link Message.HC.
These results do not establish integration of the original public Msg/GetMsg,
job queues, popup propagation or TaskRstAwaitingMsg. Those services and break
cancellation still need to be connected to the original environment.
