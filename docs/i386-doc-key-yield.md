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
The baseline native DocPutKey lacks the final Yield; the fixture established
the compatibility requirement before the production change.
It does not qualify arbitrary preemption, reentrant callbacks or full input
behavior. C2/C4 and all C1–C5 milestones remain open.

## Restored native behavior

Native DocPutKey now invokes the existing managed Yield provider after its
owned lock is released, unless DOCF_DONT_SWAP_OUT is set. Consuming callbacks
still return before dispatch/yield; incoming locks remain held across the
yield, exactly as in the original. The provider declaration moved before the
document implementation include. No public ABI/version change is required.

Build i386-doc-key-yield-native-v1 passes all five masks and samples byte for
byte against original-v1. The unchanged driver also passes arithmetic and
filesystem checks; terminal-audit.json independently rechecks pins and exports.
The nineteen clipboard key/resource cases pass unchanged on the same image,
with exact zero caller/root heap deltas. Both actual FileMgr file/tree clipboard
workflows pass all thirteen rows, exact payloads, restoration and reboot;
independent terminal audits verify every original file/directory and exact
added fixture contents after reboot.

Both bootstrap generations pass in rebuild-doc-key-yield-v2-verified, followed
by the full64 cross-build and a post-export match of all 1,737 production
hashes. The provisional v1 bootstrap was deliberately cancelled after source
inspection found the Yield declaration after its new call site; its partial
artifacts and reason are preserved. It is not qualification evidence.

Normal8 startup and full16 diagnostics reach DONE and match all 307,200 welcome
pixels. Full16 completes both program, code-heap ownership and file-break
cleanup phases. These concurrent runs do not qualify isolated startup timing
or the larger enclosing interactive suite. The five-session file-picker
regression remains live at this implementation commit. Printable metadata
queries remain a separately reproduced preexisting gap; see
i386-doc-key-description.md. Full DocPutKey and C1–C5 remain unqualified.
