# Compact private archive expansion

The 8 MiB diagnostic previously failed after phase-one DISK READ when archive
expansion requested a 65,676-byte control. Its largest free block was smaller
than that request. Moving allocations to the high end did not help.

The private whole-buffer reader now uses 4,096-entry U16 prefix, next-link and
hash-head arrays, a byte suffix array, validity bits and the 4,096-byte expansion
stack in one 33,328-byte allocation. Links encode index+1, retaining zero as the
null link. The original bit-width transitions, dictionary leaf-recycling order,
current-entry special case, chain validation and trailing-bit rule are retained.

Public CArcCtrl layout, the compression format, compression implementation and
streaming ArcExpandStep remain unchanged. Only I386ExpandBuf's temporary private
workspace changes. Its returned allocation, size/NUL contract, failure cleanup
and interrupt-state preservation remain the same. The workspace consumes 33,344
arena bytes instead of 69,808, saving 36,464 bytes. The focused 32,768-byte output
case needs 66,136 arena bytes instead of 102,600.

## Validation

`tests/guest/i386-arc-expand/Reference.HC` freezes the previous checked decoder,
with only its entry point renamed. The parity audit is preserved in
`build/i386-compact-expand-reference-parity-v1.json`. The differential fixture
runs six original compressed vectors and 64 bit mutations per vector: 390 cases,
comparing acceptance, reported size, every output byte including the terminator,
and heap cleanup. The vectors include seven- and eight-bit inputs, dictionary
width growth/recycling, repeated data, random data and single literals.

`build/i386-compact-expand-corpus-v5` passes that differential corpus plus the
existing streaming, owned-buffer, malformed-input, IF and allocation-boundary
checks on emitted i386 code. Both bootstrap generations pass in
`build/rebuild-compact-expand-v2-verified`.

The new longer corpus uses a 180-second runner timeout by default. Other corpora
retain 20 seconds, and --runner-timeout overrides either (1..3600). The v4 run
hit the previous hard-coded 20-second limit; subprocess.run terminated its guest
and the process was confirmed absent before retrying. Earlier preserved runs
exposed fixture errors: the allocation boundary initially assumed a 24-byte
rather than 16-byte arena header, and an enlarged differential-test arena
contained the runner stack. The corrected test uses the original arena and
mutates/restores its borrowed vector bytes.

The full diagnostic and application gates must be assessed separately; passing
this corpus alone does not close C1–C5.

## Integrated candidate and remaining capacity limit

The cross-build and instruction audit pass in `build/i386-compact-expand-cross-v2`.
Its post-export audit matches 1,725 source files and 26 helpers. Its normal image
is byte-identical to cross-v1's normal image, which passes exact welcome pixels,
suspended clear and subsequent input at 8 MiB TCG with unchanged inputs in
`build/i386-compact-expand-welcome-v1`.

The full cross-v1 diagnostic fails before the second CompilerProbe load. The
unchanged interface-226 baseline reproduces that failure in
`build/i386-compact-expand-baseline-heap-v2`, with unchanged inputs: the requested
module is 575,322 bytes, main capacity is 6,791,680, used is 6,276,320 and largest
free block is 483,312 bytes. The compact candidate fails at the same load with
used 6,284,512 and largest free block 475,120. Its retained footprint at this
point is 8,192 bytes larger; the workspace saving applies during expansion.
Neither run reaches the earlier interface-225 decompression failure. That gap
is therefore not proven closed, and the full 8 MiB diagnostic remains unqualified.

The baseline v1 profiler timed out after 180 seconds during header loading and
terminated its guest; both process IDs were confirmed absent. V2 used a fresh
output directory and a 1,200-second observation limit. Both records are preserved.
The completed cross-v2 packaging run preserves a normal build manifest after
cross-v1's full-test failure, without overwriting its logs or images.

## Remove unused runtime inclusions

FileRuntime no longer includes the unused streaming decoder or resident-file
implementation. The public streaming implementation remains in ConsoleRuntime.
CompilerProbe now includes loader declarations without compiling the unused
loader implementation; CompilerProgramRuntimeProbe explicitly retains it.
No probe body or assertion changes, and interface 226 is unchanged.

