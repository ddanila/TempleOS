# Original directory-context contracts

Full original DocPutKey changes the document's directory context through
DirContextDel/DirContextNew. Their complete source is
Kernel/BlkDev/DskDirContext.HC, and CDirContext is declared in Kernel/KernelA.HH.
The native public binding is still missing. No runtime directory-context port
or completed desktop milestone is claimed by this test-first checkpoint.

The shared fixture tests/guest/i386-directory-context-reference/Context.HC
calls the actual public routines and observes their returned context, real
Fs directory/drive fields, caller document roles and heap. It does not implement
a substitute path parser. The original uses writable RAM drive B; the native
runner selects C. Both use /Probe/DirContext with real A/Nested and B directories.
This profile mapping is explicit; it is not cross-drive restoration coverage.

| Case | Expected behavior |
| --- | --- |
| Filename mask | Retain the current directory and mask note.HC. |
| Relative directory | Enter A; retain *.HC. |
| Whitespace | Trim leading/trailing spaces; enter A and retain note.HC. |
| Multiple masks | Enter A; retain *.HC;*.HH. |
| Directory make_mask | Recognize existing A as a directory; enter it and use *. |
| Empty make_mask | Stay in the caller directory; use *. |
| no_mask | Enter A and return an empty mask. |
| make_dirs | Create/enter Made/Deep; retain *.HC. |
| restore FALSE | Deletion keeps A as current; fixture restores the original directory only after observing that behavior. |
| Nested contexts | Enter A/Nested, restore A on inner deletion and the original directory on outer deletion. |
| Failed path | Enter a valid A prefix, fail at Missing/Deep, return NULL and restore the original caller directory. |
| Null deletion | No directory/drive/role/heap change. |

For non-null contexts, assertions include exact old_dir/mask strings and
old_dv/dv identity. All cases check active/final paths, drive identity, unchanged
DocPut/DocDisplay/DocBorder and exact caller heap recovery after fixture cleanup.
No context-field assertion is made for a failed creation/null deletion because
there is no returned object. Cleanup of restore-FALSE state occurs after its
observable behavior is measured. Filesystem directories intentionally remain
in the disposable guest image.

build/i386-c4-directory-context-reference passes twelve masks of 63. The stronger
partial-progress failure path in
build/i386-c4-directory-context-partial-reference also passes twelve masks, with
unchanged inputs. Both execute on the qualified current original x64 rebuild.

build/i386-c2-directory-context-partial-prerequisite-red rejects the missing
DirContextNew binding with Invalid lval at its first preflight function. The
fixture and setup never run; this proves the API prerequisite remains missing,
not that any native directory-context behavior has passed or failed.

Reproduce with fresh output directories:

```sh
python3 tools/test-i386-directory-context-reference.py --current-system --out build/NEW-reference
python3 tools/test-i386-directory-context.py build/i386-c2-editor-replace-navigation-cross/kernel.img --out build/NEW-native
```

The full native Console build has now failed; its independent diagnostic replay
preserves its embedded source image (see [fault evidence](i386-native-console-fault.md)).
Independent candidates can use a separate output directory. Share the canonical context
type and complete original routines, and supply actual drive, string and
silencing services. Do not copy a private prefix layout or replace these with
a current-directory string shortcut. Repeat the same contracts on the port.
Cross-drive/removable-media behavior, initialization-in-progress restoration,
invalid drives, allocation failure, exceptions, cancellation and cross-task
ownership require separate contracts. Full original input and C1–C5 remain open.

## Native drive-state prerequisites found in source review

Exposing the string utilities removes only one dependency family. Before
integrating the unchanged context routines, resolve these actual representation
boundaries:

* Initial review found native `CDrv` complete but `CBlkDev` only forward
  declared, with `BlockDevTypes.HH` supplying only device-kind constants.
  The shared complete record below resolves that declaration gap. Context
  deletion reads `old_dv->bd->flags`, so real device instances remain necessary.
