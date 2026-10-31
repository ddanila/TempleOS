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
outside the selected range; the protected-mode boot stack at
`0x88000..0x90000` is explicitly reserved. Kernel module linking's legacy
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
(`build/i386-low-task-diagnostics-v1`). Public task cancellation and message
regressions remain in progress on the candidate. This does not establish
arbitrary concurrent task capacity or complete C1–C5 qualification.
