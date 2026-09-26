# i386 bootstrap modules

`CmpI386Module` compiles HolyC with the i386 backend and writes a `T32M` module: version 2 for position-independent payloads, version 3
when stored local data pointers require relocation, and version 4 when a stored pointer names a symbol outside its module. `I386ModuleValid` checks its structure and architecture/ABI fields.
`I386LoadInto` validates and loads a set of modules into caller-owned memory on
both the x86-64 host and the native i386 target. `I386Link` provides the host
allocation wrapper. The module format is distinct from the existing x86-64 BIN
format. Disk-backed loading and resident bindings use the same validator/loader;
general dependency-aware unloading remains open.

All fields are little endian and all offsets/counts are unsigned fixed-width
integers. No host pointer, host class image, source link, or timestamp is stored.
The structures are defined in `Kernel/I386/Module.HH` with size assertions.

## Header (32 bytes)

| Offset | Field | Width | Required value or meaning |
| --- | --- | --- | --- |
| 0 | magic | 4 | `T32M` (`0x4D323354`) |
| 4 | version | 2 | 2; 3 with at least one local stored-pointer record; or 4 with at least one named stored-pointer record |
| 6 | cpu | 1 | 3, the i386 instruction baseline |
| 7 | pointer_size | 1 | 4 |
| 8 | abi | 4 | 1, the contract in `i386-abi.md` |
| 12 | total_size | 4 | Exact file size |
| 16 | code_size | 4 | Total code/data payload bytes; nonzero, multiple of eight |
| 20 | record_count | 4 | Number of symbol/relocation records |
| 24 | records_offset | 4 | Exactly `32 + code_size` |
| 28 | strings_offset | 4 | Exactly `records_offset + 16 * record_count` |

The mixed code/data payload starts at byte 32. The historical field name
`code_size` covers the entire payload; data ranges classify its non-code bytes. Record and string bounds are checked against the supplied
file length before dereferencing them. Unsupported versions, CPU/ABI values, and
pointer widths are rejected. Instruction compatibility is checked separately by
the executable-range audit in the backend tests.

## Records (16 bytes each)

| Offset | Field | Meaning |
| --- | --- | --- |
| 0 | kind | 1: function export; 2: call import; 3: data export; 4: data range; 5: address import; 6: stored local data pointer (v3/v4); 7: named stored pointer (v4) |
| 4 | offset | Offset within the payload, excluding the module header |
| 8 | name_offset | Named record: file offset into strings; data range: byte length; local stored pointer: target payload offset |
| 12 | name_length | Named record: 1–255 nonzero bytes plus NUL; data range/local stored pointer: zero |

A function export points outside all data ranges; a data export points inside a
range. Ranges must be nonempty, contained in the payload, and mutually disjoint.
A call import identifies a zero dword immediately following `E8`. An address
import identifies a zero dword following `05` (`ADD EAX,imm32`); the emitter first
obtains a program-counter value and adjusts it to the end of that immediate.
Both imports use `symbol_offset - (patch_offset + 4)` and occupy code bytes.
Overlapping code patches, code patches touching data, invalid names, and unknown
kinds are rejected. Names are case sensitive.

Global and static storage occupies bytes in the payload, including zero-initialized
storage. Fixed-width scalar, array, packed-record, and character-array initializers
are supported. Pointer storage uses four bytes; numeric/null pointer initializers
and pointers assigned by running code work. String-pointer initializers such as
`U8 *p="text"` produce version-3 records, including globals, statics, aggregate
members and pointer arrays. The guest packer can also name exact external
function or global addresses in version-4 records. General executable initializers,
interior pointers to external data, and heap records remain unsupported.
There is no separate on-disk BSS representation yet.

## Stored local data pointers

Kind 6 identifies a four-byte slot wholly contained in one data range. Its
`name_offset` is a target byte inside a data range in the same module; `name_length`
is zero. The serialized slot must contain zero. Slots cannot overlap one another,
straddle a range boundary or touch code. Targets outside classified data are
rejected. Multiple slots may refer to the same target. Version 2 rejects these
records; version 3 requires at least one. Version 4 may contain local records
alongside at least one named record.

