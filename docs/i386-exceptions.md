# Native exception record ownership

This describes record ownership and low-level context primitives for HolyC
try/catch on the 32-bit target. The compiler SysTry entry is available as a bootstrap module. Standalone
FS-bound SysUntry and public throw are implemented; full production boot,
public CTask and debugger integration remain incomplete.
An explicit task dispatcher now connects record ownership to context transfer. Compiler registration lowering and bounded frame traversal
are separate existing prerequisites; context primitives are described below.

`Kernel/I386/Except.HH` defines a 32-byte capture containing EBP, ESP,
EBX, ESI, EDI, EFLAGS and catch/cleanup addresses. A 48-byte record adds
previous-record, task and heap pointers and a signature. The eventual assembly
entry must capture the caller's preserved registers before a HolyC helper can
use them as temporaries. Passing a capture structure does not perform capture.

`I386ExceptPush` accepts the current live task and an explicit heap. It checks
that the frame header fits within registered stack bounds, that ESP is aligned
and lies between the stack base and EBP, and that both handler addresses are
nonzero. It copies the capture and publishes the new top only after allocation
succeeds. Allocation failure leaves the existing chain intact.

`I386ExceptPop` frees the top through its original heap and advances the chain
only on success. Different records may use different heaps. Invalid signatures,
wrong task ownership and allocation-size mismatches reject removal without
changing the chain. A live inactive task cannot have its records removed by
another task; a finished task can be drained before destruction.
`I386ExceptClear` repeatedly removes records, stopping on failure. It may have
removed an earlier prefix when a later record fails validation.

Scheduler initialization and attachment reject records that still own an
exception chain. Reaping rejects a finished task until the chain is empty,
keeping its stack and private heap alive. Records are not automatically cleared
by completion; the owner must drain them before reaping. This is a lifetime
contract for the bootstrap task record, pending full public CTask integration.

These APIs require live readable task, capture, heap and record objects.
Stack bounds do not prove that handler addresses are executable or that a
capture describes a legitimate try frame. Mutations preserve interrupt state
on a single CPU; they do not yield and must not be called from NMI or used for
exception manipulation in hardware interrupt handlers. Heap lifetime must
outlast every record allocated from it.

The dedicated `python3 tools/test-i386.py --except-records` fixture uses
synthetic frame storage and scheduler ownership. It checks nested records,
capture copies, separate heaps and tasks, exhaustion, malformed captures,
rejected removal, finished-task pinning/draining and complete heap reclamation.
It does not exercise actual catches or task switches; the separate `--tasks`
regression covers the changed task layout and ordinary lifecycle.

## Context transfer primitives

`Kernel/I386/ExceptContext.HC` supplies four HolyC assembly entries using
ordinary eight-byte argument slots and callee cleanup:

| Entry | Arguments | Effect |
| --- | --- | --- |
| `i386_except_save` | capture, catch address, cleanup address | Saves the caller's EBP, post-return ESP, EBX/ESI/EDI and EFLAGS before clobbering preserved state; returns normally |
| `i386_except_invoke` | capture | Calls a bare-RET catch block on the invoking stack with captured EBP, EBX/ESI/EDI and flags; restores invoker state on normal catch return |
| `i386_except_resume` | capture | Restores captured EBP, ESP, EBX/ESI/EDI and flags and jumps to cleanup without returning |
| `i386_except_register` | task, heap, catch address, cleanup address, push provider | Captures caller state into temporary stack storage, calls the three-argument record allocator, and returns its record or null |

Offsets within the capture are 0/4 for EBP/ESP, 8/12/16 for EBX/ESI/EDI,
20 for EFLAGS and 24/28 for catch/cleanup addresses. Save's three arguments
occupy 24 bytes, so post-return ESP is entry ESP plus 28. Resume reads every
capture field before abandoning its stack. EAX/ECX/EDX are volatile; FS/GS and
task binding are unchanged. These routines neither validate captures nor manage
record ownership. Callers must supply trusted live captures, valid stack space,
compatible flags and code addresses; the normal HolyC ABI requires DF clear.

`--except-context` checks physical register and arithmetic-flag sentinels,
callee cleanup, invoker preservation even when the catch clobbers registers,
and resumption after abandoning 128 bytes of deeper stack. It also checks a
HolyC caller's captured EBP/ESP and compiler-generated catch blocks accessing
an enclosing 64-bit local. The compiler SysTry module supplies the enclosing frame and labels: one catch
returns to the invoking helper, and another resumes at the compiler's cleanup
label, skipping the remaining try body. Native runtime service binding,
unhandled exceptions and full public CTask integration remain required.
The fixtures compile these entries inside TempleOS into `ExceptContext.t32m`.
The host checks its four code exports and absence of relocations, then embeds
the generated code in the runner at the exported offsets. Only verified trailing
module alignment padding is excluded from the executable instruction audit.
NASM still builds the surrounding bootstrap runner.