* `I386TaskFilesDrive` initially constructed stable public drive identities
  without backing-device records. The identity implementation below associates
  them with their identified physical ATA disk. Full public device services,
  locking, remapping and removable-media behavior remain separate work.
* Initial review found `I386TaskFilesNew` embedding the directory string immediately
  after its state allocation. Canonical context deletion's initialization-in-progress branch
  frees/replaces `Fs->cur_dir` directly. That branch could not safely use the interior
  pointer. The ownership implementation below replaces this representation for
  public tasks; full context integration remains outstanding.
* The original `Drv` changes device state and resets the directory, while native
  file operations use `CI386TaskFiles` and its borrow/set/release protocol. Test
  public drive changes, alias resolution, restoration and initialization/error
  paths against the original before wiring the complete routines.

These are source-review findings, not runtime qualification. Keep the existing
same-drive context cases and add drive/device and exceptional ownership gates;
do not make directory restoration a string-only shim or remove original
initialization branches to avoid these prerequisites.

## Drive-state oracle and canonical device record (2026-10-16)

The shared `tests/guest/i386-drive-state-reference/Contract.HC` fixture adds
nine bounded observations on the real original APIs. All return mask 31 in
`build/i386-c4-drive-state-reference-fixed`, with unchanged inputs:

| Case | Observation before cleanup |
| --- | --- |
| Lookup | Omitted/current and lowercase letters resolve to the same drive. |
| Three same-drive resets | Drv with zero, lowercase or uppercase succeeds and resets the directory to `/`. |
| Invalid lookup | Let2Drv with `?` and except FALSE returns NULL without changing drive/directory. |
| Invalid change | Drv with `?` throws `Drv`; catching it preserves drive/directory and recovers heap usage. |
| Initialization restoration | Set the saved drive's real device initialization flag, delete a context and observe the saved drive and `/`; restore the original device flags. |
| Validation | DrvChk accepts the current drive and rejects NULL with except FALSE. |
| Aliases | Boot/home aliases resolve to the same identities as their expanded letters. |

Each case checks the real device signature/type/initialized flags, document
roles, and exact caller heap recovery after restoring the fixture directory.
Original B: RAM maps explicitly to native C: ATA, so the expected device kind
is derived from the selected drive letter. The initialization case deliberately
sets a flag on a disposable test system; it does not qualify concurrent hardware
initialization, cross-drive switching, removable media or allocation failure.

The first reference fixture called nonexistent `ToLower` and stopped in the
original debugger before executing cases. Its failed output remains in
`build/i386-c4-drive-state-reference`. The corrected fixture forms the lowercase
letter from the known uppercase A–Z range. This is a fixture repair, not a
changed behavioral expectation.

`Kernel/BlkDev/BlockDevRecord.HH` now shares the complete original device record
and flags between KernelA.HH and native DriveTypes.HH. The extracted section
reconstructs the original header byte-for-byte; evidence is
`build/i386-block-device-extraction.json`. The original two-stage compiler/kernel
bootstrap passes. The separate i386 build completes in
`build/i386-c4-block-device-cross`, with a 570800-byte kernel, matching 1481
source and 24 build-input hashes, both disk hashes verified and the limited
386 boot instruction audit passing (96 BIOS/255 protected-mode instructions).
This supplies the type, not backing-device instances or directory-string
ownership. Those prerequisites and public Drv/Let2Drv/context integration remain
open.

Before editing host headers, four relevant inputs embedded in the live repaired
Console build were compared byte-for-byte with host files and recorded in
`build/i386-c5-helper-scan-native-input-boundary.json`. That build continues on
its independent embedded image and original export directory; the new cross-build
does not change its source epoch.

The native preflight on the preceding combined image fails as expected in
`build/i386-c4-drive-state-final-prerequisite-red`, with unchanged inputs:
`Let2Drv` is rejected in the gate declaration before loading or executing the
fixture. The complete drive workflow remains red; sharing the type alone does
not close it.

