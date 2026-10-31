# Conventional-memory arena selection

`I386BootMapLowArena` selects an eight-byte-aligned conventional-memory gap
only where the complete firmware map identifies ordinary usable RAM. It clips
to the BIOS conventional-memory and EBDA bounds, starts after the loader's
reported stage end, subtracts caller reservations and all non-usable or
nonvolatile map overlaps, and chooses the lower address for equal-sized gaps.
Malformed metadata and empty results are rejected without changing the output.
The existing high-memory selector shares the same range-selection routine and
keeps its previous limits. The initial selector checkpoint did not allocate
from the low result; the later integration is described below.

The boot-memory fixture checks reserved and unusable overlaps, malformed maps,
disabled/nonvolatile entries, unaligned and invalid reservations, EBDA bounds,
and ties, together with the existing high-memory cases. Both bootstrap rebuild
generations pass (`build/i386-low-arena-rebuild-v1.log`), the protected-mode
memory fixture and instruction audit pass (`build/i386-low-arena-test-v2.log`),
and minimal and full-content cross-builds pass with 386 audits
(`build/i386-low-arena-cross-v1`, `build/i386-low-arena-full-cross-v1`). The
initial test without an implementation failed compilation
(`build/i386-low-arena-test-red-v2.log`). The 8 MiB smoke completed all nine
interactive/VGA checks but missed the 60-second startup gate at 66.7 seconds
while another guest was active (`build/i386-low-arena-smoke-v1`). The 16 MiB
startup diagnostic also passes (`build/i386-low-arena-diagnostics-v1`).

`tools/profile-i386-infile-heap.py` packages the same InFile fixture and saves
8 MiB of guest memory after observing allocation failure. The successful
capture has unchanged inputs (`build/i386-infile-heap-8m-v2`); the first
attempt lost keyboard input before the workload and is not heap evidence
(`build/i386-infile-heap-8m-v1`). The QMP stop occurred after exception unwind,
so the captured heap counters must not be substituted for the earlier failure
log. `tools/analyze-i386-infile-heap.py` independently verifies the captured
heap's public and owned region chains against raw allocation records, then
checks firmware geometry (`build/i386-infile-heap-8m-v2/backing-audit-v3.json`).
It finds 13 owned regions, all with live pages: 889,856 bytes allocated and
876,032 used, with no unheld empty region to reclaim. It also finds a 487,424-
byte firmware-described conventional candidate at `0x11000` after excluding the
reported stage and boot stack. This is a map geometry observation, not proof
that no other live loader, firmware or device use overlaps that range.

The selector and capture alone did not make the failed 8 MiB InFile workload
pass. The subsequent task-arena integration and its remaining limits are
described below; C1–C5 remain open. See
[InFile evidence](i386-infile.md).

## Auxiliary task arena integration (2026-10-31)

On the compact extended-loader path, the kernel now initializes a separate
task arena only when a complete firmware map identifies a conventional range
that does not overlap the main heap or the stage/boot-stack reservations.
The loader's real-mode bounce buffer at `0x6000`, real-mode stack at `0x9000`,
handoff records below `0x6000`, and resident stage at `0x10000..0x11000` are
outside the selected range; at this checkpoint the protected-mode boot stack
at `0x88000..0x90000` was explicitly reserved. A later verified placement is
described below. Kernel module linking's legacy
`0x11000` load address describes relocation of a generated file, not a live
write into that address. This source review and the tests below are not a
claim about all firmware implementations.

