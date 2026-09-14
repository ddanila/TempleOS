# Native exception record ownership

This describes record ownership and low-level context primitives for HolyC
try/catch on the 32-bit target. Production SysTry, SysUntry, throw and propagation
are not implemented. Compiler registration lowering and bounded frame traversal
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

`Kernel/I386/ExceptContext.asm` supplies four bootstrap assembly entries using
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
an enclosing 64-bit local. Fixture-only SysTry registration supplies the enclosing
frame and labels: one catch returns to the invoking helper, and another resumes
at the compiler's cleanup label, skipping the remaining try body.

That fixture registration is not a production SysTry implementation: it does
not capture the enclosing function's full preserved-register state or allocate
records. Native runtime entry, nested task-owned dispatch and propagation,
allocation-failure policy, unhandled exceptions and full public CTask integration
remain required. NASM remains a bootstrap tool pending native assembler support.


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
The latter still needs native binding to the current task, allocation provider
and heap, together with an allocation-failure path that cannot silently enter
an unprotected try body. Production throw dispatch and propagation remain pending.