`tools/test-i386-block-device-record.py` separately tests the delivered public
record without including a replacement declaration. All eleven commands pass
at 64 MiB on TCG `486,-fpu` in `build/i386-c4-block-device-record-native`: total
size 100 bytes, offsets and sizes for all 22 fields, initialization flags,
signature and a follow-up arithmetic command. The preceding image fails the
first size predicate in `build/i386-c4-block-device-record-final-red`. Both
runs use the same final harness and preserve inputs. This is public type/layout
qualification, not allocated device instances, drive operations or the 8 MiB
resource gate. No new minimal-profile pass is claimed.

```sh
python3 tools/test-i386-drive-state-reference.py --out OUT-original
python3 tools/test-i386-drive-state.py IMAGE --out OUT-native
python3 tools/test-i386-block-device-record.py IMAGE --out OUT-record
```

## Native backing-device identity (2026-10-16)

Each `CI386Ata` now owns a complete canonical `CBlkDev` for the lifetime of the
identified physical disk. Mounted `CDrv` records borrow that address; two
volumes on the same disk share it, and different disks have distinct records.
The record reports the real command/control-block base ports, unit, 512-byte
sector size and accessible capacity. The native protocol submits one sector
per command, so max_reads/max_writes are one; it advertises no software cache
or removable-media support. Optional retained IDENTIFY, RAM and file records
are NULL, rather than pointers into temporary or non-freeable storage.

Successful identification preserves the same device's mount/initialization
state, while a different channel/unit starts a fresh identity. Rejected decode
profiles leave the entire destination unchanged. Issued read/write commands
update the original last-write flag. Drive lookup preserves flags, refuses an
invalid device signature and can recover after the signature is restored.
This does not yet implement original public device locks, timestamps, retained
IDENTIFY ownership, media replacement, Drv/Let2Drv or directory contexts.

The first implementation reset metadata on every successful identification.
The expanded protected-mode ATA fixture catches that as error 63 in
`build/i386-c4-device-ata-reidentify-red`; its source snapshot and red-result
manifest are retained. The repaired fixture passes in
`build/i386-c4-device-ata-green`, including decode rejection preservation,
same/different-device identification, real LBA28/CHS reads/writes, last-write
flags, flushes, disk-byte verification and the instruction audit at 8 MiB on
QEMU 486. This backend run is not the no-FPU normal OS startup gate.

The extended fixture exceeded its former 128-sector bootstrap transfer limit
(66382 bytes versus a 66048-byte limit). That harness failure is preserved in
`build/i386-c4-device-ata-transport-failure`. Its test loader now reserves 160
sectors; production boot limits and guest RAM are unchanged.

The task suite initially stopped at publication-worker error 94. Diagnostic
output proves the worker had file/stage state but had not finished after 100
cooperative scheduler turns. A controlled rebuild with the pre-change ATA,
task-file code and fixture reproduces the same error in
`build/i386-c4-device-ata-tasks-baseline-control`; its control manifest pins the
actual overriding sources and harness. This is not evidence of a new device
identity regression. The fixture now waits up to 1000 turns and records the
actual count, while retaining all finish, cleanup, heap, disk and command-order
requirements. `build/i386-c4-device-ata-tasks-green` passes at 8 MiB on QEMU 486,
observing 253 turns. New assertions cover shared/different device identities,
flag preservation, invalid-signature recovery and inherited/changed task drives.

The source-matching original bootstrap and final cross-build pass in
`build/i386-c4-device-identity-final-cross`: 574056 kernel bytes, all 1481 source
and 24 build-input hashes matching, both disk hashes verified and the limited
386 boot audit passing. Independent reads of the two backend compiler ISOs
confirm all 802/807 delivered compiler/kernel and selected fixture inputs match
the workspace (`compiled-input-audit.json` in each passing backend directory).

