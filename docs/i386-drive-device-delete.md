# Complete original device-wide drive deletion

ConsoleRuntime 122 shares the complete original DrvBlkDevDel body through
Kernel/BlkDev/DriveDeviceDeleteCore.HC. It walks all DRVS_NUM records and calls
the complete original DrvDel for every record whose bd pointer equals the
argument, including a null argument. Only the table-access expression is adapted;
the extraction audit verifies the rest byte for byte against the original body.
All 304 native Console export names have corresponding bindings.
NativeDriveRecords aliases the table-pointer field in the kernel-owned console
configuration; it does not require a retained getter function.

The console configuration carries a borrowed pointer to the actual canonical
drive table. The kernel configures it before console initialization; the table
shares the kernel lifetime. FileRuntime remains version 58. Indexed
record access includes unmounted, unpublished and deleted records and does not
depend on the caller having a valid directory context. Mounted-letter lookup keeps its separate semantics.
Task-exit drive release now indexes canonical slots directly as well. Console
initialization requires a non-null table before installing the task-retirement
hook, so the old lookup wrapper and dummy drive record are unnecessary. The physical block-device array and complete
BlkDevsRelease representation are still separate unfinished work.

## Contract and evidence

The shared fixture saves and temporarily populates all 26 actual drive slots,
then restores every original byte. Its original adapter uses blkdev.drvs; the
native adapter reads the NativeDriveRecords data alias. Neither adapter creates a replacement
table. Every slot is first obtained with the caller directory and drive fields
temporarily cleared, proving that table access is independent of those fields. Four selection patterns cover no matches, every slot, alternating slots,
and both boundary slots A/Z. Each runs with a real device and with a null
argument. Matching records have optional FAT/info allocations and, with a real
device, allocated RedSea free-list nodes. Nonmatching records must remain
byte-identical. Assertions cover complete matching-record clearing, exact caller
heap recovery, device flags/locks, repeated deletion and caller directory and
document state. The task owner/window manager are suspended while real table
records are borrowed, after command input settles.

The pinned original passes all eight mask-63 cases with unchanged inputs in
build/i386-c4-drive-device-delete-reference. The preceding native image rejects
the missing private function at preflight in ...drive-device-delete-red, with
unchanged inputs; no behavioral case runs there. The native fixture delivers
both the common contract and its small table adapter and checks both byte for
byte after execution. The expanded context-independent fixture also passes on the pinned and rebuilt
original in ...drive-device-delete-context-reference and ...context-current.
The final corrected image and its qualification are recorded below.

The first implementation retained separate initialization and table-access
wrappers in FileRuntime. Its 8 MiB gate fails while compiling
StrCmp(SPText(),"VGA")==0: a 537-byte request, heap used 0x64F968, heap limit
0x652600 and largest free block 0x168. This is a real allocation failure,
not a timing failure. Evidence is ...drive-device-delete-startup. The dependent
16 MiB diagnostic run was deliberately cancelled and its reason recorded in
...drive-device-delete-diagnostics/cancellation.json. The final implementation
uses the borrowed table pointer described above, removing redundant retained
wrappers without changing the complete table walk or caller independence.
The intermediate ...drive-device-delete-table-cross candidate incorrectly put
that data pointer in the retained File service table; the unchanged loader
correctly rejects it as an invalid service address in ...table-startup. Moving
the pointer to the console's existing data configuration preserves the service
validator's function-pointer-only contract. Both failed candidates are retained.

The first wrapper image passes all eight native cases/11 commands at 64 MiB,
with unchanged inputs and exact delivery of the common fixture and adapter, in
...drive-device-delete-native. It also passes the nine public task-cancellation
cases in ...drive-device-delete-task-kill with its source disk unchanged.
The final configuration candidate also passes those eight native cases and
nine cancellation cases in ...drive-device-delete-config-native and
...config-task-kill, but still fails the 8 MiB parser-allocation gate. These
64 MiB results do not qualify its minimal-memory profile. A broader compiler-storage experiment also failed the minimal-memory gate and
was reverted; see [i386-parser-scratch.md](i386-parser-scratch.md). The allocator experiment was reverted completely. The final candidate exposes the table pointer as a
data alias and indexes it directly, removing the unnecessary getter without
changing the complete original routine. The export correction and final
qualification are recorded below.

