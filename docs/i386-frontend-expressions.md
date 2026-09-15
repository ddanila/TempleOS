# Retained frontend expressions and defaults

CompilerRuntime ABI 31 (184 bytes) adds `frontend`. It constructs the retained
parser environment for a fresh, active AOT control and returns its
`CPrsSymbolServices`. The nested declaration, type and expression services share
one parser owner, private table and allocation registry. The returned services,
private symbols and generated outputs expire with that control. Creation requires
the task's global table and an empty code registry; it does not publish symbols.

## Compiling and executing an expression

The declaration `compile_expression` provider calls the complete shared expression
parser and native backend. It saves the caller's code view, function/AOT pointers,
hash lookup, pass and temporary compilation flags. After type analysis it uses the
expression's actual result type, then copies code and literal bytes into an exact
parser-owned allocation. The temporary output builder, IR, helper descriptors and
relocation records are reclaimed, and the caller's saved view is restored.

The returned pointer remains valid until the declaration `release` provider frees
it or the owning control is unwound. Multiple outputs may coexist. `execute`
accepts only an output registered in that environment; a released or foreign
pointer raises a compiler error before execution. Errors during parsing, generation
or allocation require the caller to unwind the active control, as with the other
native parser services. These are trusted ring-0 compiler objects, not a security
boundary or an executable-memory isolation scheme.

Integer and F64 values use the native EDX:EAX return convention. `evaluate` returns
the raw value; `integer_expression` converts an F64 result numerically through the
software runtime. HolyC postfix casts retain their existing bit-reinterpretation
semantics. The language grammar is unchanged.

## Floating-point calls and literal ownership

A private backend lookup table supplies typed descriptors for the ten retained
software-F64 helpers. Generated relative calls are patched against their actual
module addresses after output storage is final. No imported/extern relocation
lists are attached to published task symbols. Relocation records are released
through the native backend's ownership routine, which unlinks their code-registry
records before freeing storage. The retained compiler module must outlive every
output that calls these helpers.

Literal addressing remains relative to the generated output, so copying the code
and its appended literal pool preserves those references. On execution, the
provider distinguishes an address into its literal pool from a numeric result
that merely used literal bytes while computing its value. This lets the shared
function-header parser duplicate returned default strings before freeing their
code, while keeping numeric/F64 defaults numeric. Existing outer misc-data state
is preserved.

Function headers now support computed numeric defaults, numeric conversion to the
parameter type, concatenated string defaults and `lastclass`. Their default
payloads remain parser-owned until normal publication/deletion work supplies a
longer lifetime. This change does not publish function bodies or executable code.

## Coverage and remaining integration

The native probe uses the retained services during boot and from the worker task.
It covers integer width/signedness, constant and generated F64 arithmetic,
comparison and an integer update, string results, six function defaults, partial
default failure, malformed/empty expressions, released-code rejection, two live
outputs with a preserved caller IR node, exhausted heap and F64 array-bound
conversion. Full control unwind must restore exact heap byte/allocation counts,
task references, active controls, exception state and interrupt state.

ABI 32 extends this environment with private statement/function compilation,
numeric static/global initialization and calls between completed private functions;
see [native statement integration](i386-native-statements.md). Its per-call
descriptors keep fixups off borrowed symbol graphs. Unresolved function/global
relocations still require a native program linker. Indirect calls retain the
caller's responsibility for the target's lifetime. ABI 34 adds
[task-owned program publication](i386-program-publication.md). Full interactive
compilation, definition replacement/unload rules, DolDoc and native self-hosting
remain open.
The existing 386SX/DX acceptance gates in `PLAN.md` are unchanged.

Run `python3 tools/test-rebuild.py`, then
`python3 tools/build-i386-kernel.py --test`.
