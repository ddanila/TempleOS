# Owned document text capacity

The canonical transcript checkpoint introduced an 8 MiB background compile/edit
regression. A host-only QMP snapshot stops at the first raw heap failure without
changing guest code. Its capture/inspection scripts and hashes are preserved in
`build/i386-c2-background-pressure`. All five detected live task heaps have no
wholly free page blocks to return; spare space is fragmented within live heaps.
This rules out simply trimming empty heaps as a recovery for that observation.

The main console heap has 36,352 allocated bytes and 26,632 used bytes in that
snapshot. The observed background and foreground heaps respectively have
41,984/40,760 and 8,704/3,408 allocated/used bytes. These are observations at the
captured failure, not final requirements or a proof that cache reclamation
alone would fix the workload.

## Edit behavior and safety

The ordinary-text edit core formerly allocated and copied a new tag on every
character insertion. It now reuses owned ordinary tag capacity when it contains
room for the added character and NUL. Backwards shifting preserves middle
insertion. Full buffers still allocate before publication; an allocation failure
leaves the old tag intact. Contents, cursor updates and document ownership are
preserved. Buffer pointer identity can remain stable for more edits, and the
reserved capacity can remain larger after deletion/reinsertion; size queries
still report the actual allocation.

Aligned pointers require a conservative path. Original `_MSIZE` in
`Kernel/Mem/MAllocFree.HC` and the native memory service both report the base
object's capacity. That cannot establish writable bytes after an interior
aligned pointer. The edit core checks the canonical negative size marker and
copies aligned tags instead of reusing their apparent spare capacity. It does
not change public MSize or aligned-allocation semantics.

The allocation-failure probe now fills a tag to its actual four-byte capacity
(`abc` plus NUL) before injecting the growth failure. It still verifies unchanged
text, lock release and heap accounting, and successful subsequent growth/save.
It does not require an allocation when owned spare space already exists.
Console interface version is 72.

## Test-first evidence

`tools/test-i386-doc-capacity.py` requires append reuse, safe overlapping middle
insertion, full-buffer growth, conservative aligned-tag copying and the existing
thirteen allocation/unwind checks. The initial candidate rejects append reuse
in `build/i386-c2-doc-capacity-red-v2/result.json`. A preliminary implementation
passes the ordinary cases but fails the aligned-pointer test in
`build/i386-c2-doc-aligned-red/result.json`; the guard is added before committing.
The first oversized test command was rejected by the harness's 255-byte limit
and is not the behavioral baseline.

The preliminary ordinary-capacity candidate does **not** restore the background
workflow at 8 MiB (`build/i386-c2-doc-capacity-checks/result.json`); its startup
and transcript checks pass, but the concurrency stage still reports OutMem.
No history or graphics is removed, and the legacy test remains enabled.

## Next architectural work

Allocation churn is only part of the resident-memory problem. Export-boundary
inspection finds 52,279 bytes of code in nine allocation/round-trip diagnostic
routines, including DocAllocationCheck, permanently resident in the console.
The report is `build/i386-c2-background-pressure/diagnostic-footprint.json`.
It excludes strings/data and operational dependencies, so it is a list of
separation candidates rather than a verified removable-byte count.

Review moving diagnostic routines into explicitly loaded test support, retaining
fault hooks and all existing assertions. Prove that normal images still exercise
the operational APIs, test support is absent until requested and unload/recovery
returns its resources. Include diagnostic support in native build/install
manifests and successive-generation tests rather than silently omitting it.
This follows the existing normal/diagnostic boot separation and preserves the
original desktop/API scope; it is not implemented or qualified here.

## Guarded candidate verification

The guarded source bootstraps/rebuilds twice and passes the cross-build and 386
loader audits in `build/i386-c2-doc-capacity-safe-cross`. All eleven capacity
commands pass, including aligned copying and the thirteen-case allocation
probe (`build/i386-c2-doc-capacity-final-checks/capacity-64m/result.json`).
The existing document group passes all 33 commands, and all thirteen transcript
commands pass at 64 MiB. Input preservation is recorded in their reports.

