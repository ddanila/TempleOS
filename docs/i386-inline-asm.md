# Native HolyC inline assembly

The i386 function backend accepts `IC_ASM` blocks and instruction statements.
The shared HolyC assembler emits the bytes on the compiler host. Native blocks
default to USE32; explicit USE32 is allowed. USE16, USE64, 64-bit general
registers and extended general registers are rejected on this target. The x64
assembler's mode selection remains unchanged.

`Compiler/I386/Asm.HC` appends assembly bytes to the native function output.
Relative I8/I16/I32 references to enclosing HolyC/assembly labels are fixed up
using native byte offsets on the final emission pass, including numeric addends.
Resolved assembly-local branches are already position independent. Branches into
assembly use the label's offset within the block. The nested native parser keeps
assembly label nodes, appends them to the enclosing function and joins preceding
HolyC goto placeholders to their definitions before assigning addresses.

Assembler expressions are a separate host operation. They may read the live
I64 value fields of unresolved host assembler symbols, so they cannot all be
folded immediately. The native path validates their IR, permits integer
arithmetic and reads only of those known host symbol fields, then uses the host
backend to compile the expression. Symbol values and host field addresses retain
host I64 width. Calls, target-memory reads and stores are rejected in this path;
emitted 32-bit target instructions are never executed by it. Ordinary target
array/default constant evaluation continues through its existing restricted path.

Inline code shares the native function's frame: four-byte saved EBP/return
address, eight-byte argument slots starting at EBP+8, and target-sized local
layout. `&local` in an assembly operand supplies the local's frame offset.
The function prologue/epilogue saves and restores EBX, ESI and EDI; inline code
may use them as scratch registers. Assembly must leave ESP/EBP and the direction
flag compatible with subsequent HolyC execution unless it intentionally performs
nonlocal transfer. It runs with the same direct ring-0 access as HolyC.

Absolute relocations, inline external imports/exports and assembly storage
relocations remain unsupported and produce compiler errors. This is not yet a
complete native assembler or a replacement for every bootstrap NASM module.
Instruction auditing remains required for the 386 baseline: rejecting 64-bit
registers does not establish that arbitrary user-supplied assembly uses only
80386 instructions. Embedded byte directives also do not bypass that requirement.

`python3 tools/test-i386.py --inline-asm` compiles through the shared HolyC parser,
links the native output and executes it in protected mode. The corpus checks
wide argument writes, loops, local assembly calls, branches between HolyC and
assembly, numeric branch addends, assembler arithmetic, named local offsets and
preservation of caller registers. Negative cases cover unsupported modes,
registers and absolute label addresses. Exported executable regions are audited
as 32-bit instructions. This is component evidence, not native self-hosting or
strict physical-386 verification.


## Bootstrap provider migration

Top-level USE32 assembly can already use the ordinary module export and REL32
import path. `Kernel/I386/SysTry.HC` now uses it for the real two-argument SysTry
entry, replacing the hand-built NASM module. The exception fixtures compile this
source inside TempleOS and link it against HolyC runtime services. This removes
one host assembler dependency; the remaining bootstrap/interrupt stubs
and full native compiler self-hosting still need migration and verification.

`Kernel/I386/ExceptContext.HC` also builds through this path, exporting the save,
invoke, resume and registration primitives as a relocation-free module. The
runner embeds the HolyC-generated code and resolves entry offsets from its
exports, so register/flag and task-switch checks exercise those exact bytes.