Both bootstrap generations pass in
`build/rebuild-runtime-unused-includes-v1-verified`. The full-content candidate
in `build/i386-runtime-unused-includes-cross-v1` completes exports, packaging and
the instruction audit, but its full diagnostic fails. Its separate
`source-audit.json` verifies 1,725 bootstrap source hashes and 26 unchanged build
helpers; it is not a full diagnostic pass. `module-comparison.json` records
CompilerProbe shrinking from 575,322 to 541,830 bytes and FileRuntime from 270,098
to 258,546 bytes. All other common exported modules are byte-identical, including
CompilerProgramRuntimeProbe, ConsoleRuntime and CompilerRuntime.

`build/i386-runtime-unused-includes-welcome-v1` passes exact normal welcome,
suspended clear and subsequent input at 8 MiB TCG, with unchanged inputs.
The full diagnostic still fails at the reclaimed CompilerProbe load: request
541,830, main capacity 6,791,680, used 6,272,224, largest free block 487,408.
The retained footprint is 12,288 bytes below the preceding compact candidate
and 4,096 below the precompact interface-226 baseline. Total free space is only
519,456 bytes, so fragmentation alone does not explain the remaining failure.
The earlier archive-expansion gate is still not reached. C1–C5 remain open.

## Share kernel symbol deletion with the primary probe

CompilerProbe imports `I386HashDel` through one private binding to the existing
kernel implementation. It retains TaskStorage locally, and the program probe
keeps its original implementations. No probe body or assertion changes.
The builder's exact import contract adds only `I386HashDel` for the primary
probe. CompilerProbe shrinks by another 14,808 bytes to 527,022; its logical
loaded image is 478,088. Kernel.t32m grows by 224 bytes, and every other common
exported module is byte-identical to the previous candidate.

Both bootstrap generations pass in `build/rebuild-probe-shared-release-v3-verified`.
`build/i386-probe-shared-release-cross-v4/source-audit.json` verifies 1,725 source
hashes and 26 helpers after export. Its 16 MiB boot completes both compiler
probe phases, worker cleanup and `DONE native kernel startup`; the enclosing
`--test` run subsequently failed its normal 8 MiB keyboard speaker-on check.
The command completed and the captured screen shows `0` instead of the required
`1`; the screen matcher then timed out. `full-test-failure.json` records the
terminal failure. Later rejection, persistence and filesystem tests were not
reached. This is not a full-suite pass, and the failing sound condition is under
separate register-level investigation. Normal 8 MiB exact welcome,
suspended clear and input pass with unchanged inputs in
`build/i386-probe-shared-release-welcome-v1`.

`build/i386-probe-shared-release-diag8-v2` still fails the full 8 MiB diagnostic
at the worker reload: request 527,022; capacity 6,791,168; used 6,271,712; largest
free block 487,408. The copied input image is unchanged. V1 never booted because
QEMU rejected concurrent write access to the 16 MiB run's image; V2 uses a copy.
The logical image fits the measured free block, but the loader first allocates
the whole file. A following change can use the worker's existing private heap
for temporary file bytes and the existing checked loader for the main-heap
image, restoring the private heap before executing any compiler probes.

Earlier development runs are preserved: cross-v1 was explicitly stopped after
review caught the exact-count binding guard; cross-v2 failed because task-storage
release is in CompilerRuntime, not the kernel; cross-v3 exported successfully
but its builder rejected the newly added import until its exact contract was
updated. None is reported as an integration pass. The active native nine-module
run retains its frozen helper; `preloaded-helper-probe-release-update.json`
records the on-disk builder change and verifies its disk-reader AST is unchanged.
C1–C5 remain open.

## Worker scratch file and compact diagnostic image

The worker now reads the temporary probe file into its existing private heap and
uses `I386LoadBoundAlloc` to validate and load only the logical image into the
main heap. It frees the source file and requires exact scratch-heap used-byte
and allocation-count restoration before any compiler probe runs. The root uses
the existing in-place compact loader with shrinking enabled. Both phases retain
478,088 image bytes instead of 527,022 file bytes. The 1 MiB private arena,
16 KiB worker stack, physical memory, module format and all probe assertions
remain unchanged. Validation and relocation reuse the existing shared loader.

