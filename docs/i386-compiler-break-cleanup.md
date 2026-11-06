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
lock-delayed delivery followed by another successful command. The follow-on [queued-file diagnostic](i386-file-break-cleanup.md) exercises
cancellation while a real file read is queued and checks compiler error-to-break
conversion in version 45. Native editor interruption remains required.

Validation passed both x64 rebuild generations and the full native kernel suite:
six boot/worker cleanup cases, 137 console commands, exact VGA, startup recovery
and 17 module rejection cases. Sizes and timings are in
[port progress](port-progress.md). The normal preview contains this behavior.

## Full minimal-gate terminal mismatch (2026-11-06)

The historical full gate in
build/i386-public-break-frontier-v1/build/i386-public-break-minimal-gate-v1
is stopped, not still running. It timed out in source-syntax-error at the first
post-startup command, `BootCount;`. Its saved frame shows `39` and the prompt;
the expected rows instead require `Error: Undefined identifier at `. Debug
output records COMMAND OK. The preceding source deliberately declares
`I64 BootCount=39;` before `Unknown bad;`, so the mismatch concerns whether a
completed declaration survives the later source error. It must be resolved
against the original compiler behavior before changing the runtime or oracle.

The terminal audit in build/i386-public-break-minimal-terminal-audit.json
checks all 3719 pinned files with no differences. The captured actual frame
was decoded to build/source-syntax-error-observed.png for inspection. This is
a failed full gate; preceding component passes do not qualify the minimum
profile or C1-C5.


## Original error semantics and native startup comparison (2026-11-06)

The original compiler preserves completed declarations across the later error.
The shared fixture in tests/guest/i386-source-error executes the exact malformed
source from the full gate: BOOT_SEEN=7, BootCount=39, then Unknown bad. The pinned
original control in build/i386-source-error-original-v3 and native comparison in
build/i386-source-error-native-v3 both pass mask 15: BootCount remains published
and evaluates to 39, bad is absent, BOOT_SEEN evaluates to 7, and a subsequent
assignment to 41 followed by increment leaves BootCount at 42. Checks use
HashFind and ExePutS, with no direct symbol-storage access. The native run also
renders fresh 42 after returning to the console. Both retain unchanged inputs.

A separate normal-startup test in build/i386-source-error-startup-v1 uses an
8 MiB KVM 486,-fpu guest and replaces only the reserved StartOS.HC source bytes.
It requires the passing original control and the same malformed-source hash,
observes STARTUP source error, then checks BootCount=39, absent bad, the later
42 value, preserved macro, Fs->gs==Gs and rendered arithmetic. All pass. The
working disk remains byte-identical to the intentionally prepared candidate;
only StartOS.HC differed from the original image. No runtime change was needed.

Therefore verify_source_startup's expected undefined BootCount is incorrect.
Its syntax-error case should require 39 and then assign BootCount=41, retaining
the increment, macro and Gs checks. The old checker has not yet been edited or
the full gate rerun: tools/build-i386-kernel.py is pinned by the still-running
nine-module native build in build/i386-inline-call-native-nine-v2. This evidence
resolves the semantic question, not the full minimal gate or C1-C5 completion.

The initial native probe attempt stopped at a packaging collision with an
existing /Probe/Bad.HC; the replacement uses /Probe/SourceErrorBad.HC. A second
attempt rejected the fixture's unexposed CHashGlblVar type before execution.
The final fixture uses public expression evaluation instead. Earlier original
controls also observed preservation; their frozen sources and failure attempts
remain retained. The public type exposure gap is not claimed fixed.

```
python3 tools/test-i386-source-error.py --out OUT_ORIGINAL
python3 tools/test-i386-source-error.py build/i386-inline-call-cross-v1/kernel.img --out OUT_NATIVE
python3 tools/test-i386-source-error-startup.py build/i386-inline-call-cross-v1/kernel.img --reference OUT_ORIGINAL --out OUT_STARTUP
```
