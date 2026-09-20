# Break checkpoints in native JIT branches

The native frontend now asks the backend to instrument backward conditional and
unconditional IR branches. The decision uses IR label order in both passes,
so stale sizing-pass addresses cannot change checkpoint placement. Each checkpoint saves flags, tests TASKf_PENDING_BREAK
through the current task's FS binding, and skips the runtime call when clear.
When pending, PUSHAD/POPAD preserve general registers around a normal call to a
retained compiler-runtime poll; POPFD restores the branch's original flags.
Expression operands already on the stack remain untouched. The 24-byte sequence
uses 386 instructions and is emitted consistently in both backend passes.

This is task-context delivery at a generated-code boundary, not an exception
raised inside the keyboard IRQ or an arbitrary saved-EIP rewrite. The runtime
uses the compiler cleanup readiness predicate: locks, live waits, I/O ownership,
extra lifetime references, busy/failed cleanup, inboxes and Shift-Escape mode
still defer delivery. Active compiler controls are permitted because the enclosing
input boundary can unwind them. An eligible poll consumes the pending bit before
throwing 'Break', so the nearest HolyC handler can catch it and continue without
a second break at the compiler boundary. If uncaught, input cleanup runs before
the exception reaches the console. Failed input unwind restores pending state
and suppresses outward delivery.

CompilerRuntime 46 retains the poll code for the lifetime of all published JIT
functions. Generated code embeds that stable address. The frontend uses an
internal backend entry with a poll callback and native task-flags offset. The
existing standalone backend service and cross-generated bootstrap code remain
uninstrumented; their function signatures and service-table layout do not change.
The shared backend's added fields are initialized to zero in those paths.

QEMU tests wait for a marker from executing HolyC before sending Ctrl-Alt-C.
They exercise an unconditional infinite while loop, a backward-goto loop, a
do/while loop with a runtime condition, and an
infinite loop inside a HolyC try/catch. These programs do not poll pending state.
The caught case must return 1, ordinary cases must recover to the exception
prompt, the request must be consumed, and later compilation/execution must work.
The previous cooperative and lock-delayed hotkey cases remain in the suite.

Checks occur at generated backward conditional/unconditional branches. Raw inline assembly,
non-returning uninstrumented resident calls and execution with interrupts disabled
are not covered by this mechanism. This does not add scheduling preemption or
complete public Break/message/job/popup semantics. Original DolDoc integration
and edit/execute/save/reboot acceptance remain open.

## Validation

Both x64 rebuild generations pass. Native diagnostics pass BitEquCheck on both
root and worker tasks at the unchanged 512 KiB worker heap limit. Checking every
forward branch as well exceeded that heap limit, so the checkpoints cover
backedges only. The interactive suite passes 153 commands / 216 input lines,
including six real hardware hotkey cases and exact VGA checks. The full native
suite passes, including startup recovery, normal boot with an invalid probe and
all 17 module rejection cases. All 1097 OS source hashes and eight build-input
hashes match, as do both disk hashes. The normal preview is refreshed. The
editing-session acceptance remains open.
