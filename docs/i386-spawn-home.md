# Public Spawn home-directory initialization

Original Kernel/KTask.HC TaskInit chooses blkdev.home_dir and its mapped drive,
independently of the selected parent’s current directory. The native public
Spawn previously inherited its parent's file context through the private task
constructor. This is a C1/C4 compatibility candidate, not full TaskInit parity.

The seven-case original oracle covers an explicit caller parent, the default
parent, another live parent in a different directory, dormant construction,
an external mapped home record, an invalid parent drive record and a NULL
parent directory. It checks the child drive/directory, selected parent, absolute
filename and real file contents, caller context/heap preservation, retirement
and mapping restoration. Each case requires mask 63. Both the pinned original
and rebuilt-original controls pass all seven cases with unchanged inputs
(build/i386-c4-spawn-home-reference-complete and
build/i386-c4-spawn-home-shared-current). The old native image fails the first
case (build/i386-c4-spawn-home-native-complete-red).

Fixture development exposed two original semantics: the boot home can be on
read-only CD media, and bare FileNameAbs("~") names a file rather than selecting
the home directory. The original control therefore temporarily configures a
writable B:/SpawnHome and resolves FileNameAbs("~/"). Earlier invalid fixture
runs are retained separately and do not count as compatibility failures.

MemoryRuntime 29 supplies a retained public birth hook; FileRuntime 61 installs
it after successful provider initialization. Public Spawn requests home-based
file construction, while private callers retain parent-context cloning. The
constructor keeps existing allocation and rollback ownership. Public birth
validates the private state without requiring a usable parent current directory.
The configured home record is selected through the independent drive map.

The loader adds the Memory-owned hook by name after 38 indexed bindings. The
binding checker validates named slots, stack/load counts, indexed capacity and
function-pointer imports. Its first rejection exposed both the old static
count assumption and an actual indexed-capacity mismatch; both were corrected.
Deliberate missing/wrong hooks, slot gaps and capacity errors are rejected.

Bootstrap and the native cross-build pass for the final constructor layout
(build/i386-c4-spawn-home-private-abi-cross). The private I386TaskCreateFrom
signature is preserved; public birth uses the explicit I386TaskCreateWithFiles
entry point, sharing existing allocation and rollback ownership. The native
seven-case oracle passes with unchanged execution inputs
(build/i386-c4-spawn-home-native-private-abi). The standalone ATA/task regression
also passes. The final drive-map/root-growth regression passes with unchanged inputs and
exact readback of all 83 files (build/i386-c4-spawn-home-drive-map-private-abi).
Public task lifecycle for this revision is in progress; the preceding candidate
passed it at 8 MiB. Memory gates remain pending.

The standalone private task regression exposed a pre-existing fixture dependency:
AtaChannel.HC now uses Bt/LBts/LBtr, but this fixture omitted their declarations.
The guest entered its debugger at the Bt call. Rebuilding and testing committed
4f4b4c48 independently in /tmp/templeos-spawn-home-baseline reproduces the same
failure. Diagnostic barriers confirmed the constructor bodies compile; they
have all been removed. The fixture now includes Bits.HH. The private task suite passes
(build/i386-c4-spawn-home-tasks-final), as does the retained task-core variant
(build/i386-task-runtime-core-test).
The earlier hypothesis that an added callback argument caused this failure was
not supported by that baseline comparison.

All 686 inventory entries remain unqualified; C1–C5 remain open. Configured-home
initialization is a bounded compatibility contract, not complete TaskInit parity.
