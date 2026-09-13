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
heap integration with the full kernel remain pending.

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
or window-manager integration is implemented yet. The test now obtains and releases its source buffer through the native arena
allocator described below. Its arena is selected from the BIOS memory handoff
after A20 verification, with the stage and stack reserved; this is not a full-OS RAM measurement. This result does not establish physical VGA or 386SX/DX compatibility.

## Native arena allocation

`Kernel/I386/Heap.HC` now executes on the target. It implements eight-byte-aligned
first-fit allocation, optional zero fill, requested-size lookup, adjacent-block
coalescing, live/peak span accounting, and whole-chain integrity checks. It uses
no x86-64 assembly or host runtime calls. See [the heap contract](i386-heap.md)
for failure behavior and remaining kernel integration.

`python3 tools/test-i386.py --heap` runs one compiled test entry containing checks
for initialization rejection without writes, alignment, zero-size allocation,
zero fill, exact exhaustion, splitting/coalescing, small-tail absorption,
foreign/interior/double-free rejection, accounting, guard bytes, and malformed
metadata. A deterministic 512-operation allocation/free sequence checks live
payload contents and heap integrity throughout. The generated code passes the
386 instruction audit and the preserved-register/stack ABI runner on QEMU's 486
model with 8 MiB RAM. The VGA test also allocates its 153,600-byte framebuffer
through this implementation, presents it, frees it, and checks heap integrity;
all 307,200 screenshot pixels still match.

These are single-owner arena tests. General device-hole discovery, task-owned
page pools, concurrency/interrupt handling, task teardown, and public allocation
wrappers remain pending. The
full OS's low-memory requirements remain unmeasured.

## Allocated native modules

`Kernel/I386/ModuleAlloc.HC` now joins the native heap and shared module loader.
It validates before allocation and returns an independently owned executable
image; the caller queries its size and releases it through the heap API. The
allocator definition now retains the same optional `zero` argument as its
prototype, so callers compiled after the definition can omit that argument too.

