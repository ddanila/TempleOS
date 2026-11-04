# Original block I/O reference

`BlkRead` and `BlkWrite` are dependencies of the complete original
block-device initializer and drive path. The reference fixture uses the public
original functions with a copied drive/device record and private RAM backing,
so no physical disk sectors are modified. It passes mask 31 in
`build/i386-block-io-reference-public` with unchanged inputs: zero-count calls,
two-sector write/read and untouched boundary bytes, out-of-bounds exception,
read-only exception, and outer drive/device lock retention. Allocations are
freed after the checks. The fixture does not qualify ATA, ATAPI, ISO files,
cache, removable media, cancellation, or allocation failure.

Two fixture failures are preserved. `build/i386-block-io-reference` declared
externs over the original public declarations and timed out with an undefined
external shown on the captured screen. `build/i386-block-io-reference-source`
attempted to include the original source without its internal declarations and
failed compilation; the screen and executed fixtures are preserved. Removing
both changes uses the original public bindings and passes. The native control
`build/i386-block-io-native-red` rejects the include at the missing `BlkRead`
binding, with unchanged inputs; no native block I/O case ran. Complete native
block I/O and C1–C5 remain open.

```sh
python3 tools/test-i386-block-io.py --out ORIGINAL
python3 tools/test-i386-block-io.py IMAGE --out NATIVE
```

## Expanded offset and lock contract (2026-10-31)

The RAM-backed original fixture now also checks a nonzero drive offset, access
to the last valid sector, the explicit read-only override, and lock ownership
after errors. It verifies that a failed operation releases locks it acquired but
retains locks already owned by the caller. The pinned original passes all nine
checks (mask 511) with unchanged inputs
(`build/i386-block-io-extended-reference-v3`). This remains a private RAM-drive
contract; it does not establish ATA, file-backed devices, cache or media behavior.

The runner now uses the current welcome-screen expectation. On the full-content
pool-validator image the native fixture include is rejected at `BlkRead` before
any contract case runs, with unchanged inputs
(`build/i386-block-io-extended-native-red-v3`). The preceding attempt timed out
at the obsolete startup screen (`build/i386-block-io-extended-native-red-v2`);
its fixture did not run. An earlier exploratory attempt changed its pinned
fixture during execution and is not valid evidence
(`build/i386-block-io-extended-native-red-v1`). The original source inventory
entry records the new reference and native gap; it remains unqualified.

## File-backed device record (2026-10-30)

The complete original `CFile` record and file flags are shared byte-for-byte
through `Kernel/BlkDev/CFileTypes.HH`, included by KernelA and native PublicFiles.
Both original rebuild generations and the cross-build/386 audit pass with 1539
source and 24 build inputs unchanged in `build/i386-cfile-types-cross`. A native
64 MiB field-access check covers all record fields, nested directory-entry data
and file flags, passing four commands with unchanged inputs in
`build/i386-cfile-types-native`; the executed runner is preserved there. Its
61.722402-second concurrent startup is not an isolated timing qualification.
FOpen, FBlkRead/FBlkWrite, block I/O and media initialization remain open.

The complete original `BlkRead` and `BlkWrite` bodies are now shared through
`Kernel/BlkDev/BlockReadWriteCore.HC`. The extraction is byte-identical to
the prior original bodies, and both original rebuild generations pass
(`build/rebuild-test`). This prepares the source for a native provider; it
does not bind or implement the native dependencies or qualify block I/O.

A separate pinned-original cache contract passes mask 15 with unchanged inputs
(`build/i386-block-cache-reference`). On a private RAM-backed drive it checks
cached reads after underlying storage changes, write coherence, and cache
invalidation. It does not cover cache eviction, concurrency, ATA, or ISO.
The native control rejects the fixture at the missing `BlkRead` binding before
any cache case runs, with unchanged inputs (`build/i386-block-cache-native-red`).
No native cache qualification is claimed.