An initial cross-build invocation preceded bootstrap completion and stopped
before compilation because build/rebuild-test/result.json did not yet exist.
Its launcher log is /tmp/drive-device-delete-cross.log; it is not qualification.
Subsequent cross-builds use fresh evidence directories after bootstrap completion.

This implements the entire original table-walk routine. It does not establish
full drive/media initialization, mounting/remapping, Drv/DirContext, application
compatibility or C1-C5 completion. All 686 inventory entries remain unqualified.

The canonical direct-table candidate (...drive-device-delete-canonical-cross)
passes bootstrap and cross-build but still fails the 8 MiB interactive gate on
StrCmp(SPText(),"VGA")==0: an emitter request of 159 bytes with a largest free
block of 88 bytes. Its Console module adds only 711 bytes over 5ad1185f, but that
is enough to exceed the available arena headroom. CompilerRuntime 73 therefore
introduces a separate immediate-push encoding reduction. The final cross-build
passes with unchanged inputs, and its 8 MiB gate passes all nine checks at
54.195792 seconds in ...drive-device-delete-push-startup. That image precedes the Console binding correction below; see [i386-immediate-push.md](i386-immediate-push.md).

The first data-alias fixture exposes an initialization-order bug in the export:
ConsoleDocExportSet used &console_config->drive_records before console_config
was assigned. The ...bound-addresses diagnostic confirms the published field address is
0xC; the supposed table pointer reads the unrelated low-memory value 0xF000FF53.
The ...push-native, ...canonical-native and ...bound-native runs fail the
all-match heap assertion; diagnostic masks are 43. Apparent heap deltas vary
(1024 and 14240 bytes) because the fixture accessed the wrong memory; they are
not evidence of a deletion leak. The ...push-layout control proves sizeof/stride
are both 136 bytes but slot C does not equal Fs->cur_dv. Changing plain extern
to explicit _extern alone did not resolve the defect. The repeated-mask probe
stopped at its unexpected delta and did not execute its second deletion call.

The export now uses &config->drive_records, borrowing the already validated
initializer argument. Native.HC retains explicit system-symbol binding, and the
native runner first asserts that the indexed current-drive slot equals
Fs->cur_dv before any table mutation. The final runner has 12 commands. Both bootstrap generations and the corrected cross-build pass in
...drive-device-delete-binding-cross, with 1506 source/24 build-input hashes
unchanged. Only ConsoleRuntime differs from the previous image, at the same
module size. The rebuilt-original oracle passes all eight cases in
...binding-current. The unchanged native runner rejects the faulty image at
its new identity check in ...identity-red, before any table mutation, with
unchanged inputs. The corrected 8 MiB image passes all nine checks at 56.954345 seconds in
...binding-startup, with four execution inputs unchanged and no build provider.
C5 was paused for the timing run and resumed. The final native runner passes all eight cases/12 commands at 64 MiB in
...final-native, with exact common-fixture/adapter delivery and unchanged inputs.
The canonical identity check passes before any table mutation. The final image also passes all 56 existing DrvDel/mounted-identity cases
(59 commands) in ...final-drive-regression with unchanged inputs. All nine public task-cancellation cases also pass in ...final-task-kill with
the source image unchanged. The final 16 MiB gate passes in ...final-diagnostics, startup 246.119320
seconds: both memory-preservation phases, 128 immediate-push cases, 32 backend
cases, 22 publication/28 program cases and all nine interactive checks. All
four execution inputs remain unchanged. This is the corrected Console image.
