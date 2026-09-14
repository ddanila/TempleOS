# Shared globals and function-body compilation

`PrsGlobalCore.HC` contains the production global-declaration loop, including
function dispatch, internal/external/import declarations, aliases, storage and
alignment, inferred sizes, initialization and data classification.
`PrsFunctionCore.HC` contains function-body IR construction, return/leave handling,
compilation, source/debug state, trace disassembly and member diagnostics.
The existing host entries compose the shared parser services and call these cores.
Statement parsing remains a supplied callback.

## Environment contracts

`CPrsGlobalServices` borrows symbol and initializer environments with the same
compilation owner. Its additional services compile a function, resolve a published
name, compare allocation ownership for an unresolved alias, and issue alias
warnings. Allocation, types, snapshots, initialization and AOT writes use the
existing shared subservices. Native heap comparison must validate the owner of
both records; it must not equate unrelated task allocations just because their
addresses happen to lie in one arena.

Global symbols and arrays are mutable during parsing. Inferred storage may be
replaced between passes, aliases may be updated, and a symbol can already be in
the hash table when a later initializer fails. Native providers need complete
allocation registration and failed-publication cleanup. These cores do not add
transactional replacement of symbols referenced by running tasks.

The non-AOT inferred-array fill now uses `tmpg->size`, the computed byte count.
Previously it used `k`, which that path did not initialize. Ordinary fill and
inferred fill still query the existing host settings when they execute.

`CPrsFunctionServices` adds statement parsing, IR compilation, disassembly and
member warnings. For AOT output, compilation must supply readable padded storage
through the next eight-byte boundary; the core copies whole words and releases
that temporary buffer. For immediate compilation, the returned code/debug data
is retained by the function symbol and must outlive the compiler control. A native
adapter must implement durable ownership before publishing that address or resolving
imports against it. Trace disassembly is provided by the environment, so the native
adapter can choose the target instruction mode.

The core preserves the original IR enter/leave sequence, leave-label restoration,
return warning, alignment and function flags. Member warnings retain their original
option checks and do not implicitly increment the compiler warning count; alias
warnings do increment it. Callbacks and all borrowed service records must remain
valid across recursive declarations and statement parsing.

## Validation and remaining work

A host regression compiles and executes an explicitly sized multidimensional global
array with the allocation-fill flag enabled, checking all values and restoring the
original settings. Existing native data tests cover inferred arrays through the AOT
path. Neither check establishes native immediate inferred-array execution; that
adapter is still absent.

The existing compiler exercises these shared paths during rebuilds and target
cross-builds. No retained native frontend service is published by this change.
Statement parsing, the native service adapters, assembler/AOT integration, target
compile-time execution and durable code/data/symbol publication remain required.
See [declarations](i386-declaration-parser.md),
[initializers](i386-initializer-parser.md) and `PLAN.md` for the full OS scope.
