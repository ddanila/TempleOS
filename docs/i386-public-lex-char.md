# Public lexer character input

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
interruption, or complete terminal lifecycle. The baseline itself changed no production implementation; the shared reader
implementation and its evidence follow below. All C1–C5 milestones remain open.

The implementation must preserve public allocation/free ownership, document
transitions and the shared prompt. Its other dependencies include
`cmp.compiled_lines`, the zero sentinel, printable-character bitmap and original
`LexDollar`; private frontend per-input line counters and arena allocations are
not interchangeable with these public objects. Restoring only a buffer reader
would omit required prompt and document behavior.

## Shared reader implementation

`Compiler/PublicLexCharCore.HC` now holds the byte-identical original
`LexDollar` and complete `LexGetChar` bodies, included by the original compiler
and native console. `LexZeroCore.HC` gives both builds the same zero sentinel
with an include guard so the native export can refer to its definition before
the document reader is compiled. Public controls retain the existing original
allocation and release routines; no private arena control is substituted.

Console service version 235 adds the public character reader and data bindings
for `cmp`, `lex_zeros` and `char_bmp_printable`. The printable array is the same
object already used by native document output. The public reader updates
`cmp.compiled_lines`; other compiler-global tables are not initialized by this
change, and private frontend per-input line statistics remain separate. This
is not complete `cmp` or public compiler qualification.

The native prompt adapter resolves the actual `CmdLinePmt` body from Adam's
shared scope, where startup publishes it with system lifetime. Missing publication
throws; it does not substitute a prompt. The retained terminal loop still bypasses
this public lexer, and public `Lex`/`ExeCmdLine` integration remains open.

The first cross-build stopped at a forward scalar-global address (`lex_zeros`)
unsupported by the compiler. Moving the original definition into the guarded
shared include resolves declaration order. This failed build is preserved under
`build/i386-public-lex-cross-v1`; it is not runtime evidence. Cross-v2 compiled
the reader but rejected the unsupported `#undef` directive afterwards. Removing
that directive preserves the translation-unit prompt alias, as with the console
module's other aliases. Cross-v2 is also not runtime evidence.

## Echo and compiler statistics contract

`tools/test-i386-public-lex-state.py` reads `A\nB` through actual public
`LexGetChar` with `OPTF_ECHO`, temporarily removes `B` from the shared printable
bitmap, and seeds the public compiled-line counter. The stream remains unchanged,
the counter increments once, the file line number becomes two, and the exact
saved document is `A`, newline, cursor byte 0x05. It checks bitmap restoration
and the output-document role. The original v3 result passes mask 63.

Original v1 and v2 recorded mask 55 because the first oracle incorrectly omitted
the saved document cursor. V2 exported the exact bytes; v3 asserts all three
bytes explicitly in both guest and host. This test does not qualify concurrent
compiler statistics, other global fields, rich document commands or error-path
heap recovery.

## Final normal-image contracts

`build/i386-public-lex-cross-v3/kernel.img` is the fresh full image with SHA-256
`856c3fb970e739e8a1adbc454c2c7b912e781c571454a0046827d7f2613dce98`.
The two bootstrap generations and native cross-build pass. All 1,748 production
source hashes and sixteen module hashes match; the kernel remains 419,896 bytes.
`post-export-source-audit.json` records that identity.

Four normal-boot contracts pass on this image:

| Evidence directory under `build/` | Exact checks |
| --- | --- |
| `i386-public-lex-char-native-v1` | Original 26 character values and eight state words, including prompt refill/help |
| `i386-public-lex-state-native-v1` | Echo bytes `A\n\x05` and six checks, mask 63 |
| `i386-public-characters-native-v4` | Sixteen ones: buffer/character/include ownership and exact caller heap recovery |
| `i386-public-control-lex-v1` | Twelve ones: public control allocation, size, flags, filename and heap recovery |

Each also completes arithmetic with the exact result glyph check. Independent
`terminal-audit.json` files recheck every current execution input, unchanged boot
bytes, all original file tuples, exact packaged fixture bytes, allocation
integrity, and successful startup without rejected input. Prompt stream/state
exports match the retained original v2 exports exactly. These contracts do not
close all lexer or terminal behavior.

The broader 24-check token fixture is still rejected at `Lex`, line 12, on this
same image (`i386-public-token-lex-baseline-v1`). Its independent terminal audit
confirms successful startup and unchanged inputs/volume. The failure occurs
before behavioral assertions; none of that token contract is claimed to pass.

Both TCG memory regressions pass on the final image: normal 8 MiB startup and
16 MiB diagnostics reach successful shared startup and match all 307,200 welcome
pixels exactly. Diagnostics complete both program, code-heap ownership and
file-break cleanup phases. `final-contract-audit.json` checks these gates,
source-image identity and all four contracts together. These concurrent runs
do not qualify the isolated startup-time budget or C5 native generations.