All 15 public identity commands pass at 64 MiB on TCG `486,-fpu` in
`build/i386-c4-device-identity-api-native`, including real disk capacity and
metadata stability across Cd with the initialization flag set. The same final
harness rejects the preceding image's NULL device pointer in
`build/i386-c4-device-identity-api-red`; inputs remain unchanged in both runs.
The first native fixture reached its mutation step, then timed out because its
empty expected output omitted the assignment's correct scalar result, 130.
That attempt remains in `build/i386-c4-block-device-identity-native`. The final
fixture uses a void helper, without changing any metadata expectation.

Normal 8 MiB startup remains failed in
`build/i386-c4-device-identity-startup-8m`: the first SPNext function definition
exhausts the heap on a 1636-byte request with a largest free payload of 712
bytes. Thus this candidate is not a minimal-profile replacement, despite its
64 MiB metadata pass and 8 MiB isolated backend passes. Directory strings still
use the incompatible interior-pointer ownership described above. Public drive
services, resource recovery and C1–C5 remain open.

```sh
python3 tools/test-i386.py --ata --qmp-stdio
python3 tools/test-i386.py --ata-tasks --qmp-stdio
python3 tools/test-i386-block-device-identity.py IMAGE --out OUT-identity
python3 tools/test-i386-startup-memory.py IMAGE --out OUT-startup
```

## Public directory allocation ownership (2026-10-16)

Public task directory strings now use the task's public heap through its retained
allocation/capacity/release callbacks. The file provider loads after the memory
provider, so the root receives the same ownership as children. `Fs->cur_dir` is
read on borrow, clone, replacement and cleanup; direct original `Free`/`StrNew`
replacement no longer leaves a cached private pointer. Public drive selection
comes from `Fs->cur_dv` matched against the mounted identity table. Directory
validation checks ownership and a terminating NUL within the allocation capacity.
The private foundation fixtures without public heaps retain their trailing-record
storage; this is not a special case in public Free. File service version 54
requires matching kernel/provider/host validation.

The shared `i386-directory-owner-reference/Contract.HC` oracle checks same-path,
child-directory and root replacements with actual FileNameAbs/Cd, exact caller
heap restoration and unchanged document roles. A fourth case checks a child has
its own allocation, replaces it independently, and exits without changing the
parent. The first three cases pass on pinned original in
`build/i386-c4-directory-owner-reference`. The first child fixture incorrectly
assumed original Spawn inherited the current directory (mask 29); evidence is
`build/i386-c4-directory-owner-reference-with-child`. Original KTask.HC initializes
new tasks at home. The corrected fixture explicitly enters the test directory;
all four masks are 31 with unchanged inputs in
`build/i386-c4-directory-owner-reference-child-fixed`. Native Spawn's inherited
start directory remains a separate compatibility gap, not qualified by this test.

The old native image fails the initial `MHeapCtrl(Fs->cur_dir)` check with
`BAD PUBLIC MEMORY` in `build/i386-c4-directory-owner-red`. This is a real ownership
failure before any Free, not merely a missing API. Its inputs stayed unchanged.

The original two-generation compiler/kernel bootstrap passes. The standalone
ATA task and public heap lifecycle suites also pass at 8 MiB on QEMU 486.
Their original test images exceeded boot transfer reservations (527202 and
238858 bytes respectively); those failures are preserved in
`build/i386-c4-directory-owner-ata-transport-failure` and
`build/i386-c4-directory-owner-task-heaps-transport-failure`. The ATA fixture now
reserves code through 0x92000 and the same 32 KiB stack through 0x9A000, below
descriptor scratch 0x9C000. The heap fixture starts its arenas at 0x4C000,
0x54000 and 0x5C000, keeping their capacities unchanged and ending before its
0x90000 stack. Production boot reservations and guest RAM limits are unchanged.
Independent compiler-ISO reads verify all delivered Kernel/Compiler/fixture
HolyC sources against the current files (799 ATA and 798 heap files).

This is a directory representation change, not a replacement implementation of
DirContextNew/Del or Drv. Public drive initialization, remapping, removable media,
allocation-failure injection in the new ownership path and cancellation still
need coverage. C1–C5 and all inventory qualification remain open.

