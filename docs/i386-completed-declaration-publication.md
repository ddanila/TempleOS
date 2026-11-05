# Completed declarations survive execution failure

The original ExePutS does not roll back a completed function declaration when a
later statement breaks, throws or fails to parse. This is a source/API behavior,
not just an answer-display rule. Native compilation currently stages declarations
until the whole input succeeds, so its earlier rollback checks are not proof of
original compatibility.

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

The next implementation must preserve completed declarations while safely
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
