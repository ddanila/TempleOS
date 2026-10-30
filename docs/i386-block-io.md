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
expectations. The 8 MiB metadata check also passes with unchanged inputs
(`build/i386-redsea-drive-fields-native-8m`). These concurrent guest runs do not
qualify startup timing. C1–C5 remain open.