`DskCacheHash` now computes its bucket stride as two pointer widths, matching
`DskCacheInit`'s allocation and initialization. This keeps the original
16-byte stride on x86-64 and permits an 8-byte stride on 32-bit. Both original
rebuild generations pass, and the rebuilt original kernel passes cache mask 15
(`build/i386-cache-stride-working`). The native cache is not yet implemented
or tested.

The expanded pinned-original cache contract passes mask 63 with unchanged
inputs (`build/i386-block-cache-extended-reference`). It also checks a read
with cached leading and trailing sectors around an uncached middle sector, and
that cache entries for two drives do not alias. This is original behavior
evidence, not a native cache result.

The pinned-original contract now also checks that invalidating one drive does
not discard another drive's cached sector. The expanded mask 127 passes with
unchanged inputs (`build/i386-block-cache-selective-reference`). That check
does not cover eviction, concurrency, ATA, ISO or native cache behavior.

The reference fixture also reads one sector more than the configured cache
capacity, then checks that the first sector was evicted and the last remains
cached. The pinned original passes mask 255 with unchanged inputs
(`build/i386-block-cache-eviction-reference`). This tests capacity replacement,
not a complete eviction-order or concurrency contract. Native cache behavior,
ATA and ISO remain unqualified.

The original `CCacheBlk` and `CBlkDevGlbls` declarations are shared in
`Kernel/BlkDev/BlockGlobalsTypes.HH` and included by the native public file
header. Both original rebuild generations and the 386 cross-build/audit pass.
A native record check timed out after the first declaration command reported
`COMMAND OK`, before its remaining field checks; inputs were unchanged
(`build/i386-block-globals-native/record-result.json`). The native record
layout and cache behavior are not yet qualified.

A fixture-based record check subsequently passes mask 15 on the pinned
original and all three commands on 64 MiB native, with inputs unchanged
(`build/i386-block-globals-reference` and
`build/i386-block-globals-native-fixture`). It covers selected cache fields,
body endpoints, array extent and field adjacency; it is not a complete layout
audit or cache behavior test. The 62.216726-second native startup observation
was concurrent and is not an isolated timing gate.

The native volume table now stores its drive map in the canonical
`CBlkDevGlbls.let_to_drv` array and sets `drvs` to its existing drive records
on lazy initialization. Console mapping and file lookup use that same array;
no public `blkdev` global or cache provider is published yet. Both original
rebuild generations, the 386 cross-build/audit (1545 source and 24 build
inputs unchanged), and the native ATA/task test pass. The native drive-map
contract passes all 20 commands at 8 and 64 MiB with unchanged inputs in
`build/i386-drive-global-map-native-8m` and
`build/i386-drive-global-map-native`. Their startup observations (61.862676
and 62.366616 seconds respectively) were concurrent, not isolated timing
gates. The isolated 8 MiB gate passes nine behavior/VGA checks with no
build-provider loads and four unchanged inputs, but misses the 60-second target
at 61.386673 seconds (`build/i386-drive-global-map-startup`). The 16 MiB
diagnostics pass at 233.926988 seconds, with 128 immediate-push, 22 publication
and 28 program-publication cases, both memory phases, nine behavior/VGA checks,
no build-provider loads, and four unchanged inputs
(`build/i386-drive-global-map-diagnostics`). The isolated timing gate remains
failed. Full block-device state and cache integration remain open.

The native ATA/task fixture also verifies that `block_globals.drvs` points to
the volume table's live records, that the C, D, and E entries refer to the
same identities returned by lookup, and that the map has 32 entries. Its
remapping and mounted-file checks pass with these assertions enabled
(`python3 tools/test-i386.py --ata-tasks`).