The final image `build/i386-c4-directory-owner-final-cross` passes the limited
386 boot instruction audit (96 BIOS/255 protected-mode instructions); its kernel
is 574056 bytes and all 1481 source plus 24 build-input hashes match. The first
cross build stopped at the host's stale version-53 check; the final build uses
version 54 consistently. All eight commands, including four mask-31 cases, pass
at 64 MiB on TCG `486,-fpu` in `build/i386-c4-directory-owner-native`, with unchanged
inputs and byte-verified delivered fixture. The backend green artifacts are
`build/i386-c4-directory-owner-ata-green` (169 publication turns) and
`build/i386-c4-directory-owner-task-heaps-green`.

Normal 8 MiB startup remains red in `build/i386-c4-directory-owner-startup-8m`:
after startup source finishes, before the first command, allocation of 9480 bytes
fails with 9184 largest free payload, 6611464 raw bytes used out of 6634496 and
9514 allocations. This is not an 8 MiB interaction pass; the minimal profile
cannot be promoted. The independent older Console rebuild continues compiling
its embedded source epoch and provides no qualification for this new image.

## Shared original drive and device lookup (2026-10-16)

`DriveLookupCore.HC`, `BlockDevLookupCore.HC` and `DriveWritableCore.HC` share the
complete original Let2Drv, BlkDevChk, Let2BlkDev and DrvIsWritable routines.
Reinserting them and expanding the drive-table expression reproduces both
original DskDrv.HC and DskBlkDev.HC byte-for-byte; see
`build/i386-drive-lookup-extraction.json`. Native table access borrows current
file state and returns the mounted volume's persistent drive identity. A mounted
identity is initialized lazily if unused; an existing identity is not repaired by
lookup, so invalid signatures still reach original DrvChk. File service version
55 and Console version 115 include the new callback and four public exports.
The original Drv/media-initialization branches have not been replaced or removed.

The twelve shared cases in `i386-drive-lookup-reference/Contract.HC` cover
current/explicit/lowercase lookup, boot/home aliases, invalid-letter NULL and
exception results, NULL/bad-signature/out-of-range device validation, writable
and read-only states, the read-only exception, and invalid current drive
signatures through both implicit and explicit lookup. They check exception
identifiers, stable directory pointer/device identity, caller document roles and
exact caller heap usage. Device flags/signatures are restored after observing
results in the disposable guest. No writes are issued while testing flags.
All original masks are 31 in `build/i386-c4-drive-lookup-reference`; native
preflight fails on missing Let2Drv in `build/i386-c4-drive-lookup-red`.

The first extraction used function-style macro syntax unsupported by HolyC and
failed the original kernel build; its artifact is retained in
`build/i386-c4-drive-lookup-bootstrap-macro-red`. The corrected extraction uses
the same expression-macro convention as the existing boot/home drive aliases.
These cases do not qualify drive remapping, hot mounting, media initialization,
full Drv or directory-context integration.

The corrected original bootstrap passes both generations, and the shared
lookup fixture again returns twelve masks of 31 on that rebuilt system in
`build/i386-c4-drive-lookup-current-reference`. Both reference runs preserve
all inputs. `build/i386-c4-drive-lookup-cross` completes with 574056 kernel bytes,
1484 source and 24 build-input hashes matching, normal disk hash verified and
the limited 96-BIOS/255-protected-instruction boot audit passing.

All fifteen native commands pass at 64 MiB on TCG `486,-fpu` in
`build/i386-c4-drive-lookup-native`, including all twelve mask-31 cases. The
same image also passes all eight directory-ownership commands in
`build/i386-c4-drive-lookup-directory-owner`. Both runners verify unchanged
inputs and byte-identical delivered fixtures. Normal 8 MiB startup still fails
before the first command in `build/i386-c4-drive-lookup-startup-8m`: 9480 bytes
requested, 9184 largest free payload, 6611296 bytes used out of 6634496 and 9545
allocations. This does not promote the minimal profile or complete C1–C5.

## Filename and silent-output prerequisites (2026-10-16)

