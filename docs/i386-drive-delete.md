# Complete original drive deletion

ConsoleRuntime 121 exposes the original public DrvDel through `_DRV_DEL`.
Its complete body is shared in `Kernel/BlkDev/DriveDeleteCore.HC`. It conditionally
tears down a RedSea free list, frees both FAT buffers, and clears the entire
CDrv record. The seven original filesystem-type constants are shared in
`FileSystemTypes.HH`; their values and comments are unchanged. No branch is
replaced with a native shortcut. The extraction audit accounts for all 302
Console export names and bindings in `build/i386-drive-delete-extraction.json`.

This is a dependency of full drive/device teardown and media initialization.
It does not implement the global drive-table walk, full BlkDevInit/ATAInit,
mounting/remapping or the complete Drv/DirContext workflow.

## Original contract

The 48 cases cover null, empty-sentinel and populated RedSea lists; absent or
present FAT/info buffers; direct and forwarded devices; no pre-held lock,
device-only ownership, drive/device ownership and a drive whose device was
released. Eight populated RedSea cases allocate all resources on the root heap.
Sixteen more cases exercise populated FAT32 and untyped drive records, whose
list nodes DrvDel intentionally leaves allocated. The fixture records that
remaining allocation before adding buffers, verifies node contents and owner,
and frees those nodes separately after observing the original behavior.

Each result must be 63: the complete drive record is zero; adjacent canaries
are intact; caller/owner heaps have the exact expected usage; device locks,
owners and unrelated flags match the original; a second deletion preserves
the cleared record and expected state; and explicit cleanup restores both
heap baselines. Root-owner cases allow command input to settle before suspending
the owner, as established by the free-list queue diagnostic. Suspension states
are restored after the measurement.

A pre-held drive can leave its device locked even though DrvDel clears the
drive's own lock/owner fields. With a null RedSea list, DrvDel does not acquire
or release either lock. These original observations are preserved rather than
normalizing every branch to a single locking policy.

## Evidence and fixture correction

`build/i386-c4-drive-delete-reference` times out because the initial fixture
redeclares DrvDel, which is already public in KernelC.HH. As in the prior private
extern investigation, redeclaration creates an unresolved header. The corrected
fixture uses the existing declaration. `...drive-delete-public-reference` passes
all 48 cases, and the extracted original passes in `...current-reference`.
The reference runner was then tightened to return failure if its final input
hash check fails, and both original controls were rerun with that final runner.

The corrected public-call preflight fails on the preceding native image in
`build/i386-c4-drive-delete-public-red`, with unchanged inputs and one undefined
identifier error. No behavioral case runs there. The earlier explicit-extern
native failure in `...drive-delete-red` is retained as diagnostic history.

The two-generation bootstrap and `build/i386-c4-drive-delete-cross` pass,
including the bounded boot instruction audit and unchanged 1505 source/24
build-input hashes. Both final original controls pass all 48 cases in
`...drive-delete-final-reference` and `...drive-delete-final-current`, with
unchanged inputs. The native fixture passes all 48 cases/51 commands at 64 MiB
on TCG 486,-fpu in `...drive-delete-native`, with unchanged inputs and a
byte-identical delivered fixture. The standard 8 MiB regression passes in
`build/i386-c4-drive-delete-startup`: 57.193246-second startup, all nine
commands, exact VGA restoration, no Build provider and unchanged execution
inputs. This run overlapped the diagnostic and C5 guests. The full 16 MiB run in
`...drive-delete-diagnostics` passes: 237.380647-second boot, both preserved
memory phases, 22 publication/28 program cases and all nine interactive checks.
Its execution inputs remain unchanged. All 686 inventory entries and C1-C5 remain
unqualified. The concurrent C5 emitter build remains pinned to 0bed4c3a and its
own immutable disk; it does not qualify this newer Console 121 source epoch.


## Preserve deletion of mounted identities

FileRuntime 58 separates first publication of each of the 26 canonical drive
records from ordinary lookup. The volume table retains an initialized-drive
bitmap outside CDrv, so the complete original DrvDel can clear every byte of
CDrv without making the next lookup treat it as an unpublished mount.
Task initialization, inheritance and directory changes use the same getter;
explicit I386TaskFilesDriveInit retains physical-volume/device validation and
publication. The bitmap does not implement media remount or full Drv behavior.

Eight additional cases temporarily delete the actual current or boot drive
record, preserving its owned allocations for exact restoration. Uppercase and
lowercase Let2Drv and Let2BlkDev calls with exceptions disabled must reject the
record and leave it entirely zero. Each case then restores every byte and checks
pointer identity, caller directory/document state and exact caller heap use.
The original and rebuilt-original controls pass all 56 cases with unchanged
inputs in build/i386-c4-drive-identity-reference and
build/i386-c4-drive-identity-current.

The initial native mapped-deletion baseline fails case 48 after all preceding
48 cases pass in build/i386-c4-drive-delete-mapped-red. The diagnostic
...drive-delete-mapped-mask observes mask 57 instead of 63: lookup accepts the
record and republishes it. Both runs preserve their input hashes.
Two original exception-throwing fixture attempts are retained in
...drive-delete-mapped-reference and ...drive-delete-mapped-log-reference.
They time out at case 51: exception logging reaches prompt/directory formatting
while the current drive is deleted, recursively throwing Drv. Keeping Adam
runnable does not fix that invalid logging context. The final fixture tests
non-throwing lookups; it makes no claim about exceptions in that context.

The ATA/task fixture separately verifies that an ordinary getter preserves a
cleared published identity, while explicit initialization still rejects and
recovers a damaged physical device signature. Bootstrap and cross-build pass, with all 1505 source and 24 build-input hashes
unchanged. The final 56-case fixture fails case 48 on the preceding image in
build/i386-c4-drive-identity-red, then passes all 56 cases/59 commands on the
new image in ...drive-identity-native. Both runs retain unchanged inputs; the
passing run also verifies the delivered fixture byte for byte.

The ATA fixture initially omitted the new internal initializer's forward
extern; the compiler failure is preserved in ...drive-identity-ata-extern-red.
After that correction, a compound staged-worker assertion failed (51).
Splitting its conditions reproduced failure 106: the worker was unfinished
after 100 cooperative yields. The identical split fixture also passed twice.
These runs are preserved as ...drive-identity-ata-stage-red,
...drive-identity-ata-wait-red, ...drive-identity-ata-split-pass and
...drive-identity-ata-repeat-pass. As in the existing publication-worker test,
the staged-worker wait now permits at most 1000 yields. Its completion,
retained stage, destruction and exact heap checks are unchanged. The final
ATA/task run passes in build/i386-c4-drive-identity-ata-final, including the
protected-mode instruction audit.

The first 8 MiB run passes all nine functional/VGA checks but fails the
60-second startup gate at 65.422216 seconds with several guests active.
That failure is preserved in ...drive-identity-startup. A lighter-load repeat
also passes the functional checks but misses the timing gate at 61.517815
seconds in ...drive-identity-startup-repeat. With the C5 build briefly paused,
...drive-identity-startup-c5-paused passes at 56.482688 seconds, all nine
checks and exact VGA restoration, with unchanged execution inputs and no Build
provider. The 16 MiB diagnostic guest remained active, so this is not an
isolated timing measurement. The recorded pause wrapper resumed both C5
processes afterward; neither was restarted.
The full 16 MiB regression passes in ...drive-identity-diagnostics: both
preserved memory phases, 22 publication/28 program cases and all nine
interactive checks, with unchanged execution inputs.
These bounded results do not qualify the complete filesystem lifecycle.
