# Owned document text capacity

The canonical transcript checkpoint introduced an 8 MiB background compile/edit
regression. A host-only QMP snapshot stops at the first raw heap failure without
changing guest code. Its capture/inspection scripts and hashes are preserved in
`build/i386-c2-background-pressure`. All five detected live task heaps have no
wholly free page blocks to return; spare space is fragmented within live heaps.
This rules out simply trimming empty heaps as a recovery for that observation.

The main console heap has 36,352 allocated bytes and 26,632 used bytes in that
snapshot. The observed background and foreground heaps respectively have
41,984/40,760 and 8,704/3,408 allocated/used bytes. These are observations at the
captured failure, not final requirements or a proof that cache reclamation
alone would fix the workload.

## Edit behavior and safety

The ordinary-text edit core formerly allocated and copied a new tag on every
character insertion. It now reuses owned ordinary tag capacity when it contains
room for the added character and NUL. Backwards shifting preserves middle
insertion. Full buffers still allocate before publication; an allocation failure
leaves the old tag intact. Contents, cursor updates and document ownership are
preserved. Buffer pointer identity can remain stable for more edits, and the
reserved capacity can remain larger after deletion/reinsertion; size queries
still report the actual allocation.

Aligned pointers require a conservative path. Original `_MSIZE` in
`Kernel/Mem/MAllocFree.HC` and the native memory service both report the base
object's capacity. That cannot establish writable bytes after an interior
aligned pointer. The edit core checks the canonical negative size marker and
copies aligned tags instead of reusing their apparent spare capacity. It does
not change public MSize or aligned-allocation semantics.

The allocation-failure probe now fills a tag to its actual four-byte capacity
(`abc` plus NUL) before injecting the growth failure. It still verifies unchanged
text, lock release and heap accounting, and successful subsequent growth/save.
It does not require an allocation when owned spare space already exists.
Console interface version is 72.

## Test-first evidence

`tools/test-i386-doc-capacity.py` requires append reuse, safe overlapping middle
insertion, full-buffer growth, conservative aligned-tag copying and the existing
thirteen allocation/unwind checks. The initial candidate rejects append reuse
in `build/i386-c2-doc-capacity-red-v2/result.json`. A preliminary implementation
passes the ordinary cases but fails the aligned-pointer test in
`build/i386-c2-doc-aligned-red/result.json`; the guard is added before committing.
The first oversized test command was rejected by the harness's 255-byte limit
and is not the behavioral baseline.

The preliminary ordinary-capacity candidate does **not** restore the background
workflow at 8 MiB (`build/i386-c2-doc-capacity-checks/result.json`); its startup
and transcript checks pass, but the concurrency stage still reports OutMem.
No history or graphics is removed, and the legacy test remains enabled.

## Next architectural work

Allocation churn is only part of the resident-memory problem. Export-boundary
inspection finds 52,279 bytes of code in nine allocation/round-trip diagnostic
routines, including DocAllocationCheck, permanently resident in the console.
The report is `build/i386-c2-background-pressure/diagnostic-footprint.json`.
It excludes strings/data and operational dependencies, so it is a list of
separation candidates rather than a verified removable-byte count.

Review moving diagnostic routines into explicitly loaded test support, retaining
fault hooks and all existing assertions. Prove that normal images still exercise
the operational APIs, test support is absent until requested and unload/recovery
returns its resources. Include diagnostic support in native build/install
manifests and successive-generation tests rather than silently omitting it.
This follows the existing normal/diagnostic boot separation and preserves the
original desktop/API scope; it is not implemented or qualified here.

## Guarded candidate verification

The guarded source bootstraps/rebuilds twice and passes the cross-build and 386
loader audits in `build/i386-c2-doc-capacity-safe-cross`. All eleven capacity
commands pass, including aligned copying and the thirteen-case allocation
probe (`build/i386-c2-doc-capacity-final-checks/capacity-64m/result.json`).
The existing document group passes all 33 commands, and all thirteen transcript
commands pass at 64 MiB. Input preservation is recorded in their reports.

The nine-command 8 MiB startup gate passes in 43.7029 seconds with no build-only
provider loads. Background compile/edit/save passes at 64 MiB, with persisted
`work\x05`, continued compilation, exact VGA and parent heap recovery. The
8 MiB concurrency regression remains open; these positive gates do not override
its failure or qualify C1–C5.

The final aggregate `build/i386-c2-doc-capacity-final-checks/result.json` reports
failure solely because its 8 MiB background stage still fails. All five other
stages pass. The guarded candidate preserves the captured OutMem and timeout
in `background-8m/result.json`; it is not a restored concurrency qualification.
Future diagnostic separation remains planned, not an implemented memory fix.
