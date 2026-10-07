# Active parent compiler context contract

`ExePutS` must preserve the original supplied `CLexHashTableContext` behavior,
including declarations and executable code. Private public hash tables already
have a separate passing contract; they do not prove parser-overlay ownership.

The original reference for `tests/guest/i386-exe-puts/ParentPublish.HC` passes
all seven checks in `build/exe-puts-parent-publish-original-v1/result.json`.
It load-compiles a global into the supplied context, finds that declaration,
initializes and reads it, load-compiles a function referencing it, calls the
function twice with an intervening mutation, and checks the parent boundary.
The driver pins the complete fixture, original source dependencies including
KTask, and bootstrap binaries. Native runs also verify VGA and saved fixture
bytes independently on a 486 without FPU and 8 MiB.

The corresponding native red run, `build/exe-puts-parent-publish-native-red-v1`,
compiles the fixture successfully, then rejects `JRContract()` with exception
`00006D654D74754F` (OutMem), zero compiler errors and zero warnings. The harness
times out waiting for mask 127. Both runs' recorded input pins still match.
This is consistent with the frontend's rejected parent overlay; it does not
prove actual physical RAM exhaustion. The failed run does not reach the driver's
independent saved-fixture byte comparison.

## Implementation requirements

1. Identify an active parent frontend through validated compiler controls.
   Accept only its exact registered overlay and bucket allocation; arbitrary
   arena allocations must not become valid tables.
2. Keep supplied context lookup and declaration destination intact. Preserve
   options, ASM-expression state and borrowed context fields.
3. Validate nested publication completely before moving any roots. Move symbol
   metadata and global data parser records into the parent ownership queue.
   Move executable allocation records and frontend code descriptors together,
   preserving task heap owners and logical sizes. Preserve relocation metadata.
4. Transfer resident bindings and class-completion state with their declarations.
   Completion of an existing parent declaration must preserve its identity and
   ownership; reject collisions without partial publication.
5. Parent publication must then retain the combined symbol/code graph normally.
   Parent unwind must release unfinished state exactly once while preserving
   successfully published declarations according to the original behavior
   established below. No task-global publication shortcut
   may replace the supplied table's scope.

## Remaining acceptance evidence

The seven-bit fixture exercises repeated nested calls while the parent is live.
The v2 driver also wraps this call in an outer `ExePutS` and requires the
function to return 43 after that outer compiler has returned. The original v2
reference passes in `build/exe-puts-parent-publish-original-v2`. Exact arena
recovery and more complex type/code graphs remain unqualified. Add separate fixtures for post-parent function/global use,
class completion, macros, relocation-bearing code, custom exception unwind and
allocation failures. Compare original behavior before accepting a native fix.
Run the existing context, private-context, execution exception, timing and
formatting regressions on the same fresh image. Finally qualify current-source
native rebuild/install generations and the release suite.

## Original exception persistence (2026-10-06)

`tests/guest/i386-exe-puts/ParentUnwind.HC` creates a global and function through
its live parent context, then throws a custom exception from that parent.
`build/exe-puts-parent-unwind-original-v1/result.json` passes mask 63: the caller
catches the custom exception, its compiler boundary restores, both declarations
remain in the task scope, and both remain usable. All recorded pins match.
The corresponding native cross-v4 red run is terminal fail in
`build/exe-puts-parent-unwind-native-red-v1/result.json`. The saved VGA checkpoint
shows mask 2: only parent-boundary restoration passes; the expected custom
exception and declaration persistence checks fail. Input pins remain unchanged.
An independent post-failure RedSea read matches the fixture byte-for-byte;
`transfer-verification.json` records that separately from the behavioral failure.

This rules out discarding all nested declarations on outer runtime failure.
A parent-overlay implementation must distinguish successfully published child
symbols from unfinished parser state, and preserve their executable/data graph
when the parent exits exceptionally. The existing native CommandInput path only
publishes after the entire input succeeds, then unconditionally unwinds controls;
that is another required integration change for this execution API. Preserve
supplied private-table scope rather than always moving roots to the task table.
Allocation failures and malformed-source partial publication need independent
original observations before specifying their final behavior.

