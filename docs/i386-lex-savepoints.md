# Public lexer save points

Normal startup now exposes LexPush, LexPopRestore and LexPopNoRestore with their
original public signatures. Compiler/PublicLexSavepointsCore.HC is the exact
previous LexLib.HC prefix, shared by the original compiler and native Console.
The state helpers retain the active include link while restoring the remaining
file record; a snapshot's next pointer belongs to the separate save-point stack.
Snapshots borrow input buffers, file names and document payloads.

Console 246 appends function exports 655–657. All existing slots and the 21-word
data-export bitmap remain unchanged; the table has 658 entries. The strict
builder requires all three actual functions. Compiler runtime 85 and its layout
are unchanged. The source-loaded type/declaration/function pipeline now calls
the delivered functions instead of compiling its own save-point implementation.

Run tools/test-i386-lex-savepoints.py --out OUT for the actual original system,
or supply a native image before --out. Original-v2 and normal native-v1 match
mask 8191: initial character state, allocation and borrowed payloads, nested
push/replay/discard, lookahead, line state, token fields remaining separate,
pending-snapshot destruction, caller-owned root buffers, preserved include-parent
links, DolDoc cursor replay across text/newline entries and exact data/code heap
recovery. The previous normal image rejects the first LexPush call at line 8
(baseline-v2), before behavior. The initial twelve-case reference and baseline
are retained separately; the final fixture adds DolDoc coverage.

Independent audits check current input hashes, exact fixtures/results, fixture-only
native volume changes, unchanged boot bytes, the shared body and export ABI.
Both x86-64 bootstrap generations rebuild and boot, and the full native build
passes all 1759 source pins and the 386 instruction audit. These bootstrap
rebuilds do not establish bit identity or C5 native-generation qualification.

Both 8/16 MiB profiles match all 307200 welcome pixels with normal startup.
The 16 MiB diagnostic completes both program, code-ownership and file-cleanup
phases. See build/i386-lex-savepoints-memory-audit.json.

The full source-loaded compiler run passes all twenty-three stages, 24 token
cases, graph mask 63, nine basic executions, six type checks, eleven runtime
cases, retained-code completion, eight class/header checks and seven ordinary
function cases with exact original return bytes and both heap recoveries. Its
independent audit checks all 1032 input hashes and proves the candidate contains
no save-point implementation copies. See
build/i386-lex-savepoints-functions-native-v1/terminal-integration-audit.json.

Restore is valid only within the same active include file, as documented by the
original implementation. Allocation/failure order is unchanged: preparation runs
before allocating the snapshot. Allocation failure, concurrent mutation, invalid
records, cross-file restore and broader compiler/API/workflow qualification remain
open. Full normal token/expression compiler delivery and C1–C5 remain open.

Evidence: build/i386-lex-savepoints-{original,baseline}-v2,
build/i386-lex-savepoints-native-v1/terminal-integration-audit.json,
build/i386-lex-savepoints-cross-v1/source-body-abi-audit.json and
build/i386-lex-savepoints-reference-baseline-v2-audit.json.
