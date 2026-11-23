# Public optimizer uses the resident shared core

The normal public OptPass012 loader now compiles the complete original helper
set and delegates the pass body to the optimizer already in CompilerRuntime.
It no longer compiles a second copy of that body or loads OptRuntime.t32m.
The source implementation remains available in PublicOptSupport.HC, byte-identical
to the prior canonical helper source; its default shared-pass path is retained.
No opcode, helper, warning, error report or ownership callback is removed.

## Live metadata and ownership

OptPass012CoreMetadata accepts a caller-owned opcode table and row size as well
as the existing services and branch callbacks. It reads arg_cnt, res_cnt and
not_const at byte offsets 0, 1 and 4; callers retain IC_ICS_NUM readable rows of
at least five bytes throughout the call. The original policy/default entries
keep their signatures and supply their containing compiler's actual table.
This avoids substituting the private compiler's table for public metadata.
The table is read live, including after callbacks, rather than copied once.

The resident core's algorithm body is otherwise unchanged. The native wrapper
checks its field-prefix assumptions during compilation. Native diagnostics
exercise five-byte and sixteen-byte rows, caller-specific not_const values,
and a callback that changes res_cnt: the core must observe the change before
pushing the result. Both target-flag modes and zero/nonzero callbacks are
checked over three passes with no heap change.

The new `_I386_OPT_CORE_METADATA` binding is appended at compiler export index
7, preserving indices 0–6. The matching kernel publishes eight validated
exports. Existing service structure layout and version are unchanged. As with
the previous append-only binding, use the matching rebuilt kernel and compiler.

ResidentOptCore.HC keeps all three shared core entry points visible in the
public source namespace. It supplies the public compiler's actual metadata,
canonical type array, original branch callbacks and original report callback.
At the call boundary it checks the native service layout and metadata prefix.
A raw layout probe independently observes metadata size/offsets [12,0,1,4],
service size/offsets [12,0,4,8], pointer size 4 and Bool size 1. No new public
control is passed to private ownership validators. Code and exported binding
lifetime remain the retained compiler image's system lifetime.

## Source delivery

ResidentOptSupport.HC is a generated single-document variant of the complete
canonical PublicOptSupport.HC. The generator adds only the resident bridge,
the external-core selection/reset and the distinct load marker. Reversing
those changes recovers the byte-identical canonical source. All original
helper bodies and declarations remain available to subsequent parser stages.

```sh
python3 tools/gen-i386-resident-optimizer.py
python3 tools/gen-i386-resident-optimizer.py --check
```

The host kernel builder requires the generation check. The generated file is
checked in for native source packaging. Keeping the variant in one document
avoids a nested support-document allocation during the already tight 8 MiB
load. The source switch uses numeric definitions and supported conditionals;
HolyC has no #undef directive. Early experimental variants using #undef failed
before publication and are excluded from passing evidence.

## Verification and limits

`build/resident-opt-public-v5/candidate.img` is the final production-source
candidate, SHA256:
`047eeae06731ba6b462472d0637519a92acd47875166ad237e5633370d22de4b`.
It contains no optimizer provider module. The rebuilt kernel/compiler/program
probe pass complete 386 module and boot audits. Console's loader selects the
resident support source with its unchanged import contract. Exact packaging
checks preserve unrelated files and audited boot bytes.

- Production User/managed-pointer oracle at 8 MiB: PASS.
- Default public optimizer at 16 MiB: PASS, exact original 48-word folding trace,
  18 state checks, zero caller heap deltas and fresh arithmetic. Exactly one
  resident marker, zero source/provider markers.
- Legacy source mode at 16 MiB: PASS with the same requirements and exactly one
  source marker. Its comparison image changes only Console back to the source
  loader, retaining the current shared sources and kernel.
- Complete native compiler/program diagnostics at 16 MiB: PASS in both rounds,
  including resident binding, metadata-stride/live-mutation and earlier boundary
  checks, DocAllocationCheck=13 and fresh arithmetic.
- Classic-host shared-core callback/default policy test: PASS with exact routing
  counters and zero heap delta.