The kernel now initializes `block_globals.blkdevs` to the existing device
array and supplies that same pointer to the console. Both original rebuilds
and the 386 cross-build/audit pass with 1545 source and 24 build inputs
unchanged. Native 64 MiB device-slot and drive-map contracts pass 24 and 20
commands respectively with unchanged inputs (`build/i386-block-globals-device-slot`
and `build/i386-block-globals-device-map`); their startup observations were
concurrent. A drive-state fixture rejected at missing `Drv` before its cases
ran (`build/i386-block-globals-device-native`), with unchanged inputs. Public
block globals and full device initialization remain open. The isolated 8 MiB
startup passes all nine behavior/VGA checks, loads no build provider, and
preserves all four inputs, but misses the 60-second target at 61.537205 seconds
(`build/i386-block-globals-device-startup`). The 16 MiB diagnostics pass at
232.471277 seconds with 128 immediate-push, 22 publication and 28 program
publication cases, both memory phases, nine behavior/VGA checks, no build
provider loads, and four unchanged inputs
(`build/i386-block-globals-device-diagnostics`). The interactive timing gate
remains failed.

Console configuration now also receives the kernel-owned `CBlkDevGlbls`
itself and checks that its drive map and block-device array match the existing
console pointers. The console service version is 139. This supplies shared
state for block I/O integration; it does not publish `blkdev` or implement the
cache. Both original rebuild generations and the 386 cross-build/audit pass
(`build/i386-block-globals-console-cross-final`). The native 64 MiB drive-map
contract passes 20 commands and VGA checks with unchanged inputs
(`build/i386-block-globals-console-map`); its 59.102222-second startup was
concurrent and is not an isolated timing gate. The expanded cache fixture on
the earlier pinned native image still rejects at missing `BlkRead`, with
unchanged inputs (`build/i386-block-cache-eviction-native-red`).

The native console module now compiles the original disk-cache routines using
the kernel-owned block globals and root-task allocation. The original and
native builds select those globals through `DskCacheGlobals`. Both original
rebuild generations pass, and a rebuilt-original guest passes the cache
contract with mask 255 (`build/i386-cache-core-original-working`). The native
cross-build and 386 instruction audit pass
(`build/i386-cache-core-cross-final`); a 64 MiB native drive-map run passes 20
commands and VGA checks with unchanged inputs
(`build/i386-cache-core-native-map`). Its 62.778933-second startup was
concurrent and is not an isolated timing gate. The native cache routines are
not yet initialized, connected to block I/O, or behavior-tested, and no public
block I/O or cache qualification is claimed.

The native console now publishes internal cache-core bindings for use by later
block I/O integration. A direct guest fixture initializes a private cache,
checks mixed leading/trailing hits, a miss on another drive, drive-specific
invalidation, capacity eviction and teardown, then verifies another command
still runs. It passes mask 127 at 8 and 64 MiB with unchanged inputs
(`build/i386-dsk-cache-core-native-8m` and
`build/i386-dsk-cache-core-native-extern`). Both original rebuilds and the
native cross-build/386 instruction audit pass
(`build/i386-dsk-cache-core-test-cross`). The startup observations of 59.050788
and 59.142578 seconds were concurrent, not isolated timing gates. These direct
cache-core checks do not establish concurrent behavior or integration with
`BlkRead`, `BlkWrite`, removable devices, ATA or ISO; the cache is still not
initialized on startup.

A separate 64 MiB native cache-core fixture runs two spawned tasks, each writing
and reading the same sector 64 times. Every completed read must contain one
whole writer's pattern. Both tasks completed and the test passed with unchanged
inputs (`build/i386-dsk-cache-concurrency-native-final`). This samples one
cooperative scheduling pattern; it does not establish exhaustive concurrency,
block I/O integration, or interrupt-level safety. Its 59.201660-second startup
was concurrent and is not an isolated timing gate.

## Private RedSea sector transport (2026-10-30)

A private `I386RawBlocks` service is being developed as a hardware backend for
future original block services. It transfers sectors only on mapped, mounted
RedSea ATA volumes, borrows the task's file state, retains the existing drive
and channel locking, checks range and read-only state, and flushes writes.
Callers remain responsible for metadata and cache coherence; a failed write
may have partially transferred sectors. This is not the public `BlkRead` or
`BlkWrite` implementation and does not provide RAM, FAT, ISO or cache support.

