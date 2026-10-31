# Conventional-memory arena selection

`I386BootMapLowArena` selects an eight-byte-aligned conventional-memory gap
only where the complete firmware map identifies ordinary usable RAM. It clips
to the BIOS conventional-memory and EBDA bounds, starts after the loader's
reported stage end, subtracts caller reservations and all non-usable or
nonvolatile map overlaps, and chooses the lower address for equal-sized gaps.
Malformed metadata and empty results are rejected without changing the output.
The existing high-memory selector shares the same range-selection routine and
keeps its previous limits. No native allocator currently uses the low result.

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

Using such a region requires an explicit low-memory lifetime/reservation audit,
a separate allocator and task ownership/cleanup integration, plus fallback,
concurrency and failure tests. The selector and capture do not make the failed
8 MiB InFile workload pass and do not qualify C1–C5. See
[InFile evidence](i386-infile.md).