- Original-User/provider-lexer prototype with these final helpers at 64 MiB:
  PASS for exact prompt output, throw/undefined-symbol/Ctrl-Alt-C recovery and
  physical task retirement. Exactly one resident optimizer publication.
- The same original-User prototype at 8 MiB: FAIL before optimizer publication,
  on an 80-byte public allocation. Pool used/reserved are 0xFFF18/0x100C00;
  backing storage is fully used at 0x118400. A matching FileRuntime trace now locates the failure while opening
  `C:/Compiler/IntermediateOpcodes.HH`. This is not a passing original-User gate.

The standalone public compiler-stream command failed before optimizer loading
at its undeclared ExeCmdLine dependency; it does not establish a bridge semantic
failure or pass. The established original-User recovery oracle exercises the
actual complete parser path. The separate 24-check lexer regression passes but
does not load the optimizer and is not counted as optimizer coverage.

`build/resident-opt-final-audit` checks the final receipts and actual RAM
commands, rehashes inputs, verifies installed current sources, confirms no
extra optimizer module, reverses the algorithm refactor and generated support,
and checks exact original folding bytes. Passing scoped audits do not qualify
unexercised APIs or malformed helper loads. Cross builds use the retained
bootstrap; two current native generations, full inventory/workflows and
startup/resource release qualification remain open. C1–C5 are not complete.

The optimizer test defaults to resident storage for native disks and source for
original-reference runs. Use `--optimizer-storage source` for historical source
images, or `provider` for that separate experimental module path. Every native
mode requires exactly its own single publication marker and no fallback marker.

## Rejected early header preload

A diagnostic-only Console variant loads the complete SystemCompilerA.HH through
raw ConsoleSource before registering rich document callbacks. Both the production
and original-User variants complete that header load, then fail User startup at
8 MiB on the 267,527-byte task allocation. These variants are not integrated.
Loading all SystemCompiler.HH earlier also fails this allocation.

Physical heap snapshots immediately after startup (before user commands), taken
from the same kernel at 8 MiB, explain why early loading is insufficient:

| Kernel heap measurement (bytes) | Baseline | CompilerA preload |
| --- | ---: | ---: |
| Live allocated spans | 6,255,104 | 6,334,056 |
| Free payload total | 489,408 | 412,584 |
| Largest free payload | 297,272 | 149,648 |
| Live allocations | 18,300 | 20,073 |

Both fallback heaps have 547,760 of 551,936 bytes allocated, eight allocations,
and a largest free payload of 2,840 bytes. The preload adds 78,952 bytes of live
kernel allocation and leaves neither heap with a contiguous block sufficient
for the task. Total free payload alone does not establish task feasibility.

`build/preload-heap-comparison/snapshot.py` stops QEMU after the startup marker,
saves physical memory, validates every block span/tag and reconciles used-byte
and allocation counters in both heaps. Its addresses are specific to the
metadata-v2 Kernel image, not a portable heap inspection ABI. Results and memory
snapshots remain under the baseline/preload subdirectories. The include trace
is under `build/current-opt-include-trace`; rejected preload overlays, packaging
receipts and startup logs are under `build/compiler-preload[-original]-v1/v2`.
These failed experiments do not qualify the original-User 8 MiB gate. The next
approach must avoid rich include-document pressure without adding these
permanent declarations before the initial task allocation.

A subsequent source-only flattening experiment in `build/compiler-flat-headers-v1`
replaces only SystemCompilerA.HH with the complete recursively expanded canonical
CompilerA dependency graph (9,541 bytes). Every dependency byte and include guard
is retained; modules and all other installed files are unchanged. At 8 MiB the
original-User startup oracle still fails on an 80-byte public allocation before
optimizer publication (used/reserved 0xFFC80/0x100800, backing 0x118000 fully used).
This rules out merging those six nested include files alone as a sufficient fix.
The experiment is not installed in production. Its packaging script and receipts
pin all seven canonical inputs; runtime failure inputs are unchanged. A scoped
raw-source delivery path remains to be implemented and qualified.

## Control-local raw declaration prototype

