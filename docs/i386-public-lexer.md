# Public compiler-control and lexer baseline

The original Psalmody source now reaches `CmpCtrlNew` in PsalmodyFile line
203. Native interface 225 rejects that call before application interaction.
The public control and lexer must preserve original ownership semantics;
exporting the private native constructor directly is insufficient.

`tests/guest/i386-public-lexer/Contract.HC` records twenty-four checks in an exact
192-byte table. It covers constructor flags and self-links, input-buffer
identity, current-task symbols, default filename and line, identifier/integer/
floating/string tokens, adjacent-string concatenation and returned ownership,
EOF, borrowed input lifetime, prompt allocation, at-sign handling, and heap
restoration after destruction. It also reads nested include files containing
Psalmody-style tempo and Play statements, concatenated notes and embedded-NUL
lyrics, and checks single-string pointer identity with `lex_next=FALSE`. The independent expected table contains twenty-four
64-bit ones. The runner preserves its source, fixture and input hashes.

Run the original oracle and native candidate into fresh directories:

```sh
python3 tools/test-i386-public-lexer.py --out build/public-lexer-original-new
python3 tools/test-i386-public-lexer.py build/i386-sprite-output-cross-v1/kernel.img --out build/public-lexer-native-new
```

## Preserved results

- `build/i386-public-lexer-original-v1/result.json`: pass, exact table, inputs
  unchanged during execution.
- `build/i386-public-lexer-native-v1/result.json`: fail at `CmpCtrlNew`, fixture
  line 6, before behavioral assertions; inputs unchanged during execution.

Both runs pinned the temporary archive-placement builder version. That helper
was subsequently restored after the unrelated experiment was rejected. Their
recorded input audits describe execution-time stability, not equality to the
current builder. The native image was the unchanged interface-225 Sprite image;
packaging preserved its boot area and original files.

## Implementation constraints and remaining scope

Original `CmpCtrlNew` accepts a public allocation and preserves its pointer.
`CmpCtrlDel` frees it unless `CCF_DONT_FREE_BUF` applies. Prompt buffers and
strings returned by `LexExtStr` use public `MSize`/`Free` conventions. Private
`I386CmpCtrlNew` instead validates arena-owned inputs, adds private control
state and uses arena cleanup. A direct export would violate this contract.

The fixture does not cover document input, general directives, error unwinding,
task death, or all `LexExtStr` modes. These require further oracle coverage and
implementation. The nested include fixture exercises the token pattern used by
Psalmody, but does not execute the full application or qualify its workflow.
This baseline closes no C1–C5 milestone.

## Nested include and song-token extension (2026-11-07)

`build/i386-public-lexer-original-v3/result.json` passes all 24 checks with
unchanged inputs. The added song and notes source files are pinned and included
in the reference ISO and native packaging. Nested includes return to EOF and
restore the initial public heap usage; embedded-NUL lyrics remain intact.

The preceding v2 result is preserved as a fixture error: check 18 expected seven
bytes for the seven-character note string, omitting its terminator. It was the
only failing check. V3 corrects the expected size to eight and reruns the full
original oracle; no production change was needed.

`build/i386-public-lexer-native-v2/result.json` still fails at CmpCtrlNew
before assertions, with unchanged inputs and the nested files packaged.


## Public character-stream oracle (2026-11-07)

`--characters` selects a separate sixteen-check public-input fixture while the
default mode retains the existing 24-token contract. The character fixture uses
CmpCtrlNew, LexGetChar, LexAttachDoc and CmpCtrlDel. It checks cursor-byte
skipping, newline/line-start accounting, one-character putback without advancing
the line, shifted-space normalization, repeated EOF, document include-stack
resumption, borrowed root-buffer identity/lifetime, ordinary document text,
tabs/newlines, and exact caller heap recovery.

`build/i386-public-characters-original-v3` passes the independent 128-byte table
of sixteen 64-bit ones. All recorded input hashes still match. The initial
fixture incorrectly called internal LexIncludeStr: original v1 ended without a
completion marker; v2 screenshots identify the compiler rejection at line 22.
That known-invalid v2 guest was explicitly stopped with its fixture, runner and
screenshot preserved. The corrected fixture constructs the include through
public LexAttachDoc instead. The runner now preserves waiting/failure screenshots
while retaining its overall completion deadline and exact byte oracle.

Native v1 rejects the missing LexGetChar at fixture line 11 before assertions.
The corrected-fixture rerun in
`build/i386-public-characters-native-v2` fails at the same missing call, with
unchanged inputs and before behavioral assertions. This is reference coverage, not an
implementation or compatibility pass. Prompt input, binary document entries,
error/unwind behavior and complete Psalmody workflows remain open.


## Public document attachment (2026-11-07)

Interface 227 exports original LexAttachDoc through
`Compiler/PublicLexDocumentCore.HC`. LexDocRead, the source-entry bitmap and the
attachment body are moved byte-for-byte from the original Lex source, which now
includes that same core. Native file-backed attachments use the public FileRead
dispatcher; this explicitly restores that alias after the original-media helper
includes. Public headers retain the original defaults and parameter order.

