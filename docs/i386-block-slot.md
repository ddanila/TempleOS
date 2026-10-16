# Canonical block-device slot selection

BlkDevNextFreeSlot scans all 26 physical-device records and initializes the first
record whose signature is invalid. It does not set the signature or reserve the
slot. A repeated call therefore returns the same record until the caller publishes
it. Type must match Let2BlkDevType(first_drv_let); exhaustion and mismatches throw
BlkDev. The original stores the supplied letter without normalizing it. An invalid
letter paired with BDT_NULL is accepted by this routine, though BlkDevChk would
reject that record. These behaviors are preserved rather than silently tightened.

The shared fixture has twenty mask-31 cases: all five physical-device types at
slots 0, 13 and 25; exhaustion; mismatched type; invalid letter with BDT_NULL;
lowercase letter; and a negative type. It compares every byte in all 26 records,
checks defaults and unrelated-record preservation, repeats successful selection,
and restores all borrowed records before reporting failure. Heap and caller
folder/document state must remain unchanged.

Both original controls pass all twenty cases with unchanged inputs:

- build/i386-c4-block-slot-reference-scoped/result.json
- build/i386-c4-block-slot-current-scoped/result.json

The original wrapper enters SingleUser only during the table-borrowing interval,
after setup/suspension and before mutation, and restores it before resuming tasks.
This suppresses original AdamLog calls from throw while the physical device table
cannot service logging I/O. Native exceptions do not use that original logger.
The test qualifies exception codes and table cleanup, not Adam exception logging.
Earlier fixture attempts deadlocked by suspending Adam during synchronous logging,
then by enabling SingleUser around setup/file compilation. Those artifacts remain
under the unsuffixed, -live-adam and -quiet directories; they are fixture failures,
not evidence about slot-selection correctness.

The ConsoleRuntime 123 image rejects the native preflight because
BlkDevNextFreeSlot is undefined (build/i386-c4-block-slot-red/result.json), with
unchanged inputs at execution. That preflight predates the final fixture's scoped
logging adjustment; its immutable result pins identify the exact earlier files.

## Implementation candidate

ConsoleRuntime 124 shares the complete original body through BlockDevSlotCore.HC;
only the record expression is adapted to the kernel-owned block table. The
extraction is byte-identical after reversing that expression. Original block-size
constants now live in BlockSize.HH and are visible through native public headers.
There are 306 matching console names/bindings, with a function export and public
prototype for slot selection. Bootstrap and cross-build pass. All 1508 source
and 24 build-input hashes match the candidate; the rebuilt original again
passes all twenty cases after extraction (i386-c4-block-slot-shared-current).
The 8 MiB gate passes all nine checks in 58.009153 seconds with unchanged
execution inputs and no build provider (i386-c4-block-slot-startup). Native slot selection passes all twenty cases/24 commands at 64 MiB,
including canonical backing-device identity and exact fixture delivery, with
unchanged inputs (i386-c4-block-slot-native). The existing block-release suite
also passes all sixteen cases/21 commands with unchanged inputs
(i386-c4-block-slot-release-regression). The full 16 MiB diagnostic gate is still
running separately and is not yet counted as passing.

The API initializes an available record; it does not implement BlkDevInit, mount
allocation, device deletion, or general media lifecycle. Boot and secondary-target
handles still use their established canonical slots. Full mounting must coordinate
record publication and those handle lifetimes. All 686 inventory qualifications
and C1–C5 remain open.