`docs/patches/i386-raw-system-header-prototype.patch` applies on top of the
original-User/provider-lexer Console overlay (not directly to production Console).
The private flag I386_CCF_RAW_INCLUDES uses compiler-control bit 44, outside the
current compiler flag set. TaskFileRead retains decoded public file reads and
owned lexer buffers, but bypasses rich document creation only for that control.
Registered callbacks and other controls are unchanged. Before normal resident
optimizer loading, Adam executes ExePutS2 with this flag to load the complete
SystemCompilerA graph lazily into the existing system compiler namespace.
No declarations, cases, stack sizes or gates are removed.

Both ConsoleRuntime and FileRuntime cross-build and pass the current whole-module
386 instruction/import audit. The source-only flag addition has no structure or
service-table layout change. Packaging replaces the two modules and their matching
three source files only; all remaining source/module bytes and boot area are
checked unchanged against the current original-User candidate. Candidate SHA256:
`5dc982a84ea8346f8035986ff21e90dad90f35ea8e861c751d2ee03f1cebb5a8`.
Evidence is under `build/compiler-raw-headers-v2`; v1 lacked prototype include
files during Console cross compilation and is not a valid runtime candidate.

The actual 8 MiB startup oracle still FAILS, now on a 52-byte kernel-heap request:
used/size 0x66F9E8/0x66FA00, largest payload 8 bytes, allocations 0x4C86. The
reported caller PCs 0x1967AC and 0x19A5CE map to exported functions
I386LexDefinePublish+0x50C and I386LexNextWithIncludes+0xFD6 using the actual loaded
CompilerRuntime base plus eight and kind-1 function exports. This moves past the
previous public Doc allocation but does not qualify original-User8. The separately run 64 MiB recovery job subsequently passed exact prompt
documents, throw and undefined-symbol recovery, physical Ctrl+Alt+C, fresh input
and physical child reclamation. Its actual QEMU command is KVM 486,-fpu with
64 MiB; inputs are unchanged and exactly one resident optimizer marker occurs.
`build/compiler-raw-headers-v2/recovery-audit.json` pins that terminal receipt and
command. This is scoped recovery evidence, not a passing User8 gate. The patch
remains a prototype and is not applied to production sources.

## Direct call-job follow-up

The v3/v4 attempts to set the current control's flag from an Adam source
statement both fail User8 with the same 52-byte macro allocation and one
reported compiler error. They are not evidence that the flag was active at the
first include: statement parsing can lex the following token before execution.

`docs/patches/i386-raw-header-call-job-prototype.patch` instead enters
ConsoleSource through an existing JOBT_CALL callback, with raw-include and
JUST_LOAD flags set before the first lex. In Adam it calls directly. From a
worker, it queues an owned empty job under an outer IRQ exclusion, converts it
to CALL, sets the callback/wake flag and suspends the master before releasing
IRQs; existing job dispatch completes and wakes the master, and JobResScan
reclaims the request. It uses retained suspend/yield providers. The complete
header graph and the subsequent normal resident optimizer load are unchanged.

The v6 Console cross-build passes with frozen inputs; the matching FileRuntime
is reused from v2. V5's missing Suspend declaration and changed-manifest build
are excluded. The small cross-audit pins v6's module, receipt and patch. Its
image packaging and actual 8 MiB startup job are running under
`build/compiler-raw-headers-v6`; no runtime qualification is claimed yet. This
is a prototype on the original-User/provider-lexer overlay, not production.

The direct call-job v6 User8 run is now terminal FAIL. The kernel arena is
completely allocated (0x66FA00/0x66FA00, largest free zero, allocation count
0x4CBD) when a seven-byte identifier is requested. Caller PCs 0x1938B5 and
0x192BDB resolve through the matching CompilerRuntime kind-1 exports to
I386IdentPublish+0xD5 and LexIdentFinish+0x233. No resident optimizer publication
occurs, and runtime inputs are unchanged. `user8-audit.json` pins the receipt
and debug log. This does not establish whether the complete raw declaration load
finished, so it cannot yet be attributed to the subsequent helper stage.

