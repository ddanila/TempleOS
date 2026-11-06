# Public compiler-control and lexer baseline

The original Psalmody source now reaches `CmpCtrlNew` in PsalmodyFile line
203. Native interface 225 rejects that call before application interaction.
The public control and lexer must preserve original ownership semantics;
exporting the private native constructor directly is insufficient.

`tests/guest/i386-public-lexer/Contract.HC` records sixteen checks in an exact
128-byte table. It covers constructor flags and self-links, input-buffer
identity, current-task symbols, default filename and line, identifier/integer/
floating/string tokens, adjacent-string concatenation and returned ownership,
EOF, borrowed input lifetime, prompt allocation, at-sign handling, and heap
restoration after destruction. The independent expected table contains sixteen
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

The fixture does not cover include files, document input, directives, error
unwinding, task death, or all `LexExtStr` modes. Psalmody uses an include directive
and needs the actual song token stream. These require further oracle coverage
and implementation; this baseline closes no C1–C5 milestone.
