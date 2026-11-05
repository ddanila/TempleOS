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
