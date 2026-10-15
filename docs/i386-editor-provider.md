# Editor provider boundary and measured memory budget

The full desktop uses the planned 64 MiB profile, with 128 MiB for rebuilding.
The existing minimal 8 MiB startup and 16 MiB rebuilding workloads remain gates.
Complete original editor/tool behavior must not be cut down to meet those gates.
Move optional editor services behind a real loading boundary before further
large additions to mandatory Console. Console 110 now contains an implementation candidate. Its corrected bootstrap
and cross-build pass; first-use search and minimal startup now pass.
Failure recovery and full lifecycle qualification remain open.

## Measured starting point

`tools/report-i386-provider-footprint.py` reads qualified normal 8 MiB startup
reports, verifies their pinned inputs and records four core provider load spans.
It rejects unqualified/diagnostic inputs and reports allocation-failure samples.
These spans exclude later initialization, heaps, buffers, tasks and other OS
memory; they are neither minimum RAM nor peak usage measurements.

The Console 109 search image retains 2,361,424 bytes for the Console provider,
24,312 bytes above the qualified Console 108 image's 2,337,112 bytes. Compiler,
file and memory provider spans are unchanged. All nine normal startup commands
still pass in 53.89 seconds, while ten speculative backing-allocation failures
exercise the existing smaller-allocation fallback. Evidence:
`build/i386-editor-provider-footprint-final.json`.

The first budget target allows the Console 108 span plus 8 KiB for loading glue:
**2,345,304 bytes**, recovering at least 16,120 bytes from the current mandatory
provider load. `build/i386-editor-provider-budget-final-red.json` fails this new target
as intended. This is a new architectural gate, not a retroactive failure of the
existing startup acceptance. Recovering code span does not guarantee equivalent
free/contiguous runtime heap: measure both behavior and actual allocation policy.

```
python3 tools/report-i386-provider-footprint.py build/i386-c2-editor-search-startup --baseline build/i386-c2-transform-startup --out build/NEW-footprint.json
python3 tools/report-i386-provider-footprint.py build/i386-c2-editor-search-startup --baseline build/i386-c2-transform-startup --max-console-span 2345304 --out build/NEW-budget.json
```

## Implementation and acceptance sequence

1. Inventory optional editor imports/exports and review the existing lazy
   provider machinery. Start with the full shared search/selection bodies;
   preserve public names, signatures and canonical CDoc/CTask layouts. Record
   ownership and dependency rules before moving code.
2. Add tests for a normal minimal boot that leaves the editor provider unloaded
   and meets the byte budget. Independently require its real packaged module,
   current source bytes and required exports; an absent/dummy module cannot pass.
3. Load on first actual use through a private versioned service table, validate
   target/version/size/addresses before publication, and reuse the successful
   load. Delegation must reach the complete original bodies. Preserve caller
   directory, task/document state and failure recovery.
4. Prove concurrent/reentrant attempts and caller cancellation/Exit cannot leave
   partial bindings, a stuck loading state or stale caller-owned pointers.
   Require a surviving parent call after a child first loads the provider.
   Exercise wrong-version/target/import failures, repair and retry.
5. Pass the same nineteen-command search suite, transformation and undo suites,
   minimal startup/resource checks and declared desktop-profile behavior. Count
   actual provider loads and record retained spans; do not infer success from
   a load message alone.
6. Add the complete DocForm/PopUpForm and metadata dependencies at this boundary,
   preserving the class-form oracle and genuine numeric input. Then integrate
   complete replacement/go-to routines and retain the actual chooser/full
   DocPutKey/GetStr/TimeClock gates. Unavailable services remain explicit gaps.
7. Update native build/install manifests, delivered source audits and generation
   qualification so self-built images contain the provider. C5 still requires
   two full native desktop/application generations; a host cross-build or a
   successful optional load does not satisfy it.

This boundary does not authorize replacing required desktop/tool shortcuts with
stubs, pruning original branches, weakening the compatibility inventory, raising
minimal-profile limits or claiming completed C1–C5 milestones.


Five negative controls also pass: failed status, inconsistent over-budget time,
diagnostic mode, a missing successful command and a changed input pin are all
rejected. Evidence: `build/i386-provider-report-negative-controls.json`. The
report validates the actual nine-command normal boot log and matching behavior
metadata as well as file pins; it does not rely on a pass label alone.