`FileNameCheckCore.HC` and `SilentCore.HC` hold the complete original
`FileNameChk`, `Silent`, and `IsSilent` bodies. The original kernel includes
those same files. Native ConsoleRuntime version 116 exports all three public
routines and imports the actual kernel `char_bmp_filename` allocation through
an additional loader binding. No separate filename table is used by the native
implementation. `build/i386-directory-prereqs-extraction.json` verifies exact
body identity and reconstructs both pre-extraction source files byte for byte.

The shared directory-prerequisites fixture checks null/empty names, dot names,
the 37/38-byte length boundary, all 255 non-NUL single-byte names against the
original bitmap values, input-string preservation, silent flag return values,
unrelated display flag preservation, and the real output hook chain. With
silence disabled the hook sees three keys and two strings; enabling silence
suppresses PutKey, PutChars, PutS and Print. The fixture restores the flag and
removes its hook. These are bounded prerequisites for directory contexts;
Drv media initialization and full DirContextNew/Del remain outstanding.

The first reference fixture failed to compile because HolyC does not accept
its initialized local array. The first correction was stopped after inspecting
the captured error, before another full timeout. The corrected fixture moves
the expected table to global storage, uses the actual flag bit index and gives
its output hook a valid positive priority. A subsequent reference compile
also rejected C-style ternary syntax; the final fixture uses ordinary HolyC
conditional returns. Both failed compile screenshots are retained.

Both original bootstrap generations pass with 1486 source hashes. The prior
native image rejects the IsSilent preflight in
`build/i386-c4-directory-prereqs-red` with unchanged inputs. The first new
cross-build compiled every module but the host packager rejected the added
bitmap import because its import allowlist had not yet been updated. That
artifact is retained in `build/i386-c4-directory-prereqs-cross`; the corrected
build updates the allowlist as well as the loader.

The corrected cross-build, `build/i386-c4-directory-prereqs-fixed-cross`,
passes with 575392 kernel bytes, 1486 source hashes and 24 build-input hashes.
The limited boot audit covers 96 BIOS and 255 protected-mode instructions.
Both `build/i386-c4-directory-prereqs-reference-green` (pinned original) and
`build/i386-c4-directory-prereqs-current-reference` (rebuilt original) pass
all eight mask-31 cases with unchanged inputs. The normal 8 MiB no-FPU startup
gate passes in `build/i386-c4-directory-prereqs-startup-8m`, with all nine
commands, exact VGA restoration and no build-provider load.

All eleven native commands pass in `build/i386-c4-directory-prereqs-native`
at 64 MiB on TCG `486,-fpu`, including all eight mask-31 cases. The runner
verifies unchanged inputs and the byte-identical delivered fixture. Startup
takes 59.092091 seconds in the separate normal 8 MiB gate. All 1510 cross-build
source/build pins still match. Inventory coverage and its five guard tests
pass, with all 686 items still unqualified.

## Drive-lock integration oracle (2026-10-16)

The next dependency is real lock integration, not just two public names.
Original `BlkDevLock` follows the controller-forwarding chain, waits while
another task owns the target and returns FALSE for same-owner reacquisition.
`BlkDevUnlock` only releases a lock held by the caller; its reset option clears
INITIALIZED and INIT_IN_PROGRESS, preserving other flags. `DrvLock` couples
that device lock to the public drive lock. `DrvUnlock` releases both.

The shared `i386-drive-lock-reference/Contract.HC` fixture observes twelve
cases: acquisition/reacquisition/unlock return values and fields; reset flags;
a two-hop controller-forwarding chain; bad signature/NULL exceptions;
non-owner unlock; competing task handoff; exclusion of a real FileRead;
normal task exit while owning a device; normal exit while owning a drive;
exclusion and persisted results of a real FileWrite; killed-owner cleanup; and cancellation of a waiting task without releasing
the current owner's lock.
Every case also checks restored caller directory text and drive identity, document
roles, released device ownership and exact caller heap recovery. The original
uses RAM drive B and the native runner uses its writable ATA drive C in a
disposable image. This is an explicit media-profile mapping, not RAM/ATA parity.
The fixture does not issue raw hardware commands or synthesize file results.