## Parent class-completion reference

`tools/test-i386-exe-puts-parent-classes.py` and `ParentClasses.HC` cover forward
completion, inheritance, target layout, inherited member access and retained
function code after the parent returns. The original reference passes mask 127
and the post-parent call in `build/exe-puts-parent-classes-original-v1`.
Compiler 64 prepares ownership-aware release of old source metadata during
completion; it does not yet admit active-parent overlay tables. Its cross-build
passes in `build/parent-metadata-runtime-cross-v1`; runtime regression checks
are recorded separately.

## Owner identity implementation

Compiler 65 records the frontend pointer in CI386CmpCtrl only after construction
finishes, rejects duplicate construction, and adds I386FrontendTableOwner. The
lookup walks active compiler controls and verifies exact frontend/table/bucket
parser records and their sizes, context identity, task ownership and unlocked
state. The builder requires the helper export. This preparatory change does not
relax I386FrontendTableValid or change publication destination/ownership.
Its source epoch requires fresh build and runtime qualification independently of
the Compiler 64 passes above.

## Compiler 66 transfer candidate

The implementation now admits a validated parent overlay and prepares transfer
of the full selected parser graph, code descriptors and relocations, resident
bindings, and managed private macro payload ownership. Commit moves those nodes
into the parent queue and joins retained frontend lists. Parent completion
metadata is released through its actual control. Custom outer exception unwind
attempts publication of the completed graph before releasing the control.
This is a candidate, not a passing contract: qualify it against all original
references and prior native execution checks on a fresh image. Allocation
failures, malformed partial publication, exact unwind recovery and release
acceptance remain open.

## Compiler 66 native qualification

The four native gates in `build/parent-publication-{context,parent-publish,
parent-classes,parent-unwind}-native-v1` pass on the fresh cross-v1 image.
They cover supplied context/options and exact caller heap recovery, scalar
publication and post-parent function use, forward completion/inheritance and
member access, and completed declarations surviving an outer custom exception.
Each uses 486 without FPU, 8 MiB, exact VGA checks, independently verified saved
fixture bytes, and matching input pins. Six existing execution API regressions
are being checked on this image. Private macro transfer, relocation-bearing
publication breadth, allocator failures and exact exceptional unwind recovery
remain required before claiming complete compiler-context or release closure.

## Direct lexer macro ownership repair

The original parent-macro reference passes mask 127 and post-parent macro and
function use. Compiler 66 fails at outer publication with no compiler errors or
runtime exception: direct lexer publication placed raw arena payloads in the
parent overlay without parser ownership records. Compiler 67 prepares all
missing nodes, then adopts the source-table macro metadata into its control's
queue before graph validation. Failed preparation frees only new nodes, leaving
macro payloads owned by their existing table. Runtime repair qualification is
pending and must include the prior four parent-context contracts.

## Repeated exceptional unwind recovery

The original `ParentRepeatUnwind.HC` reference passes mask 15 across ten cycles:
custom exception, parent boundary, caller data heap and caller code heap all
recover after empty child-context execution followed by an outer exception.
Compiler 67 fails at mask 3 in
`build/parent-macro-parent-repeat-unwind-native-v1`: both heap checks fail.
Compiler 68 records the pending expression code, clears that borrow after normal
completion, and releases interrupted code without CCF_HAS_MISC_DATA before
preserving completed child publication. Persistent code/data remains eligible
for normal publication. Fresh rebuild and runtime repair evidence are pending;
recheck declaration persistence so cleanup does not discard valid child symbols.

Compiler 68 repair qualification passes in the fresh
`build/parent-unwind-runtime-cross-v1` image: repeated unwind recovers both heaps
for ten cycles (mask 15); declaration persistence passes mask 63; macros and
classes pass mask 127 with post-parent use. All four native reports in
`build/parent-unwind-*-native-v1` have matching input pins and saved fixtures,
486 without FPU, 8 MiB and exact VGA checks. Complete allocator-fault and partial
malformed-source behavior remain unqualified.
