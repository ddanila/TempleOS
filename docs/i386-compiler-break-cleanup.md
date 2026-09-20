# Pending breaks through compiler input cleanup

Native command input now observes pending breaks inside its existing catch and
compiler-control unwind boundary. Checkpoints run before creating input state,
after a failed control factory, before and after initial lexing, before and after
command compilation, after execution returns, and before publication. This is
cooperative checking at returning calls, not asynchronous interruption of an
arbitrary instruction or a non-returning program.

Unlike the general task checkpoint, this boundary owns compiler controls and
knows how to release them. Eligibility requires no wait, blocked state, I/O lock,
compiler busy/failure state or inbox. The task's lifetime reference count must
match its active control count: each active control owns one reference, while an
additional file-context borrow or other reference defers delivery. Locked and
Break-to-Shift-Escape requests also defer. IRQ masking protects the eligibility
check and caller IF is restored before exception handling.

An eligible checkpoint raises an internal 'Break' into the input catch. The
existing unwind releases the private frontend, generated code, input/include
state and unpublished definitions back to the saved compiler boundary. Only a
successful unwind clears the pending bit and rethrows 'Break' to the caller's
handler. If unwind reports failure, the input returns failure with the request
still pending rather than rethrowing past incomplete cleanup. Ordinary completed
side effects are not rolled back, and previously published definitions survive.

CompilerRuntime advances to version 44 with the same service layout. Console
recovery uses its existing exception handler; no public Break/Yield binding,
focused Ctrl-Alt-C producer, original message/popup behavior or preemption is
added here. Pending requests can be exercised by setting TASKf_PENDING_BREAK
from native HolyC; this is a diagnostic entry, not the final keyboard workflow.

The diagnostic corpus checks a request already pending before input and repeated
requests after private function compilation/execution, on boot and worker tasks.
It checks the real outer catch, pending-bit clearing, caller IF, exact compiler
heap allocation totals, lifetime references and absence of the unpublished
function. Console cases exercise recovery, private-definition rollback and
lock-delayed delivery followed by another successful command. These tests do not
by themselves establish cancellation while an actual file read is queued, or
native editor interruption. Those integration cases remain required.

Validation passed both x64 rebuild generations and the full native kernel suite:
six boot/worker cleanup cases, 137 console commands, exact VGA, startup recovery
and 17 module rejection cases. Sizes and timings are in
[port progress](port-progress.md). The normal preview contains this behavior.
