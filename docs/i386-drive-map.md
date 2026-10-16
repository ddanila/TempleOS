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

## Required implementation

Native CI386FileVolumes currently combines a physical-volume array indexed by
letter with canonical CDrv records. It has no independent letter-to-record map.
Adding only DrvMap and changing Let2Drv would leave actual I/O on the wrong volume.
The migration must:

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

The native implementation remains missing. These controls are a C1/C4 baseline,
not a completed letter-map migration or complete mounting qualification. C1–C5
and all 686 inventory qualifications remain open.