The first native 64 MiB fixture passed its read/write, range, zero-count,
read-only and preowned-lock checks with unchanged inputs in
`build/i386-raw-blocks-native-64m`. A subsequent change adds checks after a
queued lock acquisition for changes to the device, filesystem or volume bounds;
the original two-generation rebuild, 386 cross-build/audit and basic native
sector contract all pass for that changed version (`build/rebuild-test`,
`build/i386-raw-blocks-revalidated-cross`, and
`build/i386-raw-blocks-revalidated-native`). A separate contention fixture
changes the drive size while a read waits on the device lock. It fails on the
earlier image, with unchanged inputs (`build/i386-raw-block-race-before`);
the current image passes the same fixture with unchanged inputs
(`build/i386-raw-block-race-after`). This exercises a size change, not all
possible drive remaps or device mutations. The basic sector contract also
passes at 8 MiB with unchanged inputs
(`build/i386-raw-blocks-revalidated-native-8m`); this is not the full minimal
profile or a startup timing qualification. C1–C5 remain open.

## Mounted RedSea drive fields (2026-10-30)

Mounted native RedSea drive records now initialize the original `CDrv` values
for sectors per cluster (`spc=1`), the bitmap's represented-data origin
(`data_area`), and both bitmap sector addresses (`fat1` and `fat2`). They are
derived from the already validated mounted volume, matching the calculations in
the original `RedSeaInit`. This supplies metadata needed by the original
cluster and file-stream services; it does not allocate the original FAT cache
or implement media initialization, public block I/O or `FOpen`.

The original-system fixture reads its actual RedSea boot sector through
`BlkRead` and passes all five header/record checks with unchanged inputs
(`build/i386-redsea-drive-fields-original`). The preceding native image fails
the same aggregate check after reading its header through the private sector
transport, with unchanged inputs (`build/i386-redsea-drive-fields-native-red`).
Both original rebuild generations and the corrected 386 cross-build/audit pass
(`build/rebuild-test`, `build/i386-redsea-drive-fields-cross`). The corrected image passes the 64 MiB metadata contract with unchanged inputs
(`build/i386-redsea-drive-fields-native`). The existing drive-map regression
timed out at the obsolete initial console screen, before executing its cases
(`build/i386-redsea-drive-fields-map`); it is being rerun with welcome-screen
expectations and passes all 15 drive-map cases and 20 commands with unchanged
inputs (`build/i386-redsea-drive-fields-map-welcome`). The 8 MiB metadata check
also passes with unchanged inputs
(`build/i386-redsea-drive-fields-native-8m`). These concurrent guest runs do not
qualify startup timing. C1–C5 remain open.

## Queued sector-transfer revalidation (2026-10-31)

The private raw-sector contention fixture now also changes the drive offset
and filesystem while a read waits for the device lock, and sets the device
read-only while a write waits. Alongside the existing size-change case, all
four reject the queued operation and recover after restoring the fields on the
current full native image (`build/i386-raw-block-race-expanded-v1`). Inputs and
the delivered fixture were unchanged. The write uses the sector's existing
contents and the guest runs on a snapshot. The fixture yields to the waiting
task before each change; this samples cooperative contention and does not
establish all remapping or device teardown cases. Public block I/O remains
unimplemented.

## Original ATA constants (2026-11-04)

Compiling the unchanged `DskATA.HC` on the full workstation image first
stopped at missing `ATAR1_CTRL` on line 4
(`build/i386-ata-dependency-probe-v1`). The original command, status and
register-offset constants are now shared byte-for-byte through
`Kernel/BlkDev/ATAConstants.HH`, included by both KernelA and native
PublicFiles. Both original rebuild generations pass, as do the full native
cross-build, 386 instruction audit and delivered-source audit (1198 files)
in `build/i386-ata-constants-cross-v1`. The follow-up unchanged-source compile
probe advances to missing `RepInU16` on line 87
(`build/i386-ata-dependency-probe-v2`); both probes preserve their inputs and
call no ATA routine. This supplies original constants, not native ATA, public
block I/O or media support.

