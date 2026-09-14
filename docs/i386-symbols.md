# Shared compiler symbol records and values

`Kernel/SymbolTypes.HH` now contains the original hash type/flag constants,
source/export/import/define/class/function/global records, array dimensions,
member lists and metadata, external-use records and debug-line record. The
extracted declaration block is byte-for-byte unchanged from `Kernel/KernelA.HH`;
both targets include the same definitions above the shared `CHash` prefix.
Opaque AOT references remain forward declarations.

The symbol fixture checks these sizes on both architectures:

| Record | x86-64 bytes | i386 bytes |
| --- | ---: | ---: |
| CHashSrcSym | 64 | 36 |
| CHashExport | 72 | 44 |
| CHashClass | 128 | 80 |
| CHashFun | 168 | 108 |
| CHashGlblVar | 136 | 92 |
| CMemberLst | 144 | 96 |

Additional i386 assertions cover dimensions, metadata, unions, imports, defines,
debug records and critical member offsets. I64 sizes, offsets, defaults, dimension
counts and generic/export values remain eight bytes. Pointer and function-pointer
fields become four bytes. An I64/pointer union remains eight bytes; writing its
pointer member changes four bytes on i386. Runtime cases follow linked class,
function and member records, exercise the pointer-star class-array convention,
and retain values beyond 32 bits through nested fields and unions.

`Kernel/HashValue.HH/HC` now supplies one `HashTypeNum`/`HashVal` implementation
for both targets. The type selector masks flags and locates the lowest type bit
with ordinary integer operations, including the no-type result -1. The value
helper retains the existing type-specific behavior: export/generic I64 values,
module/code/data addresses, self-valued types, register packing, and extern
function/global handling. Pointer values are explicitly widened before returning
I64; changing pointer width does not sign-extend bit 31 into the upper word.

