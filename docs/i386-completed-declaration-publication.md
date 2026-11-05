# Completed declarations survive execution failure

The original ExePutS does not roll back a completed function declaration when a
later statement breaks, throws or fails to parse. This is a source/API behavior,
not just an answer-display rule. The former native implementation staged
declarations until the whole input succeeded. The experimental checkpoint below
publishes completed top-level declarations between statements; it does not yet
qualify every declaration or source-context case.

`tools/test-i386-break-publication-reference.py` executes the pinned original
ExePutS with both default flags and CCF_CMD_LINE. Eight cases declare a distinct
function returning 99, then execute an explicit Break, a custom runtime throw,
a later undefined type, or a synthetic pending-break assignment. The fixture
waits for real server readiness, captures return/exception/answer/type/flags,
looks up the actual function in the task hash table, and calls its real address.
A synthetic pending bit is cleared only after its state is captured. No compiler
or exception routine is substituted.

`build/i386-break-publication-reference-v3/result.json` passes all eight cases
with unchanged inputs. Every completed function remains present and callable as
99. The completed answer stays 41 through Break, custom throw and parse error;
the pending assignment leaves 2048. Custom throws propagate to the surrounding
catch; Compiler/Break are absorbed by ExePutS. Only the parse-error cases print a
diagnostic. The initial four-case v1 was an observation, not the qualified
reference; v2 adds command-line flags and exact assertions. The final v3 also
requires a nonzero host exit if input pins change, and passes the same eight
cases. The native red run uses the already qualified v2 capture.

`tools/test-i386-break-publication.py` checks these source patterns through the
normal native public API and exact keyboard-driven checkpoint pixels. Its
wrapper catches runtime exceptions, and a later command must call the completed
function and get 99. It starts with the custom throw so missing public Break
cannot hide a publication failure. Both compiler flags and all eight failure
cases remain in the corpus.

The combined experimental image fails at the first function lookup in
`build/i386-break-publication-native-red-v3/result.json`, with unchanged inputs:
ExePutS and its caller return after the caught custom throw, but NativePub01 is
undefined instead of callable as 99. Later cases are not qualified. Earlier
native v1/v2 stop sooner because the child source's public Break identifier is
undefined; their driver snapshots and results are preserved. The unreached
parse-diagnostic expectation was corrected before v2, and v3 reorders the cases
to isolate publication without replacing any required source behavior.

Any implementation must preserve completed declarations while safely
unwinding transient compiler state. It must retain owners for code, metadata,
strings and referenced classes, and must not publish invalid partial graphs.
Default public source execution and command-line execution both require this
behavior. Class/global-variable publication, forward declarations, redefinition,
cleanup/resource behavior and the missing original Break interface need further
coverage. The original CMain.HC leaves failed controls alive (`okay` suppresses
CmpCtrlDel); the native port must preserve the observable declarations without
copying that cleanup limitation.

The passing 146-command native compiler group and 17-command physical hotkey
group remain useful native regression evidence, but their legacy rollback
expectations do not qualify original declaration publication. In particular,
BreakPrivate being undefined after interruption must be reconciled with the new
original observation. Complete C4 and C1-C5 remain open.

The eight-case original declaration-state reference also passes in
`build/i386-declaration-state-reference-v3/result.json`. A completed forward
class remains size 8 after a later undefined type; a string global remains
readable after the same failure. Repeated class, global and function definitions
are accepted. A caller compiled against the first function keeps returning 1
after the new definition returns 2. The original also retains the hash entry for
a malformed function after a preceding valid function. These are required
observations, not permission to publish an invalid native ownership graph.

The first incremental-publication candidate reaches class redefinition and
fails there in `build/i386-declaration-state-native-v1/result.json`; the preceding
forward completion survives the error and remains usable. All input pins remain
unchanged. The strict native corpus retains the later global redefinition,
old-caller binding and malformed-function entry checks even though they are
unreached in this run.

