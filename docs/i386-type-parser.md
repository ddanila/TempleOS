# Shared HolyC type parsing

`PrsTypeCore.HC` contains the production type parser and variadic-argument
construction. `PrsArrayDimsCore.HC` contains the production array-dimension parser.
`PrsVar.HC` keeps the existing entries and supplies host services; expression casts
reach the same core through the expression parser's type callback. Keyword
recognition is a shared pure helper in `PrsKeyword.HC`.

The shared path retains pointer-depth checks, class/union forwarding, identifier
transfer and anonymous names, function-pointer signatures, declaration-mode lexer
snapshots, array bounds, pointer warnings, and argc/argv member construction.
The existing target-specific unsized-array sentinel and 64-bit HolyC argument slots
are preserved. Variable-list parsing and class/function-header joining now have shared cores;
initialization and native adapters remain. See [declarations](i386-declaration-parser.md).

## Environment contract

`CPrsTypeServices` supplies borrowed internal types and callbacks for tokens,
errors/warnings, lexer snapshot push/drop, integer expression evaluation, class and
function joining, allocation, string duplication, and member construction/insertion.
The host reuses the expression adapter's token, diagnostic and string services.
Error reports must throw; warnings may return. Allocation must return storage of
the requested size or throw. The native adapter must register every partially
constructed allocation before an operation that can fail.

The parser transfers the current identifier string from the lexer into its result;
anonymous strings, array dimensions, and variadic members acquire new ownership.
Class and function callbacks may recursively enter declarations and expressions.
They must preserve the same task/control owner, snapshots and symbol graph through
success and exception cleanup. Array-bound evaluation must use the target-aware
compiler/execution path, with its own parser and optimizer stack lifetimes.

The dimension loop now starts at the actual root object. Previously it started at
`&dim`, the stack slot holding the root pointer, and wrote `total_cnt` through that
non-object before visiting the root. The new traversal updates only the root and
its linked dimension records.

## Validation and remaining work

The function corpus includes a native execution probe of `PrsArrayDimsCore` with
bounded token/evaluation/allocation services. It checks no dimensions, one and
three explicit dimensions, and one and three dimensions with an unsized first
dimension. Assertions cover root and suffix products, individual counts, exact
links, allocator calls, terminal token/position and guard values around the fixture
objects. This tests the shared helper on i386; it does not provide a native lexer
or expression evaluator by itself, or exercise allocation-failure cleanup.

The full native frontend still needs adapters for these services and the shared
class/function/variable-list cores, initialization, symbol lifetimes, array-bound execution,
and connection to persistent backend output. The retained compiler publishes no
new parser service in this change, and its ABI remains unchanged. See
[i386-expression-parser.md](i386-expression-parser.md) and `PLAN.md`.