The nine-command 8 MiB startup gate passes in 43.7029 seconds with no build-only
provider loads. Background compile/edit/save passes at 64 MiB, with persisted
`work\x05`, continued compilation, exact VGA and parent heap recovery. The
8 MiB concurrency regression remains open; these positive gates do not override
its failure or qualify C1–C5.

The final aggregate `build/i386-c2-doc-capacity-final-checks/result.json` reports
failure solely because its 8 MiB background stage still fails. All five other
stages pass. The guarded candidate preserves the captured OutMem and timeout
in `background-8m/result.json`; it is not a restored concurrency qualification.
Future diagnostic separation remains planned, not an implemented memory fix.

## On-demand diagnostic candidate

The follow-up candidate uses console interface 73 and adds
`Kernel/I386/DocDiagnosticRuntime.HC`. The public resident dispatcher loads its
checks only when requested, passes operational callbacks through a versioned
context, and releases the image after execution. Fault injection is scoped to
the diagnostic task; clipboard checks use a private clipboard. A resident task
cleanup callback owns the temporary image. All fourteen disk modules are
included in the updated build/install/package/generation manifests.

`tools/test-i386-doc-diagnostic-separation.py` rejects the preceding resident
image in `build/i386-c2-doc-diagnostic-red/result.json`. Its positive gate requires
check bodies outside ConsoleRuntime, no diagnostic load during boot, thirteen
checks per invocation and balanced repeated load/unload. Forced cancellation,
reentrancy, exhaustive module ABI auditing and native-generation qualification
remain open. This candidate does not yet establish recovery of the 8 MiB
background workflow.

The candidate passes the original two-generation bootstrap and 386 cross-build
in `build/i386-c2-doc-diagnostic-verified-cross`. Its focused delivered-module
test passes in `build/i386-c2-doc-diagnostic-verified-test`: no diagnostic boot
load, two invocations returning thirteen checks, balanced loading/unloading and
unchanged inputs. The nine-command 8 MiB startup suite passes in 41.7076 seconds
in `build/i386-c2-doc-diagnostic-startup-test`, with exact VGA checkpoint matches.
These focused results do not qualify the pending lifecycle/native-generation
work or restore the background concurrency gate by inference.

## Recovery and native component evidence

The two fault variants in `tools/test-i386-doc-diagnostic-recovery.py` pass:
wrong target (`build/i386-c2-doc-diagnostic-recovery-target`) and missing exception
import (`build/i386-c2-doc-diagnostic-recovery-import`). Each session rejects two
calls, accepts an arithmetic command, repairs the persisted module byte-for-byte,
and completes two thirteen-check invocations with balanced load/unload. The
input image, checker and supporting tools remain unchanged. These observations
cover retry after load rejection, not forced cancellation or reentrant loading.

The guest-native build at 16 MiB passes with 28 exports matching the cross-built
contract (`build/i386-c2-doc-diagnostic-native`). Its 65,753-byte module is installed
by the guest, then rebooted and exercised at 8 MiB; thirteen checks and unloading
pass (`build/i386-c2-doc-diagnostic-native-install`). This does not establish full
two-generation qualification or binary identity with the cross-built artifact.

The background workflow still fails at 8 MiB on the separated candidate
(`build/i386-c2-doc-diagnostic-background-8m`). Frame checkpoints reach editing,
save and compiler-progress verification. Heap exhaustion appears around stopping
the compiler, followed by an OutMem rejection of the terminal cleanup command
and a timeout. At the first recorded failure, request 0x2233 exceeds largest free
block 0x1618, with heap usage 0x6523C8 / 0x656000. Source disk preservation passes;
child completion and parent heap recovery do not. The regression remains enabled.