The shadowing candidate advances through class redefinition and the existing
holder pointer in `build/i386-shadow-declaration-native-v1/result.json`, then
fails at the first string-global comparison. The subsequent focused hash lookup
also reports the global absent; a missing declaration, rather than string
comparison alone, needs repair. The candidate's 1,362 packaged source/document
files match its dirty source snapshot. This is partial progress, not a passing
declaration-state corpus.

The public-Break candidate reaches the synthetic pending-break case in
`build/i386-public-break-publication-native-v1/result.json`, then loses that
case's function. Extending child-publication unwind alone does not repair it.
The shared statement parser consumes global declarations and can continue into
a following statement before returning to the command publication boundary.
The next candidate adds an explicit return-after-declaration option for native
commands; function and block parsers retain their existing defaults. Full
publication and answer regression results are still required for that candidate.

The parser-boundary candidate passes all 19 native publication commands in
`build/i386-answer-break-oracles-v1/build/i386-declaration-boundary-publication-v1/result.json`,
with unchanged image, original reference and runner pins. Completed functions
remain callable after all eight default/command-line failure cases, including
pending breaks. The source audit matches all 1,362 packaged source/document
files. This precedes a further policy repair that keeps low-level transactions,
modules and atomic headers strict while allowing ordinary command redefinition;
the final policy candidate still needs its own native verification.

The declaration-state run reaches the malformed-function source after passing
class/global/function redefinition and retained old-caller binding. It stops
at command 22 because its expected diagnostic was incorrectly `Undefined
identifier`. The pinned original `guest/state-7.DD` explicitly contains `Invalid
lval` and `Compiler Parse Error`; the native log reports `Invalid lval` too.
The driver now requires that specific native diagnostic prefix, preserving the
source and all subsequent checks, including the required malformed-function
hash entry. The v1 run remains a failure, and those later checks are unqualified.

## Native top-level publication checkpoint

Ordinary command execution now returns from parsing after each complete global
declaration, then transfers its validated ownership graph before processing the
next statement. Prototype semicolons belong to that boundary too. Explicit
`I386_INPUT_ATOMIC_DEFINES` header transactions retain buffer-level publication.
Low-level frontend transactions and module bindings still reject namespace
collisions; only ordinary command publication permits interactive shadowing.
Older code/data stays owned by the task for previously compiled callers. A
completed child graph also survives a later runtime exception/break in its
caller, using the existing graph validator rather than publishing partial IR.

The public Break binding follows the original current-task policy: Shift-Esc
message conversion, or wake/wait reset, drive/block release, message flush and
Break exception. Its measured tests here cover the publication scenarios, not
all message/lock side effects or the still-missing public BreakLock/BreakUnlock
interfaces. No exception routine is replaced with a success stub.

The final command-policy runtime passes all 19 publication commands and all 34
answer/prompt commands, with unchanged pins, in
`build/i386-command-policy-publication-v2/result.json` and
`build/i386-command-policy-answers-v2/result.json` inside the experimental
worktree. The same runtime passes the unchanged RegistryDemo twice in one boot
with actual registry document reload; the primary checkout records that proof
in `build/i386-command-policy-registry-warm-v2/result.json`. All 1,387 unrelated
source-image files remain unchanged. Host disk exhaustion ended the earlier v1
attempts; their `host-failure.json` files preserve that separate classification.

The strict declaration-state v2 run passes class/global/function redefinition,
retained old-caller binding, and calling OriginalGood as 99 after a malformed
successor. It fails at command 24: OriginalBad is absent, while the original
retains its hash entry. The expected value remains 1. Persistent unresolved
prototypes, malformed-function metadata, declarations inside failing compound
statements, arbitrary inherited hash contexts and allocation-pressure ownership
still need broader original comparisons and implementation. C4 remains open.

Both original bootstrap generations and the 386 audit pass. All 1,362 packaged
source/document files match the candidate image. The 16 MiB TCG/486 diagnostic
guest in `build/i386-command-policy-diagnostics-v4` completes both boot and
worker phases: 54 input cases, 28 publication cases, public-header and executable
child lifetime checks, followed by all 307,200 welcome pixels. This is not the
complete build/rejection/install gate or two native C5 generations.

