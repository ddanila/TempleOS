# Deferred parser-storage experiment

This experiment is **not retained in production**. The allocator changes were reverted to CompilerRuntime 72 before the separate
immediate-push encoding work. CompilerRuntime 73 now identifies that encoding
change; it does not include this experiment. Its patch is preserved in
build/i386-parser-scratch-experiment.patch; the candidate images and failure
reports below remain available. The patch also requires changing the builder's
expected compiler service version to 73. It has no 8 MiB or full 16 MiB
qualification.

The experimental CompilerRuntime 73 places the frontend's temporary parse/output records, including top-level command staging, on the
existing tracked task-page allocation path. I386ParserScratchAlloc wraps
I386ParserCodeAlloc with exact zero-initialization. The expression stack uses
the same helper instead of its previous inline allocation/zero loop. The two
frontend records continue to be released by I386FrontendFree and control unwind;
normal parser symbols, publication ownership and executable output are unchanged.
Controls without task heaps retain I386ParserCodeAlloc's arena fallback. This
is a storage change, not a reduced record layout or reduced compiler behavior.

## Reproducer

Adding the complete original device-wide drive deletion exposed the 8 MiB
profile's lack of arena headroom. The initial wrapper candidate fails a 537-byte
parser request in build/i386-c4-drive-device-delete-startup. Removing redundant
wrappers and passing the canonical table through console configuration reduces
the retained footprint, but ...drive-device-delete-config-startup still fails
while compiling StrCmp(SPText(),"VGA")==0: a 470-byte request with a largest free
block of 336 bytes. Disassembly confirms that 470 is the frontend output record's
non-helper prefix size. Neither failure is a startup timing failure.

An instrumented compiler in ...drive-device-delete-trace-cross changes the
footprint and fails earlier, on SPNext(), requesting 126 bytes with only an
88-byte largest free block. Its captured stack maps to I386ParserAlloc,
I386FrontendAlloc and I386FrontendCalls. This is diagnostic evidence of temporary
frontend arena pressure, not an equivalent performance/acceptance candidate.
The trace flag is removed from production. Addresses and mapping are retained in
build/i386-drive-device-delete-allocation-audit.json.

The parser already placed its expression stack on reserved task pages. The new
helper applies that established path to both temporary frontend records, making
room for ordinary arena allocations without raising RAM or weakening cleanup.
Their requested sizes and zero-filled contents remain unchanged. Public-page
ownership stays with the originating control, so exceptions use the same tracked
release path as normal teardown.

An intermediate migration covered expression compilation and output but missed
the separate top-level command allocation of CI386FrontendParseBound. It still
fails a 537-byte request on the same command in
...drive-device-delete-scratch-startup. The final change covers that third
allocation site as well; all allocations of both temporary record types now
use the tracked task-page path.

After all three record sites were migrated, ...command-scratch-startup reaches
an earlier 132-byte intermediate-code allocation failure on the same command.
The recorded callers resolve to I386ICAddBytes and I386FrontendAdd; the largest
free block is 88 bytes. Private frontend intermediate-code nodes now use
I386ParserCodeAlloc too, before graph registration. Their existing compact size,
ICSeed initialization and embedded code-lifetime record are preserved. The
allocation's parser record owns it even if a later operation throws. Allocation
occurs before the graph's IRQ guard so allocation exceptions restore caller IF.

Node lifetime lookup accepts the control's tracked logical allocation size;
ordinary full-size nodes retain arena-size validation and allocation. The
existing exact parser-size validation is shared through I386CmpAllocationSize
in the control layer, keeping standalone control implementations independent
of the frontend allocator. Normal discard and exception cleanup detach the
embedded graph record, then release both the task-owned payload and parser
tracking record through the established owner-aware path.

The experimental bootstrap, cross-build and standalone public control test pass
in ...drive-device-delete-owned-ir-cross and ...owned-ir-control. However,
...owned-ir-startup still fails on the same command: a 159-byte emitter buffer
with only a 112-byte largest free block. No full diagnostic qualification was
attempted for this experiment. Extending allocation migration further would
change a wider compiler ownership surface without yet restoring the minimal
profile, so the experiment is deferred while the new drive interface is
simplified to direct table access.

The production C5 native build remains pinned to CompilerRuntime 72 and commit
0bed4c3a. These experimental changes did not alter its immutable source image.