The kernel's private loader records now extend the real `CHashExport` record with
a module-binding kind. Their `val` field stores the address as I64. Startup finds
`HTT_EXPORT_SYS_SYM` entries, calls shared `HashVal`, checks the address fits U32,
and constructs its loader bindings. These are resident exports; they do not yet
constitute initialized compiler function/class metadata or task symbol tables.

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --symbols
python3 tools/test-i386.py --hash
python3 tools/build-i386-kernel.py --test
```

Before refactoring the helper, 28 `HashVal` cases were captured from the running
x86-64 kernel at revision `091be92`. `tests/i386/symbol-values.json` records the
values, bootstrap binary hashes and the case-source hash. Self/field addresses
are normalized in `Values.HC`; raw values include high-bit 32-bit addresses and
full-width signed bit patterns. The test checks the rebuilt x86-64 results against
that capture before running the same cases on i386, so two targets sharing a
changed implementation cannot silently redefine this oracle. Changes to the case
source require an explicit review and legacy recapture rather than updating the
expected values from the new helper.

The native test also covers all 289 pairs of type bits with public/private/local
flags, layout assertions and live metadata accesses. It passes with the instruction
audit, the existing hash/owned-table regression, both x86-64 rebuild/reboot
generations and the complete standalone source/module/keyboard/VGA boot checks.

This establishes shared declarations and value access. Native construction and
destruction of rich symbols, task ownership, compiler initialization, language
runtime dependencies and compile-time execution remain required before the
resident compiler and HolyC shell can operate. Native self-hosting and strict 386
verification remain open.

## Shared member and metadata lookup

`Compiler/MemberLookup.HH/HC` now contains the existing `MemberFind`,
`MemberClassBaseFind`, `MemberMetaData` and `MemberMetaFind` routines. `LexLib.HC`
includes this implementation for the x86-64 compiler; the native fixture compiles
the same source. The original bodies are preserved apart from spelling `NULL`
as zero. They require the caller's `StrCmp` implementation and allocate no memory.

Member-name lookup follows the existing tree ordering, then searches base classes
when a name is absent. A derived member shadows a base member; only the selected
member's U32 use counter increments. Metadata lookup returns the first matching
linked record or its full-width I64 value. Class-base lookup searches its separate
pointer-key tree and does not fall back to inherited classes.

Native callers must supply live, acyclic trees and zero-terminated names, and keep
lookup/counter access exclusive. These compiler helpers add no IRQ synchronization,
ownership or reclamation policy. Empty member trees and metadata lists are handled;
a null class/member record is not a supported input.

`Kernel/I386/String.HH/HC` supplies native public `StrCmp`, using unsigned bytes
and returning exactly -1, zero or 1 as the original x86-64 assembly does. Both
arguments must be live zero-terminated strings. Native hash lookup now uses this
routine too, putting it on the standalone resident export-resolution path.

The expanded `--symbols` fixture runs the same member checks on x86-64 and i386.
It covers derived/base shadowing, empty-tree fallback, missing and case-sensitive
names, use-counter rollover, duplicate metadata keys, wide values and class-key
ordering across bit 31. Synthetic high-address keys are compared without being
dereferenced. All 65,536 pairs of single-byte strings, plus prefix and embedded-NUL
cases, verify the exact `StrCmp` result. The existing symbol-value/layout and
hash/owned-table checks, both x86-64 rebuild generations, instruction audits and
the complete standalone keyboard/VGA boot checks also pass.

Member construction, symbol destruction, compiler control records, allocation and
native compiler initialization remain required. This is shared frontend code
running in a native fixture, not an operational native HolyC compiler.

## Shared class/function initialization and native allocation

`Compiler/SymbolInit.HH/HC` extracts the initialization performed by the original
class and function constructors. The caller supplies five fresh, zeroed records:
the root and four pointer variants, each separated by a complete typed record.
Variants retain `RT_PTR` and use the target pointer size; the root has size zero
and a member-list tail cursor pointing at its own list head. Raw-type constants
now come from `Kernel/RawTypes.HH`; their values and legacy signed pointer tag
are unchanged. The x86-64 constructors retain `CAlloc` and `Fs->code_heap`.

`Compiler/I386/SymbolAlloc.HH/HC` adds explicit-heap try constructors for native
class/function arrays. Allocation, zeroing and initialization run with interrupts
masked and restore the caller's flags. Failure returns zero. These do not yet
provide public task-selected allocation or the public `OutMem` failure path.
Only the root allocation can be freed; pointer-variant interior addresses cannot.
Callers must detach symbol references and dispose of owned nested objects before
releasing an array. A compiler-aware destructor remains required.

The `--symbols` fixture checks the same initializers on x86-64 and i386, including
variant strides, pointer sizes, root cursors and untouched zero fields. Native
lifecycle checks cover null/exhausted heaps, interrupt-state preservation, rejected
interior frees, inherited member lookup through the constructor's list sentinel,
hash insertion/removal, high-bit function values, and complete arena reclamation.
Existing legacy value, layout, member and string checks and the instruction audit
pass. Both x86-64 rebuild generations also pass. This supplies another compiler
dependency; it does not initialize or run a resident native compiler.

## Symbol ownership and destruction

`Kernel/SymbolDelete.HH/HC` shares the original `HashDel`, `MemberLstDel` and
`ClassMemberLstDel` ownership branches through an explicit release callback.
The x86-64 public functions adapt ordinary `Free`; the native adapters in
`Compiler/I386/SymbolDelete.HH/HC` release allocations from a supplied heap.
The walker follows the list links, not the member search trees. Function-pointer
variants are normalized to their five-record root before recursively deleting
owned signatures. Member-only cleanup resets the class list cursor, roots, size
and counts, including function argument count, while retaining the symbol itself.

Owned names, source links, indices, import names, import/export lists, dimensions,
string defaults and string metadata follow the existing cleanup policy. Function
and export debug data are owned; dictionary names, aliased global data, executable
code, class references, return types and member static data are retained. This is
legacy ownership behavior, not a new general-purpose garbage collector or a
module-image destructor. In particular, shared type references must not be
mistaken for the privately owned function signatures marked by `MLF_FUN`.

The caller must detach external references and supply a live acyclic ownership
graph without duplicate owned allocations. Native owned allocations must all
belong to the supplied heap. The native result reports rejected frees; it does
not validate arbitrary graphs or roll back a partially completed deletion.
Nested signatures use recursive calls, so stack demand depends on nesting depth.
Native deletion masks interrupts around each heap release and restores the
caller's state between releases. The caller retains exclusive ownership of the
graph throughout the walk; callbacks must not yield or publish its records.

The shared functions are declared through `KernelC.HH`, so compiler builds mark
calls across this boundary as kernel imports. Declaring them only inside
`LexLib.HC` was insufficient: the first rebuilt compiler faulted during loading.
With the import declarations in place, two x86-64 rebuild/reboot generations and
the standalone 8 MiB QEMU/486 kernel boot checks pass.

The same tracked-allocation fixture now passes on x86-64 and i386. It exercises
nested function signatures through pointer variants, multiple members, dimension
and import/export lists, string defaults, string/numeric metadata, class-list
reset, ordinary/aliased globals, defines, exports, file payloads and dictionary
names. It detects missing, duplicate and unexpected releases while retaining a
borrowed allocation through all cases. Native adapters also pass real heap
reclamation and interrupt-state checks. Existing symbol layout, legacy value,
member/string and constructor tests and the executable instruction audit pass.

Public task-selected allocation, compiler control state, native compiler startup,
source execution and self-hosting remain required. These cleanup routines do not
make a borrowed module image safe to unload while code or data references survive.

## Member construction and signature comparison

`Compiler/MemberBuild.HH/HC` shares member insertion and `MemberLstCmp` between
compiler targets. `MemberInsert` performs the existing reversed name-tree insert,
local-variable base-type indexing and declaration-order list append. Pointer
variants normalize by full class-record strides. Duplicate base types keep the
first indexed member, while every accepted member remains in declaration order.
The parser still controls member counts, layout and register assignment.

A diagnostic callback separates parser reporting from these operations. Ordinary
duplicate names, including inherited names, report an error before insertion;
`pad`, `reserved` and `_anon_` retain their repeatable-name exceptions. A returning
error callback yields false. Duplicate-name lookup retains its use-counter side
effect. Type warnings occur after name insertion and before the remaining links,
matching the original order. Warning callbacks must return normally; callbacks
must not mutate the graph or yield. `MemberAdd` adapts the existing LexExcept and
LexWarn behavior. Callers retain exclusive ownership of live, fresh records and
valid class/list roots; insertion does not allocate or synchronize access.

`I386MemberLstNew` supplies explicit-heap, zeroed native member allocation and
stores the requested register number in the existing I8 field. It restores the
caller's interrupt state and returns zero on allocation failure. The x86-64
constructor retains ordinary CAlloc. Public task selection and OutMem behavior
remain separate integration work.

Signature comparison retains full I64 defaults, string-content comparison,
type-pointer identity and the original count-limit semantics. In particular,
ending just one list exactly at the limit still returns false; reaching the
limit while both lists have another node returns true. This extraction does not
silently change that existing behavior.

The shared host/native fixture passes declaration order, both search-tree
orderings, base-type normalization, duplicate-type warnings, direct/inherited
name rejection, all three repeatable-name exceptions, lookup counter effects,
wide/string defaults and count-limit boundaries. Native allocation tests cover
zero initialization, signed register selection, null/exhausted heaps and complete
reclamation through the shared member destructor. Both x86-64 rebuild generations,
the existing symbol/ownership tests, executable instruction audit and complete
standalone kernel boot checks pass. The comparison default argument is present
on both declaration and definition to preserve two-argument target calls.

This supplies shared frontend primitives. Native compiler-control initialization,
parser diagnostics, task-selected allocation and source execution still need
integration before there is an operational native HolyC compiler.

## Built-in type registry

`Compiler/InternalTypes.HH/HC` shares the original 17-entry descriptor table and
root initialization used by `AsmHashLoad`. Descriptors retain their names, raw
tags, sizes and ordering, including Bool's signed-I8 tag and the `I64i`/`U64i`
internal names. Only the class root becomes `HTT_INTERNAL_TYPE`; the four pointer
variants keep `HTT_CLASS`, `RT_PTR` and the target pointer width. The x86-64 path
retains its original class allocator, name allocator and assembler table.

`Compiler/I386/InternalTypes.HH/HC` builds an owned 32-bucket table, five-record
class arrays and eight-byte name allocations using an explicit heap. Its
raw-type array keeps the last descriptor for each raw tag, matching the compiler's
original overwrite order. Unused raw slots remain zero. The caller supplies a
zeroed registry and keeps its contents exclusively owned; external additions,
renames and shared ownership of its entries are unsupported. Read-only lookup is
allowed while the table is live. Before deletion, detach all incoming references.

Creation failure releases every completed entry and temporary allocation and
leaves the registry reusable. Deletion rejects a locked table. Under the live,
owned-graph contract, ordinary deletion empties the table and resets the registry;
it is not a validator or rollback mechanism for arbitrary corrupt graphs. Heap
operations preserve interrupt state without masking the entire initialization.

Host/native tests check the descriptor bytes against independent names, tags and
sizes; root flag preservation; untouched pointer variants; alias-map selection;
lookup and requested allocation sizes; reinitialization/locked-delete rejection;
and reclamation across all 1,022 aligned arena sizes from 24 through 8,192 bytes.
The symbol runner now transfers 160 KiB, ending at 0x38000 below its first heap
at 0x40000.

Standalone startup attaches this registry as the parent of the kernel export
index, verifies lookup of every built-in name and checks the Bool/F64 alias map.
The registry is retained for the kernel's lifetime. This initializes real resident
type symbols, but does not yet initialize compiler control records, opcode tables,
lexer/parser execution, the JIT shell or the complete public type environment.

The 314504-byte standalone kernel passes the complete 8 MiB QEMU/486 boot checks.
Its `TYPES` marker and image manifest verify 17 resident names and 7,672 bytes of
heap use for table ownership, buckets, class arrays and names. This heap figure
excludes registry globals and code, which are included in the kernel image.
Both x86-64 rebuild/reboot generations and the expanded native symbol suite pass,
including instruction audits, cleanup, module rejection and keyboard/VGA checks.

## Compiler control records and initial state

`Kernel/CompilerTypes.HH` extracts the existing compiler declarations from
`KernelA.HH`: compiler options and tokens, intermediate-code records, parser
stack, assembler/AOT records, lexical files, hash context, CCmpCtrl and compiler
globals. Numeric fields and raw tags retain their widths. Embedded structures
follow target pointer sizes; this is the actual public control record rather
than a smaller replacement used only by the bootstrap runtime. Register constants
remain compiler identifiers and do not authorize newer CPU instructions.

`Compiler/ControlInit.HH/HC` shares the initial self-linked control/stream queues,
flags, default warning options, symbol-table bindings and character bitmap.
`LexFileSeed` sets a file's buffer pointers and initial line number, retaining the
include-stack depth, name and flags set by its caller. The x86-64 CmpCtrlNew still
selects Fs's hash table, handles filenames and prompt-buffer allocation, and uses
the existing LexFilePush/pop and destructor path.

Native callers must supply fresh zeroed, stable records and live borrowed table,
bitmap and buffer references. These helpers do not allocate, acquire ownership,
initialize the code-generation queues or implement compiler destruction. Native
file/include ownership, task-selected constructors, complete lexer state and
compiler execution remain integration work.

The extracted declaration block is byte-preserved. Forward declarations use
type-name guards: blindly repeating `extern class` would shadow already-defined
document types in HolyC. Both x86-64 rebuild/reboot generations pass with the
shared initializers, exercising the production compiler-control constructor.

Host/native fixtures verify self/stream queue sentinels, default options, borrowed
symbol/bitmap/buffer bindings, preserved file metadata, zeroed untouched fields
and values beyond 32 bits in control/lexical fields, plus embedded intermediate-code fields.
CCmpCtrl is 472 bytes on x86-64 and 344 on i386; CLexFile is 80/52 bytes and
CCodeCtrl is 48/28 bytes. Native assertions also cover embedded record sizes and
critical offsets. The expanded symbol fixture, instruction audit and complete
314504-byte standalone kernel boot checks pass on the 8 MiB QEMU/486 profile.

The control record's saved-position stack now also has shared host/native
semantics and explicit native heap ownership. See `i386-lex-state.md` for shallow
payload lifetime, include-boundary rules and save/restore verification.
