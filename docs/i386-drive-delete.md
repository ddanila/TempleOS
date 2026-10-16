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
inputs. This run overlapped the diagnostic and C5 guests. The 16 MiB run in
`...drive-delete-diagnostics` has completed boot and remains live for its
interactive checks; its final verdict is pending. All 686 inventory entries and C1-C5 remain
unqualified. The concurrent C5 emitter build remains pinned to 0bed4c3a and its
own immutable disk; it does not qualify this newer Console 121 source epoch.
