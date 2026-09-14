# Native exception record ownership

This is a runtime prerequisite for HolyC try/catch on the 32-bit target.
It does not implement SysTry, SysUntry, throw, catch execution, propagation,
or nonlocal register/stack restoration. Compiler registration lowering and
bounded frame traversal are separate existing prerequisites.

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