## Native repeated port transfers (2026-11-04)

The native public kernel now binds all six `RepInU8/U16/U32` and
`RepOutU8/U16/U32` entry points with the original signatures. The native
implementation uses scalar port intrinsics with element counts and byte
strides, without scheduler yields between accesses. Exports are appended to
the console table, retaining all prior data-symbol indices. Both original
rebuild generations and the full cross-build/386 audit pass
(`build/i386-port-string-cross-v2`).

`tools/test-i386-port-string.py` passes on that image with unchanged inputs
(`build/i386-port-string-native-v3`). In QEMU it checks zero-count calls with
null buffers, byte/word/dword unassigned-port reads into unaligned guarded
buffers, output count/stride through the UART scratch register, and source
buffer preservation. Only each output element's low byte is observable at
the scratch register; this does not establish full-width ATA transfers or
physical hardware behavior.

The first image boot failed because an initial edit shifted the indexed
export table; its fixture and ATA probe never ran
(`build/i386-port-string-native-v1`, `build/i386-ata-dependency-probe-v3`).
The corrected image boots, but the first fixture attempt had an unsupported
expected-value expression (`build/i386-port-string-native-v2`); the simplified
fixture passes as v3. Compiling unchanged `DskATA.HC` on the corrected image
now advances to missing `EndianU16` on line 112, with inputs unchanged and
no ATA routine called (`build/i386-ata-dependency-probe-v4`). Native ATA,
public block I/O, streams and C1-C5 remain open.

## Public endian bindings (2026-11-04)

The native public kernel now exposes `EndianU16`, `EndianU32` and `EndianI64`
using the already included, unchanged `Kernel/EndianCore.HC` bodies. The three
exports are appended without shifting existing symbol indices. Both original
rebuild generations and the full native cross-build/386 audit pass, as does
the 1199-file delivered-source audit (`build/i386-endian-public-cross-v1`).
`tools/test-i386-endian-public.py` runs the exhaustive native fixture, kept
separate from the original-system comparison runner. It passes with unchanged
inputs on the native image
(`build/i386-endian-public-native-v1` and the separately named runner
rerun `build/i386-endian-public-native-v2`), covering every U16 input, mixed and
all-ones vectors, all U32/U64 bit positions and double-swap recovery.
The unchanged ATA compile probe now advances from missing `EndianU16` at
line 112 to missing `CATAPITrack` at line 281, with inputs unchanged and
no ATA routine called (`build/i386-ata-dependency-probe-v5`). Native ATA,
public block I/O, streams and C1-C5 remain open.

## Shared ATAPI track record (2026-11-04)

The complete original `CATAPITrack` declaration is now shared byte-for-byte
through `Kernel/BlkDev/ATAPITrackTypes.HH` by KernelA and native PublicFiles.
Both original rebuild generations and the full cross-build/386 audit pass;
the delivered-source audit matches all 1200 packaged source/doc files
(`build/i386-atapi-track-types-cross-v1`). The native packed-layout fixture
passes with unchanged inputs (`build/i386-atapi-track-types-native-v1`),
checking the 48-byte size, typed reads of a byte-pattern record, unaligned
fields and both union aliases. Reserved fields are not individually checked.
No ATAPI command is executed. The unchanged ATA compile probe now advances
from missing `CATAPITrack` at line 281 to missing `blkdev` at
`blkdev.read_cnt` on line 372 (`build/i386-ata-dependency-probe-v6`), with
inputs unchanged. Public block-global access and native ATA integration,
block I/O/streams and C1-C5 remain open.

## Public block-global identity (2026-11-04)