The compiler emits four-byte AOT absolute records and separate literal data ranges,
then serializes the module-local target into kind 6 and zeroes the slot. Loading
writes `load_address + module_offset_in_image + target_offset`. No host allocation
address enters the module. The source file remains unchanged, and loaded literal
storage belongs to the loaded image, independently of the serialized source.

## Named stored pointers

Kind 7 identifies a zeroed four-byte data slot and a unique named function or
data export in another selected module or an explicit binding. Its name uses the
ordinary string table. The loader validates every name before writing the image,
then writes the absolute loaded address of that export or binding into the slot.
The slot must fit wholly inside a data range and cannot overlap another stored
pointer. An unresolved or duplicate name rejects the whole load. Version 4
requires at least one kind-7 record; versions 2 and 3 reject it.

The native packer chooses a local kind-6 record for selected data and a kind-7
record only for an exact, unambiguous external symbol address. This supports
persisting the pointer-bearing consumer and its provider as separate modules.
The caller must retain both loaded modules for as long as that pointer is used.

## Linking

Compile callers with `import` declarations and providers with matching function
definitions. Plain `extern` declarations still require a definition within their
compilation unit; they do not silently become imports.

The linker validates every input, assigns code positions, requires exactly one
export for each referenced symbol and one function export for the entry name
(default `Main`), and
rejects duplicate exports, unresolved imports, missing entries, or an image
exceeding the 32-bit size range. It copies code into a new allocation and patches
each call or address import with `target_offset - (patch_offset + 4)`. Stored local
pointers receive absolute destination addresses. Inputs remain unchanged.

The flat output begins with an eight-byte bootstrap entry area: `E9 rel32`
followed by three zero padding bytes. Module code follows on eight-byte
boundaries. The trampoline jumps to the selected entry without changing its
arguments or return address. Module-local relative calls remain valid when the
entire image is moved; images with stored pointers or resident bindings must be
reloaded for the new address. Same-module function addresses are computed relative to the executing
code, including self-references and forward declarations resolved by the compiler.
Imported function and data addresses use address-import records. Direct calls
must resolve to functions; address imports may resolve to either kind of symbol. This flat output is bootstrap code, not another T32M module.

The host `I386Link` accepts an optional final `I64 load_address=-1`. The default
permits position-independent module sets. A stored-pointer set requires an explicit
future address and is rejected without one, even if the host heap happens to be
below 4 GiB. The complete image must fit that 32-bit address range. The standalone
kernel links at `0x11000`; its BIOS stage reserves a fixed 4096-byte prefix from
`0x10000`, and the builder checks placement and relocated values independently.

`python3 tools/test-i386.py --functions` compiles and links separate caller/provider
modules in both orders, executes relative imports and a self-callback in the
linked images in the protected-mode runner,
checks repeatable output and unchanged inputs, and exercises malformed module and
symbol-resolution rejection. Exported `.t32m` fixtures are saved under
`build/i386-functions-test/exports/`.

`python3 tools/test-i386.py --data` exercises persistent globals/statics, target
pointer and packed-record layouts, initialized/inferred arrays, shared data imports
in both module orders, and imported callback addresses. The instruction audit uses
export and data-range boundaries and rejects unclassified non-padding bytes.
`python3 tools/test-i386-module-check.py` executes the shared validator itself as
i386 code, including malformed data-range and export-kind fixtures.

## Native loading API

`Kernel/I386/ModuleLoad.HC` implements:

```text
I64 I386LoadInto(U8 **modules, I64 *sizes, I64 count,
                U8 *image, I64 capacity, U8 *entry_name)
```

A successful call returns the image size; failure returns zero. Passing a null
image with zero capacity validates the complete module set and queries the needed
size. A non-null output must have enough capacity. Entry names must contain 1–255
bytes followed by NUL. Pointer tables use the executing architecture's pointer
width; size/count/capacity arguments retain I64 widths.