## Console 110 checkpoint

`EditorRuntime.HH` defines private version-1 context and service tables.
`EditorRuntime.HC` compiles the complete shared search/selection bodies without
external module imports; context callbacks supply document operations.
`EditorDispatch.HC` retains context, image and successful service bindings in
Console and loads on first public call. Kernel loading validates the module and
service addresses. No first caller namespace owns these bindings.

The corrected build is `build/i386-c2-editor-provider-copy-cross` (569584 kernel
bytes). An earlier first-use fault exposed a struct-value/address cast in the
kernel copy loop; explicit pointer copying and destination validation replace
it. This correction has build evidence only at this checkpoint.

`tools/test-i386-editor-provider.py` checks packaging, exact delivered source,
exports, search behavior and load count. The recovery driver adds wrong-target,
wrong-version and unresolved-import mutations, repeated rejection, guest repair,
retry and cached reuse. These new runtime gates have not yet passed on the
corrected candidate. Normal startup/footprint, transform/undo regressions,
child-first ownership, cancellation/reentrancy and native generations also
remain pending. Historical Console 109 measurements above are not measurements
of Console 110. Full class forms and the remaining original input/editor
services are still subsequent implementation work.

## First runtime qualification

The corrected candidate passes `build/i386-c2-editor-provider-copy-first-use`:
real packaged module and exact delivered sources, required exports, sixteen
masks of 63 over nineteen commands, no early load and exactly one successful
load. All inputs remain unchanged. All 1499 cross-build pins also match.

`build/i386-c2-editor-provider-copy-startup` passes nine normal 8 MiB commands in
54.05 seconds on `486,-fpu`, with automatic window management active and zero
editor loads. `build/i386-editor-provider-copy-budget.json` records a Console
span of 2343392 bytes, 1912 below the budget and 18032 below Console 109. Other
core spans are unchanged, with zero observed backing allocation failures.

These results supersede the earlier pending first-use/startup status only.
Malformed-module recovery, lifetime/cancellation, transform/undo regressions
and native-generation acceptance are still separate gates.

## Wrong-version recovery and child-first ownership

`build/i386-c2-editor-provider-recovery-version-v2` passes two rejected load
attempts with exact caller heap recovery, unchanged directory/document roles,
guest repair and successful retry. One module load serves three successful
calls, including a cached call while the on-disk module is corrupted again.
The fixture repairs the provider byte-identically before finishing; inputs
remain pinned. The first fixture run stalled on its setup VGA expectation,
before rejection was exercised; explicit checked setup/cleanup replaces the
mixed declaration/expression command. It is not a provider failure result.

`build/i386-c2-editor-provider-lifetime` passes nine commands: first load from
a child, two natural child exits, exact public pool recovery for the second
child and a surviving parent call. Only one load is logged, and inputs remain
unchanged. This qualifies natural caller retirement, not forced cancellation
or reentrant initialization.

Wrong-target recovery also passes in
`build/i386-c2-editor-provider-recovery-wrong-target`, with the same two rejected
attempts, three successful calls and exact final repair. Fourteen-command
transform and ten-command undo regressions pass in
`build/i386-c2-editor-provider-copy-transform` and
`build/i386-c2-editor-provider-copy-undo`; inputs remain unchanged.

## Native provider and remaining diagnostic resource failure

Unresolved-import recovery passes in
`build/i386-c2-editor-provider-recovery-missing-import`, completing the three
malformed-module cases. All inputs remain unchanged.

The guest-built provider in `build/i386-c2-editor-provider-native-build` passes
the export audit at 16 MiB. The strict cross/native byte comparison fails
(30875 versus 32428 bytes); its report is retained separately. Local function/
data references in the native module resolve against its own exports. The
provider verifier accepts those references and rejects external dependencies.
The retained-build tool now records audit failures as terminal failures rather
than leaving a stale running status.

Guest installation preserves the native module bytes exactly. Its nineteen
search/selection commands pass in
`build/i386-c2-editor-provider-native-first-use`, with one load and unchanged
inputs. This proves the installed optional module's bounded behavior, not a
complete native generation or reproducibility.