A v7 diagnostic adds begin/end markers around that header ConsoleSource call;
both its Console cross-build and exact module packaging pass, and its fresh
User8 run is in flight. The separate v6 recovery64 test is also live and must
be inspected before extending v2's recovery result to the new job path. Unique
artifacts remain under their corresponding build directories. Neither variant
is installed in production or counted as an 8 MiB pass.

## Paused checkpoint: terminal results and resume point

At the user's pause/wrap-up request, all outstanding jobs are terminal:

- Direct call-job v6 recovery64: PASS. Exact prompt documents, throw and
  undefined-symbol recovery, physical Ctrl+Alt+C and physical child reclamation
  pass with unchanged inputs. The actual QEMU command specifies 64 MiB.
- V7 User8 stage trace: FAIL. RAW COMPILER A begin precedes heap exhaustion;
  INPUT REJECT then precedes RAW COMPILER A end. The end marker records return
  from a failed ConsoleSource, not successful header completion. Thus the heap
  is exhausted during complete CompilerA declaration loading, before optimizer
  publication, not during the later optimizer helper body.
- compiler-high-headers-v1: cross-build FAIL with unchanged inputs. The compiler
  reports a parse error at `text=NULL` in Compiler/I386/LexIdent.HC, line 46 of
  its overlay. No candidate image or runtime qualification exists for this idea.

The unfinished high-placement experiment applies a private per-control bit 45
only to early complete CompilerA loading. It directs parser payloads, macro
records/body/source links and identifier strings to the high allocator, aiming
to preserve the contiguous task-stack block lost by the earlier eager preload.
Its full unapplied candidate.patch, overlay Once.HC, run.py and package.py are
retained in build/compiler-high-headers-v1. This is an experimental hypothesis;
allocation ownership, failure behavior and ordinary unflagged paths still need
review and tests. The first resume step is to correct the bootstrap-incompatible
NULL token in a fresh frozen overlay, rebuild and audit both CompilerRuntime and
ConsoleRuntime, then measure the heaps and run the unchanged User8 oracle.
Do not integrate this allocator policy merely because it cross-compiles.

build/compiler-header-pause-checkpoint/audit.json pins all three terminal
receipts. Production source files remain unchanged by these experiments. The
last production optimizer integration remains the resident core implementation;
original User/provider lexer and raw-header policies remain prototypes. Full
C1–C5, the 2/686 inventory, original-User8, current native generations and startup
qualification remain open. Work is paused at the user's request.

## Resumed allocation-placement experiment (2026-11-23)

Work resumed on main from the paused checkpoint. A fresh
build/compiler-high-headers-v2 overlay replaces the bootstrap-incompatible NULL
in the experimental identifier path with zero. Both complete CompilerRuntime
and ConsoleRuntime now cross-compile with unchanged pinned inputs. The
cross-audit.json records their hashes and the build receipt. This establishes
compilability only; it does not verify the placement policy's ownership behavior,
heap fragmentation, startup or broader compatibility. The original-User8 test
is launched after successful image auditing/packaging and needs its terminal
receipt before any passing claim. No production source changes are applied.
The full C1–C5 objective is active again; all prior open gates remain open.


High-placement v2 passes the module and image audits. The actual 8 MiB User
startup test completes CompilerA preload and reaches USCheck, then fails the
267,527-byte task allocation. The fallback arena's largest free payload is still
2,840 bytes. The experiment therefore leaves the original-User8 gate open.
`build/compiler-high-headers-v2/user8-audit.json` pins the runtime and packaging
receipts. The physical startup heap snapshot under
`build/preload-heap-comparison/high_v2` measures the effect on the main arena.

The high-placement v2 physical snapshot confirms that the main arena already
lacks a contiguous task-sized block immediately after startup. Its largest free
payload is 202,512 bytes, 65,015 bytes below the 267,527-byte request, despite
386,680 bytes of total free payload. The fallback maximum is still 2,840 bytes.
The earlier ordinary preload snapshot measured 149,648 bytes for the largest
main-arena block on a production User base. A separate snapshot of the ordinary
preload on the original-User base is needed to isolate the placement effect.
`build/preload-heap-comparison/high_v2/summary.json` pins the full census.

