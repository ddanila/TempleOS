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