Integration points reviewed before implementation:

- `Kernel/BlkDev/DskBlkDev.HC` and `DskDrv.HC` contain the complete original
  lock/unlock routines; their forwarding and reentrant return behavior must be
  preserved.
- `Kernel/KTask.HC` releases drive/device locks during TaskEnd, and
  `Kernel/KExcept.HC` releases them for Break. The respective full release
  routines iterate the canonical device and drive registries.
- `Kernel/I386/AtaChannel.HC` currently provides a separate nonrecursive FIFO
  channel gate with cancellable waiters. `RedSeaTaskBegin/End` use it directly;
  neither checks the public device/drive lock fields. Public locking must
  coordinate with this gate before actual file transactions can claim parity.
- `CI386FileVolumes.drives` and each mounted volume's `disk->public_device`
  provide stable public identities. They must participate in task cleanup as
  well as I/O exclusion. The existing native owner-retirement hook presently
  concerns render/document lifetime; simply exporting original lock bodies
  would leave file exclusion and task cleanup incomplete.

The first reference compile failed because its exception identifier exceeded
HolyC's eight-byte character-literal limit. The screenshot and failed run are
retained in `build/i386-c4-drive-lock-reference`; the fixture now uses DrvLock.
The prior native preflight rejects the missing BlkDevLock binding in
`build/i386-c4-drive-lock-red`. No runtime lock implementation or directory
context completion is claimed by this oracle checkpoint.

The next reference run reached setup and exposed a fixture assumption about
FileWrite: the original returns its starting disk block, not a byte count.
The corrected fixture requires a positive result and verifies the real file's
size and bytes by readback. It compares restored directory text rather than
allocation identity because original file operations can replace cur_dir.
`build/i386-c4-drive-lock-reference-block-result` passes all eleven initial
mask-31 cases with unchanged inputs. The expanded fixture adds waiter kill.
These failed fixture attempts do not indicate runtime implementation failures.

The final twelve-case oracle passes against both the pinned original in
`build/i386-c4-drive-lock-reference-cancel` and the current rebuilt original in
`build/i386-c4-drive-lock-current-reference`. Every result is 31, and both
runners verify unchanged inputs. This establishes real lock exclusion and
cleanup behavior to preserve; it does not qualify the native implementation.
Break cleanup, remapping, additional controller/media profiles and the complete
Drv/DirContext workflows still need executable coverage.

`build/i386-c4-drive-lock-final-red` uses the final shared fixture and rejects
the BlkDevLock preflight with unchanged inputs. Inventory coverage and all five
guard tests still pass. No OS source changed in this checkpoint, so the prior
bootstrap, cross-build and 8 MiB startup artifacts retain their source scope.

## Native lock integration implementation (2026-10-16)

The complete original device/drive lock, unlock and release routines now live
in four shared cores. Reconstruction in `build/i386-drive-lock-extraction.json`
confirms the two original containing files byte for byte. Native release scans
resolve the mounted canonical drive/device records; empty slots use zeroed
records. ConsoleRuntime exports the original public functions and invokes the
release routines before its existing owner-retirement work, including before
waiting for descendants. Its Break checkpoint also releases public locks.

Mounted devices on one ATA controller forward to one public device lock.
Physical transactions participate in that ownership rather than running behind
an unrelated gate. Existing physical-session waiters retain channel queuing
and cancellation. A retained outer public lock wakes queued transactions to
retry without reserving the channel against its owner. A file operation waiting
on a public owner keeps its borrowed state protected, observes kill requests,
and unwinds normally instead of exiting with that borrow pinned.