The matched original-User ordinary preload census is complete. The largest
main-arena free payload rises from 149,648 to 202,512 bytes with high placement,
a gain of 52,864 bytes. Total free payload falls from 392,104 to 386,680.
Both experiments still fail the 267,527-byte task allocation. This comparison
includes the rebuilt module size and layout effects. In high v2 the two
largest free spans are separated by live requests of 8,400 and 8,328 bytes
and additional smaller allocations. The census records size and location.
Ownership must be traced before changing placement of those allocations.
The matched receipts and neighboring blocks are pinned in
`build/preload-heap-comparison/original-preload-placement-comparison.json`.

The physical backing ownership audit identifies exactly two live blocks between
the largest free spans. Both belong to the public backing pool and each holds
8,192 bytes of assigned pages. Neither carries the reserve hold. The audit
walks all 22 owned regions, reconciles their request and span fields against
the physical heap, and matches the pool's retained-byte counter. These regions
cannot be trimmed as empty. The allocator already places these batches high in
the last fitting block, so changing header allocation placement alone leaves
public backing placement as a separate constraint. The decoder and its result
are under `build/preload-heap-comparison`.

The smallest-fit public backing experiment cross-compiles MemoryRuntime and
passes the image audit on the high-placement original-User base. The 8 MiB
oracle fails earlier, after the window manager starts and before native
startup completes, on a 131,976-byte public allocation. The placement
change therefore fails the startup gate. Choosing a small block for each
batch in isolation can still leave subsequent large page requests without
a usable contiguous extent. The unapplied patch and pinned test evidence
are under `build/compiler-backing-fit-v1`.

A second smallest-fit candidate keeps existing placement until the pool retains
one MiB, an experimental cutoff above the pool usage seen at the previous
large allocation failure. The cross-build and image audit pass. At 8 MiB the
window manager and native startup complete, and User startup reaches USCheck.
It then fails the original 267,527-byte task allocation. The threshold avoids
the earlier public allocation failure in this run but still leaves User8 open.
The unapplied policy and pinned evidence are in `build/compiler-backing-fit-v2`.

The aligned high-placement candidate computes the padding from each free
block's end address for native-size backing batches. It retains the
conservative arena admission check and reverse-address block preference.
The module cross-build and image audit pass, and native startup completes at
8 MiB. USCheck still fails the 267,527-byte task request. The fallback's
largest free payload increases from 2,840 to 3,496 bytes. The unapplied
experiment and pinned receipts are under `build/compiler-backing-aligned-v1`.

Separating the task record from its stack would still leave the 262,144-byte
stack larger than any free block in the captured high-placement arenas. If
the two live backing batches had been placed outside the gap, the joined
span would offer 325,112 bytes of payload. A separate 36,248-byte free span
can hold both batches with worst-case padding in this snapshot. Its
availability when the batches were originally allocated remains unverified.
The existing backing pages remain live at fixed addresses. The calculation
is pinned in `build/preload-heap-comparison/high_v2/task-placement-feasibility.json`.

An instrumented MemoryRuntime reproduces the 8 MiB USCheck task allocation
failure while recording every fitting block before each backing allocation.
The payload address 0x793730 matches one of the two split-span backing blocks
in the prior snapshot. Several allocations at that address have exactly one
fitting block in the selected main arena. Other allocations at the same
address have alternatives. Address reuse means that a matching pick alone
does not prove which instance survived to startup completion. A packing
policy cannot redirect the single-fit allocations without changing the
earlier layout or the batch size. The trace patch, build drivers, and parsed
records are under `build/compiler-backing-trace-v1`.

The allocation and release replay resolves the address reuse. All 22 live
addresses at the startup marker match the backing ownership chain in a
separate physical snapshot of the same instrumented image. The two batches
between the largest free spans survived from allocations at trace lines
938 and 375. They had five and three fitting blocks respectively, including
alternatives outside their selected blocks. The single-fit instances seen
earlier were temporary. This narrows the placement problem to the choices
made for the surviving batches and the effects of earlier placement on
those choices. The instrumented run still fails USCheck at 8 MiB.
Replay inputs and results are under `build/compiler-backing-trace-v2`.

