# Block-device release independent of mounted drives

The complete original BlkDevsRelease walks all 26 canonical block-device
records. ConsoleRuntime 122 included that loop, but its record adapter found
devices through the drive table and substitutes an empty record for missing
associations. It therefore missed a still-owned physical device when no drive
points to it. The regression below captures that older adapter's incomplete semantics.

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

## Canonical table migration (2026-10-16)

ConsoleRuntime 123 now indexes the kernel-owned 26-record CBlkDev array directly.
Its NativeBlockRecords data export binds through the validated config argument;
all 305 export names and bindings match. CI386Ata borrows a lifetime-stable record
instead of embedding a second identity. Boot and secondary-target handles use
slots 0 and 1, respectively. ATA metadata, channel forwarding and CDrv.bd all
refer to those records. Installation copy and compiler format/create probes use
the persistent secondary-target handle. File services version 59 and compiler
probe version 18 reject stale ABI combinations. Standalone protocol fixtures own
explicit records and bind them before identify.

Eight additional original cases cover every slot, with none/all/even/boundary
ownership patterns, mixed invalid signatures and unlocked records. They check
exact bytes, repeat release, canonical backing-device identity, caller state and
heap accounting, restoring all records before assertion. Both original and
rebuilt-original controls pass all 16 cases with unchanged inputs:

- build/i386-c4-block-table-reference/result.json
- build/i386-c4-block-table-current/result.json

The bootstrap and cross-build pass, with all 1506 source and 24 build-input
hashes matching. ATA and task/ATA regressions pass, including null borrowed-record
rejection, stable re-identify, transfers and ownership/channel behavior. The
8 MiB gate passes nine interactive checks in 54.848084 seconds, with no build
provider and unchanged execution inputs. Evidence is under
build/i386-c4-block-table-{cross,ata,ata-tasks,startup}.

Native release also passes all 16 cases/21 commands at 64 MiB, including both
canonical identity preflights and exact delivery of all three fixture files.
Its execution inputs are unchanged (build/i386-c4-block-table-native/result.json).
RedSea mount/read/allocation/delete/replace/load/low-memory-load/load-set/bind
all pass (build/i386-c4-block-table-redsea-results.json). Installation/format and
full diagnostics are being validated separately.

The first format harness run selected the old fixed 8 MiB guest profile and
exhausted memory in ModuleCheck.HC before reaching the format probe. The harness
now explicitly selects 16 MiB for this full diagnostic workflow. The first
installation-copy attempt stopped at the boot checksum marker because its old
harness patched flags without refreshing the extended checksum; all three flag
patches now refresh it. Failed artifacts are retained under
build/i386-c4-block-table-target and
build/i386-c4-block-table-install-copy-checksum-red. These harness-only changes
postdate the cross-build; pre-harness-fix-audit.json records matching build inputs
before those edits. Production source hashes remain unchanged.

Standalone RedSea write returns case 3: its old fixture expects resident-bit
records to be rejected, but the unchanged write implementation has permitted
them since a4193484. Creation returns combined case 2. Splitting its assertions without changing
expectations isolates return 28: the full-directory case expects failure despite
the existing directory-growth implementation. Likewise, write return 33 isolates
its resident-attribute case. The isolated artifacts have a -isolated suffix.
These failures remain open, preserved under build/i386-c4-block-table-redsea-write
and -redsea-create; they are not counted as passes or silently weakened.
The fixed boot/secondary-target topology does not implement general mount-slot
allocation, BlkDevInit or the remaining media lifecycle. All 686 inventory entries
and C1–C5 remain unqualified/open.