MemoryRuntime 37 passes the optional arena to a new task constructor. Under
masked interrupts it validates both heaps and their non-overlap, prefers the
main arena when a suitable block exists, and uses the auxiliary arena only
when it does not. The task and its cloned controls are owned by the selected
arena; later clone failures roll back without retrying. The existing
single-arena constructor retains its ABI and behavior. Native task, inherited
heap, file/symbol, and retained-lifecycle fixtures pass, covering corrupt or
overlapping controls, exhaustion, preferred selection, fallback, task
retirement, and failed-clone rollback (`build/i386-low-task-tasks-v1.log`,
`build/i386-low-task-heaps-v1.log`, `build/i386-low-task-symbols-v3.log`,
`build/i386-low-task-retained-v1.log`). Both bootstrap generations and the
minimal/full cross-builds with 386 audits pass
(`build/i386-low-task-rebuild-v2.log`, `build/i386-low-task-cross-v2`,
`build/i386-low-task-full-cross-v1`).

The boot-map handoff fixture passes with a complete map and confirms the
auxiliary arena is present; a forced-unavailable map also boots through the
legacy high-memory path and confirms it is absent, with unchanged inputs
(`build/i386-low-task-map-selected-v1`,
`build/i386-low-task-map-unavailable-v1`). The original 8 MiB InFile failure
now passes the same contract with unchanged inputs; an additional check shows
both queued input tasks execute in the selected low range and reuse the same
slot after retirement (`build/i386-low-task-infile-8m-v2`). Its observed startup
was 66.9 seconds with another guest active, so it does not pass the 60-second
startup gate. The 16 MiB startup diagnostic passes
(`build/i386-low-task-diagnostics-v1`). Public messaging and task cancellation regressions also pass at 64 MiB
(`build/i386-low-task-messages-v4`, 19 cases;
`build/i386-low-task-kill-v4`, 9 cases), with unchanged source images and
matching VGA checkpoints. Their include-based fixture mode avoids typing long
definitions and clears the transcript periodically; it adds cooperative
yields and does not independently establish low-arena behavior. Earlier runs
timed out while typing long definitions or matching a scrolled transcript.
This does not establish arbitrary concurrent task capacity or complete C1–C5
qualification.

An isolated 8 MiB startup run passed all nine interactive behavior and VGA
checks, but took 63.500 seconds and therefore failed the 60-second gate
(`build/i386-low-task-startup-isolated-v1/result.json`).

## Popup allocation and task-tail reclamation (2026-10-31)

`tools/profile-i386-popup-file-heap.py` captures the actual 8 MiB popup
failure on the Console 181 image, with unchanged inputs
(`build/i386-popup-file-heap-v1`). The log identifies task creation as the
failed allocation. QMP stopped the guest after failure handling had started,
inside public-memory reclamation, so these are not the exact allocator-failure
counters: the main arena then had 201,936 bytes free in total and a 149,088
byte largest free block. The independently checked public backing chains
contained 15 live regions and no wholly unused, unheld region
(`build/i386-popup-file-heap-v1/backing-audit.json`). The captured firmware map
ends conventional usable memory at `0x9fc00`; the live protected-mode boot
stack still occupies `0x88000..0x90000`. The map alone does not authorize moving
that stack or using its reservation.

Task creation now shrinks its owned allocation to the actual end of the
page-rounded stack and private-heap extent after alignment. It keeps the full
requested stack, its page isolation, all private storage and normal ownership;
only unused trailing alignment slack is returned. An added task fixture checks
the allocation's exact retained size and fails on the prior implementation
(`build/i386-task-tail-test-red-v1.log`). The native task, inherited heap and
symbol, retained-core and heap tests pass, as do both bootstrap generations
the full cross-build/386 audit and the 16 MiB diagnostic (`build/i386-task-tail-tasks-v1.log`,
`build/i386-task-tail-heaps-v1.log`, `build/i386-task-tail-symbols-v1.log`,
`build/i386-task-tail-retained-v1.log`, `build/i386-task-tail-heap-v1.log`,
`build/i386-task-tail-rebuild-v1.log`, `build/i386-task-tail-full-cross-v1`,
`build/i386-task-tail-diagnostics-v1`).
The 8 MiB InFile contract, including low-slot reuse, remains passing with
unchanged inputs (`build/i386-task-tail-infile-8m-v1`). The 64 MiB popup
contract also remains passing (`build/i386-task-tail-popup-64m-v1`).