RedSea sessions also track the canonical public drive. This matters because
the original DrvUnlock releases its device even if the caller had already held
only the device lock. The first new reference assumption that FileRead would
preserve such a device lock was wrong; the captured original result is retained
in `build/i386-c4-drive-lock-reference-io-kill`. The isolated oracle now has
fourteen cases, adding killed file-reader cleanup and FileRead's release of an
outer device lock. It restores device flags between cases: killing a RAM-drive
reader during entry can leave initialization flags changed before it acquires
the device, an effect outside this lock-only fixture. This is not a claim of
interrupted media-initialization compatibility.

`build/i386-c4-drive-lock-reference-isolated` passes all fourteen mask-31 cases.
The native code is still under validation at this checkpoint. It does not yet
qualify remapping, unmounted devices, all media initialization or full directory
contexts. The ATA foundation fixture enables the same RedSea lock adapter used
by the native kernel so existing queued cancellation/publication checks exercise
the integration rather than bypassing it.

The first integrated native compile failed on two NULL tokens in foundation
files that do not import that macro. These adapter assignments now use 0; the
original shared routine bodies remain unchanged. Failed compiler artifacts are
`build/i386-c4-drive-lock-cross` and
`build/i386-c4-drive-lock-ata-compile-red`.

The older independent C5 native-build process stopped after 449 function starts
at GrPlot3 without a terminal runner report or completed module. Its prior PIDs
and exec handle no longer exist; `process-exit-observation.json` beside its
artifacts records this observation. The cause is not established and the stale
running report is not qualification evidence. No replacement run is counted.

The native fixture first hit the unrelated missing MemCmp public binding.
Its independent four-byte comparisons now avoid that dependency while retaining
exact content checks. A later run completed every case but timed out at cleanup
because the harness expected no output from a pointer assignment; the captured
screen shows its correct 0x0 result. The final harness expects that value.
Artifacts `-native` and `-native-bytes` retain both failures.

The ATA fixture required its canonical intrinsic declarations and a larger
test-only transport. Its 536018-byte runner now fits the 1048-sector allowance:
code ends below 0x93000, the unchanged 32 KiB root stack ends at 0x9B000, and
descriptor scratch remains at 0x9C000. Production boot defaults, RAM and task
stacks are unchanged. The staged compile/size/reservation failures are retained.

Validation now passes:

- Both original bootstrap generations; 1490 source hashes.
- Final cross-build `build/i386-c4-drive-lock-reservation-cross`: 578136 kernel
  bytes, all 1490 source and 24 build-input pins matching, limited boot audit.
- Pinned and rebuilt original fourteen-case controls in `-reference-bytes` and
  `-final-reference`, with unchanged inputs.
- `build/i386-c4-drive-lock-native-green`: nineteen commands at 64 MiB on
  TCG 486,-fpu, all fourteen masks 31, unchanged inputs and byte-identical
  delivered fixture.
- `build/i386-c4-drive-lock-ata-green`: 8 MiB ATA/channel/file publication and
  cancellation suite with instruction audit. Independent ISO inspection checks
  all 808 delivered Kernel/Compiler/fixture HolyC sources.
- Normal 8 MiB startup in `build/i386-c4-drive-lock-startup-8m`: nine commands,
  55.797052 seconds, exact VGA restoration and no build-provider load. The three
  candidate images are byte-identical across test-transport harness updates,
  recorded in `build/i386-c4-drive-lock-image-identity.json`.
- Inventory coverage and five guard tests; all 686 entries remain unqualified.

ConsoleRuntime is version 117 and FileRuntime version 56. The broader public
kill regression passes all nine cases at 64 MiB in
`build/i386-c4-drive-lock-kill`, with its source disk unchanged. This checkpoint still does not qualify every lock-state
combination, drive remapping, unmounted devices, Break end-to-end behavior,
interrupted media initialization, full Drv/DirContext or C1-C5 completion.

A replacement C5 selected-module build is live in
`build/i386-c5-drive-lock-native-build`, on the verified current image at
16 MiB, TCG 486,-fpu. Its detached launcher PID is recorded beside the output
folder. This remains pending evidence; the selected-module run does not by
itself satisfy two complete native release generations.
