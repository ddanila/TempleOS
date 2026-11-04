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


### Active-source CallExtStr lookup

The earlier same-include lookup failure is now fixed for `CallExtStr`.
Compiler service version 83 adds a narrow callable-address lookup over the
current task's validated active frontend tables, from child to parent.
Each lookup uses a temporary single-table view; it neither changes parent
links nor publishes declarations. Missing names fall back to the task's
published table, and a found null address still returns zero. Only the
borrowed callable address crosses the compiler service boundary.

Both original rebuild generations, the full native cross-build and 386
instruction audit pass (`build/i386-call-ext-scope-cross-v5`). The 1212-file
source audit matches the checkout before this evidence append. The native
KVM contract passes with unchanged pinned inputs
(`build/i386-call-ext-scope-native-v2`): the full existing argument/return,
missing/null, exception and repeated-call checks run both inside the
unpublished include and after publication. Nested `ExePutS` also resolves a
pending parent function. An explicit public `HashFind` assertion proves the
pending function remains absent from the task table during the include.
General public `HashFind` overlay visibility is not changed or qualified.

Earlier attempts remain diagnostic evidence: cross v1 stopped at the old
host interface-version check; native v1 found that the first active-table
lookup did not search pending parent controls; cross v3 required refreshed
original rebuild provenance; cross v4 rejected an unsupported `continue`
statement, subsequently replaced with a conditional block. Full native
media/streams and C1-C5 remain open.


### Retained native block/media/stream closure

The native console now retains the complete mutually recursive original
block read/write dispatch, initializer, RedSea media/allocator, FAT32 allocator,
cluster transfer, directory lookup/mutation, directory-context, delete and
CFile routines in `Kernel/I386/BlockMediaRuntime.HC`. Public bindings include
`FOpen`, `FClose`, `FBlkRead` and `FBlkWrite`, alongside the block/cluster and
directory APIs listed in `docs/i386-block-io.md`. The RAM, ATA/ATAPI and
file-backed image branches remain in the implementations. No raw-RedSea-only
replacement or missing-operation stub is used. Public path operations still
use the retained file provider; complete FAT32/RAM path dispatch remains open.

Original and retained-provider allocators now share a lock-protected cache
handoff. `I386RedSeaBegin` calls the installed console-lifetime callback after
owning the mapped drive. It flushes dirty original FAT state, invalidates its
FAT block number, drops its free list, and invalidates its read cache. A missing
FAT buffer is initialized. Callback exceptions end the acquired transaction
before propagating. Console interface version 203 adds the kernel-owned
callback slot; the boot-drive global comes from the retained provider. The
console imports the existing public MemCmp implementation through an explicit
loader binding (62 console bindings).

Both original rebuild generations and the full native cross-build/386 audit
pass (`build/i386-block-media-retained-cross-v7`). The 1222-file delivered
source audit passes both before execution and on the mutated native contract
image, before this evidence append. The existing original CFile contract
returns mask 16383 on the rebuilt original
(`build/i386-block-media-cfile-reference-v1`) and on the native 486/no-FPU TCG
image (`build/i386-block-media-cfile-native-v2`), with unchanged inputs.

The stronger KVM contract passes with unchanged inputs
(`build/i386-block-media-native-v7`). It interleaves FOpen/FClose with retained
FileWrite allocation, creates files through both paths across root growth,
checks parent links immediately after original-only growth, checks a
non-root directory's grandchild link before cleanup, and verifies all data.
It also exercises complete RAM initialization/formatting, block bounds,
read-only override and nested locks; read and write file-backed RedSea image
initialization (including the default filename); and a FAT32 stream chain
with a reserved physical gap and an untouched-gap assertion. The independent
final audit finds 62 directories and 1687 files, non-overlapping live extents
and a bitmap matching reachable extents. All delivered source/doc bytes remain
unchanged after these operations.

This testing exposed and repaired an existing shared RedSea directory-growth
bug. Relocation copied stale `..` links into the new root and left child
parent links at the old cluster. An original-only private RAM regression
reproduced it (`build/i386-redsea-directory-growth-reference-v1`: root 2->18,
both parent links still 2, mask 1). `RedSeaDirNew` now fixes the relocated root's
parent and reparents live child directories, skipping a newly created child's
still-empty dot records. The expanded rebuilt-original regression passes
root relocation, directory creation during growth, non-root relocation and
grandchild parent links (`-v3`, mask 63), with unchanged inputs. Native
`i386-block-media-native-v4` independently caught the stale root-parent link
before this fix; final native checks pass it immediately, before later retained
writes can repair the metadata.

Earlier cross attempts found progress aliases, function-pointer declaration
placement, the missing MemCmp import and unsupported globals-expression/
forward-data forms; these were corrected in integration glue. Native fixture
v6 was stopped during boot to split a mixed pointer/value declaration. The
superseded workstation v1 run was stopped after the directory fix; the current
full WinMgr/welcome 64 MiB KVM run is in progress at
`build/i386-block-media-workstation64-kvm-v2`. No full-suite pass is claimed yet.
Native full FAT32 path handling, ATAPI/optical behavior, general media failure
recovery, complete resource/release qualification and C1-C5 remain open.
