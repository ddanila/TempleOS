# Block-device release independent of mounted drives

The complete original BlkDevsRelease walks all 26 canonical block-device
records. ConsoleRuntime 122 includes that loop, but its record adapter finds
devices through the drive table and substitutes an empty record for missing
associations. It therefore misses a still-owned physical device when no drive
points to it. The adapter does not yet establish the original routine's full
semantics.

The shared eight-case oracle borrows the caller's actual backing device (following
its lock-forwarding chain), saves all drive records, and optionally removes every
drive association. It covers an owned valid device, an unowned locked device,
an invalid-signature record and a device owned by another task, both with and
without drive associations. It checks the exact resulting device bytes,
preservation of every drive record, repeated release, caller heap accounting,
and caller directory/document identity. It restores the complete device and
drive records before returning or reporting an assertion failure. Root and
window-manager tasks are suspended while records are borrowed.

All eight mask-31 cases pass on the pinned original and the current rebuilt
original, with unchanged inputs:

- build/i386-c4-block-release-reference/result.json
- build/i386-c4-block-release-current/result.json

The native runner first verifies that its table adapter addresses the actual
current drive. On fe838d81's image it passes cases 0–3 and fails case 4, the owned
valid device after all drive associations are removed. No later behavioral case
runs. The fixture restores the records before BRCheck throws. Evidence:
build/i386-c4-block-release-red/result.json, with unchanged inputs.

## Required representation change

Replace drive-based device enumeration with a canonical 26-record CBlkDev table.
The kernel must own its lifetime and pass it through console configuration;
BlkDevsRelease must index that array directly. The initialization-order regression
from device-wide deletion also applies to any new data export.

CI386Ata currently embeds its public CBlkDev, so merely adding another array
would duplicate identity. Move public-record ownership out of the ATA protocol
record and make ATA transactions, channel forwarding and mounted-drive records
refer to the same canonical device. Preserve stable identity on re-identify,
metadata rejection without mutation, lock forwarding, last-write flags and
unmounted-device ownership. Boot, secondary-target mounting, installation/copy,
format probes and standalone ATA/RedSea test callers all need explicit record
lifetime review. Do not silently retain a mounted-drive-only path or a dummy
record as the production representation.

Before qualifying that migration, extend coverage to all table slots and
unrelated records, then run ATA decode/transfer/task exclusion, mounted identity,
owner cancellation, installation/target workflows and the minimal/full diagnostic
memory gates. The bounded orphan oracle alone does not qualify the whole physical
device/media lifecycle. C1–C5 remain open.