The 8 MiB popup contract still fails `OutMem` with unchanged inputs
(`build/i386-task-tail-popup-8m-v1`). The low arena's logged used count falls
from 276,016 to 274,712 bytes and its largest free block rises from 210,608 to
211,912 bytes, a 1,304-byte recovery in this workload; the next requested task
still needs 267,527 bytes. The runs overlapped other guests and are not timing
qualification. Further capacity work must retain the full task stack and
firmware reservations. C1–C5 remain open.

## Firmware-verified root-stack placement (2026-10-31)

The extended loader can now place its unchanged 32 KiB protected-mode root
stack at the top of verified conventional RAM. It requires a complete E820
map, a single volatile usable entry covering the entire candidate, no
conflicting overlapping entry, no overflow in any map entry, and bounds below
both the conventional-memory and EBDA limits. If the check fails it retains
the established `0x88000..0x90000` stack. Only after the selector returns does
the loader switch stacks and call the kernel. A separate handoff records the
chosen base; the kernel independently checks the exact interval against the
map and its current stack pointer before reserving it. The non-extended path
retains the legacy reservation. This changes neither task stack sizes nor the
requirement to exclude firmware and live stack memory.

On the captured QEMU firmware map, the verified stack is
`0x97c00..0x9fc00`; the task arena grows from 487,424 to 551,936 bytes. The
normal and forced-unavailable map boots pass with unchanged inputs
(`build/i386-high-stack-map-normal-v1`,
`build/i386-high-stack-compact-map-unavailable-v1`). Injected overlapping
reserved, uncovered, overflowing, and nonvolatile map entries all keep the
legacy stack (`build/i386-high-stack-map-conflict-v1`,
`build/i386-high-stack-map-uncovered-v1`,
`build/i386-high-stack-map-overflow-v1`,
`build/i386-high-stack-map-nonvolatile-v1`). The kernel rejects a forged stack
handoff before boot continues (`build/i386-high-stack-compact-map-forged-v1`).
These are emulated and injected maps, not a claim about every firmware.

The first candidate boot hit its early fault handler because the selector
clobbered the kernel-entry register; restoring that register fixed boot
(`build/i386-high-stack-popup-8m-v1`, interrupted after the fault). The first
two cross-builds also stopped at the 386 instruction audit because its
mnemonic whitelist omitted `adc` and the `jna` alias for `jbe`; the gate and
its mutation test now cover those 386 encodings. Both bootstrap generations
and the compact full cross-build/386 audit pass
(`build/i386-high-stack-compact-rebuild-v2.log`,
`build/i386-high-stack-compact-cross-v1`). The compact validator retains the
same checks and reduces the flat kernel by 1,128 bytes relative to the first
working C validator.

The expanded arena gets the 8 MiB `PopUpFile` workload past its earlier task
allocation, but the case remains failed: it next requests a 153,600-byte
terminal graphics buffer while the main arena's largest free block is 151,648
bytes (`build/i386-high-stack-compact-popup-8m-v1`). A stopped capture of the
preceding candidate identifies a partially used 8 KiB public backing region
between a 28,144-byte free block and the 151,664-byte free block
(`build/i386-high-stack-popup-heap-v1` and its `backing-audit.json`). The stop
occurred after failure handling began; its counters are not a replacement for
the failure log. Reclaiming live pages or assuming a firmware map is safe is
not justified by this observation. The popup, timing gate and C1–C5 remain
open.

The compact image passes the 8 MiB InFile low-slot contract, the 64 MiB
popup contract, and the 16 MiB diagnostic with unchanged inputs
(`build/i386-high-stack-compact-infile-v1`,
`build/i386-high-stack-compact-popup-64m-v1`,
`build/i386-high-stack-compact-diagnostics-v1`). An isolated 8 MiB startup
run passes all nine behavior and VGA checks but takes 65.861 seconds, above
the unchanged 60-second gate (`build/i386-high-stack-compact-startup-v1`).