## Capture and allocation boundary

`i386_except_register` reserves a 32-byte temporary capture without changing
flags or preserved registers. It records the caller's EBP and the ESP after
its five argument slots have been removed (entry ESP plus 44). It then calls
the supplied provider with task, heap and capture, using the I386ExceptPush ABI.
The provider must copy the capture before returning: the temporary storage
expires when registration returns. The ordinary provider validates the capture
and publishes an owned heap record only on success. A null result leaves the
existing record chain intact.

The context fixture checks physical register and flag sentinels through this
entry, verifies provider argument placement and pointer return normalization,
and registers two real records through native I386ExceptPush. It tests exhaustion
with the existing chain intact and complete heap reclamation after clearing.

This five-argument bootstrap entry is not the two-argument compiler SysTry entry.
The compiler entry is supplied by the SysTry module below. Its environment
services still need production binding to the current task, allocation provider
and heap. Public throw integration remains pending.


## Task-owned dispatch

`I386ExceptDispatch(task, ch, invoke, resume)` stores the full I64 exception
value in the current task's `except_ch` and clears `catch_except`. It validates
each selected record's signature, owner, allocation size and capture bounds
before invoking its catch. A rejected catch has its record popped and dispatch
continues outward. An accepted catch (`task.catch_except=TRUE`) resumes at that
record's compiler cleanup label, retaining the record for SysUntry to remove.
The accepted path abandons the dispatch stack and does not return.

All returned statuses require an explicit caller policy:

| Status | Meaning |
| --- | --- |
| `I386_EXCEPT_UNHANDLED` | No record accepted; rejected records have been removed |
| `I386_EXCEPT_INVALID` | Invalid arguments, record/capture, or task/chain changed incompatibly during the handler |
| `I386_EXCEPT_RESUME_RETURNED` | The supplied resume callback unexpectedly returned; selected record remains owned |

This is a task-context API, not an interrupt or NMI exception handler. It keeps
interrupts available to catch code according to captured flags; only individual
record mutations mask interrupts. A catch may use balanced nested try blocks
and may yield, but must return with the selected record and task still current.
Removal of the selected record before a normal catch return is rejected. The
exception value and acceptance flag are task state, matching the existing
shared-per-task reporting model; recursive throw semantics and debugger/logging
integration still need dedicated work. Task initialization, attachment and
reaping reset these fields.

The context fixture now allocates actual records for compiler-generated tries.
It verifies inner rejection and outer acceptance in one frame and across
function frames, inner acceptance followed by normal outer cleanup, full-width
exception values, unhandled cleanup, corrupt-record rejection, a returning
resume callback, selected-record removal and invalid current-task/callback
arguments. The fixture imports the assembly SysTry provider described below. Full public
throw must route returned
errors to recovery or an unhandled-exception path instead of continuing the try
body. Task switching during catches has not yet been exercised by this fixture.


## Compiler SysTry module

`Kernel/I386/SysTry.HC` builds a position-independent T32M v2 provider exporting
`SysTry(catch_start, untry_start)` with the compiler's two eight-byte argument
slots. Compile its top-level USE32 assembly with CmpI386Module and link it through
the ordinary native module loader. The shared HolyC assembler emits the code;
NASM no longer builds this provider. The module has relative-call imports for
two HolyC services:

- `Bool I386ExceptEnter(CI386ExceptCapture *capture)` copies the temporary capture
  into an owned record and returns true only after successful publication.
- `U0 I386ExceptRegistrationFailed()` transfers to an existing recovery handler
  or terminates; it must not return into the try body.

The entry snapshots EBP, EBX/ESI/EDI and flags before calling HolyC. Its saved
ESP is entry ESP plus 20, after the return address and both argument slots. The
32-byte temporary capture remains live throughout the Enter call. Success
releases that storage and returns with 16-byte callee cleanup. Failure calls
the failure service; if the service erroneously returns, an infinite branch
prevents entry into the unprotected body. This fallback is not a user-facing
unhandled-exception or debugger implementation.

