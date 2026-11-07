# Public statement compilation frontier

The original x64 `LexStmt2Bin` reference passes the 22-word contract in
`tests/guest/i386-public-statement-compile/Reference.HC`. Run it with:

```
python3 tools/test-i386-public-statement-compile.py --out build/statement-original-fresh
```

The contract compiles scalar, 64-bit literal, comma, block, conditional and F64
statements. It deletes each controller before calling the returned code, checks
valid-case data/code heap recovery, an empty statement's pointer-width sentinel,
and malformed-input rejection. Conditional and void blocks are checked through
observable side effects: their incidental return registers are not a contract.
The F64 side effect uses `1.25+2.5`; the original compiler's literal `3.75`
produced a two-ULP difference in the earlier reference. Malformed input waits for
the original Adam server before exercising exception handling.

Evidence: `build/i386-public-statement-compile-original-v4/result.json` passes
with unchanged pinned inputs; `terminal-input-audit.json` independently verifies
those inputs and the retained 176-byte output. Earlier failed references and
raw records remain in v1–v3. These failures are not native regressions.

A direct native run accepts a disk image as its positional argument. The current
normal native API baseline fails at the missing public `Lex` entry point
(`build/i386-public-statement-compile-api-baseline-v1`). Separately, loading
the complete actual `LexStmt2Bin` body after the existing 23 source stages stops
at its `QueDel` call: the native public queue header does not declare that API
(`build/i386-statement-compile-source-baseline-v1`). That diagnostic precedes
execution of the statement contract. No statement execution or temporary-frame
support is qualified by this source-loading failure.

That source-loading failure is historical. The verified follow-up below closes
this stage; normal compiler delivery, stream/assembly/AOT closure and the full
C1–C5 release gates remain open.

The implementation candidate shares `Compiler/I386/CompileFrame.HC` between the
production cross-compiler and the source-loading diagnostic backend. It supplies
an allocator-owned temporary ENTER and function descriptor for top-level code,
recognizes both RETURN_VAL forms, converts RET to LEAVE, and restores the prior
function descriptor and releases the temporary node before controller cleanup.
Ordinary functions retain their existing frame. Type inference for RETURN_VAL2
uses the optimizer's backward scan and effective result conversion flags.

The normal native public header supplies `INVALID_PTR=U32_MAX`, matching the
32-bit truncation of the original I64_MAX sentinel. I64 remains 64 bits. The
source runner no longer injects a private sentinel definition or replaces the
LexStmt2Bin body. Assembly, AOT-store and stream dependencies remain explicit;
this candidate does not provide the normal public Lex entry point.

The production entry point is separately verified by
`tools/test-i386-cross-statement.py`:

```
python3 tools/test-i386-cross-statement.py --out build/cross-statement-fresh
```

`build/i386-cross-statement-production-v7/result.json` passes six statements
through actual CmpI386Buf, CmpJoin, LexStmt2Bin and I386COCCompile. Each AOT has
one bounded MAIN entry and no external relocations, absolute references or heap
globals. The test embeds the complete emitted bytes in an ELF32 executable and
calls each entry independently of the HolyC host. Exact EDX:EAX results cover
scalar, full-width literal, comma, block, F64 arithmetic and full-width shift/XOR
statements. All pinned sources and bootstrap binaries pass an independent
terminal audit. This isolated probe retains its AOT records until VM exit and
does not claim heap recovery or native public compiler delivery.

The final source-loaded suite in `build/i386-statement-frame-source-v3` publishes
all 24 stages, including the complete unchanged LexStmt2Bin prefix of CMain.HC.
Every earlier lexer, parser graph, expression, type, runtime, lifetime, class and
ordinary-function regression passes. The 22 statement words match all 176
original bytes exactly, including post-controller execution, both valid-case
heap recoveries, empty sentinel, syntax rejection and full-width I64. Its
terminal audit independently verifies all 1,036 inputs. This uses a source-loaded
compiler and diagnostic allocation/linking adapter with the shared production
frame helper; it does not establish normal public native Lex/LexStmt2Bin delivery.

The production probe explicitly declares unsupported intrinsic opcode 0x64
(CLFLUSH), requires the target backend diagnostic at opcode 64, then compiles and
executes all six valid statements, checking recovery through the temporary-frame
error path. The reference waits for RLf_ADAM_SERVER before rejection, as required
by the original error handling. v4 omitted that prerequisite and was cancelled
with explicit evidence; it is neither a production failure nor a passing run.
v5 checked rejection too weakly; v6 required the backend diagnostic and caught
that CLFlush name lookup failed before reaching the backend. v7 uses the explicit
intrinsic declaration and proves the intended target error path.

The final full image has compiler runtime 88, console 248 and 454,184 native
kernel bytes. Both x64 bootstrap generations and all 1,762 source pins pass.
Carry and ClassMeta retain their qualified workflows and complete original
outputs on this candidate; the inventory appends these regressions without
qualifying another program. The 8 MiB normal and 16 MiB diagnostic boots each
match all 307,200 welcome pixels. The latter passes both program, code ownership
and file-break cleanup phases. Its first 300-second observation timed out;
the unchanged-image recheck completed with a larger observation window. See
`build/i386-statement-frame-memory-audit-v3.json`; this is not a C5 startup-budget
or native-generation/full-suite qualification.

The extracted queue body deliberately retains its original trailing separator
blank line for byte identity; the diff whitespace check reports that one line.