Three earlier diagnostic failures are retained with frozen packaged probe
sources and hashes. The first assumed an 8 MiB request must fail even with
16 MiB RAM; the test now frees a successful request and forces exhaustion above
every supported profile. The second expected a completed function to roll back
after break; it now calls 99, removes the retained graph and requires exact heap
recovery. The third counted a declaration and call as one parser batch; the
lifetime probe now requires two commands and keeps all execution/ownership checks.
The production-module identity report proves that only CompilerProbe.t32m changed
across these fixture iterations. The full retained compiler-command regression
with updated original-derived oracles passes all 146 commands at 8 MiB KVM
486 without FPU/live WinMgr in
`build/i386-command-policy-compiler-v1/result.json`, with unchanged inputs. Its
independent pointer oracle checks the actual published bad-string pointer and
then exact VGA formatting. The source-retention audit preserves every original
submitted source occurrence. This regression retains native unsupported-prototype
expectations and does not close the separate original-fidelity gaps above.

## Compound statements and incomplete headers

`tools/test-i386-declaration-frontier-reference.py` passes ten actual original
cases in `build/i386-declaration-frontier-reference-v2/result.json`, with flags
0 and CCF_CMD_LINE and unchanged inputs. A completed function remains callable
as 99 after a later throw or parse failure inside the same compound statement;
a string global inside a throwing compound statement remains readable as 97.
Each failing source preserves the preceding task answer 23. A malformed function
retains its actual header: Cf_EXTERN, two arguments, default integer 7 and string
AZ, and the real UndefinedExtern address. Calling that header uses its defaults,
prints the actual Undefined Extern diagnostic and throws UndefExt. The fixture
inspects live metadata and calls the real routine, without replacement stubs.

The first capture's numeric records matched, but it freed exported document
buffers before the host collected them at DONE. Reuse corrupted the diagnostic
captures. Its frozen fixture and failed result remain preserved; v2 keeps export
payloads and borrowed failed-control source buffers alive and passes all numeric
and diagnostic assertions. No diagnostic expectation was weakened.

`tools/test-i386-declaration-frontier.py` retains all ten cases, including saved
put-document diagnostic routing. Its first native run stopped during setup
because the inspector needed the canonical SymbolTypes header. The v2 driver
loads that actual header, then reaches the first compound-source case in
`build/i386-declaration-frontier-native-v2/result.json`. The custom throw and
answer 23 survive, but the required function hash lookup returns 0 instead of 1.
Inputs are unchanged. Later cases remain unreached, not passing. This is the
next ownership/publication requirement beyond the measured top-level repair;
complete C4 and C1–C5 remain open.


## Completed declarations inside failed compound statements

The declaration-frontier candidate records completion separately from hash
insertion. Function completion follows code generation and fixup validation;
globals are marked after initializer processing, before the following token is
lexed. Class completion follows the shared class parser. Ordinary command
recovery first retires registered IR and saved optimizer views, then attempts
the same two-pass ownership transfer used by successful publication. The
terminal-only entry point retains the error count and requires every staged
core declaration to be complete. Atomic headers and module transactions do not
use this recovery path. Parent publication transfers readiness records along
with the validated graph, including canonical class-completion identities.

Diagnostics now follow a redirected actual put document through DocPrint;
normal terminal presentation keeps its existing path. This supports real
DocSave-based message checks without introducing a diagnostic capture stub.
Full original diagnostic bytes and styles remain a separate fidelity gap.

The current candidate passes both original x64 bootstrap generations, native
cross-compilation, the 386 instruction audit and the 1,362-file source-image
audit (`build/i386-completed-frontier-v2` and
`build/i386-completed-frontier-source-audit-v1.json`). Its unchanged-image answer
regression passes all 34 commands in
`build/i386-frontier-answer-regression-v1/result.json`. The 16 MiB TCG diagnostic
run (`build/i386-completed-frontier-diagnostic-v1`) reaches normal startup after
both boot and worker compiler probes, with an exact 307,200-pixel welcome frame.
These are focused checks, not native C5 rebuild generations or a complete gate.

