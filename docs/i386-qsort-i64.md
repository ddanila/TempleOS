# QSortI64 dependency

The unchanged Budget loader next reaches `QSortI64` in `BgtStrs.HC`. Its
original implementation is shared through `Kernel/QSortI64Core.HC` and
exported by MemoryRuntime 33. The native build substitutes a regular I64 swap
for the original swap intrinsic, preserving the sort algorithm and comparator
call order. This service sorts I64 values (including pointer values passed to
comparators); the separate arbitrary-width `QSort` service is not included.

The pinned original passes six checks for empty and singleton inputs,
ascending and descending comparisons, duplicate values and string pointer
callbacks (`build/i386-qsort-i64-reference`). Both original rebuild generations
pass (`build/rebuild-test`), as do the native cross-build and 386 boot audit
(`build/i386-qsort-i64-cross-v3`). The first cross-build failed on an
unsupported, unnecessary `#undef`; that directive was removed. The intermediate
retry was stopped by the build's changed-source guard, then the bootstrap was
rerun. The native 64 MiB sort contract passes all six checks and continuation input
with unchanged inputs (`build/i386-qsort-i64-native-64m`). The concurrent run
does not qualify startup timing. The unchanged Budget load proceeds through
`BgtStrs.HC` and fails at the `PopUpOk` call in `BgtMain.HC` line 50
(`build/i386-budget-native-load-v3`); Install has not run.
These focused checks do not qualify Budget or any C1–C5 milestone.

## Budget pointer-array width mismatch (2026-11-06)

The installed-template storage comparison exposed an application-side width
assumption. BgtStrs.HC allocated `cnt*sizeof(CHashGeneric *)`, populated a
pointer array and passed it to QSortI64. This is an eight-byte array on the
original x64 system but a four-byte array on i386; the public sort correctly
continues to read and write eight-byte values. The earlier sort contract used
an I64 array for its string pointers and therefore did not cover this mismatch.

The failed native storage run is preserved in
build/i386-budget-storage-installed-native-v1. The 48-byte transaction record
matches the original exactly, but the decoded string table is 241 bytes of
corrupted indices/empty names instead of the original 106 bytes. Reopening
then requests an implausibly large allocation and raises OutMem. A separate
run in build/i386-budget-storage-isolate-v1 confirms that path setup and
BgtAcctsRead alone pass. The decoded artifact comparison and decoder hash are
in build/i386-budget-storage-inspect-v1/result.json.

BgtStrs now uses explicit I64 slots and allocates sizeof(I64) per entry, keeping
the original sort algorithm, comparator, account order and serialization.
This is the pointer-width adaptation permitted by PLAN.md's scope constraints;
it does not change QSortI64 into a pointer-width sort. The source gate in
tools/i386-budget-source.py permits exactly this reviewed transformation of
BgtStrs.HC and still requires all ten other Budget files to match the pinned
original. The pinned-original storage fixture remains unmodified by this port.

The corrected full image in build/i386-budget-sort-slot-cross-v1 passes the
original two-generation bootstrap and cross-build/386 audit. All 1368 delivered
source/doc files and all 686 inventory files match the candidate (the two audits
are build/i386-budget-sort-slot-source-audit-v1.json and
build/i386-budget-sort-slot-content-audit-v1.json).

The original installed-template oracle in
build/i386-budget-storage-installed-reference-v1 passes mask 15 and independent
48-byte typed-record/106-byte twelve-string checks. With the fix, the native
comparison in build/i386-budget-storage-installed-native-v2 passes both its
same-session reopen and a fresh QEMU boot. Both phases exactly match the
original records and mask, including all eleven installed accounts and BANK/
RENT colors. The second phase calls only the read path, with no installation or
transaction rewrite. All three Budget files retain identical bytes, attributes
and timestamps across reboot; 1738 preexisting files are preserved, the final
filesystem audit passes, and the input pins remain unchanged.

The new storage test constructs the transaction through BgtIns/BgtDataWrite.
Interactive form entry, account views, scheduled templates, cancellation and
whole Budget/C1-C5 qualification remain open. The original v1 driver is frozen
beside its result because the final runner adds explicit source-port validation;
the guest fixture and original expected records are unchanged.