The context fixture now imports this actual SysTry module. It no longer rebuilds
the enclosing frame in a HolyC SysTry wrapper. Its environment services bind to
the explicit test task/heap, and route registration failure through dispatch
with an OutMem value. The FS-bound runtime below supplies the task/allocator services; production boot
still must install runtime callbacks and unhandled-exception policy. Full native
assembler self-hosting remains pending. Other task/interrupt/boot stubs and the
test runner still use NASM.

The linked context suite passes nested/cross-frame propagation with this entry,
allocation failure caught by an outer handler, and early returns from both a
try body and a catch body. Each path checks that exception records and heap
allocations are reclaimed. Executable instruction auditing includes the linked
SysTry module as well as generated HolyC and the context primitives.


## FS-bound public runtime

`ExceptRuntime.HH/HC` supplies the HolyC services imported by SysTry, public
SysUntry and `throw(I64 ch=0, Bool no_log=FALSE)`. These use I386TaskSelf through
FS and allocate records from the current task's `memory` heap. Boot must install
a valid FS task binding, register stack bounds and provide a live heap before
using try/throw. Invalid registration context takes the fatal path; failure to
allocate a record raises OutMem through existing catches with logging suppressed.

`I386ExceptInstall` copies a service table once, rejecting missing callbacks or
a second installation. The required callbacks are catch invocation, nonlocal
resume, reporting and fatal recovery. Install before enabling the runtime; keep
all callback code resident. Table publication preserves interrupt state.

Public throw stores the I64 exception value before reporting, calls the report
hook unless no_log is true, and dispatches through the current task's records.
The report hook must return normally without throwing. A returned dispatch status
is sent to the fatal hook with the task and original exception value. Fatal
may transfer to debugger/recovery code or terminate; if it returns (or services
were never installed), the runtime masks IRQs and stops in a loop. This fallback
prevents continuation after a failed operation; it is not a complete panic UI.
Fatal must also tolerate a null/invalid-context task argument. SysUntry removes
the current record and routes removal failure to fatal recovery.

The dedicated `--except-runtime` fixture runs the actual SysTry module and these
HolyC services under two sequential FS bindings with separate task heaps. It
checks current-task selection, ordinary/default/no_log throws, full I64 exception
values, logging calls, nested cross-frame propagation, OutMem recovery, early
catch return and reclamation. It checks unhandled routing with a test recovery
hook that recreates a cleanup record before resuming a saved frame. This proves
hook routing, not a debugger or panic implementation. Both task profiles share
the runner stack sequentially; the separate task fixture below covers actual
catch-time scheduler switching.

Full public CTask integration, concrete log/debugger hooks, recursive throw
semantics and native assembler/boot integration remain required. The runtime does not provide those by itself.


## Caller diagnostics and task switches

Public throw records its frame address in `except_rbp` and up to eight saved
return addresses in `except_callers` before invoking the report hook. The first
address is the call site of throw; this matches Caller(1) when called inside
throw. Every frame read uses the task's registered stack bounds, and traversal
past an invalid/end frame fills the remaining entries with zero. no_log suppresses
reporting but does not suppress capture. Task initialization, attachment and
reaping clear the diagnostic fields.

These are diagnostic snapshots. The throw frame may no longer be live after
recovery, and its address must not be used as an unwinding context. Actual
restoration continues to use the selected owned exception record.

`--except-tasks` runs two heap-owned workers with separate 8 KiB stacks and
4 KiB private heaps across two creation/destruction cycles. Each worker performs
four rounds of accepted and nested rejected/accepted throws, yielding three
times per round from catch code (48 catch-time yields in total). Tests check
FS binding, local I64 values, exception codes, acceptance flags, live record
identity/counts, caller snapshots, normal completion and full reclamation.
Report-time caller addresses are compared with Caller from the reporting frame.
The sequential-FS public runtime fixture also checks reported caller addresses.

This establishes cooperative catch-time switching for the tested bootstrap
scheduler. Recursive throw behavior, full CTask migration, concrete debugger
and logging UI, production boot integration and native self-hosting remain open.


The context, public-runtime and task-switch fixtures compile SysTry.HC inside
TempleOS and export the generated `SysTry.t32m` alongside their linked test
image. The old NASM source and host generation step have been removed. Top-level
HolyC assembly's exports and REL32 imports are sufficient for this provider;
inline assembly imports and absolute relocations remain separate pending work.
All three suites pass with this generated provider and native instruction audits;
both x86-64 rebuild/reboot generations also pass. These are cross-compiled
component results, not a native compiler self-hosting result.
