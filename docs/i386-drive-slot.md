# Original drive-slot preparation and letter selection

DrvMakeFreeSlot resolves the supplied drive letter, clears that canonical CDrv
record, and writes its uppercase letter. It neither frees the record's previous
resources nor publishes a valid signature. Teardown must precede repurposing a
live record; this API is not a substitute for DrvDel.

DrvNextFreeLet scans from the requested letter (default C), returning the first
invalid-signature record only if its letter belongs to the same block-device
class. It throws Drv on invalid letters, crossing a device-class boundary into a
free slot, or exhaustion. It does not mutate or reserve a slot.

The 42-case shared fixture covers both edges of every letter class, lowercase,
current/boot/home aliases, invalid letters, first/last free letters within each
class, a free slot only in the next class, exhaustion, the default argument,
repeat behavior, exact preservation of all 26 records, heap balance and caller
folder/document state. Records are restored before assertion. The original
wrapper suppresses Adam exception logging only while borrowing the drive table,
using the same scoped SingleUser isolation as the block-slot oracle.

The initial controls exposed two mistaken fixture expectations: after clearing
the current drive through letter 0, repeating that alias throws because the
current signature is invalid; searching through letter 0 also requires a valid
current record. The corrected test keeps that record valid during search and
checks the repeated-clear exception. The failed initial artifacts remain in
build/i386-c4-drive-slot-{reference,current}. Both corrected original controls
pass all 42 mask-31 cases with unchanged inputs:

- build/i386-c4-drive-slot-reference-alias/result.json
- build/i386-c4-drive-slot-current-alias/result.json

ConsoleRuntime 124 rejects the native preflight as undefined, before table
mutation (build/i386-c4-drive-slot-red/result.json). Its result pins the earlier
fixture before the alias-expectation correction; it is evidence of missing API
exposure, not a behavioral run of those cases.

## Implementation candidate

ConsoleRuntime 125 shares both complete original bodies through DriveSlotCore.HC.
Only the canonical record and signature expressions are adapted. The console has
308 matching export names/bindings and public declarations, including the original
default argument. Bootstrap and cross-build pass with 1509 source and 24
build-input hashes matching. The rebuilt original again passes all 42 cases after
extraction (build/i386-c4-drive-slot-shared-current). Native behavior passes all
42 cases/46 commands at 64 MiB, including canonical drive identity and exact
fixture delivery (i386-c4-drive-slot-native). The 56-case drive-deletion and
20-case block-slot regressions also pass (i386-c4-drive-slot-delete-regression
and -block-regression). All three runs preserve their execution inputs. The memory-gate coordinator waits for other guests before isolating
8 MiB startup, then runs 16 MiB diagnostics; its live state is recorded in
build/i386-c4-drive-slot-gates.json. The queued gates use an isolated snapshot of the committed source so subsequent
work cannot invalidate their source checks. Pending gates are not counted as passes.

These routines prepare records and choose letters. They do not supply the full
mount allocator, mapping, FAT initialization, media initialization or resource
teardown. All 686 inventory entries and C1–C5 remain unqualified/open.

The queued 8 MiB gate subsequently passes all nine checks in 58.410043 seconds,
with no build provider and all four execution pins unchanged
(build/i386-c4-drive-slot-startup). C5 resumed afterward; the separate 16 MiB
diagnostic gate is now running against the isolated f038f05e source snapshot.
