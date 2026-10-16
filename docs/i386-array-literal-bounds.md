# Native literal array-bound evaluation

CompilerRuntime 74 returns a single integer array bound directly when the lexer
has already buffered its closing `]`. The existing compiler-control ownership
check still runs, and the ordinary lexer consumes the delimiter. This avoids
allocating parser/output state, emitting code, linking it, executing it and
freeing it for a value already available in `cur_i64`.

There is no speculative token read or snapshot rollback. Expressions, floating
point, character constants, intervening whitespace/comments and any macro
expansion without an already buffered closing bracket retain the full expression
compiler. Default arguments and other compile/evaluate consumers are unchanged.
The original array parser still rejects negative dimensions. Public headers and
APIs are unchanged; this is intended to recover startup time without narrowing
the desktop surface.

The fixture covers decimal/hex/character bounds, whitespace/comments/newlines,
macro literals and expressions, arithmetic, parentheses, unsigned bit patterns,
floating-point conversion, multidimensional arrays, unary negative expressions,
a compile-time function evaluated exactly once, and local arrays. Eight masks
combine these checks into 255, with an independent call count of one.

The first original fixture failed because its counter was uninitialized;
`build/i386-c4-array-literal-reference` preserves that failure. That original
run observed nonzero initial storage. Explicitly initializing the counter
corrects the fixture. The corrected pinned-original
and preceding native image pass with unchanged execution inputs:

- `build/i386-c4-array-literal-reference-fixed/result.json`
- `build/i386-c4-array-literal-baseline-fixed/result.json`

Both bootstrap generations and the cross-build pass, including the 386 boot
instruction audit. All 1528 source and 24 build inputs remain unchanged in
`build/i386-c4-array-literal-cross/input-audit.json`. The candidate native four-command suite passes in
`build/i386-c4-array-literal-native`, and the nine-command document/VGA regression
passes in `build/i386-c4-array-literal-doc-type`, both with unchanged inputs.
The latter preserves all six exact document buffers, two full raw VGA captures
and real hardware delay checks. The isolated comparison passes all nine behavior/VGA checks on both images with
no build-provider loads and unchanged execution pins. The control starts in
59.607815 seconds; Compiler 74 starts in 58.104980 seconds, 1.502834 seconds less
in this paired observation. Evidence is in
`build/i386-c4-array-literal-startup-compare.json` and its two referenced runs.
This is one comparison with limited margin; the earlier control failure at
62.374019 seconds remains recorded. Candidate 16 MiB diagnostics are running.
No completed compatibility milestone is claimed.

```sh
python3 tools/test-i386-array-literal.py --out ORIGINAL
python3 tools/test-i386-array-literal.py IMAGE --out NATIVE
```