The exact-size late growth experiment switches to requested pages once the
pool retains 1 MiB and uses high placement for requests through one 8 KiB
batch. The threshold is experimental and follows the earlier growth trace.
The audited image completes native startup at 8 MiB, then USCheck fails
the same 267,527-byte task request. The fallback largest free payload is
2,768 bytes. The experiment and pinned receipts are under
`build/compiler-backing-exact-v1`. All five inventory guard tests also pass.

Increasing the initial public backing reserve from 128 to 192 KiB on the
high-header candidate reduces the fallback allocation count from eight to
seven at the failing task request. The cross-build and image audit pass.
Native startup completes at 8 MiB and USCheck still fails the 267,527-byte
task request. The fallback largest free payload is 2,696 bytes. The
experimental reserve and pinned evidence are under
`build/compiler-backing-reserve-v1`.

Reducing the initial reserve to 32 KiB also passes the cross-build and image
audit and completes native startup at 8 MiB. USCheck still fails the same
267,527-byte task request. The fallback then contains twelve allocations
and its largest free payload is 496 bytes, versus eight allocations and
2,840 bytes at 128 KiB. Varying the reserve alone has failed over both
tested directions. The unapplied experiment and pinned receipts are under
`build/compiler-backing-reserve-v2`.

Placing large main-arena backing regions at the high end also passes the
cross-build and image audit. The 8 MiB image completes native startup but
USCheck fails the same 267,527-byte task request. The fallback still has
eight allocations and a largest free payload of 2,840 bytes.
A physical snapshot of this candidate is running under
`build/preload-heap-comparison/large_high_v1` to measure the changed main
arena layout. The patch and pinned receipts are under
`build/compiler-backing-large-high-v1`.

The large-region high-placement snapshot is complete. The largest main free
payload falls from 202,512 to 150,112 bytes while total free payload rises
from 386,680 to 388,144 bytes. The 267,527-byte task still cannot fit in the
captured layout. The pinned census is under
`build/preload-heap-comparison/large_high_v1/summary.json`.

The production image containing the direct-copy autocomplete dictionary
also passes the resident optimizer oracle at 16 MiB. The original 48-word
folding trace matches, heap deltas are zero, fresh arithmetic runs, and
exactly one resident publication occurs. The result pins unchanged inputs
in `build/ac-dictionary-direct-copy/resident-opt16/result.json`.

The dictionary-updated production image also passes the 16 MiB native
compiler and program diagnostic run. Both rounds complete the code header,
emitter, resident policy and metadata checks. Fresh arithmetic and
DocAllocationCheck pass, including diagnostic load, recovery and unload.
The diagnostic image and pinned inputs are unchanged. See
`build/ac-dictionary-direct-copy/diagnostic16/result.json`.

An 8 MiB original-User overlay reserves the full 267,527-byte task allocation
before compiling the complete root CompilerA headers. The reservation succeeds
at `0x708CB8`. The headers load and the contiguous block is returned before
the remaining startup work. Startup completes, but USCheck still fails the
same-size allocation. This rules out a reservation limited to the CompilerA
load as a sufficient fix. The patch, packaging and runtime receipts are in
`build/original-user-stack-reserve-v4`.

Extending the same reservation through the remainder of startup leaves the
original task block occupied at `0x708CB8`. The complete compiler headers
load and WinMgr starts. Startup then runs out of segmented emitter space
while compiling `Compiler/UAsmCore.HC` for the original command prompt.
This is earlier than the original User task allocation. The audited patch and
failure receipts are in `build/original-user-stack-reserve-v5`.

Splitting command-prompt startup into four native source transactions advances
the reserved-stack image from segmented emitter exhaustion to the final code
storage allocation while loading the unit containing `Ui`. The splitter
preserves every byte of the original disassembler across its two source units.
The image still fails before startup completes. See
`build/original-user-split-prompt-v1`.

The first high-end reservation image adds a direct Console import for the
kernel's high allocator. It passes the host instruction audit with that
specific import accounted for, then the native Console loader rejects the
module before the reservation runs. The failure leaves the high-end placement
hypothesis untested. See `build/original-user-stack-reserve-v6`.
