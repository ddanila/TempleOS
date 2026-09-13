# i386 port progress

The full objective and acceptance gates remain in `PLAN.md`. The standalone
32-bit TempleOS environment is not yet implemented.

## Bootstrap evidence

`python3 tools/test-rebuild.py` packages an isolated test ISO, builds the compiler
and kernel inside the x86-64 guest, exports their uncompressed binaries via QMP,
boots those binaries, and rebuilds them again. Host tools package and transport
bytes; HolyC compilation occurs in TempleOS. The desktop image, archived binaries,
and user's writable disk are not modified by this test.

Two such generations have run successfully. In the initial run, exported sizes were 193,792 bytes for
the compiler and 189,760 for the kernel. The generations are not byte-identical:
the initial run found 22 differing compiler bytes and 67 differing kernel bytes.
The kernel has an embedded compilation timestamp, but differences beyond that
remain unexplained. This proves a rebuild/reboot cycle, not a reproducible-build
fixed point or complete M0 acceptance. Run manifests record hashes and differences
under `build/rebuild-test/result.json`.

Persistence, audio, multicore validation, 386 emulator profile selection, and
further source/binary difference analysis remain outstanding for M0.

## Initial i386 backend

`Compiler/I386/Expr.HC` uses the existing HolyC lexer/parser and consumes its IR.
It emits 386 integer instructions with a pair-of-dwords evaluation stack and
EDX:EAX returns. Currently supported: I64 literals, addition, subtraction,
multiplication, bitwise AND/OR/XOR/complement, negation, and parentheses.

`python3 tools/test-i386.py` compiles nine boundary-value expression cases inside
TempleOS, exports the machine code, audits executable instruction ranges, and
executes them in a separate 32-bit protected-mode BIOS/CHS runner with 8 MiB RAM
under QEMU's 486 model. Cases exercise carry, borrow, cross-word multiplication,
signed negation, complement, and wraparound. Expected values are fixed test
vectors; the host does not evaluate source to generate the target code.
Unsupported floating point, narrowing casts, and division are explicitly rejected.

## Function compilation in progress

`Compiler/I386/Core.HC` is selected by `CCF_TARGET_I386` in the normal compiler
pipeline. `CmpI386Buf` is an experimental cross-compilation entry point. It emits
fixed-arity integer functions, EDX:EAX arithmetic, stack arguments at EBP+8,
local scalar loads/stores, explicit casts, and callee cleanup. Comparisons,
conditional branches, `if`/`while`/`do`/`for`, unary operations, prefix/postfix
increment/decrement, arithmetic/bitwise compound assignments, and 64-bit shifts
are also emitted. `Compiler/I386/Divide.HC` provides a relocatable 32-bit
quotient/remainder template assembled by HolyC and copied into target functions.
Signed division truncates toward zero, including constant powers of two; signed
remainders follow the dividend. Zero divisors and signed quotient overflow raise
processor vector 0. Shift counts are masked modulo 64; signed right shifts extend
the sign and unsigned right shifts insert zero bits. Target-size queries
cover parser member/local layouts, `sizeof`, and pointer arithmetic without
changing the running compiler's object pointers. `Kernel/Types.HH` shares the
numeric unions without requiring the complete architecture-specific kernel header.

The x86-64 bootstrap handles folded integer array bounds/default expressions via
an explicit host-constant path. It produces a host return stub containing the
folded value; target function bytes are never used as host executable code.
Nonconstant host evaluation and `#exe` are unsupported. This is temporary
bootstrap machinery, not the eventual native i386 compiler implementation.

