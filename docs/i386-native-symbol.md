# Native class and function headers

CompilerRuntime ABI 28 (164 bytes) adds `parse_class` and `parse_fun_join`.
Both validate the current compiler owner, the complete supplied service graph and
available task stack before calling the full shared `PrsSymbolCore.HC` algorithms.
Invalid setup returns null; parser errors throw and require compiler-control unwind.
AOT function headers additionally require an AOT context. Native controls set
`CCF_TARGET_I386` at creation so argument layout uses the 32-bit saved-frame and
return-address size before any optimizer or backend runs.

Class/header parsing mutates its symbol table and may complete existing forward
symbols. The environment must supply private mutable tables and symbol graphs.
This interface does not make updates to published symbols transactional, or extend
parser-owned allocations beyond compiler-control destruction.

The native fixture reads the packaged `Kernel/Types.HH` from RedSea unchanged.
It uses the native lexer, type, class, declaration and expression parsers, plus
native backend execution for array bounds. Its checks cover all six public scalar
unions, their intrinsic forwarding, byte/word/dword array members, overlapping
offsets, cross-references and 32-bit pointer variants. Eight compiled expressions
check scalar/pointer and member-view sizes, signed and unsigned narrow casts,
unsigned shifts, and signed/unsigned division. No public scalar union is replaced by an alias.

The i386 backend follows class forwarding when selecting scalar width, signedness
and floating-point behavior. This preserves the union's member graph while using
its intrinsic value type. Previously a newly parsed `U32` cast retained the high
word because the wrapper's raw type shares the `I64` tag. The execution cases
exercise this boundary directly.

Additional cases cover inherited class layout, extern completion, a function
header with integer/pointer arguments, partial class/function failures, and help
index replacement, concatenation and malformed-string recovery. Every case uses
a private table chained to the task's existing symbols; full control unwind must
restore heap accounting, task references, exception state and interrupt state.

The lexer now handles `#help_index`, including immediate backslash string
continuations. Partial strings stay in compiler-control slots so cleanup can
reclaim them on failure. The fixture copies help indices into parsed symbols;
full source links and the rest of the document metadata environment are unfinished.

General function-header replacement providers, default/static initialization,
function/global/statement integration, durable code/data/symbol publication and
interactive compilation remain required. Parsing the original scalar declarations
is a component milestone, not a native compiler or kernel self-build.
