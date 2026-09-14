# Native declaration parsing

CompilerRuntime ABI 29 (168 bytes) includes `parse_declarations` and `code_init`,
introduced in ABI 27. Declaration parsing calls the complete shared
`PrsVarLstCore` in `Compiler/PrsDeclarationCore.HC` with supplied expression, type and declaration services. It
validates the service graph and current compiler owner before entering the parser,
and applies the existing task-stack reserve check. Invalid setup returns false;
parsing/allocation errors throw and require control unwind. The target class or
function and its member graph must be private and mutable; this entry does not
provide transactional replacement of types referenced by running tasks.

`code_init` resets the active IR view after an owner check. Callers preserving a
view must save it first. Resetting the view does not discard allocation ownership;
registered instructions and misc records remain covered by full control cleanup.

The native declaration fixture supplies real lexer snapshots, owned token strings,
parser allocations, member construction and the shared member insertion logic.
Array bounds use the native expression parser and backend: temporary function IR
is compiled and executed, then discarded before restoring the original IR view.
This validates compile-time evaluation for the tested arithmetic bounds, including
preservation of pre-existing IR. It is not a general native compile-time execution
adapter or a new constant-expression grammar.

Tests cover packed class fields, union overlap, arithmetic array bounds, nested
unions, comma declarations, unknown types, duplicate members, snapshot allocation
failure and malformed array-bound expressions with a saved IR view. They check field offsets/sizes, member counts, dimensions and exact resource
restoration. Callbacks outside that fixture's coverage fail explicitly.

The entry includes local/static/function-argument paths from the shared core, but
these still need complete native providers and native execution coverage. Full
class/function integration, initializers, metadata, source attribution and
publication remain unfinished. Native class/header entries and parsing of the
original `Kernel/Types.HH` are covered in [i386-native-symbol.md](i386-native-symbol.md). No public scalar
union is replaced by a plain alias. DolDoc, self-hosting and the rest of `PLAN.md`
remain part of the full OS goal.
