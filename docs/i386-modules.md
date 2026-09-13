# i386 bootstrap modules

`CmpI386Module` compiles HolyC with the i386 backend and writes a version-2 `T32M` module.
`I386ModuleValid` checks its structure and architecture/ABI fields. `I386Link`
links an array of modules into a flat bootstrap image. These functions currently
run inside the x86-64 HolyC compiler host. The shared validator also has a native
i386 execution test; a native i386 runtime loader remains
unfinished. The module format is distinct from the existing x86-64 BIN format.

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
