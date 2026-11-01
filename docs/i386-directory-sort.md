# Directory tree sorting

The original name and cluster comparators and recursive `DirFilesSort` are
shared through `Kernel/BlkDev/DirFilesSortCore.HC`. The sorter now stores
entry pointers in explicit eight-byte slots before calling `QSortI64`. This
preserves the original 64-bit slot layout on i386, where pointer slots would
otherwise be four bytes. Directory-first name ordering, extension tie breaks,
cluster order and child recursion retain the original code.

The fixture executes both the original pre-change body and the shared body
under private names on the pinned original system. It checks empty input,
directory-first and file name ordering, ascending clusters, nested sorting,
singleton-root recursion and exact caller-heap recovery. Both pass mask 511
with unchanged inputs (`build/i386-dir-sort-original-v1` and
`build/i386-dir-sort-original-v2`). The previous native image rejects the missing
sorter binding before any case runs (`build/i386-dir-sort-native-red`). Both
original rebuild generations pass (`build/i386-dir-sort-rebuild-v2.log`), though
their binary differences do not qualify reproducibility. The fixture does not
cover every filename, duplicate keys, allocation failures, or filesystem
enumeration.

The native 386 cross-build and instruction audit pass
(`build/i386-dir-sort-cross-v3`), and the 64 MiB native fixture passes all nine
checks with unchanged inputs and a byte-identical delivered fixture
(`build/i386-dir-sort-native-v1`). The concurrent run does not qualify startup
timing. An earlier cross-build exposed a missing forward declaration and the
retry required a refreshed bootstrap manifest; both were corrected before the
passing build.