The full ten-case frontier test keeps the failed-header expectations intact.
Completed compound functions after throws/parse failures and the string global
after a throw now survive in both flag modes, while preserving answer 23 and
actual redirected-document messages. A malformed function header is still
absent. Unfinished siblings still prevent publication of the whole staged
graph; selective graph recovery, persistent extern/default metadata, actual
UndefinedExtern behavior and late binding remain open C4 work. No inventory
entry or C1–C5 milestone is promoted by this repair.


The top-level publication regression also passes all 19 commands with unchanged
inputs (`build/i386-frontier-publication-regression-v1/result.json`). The full
frontier run is retained as a failure at command 35, the malformed-header hash
lookup, with unchanged input hashes and a frozen driver in
`build/i386-completed-frontier-native-v1`. Its preceding six compound cases and
all 30 per-case checks passed. The default driver still runs all ten cases;
`--compound-only` explicitly selects the six completed-declaration cases for a
separate focused result and does not qualify failed headers or unresolved calls.


The separate six-case compound run now passes all 35 commands, including
cleanup and a final 42, with exact pixels and unchanged inputs in
`build/i386-completed-compound-native-v1/result.json`. This independently
qualifies the completed-declaration repair while the ten-case failure remains
preserved. The next candidate adds parsed-header readiness and the real
UndefinedExtern export/exception path; it is not yet qualified by native tests.


## Persistent extern and caller binding reference

`tools/test-i386-extern-binding-reference.py` passes sixteen original cases in
`build/i386-extern-binding-reference-v3/result.json`, with unchanged inputs.
Each flag mode declares an extern with integer default 7, compiles a caller,
calls it unresolved (real UndefExt and saved-document diagnostic), defines the
target as a+90, then shadows it with a function returning 101. The original
reuses the extern descriptor for the first definition, fixes the already
compiled caller to return 97, and creates a new descriptor for the later
redefinition. The old caller keeps returning 97; direct lookup calls 101.
The actual unused-argument warning during redefinition is also required.
`tools/test-i386-extern-binding.py` preserves these sources and checks native
answers, descriptor identity and actual saved documents. Its native candidate
run remains pending; this reference does not establish native late binding.

The first experiment used a string default and observed old callers returning
7 rather than the assumed 97 after the initial definition. Its frozen fixture,
driver, exported documents and unchanged-input failure remain in
`build/i386-extern-binding-reference-v1`; string-default storage lifetime is a
separate investigation, not inferred compatible. The integer-default v2 had
all numeric rows correct but omitted the real unused-argument warning from its
document oracle. V3 keeps the source and requires that warning. Nothing is
substituted for UndefinedExtern or for actual guest compilation/execution.

The header candidate also exposes a stale diagnostic expectation: low-level
statement case 11 executes an unresolved function, so its actual original
exception is UndefExt rather than Compiler. The first candidate diagnostic
failure and exact packaged probe source are frozen in
`build/i386-persistent-header-diagnostic-v1`. Only that case's exception oracle
changes; its unwind, heap, task lifetime and interrupt checks are retained.


## Native failed-header checkpoint

The header candidate passes all ten original-derived cases / 55 commands at
8 MiB KVM 486,-fpu with live WinMgr, exact pixels and unchanged input hashes in
`build/i386-persistent-header-native-v1/result.json`. Both malformed headers
remain present with Cf_EXTERN, integer default 7, string default AZ and the
actual exported UndefinedExtern address. Both real unresolved calls preserve
answer 23, emit a saved-document diagnostic and throw UndefExt. Completion of
argument parsing is recorded independently from body completion. Terminal
recovery retires the failed body view only for a validated completed signature;
error counts and whole-graph ownership checks remain in force. Module
transactions continue to reject unresolved publication.

