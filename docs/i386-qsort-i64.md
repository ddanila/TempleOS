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
