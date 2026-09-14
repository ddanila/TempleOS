# Shared initializer parsing

`PrsInitializerCore.HC` contains the production scalar, aggregate, array, global
and static initializer paths. `PrsVarInit`, `PrsVarInit2`, `PrsGlblInit` and
`PrsStaticInit` remain host entries in `PrsVar.HC`; they compose the shared parser
services and enter this core. Recursive calls keep the same service environment.

The common implementation retains lexer snapshot/replay order, scalar conversion,
fixed/inferred array sizing, temporary rows for inferred aggregates, static two-pass
initialization and AOT initialization records. Queue insertion now uses explicit
next/last links for scratch rows and AOT records, avoiding host queue primitives.
The scalar initializer captures its incoming flags before choosing the string
branch; that branch previously restored an uninitialized `old_flags` value.

## Services and ownership

`CPrsInitializerServices` adds memory copy/fill, AOT byte storage and compilation of
an existing IR graph to the declaration environment. Expression/type/declaration
services supply lexical operations, snapshots, IR, allocation, execution and release.
Those records must belong to the same compilation owner and remain alive through
all recursion and callbacks.

Allocated destinations, inferred-row temporaries, copied strings, generated code
and relocation records need distinct but coordinated lifetimes. Inferred arrays
release the old destination, allocate final storage and copy rows before releasing
them. Native allocation registration must cover the interval before any temporary
is linked, and full failure cleanup must work independently of these list views.
This core does not implement transactional rollback or a native allocation registry.

Generated scalar code is retained when the existing `CCF_HAS_MISC_DATA`/pass policy
requires its data to outlive evaluation. A native provider cannot rely on a temporary
compiler-control output buffer when initialized values point into that buffer.
Persistent code/data publication and ownership transfer are still required. AOT
records remain attached to the caller's private AOT context for later serialization
and resolution.

Memory services receive exact byte counts; target class sizes determine scalar
copy width. F64 conversion remains in the common language path and will require
native software-F64 providers when this core runs on i386. The existing i386
rejection of initialized string pointers remains: supporting those values needs
proper target pointer/data relocation, not the legacy 64-bit absolute patch path.

## Validation and remaining integration

The data corpus adds inferred multidimensional globals, inferred arrays of
aggregates, and static multidimensional arrays. Their generated native programs
check final sizes and values, exercising host-side recursive row assembly and
static passes. They do not prove that initializer parsing runs natively.

Native adapters, target expression execution, durable destinations and relocation
publication remain open. Global declarations and function-body construction now
have [shared cores](i386-global-function-parser.md); statement parsing and native
frontend execution remain to be integrated. No new retained compiler service or ABI is introduced.
See [declarations](i386-declaration-parser.md),
[expression parser](i386-expression-parser.md) and `PLAN.md`.