The builder requires the compact capacity in both phases and exactly one
scratch-restoration marker between worker memory completion and the second
probe load. Kernel.t32m grows by 2,056 bytes; all other common exported modules
are byte-identical. Both bootstrap generations pass in
`build/rebuild-probe-scratch-loader-v1-verified`. Cross-v1 exports and instruction
audit pass; `source-audit.json` verifies 1,725 sources and 26 helpers, without
claiming the failed full 8 MiB test passed.

`build/i386-probe-scratch-loader-diag16-v1` passes the full 16 MiB diagnostic boot
and exact welcome frame with unchanged input, including both compiler phases.
The builder's worker lifetime/scratch assertions also pass on that log.
`build/i386-probe-scratch-loader-welcome-v1` passes normal 8 MiB exact welcome,
suspended clear and input with unchanged inputs.

At 8 MiB the previous reload failure is resolved. The worker scratch heap is
restored to 5,408 used bytes and five allocations, the compact provider loads,
and token, define, conditional and include probes pass. The diagnostic then
fails after phase-one `DISK READ`, requesting a 33,328-byte compact decoder
workspace: main capacity 6,789,120, used 6,750,344, largest free block 9,304.
`build/i386-probe-scratch-loader-cross-v1/failure.json` records the terminal
failure. The remaining 38,776 total free bytes are fragmented; archive workspace
placement is the next investigation. No full 8 MiB or C1–C5 pass is claimed.

## Current-task decoder workspace with preserved output ownership

`I386ExpandBufWorkspace` separates temporary decoder ownership from output
ownership. It prefers the supplied workspace heap and falls back to the output
heap if that allocation fails. The original four-argument `I386ExpandBuf`
continues to use its output heap for both. FileRuntime's unchanged four-argument
service callback now uses `I386FileExpandBuf`, which prefers the current task's
private heap. The returned buffer always belongs to the requested output heap;
optional size, terminator, malformed-input cleanup and IF behavior are preserved.
The original `ExpandBuf` similarly allocates its decoder control in the current
task while allowing a distinct output task. No public service ABI changes.

The captured old failure in `build/i386-probe-scratch-loader-heap8-v1` has unchanged
inputs. After failure cleanup its free payload totals 32,424 bytes across 558
blocks; the largest is 9,304 and the next 2,800. Splitting the 33,328-byte workspace
into a few large arrays would not solve that state. `free-block-summary.json`
uses the logged allocation request; the profiler's stopped-register request
field belongs to the stop frame and is not used as the allocation request.

Both bootstrap generations pass in `build/rebuild-expand-workspace-v1-verified`.
`build/i386-expand-workspace-corpus-v1` passes emitted-i386 checks with a
240-second observation limit: all 390 original-decoder differential cases,
existing streaming/ownership/malformed/boundary cases, and new separate-heap
cases. All six original vectors verify exact bytes and NUL, output ownership,
workspace sentinel preservation, exact heap recovery and alternating IF states.
Additional cases cover both heaps exhausted, preferred heap full with successful
fallback, output allocation failure, and truncated compressed data after both
allocations. The original single-heap allocation boundary remains unchanged.

The full-content cross-v1 exports and instruction audit pass. FileRuntime grows
from 258,546 to 259,345 bytes; every other common exported module is byte-identical.
Its post-export audit pins 1,725 sources and 26 helpers. The subsequent sound-test
helper correction is separately recorded and was not used during this candidate's
failed full 8 MiB diagnostic. `build/i386-expand-workspace-welcome-v1` passes exact
normal 8 MiB welcome, suspended clear and input with unchanged inputs.
`build/i386-expand-workspace-diag16-v1` passes the full 16 MiB diagnostic boot
and exact welcome with an unchanged image.

The 8 MiB diagnostic now passes disk include expansion and progresses through
phase-one public queue and bit checks. It then fails reading the 7,422-byte
`CompilerTaskLayoutProbe.HC` source plus NUL: requested 7,423, largest free block
5,208. `failure.json` records the terminal state. The public file bridge still
stages stored file bytes in the main heap before copying to the caller's private
heap. That temporary read allocation is the next memory issue; no assertion,
workload or physical-memory limit was reduced. Full 8 MiB and C1–C5 qualification
remain open.