Both original bootstrap generations, cross-build, 386 audit and the 1,362-file
source audit pass for `build/i386-persistent-header-v3`. The v2 ten-case image
and v3 have identical production modules; only CompilerProbe.t32m changes to
require UndefExt in statement case 11, as recorded in
`build/i386-persistent-header-module-identity-v1.json`. The next diagnostic run
gets through that statement check and stops at input case 12, whose legacy
catch/persistence oracle assumes Compiler and rollback for a prototype call.
That failed run and exact packaged source are frozen. Input case reconciliation,
extern descriptor reuse, retained caller patching, and complete diagnostic
cleanup remain unqualified. The sixteen-case native binding run explicitly
fails first-definition descriptor identity at command 17; it is not a pass.

Separately, the earlier completed-compound candidate passes the full retained
146-command compiler group with exact pixels, independent pointer validation
and unchanged inputs in `build/i386-frontier-compiler-regression-v1/result.json`.
It predates the new extern semantics and does not qualify the header candidate's
full command group. C4, all inventory qualification and C1–C5 remain open.


## Live extern executable slot

The shared original expression parser emits IC_CALL_INDIRECT2 through
`&function->exe_addr` for JIT extern calls (static modules use IC_CALL_EXTERN).
`tools/test-i386-extern-retarget.py --original` verifies this behavior in
`build/i386-extern-retarget-reference-v1/result.json`, with unchanged inputs.
Both flag modes create an extern caller, define the target, redirect its live
executable slot to another compatible function and restore it. The caller
returns 97, 101, then 97. A later name redefinition returns 107 through new
lookup while the existing caller keeps 97. The original's raw U0 ExePutS
return bits are captured but deliberately unconstrained; numeric I64 returns
are asserted. No function implementation is replaced with a test stub.

A first-definition-only relative-call patch would miss the slot-redirection
case. The next native candidate therefore emits an actual indirect call
through the stable descriptor slot, with ownership records retained for caller
teardown and explicit symbol deletion. Its native retarget, child-exit and
cleanup checks remain pending. Static module packing continues to use its
separate relocation path; task-local JIT slot references cannot silently be
serialized as relocatable function addresses.


## Indirect-call and lifetime comparisons

The indirect-call candidate (`build/i386-extern-binding-v4`) passes all 69
binding commands, all 42 live-slot commands, all 55 frontier commands and all
18 lifecycle commands, with exact VGA pixels and unchanged inputs. Results are
`build/i386-extern-indirect-binding-native-v1`,
`build/i386-extern-retarget-native-v1`,
`build/i386-extern-indirect-frontier-v1` and
`build/i386-extern-lifecycle-native-v1`. The preceding relative-call candidate
passed basic binding/frontier checks but returned 97 instead of 101 after slot
redirection; its unchanged-input red result and observed frame remain in
`build/i386-extern-retarget-native-red-v1`. The live-slot test distinguishes the
actual original dispatch contract from a first-definition-only patch.

`tools/test-i386-extern-lifecycle.py --original` passes five child-exit cases in
`build/i386-extern-lifecycle-reference-v2`. A child compiles against its parent's
unresolved extern and exits; the parent then has no outstanding usage and can
define/call the target as 42. Native also requires HashRemDel to retire compiled
indirect descriptor borrows to the real UndefExt target before deleting the
descriptor. An old caller must keep throwing UndefExt with answer 23 and an
actual document diagnostic, including after a same-name replacement. This is
an explicit cleanup policy for a deleted-descriptor borrow, not equivalence to
an original dangling dereference. The failed initial experiment preserves raw
U0 return bits and allocator-dependent reuse observations; neither supplies a
defined original return-value contract. Native's task-owned borrow records and
ext_lst bookkeeping still require broader public-metadata/API review.

## Following-include lexer error reference

