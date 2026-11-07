# Public lexer character input baseline

The restored public command prompt does not yet restore original terminal input.
Original `UserTaskCont` allocates a public `CCmpCtrl` with `CCF_CMD_LINE`,
`CCF_PMT` and `CCF_QUESTION_HELP`, then enters `Lex` and `ExeCmdLine`.
`LexGetChar` refills exhausted prompt input through `CmdLinePmt` and owns the
replacement buffer in that control's root `CLexFile`. Native retained terminals
still enter `NativeTerminalInput`, while private `I386LexRawChar` rejects
`CCF_PMT` and `OPTF_ECHO`. Redirecting the public name to that private reader
would not restore this behavior or public allocation ownership.

`tools/test-i386-public-lex-char.py` calls the actual public `LexGetChar` symbol
through its hash record. Its fixture uses real `CmpCtrlNew`, `LexAttachDoc`,
`CmpCtrlDel` and queued `In`/`GetStr` input. Four groups assert 26 exact character
values and eight exact state words:

- Buffer input skips `CH_CURSOR`, normalizes `CH_SHIFT_SPACE`, replays one
  character through `CCF_USE_LAST_U16`, counts newline, and repeats EOF.
- A plain document produces `xy\nz`, releases its include frame, resumes root
  buffer `R`, and reaches repeated EOF.
- With prompt help enabled, a blank line remains blank, the first nonblank `?`
  produces `Help;;\n`, and the second `?` remains `?\n`. The first blank does
  not consume first-line help. The prompt counter is two and line number four.
- With help disabled, `?` remains literal; the prompt counter still increments.
  Put/display/border roles and the task prompt flag are checked after input.

The exact state table is `[2,1,1,2,4,1,1,1]`. Values and state are exported as
little-endian I64 words; no addresses or timing are normalized into the oracle.
The expected values are specified independently in the host runner.

## Evidence

`build/i386-public-lex-char-original-v2` passes against pinned reference
`c26482bb6ad3f80106d28504ec5db3c6a360732c`.
`build/i386-public-lex-char-native-baseline-v2` uses the unchanged normal
cross-v6 image and fails with `LexGetChar is not bound in the native public
symbol chain`, before behavioral checks. V1 has the same observed results;
v2 guards null cleanup in the fixture's exception handler. Each final evidence
directory contains an independent `terminal-audit.json` for execution inputs
and reference or packaged-volume preservation.

Run into fresh output directories:

```sh
python3 tools/test-i386-public-lex-char.py --out build/public-lex-original-new
python3 tools/test-i386-public-lex-char.py build/i386-command-prompt-cross-v6/kernel.img --out build/public-lex-native-new
```

This baseline does not qualify rich document commands, binary inserts, quoted
Dollar conversions, echo, nested include replay, exceptions or heap recovery.
It does not exercise tokenization, physical keyboard input, `ExeCmdLine`,
interruption, or complete terminal lifecycle. No production implementation is
changed by the baseline; all C1–C5 milestones remain open.

The implementation must preserve public allocation/free ownership, document
transitions and the shared prompt. Its other dependencies include
`cmp.compiled_lines`, the zero sentinel, printable-character bitmap and original
`LexDollar`; private frontend per-input line counters and arena allocations are
not interchangeable with these public objects. Restoring only a buffer reader
would omit required prompt and document behavior.