Native `blkdev` now binds directly to the existing kernel-owned
`CBlkDevGlbls` record as a data symbol. It shares the drive map, block-device
records and cache state used by existing services. The appended export
preserves prior indices. Both original rebuild generations, full native
cross-build/386 audit and 1200-file delivered-source audit pass
(`build/i386-public-block-globals-cross-v1`). The native identity fixture
passes with unchanged inputs (`build/i386-public-block-globals-native-v1`),
checking the cache helper's record address, mapped C drive, block-device
array and reversible read/write counter updates through both aliases.
This does not qualify initialization or behavior of every global field.
The unchanged ATA compile probe advances to missing `DskCacheAdd` at line
439, with inputs unchanged and no ATA operation executed
(`build/i386-ata-dependency-probe-v7`). Full ATA, public block I/O/streams
and C1-C5 remain open.

## Public cache core and complete ATA compilation (2026-11-04)

Native public headers now bind `DskCacheInit`, `DskCacheAdd`, `RCache` and
`DskCacheInvalidate2` to the existing shared original cache implementation.
The new exports are appended and retain prior symbol indices. Both original
rebuild generations, full cross-build/386 audit and 1200-file delivered-source
audit pass (`build/i386-public-dsk-cache-cross-v1`). The public-name cache
fixture passes all seven existing core checks with unchanged inputs
(`build/i386-public-dsk-cache-native-v1`): initialization, leading/trailing
hits around a miss, drive isolation, selective invalidation, eviction and
teardown. It does not exercise full public block I/O or media invalidation.

The complete unchanged `Kernel/BlkDev/DskATA.HC` now compiles without stubs
on the native image, followed by a successful command, with inputs unchanged
(`build/i386-ata-dependency-probe-v8`). This is compilation evidence only:
no ATA/ATAPI routine is called, the routines are not yet retained as a native
provider, and device transfers, initialization and failure behavior remain
unqualified. The higher-level `DskCacheInvalidate` wrapper still requires
media initialization and is not replaced by the low-level function. Full
ATA, public block I/O/streams and C1-C5 remain open.

## Original ATA read on native hardware records (2026-11-04)

The complete unchanged `DskATA.HC`, compiled in the native guest, now
executes its original `ATAReadBlks` successfully on the existing QEMU ATA
device record (`build/i386-original-ata-read-native-v1`). The runner checks
that the image's ATA source matches the worktree before boot and preserves
its pinned inputs. It compares one RedSea header sector byte-for-byte
against `I386RawBlocks`, checks guards around an unaligned 512-byte target,
verifies the original read counter increment, and confirms a preowned drive
lock is retained. The guest uses a copied image and performs no ATA writes.
This is a one-sector ATA read contract, not retained-provider integration,
multi-sector transfers, ATA writes, ATAPI, initialization, media changes or
failure recovery. The complete provider and public block I/O/streams remain
open. Run with `tools/test-i386-original-ata-read.py IMAGE --out FRESH_DIR`.

## Retained original ATA provider (2026-11-04)

The complete `DskATA.HC` is now included by the retained native console
runtime. `ATAReadBlks`, `ATAWriteBlks`, `ATAInit`, `ATARBlks` and `ATAWBlks`
have public bindings. The shared source adds a typed `ATAGlobals` accessor
and routes its four counter accesses through it; the original target returns
`&blkdev`, and the native target returns the existing kernel-owned cache/block
record. The rest of the original ATA implementation is retained. `FloorU64`
is an explicit runtime import, listed in both the build contract and kernel
loader bindings.

Both original rebuild generations, full native cross-build/386 audit and
1200-file delivered-source audit pass (`build/i386-retained-ata-cross-v5`).
The retained public read contract passes with unchanged inputs
(`build/i386-retained-ata-read-native-v2`), matching one RedSea header sector
against native raw transport and checking guards, counter accounting and
preowned lock retention. This fixture does not compile ATA source in the
guest; it calls the retained binding. No ATA writes are performed.

