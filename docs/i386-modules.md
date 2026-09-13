# i386 bootstrap modules

`CmpI386Module` compiles HolyC with the i386 backend and writes a version-2 `T32M`
module. `I386ModuleValid` checks its structure and architecture/ABI fields.
`I386LoadInto` validates and loads a set of modules into caller-owned memory on
both the x86-64 host and the native i386 target. `I386Link` provides the host
allocation wrapper. The module format is distinct from the existing x86-64 BIN
format. Filesystem integration, resident kernel symbols, and module lifetime
management are still pending.

All fields are little endian and all offsets/counts are unsigned fixed-width
integers. No host pointer, host class image, source link, or timestamp is stored.
The structures are defined in `Kernel/I386/Module.HH` with size assertions.

## Header (32 bytes)

| Offset | Field | Width | Required value or meaning |
| --- | --- | --- | --- |
| 0 | magic | 4 | `T32M` (`0x4D323354`) |
| 4 | version | 2 | 2; version 1 is rejected |
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
| 0 | kind | 1: function export; 2: call import; 3: data export; 4: data range; 5: address import |
| 4 | offset | Offset within the payload, excluding the module header |
| 8 | name_offset | Named record: file offset into strings; data range: byte length |
| 12 | name_length | Named record: 1–255 nonzero bytes plus NUL; data range: zero |

A function export points outside all data ranges; a data export points inside a
range. Ranges must be nonempty, contained in the payload, and mutually disjoint.
A call import identifies a zero dword immediately following `E8`. An address
import identifies a zero dword following `05` (`ADD EAX,imm32`); the emitter first
obtains a program-counter value and adjusts it to the end of that immediate.
Both imports use `symbol_offset - (patch_offset + 4)` and occupy code bytes.
Overlapping patches, patches touching data, invalid names, and unknown kinds are
rejected. Names are case sensitive.

Global and static storage occupies bytes in the payload, including zero-initialized
storage. Fixed-width scalar, array, packed-record, and character-array initializers
are supported. Pointer storage uses four bytes; numeric/null pointer initializers
and pointers assigned by running code work. Absolute pointer initializers such as
`U8 *p="text"`, executable initializers, and heap records remain unsupported.
There is no separate on-disk BSS representation yet.

## Linking

Compile callers with `import` declarations and providers with matching function
definitions. Plain `extern` declarations still require a definition within their
compilation unit; they do not silently become imports.

The linker validates every input, assigns code positions, requires exactly one
export for each referenced symbol and one function export for the entry name
(default `Main`), and
rejects duplicate exports, unresolved imports, missing entries, or an image
exceeding the 32-bit size range. It copies code into a new allocation and patches
each call or address import with `target_offset - (patch_offset + 4)`. Inputs remain unchanged.

The flat output begins with an eight-byte bootstrap entry area: `E9 rel32`
followed by three zero padding bytes. Module code follows on eight-byte
boundaries. The trampoline jumps to the selected entry without changing its
arguments or return address. Relative calls remain valid when the entire image
is moved. Same-module function addresses are computed relative to the executing
code, including self-references and forward declarations resolved by the compiler.
Imported function and data addresses use address-import records. Direct calls
must resolve to functions; address imports may resolve to either kind of symbol. This flat output is bootstrap code, not another T32M module.

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
manage unloading.

`python3 tools/test-i386-loader.py` first regenerates the data fixtures, then
compiles this exact loader and executes it in the i386 runner. Its 23 cases cover
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
implied; resident kernel symbol binding and lifecycle integration remain pending.

The native loader fixture exercises simultaneous allocated images, exact size
queries, heap exhaustion, release and address reuse, and independent loaded data.
It also loads from a live source allocation, frees and overwrites that allocation,
and executes the resulting image. Malformed sets must allocate nothing. These
checks supplement the existing caller-buffer tests rather than replacing them.
The defensive rollback branch after a final-load failure is not fault-injected;
validated stable inputs and a valid nonoverlapping allocation normally make that
second load succeed.

The larger test image uses 256 single-sector CHS reads into 0x10000–0x2FFFF.
Other compiler runners retain the 128-sector default. The heap is selected from the BIOS-reported regions after A20 verification and
exclusion of the loaded stage, boot scratch, and the runner's scratch/stack
reservation. The 8 MiB fixture explicitly requires high-memory allocation. This remains a test
boot stage, not the production disk loader or a complete usable-memory map.

All 23 expanded native loader cases pass on the QEMU 486/8 MiB runner, together
with the 16 regenerated data cases and the native heap regression. This is not
a physical-386 result or completion of native OS module/lifetime integration.