`tools/test-i386-include-header-reference.py` passes the original seven-field
record in `build/i386-include-header-reference-v4`: a function body followed by
an include containing an overlength identifier retains an unresolved header.
ExePutS consumes the Compiler error, preserves answer 23, and keeps Cf_EXTERN
and the real UndefinedExtern address. An actual call throws UndefExt and still
preserves 23. This verifies the lexer-error boundary; it is not an original ATA
cancellation timing comparison.

Three failed experiments are preserved with frozen fixtures/drivers. Break
inside #exe is caught by nested compilation and does not model a cancelled
include read. #assert 0 is a warning and lets the function complete as 99. The
first overlength-identifier capture checked only HTT_FUN for UndefinedExtern,
missing the kernel export form; the corrected reader handles HTT_FUN and
HTT_EXPORT_SYS_SYM, as the existing frontier inspector already does. No expected
address or routine is substituted.

The diagnostic file-break fixture now requires the actual retained unresolved
header, removes it explicitly, and keeps its exact heap, lock, lifetime,
interrupt and subsequent file/input recovery checks. Its fresh native diagnostic
verification remains pending. The latest cleanup candidate also masks the
symbol teardown transaction and bounds ownership-list validation by actual heap
allocation count. It needs its own final native reruns. Full C4 and C1–C5 remain
open; none of these component results promotes the inventory or a release.


## Scoped extern completion and current native checkpoint

Native ordinary JIT extern calls now use the actual stable executable-address
slot (FF /2 absolute indirect call), not a first-definition-only relative patch.
Completion stages a private replacement, checks signatures and the full graph,
retains old default storage that compiled callers can borrow, and updates the
existing descriptor only at the publication boundary. Later non-extern
redefinitions still create new descriptors. Static modules keep their existing
relocation/fixup path; task-local descriptor-slot references are rejected by
module packing rather than serialized as function-address relocations.

Task-owned usage records retain code owner, byte extent, call-site encoding,
argument/result classes and descriptor identity. Child teardown removes its
borrows before releasing code. Explicit HashDel rewrites outstanding indirect
borrows to the real UndefinedExtern call before freeing the descriptor; the
same-name replacement cannot accidentally bind callers through reused storage.
Pending queues use the private TSY3 scope layout. Native ext_lst borrow tracking
and the cleanup policy remain recorded architecture details requiring broader
API review, not an all-metadata parity claim. Symbol teardown holds interrupt
exclusion, and ownership-list bounds follow actual heap allocation count.

Declaration joining now searches the immediate destination table, matching the
original HashSingleTableFind rule. The original child-shadow reference passes
all defined numeric returns in
`build/i386-extern-child-shadow-reference-v1/result.json`. The previous native
image fails its parent-descriptor check at command 8; the corrected image passes
all 15 commands with exact pixels and unchanged inputs in
`build/i386-extern-child-shadow-native-v1/result.json`. The child calls its local
definition as 42 and exits; the parent retains its unresolved prototype and an
actual call still throws UndefExt with answer 23 and a real document diagnostic.
Explicit completion through an ancestor task's foreign hash context is rejected
until code/storage ownership can be transferred safely; that C4 gap stays open.

The cleanup candidate v6 passes 69 binding, 42 slot-redirection, 55 frontier and
18 lifecycle commands with unchanged inputs in the corresponding native-v2
reports. The final immediate-scope candidate v7 passes both original x64
bootstrap generations, cross-build, 386 audit, the 1,364-file source audit and
the 15-command child-shadow test. The 16 MiB TCG diagnostic run
`build/i386-extern-indirect-diagnostic-v3/verification.json` passes both phases,
54 input cases, both public-header and executable-lifetime checks, both actual
queued-file break/cancellation cases, normal startup and all 307,200 welcome
pixels. Removing the retained FileBreakPrivate header restores the exact heap
baseline before further file reads and arithmetic. The last 69-command rerun
on v7 remains pending at this checkpoint. Full retained command-oracle migration,
whole-gate/current-image checks, selective recovery with unfinished siblings,
partial signatures and all C1–C5 qualification remain open.
