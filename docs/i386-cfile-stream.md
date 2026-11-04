# Block-backed file stream dependency

The unchanged autocomplete source first requires `FOpen`, then uses `FBlkRead`
and `FClose` for dictionary blocks. The complete original file-stream bodies
are shared through `Kernel/BlkDev/CFileStreamCore.HC`: open modes, cluster
buffering, block reads and writes, and close-time directory updates remain the
original implementation. This extraction does not yet bind the native block,
cluster and directory-context dependencies or export the stream APIs.

A ten-check original reference covers contiguous RedSea preallocation, write,
close, reopen, explicit and sequential reads, end-of-file and bounds,
read-only write rejection, a zero-count read, contiguous mode, and a `w+`
update followed by whole-file verification. The pinned original and rebuilt
original with the shared source both pass with unchanged inputs
(`build/i386-cfile-stream-reference-v4`,
`build/i386-cfile-stream-shared-original`). A zero-count read returns success
without changing the current block position; the earlier contrary expectation
is preserved in `build/i386-cfile-stream-reference-v2`.

Both original bootstrap generations and the cross-build/386 audit pass
(`build/rebuild-test`, `build/i386-cfile-stream-source-cross`). The native
fixture rejects at the missing `FOpen` binding before any case runs
(`build/i386-cfile-stream-native-red`). FAT, fragmentation, growth,
concurrency, error cleanup, the native implementation and C1–C5 remain open.

## Original cluster transfer dependency

The complete original `ClusBlkRead`, `ClusRead`, `ClusBlkWrite`, `ClusWrite`
and `ClusAlloc` bodies now live in `Kernel/BlkDev/ClusTransferCore.HC`, included
at their original position by `DskClus.HC`. A source comparison confirms the
expanded file is byte-identical to the preceding original. The RedSea and FAT
branches, drive locking, error handling and allocation choices are retained.
This makes the original routines available for later native integration; it does
not bind them or implement their block, FAT, directory or media dependencies.

The reference fixture now also directly reads three RedSea blocks, verifies
whole-cluster reading, checks zero-length read and write return values, and
writes and rereads an unchanged block. It observes that RedSea reads return the
next sector while nonempty writes return zero. The pinned original and rebuilt
original both pass all fourteen checks with unchanged inputs
(`build/i386-cfile-cluster-oracle-original` and
`build/i386-cfile-cluster-oracle-shared`). These direct cases do not cover FAT,
fragmentation, contention, failure cleanup or general cluster sizes.

Both original rebuild generations pass (`build/i386-clus-transfer-rebuild.log`),
as do the full native cross-build and 386 instruction audit
(`build/i386-clus-transfer-cross`). Neither the cluster transfers nor the file
stream APIs are yet exported by the native runtime. C1–C5 remain open.

The welcome-console full-content image repeats the native compile boundary
with the complete shared cluster core
(`build/i386-cluster-transfer-dependency-probe-v1/result.json`). It rejects
`ClusTransferCore.HC` at line 11, the first `BlkRead` call, before any transfer
executes. The source image hash remains unchanged. This identifies public
block I/O as the next dependency; the private raw-sector transport does not
provide the original cache/media contract or qualify cluster and stream APIs.

## Public file-attribute dependency (2026-11-04)

The existing shared `FileAttr` body now has a native public binding, and
native PublicFiles includes the unchanged shared RedSea attribute constants.
No attribute calculation body is replaced. Both original rebuild generations,
full native cross-build/386 audit and 1207-file source audit pass
(`build/i386-public-file-attr-cross-v2`). The 14-case native fixture passes
with unchanged inputs (`build/i386-public-file-attr-native-v2`), checking
final uppercase suffixes, whole-path dot counting, lowercase rejection,
empty names, compressed-bit removal and preservation of contiguous and
unrelated attribute bits. No file operation is executed by that fixture.

The first native fixture and stream-core probe stopped before execution at
missing public `RS_ATTR_DIR`/`RS_ATTR_CONTIGUOUS` constants; including the
existing shared header corrects that API gap. The complete unchanged stream
core now compiles past those attributes and stops at the missing `Del` call
on line 43, with inputs unchanged and no stream operation called
(`build/i386-cfile-stream-dependency-probe-v3`). Full streams, block I/O/media
and C1-C5 remain open.