The caller supplies readable input arrays and module buffers, keeps them stable
through the call, and owns writable output storage. The loader rejects an output
range that wraps its address space or overlaps the module bytes, pointer/size
tables, or entry name. It validates every module, symbol, and relocation before
writing, so rejected loads leave output and inputs unchanged. Successful loads
write exactly the returned number of bytes. No allocator, host callback, floating
point, or exception runtime is required by the loader itself.

The output begins with the entry trampoline and can be called using the entry
function's HolyC signature. The caller controls execution and retains the buffer
while code, data, or function pointers still refer to it. This API loads a complete
module set; it does not yet bind imports to an existing kernel symbol registry or
manage unloading. Resident bindings are available through `I386LoadBoundInto`.

`python3 tools/test-i386-loader.py` first regenerates the data fixtures, then
compiles this exact loader and executes it in the i386 runner. Its cases cover
loaded code/data at two output addresses, malformed/truncated modules, unresolved
and duplicate exports, missing entries, and attempts to use data as code. Each
valid case also checks size queries, exact/insufficient capacity, buffer overlap,
address wrapping, invalid arguments, unchanged input bytes, output sentinels,
and the loaded program's result. Artifacts are in `build/i386-loader-test/`.

## Allocating native loader

`Kernel/I386/ModuleAlloc.HC` combines the arena allocator with the shared loader:

```text
U8 *I386LoadAlloc(CI386Heap *heap, U8 **modules, I64 *sizes,
                  I64 count, U8 *entry_name)
```

It validates and queries the complete module set before allocating. Success
returns a heap-owned image beginning at the entry trampoline; `I386HeapSize`
reports its byte size. Invalid input, unavailable memory, or an invalid heap
returns zero. If the final load fails after allocation, the temporary allocation
is freed. The try-allocation interface does not throw `OutMem`.

Inputs and heap access must remain stable and serialized throughout the call.
Inputs may reside in the same heap, but must then occupy live allocations, not
unallocated space. After a successful load, source module bytes and their tables
may be released: the loaded payload owns the code and data needed for execution.
The caller must retain the image while any executing code, data pointer, callback,
or other reference still depends on it. Once idle and unreferenced, release the
entire image with `I386HeapFree`. No reference registry or automatic unloading is
implied. Resident kernel bindings are supplied explicitly through the bound loader;
automatic dependency tracking and unloading remain open.

The native loader fixture exercises simultaneous allocated images, exact size
queries, heap exhaustion, release and address reuse, and independent loaded data.
It also loads from a live source allocation, frees and overwrites that allocation,
and executes the resulting image. Malformed sets must allocate nothing. These
checks supplement the existing caller-buffer tests rather than replacing them.
The defensive rollback branch after a final-load failure is not fault-injected;
validated stable inputs and a valid nonoverlapping allocation normally make that
second load succeed.

The larger test image uses 256 single-sector CHS reads into 0x10000–0x2FFFF.
Other compiler runners select transfer sizes for their own fixtures. The heap is selected from the BIOS-reported regions after A20 verification and
exclusion of the loaded stage, boot scratch, and the runner's scratch/stack
reservation. The 8 MiB fixture explicitly requires high-memory allocation. This remains a test
boot stage, not the production disk loader or a complete usable-memory map.

All 37 native loader cases pass on the QEMU 486/8 MiB runner, including the
27 regenerated data cases and malformed stored-pointer records. Loaded pointers
are checked against each allocation address, including simultaneous images and
source-buffer destruction. This is not a physical-386 result or completion of
native OS module/lifetime integration.

## Function-body string literals

The native COC backend now emits position-independent addresses for
`IC_STR_CONST`. Literal bytes, including their trailing NUL and any embedded NULs,
follow the function's executable body. A module data-range record covers that
pool so validation and instruction auditing do not decode literal bytes as code.
The address uses a local CALL/POP plus displacement and zeroes the high half of
the pointer value. It needs no load-address relocation and remains valid for the
lifetime of the loaded image. Literal identity/deduplication is not guaranteed.

The native input fixture exercises multiple table literals, empty strings and
an embedded-NUL string returned from another function. The existing 155 compiler
cases also pass. This adds function-body expressions, not address-bearing global
or static initializers, a general native assembler, or self-hosted compilation.
