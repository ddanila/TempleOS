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