## Complete shared deletion dispatcher (2026-11-04)

The complete original `Del` dispatcher is now shared byte-for-byte through
`Kernel/BlkDev/FileDeleteCore.HC`, retaining both RedSea and FAT32 branches.
Both original rebuild generations, full native cross-build/386 audit and
1208-file source audit pass (`build/i386-file-delete-core-cross-v1`).
The original private RAM RedSea fixture passes with unchanged inputs
(`build/i386-file-delete-reference-v2`): wildcard counts, unmatched masks,
literal stem preservation, explicit extension masks, `make_mask` expansion
of directory contents, sibling preservation and the empty-directory option.
Directory deletion contributes zero to the file count. The fixture restores
its temporary drive mapping and frees RAM/cache/list storage. It does not
qualify FAT32 deletion or native dispatch.

Reference v1 reached `Delete6` because the fixture incorrectly expected
`make_mask` to expand a filename stem; the original only expands directory
paths. The corrected fixture verifies that distinction without changing
production behavior. Native compilation stops at missing `DirContextNew`
on line 6, with unchanged inputs and no deletion executed
(`build/i386-file-delete-dependency-probe-v1`). Full native `Del`, streams,
block I/O/media and C1-C5 remain open.

## Directory-context and full drive lifecycle dependency (2026-11-04)

The complete original `DskCacheInvalidate`, `DskChg` and `Drv` bodies are
shared byte-for-byte through `DriveMediaLifecycleCore.HC`, preserving media
initialization and removable-media branches. Both original rebuild generations,
full native cross-build/386 audit and 1209-file source audit pass
(`build/i386-drive-media-lifecycle-cross-v1`). They are not native bindings.

The original private RAM directory-context contract passes with unchanged
inputs (`build/i386-dir-context-reference-v1`). It checks saved drive/path
identity, ordinary masks, directory-to-star expansion, semicolon masks,
`no_mask`, restoration and explicit non-restoration, failed parent rollback,
recursive directory creation, and the initialization-in-progress restore
branch. The fixture restores its original path/drive and RAM map and frees
its private storage. It does not qualify native contexts or removable media.

Compile-only native probes stop at `Drv` on line 9 of `DskDirContext.HC`
and `BlkDevInit` on line 8 of the shared lifecycle core, with inputs unchanged
and no lifecycle operation called (`build/i386-dir-context-dependency-probe-v1`,
`build/i386-drive-media-dependency-probe-v1`). Full native contexts, deletion,
streams, block I/O/media and C1-C5 remain open.

## Native dynamic fixed-argument calls (2026-11-04)

Native public `CallExtStr` now resolves functions and system exports from
the current task hash table, returns zero for absent/null addresses, and
forwards the caller's eight-byte argument slots through a native stack
bridge. The matching fixed-arity target removes those slots and returns
integer/soft-float bits in EDX:EAX. This supplies the dynamic callback
mechanism used by file-backed device initialization; it does not implement
the remaining media or stream services.

Both original rebuild generations, full native cross-build/386 audit and
1212-file source audit pass (`build/i386-call-ext-str-cross-v2`). The native
fixture passes with unchanged inputs (`build/i386-call-ext-str-native-v4`):
missing symbols/null export, zero/one/three/ten arguments, wide integers,
pointers, soft-float bits, nested calls, system exports, propagated exceptions
and 100 subsequent calls. Definitions are committed by one command before
the separate contract invocation. The earlier same-include invocation
returned zero while a direct call succeeded (`-v2`/`-v3`); publication-time
visibility remains a separate compiler compatibility boundary. No same-unit
dynamic visibility qualification is claimed. Fixture v1 stopped at an
opaque public function-record field before execution.

The first cross-build stopped at ndisasm 3.01's undecoded `FF D0`. GNU
objdump independently identifies those bytes as `call eax`. The existing
exact-byte indirect-branch decoder workaround now includes this encoding;
checks preserve following instruction boundaries and retain invalid bytes
as `db`. No instruction allowlist was broadened. Full native media/streams
and C1-C5 remain open.
