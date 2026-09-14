# Shared declaration and symbol parsing

`PrsDeclarationCore.HC` contains the production member, local-variable, static-local
and function-argument declaration loop. `PrsSymbolCore.HC` contains class declaration
and function-header joining. The existing `PrsVarLst`, `PrsClass` and `PrsFunJoin`
entries now initialize host services and call those cores. The original type and
expression parsers supply the other shared parts of this recursive frontend.

The common code retains union layout, explicit `$$` offsets, register hints, comma
and semicolon rules, metadata, anonymous and variadic arguments, defaults and
`lastclass`, local alignment, static initialization ordering, forward declarations,
class inheritance and signature comparison. i386 arguments retain the eight-byte
HolyC slots and eight-byte saved-frame/return adjustment; x64 retains its sixteen-
byte adjustment. Function modifier constants now have a shared header.

## Service and lifetime contracts

`CPrsDeclarationServices` composes the expression and type service records with
callbacks for definition lookup, untyped expression evaluation, snapshot restore,
static initialization, AOT writes/data classification, executable expression
compilation/execution and release. Its subservices must all describe the same
compiler environment and remain valid throughout recursive parsing.

The static-storage initialization callback reads the host initialization flag and
fill byte when it executes. Capturing those settings on parser entry would change
behavior if compile-time execution changed them. Default-expression code remains
alive through result conversion and string duplication, and is released afterward.
The native provider must preserve that order when results point into generated
storage; it cannot free code immediately after returning a pointer-valued default.

`CPrsSymbolServices` adds class/function creation, single-table lookup, member-graph
release, source attribution, option queries, warning delivery and target register
masks/undefined-function address. Table-chain lookup remains the shared `HashFind`.
Option queries occur at the original decision points. Warning kind 0 preserves
unused-extern handling; kinds 1/2 report return/argument mismatches and must update
the warning count. Syntax errors use the expression service's throwing reporter.

Forward declarations and function headers are mutated in place. Existing source
links and indexes are released before replacement; old argument lists remain
available for signature comparison and are then reclaimed. This requires private,
mutable symbol graphs owned by the compilation environment. It does not establish
safe replacement of code or symbols retained by running tasks. A native adapter
must register newly allocated members, metadata, static buffers and detached old
lists so exceptions reclaim them even before final publication.

## Remaining native work

These extractions remove direct host globals, allocation, output formatting and
execution from the shared parsing bodies. They do not add a retained native parser
service. Native adapters still need source-link creation, task-owned symbol and
member publication/replacement, register-name policy, snapshot integration, complete
variable initialization and target expression execution. Default conversions also
need the native software-F64 services when this code is compiled for i386.

Function-body/statement parsing, global declarations, static/aggregate initializer
execution and persistent AOT/JIT publication remain outside these cores. The
existing compiler exercises the shared paths, including when cross-building the
standalone image. That is not evidence of native declaration parsing or a HolyC
shell. See [expression parser](i386-expression-parser.md),
[type parser](i386-type-parser.md) and `PLAN.md` for the full integration requirements.