Earlier integration attempts are preserved: cross v1 rejected a macro-based
record lvalue; cross v2 rejected the unnecessary `#undef` directive; cross v3
compiled the module but rejected its added import contract. Cross v4 passed
build/audits, but read-native-v1 stopped before fixture execution because
the kernel loader lacked that import. Cross v5 and read-native-v2 include
that binding and pass. Writes, multi-sector transfers, ATAPI, media initialization
and failure recovery remain unqualified, and full public block I/O/streams
and C1-C5 remain open.

## Retained ATA multi-sector transfers (2026-11-04)

`tools/test-i386-retained-ata-transfer.py` passes with unchanged inputs on
the retained-provider image (`build/i386-retained-ata-transfer-native-v3`).
It allocates a 1536-byte scratch file in a copied QEMU disk, verifies its
record and sector bounds, reads two sectors through `ATAReadBlks`, then
sets read/write limits to two sectors and exercises three-sector
`ATAWBlks`/`ATARBlks` transfers across the chunk boundary. It verifies
zero-count wrapper calls, byte guards around unaligned read buffers,
read/write counter deltas and preowned drive-lock retention. It restores
the limits, compares all written bytes through both `I386RawBlocks` and
`FileRead`, then deletes the scratch file. Writes target only its allocated
sectors. This does not qualify ATAPI, media initialization, failure recovery,
all transfer sizes, physical hardware or cold-reboot persistence.

The first two attempts stopped at fixture setup: `FileWrite` returns a
starting cluster, not a byte count. The second attempt added per-assertion
exception markers and identified `AX0002`; correcting that expectation kept
the independent file-size and transfer assertions intact. Neither earlier
run executed an ATA transfer from this fixture. Full public block I/O/streams
and C1-C5 remain open.

## Shared RedSea boot record (2026-11-04)

The complete original `CRedSeaBoot` declaration and `MBR_PT_REDSEA` value
are now shared through `Kernel/BlkDev/RedSeaBootTypes.HH` by KernelA and
native PublicFiles. The record body is byte-identical to the original. Both
original rebuild generations, full native cross-build/386 audit and 1201-file
delivered-source audit pass (`build/i386-public-redsea-boot-cross-v1`).
The native live-header fixture passes with unchanged inputs
(`build/i386-public-redsea-boot-native-v1`): 512-byte size, field offsets,
header signatures and volume/root/bitmap fields match the mounted drive
record after a retained ATA read. This does not initialize or format media.

A compile-only probe of the complete shared `BlockDevInitCore.HC` stops
at missing `RedSeaValidate` on line 17, with inputs unchanged and no
initializer called (`build/i386-block-init-dependency-probe-v1`). Original
RedSea validation/initialization/formatting, full block I/O/streams and
C1-C5 remain open.

## Complete shared RedSea media core (2026-11-04)

`RedSeaInit`, `RedSeaValidate` and `RedSeaFmt` now share their complete
original bodies byte-for-byte through `Kernel/BlkDev/RedSeaMediaCore.HC`.
Both original rebuild generations and full native cross-build/386 audit
pass; all 1202 packaged source/doc files match the candidate
(`build/i386-redsea-media-core-cross-v1`).

The original-system private RAM contract passes before and after extraction
(`build/i386-redsea-media-reference-v4` and `-v5`). It temporarily maps a
private RAM device at Z, checks valid/corrupt headers, initialization metadata
and bitmap-cache allocation, preowned lock retention, and quick-format root
`.`/`..` entries, then frees backing/cache/list storage and restores the map.
No physical disk sector is formatted. Three earlier attempts timed out at
fixture compilation; split declarations and a fixed slot index did not
resolve it. The decisive correction supplied exact extern declarations for
these internal original helpers. They were not media runtime failures.

