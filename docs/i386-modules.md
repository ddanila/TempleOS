# i386 bootstrap modules

`CmpI386Module` compiles HolyC with the i386 backend and writes a `T32M` module.
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
| 4 | version | 2 | 1 |
| 6 | cpu | 1 | 3, the i386 instruction baseline |
| 7 | pointer_size | 1 | 4 |
| 8 | abi | 4 | 1, the contract in `i386-abi.md` |
| 12 | total_size | 4 | Exact file size |
| 16 | code_size | 4 | Nonzero, multiple of eight |
| 20 | record_count | 4 | Number of symbol/relocation records |
| 24 | records_offset | 4 | Exactly `32 + code_size` |
| 28 | strings_offset | 4 | Exactly `records_offset + 16 * record_count` |

Code starts at byte 32. Record and string bounds are checked against the supplied
file length before dereferencing them. Unsupported versions, CPU/ABI values, and
pointer widths are rejected. Instruction compatibility is checked separately by
the executable-range audit in the backend tests.

## Records (16 bytes each)

| Offset | Field | Meaning |
| --- | --- | --- |
| 0 | kind | 1: export; 2: imported relative call |
| 4 | offset | Offset within code, excluding the module header |
| 8 | name_offset | Offset from file start into the string area |
| 12 | name_length | 1–255 nonzero bytes, followed by a zero terminator |

An export points inside the code. An import identifies a four-byte, initially
zero displacement immediately following an `E8` call opcode. Duplicate patch
positions, invalid names, unknown record types, and out-of-bounds records are
rejected. Names are case sensitive. Current modules contain function code only;
absolute/data relocations, global storage, and heap records are not yet supported.

## Linking

Compile callers with `import` declarations and providers with matching function
definitions. Plain `extern` declarations still require a definition within their
compilation unit; they do not silently become imports.

The linker validates every input, assigns code positions, requires exactly one
export for each referenced symbol and for the entry name (default `Main`), and
rejects duplicate exports, unresolved imports, missing entries, or an image
exceeding the 32-bit size range. It copies code into a new allocation and patches
each call with `target_offset - (patch_offset + 4)`. Inputs remain unchanged.

The flat output begins with an eight-byte bootstrap entry area: `E9 rel32`
followed by three zero padding bytes. Module code follows on eight-byte
boundaries. The trampoline jumps to the selected entry without changing its
arguments or return address. Relative calls remain valid when the entire image
is moved. Same-module function addresses are computed relative to the executing
code, including self-references and forward declarations resolved by the compiler.
Taking an imported function's address needs a new relocation path and is currently
rejected. This flat output is bootstrap code, not another T32M module.

`python3 tools/test-i386.py --functions` compiles and links separate caller/provider
modules in both orders, executes relative imports and a self-callback in the
linked images in the protected-mode runner,
checks repeatable output and unchanged inputs, and exercises malformed module and
symbol-resolution rejection. Exported `.t32m` fixtures are saved under
`build/i386-functions-test/exports/`.
