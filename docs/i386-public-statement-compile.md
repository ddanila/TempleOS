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
(`build/i386-public-statement-compile-native-baseline-v1`). Separately, loading
the complete actual `LexStmt2Bin` body after the existing 23 source stages stops
at its `QueDel` call: the native public queue header does not declare that API
(`build/i386-statement-compile-source-baseline-v1`). That diagnostic precedes
execution of the statement contract. No statement execution or temporary-frame
support is qualified by this source-loading failure.

The source-loading experiment and temporary-frame helper remain work in
progress. Normal compiler delivery, stream/assembly/AOT closure and the full
C1–C5 release gates remain open.