Run `python3 tools/test-rebuild.py` before
`python3 tools/test-i386.py --functions` so the test boots the newly built compiler.
150 function cases pass on QEMU's 486 model with 8 MiB RAM. The runner checks
arguments, returns, stack cleanup, preserved registers, pointer-array and packed
class sizes, pointer indexing/wraparound, narrow integer conversion, signed and
unsigned comparisons, loops, mutation operations, and HolyC lvalue storage
reinterpretation. Shift cases cover counts 0, 31, 32, 63, and 64, constant counts,
and compound assignments. Division cases cover mixed signedness, multiword
quotients/remainders, constant divisors, and compound assignments. Four cases
require vector 0 for zero divisors or signed quotient overflow; the runner checks
the exact fault count. Call cases cover forward/backward references within one
compilation unit, recursion, nested calls, zero/two/three arguments, default
arguments, void and narrow returns, pointer mutation, and full argument-slot
extension. Boolean cases cover `&&`, `||`, and `^^`, nested conditions, skipped
side effects, and skipped division faults. F64 output, unresolved functions, and `#exe` remain rejection cases.
Exported function boundaries separate executable code from AOT alignment padding
during instruction auditing. Callback cases cover self-recursion, forward and
backward function addresses, nested calls, callback parameters, class fields and
arrays of records, narrow arguments/returns, void and zero-argument callbacks,
and default arguments. Function pointer loads use the target's four-byte width.
Undefined function addresses are rejection cases. Imported addresses are covered
by the data/module corpus. The runner reports the zero-based case index in
hexadecimal on failure. Function bodies
are exercised; the cases may contain multiple functions in one compilation unit.
Resident-module integration, switch dispatch,
chained comparisons, variadic functions, debug information, and
software F64 are not implemented by this backend.

## Bootstrap module format and linking

`CmpI386Module` writes architecture-tagged T32M objects; `I386Link` resolves
relative-call and address imports between separately compiled objects on the x86-64 HolyC
host. See [module format](i386-modules.md). The fixed-width header records CPU,
pointer width and ABI version; incompatible values are rejected.

Two linked-image cases execute caller/provider objects in both input orders.
The caller also invokes a callback to itself, checking address materialization
when the linker changes its position.
They also check repeatable output and byte-for-byte unchanged inputs. Validation
covers 19 malformed header/record variants (including overflow-shaped counts),
truncated/null buffers, duplicate exports, unresolved imports, and missing entry
symbols. An independent host read of the four exported fixtures confirms the
header layout, symbol names, and relocation records. This is a bootstrap static
linker using the shared native loader; resident kernel symbol integration,
absolute pointer initializers, and module lifecycle support remain unfinished.

Version-2 modules classify data ranges and distinguish function/data exports.
All 16 `python3 tools/test-i386.py --data` cases pass in the 8 MiB QEMU 486
runner, together with five link/initializer rejection checks. The corpus covers
zero/constant global and static storage, four-byte
pointers, packed records, initialized and inferred arrays, character arrays,
shared data imports in both module orders, and imported callbacks. It also checks
narrow array stores and compound assignments. Data cannot serve as a call target
or module entry; duplicate function/data symbol names are rejected. Pointer-to-string
and executable initializers are rejected before emitting target initialization code.
The instruction audit accounts for data boundaries and alignment padding explicitly.

`Kernel/I386/ModuleCheck.HC` now shares the same validator between the host
module tools and target code. `python3 tools/test-i386-module-check.py` compiles
that function through the i386 backend and executes 35 cases in the protected-mode
runner: valid modules, null/truncated buffers, negative and oversized lengths,
malformed records, duplicate patches, modules without symbol records, data-range
overlaps/bounds, code/data export mismatches, address imports, and legacy-version
rejection. This
exercises a real kernel unit with target pointer layouts and short-circuit guards;
the allocation-free loading implementation is exercised separately below.

`Kernel/I386/ModuleLoad.HC` loads a validated module set into caller-owned memory.
The host linker and the native target execute the same implementation. All 23
`python3 tools/test-i386-loader.py` cases pass on the 8 MiB QEMU 486 runner,
including executing each valid image at two addresses. Failure paths check capacity,
input/output overlap, address wrap, symbol errors, and unchanged buffers. The
loader uses no allocation or host calls. Filesystem access, a resident kernel
symbol registry, and lifetime/unloading integration are still required.

This remains partial M1/M2 work. There is no software F64,
full kernel, native i386 compiler, or DolDoc desktop yet. Passing the runner does not prove 386SX/DX support,
low-memory self-hosting, or completion of M1/M2. See `docs/i386-abi.md` for the
working ABI decisions and remaining boundaries.

