# Original command prompt contract

The retained search-results terminal preserves its document and interactive
execution, but omits the original elapsed-time/result line and current directory
before the prompt. This is an execution-path difference: original `UserTaskCont`
uses the public lexer, whose exhausted `CCF_PMT` input calls `CmdLinePmt`.
Native `NativeUserTaskCont` enters `NativeTerminalInput`, whose
`NativeConsolePrompt` writes `> ` and inserts a prompt marker directly.

`tools/test-i386-command-prompt.py` calls the actual public `CmdLinePmt` through
its hash entry and supplies real queued input to `GetStr`. It does not substitute
a prompt implementation. Six cases check no pending answer, signed -7, F64
3.75, a void result, blank input, and unsigned all-ones. Elapsed time is seeded
to 1.25 so the formatting comparison is exact rather than normalized away.

The expected prefixes include `1.250000s ans=0xFFFFFFFFFFFFFFF9=-7`,
`1.250000s ansf=      3.7500000`, and the void-only `1.250000s` line, each
followed by the actual current directory and `>`. Unsigned all-ones displays
`0xFFFFFFFFFFFFFFFF=-1`, as the original formatter uses the signed decimal
conversion regardless of the stored integral type. No-answer cases have no
elapsed/result line. The comparison checks this prefix, not the entire saved
input document.

The returned strings retain leading whitespace, trim trailing whitespace,
duplicate a final semicolon for lexer lookahead, and append newline. The exact
24-word state table checks answer preservation (void resets it to zero),
consumption of `new_answer`, clearing of the task prompt flag after return, and
preservation of put/display/border roles. It does not sample the flag while
input is blocked.

## Evidence

- `build/i386-command-prompt-original-v2/result.json`: all six cases pass;
  input hashes unchanged. This is the current fixture with missing-symbol
  cleanup. Original v1 also passed, but predates that cleanup correction.
- `build/i386-command-prompt-native-baseline-v1/result.json`: fails with
  `CmdLinePmt is not bound in the native public symbol chain`, before any
  behavioral cases. It uses the normal handoff-v2 image without injecting a
  prompt implementation. The independent terminal audit verifies every input
  hash, preservation of all original file tuples, the sole fixture addition,
  and volume integrity. The original terminal audit also verifies restored
  reference files, the exact Once fixture and exported state bytes.

Run into new output directories:

```sh
python3 tools/test-i386-command-prompt.py --out build/command-prompt-original-new
python3 tools/test-i386-command-prompt.py build/i386-terminal-handoff-cross-v2/kernel.img --out build/command-prompt-native-new
```

## Implementation boundary

The full original body is in `Compiler/CMisc.HC`. Its normal path depends on
existing public task answer fields, formatting, `DirCur`, allocation, `GetStr`,
and the character whitespace bitmap. Its debug/raw path calls `RawDr`, which
is not currently published by the native debugger. Original `RawDr` also
requires register presentation, raw cursor placement and `Ui` disassembly;
a no-op replacement would lose debugger behavior.

The public compiler control already has its own allocation/ownership path in
`Compiler/PublicControlCore.HC`; it must not be replaced with the private arena
constructor. Public `LexGetChar`/`Lex` and interactive input remain missing.
The private `I386LexRawChar` explicitly rejects `CCF_PMT`, so adding a symbol
alone would not restore the original interactive execution path. The next
integration must preserve the complete prompt body, its debugger dependency,
public lexer ownership, and `UserTaskCont` execution/error cleanup.

This is a C1/C2/C4 reference contract and a visible implementation gap, not
terminal qualification. Physical keyboard input, Shift-Esc task exit, raw/debug
presentation, exceptions, exact heap recovery and full lexer/terminal behavior
remain open. No C1–C5 milestone is closed by these six cases.