All 23 native loader cases pass with the expanded fixture. Valid module sets are
loaded into two simultaneous heap allocations, executed, freed, and loaded again
at a reused address with fresh data. They also load from source modules held in
live heap storage, then execute after that source storage is freed and overwritten.
Tests cover exact allocation sizes, heap exhaustion, a null heap, no allocation
for malformed sets, and zero live allocations after release. The original
caller-buffer overlap, capacity, symbol, and input-preservation checks remain.
The 16 data cases, native heap stress fixture, and both x86-64 rebuild generations
also pass. See [the allocating API](i386-modules.md#allocating-native-loader).

This fixture now needs a larger test stage: 256 individual BIOS CHS sector reads
load at most 128 KiB beginning at 0x10000. The other runners keep their 128-sector
default. Both paths pass target execution checks. The heap is now selected from
the BIOS handoff below, with explicit runner reservations and verified A20 for
extended RAM. Filesystem integration, resident kernel symbol binding,
public allocation/exception interfaces, and coordinated unloading remain pending.

## BIOS conventional-memory handoff

The CHS test boot path now records INT 12h conventional memory, the BDA's EBDA
address, an optional INT 15h/AH=88h extended-memory result, and the loaded stage
bounds. `Kernel/I386/BootMemory.HC` validates that fixed-width record and selects
the largest aligned conventional-memory gap after subtracting caller reservations.
It excludes low boot/firmware data, loaded code, EBDA, and VGA/ROM space. Its default
also excludes memory above 1 MiB; the verified-A20 opt-in is described below. Reservation order and overlap do not change the selected free gap.
VGA and module loading now initialize their heaps from this result while reserving
the runner's packet buffer and protected-mode stack. All 307,200 VGA pixels and
all 23 loader cases still pass, along with the 16 data-module cases.

`python3 tools/test-i386.py --memory` tests the real handoff and synthetic records
covering limits, malformed inputs, range unions, alignment, endpoint overflow,
minimum size, equal-size choices, and unchanged outputs on rejection. It also runs
an injected carry-set failure of the legacy extended-memory query. The same native
selector passes with or without that optional result. Both x86-64 rebuild/reboot
generations pass; this remains QEMU 486/8 MiB evidence. See the detailed
[boot memory contract](i386-boot-memory.md).

The production boot path, general device-hole discovery, and task/page-pool
integration remain pending. These tests do not establish the full OS's memory
budget or native 386 compatibility.

## Native A20 and extended memory

`Kernel/I386/A20.HC` now verifies and enables A20 using native HolyC port I/O and
restoring memory probes. It recognizes an already-open gate, supports the legacy
keyboard-controller sequence, and offers an explicitly enabled port-0x92 fallback.
Polling is bounded and success requires a non-aliasing memory check. The code is
for low-memory boot execution before input initialization, with interrupts disabled.

`python3 tools/test-i386.py --a20` forces the gate closed and checks aliasing,
zero-budget failure, controller enabling, fast fallback, invalid polling limits,
and preservation of both scratch bytes. It then allocates the full selected
high-memory arena, verifies distinct U32 values at every 4 KiB interval and a
marker at its last byte, and frees it. The memory selector's extended opt-in skips
the first 64 KiB above 1 MiB and caps the region at 15 MiB; caller reservations
still apply, and conventional RAM remains available when high memory is excluded.

The A20 and expanded memory fixtures pass the instruction audit and native ABI
runner. VGA explicitly requires a high-memory framebuffer in its 8 MiB QEMU
profile and all 307,200 displayed pixels match. All 23 native loader cases now
require and execute heap-owned images above 1 MiB; its 16 data-module regressions
also pass. Both x86-64 rebuild/reboot generations pass. See the detailed
[A20 and extended-memory contract](i386-a20.md) for hardware assumptions, controller
side effects, and validation limits. No physical-386 or full-OS memory claim follows.

## PIC/PIT/RTC interrupt entry

`Kernel/I386/PicPit.HC` now programs the legacy PIC pair and PIT from native
HolyC. The PIC uses vectors 0x20–0x2F, exact mask read/write, spurious IRQ7/15
checks, and slave-before-master EOI. PIT channel 0 uses binary mode 2 and an
8253-compatible counter latch. `Kernel/I386/Irq.asm` provides sixteen 386 stubs
that save a fixed-width frame, clear DF, call HolyC, restore registers/segments,
and return with IRETD. The current bootstrap links these stubs with NASM.

`python3 tools/test-i386.py --irq` passes with at least 32 PIT IRQs at divisor
11932 and four at divisor 65536. It checks a 64-bit counter crossing the 32-bit
boundary, mask readback, counter changes, frame offsets, saved general registers,
IF/DF inside the callback, and restored general registers, FS/GS and DF afterward.
Software vectors 0x27/0x2F exercise the spurious rejection paths. Production stubs
and test IDT/wait assembly have separate instruction audits excluding data tables.
The 150-function regression corpus and both x86-64 rebuild generations also pass.
See the [interrupt ABI and limits](i386-interrupts.md).

`Kernel/I386/Rtc.HC` adds exclusive boot-time CMOS access and a saved A/B
configuration for periodic IRQ8. Two more test phases each receive at least eight
RTC IRQs at rate codes 10 and 11, with PIT IRQ0 masked. They check status C's
IRQF/PF, frame restoration, both PIC EOIs through repeated slave delivery,
configuration restoration, restart, and invalid rates/state transitions. CMOS
access keeps NMI disabled; calendar reads and general shared ownership are pending.

This is IRQ0/IRQ8 delivery in the QEMU 486/8 MiB runner, not a complete interrupt/time
subsystem. Keyboard input, exception entry, scheduling,
calibrated time, production boot wiring and physical 386 validation remain pending.

## Test artifacts

- `build/rebuild-test/`: build ISOs, both exported generations, QEMU commands,
  debug logs, screenshots, and source/binary hash manifest.
- `build/i386-module-check/`: shared validator code, module fixture, disassembly,
  malformed-input corpus, runner log, and result JSON.
- `build/i386-loader-test/`: native loader image, disassembly, module packets,
  and allocated/caller-buffer loaded-code execution and lifetime results.
- `build/i386-data-test/`: linked code/data corpus, version-2 module fixtures,
  executable/data boundaries, disassembly, and target runner results.
- `build/i386-irq-test/`: compiled PIC/PIT/RTC and callback code, audited assembly
  ranges, interrupt runner, and execution result.
- `build/i386-a20-test/`: native gate-method and high-memory allocation fixture,
  instruction audit, runner disk/log, and result.
- `build/i386-memory-test/`: native handoff/selector fixture, instruction audit,
  normal and injected-query-failure boot disks/logs, and results.
- `build/i386-heap-test/`: compiled allocator and integrity/stress fixture,
  instruction audit, runner disk, and target results.
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
