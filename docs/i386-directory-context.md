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
* `I386TaskFilesNew` embeds the directory string immediately after its state
  allocation. Canonical context deletion's initialization-in-progress branch
  frees/replaces `Fs->cur_dir` directly. That branch cannot safely use an interior
  pointer owned by the task file-state allocation. Resolve ownership and keep
  the public directory/drive fields synchronized with internal file operations.
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