The generic install suite remains failed in
`build/i386-c2-editor-provider-native-install`: independent 8 MiB reboot passes
arithmetic, but DocAllocationCheck returns -1 when loading its optional
65067-byte diagnostic module exhausts the heap. Its expected result was 13;
the debug log and captured VGA checkpoint show the failure. Keep this resource
case visible alongside the separate qualified normal-startup result. Forced
cancellation/reentrancy, complete native generations and original forms/input
remain open.

## Version-2 complete form candidate

Console 111 adds stable public DocForm/PopUpForm dispatch. The optional module
shares their complete original bodies and the original class-forwarding and
member-metadata helpers. Context/services are now version 2, 84/44 bytes on
32-bit targets; real variadic DocPrint/PopUpPrint pointers preserve their ABI.
LBtr remains the existing intrinsic. No public CDoc/CTask layout changes occur.

The corrected cross-build, nineteen-command search regression and version-2
wrong-version recovery pass. Normal 8 MiB startup passes in 57.69 seconds,
keeping editor code unloaded. The budget report records 2345016 Console bytes,
288 below the unchanged cap. See [class-form evidence](i386-class-form.md) for
the remaining typed-input failure, strengthened cancellation oracle and the
unexplained initial inferred-class failure. Compiling complete form wrappers
is not complete form/input or popup qualification. Full native generations,
forced cancellation/reentrancy and the diagnostic allocation issue remain open.

## Permanent export resolution (Console 112)

The private version-3 context now passes the permanent Console export array and
its count, the canonical character bitmap, and four stable kernel callbacks
(string comparison, metadata hash lookup, allocation and free). Context/services
are 40/44 bytes on i386. The optional provider resolves its document callbacks
by exact export name, checking kind, type, nonzero 32-bit address and duplicate
matches before publishing its own bindings pointer. It never searches the first
caller's hash table for those callbacks and never writes its bindings back into
the caller's namespace/context. Public document layouts and 273 Console exports
remain unchanged; Memory remains 26.

This moves growing dependency initialization out of mandatory Console. The
original callback semantics and full shared search/form bodies remain intact.
The corrected cross-build `build/i386-c2-editor-export-cross` passes with 569584
kernel bytes and 1502 matching build pins. The nineteen-command search suite
passes in `build/i386-c2-editor-export-search`.

`build/i386-c2-editor-export-owner-checked` passes seven commands: a first child
installs a real _DOC_NEW shadow that resolves locally, calls complete DocForm
on a known public unformatted class, and exits. The poisoned allocator is never
called; a second child and the parent reuse the same provider. Per-call heap
and document/end-callback roles recover exactly, the second child's public pool
recovers, and parent export identity is unchanged. There is exactly one load.
The fixture explicitly checks the class exists, so unknown-class early return
cannot substitute for allocation. Initial fixture runs stopped at a missing
canonical type include and an unexpected pointer-printing setup expression;
neither reached the ownership assertion. A void setup function fixes the latter.

Version-3 repeated wrong-version rejection, guest repair/retry and cached reuse
pass in `build/i386-c2-editor-export-version-recovery`. All test inputs remain
unchanged. Normal 8 MiB startup passes nine commands in 55.14 seconds with zero editor
loads in `build/i386-c2-editor-export-startup`. The qualified report
`build/i386-editor-export-budget.json` records Console 2344448 bytes, 568 below
Console 111 and 856 below the unchanged cap; other measured core spans are
unchanged and no backing failures are observed. This is provider span, not
peak RAM. Additional dependencies already exported by Console can now be
resolved without adding mandatory per-callback initialization code; new public
entry stubs/exports still count against the budget.

The strengthened original form oracle passes seven masks of 63 in
`build/i386-c4-editor-export-form-reference`. Native diagnostic-only observations
in `build/i386-c2-editor-export-form-observation` remain
[63,63,63,63,63,60,62], with zero caller heap deltas and unchanged inputs. Typed
accept/cancel remain red; this is no form-compatibility pass.

The provider compiles natively on 486 without an FPU at 16 MiB in
`build/i386-c2-editor-export-native-build`: persisted export audit passes for
53482 bytes, 165 records and 35 exports. This is component build evidence;
installation/runtime on that native module and full generations remain open.
The [replacement oracle](i386-editor-replace.md) is the next dependency gate. This does not qualify forced cancellation/reentrancy,
new native generations, the diagnostic memory case or full desktop behavior.
