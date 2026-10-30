# Linked-list count dependency

Budget's unchanged `BgtStrs.HC` calls the public `LinkedLstCnt` service. The
native Budget load initially rejected that symbol in
`build/i386-budget-native-load-v1` before reaching installation. The original
implementation now lives in `Kernel/LinkedLstCntCore.HC`, shared by the
original kernel and MemoryRuntime 32. It counts a null-terminated chain by
following the first pointer in each node; it does not mutate the nodes or
validate malformed or cyclic lists. The native public declaration retains the
original signature.

The independent contract checks null, one-node, suffix and full chains, an
updated link, and unchanged link/payload values. The pinned original passes
all six checks (`build/i386-linked-count-reference-v3`). Both original
bootstrap generations pass (`build/rebuild-test`), and the cross-build and 386
audit pass (`build/i386-linked-count-cross`). The initial native contract was blocked by an obsolete startup-screen oracle
(`build/i386-linked-count-native-64m`); its replacement passes all six checks and a continuation command at 64 MiB
with unchanged inputs (`build/i386-linked-count-native-64m-v2`). This
concurrent run does not qualify startup timing. Budget now compiles past
`LinkedLstCnt` and rejects line 97 at `QSortI64`
(`build/i386-budget-native-load-v2`). Neither a Budget workflow nor any C1–C5
milestone is qualified by this dependency alone.
