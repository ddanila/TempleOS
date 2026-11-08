# Public expression error cleanup

For the tested parse, backend-precondition, and evaluated-expression failures,
the shared `Compiler/PrsExp.HC` now restores the saved graph and trace/host-constant
flags. The normal APIs retain the same exception tags and error counters.

The pre-change normal image leaked 4,584 live bytes per malformed expression,
even after the probe released every reachable graph. The expression's saved
control and trace flag were not restored. Each of the raw/I64/F64 evaluating
wrappers leaked a 56-byte generated code allocation when its call threw. A
throw during a cast's first array-bound evaluation leaked 4,640 bytes and left
the outer compilation context selected. Successful compilation also cleared a
pre-existing host-constant flag.

The parser now frees its owned stack before issuing a second parse diagnostic,
and frees it when a non-Compiler exception propagates. A supplied parser stack
remains caller-owned. The binary wrapper installs its handler before saving a
graph, tracks whether that save succeeded, releases only the temporary graph,
restores the saved graph and the trace/host-constant bits, and then propagates
any captured exception. A secondary cleanup diagnostic does not replace an
already captured exception. Each evaluating wrapper frees generated code in
its catch before automatic HolyC propagation; it does not explicitly throw
from inside that catch.

Run:

```
python3 tools/test-i386-public-expression-errors.py IMAGE --out OUT
python3 tools/test-i386-public-expression.py IMAGE --extended --out SUCCESS_OUT
```

The error contract has nine cases: three malformed expressions, successful
flag preservation, an invalid AOT backend precondition, throws from all three
evaluating wrappers, and a throw during the first dimension of an array cast.
Each row checks the exception tag and error count, saved control chain,
trace/host-constant mask, preserved outer instruction, caller data/code heap
deltas, compile-result presence, and a following successful result 42.
Diagnostics go to a private document which is released before measurement;
pending Adam error jobs are drained. Thus retained diagnostic text is not
mistaken for an orphaned compiler allocation. The probe cleans reachable
frames after recording restoration checks, so a failure cannot pass merely
because the probe repaired it.

Evidence:

- `build/i386-expression-error-baseline-v3/result.json`: eight pre-fix rows,
  including syntax leaks, flag loss, backend context loss and evaluation leaks.
- `build/i386-expression-nested-error-baseline-v2/result.json`: pre-fix nested
  array-bound evaluation failure and 4,640-byte leak.
- `build/i386-expression-error-contract-v2/result.json`: all nine rows pass
  through normal delivered APIs at 64 MiB, with exact counters/tags, restored
  graphs/flags, zero heap deltas, continued execution, one publication,
  unchanged inputs and filesystem checks.
- `build/i386-expression-error-success-v2/result.json`: all previous basic and
  extended normal expression/type/class/function/statement/stream checks pass.
- `build/i386-expression-error-lex8-v2/result.json`: normal lexer regression
  passes at 8 MiB.
- `build/rebuild-test/result.json` and `build/i386-expression-error-cross-v2`:
  two original native rebuilds and the current cross-build/instruction audit.
  All native runtime modules and the flat kernel are byte-identical to the
  preceding publication checkpoint; this change is in the shared source body.
  These checks do not qualify C5's complete native release generations.

ABI versions remain Compiler 101, Console 259 and Memory 41. Source pins and
revision identify this implementation change. The normal expression tests use
64 MiB; no new 8 MiB expression-service or startup-performance claim is made.
Allocator/context-install exhaustion, cancellation/concurrency, richer partial
type/declaration ownership (including later array dimensions), other backend
failure modes, assembly/AOT closure, and full C1–C5 qualification remain open.
Bundled qualification remains 2/686.

`build/i386-expression-error-cross-v2/final-verification-audit.json` verifies
1,833 source pins, 26 build-input pins, images/modules, current bootstrap,
all component receipts and input pins, pre-fix leak observations, exact prior
success records, the unchanged sixteen native modules/flat kernel, ABI layouts
and the 2/686 inventory count. It records an explicit immutable base revision
and the remaining qualification limits.
