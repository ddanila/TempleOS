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
The retained native frontend transfers live outputs into task-owned storage during
program publication, so initialized pointers can outlive their compiler control. AOT
records remain attached to the caller's private AOT context for later serialization
and resolution.

Memory services receive exact byte counts; target class sizes determine scalar
copy width. F64 conversion remains in the common language path and uses the native software-F64
providers in the retained frontend.

The native JIT now accepts string pointers in globals, statics, aggregate members
and pointer arrays. Its usual expression executor returns an address into a
registered literal pool and sets `CCF_HAS_MISC_DATA`. Final-pass initialization
retains that output; scalar storage receives the target's four-byte pointer.
First-pass temporary outputs and failed controls are reclaimed under the existing
initializer/unwind rules. Successful publication retains the pool until task
storage is destroyed. Empty strings and embedded NUL bytes keep their lexical
lengths; the source buffer itself is not retained as the initialized value.

Cross-compiled AOT string pointers now emit `AAT_ADD_U32` slots and classified
literal data. The module writer serializes these as version-3 stored local data
pointers, and the loader resolves them for the actual destination. The existing
x64 path retains eight-byte absolute records. Native JIT keeps its established
literal-pool ownership; the AOT module does not contain a compiler-host pointer.
See [module format](i386-modules.md) for loading and placement contracts.

## Validation and remaining integration

The data corpus adds inferred multidimensional globals, inferred arrays of
aggregates, and static multidimensional arrays. Their generated native programs
check final sizes and values, exercising host-side recursive row assembly and
static passes. They do not prove that initializer parsing runs natively.

The standalone native statement probes cover writable/empty/concatenated strings,
embedded NULs, signed-byte pointers, adjacent scalar fields, static pointers and
inferred pointer arrays. Publication probes destroy the originating control, then
read and mutate global/static strings from fresh controls, recover from a failed
string initialization buffer, and restore exact heap ownership after teardown.
Keyboard checks exercise the same source path and compare the resulting pixels.

Global declarations and function-body construction use the
[shared cores](i386-global-function-parser.md). No new retained compiler service or
ABI is introduced. Symbolic stored function/import pointers and deferred executable initializer
output remain required before native module generation and self-hosting.
See [declarations](i386-declaration-parser.md),
[expression parser](i386-expression-parser.md) and `PLAN.md`.