## Diagnostic child task backing (2026-11-07)

After direct private file results removed the 7,423-byte main-heap copy, the
worker's code-lifetime test could not allocate its 13,575-byte task/stack block
in the fragmented main heap. The worker already owns a live private arena.
The code-lifetime probe now retains the boot/main-heap case and allocates the
worker's child in that private arena. It checks the child's actual allocation
owner and size, then requires exact used bytes/allocation counts in both arenas,
parent reference restoration, and unchanged interrupt state. Executable
publication, execution across yields, and deferred destruction for locked code
and attached controls remain required.

The first candidate, `build/i386-code-lifetime-private-cross-v1`, passed both
lifetime phases and then failed on the file-break probe's 21,767-byte child
allocation in the main heap. The same explicit private backing now applies to
both worker-only file-break scenarios. Their real queued ATA cancellation,
locked-break behavior, unpublished-header cleanup, subsequent file read and
compiler reuse remain unchanged; both arenas must recover exactly. The builder
requires the new ownership markers as well as the existing behavioral markers.

`build/rebuild-child-probes-private-v1-verified` passes both bootstrap
generations. The frozen `build/i386-child-probes-private-cross-v1` passes native
compilation, packaging and instruction audit. Only `CompilerProbe.t32m` changes
relative to the direct-read candidate: 527,022 to 529,894 bytes. At 8 MiB,
ownership markers are exactly `[[0,1],[1,0]]` for boot-main/worker-private
code lifetime and `[[0,0],[1,0]]` for the two private file-break scenarios;
all corresponding cleanup markers pass. Source provenance and module comparison
are preserved with that candidate.

The complete 8 MiB diagnostic still **fails later**, in the program provider:
`PARSER CODE ALLOCATION REJECT C:/Kernel/I386/ModuleLoad.HC`, followed by `OutMem`.
No full-suite or memory-profile qualification is claimed. The live native
generation-two run retains its frozen guest sources and preloaded builder;
separate disclosure records verify that its disk-reader AST is unchanged despite
the on-disk verifier additions. C1–C5 remain open.


## Break-request source split and stopped code allocation (2026-11-07)

The synchronous scrolling candidate increased the resident console enough that
worker probe loading failed before its tests: the 480,528-byte request exceeded
the largest contiguous free block by 1,312 bytes. CompilerProbe included the
complete task-break implementation even though its file-break tests call only
lock, request and unlock; neither polling function was called there.

`TaskBreakRequestCore.HC` now holds the unchanged request functions. The normal
`TaskBreak.HC` includes that core and retains both polling functions, while the
probe includes only the request core. All diagnostic cases and assertions stay
in place. The expanded runtime source is byte-identical to its predecessor,
verified in `build/i386-break-request-split-source-parity.json`.

Both bootstrap generations pass in
`build/rebuild-break-request-split-v1-verified`. Native exports, packaging,
instruction audit and the 1,726-source audit pass in
`build/i386-break-request-split-cross-v1`. CompilerProbe shrinks from 529,894 to
526,629 bytes. All fifteen other emitted modules, including ConsoleRuntime,
are byte-identical to the scrolling candidate. Full 8 MiB and 16 MiB diagnostic
runs are pending; source and export evidence alone does not qualify them.

The stopped earlier program-loader failure is preserved in
`build/i386-program-loader-heap8-v1`. Its source/tool hashes are unchanged and
the captured heap block totals match the control records. Decoding the active
`I386ParserCodeAlloc` argument frame gives an 11,070-byte executable allocation.
The private compiler arena has 462,536 bytes used out of 1,048,576 and a largest
free block of 576,936 bytes. The main arena has 6,748,856 used out of 6,789,120
and a largest free block of only 4,536 bytes. The frame and private-heap walk are
recorded in `parser-code-failure.json`. The exported public backing pool has
1,001,472 of 1,004,032 bytes used across 26 regions. Its low-memory fallback
has only a 6,056-byte largest free block. Both backing heap walks, every region
allocation, region count and retained/allocated totals validate against the
capture. Neither backing arena can supply this contiguous code request.
This evidence directs the remaining investigation toward public code backing,
rather than increasing the private compiler arena. It closes no C1–C5 gate.
