# Shared HolyC expression parser

`Compiler/PrsExpressionCore.HC` contains the production expression state machine,
operator insertion, unary terms and modifiers, function calls, `sizeof`, and
`offset`. `PrsExp.HC` retains its existing entry points and supplies host services.
The implementation preserves the original expression rules, including HolyC
precedence, postfix casts, pointer scaling, chained comparisons, default and
variadic arguments, implicit Print/PutChars calls, and assembler expressions.
There is no separate expression grammar for the native port.

`PrsBinary.HC` initializes the full operator table, including zero entries for
nonoperators. Precedence/associativity and type-parser mode flags now have common
headers included by `CompilerA.HH` and the expression service header.

## Service boundary

`CPrsExpressionServices` supplies borrowed type/operator tables and an opaque
context. Its callbacks cover lexical advancement, diagnostics, IR creation and
retirement, miscellaneous payloads, saved code views, optimization, allocation,
string duplication/concatenation, hash insertion, type parsing and recursive
expression entry. The parser still uses the shared stack, symbol lookup and target
size helpers, opcode metadata, and ordinary integer/bit primitives.

Error reports (kind 0) must throw. Warning reports (kind 1) and parenthesis reports
(kind 2) may return; the host preserves its existing option and macro suppression
rules. Allocation callbacks must either return valid storage or throw. The
`zeroed` flag distinguishes the unresolved export record from an uninitialized
assembler-reference record; `code_heap` records the original lifetime request.
It is not permission to put native allocations into an unrelated heap.

The recursive expression callback preserves the environment's exception and stack
policy. The host still catches compiler exceptions in `PrsExpression`, preserves
its returned boolean and flags, and keeps immediate expression compilation and
execution in `LexExpression*`. Those host execution helpers must not be called to
execute target bytes while cross-compiling.

This is an internal parser contract, not an untrusted-graph validation layer.
Services must belong to the same compiler environment and outlive every recursive
call. Type/operator tables are borrowed and must remain stable. Graph mutations,
partially constructed symbols, strings transferred from `cc->cur_str`, and saved
views must all be covered by the environment's failure cleanup.

## Remaining native integration

The retained native compiler does not yet publish an expression-parser service.
The existing production compiler now exercises this core; native execution needs
these concrete adapters and ownership work:

| Dependency | Existing foundation and remaining connection |
| --- | --- |
| Tokens | `I386RuntimeLexIncludes` supplies tokens; preserve lexer errors and include context through a throwing parser callback. |
| IR | `I386ICAdd`, `I386COCMiscNew`, `I386ICRetire` supply control-owned nodes; convert failed service returns into compiler/allocation failures consistently. |
| Saved views | Native push/pop/header-free/append exist; preserve the argument parser's explicit view-chain rearrangement while using the ownership registry for unwind. |
| Optimization | `I386OptPass012` already uses borrowed types and an owned pass stack. |
| Parser stack | Recursive expression parsing needs its own owned stack lifetime; it cannot alias `cc->ps` while argument optimization is using that stack. |
| Types | `PrsTypeCore` and `PrsArrayDimsCore` now share the original type/array parser. Connect class/function joins, declaration ownership and target array-bound evaluation; see [type parser](i386-type-parser.md). |
| Strings | Connect adjacent-string concatenation with native ownership, including failure after token-buffer transfer and embedded zero bytes. |
| Symbols | Provide owned unresolved exports and assembler references, ordered hash insertion, and cleanup after publication or failure. |
| Diagnostics | Map error/warning/parenthesis callbacks to native task exceptions and source locations. |
| Execution | Feed valid completed IR to the native backend, resolve imports and publish code under a durable owner before top-level execution or `#exe`. |

A native expression demo alone will not complete the frontend: declarations,
statements, classes, functions, assembly, top-level execution and self-hosting stay
required by `PLAN.md`.