The independent `--attachment` fixture checks twelve results: supplied documents
and explicit entries/columns, clamping, copied filenames, parent-buffer resumption
state, new stack entries, reuse of a supplied record, borrowed root-document
lifetime, file-backed loading, empty-document state and exact heap recovery.
For reused records it releases the old filename first. For an empty supplied
document the original attachment stores a plain empty buffer and leaves document
cleanup to the caller; the fixture preserves and checks that behavior.

Original v1 had fixture errors: plain-text DocPrint returns no dollar-command
entry, and a reused lexer-file record's old filename was not released. Original
v2 selects an actual text entry and releases the old filename, then passes all
12 checks in `build/i386-public-attachment-original-v2`. Its execution inputs
were unchanged; the later interface-227 builder verifier update is preserved
alongside `pre-update-build-helper.py`. The native baseline rejects missing
LexAttachDoc before execution. The corrected fixture passes all twelve checks
and concluding arithmetic on interface 227 in
`build/i386-public-attachment-native-v1`, with unchanged input hashes.

Both bootstrap generations pass in `build/rebuild-public-attachment-v2-verified`.
The cross-build, packaging, instruction audit and source audit pass in
`build/i386-public-attachment-cross-v1`. ConsoleRuntime grows from 2,056,210 to
2,059,029 bytes; Kernel changes for the interface version, with unchanged size.
The other fourteen emitted modules are byte-identical. Source-block parity is
recorded in `build/i386-public-attachment-source-parity.json`. The full 16 MiB
diagnostic and exact welcome pass (`diagnostic16-audit.json`); the outer builder
interactive/rejection checks remain running. The fresh suspended 8 MiB KVM
scrolling regression passes all four exact typing/result pixel checkpoints and
restores the refresh flag in `build/i386-public-attachment-scroll-v1`, with
unchanged inputs. This qualifies the
attachment API, not LexGetChar, Lex/LexExtStr, prompt/error handling, complete
Psalmody, or C1–C5.


## Shared public character reader (2026-11-07)

The full original LexGetChar/LexDollar bodies are now shared with console 235.
On the fresh public-lex-cross-v3 image, `i386-public-characters-native-v4` passes
all sixteen original character/include/borrowed-buffer/heap checks. The public
control regression also passes all twelve checks. Separate prompt/refill and
echo/statistics contracts pass; see docs/i386-public-lex-char.md for source
identity, exact outputs and independent volume audits. Public Lex/LexExtStr,
full song loading and terminal execution remain open.


## Source-loaded token integration experiment (2026-11-07)

`build/i386-public-token-loader-v4` loads the complete current original `Lex`
and `LexExtStr` bodies and their shared helpers into a test task on the metadata
image (`i386-hash-source-cross-v1`). It passes all 24 original token, string,
nested-include and ownership checks, including embedded-NUL lyrics and exact
caller heap recovery, then passes the arithmetic glyph check. Its independent
terminal audit compares the exact fixture and 24-word export against original
v3, checks both function bodies byte-for-byte, and verifies unchanged boot bytes,
all original file tuples, exact added sources and volume allocation.

This is diagnostic evidence, not a production lexer. The prototype declares
`LexExcept`, `LexWarn`, `LexExpression` and `PrsStreamBlk` as unresolved externs;
the valid-input contract does not exercise those services. It also suppresses
`Kernel/CharBitmaps.HH` with its include guard and explicitly declares the two
existing kernel bitmap objects needed by the define reader, alongside the
already declared numeric bitmaps. This isolates header integration without
replacing any lexer body. The workaround is absent from production sources.

Earlier preserved experiments locate the failure: v1's combined library is
rejected during publication with exception zero and no compiler errors; v2
publishes declarations and file/member helpers, then rejects the token-helper
section; v3 publishes each helper through identifiers, then rejects the
`LexDefine.HC` section, which includes the shared bitmap header. V4 publishes
all thirteen stages with that header isolated and reaches the full contract.
The exact scripts, staged sources and results are retained under `build/`.

The next integration work is the public bitmap-header/export contract, followed
by real diagnostic, expression and executable-directive services and delivery
through shared startup. The prototype does not qualify those paths, complete
public compiler globals, physical terminal execution, or any C1–C5 milestone.

A follow-up diagnostic (`build/probe-public-token-no-bitmap-help.py`, evidence
`build/i386-public-token-loader-v5`) restored the shared bitmap declarations
through a staged copy of `Kernel/CharBitmaps.HH` with only its `#help_index`
directive removed. Normal startup succeeded, but publication of part zero
was rejected with exception zero, zero errors and zero warnings before any
token cases ran. The source image hash remained unchanged. Thus removing
that directive alone does not resolve header publication; this result does
not identify which declaration or binding causes the rejection.

The individual-declaration probe (`build/probe-public-token-bitmap-symbols.py`,
`build/i386-public-token-loader-v6`) successfully publishes the existing v4
prefix as part zero, then rejects part one, containing only
`public extern U32 char_bmp_alpha[16];`, with zero errors and warnings.
`KernelSymbols` does not export that name. This reproduces a specific missing
public bitmap binding independently of the combined header and help directive.
No token cases run in this negative probe.