## Direct hardware I/O

The i386 backend now lowers `InU8`, `InU16`, `InU32`, `OutU8`, `OutU16`, and
`OutU32` to 386 port instructions. Arguments keep eight-byte slots; ports use
DX, output values use AL/AX/EAX, and input values are zero-extended to EDX:EAX.
Nine function cases cover all six operations, nested intrinsic calls, high-bit
truncation, and VGA sequencer map-mask writes/readback using byte and word output.
The existing runner checks stack cleanup and preserved registers for these cases.
Unassigned-port read values are QEMU-specific test expectations; they are not a
hardware discovery mechanism or a promise about physical machines. Those cases
exercise output execution but do not independently observe word/dword output data.
Executable instruction auditing covers the generated I/O instructions.

Both x86-64 rebuild/reboot generations and the 150-case i386 function corpus pass.
This is a prerequisite for platform drivers, not a framebuffer presentation test.
The initial VGA upload implementation is described below; keyboard, timers, and
native allocation remain pending.

## Native VGA presentation

`Kernel/I386/Vga.HC` provides `I386VgaPalette` and `I386VgaPresent`, compiled by
HolyC into the i386 module format. Presentation accepts the existing 640×480
TempleOS planar layout: four consecutive 38,400-byte planes with the left pixel
in the low bit. It reverses each byte for VGA, selects each hardware plane, and
writes the 0xA0000 aperture. The implementation uses byte accesses and requires
no newer CPU instructions. Palette setup follows the existing attribute-index
and six-bit DAC programming sequence. `Kernel/I386/Ports.HH` supplies standalone
intrinsic declarations for platform units; full kernel declarations remain in
`KernelB.HH`.

`python3 tools/test-i386.py --vga` cross-compiles the actual implementation,
audits its executable regions, and boots a BIOS-CHS protected-mode runner on
QEMU's 486 model with 8 MiB RAM. The guest uploads a filled framebuffer, replaces
it with an asymmetric 16-color pattern, and returns through the normal ABI
checks. QMP captures the display; all 307,200 pixels match independent host-side
coordinate/color expectations. The screenshot comparison uses QEMU's specific
[six-bit DAC conversion](https://github.com/qemu/qemu/blob/v10.2.1/hw/display/vga_int.h#L150-L156).
The 150-function regression corpus and both x86-64 rebuild generations also pass.

The BIOS still establishes mode 0x12 before protected-mode entry. These routines
require that mode's graphics-controller configuration and exclusive caller-owned
VGA access. No scheduler locking, dirty-region optimization, retrace scheduling,
or window-manager integration is implemented yet. The test reserves its source
buffer at 0x30000; this is not a native memory allocator or a measured full-OS RAM
budget. This result does not establish physical VGA or 386SX/DX compatibility.

## Test artifacts

- `build/rebuild-test/`: build ISOs, both exported generations, QEMU commands,
  debug logs, screenshots, and source/binary hash manifest.
- `build/i386-module-check/`: shared validator code, module fixture, disassembly,
  malformed-input corpus, runner log, and result JSON.
- `build/i386-loader-test/`: native loader image, disassembly, module packets,
  and loaded-code execution results.
- `build/i386-data-test/`: linked code/data corpus, version-2 module fixtures,
  executable/data boundaries, disassembly, and target runner results.
- `build/i386-vga-test/`: compiled presentation code, instruction audit, disk,
  QMP display captures, pixel comparison result, and emulator command.
- `build/i386-functions-test/`: function corpus, disassembly, ABI runner and logs.
- `build/i386-test/`: compiler ISO, generated expressions, disassembly of code
  ranges, test disk, runner log, and result JSON.

The runner's minimal vector-0 handler abandons an expected failing function and
continues the corpus. It is isolated test instrumentation, not the ported kernel's
exception or task-unwinding implementation.

`tools/guest-run.py` owns each test QEMU process and terminates it on completion
or failure. Its port 0xE9 report/export protocol is test instrumentation, not a
new production OS dependency. The ISO builder's overlays inject guest test files
without modifying production startup files.