The native compile-only core probe stops at missing public `BlkRead` on
line 7 with inputs unchanged and no media function executed
(`build/i386-redsea-media-dependency-probe-v1`). The core is delivered but
not bound as a native media provider. Full block I/O, RedSea media lifecycle,
streams and C1-C5 remain open.

## Retained partition type setter (2026-11-04)

The complete original `DrvTypeSet` body is now shared byte-for-byte through
`Kernel/BlkDev/DriveTypeSetCore.HC` and retained with a native public binding.
The original `CMBRPrt`, `CMasterBoot` and partition constants are shared in
`MasterBootTypes.HH`; `INVALID_CLUS` moves unchanged into the shared block
header. Both original rebuild generations, full native cross-build/386 audit
and 1204-file source audit pass (`build/i386-drive-type-set-cross-v2`).
The first cross-build stopped at the previously unshared `INVALID_CLUS`
constant; no native fixture ran on that attempt.

The native fixture passes with unchanged inputs and exact restored-header
verification (`build/i386-drive-type-set-native-v1`). On a copied raw RedSea
image it temporarily writes a synthetic primary MBR, checks the 16-byte
partition/512-byte MBR layout, RedSea and FAT32 type/active-byte updates with
all other bytes unchanged, invalid type rejection without sector changes,
and preowned lock retention. It restores the original sector and verifies
all 512 bytes in both the guest and host runner. The source image is
unchanged. Extended-partition traversal and physical hardware are not
qualified. This supplies the partition-edit dependency of `RedSeaFmt`;
complete native formatting, block I/O/media/streams and C1-C5 remain open.

## Complete shared media block helpers (2026-11-04)

The complete original `BlkWriteZero` and `DrvFATBlkAlloc` bodies are shared
byte-for-byte through `BlockWriteZeroCore.HC` and `DriveFATAllocCore.HC`.
Both original rebuild generations, full native cross-build/386 audit and
1206-file delivered-source audit pass (`build/i386-media-block-helpers-cross-v1`).
The original-system private RAM fixture passes with unchanged inputs
(`build/i386-media-block-helpers-reference-v1`): 2049 sectors zeroed across
the 2048-sector chunk boundary, untouched surrounding sectors, zero-count
behavior, bitmap-cache replacement/data/reset and preowned lock retention.
It does not exercise non-RAM progress reporting or native block operations.

Native compile-only probes stop at missing public `BlkWrite` on line 17
and `BlkRead` on line 8 respectively, with inputs unchanged and no helper
called (`build/i386-block-zero-dependency-probe-v1` and
`build/i386-fat-alloc-dependency-probe-v1`). These are delivered complete
sources, not native bindings. Full block I/O, media lifecycle, streams and
C1-C5 remain open.

## Complete shared RedSea allocation core (2026-11-04)

The complete original free-list build, cluster free and best-fit allocation
bodies are shared byte-for-byte through `RedSeaAllocationCore.HC`. Both
original rebuild generations, full native cross-build/386 audit and
1207-file source audit pass (`build/i386-redsea-allocation-core-cross-v1`).
The original-system RAM fixture passes with unchanged inputs
(`build/i386-redsea-allocation-reference-v3`), compiling the complete
allocation and FAT-cache bodies under fixture-local names because the
internal kernel helpers are not all exported. It checks contiguous
allocations, bitmap set/clear, best-fit hole reuse, automatic list rebuilding
from the bitmap, zero-count allocation rejection and preowned lock retention.
The original free operation merges one adjacent list entry per call; the
fixture clears the list before checking recovery of the complete free range.
It does not claim two-sided coalescing from each individual free call.

The first two reference attempts stopped at undefined internal extern calls,
not failed allocation assertions. Native compile probe v1 stopped at the
untyped teardown call; supplying its existing provider declaration lets v2
reach missing `DrvFATBlkSet` on line 14, with inputs unchanged and no allocator
called (`build/i386-redsea-allocation-dependency-probe-v2`). Native allocation,
full public block I/O/media/streams and C1-C5 remain open.
