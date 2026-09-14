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
