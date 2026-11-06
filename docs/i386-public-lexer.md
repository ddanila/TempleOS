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
