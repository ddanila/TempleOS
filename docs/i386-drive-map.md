# Drive-letter mapping across filesystem operations

Original DrvMap changes blkdev.let_to_drv and the target record's drv_let. It
resolves current, boot and home aliases, accepts lowercase, and returns FALSE for
an invalid letter before touching its target. It does not relocate canonical
records, validate their signature, or require that the target belongs to the
canonical table. Multiple letters can still point to one record; the most recent
mapping sets the letter reported by Drv2Let. A current task keeps its CDrv pointer
even when that letter's mapping changes.

## Original baseline and native failure

Fifteen shared cases cover uppercase/lowercase mapping, invalid letters, an
invalid-letter/null-target call, replacing a mapping through an external record,
current/boot/home aliases, invalid-signature records, canonical-record preservation, mapped FileRead/FileFind (also through an external
copy of the mounted record),
FileWrite observed through the original letter, Cd and relative FileNameAbs,
DirMk and nested writes, and a child task explicitly entering the mapped directory.
The fixture restores every mapping and the backing record's letter. Pure mapping
cases compare every canonical CDrv byte; I/O cases allow legitimate cache updates
while checking unrelated letters, caller folder/document state and heap balance.
Printed directory-creation output is captured in a temporary document and reclaimed.

Both original controls pass every mask-31 case with unchanged inputs:

- build/i386-c4-drive-map-reference-complete/result.json
- build/i386-c4-drive-map-current-complete/result.json

The first fixture run retained DirMk's printed document entries and incorrectly
assumed original Spawn inherited its parent's current directory. Those failures
remain under the unsuffixed -reference/-current paths. Original TaskInit chooses
the configured home drive/directory. The corrected child explicitly calls Cd;
this test qualifies cross-task visibility of mappings, not task-birth directory
semantics. Public task initialization needs a separate comparison with the native
private-context cloning policy.

ConsoleRuntime 125 rejects the native preflight because DrvMap is undefined,
before any table mutation (build/i386-c4-drive-map-native-complete/result.json),
with unchanged inputs. The native runner additionally requires
exact Seed.TXT, Write.TXT and Sub/Child.TXT contents in the backing disk image.
Those checks have not run successfully and are not counted as qualification.
The added invalid-signature case confirms mapping succeeds but non-throwing
lookup rejects the mapped record. A first version used a conditional expression
rejected by the original compiler; that fixture-only failure remains under the
-signature paths. The corrected ordinary-if version passes both controls.

## Native mapping candidate

The initial native system combined physical-volume indexing with public letters.
The candidate separates those identities and routes filesystem operations through
the mapped record. Its implementation requirements are:

- Preserve canonical drive identities and introduce a lifetime-stable letter map;
  slot preparation/search must continue to operate on physical records.
- Route public lookup and every filesystem consumer through the mapping, including
  FileContext, TaskFileFind, TaskFileWrite, TaskCd, task context construction and
  boot/install helpers. Raw volume-letter indexing must not bypass remapping.
- Derive the current logical letter from the actual CDrv, rather than its physical
  array index; preserve the current record independently from later map changes.
- Preserve original acceptance of external records for mapping/lookup. Mount and
  backend resolution must respect the device/volume represented by a drive instead
  of silently restricting the public API to pre-existing array entries.
- Keep one public device/drive identity through channel locking, deletion,
  publication and task lifetime. Test mapped reads, writes, directory changes,
  child-task access and exact persisted output on the delivered native image.

ConsoleRuntime 126 now shares the original DrvMap body with only its mapping
storage expression adapted. FileRuntime 60 owns the independent 26-pointer map,
initialized to the canonical records just as in BlkDevsInitAll. Physical slot
preparation stays on the canonical table. Logical lookup does not republish
records cleared by DrvDel. Current-directory letters follow the current record;
private context cloning preserves that pointer even if its letter is remapped.
This does not change the separately unqualified public Spawn initialization policy.

Read/find/write, directory creation/deletion, rename/move, Cd, installation and
BuildRuntime 3 staging/publication now resolve mapped device and mounted extent.
External records borrow operation-owned RedSea views with their own public-drive
lock identity and a pointer to the mounted backend; native build stages retain their view through cleanup. Uncertain
mutations through views quarantine the matching shared backend. Retained views
reject backend quarantine, including after channel acquisition; they refresh
the public root and reject deleted records before I/O. CompilerProbe 19 carries
the changed RedSea layout. Mapping and
lookup accept external records; I/O still requires a supported mounted backend
with matching device, offset and size; the mapped record supplies the root,
which must be within the mounted extent. Root growth updates that public record. General mounting and additional
filesystem types remain separate work.

The first candidate passes the 15 native cases and exact persisted files
(build/i386-c4-drive-map-native), but the slot regression exposes a boot/home
alias incorrectly depending on the current record's signature. The corrected
alias/explicit-lookup helpers access task configuration independently. The new
mapped root-growth regression rejects that first image after root relocation
(build/i386-c4-drive-map-root-red); it requires 80 exact files through both
letters and a changed public root cluster.

The final cross-build is build/i386-c4-drive-map-lifetime-cross; all
1511 source and 24 build inputs match. The rebuilt-original control passes all 15 cases
(build/i386-c4-drive-map-current-lifetime). The 42-case slot regression also
passes (build/i386-c4-drive-map-slot-lifetime).

The ATA/task regression passes with an added retained external-record view and
failed-cleanup quarantine/retry case (build/i386-c4-drive-map-ata-lifetime).
It checks all 20 additional ATA commands, exact 32 MiB backing bytes, owned
reservation recovery, locks and heap balance. It additionally rejects backend
invalidation both before and during channel acquisition, refreshes a retained
root and rejects a deleted mapped record without issuing disk commands. Fixture remounts now explicitly
republish canonical drive records. An initial compile failure exposed a missing
forward declaration for the shared quarantine helper; its snapshot remains under
-drive-map-ata-forward-declaration-failure. The first expanded transport run
correctly rejected the previous command-stream expectation; that artifact remains
under -drive-map-ata-mapped-old-expectation. The final cross-build includes the updated exact command expectations and
counters in its pinned build inputs.

The final native lifetime image passes the 15 mask-31 mapping cases plus mapped
root growth in 22 commands, with exact readback of all 83 persisted files
(build/i386-c4-drive-map-native-lifetime). The 56-case/59-command drive-deletion
regression also passes (build/i386-c4-drive-map-delete-lifetime). All final native
runs preserve their execution inputs. The memory gates will use an isolated
committed source snapshot; they are not yet counted as passing. The original controls establish a
C1/C4 baseline, not complete mounting qualification. C1–C5 and all 686 inventory
qualifications remain open.
