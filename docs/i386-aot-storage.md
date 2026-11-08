# Shared AOT storage implementation

The next public compiler delivery dependency is AOT storage. The source-loaded
expression/statement pipeline still declares unresolved `AOTStoreCodeU8`,
`AOTStoreCodeU64`, `AOTStoreCodeU8At` and `PrsI386DataRange` callbacks. These
callbacks need real normal native bindings before that delivery gap can close.

`Compiler/AOTStoreCore.HC` now contains the existing four store implementations
(including `AOTStoreCodeU32`), included by `Compiler/AsmLib.HC`.
`Compiler/I386DataRangeCore.HC` contains the existing data-boundary recorder,
included by `Compiler/PrsLib.HC`. No function body changed. The source expansion
comparison against parent revision `52a9afc59d0e61b972a1c31812a1d34caf76292a`
is recorded in `build/aot-shared-core-source-audit-v1.json`.

This is preparation for sharing the actual implementation with normal native
console delivery. It adds no exports and does not establish native public AOT,
lexer, assembly, or compiler-module closure. The original block-allocation,
listing, cursor/high-water, variadic patching, and data-record ownership behavior
must be exercised through the eventual public bindings, including block edges.
The first binary block remains a caller precondition for sequential stores.

Validation: two x86-64 bootstrap generations are recorded in
`build/rebuild-test/result.json`, with the console log in
`build/aot-shared-core-bootstrap-v1.log`. This is bootstrap validation, not a
native 386 public API contract or a C5 reproducibility result.
