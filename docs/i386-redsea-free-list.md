# Original RedSea free-list teardown

The complete original `RedSeaFreeFreeLst` body is shared through
`Kernel/BlkDev/RedSeaFreeFreeListCore.HC`. The complete `CFreeLst` record is
shared through `FreeListTypes.HH`. ConsoleRuntime 120 adds the private kernel
export `RedSeaFreeFreeLst` (301 bindings); callers explicitly declare it.
This is a prerequisite for full original drive/media initialization, not a
replacement implementation of the RedSea allocator or a filesystem qualification.

The 32-case original/native contract covers null lists, empty sentinel queues,
three-node queues, direct and forwarded device locks, no pre-held lock,
device-only ownership, drive/device ownership, and drive ownership with its
device released. Eight additional populated-list cases allocate nodes on the
root task's heap. The fixture suspends the window manager and, when distinct,
the allocation owner while measuring exact heap recovery, restoring their
previous suspension states afterward.

Every case requires mask 63: cleared next pointer, unchanged last pointer,
exact caller and owner heap recovery, original lock/owner state, unchanged
drive/device metadata, and an idempotent second teardown with those invariants.
The original leaves last_free unchanged; tests never dereference that freed
pointer. A device-only outer lock is released when the routine takes and then
releases the drive. A pre-held drive retains its device, including when the
routine must reacquire the device first. These are original observations.

## Fixture and declaration controls

Earlier fixture errors are preserved: `...redsea-free-list-reference` used an
unsupported ternary; `...control-reference` lacked the private extern.
`...extern-reference` and `...current-reference` pass the initial 24 cases.
The first root-owner extension failed exact heap observations while that owner
could run at a Yield. `...owner-reference` and `...owner-current` preserve those
failures. Suspending the separate owner gives 32 masks of 63 on both the pinned
original and extracted original in `build/i386-c4-redsea-free-list-suspended-reference`
and `build/i386-c4-redsea-free-list-suspended-current`, with unchanged inputs.

The missing-binding preflight fails on the prior native image in
`build/i386-c4-redsea-free-list-pinned-red`, with unchanged inputs. The first
Console 120 run, `...redsea-free-list-native`, passes that preflight but rejects
the included fixture's second extern. A diagnostic `...binding-probe` loads the
fixture without the separate preflight, executes case 0 with mask 63, then
rejects a repeated extern. This was initially suspected to be a publication bug.

The independent original control disproves the assumption that repeating this
private extern is supported. `...redsea-free-list-repeat-reference` does not
complete the repeated-declaration fixture. In
`build/i386-c4-redsea-repeat-metadata`, an original-only probe observes flags
0x8000/address 0x27D6B after the first declaration and flags 0x8001/address
0x6EB9FC12 after the second. The second declaration is unresolved. The speculative
native collision relaxation was removed; CompilerRuntime remains 71. The
experimental `...redsea-repeat-cross` image is not a qualified release.
The rebuilt-original repeat run's inputs changed during that reversal, so it
is not an unchanged-input control. The final fixture uses a single extern for
both the compile-only gate and the included behavior, matching original semantics.

## Root-heap measurement control

The single-declaration native run passes cases 0-23 and fails case 24 with
unchanged inputs in `build/i386-c4-redsea-free-list-single-native`. The diagnostic
`...owner-mask` returns 27. `...owner-delta/run` observes unchanged caller heap
usage but root usage rising from 0xC1468 to 0xC14D8 in both cases 24 and 25:
112 bytes. These diagnostic variants are not full contract passes.

The queue diagnostic `...owner-queue/run` confirms the source of the change:
before teardown the caller's waiting queue is empty; afterward it contains a
JOBT_MSG/MSG_KEY_UP job (codes 1/3), character 10, allocation size 112, owned by
adam_task's data heap. The native keyboard worker can allocate that job even
while the root task is suspended. The fixture now allows 100 ms for command
input delivery before suspending the separate owner and taking its baseline. All six assertions and exact heap comparisons
remain unchanged; this does not subtract an allowance from observed heap usage.

## Passing final contract

`build/i386-c4-redsea-free-list-settled-reference` and `...settled-current`
pass all 32 masks on the pinned and rebuilt original. `...settled-native`
passes all 35 commands at 64 MiB on TCG 486,-fpu, including the compile-only gate,
fixture include, 32 cases and arithmetic sentinel. All three reports require
unchanged inputs; the native runner also checks the guest fixture byte for byte.

The final two-generation bootstrap passes in `build/rebuild-test`. The native
image `build/i386-c4-redsea-free-list-cross` passes cross compilation and its
bounded boot instruction audit. `final-source-audit.json` confirms all 1503
source and 24 build-input hashes still match after removing the speculative
compiler change, and byte-for-byte equality of the complete original routine
and record. CompilerRuntime remains 71; ConsoleRuntime is 120.

The full 16 MiB diagnostic regression passes in
`build/i386-c4-redsea-free-list-diagnostics`: 225.687243-second diagnostic
startup, all nine interactive commands, 22 publication and 28 program cases,
and both preserved memory phases (phase 1 retains 16 bytes in 8192 owned bytes).
Its final input audit confirms unchanged execution inputs.

The isolated 8 MiB normal regression passes in
`build/i386-c4-redsea-free-list-startup`: 55.149927-second startup against
the unchanged 60-second budget, all nine commands, exact VGA restoration and
no Build-provider load. Its execution inputs remain unchanged. The shared
routine retains the original trailing blank line; the remaining staged
whitespace check passes with only blank-at-EOF checking disabled.

## Remaining scope

List construction, disk-space accounting, allocation failure, cancellation
inside teardown, interrupted media initialization, full Drv/DirContext behavior,
and application workflows remain open. The inventory's 686 entries remain
unqualified. Full C1-C5 and two native release generations remain open.
