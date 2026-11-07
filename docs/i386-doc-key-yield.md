# DocPutKey cooperative scheduling reference

Original DocPutKey ends with Yield unless DOCF_DONT_SWAP_OUT is set. Its
user_put_key callback runs first; a consuming callback returns before that
Yield. An existing document lock does not suppress the final Yield.

The fixture creates a real child task and waits until it reports readiness.
The parent disables local interrupts, opens the child's progress gate, calls
DocPutKey with shifted Ctrl-C (an original no-op), and immediately samples
child progress. It restores the incoming interrupt flags before cleanup.
One CPU and disabled local interrupts exclude timer preemption from the
observation, so progress across the call requires cooperative scheduling.
The observer does not change document state or trigger a key action.

Five cases cover default behavior, DOCF_DONT_SWAP_OUT, consuming and
non-consuming callbacks, and an incoming document lock. Each checks the
expected progress, interrupt/lock preservation, callback count, caller document
roles and worker retirement. Exported samples are compared independently of
the guest masks.

Build i386-doc-key-yield-original-v1 passes masks [63,63,63,63,63] and samples
[1,0,0,1,1]. Build i386-doc-key-yield-native-baseline-v1 fails with masks
[62,63,63,62,62] and samples [0,0,0,0,0]. Only the expected-progress bit fails
in the three yielding cases; all other observations pass. Both terminal
audits independently reverify input hashes.
The retained native DocPutKey currently lacks the final Yield; this fixture
establishes the precise compatibility requirement before changing scheduling.
It does not qualify arbitrary preemption, reentrant callbacks or full input
behavior. C2/C4 and all C1–C5 milestones remain open.
