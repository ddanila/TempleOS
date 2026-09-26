# i386 port progress

The full objective and acceptance gates remain in `PLAN.md`. The standalone
32-bit TempleOS environment is not yet implemented.

## Progress checkpoint (2026-09-25)

This checkpoint collects the work since `c7af3bd`: expanded canonical document
editing, structured/binary DolDoc persistence and cross-reading, save failure
recovery, project file navigation and RedSea rename/move recovery, packaged help
navigation, PC-speaker output, and PS/2 mouse integration. The native editor now
supports selection, clipboard, search/replace, undo, styles, scrolling, save and
execution with return to editing. Mouse input reaches the editor, file picker,
help viewer and idle console, including double-click activation and verified
vertical and horizontal edge-drag paths.

Current-source validation is recorded in the local build artifacts:

- `build/rebuild-test/result.json`: two x86-64 rebuild/reboot generations.
- `build/i386-kernel/result.json`: native cross-build, 429600-byte kernel;
  the latest build did not run the complete `--test` promotion gate. The new
  boot audit covers 96 BIOS and 33 protected-mode instructions.
- `build/i386-mouse-held-green-attempt/result.json`: 46 native commands,
  including timer-driven held-edge scrolling, exact VGA cells and canonical
  save bytes; QEMU `486,-fpu`, 8 MiB, 48.178-second startup.
- `build/i386-mouse-held-combined/result.json`: 204 native commands,
  mouse plus document editing, exact VGA frames, QEMU `486,-fpu`, 8 MiB,
  48.132-second startup; release stops the held-edge repeat.
- `build/i386-doldoc-session-no-fpu-help/result.json`: writable three-boot
  project acceptance, 107/56/15 guest commands on QEMU `486,-fpu`, 8 MiB;
  F1 help return, F5 execution, revision across reboots, and independent
  RedSea extent/bitmap integrity all pass.
- `build/i386-doldoc-session-pentium3-no-fpu/result.json`: the same three-boot
  project acceptance passes on QEMU `pentium3,-fpu`, 8 MiB, with the same final
  candidate disk SHA-256 and independent filesystem audit.

The current disk SHA-256 is
`18962f93d172b9c34ef2d291272c4aed8786698e9a22ff58e20e5e60ad05c648`.
Both build manifests' recorded source hashes match the checkpoint's guest source.
Their revision field names the pre-commit base because the builds ran in the
working tree. Earlier sections preserve evidence for intermediate images; those
results do not constitute a full promotion run on this final image.

The standalone-development goal remains open. Original DocEd/ExeDoc integration,
full document layout, complete public programming/debugging services, integrated
resource acceptance and the QEMU 386 instruction audit remain required.
Native self-hosting remains the following major goal.

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
155 function cases pass on QEMU's 486 model with 8 MiB RAM. The runner checks
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

`Kernel/I386/Exception.asm` and `Exception.HH` add a separate normalized 68-byte
exception frame. The native test handles actual #DE, #GP with selector error 0x18,
and #BP; it checks fault versus trap EIP, error codes, registers/segments/flags,
and resumes through a HolyC-edited saved EIP/EAX. The exception stubs have their
own instruction-audit range. The combined test and both x64 rebuild generations
pass. Stack-fault/double-fault recovery, NMI policy, debugger integration, and
HolyC exception unwinding remain unimplemented.

The compiler now lowers the existing `GetRFlags`/`SetRFlags` intrinsics to
PUSHFD/POPFD with eight-byte HolyC slots and 32-bit hardware values.
`Kernel/I386/Cpu.HC` provides interrupt save/disable and IF-only restore helpers.
The native test checks nested disabled/enabled restoration, high-half handling,
and DF read/write, and uses the intrinsic inside hardware IRQ callbacks. The
combined IRQ/exception test, 150-function regression corpus, and both x64 rebuild
generations pass. `HeapIrq.HC` now uses these helpers around the base allocator.
The guarded 8 KiB shared-heap test runs at least 256 foreground iterations with
at least 16 hardware PIT callbacks, each context owning and checking its own
payloads. Integrity, IF restoration, rejected requests, final accounting and
full-arena reuse pass, as does the standalone heap regression. All users of a
shared heap must serialize; raw boot allocator entry points remain available.
Task integration and reducing interrupt-disabled scan/zeroing latency are pending.

This is IRQ0/IRQ8 delivery in the QEMU 486/8 MiB runner, not a complete interrupt/time
subsystem. Keyboard input, full exception handling, scheduling,
calibrated time, production boot wiring and physical 386 validation remain pending.

## Cooperative context foundation

`Kernel/I386/Context.asm` saves/restores integer registers, selectors, EFLAGS and
ESP between live ring-0 stacks in one flat address space. `Context.HC` constructs
fresh stacks for a HolyC entry with one full-width argument and a nonreturning
exit path. Both calls require caller-owned state; switching requires IF clear.

`python3 tools/test-i386.py --tasks` passes with two heap-owned guarded 8 KiB
stacks, 64 yields per worker, checked local arrays and 64-bit accumulators,
same-context switching, rejected initialization, task return, and retirement from
the parent stack. Both stacks are freed and the full arena is reusable. Context
assembly and native HolyC code have separate instruction audits. Both x64
rebuild/reboot generations and the 718-file image verification also pass.

This is a context primitive plus a test scheduler, not the complete TempleOS
task system. Current-task/CPU descriptor bindings, public `Yield`,
public wait services, cancellation, debugger/exception state, and F64 state remain.
`Scheduler.HC` now adds a circular runnable queue, cooperative Yield, completion
without returning to the finished task, and explicit reaping before stack release.
The task test runs two additional 64-yield workers through this queue, checks
ordering and lifecycle rejection, retires/frees them, then repeats using the same
records. A root-only queue yields without switching and root completion is rejected.
The combined task test, both x64 rebuilds, and 720-file image verification pass.
The queue now supports Block/Wake: both workers leave the runnable queue,
root remains available, reversed wake order produces reversed resume order, and
duplicate/finished wakes and reaping blocked tasks are rejected. The same lifecycle
runs twice across record reuse and passes with both x64 rebuilds. The atomic
condition-check/block contract is documented to avoid missed IRQ wakeups.
The combined task runner now passes hardware IRQ wakeups: a PIT callback publishes
an event and inserts a blocked worker into the runnable queue without switching
inside the handler. A native worker completes 16 event waits using the masked
condition-check/block protocol, checks its 64-bit local and IF, and retires with
stack guards and heap accounting intact. The task boot stage is now 128 KiB to
hold the combined fixture; all four assembly regions are audited separately.
`Idle.asm` and `I386SchedIdle` now provide root-only interrupt-driven waiting.
Queue inspection stays under IF masking until STI/HLT; the primitive returns with
IF clear and the wrapper restores the original IF. The combined task test forces
an initial halt/wakeup, checks the runnable-work rejection path and both disabled
and enabled caller IF, then completes the 16 waits through an idle/yield loop.
The idle code is a fifth separate audit range. Task and IRQ suites, both x64
rebuilds, and 721-file image verification pass. Current-task bindings, public
TempleOS task semantics, and production boot/service-loop wiring remain pending.

The compiler now supports native `Fs()`/`Gs()` reads of the 32-bit self-address
pointer at segment offset zero. The i386 optimizer retains ordinary pointer-based
field accesses instead of the x64 MOV_FS/MOV_GS folding. A temporary GDT test uses
distinct FS/GS bases, checks self/pointer fields, reads/writes and 64-bit arithmetic,
then restores the original GDTR and selectors. The combined task test, 150-function
regression corpus, both x64 rebuilds and image verification pass. Descriptor setup
is test-only and separately audited.

Scheduler records now carry self-address pointers, and a one-time binding hook
runs with IF masked before Yield/Block/Finish switches. Native descriptor creation
and a small FS/GS reload routine bind the incoming task and one CPU record. Fresh
contexts accept the corresponding selectors. The combined fixture verifies Fs/Gs
identity in root, workers, the binding hook and timer IRQs, checks rejected binding
and descriptor arguments, then restores the original GDT. The task and IRQ tests,
both x64 rebuilds, and 723-file verification pass. Full CTask/CCPU migration,
production descriptor-slot management and public task APIs remain pending.

`Task.HC` now allocates a combined owned-task record and stack, prepares its
context and queues it. Normal entry return uses the native FS self-pointer to
finish the task; a separate task validates, reaps and frees the allocation.
The test checks two workers over repeated creation/retirement cycles, full-width
arguments and local state, rejected premature destruction and creation failures,
heap accounting, and full-arena reuse. The combined task suite, both x64 rebuilds
and 725-file verification pass. These are bootstrap try-allocation APIs; full
Spawn settings/inheritance, per-task heaps, public wait APIs, cleanup and OutMem behavior
remain to be integrated.

See the [context ABI and limits](i386-context.md).

## Test artifacts

- `build/rebuild-test/`: build ISOs, both exported generations, QEMU commands,
  debug logs, screenshots, and source/binary hash manifest.
- `build/i386-module-check/`: shared validator code, module fixture, disassembly,
  malformed-input corpus, runner log, and result JSON.
- `build/i386-loader-test/`: native loader image, disassembly, module packets,
  and allocated/caller-buffer loaded-code execution and lifetime results.
- `build/i386-data-test/`: linked code/data corpus, version-2 module fixtures,
  executable/data boundaries, disassembly, and target runner results.
- `build/i386-tasks-test/`: native workers, initializer, separately audited context
  assembly, runner, and execution result.
- `build/i386-irq-test/`: compiled PIC/PIT/RTC and callback code, audited assembly
  ranges, interrupt/exception runner, and execution result.
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

## Task completion joins

`I386SchedJoin` now registers a waiter before blocking, rechecks completion after
wakeups, and rejects self/root/foreign targets and join-dependency cycles. Finish
wakes registered joiners; reaping and owned-task destruction remain blocked until
those joiners resume and unregister. Root can observe an already completed target
but cannot block on an unfinished one.

The combined native task test passes with two joiners, an injected spurious wake,
cycle rejection, completed-target destruction rejection before joiners resume,
and final destruction of all three tasks with clean queue/heap accounting. Both
x64 rebuilds and image verification pass. Joins have no timeout/cancellation and
are not the full public TempleOS task-wait interface. A pointer-to-pointer unlink
expression was rejected by the current backend; the runtime uses a predecessor
walk for this list operation.

## Computed-pointer member access

The parser now preserves the emitted pointer type when an i386 arrow expression
uses a computed receiver. Previously `(ptr)->value` changed the preceding pointer
load into a structure load, which the backend rejected; the same issue affected
`&(*link)->next` during join implementation. Member lookup now uses the pointee
class without changing the already-emitted operand type. The change is guarded
for the i386 target.

A reproducer failed before the fix. Five new native cases cover parenthesized
pointers, pointer-to-pointer receivers, taking and writing a member address, array
members, and pointer-returning calls with full-width numeric values. All 155
function cases, the complete native task suite, both x64 rebuilds, and image
verification pass. The join implementation can keep its predecessor walk; the
original field-address expression is now independently supported and tested.

## Private task arenas

Owned-task creation now accepts an optional fixed-size private heap after the
stack, and the task record carries its allocator pointer. `I386TaskAlloc` and
`I386TaskFree` use the current FS-bound task and preserve IF. Stack-only tasks
retain the default zero-capacity behavior. Private allocations remain live after
Finish and are reclaimed together when the owned task is destroyed.

The combined task suite passes with two 4 KiB arenas, exhaustion/reuse, zero fill,
payload retention over yields and after completion, rejected cross-arena frees,
invalid arena sizes and complete parent-heap reclamation across repeated cycles.
Both x64 rebuilds and image verification pass. These remain fixed-capacity,
NULL-returning bootstrap heaps; page-pool growth, inherited policies, and public
MAlloc/CAlloc/OutMem integration are pending.

## Task cleanup hooks

The scheduler now supports one replaceable cleanup hook on the current worker.
Finish enters a distinct finishing state and invokes the hook before unlinking or
publishing completion. The hook runs on its task stack with FS/private memory and
incoming IF available, may yield, and cannot recursively finish or replace itself.
Only after return are completion and join wakeups published.

The native test allocates private scratch memory during cleanup, yields with IF
enabled, checks preserved data/IF, and verifies that root cannot destroy the task
while cleanup is suspended. Hook install/clear/reinstall and recursive-operation
rejection pass across repeated task creation. The full task suite, both x64
rebuilds and image verification pass. Hook faults, cancellation and exception-safe
unwinding remain pending.

## Keyboard-controller transport and IRQ1

Native 8042 transport now provides bounded writes, raw status/data reads,
polling reads and boot-only draining. Reads preserve auxiliary/error status for
the caller; invalid arguments and unsuccessful reads leave outputs unchanged.
Complete transactions require exclusive controller ownership with IF clear.

The IRQ suite passes four keyboard echo exchanges through actual IRQ1 delivery,
including frame/register/flag restoration, controller configuration restoration,
invalid arguments and empty-buffer polling. Existing PIT, RTC, exception and
shared-heap interrupt phases pass in the same runner. Both x64 rebuilds pass;
image verification covers 727 files and 62 directories. This is a QEMU 486/8 MiB
transport checkpoint, not keyboard initialization or interactive input. Scan-code
decoding, input queues, task wakeups and physical vintage hardware checks remain.

## IRQ-to-foreground input queue

A fixed 64-entry FIFO retains raw keyboard-controller byte/status pairs. All
operations preserve IF and serialize one CPU's IRQ producer and foreground
consumer. Overflow drops the newest input and records a saturating loss count;
empty and invalid reads preserve outputs and pending input.

The native IRQ test passes fill, wraparound, ordered drain, status retention,
overflow/saturation, invalid arguments and IF restoration. Four actual IRQ1 echo
responses now pass through the queue. The enlarged fixture exceeded the previous
64 KiB loader capacity, so it uses the existing 128 KiB transfer option, ending
at 0x30000 below the test heap and stack. The full IRQ fixture and instruction
audit pass; both x64 rebuilds and image verification (729 files, 62 directories)
pass. Blocking input, scan-code decoding and scheduler wakeups remain pending.

## Blocking keyboard input and task wakeup

The raw input interface now associates a FIFO with a scheduler and one pending
reader. Queue check, waiter registration and blocking occur with IF masked;
resumption rechecks the predicate. IRQ publication wakes the reader without
switching the interrupted task. Other tasks cannot consume its reserved input.

The separate `--input` native fixture passes queued/nonblocking reads, invalid
arguments, competing readers, spurious wake/reblock and four actual IRQ1 keyboard
echo replies waking a blocked worker from root idle. Extra bytes published while
the worker is already runnable remain ordered. IF restoration, task completion,
reaping and controller restoration pass. Both x64 rebuilds and image verification
(731 files, 62 directories) pass. Tests use QEMU 486/8 MiB; scan-code decoding,
keyboard initialization, cancellation/close and interactive shell input remain.

## Native scan-set-1 packet decoder

The raw decoder now preserves TempleOS's physical E0/release bit conventions,
recognizes complete Pause packets and suppresses Print Screen's fake Shift bytes.
It retains keyboard prefix state across auxiliary traffic, rejects corrupt or
malformed packets, ignores command acknowledgements and exposes an explicit reset
for stream discontinuities. It assumes scan set 1 has already been established.

The native input suite passes synthetic ordinary/extended make-release coverage,
special sequences, auxiliary interleaving, invalid arguments and error recovery;
the existing real IRQ1 worker-wakeup phase still passes. Both x64 rebuilds and
image verification (733 files, 62 directories) pass. Decoder evidence is synthetic
on the QEMU 486/8 MiB runner. Modifier/lock semantics, character mapping, real key
injection, keyboard configuration and integration into the input consumer remain.

## Character compatibility and native string literals

Native character conversion now matches the existing x64 ScanCode2Char function
for all 32,768 combinations of the low scan/flag bits, including Ctrl precedence
and TempleOS's Shift/Caps punctuation behavior. The fixture compares against
results generated by the running x64 OS and repeats with the high word set.
Modifier tracking, keypad mapping and message dispatch remain pending.

Compiling the character tables exposed missing IC_STR_CONST support. The backend
now places literals after each function body, records them as module data and
materializes their addresses relative to the current PC. Empty strings, embedded
NULs and returned string pointers pass native checks. The full input fixture,
155 compiler cases, both x64 rebuilds and image verification (735 files,
62 directories) pass. Global/static address initializers and full self-hosting
remain pending; this is still a QEMU 486/8 MiB development checkpoint.

## Explicit keyboard configuration

Boot setup now disables scanning, explicitly selects scan set 2, re-enables
scanning and enables controller translation/IRQ1 with the auxiliary path disabled.
A bounded command helper requires ACK and retries RESEND up to three attempts.
The contract requires exclusive, quiescent boot ownership; failures can leave
partial device state and do not claim transactional rollback.

The native input fixture passes command-byte checks and a translated scan-set
query, invalid budgets/attempt counts, exhausted RESEND handling, unexpected
reply rejection and recovery with a successful command. All four subsequent
IRQ1 worker-wakeup exchanges, decoder cases and 65,536 character comparisons
pass. Both x64 rebuilds and image verification (737 files, 62 directories) pass.
Live key injection, modifier tracking, concurrent runtime command routing and
physical AT/386 checks remain pending.

## Live emulated-keyboard input

The native input fixture now consumes QMP-injected A, Enter, Up, Print Screen
and Pause events through the keyboard device, IRQ1, the input queue and a blocked
worker. All nine decoded make/release events and A/Enter character conversions
pass. The host validates each guest request and the final runner exit, and records
its QMP key sequence. Synthetic scan tests and the character oracle still pass.

An initial compile stalled because fixture debug-port writes preceded their
port declarations; the captured debugger screen identified that site, and adding
the header fixed compilation. The completed native run and instruction audit
pass. This checkpoint changes test tools/fixtures and documentation only; kernel
and compiler sources retain the previous verified rebuild. Modifier tracking,
public input messages and physical 386/controller validation remain pending.

## Modifier state and TempleOS scan pairs

A native state layer now applies the original normal/Num Lock maps and emits
TempleOS's I64 mapped/raw scan pair. Physical left/right modifiers remain
independent, locks toggle on matched releases and held keys retain their mapped
identity across lock changes. Insert/Delete flags and Pause impulse behavior are
also covered. LED commands, public message dispatch and loss recovery remain.

All 512 mapping entries match the original declarations compiled by the x64 test
host. Native state tests cover paired modifiers, repeats, lock transitions,
held-key identity and invalid input; live QMP keys pass through the new layer.
The character reference is now compact, with its compression checked against
all original 32,768 inputs before the native 65,536 comparisons run. A Num Lock
failure exposed truncation when passing the flag mask to one-byte Bool; an explicit
zero comparison fixes it. The full input suite, instruction audit, both x64
rebuilds and image verification (739 files, 62 directories) pass.

## Reusable keyboard-event interface

Packet decoding, key state and character conversion now compose into a native
interface returning TempleOS key-down/up message types, characters and full scan
pairs. It consumes internal NEW_KEY flags, suppresses repeated modifier makes
and resets both state machines on corrupt keyboard input while preserving the
output on non-event returns.

The live QMP worker now uses this interface directly. Synthetic shifted press/
release, Ctrl-C, suppression, invalid arguments and error-reset checks also pass,
along with the existing mapping and character references. The full input suite,
instruction audit, both x64 rebuilds and image verification (741 files,
62 directories) pass. TaskMsg/focus routing, LED updates and queue-loss/client
state reconciliation remain pending.

## Native task-to-task message transport

A bounded native queue now carries message types and two full-width I64 arguments.
Sends reject full queues, reads discard types outside their mask and may block,
and close preserves queued data while waking the reader to drain/finish. All
queue operations preserve IF; only one reader may be pending.

The new `--messages` fixture passes capacity/wraparound, payload retention,
mask/type-63 handling, invalid arguments and close/drain checks. A keyboard broker
receives live QMP events and sends all nine decoded messages to a second blocked
worker. Spurious wake/reblock and empty-queue close wakeup pass, followed by both
workers finishing and being reaped. The native test, instruction audit, both x64
rebuilds and image verification (743 files, 62 directories) pass. Full CTask/CJob
ownership, public message wrappers and focus/popup routing remain pending; see
`docs/i386-messages.md` for the transport contract.

## Task inbox association and retirement

Native task records now hold an optional inbox association. Task-addressed sends
reject finished recipients, attached queues enforce recipient-only reads, and
reaping/owned destruction is blocked until the inbox is closed and detached.
A recipient may detach its own closed inbox; external cleanup requires completion.
Detach discards remaining messages and clears both references.

The live keyboard broker/consumer fixture passes task-addressed delivery,
recipient isolation, duplicate/early-operation rejection and retirement gating.
A worker returning with unread messages rejects further sends and can be cleaned
up externally before reaping. The full task suite, both x64 rebuilds and image
verification (743 files, 62 directories) pass. Automatic inbox allocation, full
public task/job integration and focus routing remain pending.

## Heap-owned native inboxes

Inbox allocation now obtains a queue from a caller-supplied native heap and
attaches it to a live task, with no association left behind on failure. The
matching cleanup helper validates ownership, closes/detaches, discards unread
messages and returns the allocation to its original heap. Live foreign cleanup
is rejected without closing the queue.

The message fixture passes exhaustion, duplicate allocation, rejected premature
cleanup and full arena reclamation after completion across repeated cycles.
A recipient also frees its own inbox with IF enabled before returning. The full
message/QMP suite, instruction audit, both x64 rebuilds and image verification
(745 files, 62 directories) pass. Automatic Spawn policy, full public task/job
integration and focus routing remain pending.

## Native keyboard focus routing

The scheduler now retains one focus recipient. Selection requires a live task
with an open attached inbox; invalid changes preserve the previous target.
Focus-based sends select and publish under one interrupt mask. Reaping rejects
the selected task even after inbox detach, so routing cannot retain a freed task.
Focus must be moved or cleared explicitly after completion.

The message fixture checks root/consumer switching, absent and invalid targets,
recipient isolation, live keyboard delivery through focus and retirement gating.
The full task suite, both x64 rebuilds and image verification (747 files,
62 directories) pass. Window activation, popup/parent focus selection, focus
notifications and release ownership across focus changes remain pending.

## Overflow-aware keyboard event reads

A reusable blocking reader now checks raw loss accounting before and after a
potentially suspended input read. Changed loss counts discard ambiguous backlog,
reset packet/key state and return an explicit discontinuity without overwriting
the event output. Saturation requires coordinated queue reset rather than silently
accepting further unobservable losses.

Native tests drop a Shift release while an E0 prefix is pending, verify state
reset and backlog disposal, then receive unshifted input. Counter saturation/
reset, invalid arguments and IF restoration pass. All nine live QMP events also
pass through the new reader. The full input suite, instruction audit, both x64
rebuilds and image verification (749 files, 62 directories) pass. Notification and
reconciliation of key state already delivered to message clients remain pending.

## Native ATA sector reads

The port now identifies compatibility-port ATA disks and reads single LBA28
sectors with 16-bit PIO. Operations use bounded polling and leave device IRQs
disabled under exclusive boot ownership. Sector data is staged until successful
completion, preserving the destination on failure.

The new native ATA fixture passes capacity discovery, boot-signature and distinct
pattern reads, the final sector, repeated reads, argument rejection, guard checks,
a real out-of-range device error and recovery, plus absent-device probing. The
instruction audit, both x64 rebuilds and image verification (751 files,
62 directories) pass. CHS-only drives, writes, reset/recovery service, block/filesystem
integration and physical vintage hardware validation remain pending.

## Native ATA CHS addressing

IDENTIFY decoding now selects valid current translation or default CHS geometry,
checks register limits and derives capacity for devices without LBA. Reads convert
logical sector numbers to ATA cylinder/head/sector registers when LBA is absent,
while retaining the existing bounded PIO and output-preservation contract.

Synthetic records pass geometry/capacity and malformed-response checks. Clearing
LBA support in the emulated disk profile exercises CHS commands against seeded
sectors across head/cylinder boundaries and the final CHS sector, with invalid
geometry/range rejection and unchanged failure outputs. The native ATA suite,
instruction audit, both x64 rebuilds and image verification (751 files,
62 directories) pass. This is evidence for CHS command
execution on QEMU, not a physical CHS-only drive. Firmware-dependent parameter
initialization, writes, recovery and filesystem integration remain pending.

## Native ATA sector writes

The shared LBA28/CHS transfer path now supports WRITE SECTORS through 16-bit PIO,
with staged input, bounded DRQ/completion waits and unchanged source buffers.
Failure may have altered media; success is command completion and does not yet
include a cache flush or power-loss guarantee.

Native tests pass LBA and forced-CHS writes, overwrite/readback, final-sector
access, invalid arguments/geometry, guards, and a real out-of-range write error
followed by successful writes. The host compares the entire 16 MiB image after
QEMU exits and finds exactly the three intended sector replacements. The ATA
suite, instruction audit, both x64 rebuilds and image verification (751 files,
62 directories) pass. Cache policy/flush, task
ownership, block/filesystem integration and physical IDE validation remain.

## Explicit native ATA cache flush

IDENTIFY now records FLUSH CACHE support only when word 83's validity bits and
command capability agree. The explicit flush API rejects unsupported profiles,
selects the drive and waits for successful non-data E7 completion under the
existing boot ownership/poll bounds. It does not change cache policy or silently
claim durability for legacy devices lacking capability reporting.

Synthetic capability records and rejected invalid/unsupported calls pass. Four
native write/flush/read sequences and a repeated final flush pass; QEMU's command
trace independently confirms the exact command ordering. The full backing-image
comparison, ATA instruction audit, both x64 rebuilds and image verification
(751 files, 62 directories) pass. Legacy cache policy,
fault-injected flush recovery, physical durability and filesystem integration
remain pending.

## Native RedSea volume and file reads

The native filesystem path now mounts RedSea volumes through ATA, validates boot
and root metadata, streams directory lookup and reads bounded raw file ranges.
It preserves the existing 64-byte directory format and 64-bit block/size/date
fields, validates extents and 32-bit destinations, and avoids whole-directory or
whole-file allocation. Mount/lookup failures preserve output records; reads
report partial progress on a later disk error.

The native fixture passes a directory spanning two sectors, deleted-entry skip,
nested HolyC source, empty files, unaligned/EOF reads, full-width timestamps,
malformed metadata/extents and unchanged failed outputs. Overstated disk/volume
bounds force a real second-sector read error and verify partial reporting.
The complete backing image remains unchanged. The RedSea suite, executable-region
instruction audit, both x64 rebuilds and image verification (753 files,
62 directories) pass. Public file APIs, decompression,
filesystem writes, module loading from files and physical hardware remain pending.

## Native RedSea fixed-extent writes

Raw file updates now validate the entire range against the existing extent and
reject read-only/directory/deleted/resident entries. Partial sectors use read–
modify–write while whole sectors avoid the preliminary read. Sources remain
unchanged; completion counts include only confirmed sectors, with failed-sector
contents explicitly uncertain. Flushing remains a caller operation, and file
size, timestamps and allocation metadata are not changed by this low-level API.

The native write fixture passes overlapping unaligned/aligned updates, EOF
padding preservation, flush/readback, invalid range/attribute checks and real
partial/zero-progress device errors. A complete disk-image comparison verifies
exactly the requested byte changes plus the confirmed sector of the fault test.
The instruction audit, both x64 rebuilds and image verification (754 files,
62 directories) pass. Allocation/directory mutation,
public file semantics and physical storage validation remain pending.

## Native RedSea bitmap allocation

Contiguous allocation now scans bitmap sectors for a sufficient free run and
reserves it on disk. Release preflights the complete range, rejects already-free
bits and protected root/metadata extents, then updates the bitmap. Both use the
existing RedSea data-area bit numbering. Bitmap I/O failure invalidates the mounted
view; recovery of partially written bitmap state is explicitly not automatic.
These low-level helpers assume a consistent bitmap and exclusive caller ownership.

The native allocation fixture passes bitmap-sector boundary changes, fragmentation,
mixed-range/double-free rejection, full exhaustion and reclamation. It preserves
reserved and out-of-volume tail bits, and forces a real bitmap-read failure to
verify invalidation. After release and flush the entire disk image equals its
starting contents. The instruction audit, both x64 rebuilds and image verification
(755 files, 62 directories) pass. Directory
publication/removal, allocation policy in public file APIs, interrupted-update
recovery and physical storage validation remain pending.

## Native RedSea file creation

Raw file creation now connects contiguous allocation, file data writes and
directory publication. It reuses deleted slots, preserves append terminators
across sector boundaries, rejects duplicate/full/read-only/invalid requests and
creates empty files without a data extent. Data/allocation are flushed before
publication; the entry is then flushed. I/O failure after reservation invalidates
the mounted view and may require orphan/uncertain-entry recovery.

The native fixture creates a 700-byte binary file, HolyC source and an empty file,
then remounts and reads them back with exact timestamps. The host checks the
complete image's data, bitmap, directory and unchanged surrounding bytes; QEMU's
trace confirms the expected write/flush ordering. The instruction audit, both
x64 rebuilds and image verification (756 files, 62 directories) pass. The combined fixture uses the existing 128 KiB stage and remains
below the runner stack. Legacy cache policy, deletion/replacement, directory growth,
public file APIs, interrupted-update recovery and physical validation remain.

## Native RedSea deletion and reuse

Regular-file deletion now flushes a directory tombstone before releasing and
flushing its extent. It rejects directories/read-only targets, reports absent
names separately, and removes empty files without a bitmap operation. Data is
not erased. Failure after mutation invalidates the mounted view and can require
orphan/uncertain-entry recovery; public handle lifetime tracking remains pending.

The native fixture creates/removes a multi-sector file, verifies exact bitmap
reclamation and residual data, and creates HolyC source in the reclaimed extent
and slot. Empty/duplicate/invalid/read-only cases and remount/readback pass.
Whole-image comparison verifies expected bytes and QEMU traces confirm ordering.
The instruction audit, both x64 rebuilds and image verification (757 files,
62 directories) pass. Replacement, directory growth,
public file APIs, interrupted-delete recovery and physical validation remain.

## Native RedSea file replacement

Raw replacement now retains the existing name/attributes while writing a new
extent, flushing its data, publishing/flushing the updated entry and finally
reclaiming/flushing old storage. Empty replacement releases the old extent after
publishing block/size zero. No-space failure preserves the old file; I/O failures
invalidate the view and require explicit recovery of uncertain/orphan state.

Native tests pass growth, truncation to empty, a subsequent HolyC-source save,
64-bit timestamps, preserved attributes, intermediate bitmap states and remount
readback. A separate full volume preserves its old file when replacement cannot
allocate. Whole-image and command-trace checks confirm expected bytes and ordering.
The creation regression, instruction audits, both x64 rebuilds and image
verification (758 files, 62 directories) also pass.
Directory growth, public file APIs, legacy cache policy, interrupted replacement
recovery and physical validation remain pending.

## Native modules loaded from disk

A RedSea-to-module bridge now reads a complete uncompressed module file into a
temporary heap allocation and passes it through the existing target/ABI validator
and native loader. It returns an independent executable image and releases the
file copy. Incomplete reads, invalid modules and allocation failures return zero
with temporary storage reclaimed; invocation/unloading remain caller-owned.

A freshly cross-compiled file with mutable 64-bit global data executes after
loading from RedSea, including after the exact reclaimed file-buffer allocation
is overwritten. Repeated load/free resets module data and reclaims the heap.
Wrong pointer width, truncation, small/compressed files, missing entry symbols,
both exhaustion stages and a real partial disk read pass rejection/cleanup checks.
The payload and loader code pass instruction audits; the backing disk remains
unchanged. Both x64 rebuilds and image verification (760 files, 62 directories)
pass. Multi-file dependencies, resident symbols,
registry/lifetime policy and production boot/JIT integration remain pending.

## Native module sets loaded from disk

The disk bridge now accepts an explicit file-entry array, validates all extents,
reads the files into temporary allocations and links one combined executable
image. Cross-file function/data imports use the existing shared resolver. Temporary
tables and every file buffer are reclaimed on success and failure; the one-file
path retains its original allocation behavior.

Native consumer/provider tests pass both file orders, mutable 64-bit imports,
exact reclaimed-buffer overwrite and complete heap reclamation. Missing/duplicate
providers, malformed dependencies, missing entry symbols, all four allocation
stages and a real second-file read error pass rejection/cleanup checks. The direct
linked payload and runtime pass instruction audits; the disk remains unchanged.
The single-file regression, both x64 rebuilds and image verification (760 files,
62 directories) pass. Automatic dependency search,
resident kernel symbols, registry/lifetime policy and production boot/JIT remain.

## Explicit resident module bindings

The shared loader now accepts typed resident function/data addresses alongside
module exports. Names must resolve uniquely, direct calls require function kinds,
and binding metadata/target overlap is rejected before image writes. Native
relative patches use the final image address. Heap and disk-loading bound APIs
are available, while existing APIs delegate with no bindings and retain their ABI.

Native tests call resident code and share mutable 64-bit data, including after
binding addresses are cleared. They reject invalid, missing, duplicate, wrong-kind
and conflicting definitions, protect output on rejection and check high-address
relative arithmetic without executing the synthetic address. The shared-loader
23-case corpus, 16-case data corpus, both disk-loader regressions, instruction
audits, both x64 rebuilds and image verification (761 files, 62 directories) pass.
Production kernel export discovery, provider pinning/unloading policy and boot/JIT
integration remain pending.


## Software binary64 addition and subtraction

The initial software F64 runtime now implements addition/subtraction on binary64
bit patterns through the native integer ABI. It uses integer operations only,
with nearest-even rounding, gradual underflow, signed zeros, infinities and an
explicit first-NaN quieting/payload policy. It is not yet connected to native
HolyC F64 expression lowering; other arithmetic, comparisons, conversions,
formatting, math functions and exception/rounding state remain pending.

The native fixture passes 2,048 operand pairs (4,096 bit-for-bit add/subtract
checks), including boundary cross-products, alignment/halfway cases, cancellation
and seeded random inputs. Expected finite results come from host binary64
arithmetic; NaN policy has explicit expected bits. Generated functions pass the
386 instruction audit, and CR0.EM is set to trap x87 use during execution.
Both x64 rebuild generations and image verification (763 files, 62 directories)
pass. This remains a QEMU 486/8 MiB development check, not real-386 validation or
full HolyC floating-point compatibility. See `docs/i386-soft-f64.md`.


## Software binary64 multiplication

`I386F64Mul` now multiplies binary64 bit patterns without a coprocessor. It
normalizes nonzero subnormals, computes the exact 106-bit significand product
with integer limbs, and shares nearest-even rounding/packing with addition and
subtraction. Underflow retains sticky information, including rounding to signed
zero; zero times infinity returns the documented canonical quiet NaN.

The expanded native fixture passes 2,048 operand pairs across all three operations
(6,144 bit comparisons), including product halfway cases, underflow/overflow,
operand reversal and signed special values. Addition/subtraction pass again after
the shared-rounding refactor. Generated-function instruction audits, execution
with CR0.EM set, both x64 rebuild generations and image verification (763 files,
62 directories) pass. Division, conversions and native F64 expression lowering
remain pending; this is still runtime groundwork for the complete port.


## Software binary64 division

`I386F64Div` now divides binary64 bit patterns with integer shift/subtract long
division. It normalizes subnormal operands, retains 56 quotient bits and uses the
remaining nonzero remainder as sticky information for nearest-even rounding.
Signed zero/infinity and invalid zero/zero or infinity/infinity cases follow the
documented runtime policy; floating-point exception flags remain pending.

All four arithmetic helpers pass the expanded native fixture: 2,048 operand pairs,
8,192 result comparisons against host binary64 arithmetic and explicit special
value expectations. This includes repeating quotients, subnormal rounding, zero
divisors and signed infinities. The fixture passes generated-function instruction
audits and execution with CR0.EM set. Both x64 rebuilds and image verification
(763 files, 62 directories) pass. Conversions, comparisons, native F64 compiler
lowering and the rest of the full port remain unfinished.


## Software integer-to-binary64 conversion

`I386F64FromU64` and `I386F64FromI64` now convert full-width integers to binary64
bit patterns with nearest-even rounding. Normalization preserves sticky bits;
unsigned magnitude subtraction handles `I64_MIN` without signed overflow.
`U64_MAX` correctly rounds to 2^64 under this helper contract.

A separate native fixture passes 1,024 input bit patterns interpreted as both
signed and unsigned integers (2,048 result checks against host conversions).
Power-of-two boundaries, signed extrema, both retained-significand parities at
halfway rounding, neighboring values and seeded random inputs are covered.
The 8,192-check arithmetic regression also passes. Both fixtures pass instruction
audits and execute with CR0.EM set; both x64 rebuild generations and image
verification (763 files, 62 directories) pass. Mapping helpers to HolyC conversion
nodes still needs x64 compatibility tests. Reverse conversions, comparisons and
native F64 compiler integration remain unfinished.


## Software binary64 comparison

`I386F64Compare` now returns less/equal/greater/unordered through the integer ABI.
It treats both signed zeros as equal, orders negative values numerically and
returns unordered for either quiet or signaling NaNs without raising flags.
The documented result contract explicitly distinguishes greater from unordered,
so future relational lowering can avoid treating NaNs as greater values.

The native fixture passes 1,024 operand pairs against host ordering and NaN
classification, plus reversed operands (2,048 comparisons). Special values,
subnormal/normal boundaries, adjacent representations and seeded random pairs
are covered. The 8,192-check arithmetic regression, instruction audits, execution
with CR0.EM set, both x64 rebuilds and image verification (763 files, 62
directories) pass. This helper still needs native HolyC relational-operator
integration and x64 compatibility checks; F64-to-integer conversion also remains.


## Software binary64-to-I64 conversion with x64 evidence

`I386F64ToI64` now truncates binary64 values toward zero using integer operations.
NaNs, infinities and out-of-range values return the integer-indefinite bit pattern
used by masked x64 `FISTTP`; exactly -2^63 correctly has that same result pattern.
The runtime does not yet track floating-point invalid/inexact flags.

A 1,024-input fixture executes the original x64 HolyC `ToI64` and compares its
exported results to independent host truncation/range checks. Native results then
match those same expectations with CR0.EM set. Inputs cover both signs around
powers of two through the signed boundary, subnormals, signed zeros, infinities,
quiet/signaling NaNs and deterministic random values. The 8,192-check arithmetic
regression, instruction audits, both x64 rebuilds and image verification (763
files, 62 directories) pass. Native compiler lowering, unsigned-output semantics
and floating-point exception-state compatibility remain pending.


## Initial native HolyC F64 expressions

The i386 backend now compiles same-type F64 addition, subtraction, multiplication
and division into calls to the software runtime. F64 bits pass through eight-byte
argument/evaluation slots and EDX:EAX returns, with four-byte pointers. Literals,
local/global and pointer storage, bitwise casts, unary sign changes and
fixed-arity direct/indirect F64 calls are supported. Runtime ABI validation follows
HolyC union forwarding to primitive types; forward and direct helper references
use the existing relative module fixups. Direct helper definitions must precede
the caller in the current module's address range.

The native fixture passes 12 positive checks, including nested/indirect calls,
zero/NaN sign changes and both helper-reference paths. Eight negative compilation
checks reject missing/wrong runtime declarations and currently unsupported F64
operations. Execution with CR0.EM set and generated-function instruction audits
pass, along with all 155 integer/call cases, the 8,192-result arithmetic corpus,
both x64 rebuild generations and image verification (763 files, 62 directories).
Mixed conversions, comparisons, F64 conditions, compound assignment, remainder,
math operations and floating-point state remain pending; the full port is not
complete. See `docs/i386-f64-backend.md`.


## Native HolyC F64 relational operators

All six same-type F64 relations now call the software comparator and produce
integer zero/one results. NaNs make inequality true and every ordered/equality
relation false; signed zeros compare equal. The backend uses actual expression
result types rather than the operand-precision metadata retained on comparison
nodes, allowing their boolean results to drive branches and integer arithmetic.

The expanded native corpus checks 1,024 pairs in both orders: 12,288 branch
predicates, plus all six relations used in integer arithmetic and division of a
boolean result. The 2,048 direct-runtime comparisons still pass. The compiled
F64 fixture and its eight strengthened rejection cases, all 155 integer/call
cases, instruction audits, execution with CR0.EM set, both x64 rebuilds and image
verification (763 files, 62 directories) pass. Mixed conversions/relations, raw
F64 conditions, floating-point state and complete native compiler/OS integration
remain unfinished; x64 relational exception/NaN compatibility is not yet proven.


## Native F64 compound updates and increment/decrement

The backend now lowers same-type F64 `+=`, `-=`, `*=` and `/=` through the
software runtime while preserving the destination address across calls. Prefix
and postfix increment/decrement use binary64 1.0; postfix keeps the original
value in callee-preserved registers, while prefix returns the stored result.

The native F64 fixture now passes 27 positive checks and eight unsupported-source
checks. New cases cover all update forms, returned expression values, counted
pointer-producing destinations, original signed-zero/signaling-NaN postfix bits
and nearest-even increments at 2^53. The 155-case integer/call regression,
instruction audits, CR0.EM execution, both x64 rebuilds and image verification
(763 files, 62 directories) pass. Mixed conversions/updates, raw F64 conditions,
remaining math operations and complete native compiler/OS integration remain.


## Native explicit F64 conversion intrinsics

`ToF64` and `ToI64` now call one-argument software helpers through the native
integer ABI. Standalone declarations live in `Kernel/I386/Float.HH`. `ToF64`
retains the original I64 parameter interpretation, including U64 argument bit
patterns; true unsigned conversion remains a separate runtime helper. Intrinsic
call tracking handles nested calls, and existing optimizer rules preserve
already-integer/already-F64 inputs without a lossy intermediate conversion.

The conversion fixtures pass 5,120 native result checks: 3,072 integer-to-F64
checks and 2,048 F64-to-I64 checks. Actual x64 ToF64 results match signed conversion
at eight selected boundaries; the existing 1,024-input x64 ToI64 oracle still
matches. The main F64 fixture passes 31 positive/eight rejection checks, including
nested/no-op conversions. The 155-case integer regression, expanded comparison
corpus, instruction audits, CR0.EM execution, both x64 rebuilds and image
verification (764 files, 62 directories) pass. Implicit mixed conversions,
floating-point state and complete native compiler/OS integration remain pending.


## Native implicit integer/F64 conversions

The backend now applies producer conversion flags through the software runtime
and handles function return-type conversion before ABI normalization. Effective
operand types include those conversions, enabling mixed arithmetic/relations,
assignments, arguments, returns and integer operands in F64 compound updates.
A second type pass refreshes links after optimizer rewrites; logical results are
integer booleans, including when later converted to F64 on short-circuit paths.

All 49 positive F64 fixture checks and eight rejection checks pass, including
mixed operand order, signed U64 interpretation, call/return coercion and converted
comparison/logical results. The 155-case integer regression, expanded comparison
corpus, 5,120 native conversion checks with x64 evidence, instruction audits,
CR0.EM execution, both x64 rebuilds and image verification (764 files, 62
directories) pass. Integer-destination compound updates with F64 operands, raw
F64 conditions, chained comparisons, remaining math/formatting and complete
native compiler/OS integration remain unfinished.


## Integer-destination compound updates with F64 operands

Native `+=`, `-=`, `*=` and `/=` now convert the loaded integer to F64, perform
software arithmetic, truncate to I64 and normalize to the destination width.
The destination is evaluated once and retained across helper calls; the expression
returns the stored result. U64 preserves x64 HolyC's signed interpretation.

All 61 positive F64 checks and eight rejection checks pass with CR0.EM set and
generated-instruction auditing. The added cases cover negative truncation, narrow
overflow, U64 bits, counted pointer destinations and NaN-to-integer conversion.
Eight x64 checks agree for wide integers and addressed narrow storage. Register-held
x64 narrow locals retain out-of-range values in the observed overflow cases; the
native backend normalizes stored locals. This difference is recorded explicitly
in `docs/i386-f64-backend.md`.

The 155-case integer/call regression, both x64 rebuild generations and image
verification (764 files, 62 directories) pass. Raw F64 conditions, chained
comparisons, remaining arithmetic/formatting/math, floating-point state and the
full native compiler/OS remain unfinished.


## Native F64 conditions and logical evaluation contexts

Raw F64 conditions and logical operators now use the full 64-bit truth test:
positive zero is false, while negative zero, subnormals, infinities and NaNs are
true. Actual x64 execution confirms this behavior. The i386 backend also now
matches HolyC's evaluation distinction: logical operators directly controlling
branches short-circuit, including nested negation/AND/OR; value expressions
evaluate both operands. The former implementation short-circuited all contexts.
Integer regressions now check eager side effects and retain fault-skipping tests
in branch conditions.

A shared x64/native fixture passes 144 operand pairs, checking five branch
predicates, four arithmetic Boolean values and six evaluation-count cases per
pair. Twelve cases additionally cover while, for and do/while loops. The main
F64 fixture passes 62 checks and eight unsupported-source rejections. The x64
uncast `!F64` arithmetic metadata quirk remains explicit: `(!a)+2` with positive
zero returns 2 on x64, while the native integer Boolean returns 3. Shared arithmetic
checks bitcast the negation result to I64; native behavior is checked separately.
See `docs/i386-f64-backend.md` for the compatibility boundary.

All 155 integer/call cases, the expanded software comparison corpus and the
RedSea-to-resident-binding integration test pass, along with generated-instruction
audits, F64 execution with CR0.EM set, both x64 rebuild generations and image
verification (764 files, 62 directories). Chained comparisons, remaining numerical
operations/formatting, floating-point state, full kernel integration and native
self-hosting remain unfinished. QEMU 486 runner success does not prove strict
386 compatibility or a complete native OS.


## Native chained comparisons

The backend now retains each middle operand in a dedicated eight-byte frame
slot before emitting its comparison. `IC_PUSH_CMP` reloads that value for the
next pair, without re-evaluating its source or exposing hidden stack entries to
short-circuit branches. Comparison results are integer booleans independently
of their retained operand-precision metadata. Nested chains use separate slots;
normal call-frame isolation protects retained values across calls and recursion.

The native fixture passes 512 triples across signed four-operand chains,
unsigned chains, F64 and both mixed-type middle-operand arrangements. It checks
pairwise numerical equivalence and eager/short-circuit evaluation counts. Nine
additional integer cases cover nested chains, constants, equality/inequality,
descending relations, arithmetic use and a function-produced middle operand;
all 164 integer/call cases pass. Existing 62 F64 checks, 144 condition pairs,
12 loop cases, eight rejection cases and the software comparison corpus pass.

Actual x64 checks agree for the covered integer/unsigned cases, evaluation counts,
F64 value chains and mixed chains with F64 middle operands. The test records and
checks 29 NaN-leading F64 branch differences and 130 mixed-integer-middle
result differences in its 512-triple corpus. Native chains must match separate
numeric comparisons throughout; full compatibility with these x64 quirks remains
unresolved. See `docs/i386-f64-backend.md` for the precise boundary and example.

Generated-instruction audits, CR0.EM execution, both x64 rebuild generations and
image verification (764 files, 62 directories) pass. Remaining numerical/math/
formatting support, full production compiler and kernel integration, native
self-hosting, memory targets and strict 386 validation remain unfinished.


## Native ToBool intrinsic

`ToBool` now normalizes all 64 bits of its I64 argument to zero or one and
returns through the existing Bool ABI. The standalone declaration is in
`Kernel/I386/Bool.HH`. Native tests cover high-word/high-byte-only values,
negative values, nested calls, side-effecting arguments, Bool storage, pointers
and constant expressions. All 178 integer/call cases pass.

The F64-to-integer corpus now runs 4,096 native checks over 1,024 inputs:
direct and compiled ToI64, ToBool after numeric F64 argument conversion, and
ToBool on the original U64 pattern. The host validates 2,048 actual x64 Boolean
outputs against independent numeric/raw-bit expectations. The shared optimizer's
constant-folding distinction is preserved: literal -0.0 and +/-0.5 yield true,
while the corresponding variable F64 arguments truncate to integer zero and
yield false. Four x64 constant checks and the native constant-expression case
verify this behavior; see `docs/i386-f64-backend.md`.

Generated-instruction audits, CR0.EM execution, both x64 rebuild generations and
image verification (765 files, 62 directories) pass. Remaining numerical/math/
formatting support, full compiler/kernel integration, native self-hosting,
memory targets and strict 386 validation remain unfinished.


## Native integer math intrinsics

The function backend now implements AbsI64, SignI64, signed/unsigned Min/Max and
SqrI64/SqrU64. Standalone declarations are in `Kernel/I386/Math.HH`. The lowering
uses register pairs and existing 386 arithmetic/comparison emission; min/max
select with branches. It preserves x64 MIN_I64 absolute-value overflow and
low-64-bit square results. These operations are used by existing message,
memory and mouse code, whose full native integration remains pending.

`tools/test-i386.py --integer-math` checks 8,192 results over 1,024 operand pairs
from 32 boundary/bit-pattern values. Actual x64 intrinsic results must match the
independent Python integer oracle before the native module executes. Three
additional checks cover nested calls and single evaluation of side-effecting
arguments. All cases and generated-instruction audits pass in the 8 MiB QEMU 486
runner. The 178-case integer regression, both x64 rebuild generations and image
verification (766 files, 62 directories) also pass.

Floating-point math intrinsics, remaining compiler features and full production
kernel integration remain unfinished, along with native self-hosting, memory
targets and strict 386 validation. This arithmetic checkpoint does not establish
complete native OS support.


## Native F64 Abs and Sqr

F64 Abs and Sqr now lower as unary template expressions, which have no ordinary
call-start/end nodes. Abs uses the one-argument software `I386F64Abs` helper;
Sqr evaluates its operand once and calls software multiplication with duplicate
values. Existing numeric conversion handles integer operands, and surrounding
ordinary/intrinsic call contexts remain intact. The standalone declarations are
in `Kernel/I386/Float.HH`.

The new `--soft-f64-unary` fixture passes 3,072 native checks over 1,024 patterns,
with 2,048 actual x64 Abs/Sqr outputs matching the independent host oracle. It
covers signed exponent neighborhoods, square underflow/overflow boundaries,
zeros, infinities, signaling/quiet NaNs and deterministic random values. Abs
clears sign and quiets NaNs while preserving payloads. Four additional positive
cases cover nested templates, integer conversion, postfix side effects and a
surrounding ToI64 call; four rejection cases check missing/malformed providers.

The expanded F64 expression/condition/chain fixture, all 178 integer/call cases,
generated-instruction audits, coprocessor-disabled unary execution, both x64
rebuild generations and image verification (766 files, 62 directories) pass.
Sqrt, trigonometry, other numerical/formatting operations, floating-point state,
full compiler/kernel integration, native self-hosting, memory targets and strict
386 validation remain unfinished.


## Native software square root

`I386F64Sqrt` now normalizes positive finite inputs, makes their exponent even,
and extracts a 56-bit root from a two-word radicand using integer operations.
The remainder supplies sticky information to the common nearest-even rounder.
The helper preserves both zeros, quiets NaNs with sign/payload intact, returns
positive infinity unchanged, and returns the negative indefinite NaN for negative
nonzero values. The compiler lowers the Sqrt template intrinsic through this
helper without requiring a coprocessor.

The unary fixture now passes 5,120 native checks over 1,024 inputs, six nesting/
side-effect cases and six malformed-provider rejection cases. Its square-root
oracle uses arbitrary-precision integer square root and exact midpoint comparison.
Two observed x64 results differ by one ULP, consistent with a 64-bit-significand
intermediate rounded again to binary64. These observations are checked separately;
the native result must match the correctly rounded oracle. The precise input and
result bits are documented in `docs/i386-f64-backend.md`.

The F64 expression/condition/chain suite, all 178 integer/call cases, instruction
audits, CR0.EM execution, both x64 rebuilds and image verification (766 files,
62 directories) pass. The growing main F64 fixture now uses the existing 128 KiB
boot-transfer path instead of 64 KiB; its RAM remains 8 MiB. This changes fixture
capacity, not the OS memory requirement. Trigonometry, remaining numerical/
formatting support, floating-point state, full compiler/kernel integration,
native self-hosting, memory targets and strict 386 validation remain unfinished.


## Native ModU64 quotient/remainder intrinsic

ModU64 now evaluates its destination and divisor once, reads the full U64 value,
and computes quotient and remainder in one unsigned division. It stores the
quotient through the saved 32-bit pointer and returns the remainder. A new private
mode in the existing division template exposes both results without repeating the
64-step division. Existing signed/unsigned quotient and remainder modes remain
unchanged semantically. This supports the digit-extraction operation used by
StrPrint and date decomposition; their full native integration is still pending.

The integer-math corpus passes 10,176 result checks: the prior 8,192 intrinsic
results and 1,984 quotient/remainder results over nonzero-divisor pairs. Actual
x64 output matches the Python oracle before native execution. Eight additional
checks cover nesting, side effects, shared operands and decimal extraction of all
20 digits of U64_MAX. The function fixture now passes 179 cases, including five
hardware #DE cases with a new zero-divisor ModU64 check.

The 5,120-check F64 unary corpus, nesting/rejection checks, instruction audits,
both x64 rebuild generations and image verification (766 files, 62 directories)
pass. Full formatting/variadic calls, remaining compiler features, numerical state,
production kernel integration, native self-hosting, memory targets and strict
386 validation remain unfinished.


## Native exception record lifetime

Task records now retain a nested exception-record chain. Push copies an explicit
32-bit register/handler capture after validating stack bounds and allocating
from the supplied heap. Pop and clear enforce task ownership and retain the
chain on failed removal. Scheduler reaping rejects records that still reference
the task, allowing a finished task to be drained before freeing its stack.

The dedicated `--except-records` fixture passes nested and separate-task/heap
ownership, copied capture values, allocation failure, malformed capture and
record rejection, finished-task pinning and full reclamation checks. Its first
version used unaligned global frame storage and was correctly rejected; the
passing fixture uses aligned local stack storage. The native task regression,
generated-instruction audits and both x64 rebuild/reboot generations pass.

These are synthetic capture and lifetime checks, not actual exception transfer.
SysTry/SysUntry runtime entry, caller register capture, catch execution, propagation,
nonlocal restoration and full CTask integration remain pending. See
`i386-exceptions.md`. The complete OS, native self-hosting, memory budgets and
strict 386 hardware compatibility remain unproven.


## Native exception context primitives

Bootstrap assembly now captures the caller's EBP, post-return ESP, preserved
registers, flags and handler addresses without a HolyC wrapper changing them
first. Catch invocation supplies the saved enclosing frame on the invoking
stack and restores invoker state after a bare-RET catch. Nonlocal resume restores
the saved stack/registers/flags and jumps to cleanup.

The dedicated `--except-context` fixture passes physical register/flag sentinel
checks, stack abandonment, and compiled catches accessing enclosing 64-bit locals.
One compiled case returns to its invoking helper; another resumes at cleanup
and skips the remaining try body. Fixture-only registration supplies compiler
labels and frame addresses; production registration and task-owned propagation
remain pending. Both x64 rebuild/reboot generations and the native task regression
pass, with instruction audits covering production and test assembly ranges.
The ndisasm 3.01 JMP-register workaround now also recognizes exact FF E2
(JMP EDX), independently checked with objdump.

This does not complete exception handling or the OS. See `i386-exceptions.md`
for the ABI, limits and remaining runtime integration. Native assembler support,
self-hosting, memory targets and strict 386 validation remain required.


## Native capture-to-record registration

A new assembly registration entry captures preserved registers, EBP, post-return
ESP, flags and catch/cleanup addresses before calling HolyC. It passes the
temporary capture to an explicit task/heap provider and returns its pointer
result, freeing the temporary stack storage with callee cleanup. Native tests
verify physical register/flag captures, provider arguments and nested real record
allocation, then force exhaustion and check unchanged ownership and complete
reclamation. The expanded context fixture and instruction audits pass, as do
both x64 rebuild/reboot generations.

Production SysTry binding, registration-failure propagation and throw dispatch
remain pending; the explicit five-argument entry does not supply those policies.
See `i386-exceptions.md`. The complete OS and native self-hosting remain unfinished.


## Native task-owned exception dispatch

I386ExceptDispatch now stores the full exception value and acceptance flag in
the bootstrap task record, validates the selected capture, invokes its catch,
removes rejected records and resumes accepted catches at compiler cleanup.
Returned statuses distinguish unhandled exceptions, invalid state and a broken
resume provider that returned. Task lifecycle operations reset exception state.

The expanded context fixture passes nested rejection/acceptance in one frame
and across function frames, accepted inner catch with normal outer cleanup,
full I64 exception values, unhandled cleanup, corrupt records, returning resume
callbacks, selected-record removal and invalid task/callback arguments. It uses
real heap records with fixture-only SysTry frame registration. The record-lifetime
suite, task regression, generated/assembly instruction audits and both x64
rebuild/reboot generations pass.

The production two-argument SysTry entry, public throw/error policy, recursive
throw semantics, catches that yield, debugger/logging and full CTask integration
remain pending. The complete native OS, self-hosting, memory targets and strict
386 validation remain unfinished. See `i386-exceptions.md`.


## Compiler SysTry entry

A bootstrap T32M provider now exports the actual two-argument SysTry ABI. It
captures caller registers and the stack after callee cleanup before calling
HolyC, then imports record publication and registration-failure services through
normal relative module relocations. Failed registration cannot return into the
try body, even if the failure service incorrectly returns.

The context fixture now links this provider and no longer reconstructs try
frames in a HolyC wrapper. Nested/cross-frame dispatch passes with real captures,
as do OutMem recovery through an outer catch and early returns from both try
and catch bodies, with record/heap reclamation. Generated, linked-provider and
context assembly instruction audits and both x64 rebuild/reboot generations pass.

The fixture still supplies environment-specific task/heap and failure services.
Production service binding, public throw/unhandled/debug recovery, native
assembler/self-hosting and the complete OS remain unfinished. See
`i386-exceptions.md`.


## FS-bound public exception runtime

ExceptRuntime now supplies the native SysTry services, public SysUntry and throw.
It resolves the task through FS, uses that task's heap, reports ordinary throws
through an installed callback, honors no_log, and sends returned dispatch errors
to a fatal/recovery hook. OutMem during registration propagates to existing
catches without logging. A returning fatal hook cannot continue the failed
operation. Service installation is validated and allowed once.

The new `--except-runtime` fixture passes under two sequential FS task bindings
with separate heaps. Tests cover default and full-width exception values, logging
and no_log, nested propagation, registration exhaustion, early catch return,
unhandled recovery-hook routing and complete record reclamation. The context
regression, instruction audits (including temporary segment setup) and both x64
rebuild/reboot generations also pass.

These remain bootstrap task records and installed test report/recovery hooks.
Concrete logging/debugger behavior, caller traces, recursive throw semantics,
catch-time switching, public CTask/boot integration, self-hosting and the full
386 OS remain unfinished. See `i386-exceptions.md`.


## Exceptions across task switches and caller diagnostics

Public throw now stores a diagnostic throw-frame pointer and eight bounded
return addresses before reporting, including when no_log suppresses the report.
Task lifecycle operations clear the fields. These are snapshots, not contexts
that may safely be dereferenced or restored after recovery.

The new `--except-tasks` integration suite runs two actual heap-owned workers
with separate stacks and private heaps across two lifecycle cycles. Four rounds
per worker cover acceptance, rejection/propagation and 48 yields inside catches.
FS task state, I64 locals, exception values and flags, record identity/counts and
caller snapshots survive switches; completion and destruction reclaim all memory.
Report hooks compare stored addresses against Caller at the corresponding depth.

The new task-exception and sequential-FS runtime suites, general task regression,
instruction audits and both x64 rebuild/reboot generations pass. The general
task fixture exceeded its 128 KiB transfer cap after the layout/lifecycle changes.
It now loads 160 KiB from 0x10000 through 0x37FFF, below its first heap at 0x40000.
Other fixture transfer sizes and the 8 MiB guest RAM setting are unchanged. This
is harness capacity, not evidence that the full OS meets its RAM targets.

Recursive throw semantics, full public task/debugger integration, production
boot, native self-hosting and strict 386 validation remain unfinished.


## Native HolyC inline assembly

The i386 backend now emits inline assembly bytes and fixes relative label
references at native offsets, including addends. Native assembly defaults to
USE32. The nested parser preserves label nodes and connects prior HolyC goto
references to assembly definitions instead of discarding those definitions.
Assembler expressions use target-size folding followed by a validated host
expression path for integer arithmetic and known host symbol-value reads.
Target instruction bytes are never executed as host code.

The dedicated `--inline-asm` fixture passes nine native checks covering wide
argument writes, loops, local calls, branches in both directions between HolyC
and assembly, nonzero branch addends, constant arithmetic, named locals and bare
assembly statements. Caller register preservation is checked by the runner.
Seven rejection cases cover wrong modes, 64-bit/extended registers, absolute
label addresses and inline imports. Native instruction audits, all 233 existing
function cases and both x64 rebuild/reboot generations pass.

Inline external imports/exports, absolute/storage relocations and migration of
bootstrap assembly modules remain unfinished, as do the full compiler/kernel
link, native self-hosting and strict 386 verification. See `i386-inline-asm.md`.

## HolyC-built SysTry provider

`Kernel/I386/SysTry.HC` replaces the NASM-built two-argument entry with top-level
USE32 assembly compiled inside TempleOS. Its module exports SysTry and imports
the registration and failure services through ordinary REL32 relocations. The
capture layout, callee cleanup and non-returning registration-failure contract
are preserved. Exception fixtures now build and export this provider themselves.

The context, public-runtime and task-switch suites all pass with the generated
provider, including native instruction audits. Both x86-64 compiler/kernel
rebuild/reboot generations also pass. This removes one host assembler dependency;
the cross-compiler still runs on x86-64, and context/interrupt/boot assembly,
production kernel integration, native self-hosting and strict 386 validation
remain unfinished.

## HolyC-built exception context module

`Kernel/I386/ExceptContext.HC` now provides all four exception context entries:
save, invoke, resume and capture/registration. The NASM implementation has been
removed. Each exception fixture builds and exports the module inside TempleOS;
the host checks its four exports and absence of relocations before embedding
the generated code into the protected-mode runner. The instruction audit excludes
only checked zero alignment padding following the final callee-cleanup return.

The context, public-runtime and task-switch suites pass with these generated
entries. Coverage includes physical register/flag restoration, stack abandonment,
record exhaustion/reclamation, propagation, caller diagnostics and catch-time
switches. Both x86-64 compiler/kernel rebuild/reboot generations also pass.
Task context switching, interrupt/boot assembly, full public kernel integration,
native compiler execution and strict 386 verification remain required work.


## HolyC-built task context, idle and segment reload

`Kernel/I386/TaskContext.HC` replaces the three NASM task-switch, idle and FS/GS
reload stubs with one HolyC assembly module. Task fixtures compile it inside
TempleOS and use the exported entry offsets in the generated code. The host
requires only the expected code exports, no relocations, complete entry coverage
and bounded zero tail padding. Both exception and task modules share this small
embedding helper; task entry ranges remain individually instruction-audited.

The general task, blocking-input, message-delivery and exception-task suites all
pass, including native instruction audits. They exercise stack switching and
lifecycle, IRQ-driven idle/wakeup, FS/GS identity, keyboard delivery and catch-time
switching with the new entries. Both x86-64 rebuild/reboot generations pass.

The runner still passes entry pointers into standalone native services. Public
CTask/Yield and production boot integration, the interrupt/boot assembler path,
native compiler execution and strict 386 validation remain unfinished.


## HolyC-built IRQ and CPU exception entries

`Kernel/I386/IrqEntry.HC` and `ExceptionEntry.HC` replace the remaining NASM
kernel entry stubs. They export the sixteen PIC IRQ entries and seventeen 386
exception entries, importing `I386IrqDispatch` and `I386ExceptionDispatch` through
REL32 calls. Their register/segment/flags and normalized error-code contracts are
unchanged; neither module contains fixed-address callback data.

The IRQ and task fixtures compile both modules inside TempleOS. The host checks
entry exports, the allowed CALL relocation, complete code coverage and bounded
zero padding after IRET. It binds the imports to small test-only callback adapters
and builds IDT address tables from exports. Instruction audits inspect the patched
code and adapters. The production linker can bind these ordinary module imports;
the fixtures still use the bootstrap embedding path, not a production IDT setup.

The IRQ suite passes its hardware delivery, spurious IRQ, frame-restoration and
three recoverable-fault checks. Task, blocking-input, message and exception-task
regressions also pass, including instruction audits. Both x86-64 compiler/kernel
rebuild/reboot generations pass. No NASM source remains under `Kernel/I386`, but
the boot/test harness still uses NASM. Native compiler execution, production
boot/IDT/dispatcher integration and strict 386 verification remain unfinished.


## Native IDT construction and installation

`Kernel/I386/Idt.HH` and `Idt.HC` now construct 32-bit ring-0 interrupt gates,
replace individual vectors and load/read the actual IDTR through HolyC inline
assembly. The API checks table bounds, full-width counts/vectors, handler and
GDT-selector constraints. Loading requires IF clear and leaves the IDTR unchanged
on rejected inputs. Storage ownership, executable segment validity and handler
lifetimes remain caller responsibilities.

The IRQ fixture creates and installs its own 256-entry table, populating it with
the HolyC-generated IRQ and CPU-exception entries. Native checks cover exact gate
bytes, surrounding sentinels, invalid/wrapping input rejection, IF-enabled load
rejection and IDTR readback. Hardware delivery and three recoverable faults then
pass through that table. Instruction audits, the exception-task regression and
both x86-64 rebuild/reboot generations also pass.

The runner still installs its emergency table before entering native code. Full
production boot handoff, NMI/double-fault policy, debugger integration, native
compiler execution and strict 386 verification remain unfinished. See
`i386-idt.md` for ownership and gate contracts.


## Linked native interrupt installation and dispatch

`Kernel/I386/Interrupt.HH` and `Interrupt.HC` now connect IDT setup to ordinary
module linking. The runtime imports all IRQ/exception entry addresses, while
those modules import the runtime's dispatcher functions. Installation copies
validated service callbacks, builds the table, publishes services and loads the
IDTR with IF clear. It rejects invalid/repeated installation before mutations.
The caller owns device setup, module/table lifetimes and callback behavior.

The IRQ fixture now links the runtime and both entry modules together. Its
installed gates point to linked entries rather than the runner's initial copies;
native callbacks observe hardware IRQ delivery and all three recoverable faults.
Tests cover invalid/IF-enabled/repeated installation, table/IDTR preservation and
service-record lifetime independence. Instruction audits explicitly classify the
linked interrupt blocks through their final IRET and bounded zero padding.
The IRQ suite, exception-task regression and both x86-64 rebuild/reboot
generations pass.

This removes bootstrap callback adapters from the installed IRQ-test path.
Production boot/device/task initialization ordering, debugger policy, native
compiler execution and strict 386 verification remain unfinished. See
`i386-interrupt-runtime.md`.


## Native GDT and linked task-context setup

`Kernel/I386/Gdt.HH` and `Gdt.HC` now construct the five-entry baseline GDT and
load/read GDTR through HolyC assembly. Construction validates table and task/CPU
extents before mutation. Loading checks table extent/count and requires IF clear;
segment reload and lifetime remain explicit caller responsibilities.

The exception-task fixture links TaskContext with its runtime, builds and loads
its own GDT, binds FS/GS through the linked reload entry, and runs both worker
lifecycles and 48 catch-time yields with the native descriptors. It restores the
saved GDTR and selectors before returning, without the runner's temporary-GDT
wrapper. Checks cover bounds/no-mutation, flat descriptor bytes, guards, actual
GDTR values, IF-enabled load rejection and restoration. The saved packed limit
is decoded bytewise when calculating the restoration entry count.

The exception-task suite and instruction audit pass, as do general tasks, linked
IRQs and both x86-64 rebuild/reboot generations. Production task/CPU records,
complete boot sequencing, exceptional-stack policy, native compiler execution and
strict 386 verification remain unfinished. See `i386-gdt.md`.


## Native task platform and root-stack registration

`Kernel/I386/TaskPlatform.HH` and `TaskPlatform.HC` now initialize the native
single-CPU scheduler, root stack and heap, CPU record, GDT and binding callback
as one controlled operation. They link the context-switch/reload entries directly.
Validation precedes mutation; unexpected post-validation failures halt instead
of exposing partially initialized state. The platform is installed once and its
caller-owned records/table/stack/heap remain live.

The exception-task fixture no longer supplies its own binding callback. It uses
the kernel initializer, checks rejected/repeated setup and root stack/heap/FS/GS
identity, and handles a full-width root exception with caller diagnostics and
record reclamation before running worker cycles. All 48 catch-time yields pass
with task and CPU identity checks and full worker reclamation. Native instruction
audits, general task regression and both x86-64 rebuild/reboot generations pass.

These are still the standalone native task/CPU records. Public CTask integration,
complete boot/device/interrupt ordering, NMI/exceptional-stack policy, native
compiler execution and strict 386 verification remain unfinished. See
`i386-task-platform.md`.


## Fully linked native exception context binding

`ExceptNative.HH/HC` now bind the public exception services to invocation and
resumption imports from `ExceptContext.HC`, preserving the existing one-time
installation and report/fatal contracts. The exception-task fixture links its
consumer, SysTry, TaskContext and ExceptContext together. It no longer accepts
any runner runtime-function pointers; both entry arguments are explicitly zero.

The fixture passes rejected/repeated installer calls, root exception diagnostics
and reclamation, and all 48 worker catch-time yields through the linked context
entries. Public exception-runtime and general task regressions, instruction audits
and both x86-64 rebuild/reboot generations pass. Initial protected-mode boot,
concrete debugger/logging handlers, full public task migration, native compiler
execution and strict 386 verification remain unfinished. See `i386-exceptions.md`.


## Native timer delivery across task and exception state

`Kernel/I386/Timer.HH/HC` now provide a 64-bit serviced-IRQ0 counter over the
existing PIT driver, with IF-clear initialization/update and atomic single-CPU
snapshots that preserve IF. `PicPit.HH` supplies shared driver declarations.
The counter wraps modulo 2^64 and counts delivered interrupts; it is not an
elapsed-time guarantee when interrupts are masked or coalesced.

The exception-task fixture now links six modules, including native IRQ and CPU
exception entries. It installs its own GDT/IDT and dispatch services, configures
PIT channel 0 and unmasks IRQ0. Root and both workers receive real interrupts.
Each of the 48 catch-time yields is followed by a hardware-tick wait, checking
FS/GS, current task/CPU, IF/DF and exception/local preservation. Root also reads
atomic snapshots with IF enabled across the 32-bit rollover; monotonicity and
IF preservation pass. Rejected initialization/update cases and direct U64 wrap
are checked. The fixture masks IRQs and restores its original IDTR/GDTR on return.

The combined suite, linked IRQ regression, instruction audits and both x86-64
rebuild/reboot generations pass. No runner function pointers enter the combined
runtime. Production boot/device integration, public clock/sleep APIs, full CTask
migration, native compiler execution and strict 386 validation remain unfinished.
See `i386-timer.md`.


## Timer-driven cooperative sleep queue

`Kernel/I386/Sleep.HH/HC` now register stack-owned waiters, block non-root tasks
and wake due tasks from timer dispatch without IRQ-time switching or allocation.
The queue counts delivered ticks, preserves caller IF and reblocks after spurious
scheduler wakes. Pending tasks/stacks cannot be destroyed or abandoned; public
cancellation and millisecond sleep APIs remain pending.

The combined fixture now performs 48 timed sleeps inside catches across worker
lifecycle cycles. Root idles when both workers block; IRQ0 advances the queue.
Early-wake injection, no-early-return checks, IF-clear/enabled caller preservation,
64-bit countdowns, already-runnable expiration and full queue/heap reclamation
pass. General task and linked IRQ regressions, instruction audits and both x86-64
rebuild/reboot generations also pass.

The combined image has grown beyond 128 KiB and now uses the existing 160 KiB
loader capacity below its 0x40000 heap arena. Full boot/desktop integration,
public task/time interfaces, native compiler execution and strict 386 verification
remain unfinished. See `i386-sleep.md`.


## First standalone native kernel image

`Kernel/I386/Kernel.HC` now boots independently of the function-test runner.
The new cross-builder compiles/links six modules inside TempleOS, audits native
code and packages a BIOS-CHS hard-disk image using the shared loader. Native entry
consumes the memory handoff, enables A20, selects a heap, initializes task/CPU/GDT,
exception and interrupt services, timer/sleep queues, and presents planar VGA.
A heap-owned task performs periodic sleeps while root idles. No runtime function
pointers are provided by the boot stage.

The image boots on the 8 MiB QEMU/486 profile with CR0.EM set. The selected arena
is 0x110000+0x6D0000, the linked kernel is 125672 bytes, and timer wakeups occur at
ticks 25 and 50. All 640×480 pixels match the sixteen-color output. Source/tool,
bootstrap, module and image hashes and boot evidence are recorded by the builder.
The combined task/exception/sleep regression and both x86-64 rebuild/reboot
generations also pass.

This is a standalone kernel foundation, not completion of the OS: shell/JIT,
DolDoc, RedSea startup, public task records, input/audio integration, native
self-hosting and strict 386 validation remain unfinished. The disk is not yet
an installed RedSea distribution. See `i386-kernel.md` for build/run commands
and the remaining boot assumptions.


## RedSea-backed standalone kernel startup

The standalone image now includes a formatted RedSea volume at sector 2048 with
231 source/module files. The builder preserves source bytes and independently
walks serialized directories, file hashes, extents and allocation ownership;
header, directory-size, file-byte and bitmap corruption checks reject mutations.
A separate versioned boot-disk sidecar preserves the existing memory handoff ABI.

Native startup requires the initial BIOS-0x80/primary-IDE-master profile,
identifies the disk, mounts RedSea and streams its own Kernel/I386/Kernel.HC in
256-byte chunks. The boot check matches the complete file size/checksum and
verifies that the disk did not change. VGA, memory selection and delayed task
wakeups still pass. The memory-sidecar and RedSea reader regressions and both
x86-64 rebuild/reboot generations also pass.

The linked kernel is now 173512 bytes. Its reserved CHS transfer grows to 384 KiB,
ending at 0x70000 below the root stack; test stages retain their 160 KiB bound.
The disk is a source/module volume, not a complete installed distribution.
Public filesystem/task integration, startup-source execution, shell/JIT, DolDoc,
native self-hosting and strict 386 validation remain unfinished. See `i386-kernel.md`.

## Disk-loaded native startup module

Standalone startup now loads `Modules/I386/Startup.t32m` from RedSea through the
checked native loader. The separately cross-compiled module binds two resident
functions and one data symbol, initializes VGA through the resident display
service, increments a resident counter and returns. It is not part of the six
resident modules linked into the boot kernel.

The kernel verifies that the file-loading temporaries are freed, then releases
the loaded image after execution and checks heap byte/allocation accounting.
The 8 MiB QEMU/486 boot passes source reads, module execution, 232-byte image
reclamation, all VGA pixels and timer wakeups. Copies with a wrong CPU tag or an
unresolved import halt before startup execution without changing disk contents.
The linked kernel is 221632 bytes; instruction audits cover it and the separate
startup payload. Resident-binding regressions and both x86-64 rebuild/reboot
generations pass.

Startup runs synchronously with exclusive heap/disk ownership and cannot retain
module addresses after return. The display buffer is owned by resident code.
This is disk-loaded AOT execution; native source compilation, the shell/JIT,
public task/filesystem interfaces, input/audio/DolDoc integration, native
self-hosting and strict 386 verification remain required. See `i386-kernel.md`.

## Standalone keyboard and VGA text console

The standalone kernel now initializes the existing keyboard controller and
decoder, publishes IRQ1 bytes through the bounded input queue, and runs a
dedicated blocking reader task. A new 80×60 text renderer uses the original
TempleOS 8×8 font and planar framebuffer. It supplies wrapping, scrolling,
backspace and tabs without additional allocations. The input task collects
bounded lines, supports Ctrl-C cancellation and resets partial input after queue
loss; native source compilation and command execution remain pending.

The 8 MiB QEMU/486 boot passes the source/module/timer checks and the initial text
screen comparison. A separate real-device input test passes make/break and Shift,
line editing, cancellation, tab expansion, backspace across a wrapped row, and
sixty newlines that scroll the screen. Every checkpoint matches all 640×480 pixels
against an independent rendering of the original font. The disk remains unchanged.
Wrong-target/unresolved-import startup rejection, the existing blocking-input
regression and both x86-64 rebuild/reboot generations also pass.

The linked kernel is 274160 bytes. Full-frame presentation per key-down still
needs vintage-CPU performance work. This console collects lines; it is not the
HolyC shell, DolDoc editor or completion of the 8 MiB interactive-system target.
Native compiler/JIT, full public interfaces, mouse/audio, self-hosting and strict
386 validation remain required. See `i386-kernel.md`.

## Native public hash primitives and resident export lookup

`CHash` and `CHashTable` now come from one shared declaration file. Their pointer
fields follow each target ABI while the original U32 counters and I64 table
fields retain their widths. The x86-64 assembly remains unchanged. Native HolyC
now supplies `HashStr`, bucket lookup, insertion, single-table lookup and chained
lookup, preserving full-width hashes, type masks, duplicate instances, insertion
order and use counters. Publication and selected-entry counter updates preserve
caller IF through short interrupt-masked sections.

A new `--hash` fixture compares 512 strings against actual x86-64 hash results
and exercises collisions, parent tables, case sensitivity, masks, counter
rollover, IF preservation and four-byte bucket addressing. Both target layouts
are asserted. The fixture and executable instruction audit pass, as do both
x86-64 compiler/kernel rebuild/reboot generations.

Standalone startup now obtains its loader bindings by name from a private
resident hash index. The full 8 MiB QEMU/486 boot, disk-module rejection checks,
keyboard editing/scrolling and VGA pixel comparisons pass with a 279952-byte
linked kernel. These records are loader exports, not compiler function/class
metadata. Symbol-table allocation/destruction, rich compiler records, task
ownership, compiler initialization and native source execution remain pending.
The shell/JIT, complete environment, self-hosting and strict 386 requirements
remain open. See `i386-hash.md`.

## Owned native hash tables

Native hash tables now have explicit-heap creation, validation, resizing, exact
entry detachment and empty-table deletion. The owner record remains stable while
resizing replaces its bucket array. Rehashing preserves equal-name instance
order and use counters without an additional tail array. Entry/string and parent
lifetimes remain separate; locked or nonempty deletion is rejected. These APIs
preserve caller IF and perform no callbacks or yielding while relinking.

The expanded hash fixture passes partial-creation and exhausted-heap failures,
growth/shrink cycles, duplicate ordering, counter preservation, exact removal,
parent survival, allocation ownership checks and full arena reclamation. Existing
512-string compatibility checks and instruction audits still pass. Its stage is
now 128 KiB, below the test heaps at 0x40000 and above.

The standalone kernel allocates its resident export index through the new owner
path. The 289832-byte kernel passes the 8 MiB QEMU/486 source/module/keyboard/VGA
and timer checks, including invalid-module rejection and unchanged disk contents.
Both x86-64 rebuild/reboot generations pass. Public task-selected allocation,
typed compiler-symbol destruction, compiler initialization, native HolyC execution,
the full environment, self-hosting and strict 386 verification remain unfinished.

## Shared compiler symbol records and value access

The original symbol type/flag constants and record declarations now live in
`Kernel/SymbolTypes.HH`, shared by x86-64 and i386 without changing their fields.
Native layout checks cover source/export/import/define/class/function/global
records, member lists, dimensions, metadata and unions. Runtime cases preserve
I64 fields beyond 32 bits while following target-width pointers and class arrays.

One shared `HashTypeNum`/`HashVal` implementation now handles symbol value access
on both targets. Twenty-eight value cases match a pre-refactor x86-64 capture;
the native fixture also passes 289 type-bit pairs with flags and critical layout
assertions. The existing hash/owned-table regression, instruction audits and both
x86-64 rebuild/reboot generations pass.

Resident loader entries now use the real `CHashExport` prefix and shared value
access before checked conversion to 32-bit bindings. The 292144-byte standalone
kernel passes the full 8 MiB QEMU/486 source/module/keyboard/VGA and timer checks.
Rich-symbol construction/destruction, task ownership, compiler initialization,
native source execution, the full environment, self-hosting and strict 386
verification remain unfinished. See `i386-symbols.md`.

## Shared member lookup and native string comparison

The existing compiler member-name, class-base and metadata lookup routines now
live in a shared implementation included by `LexLib.HC` and compiled unchanged
on i386 apart from null-literal spelling. Native public `StrCmp` preserves the
x86-64 primitive's unsigned byte ordering and exact -1/0/1 result. Resident hash
lookup now calls it, connecting that dependency to standalone startup.

The expanded symbol fixture passes inheritance/shadowing, empty-tree fallback,
missing/case-sensitive names, member use-counter rollover, duplicate metadata
keys, wide values and high-bit class-pointer ordering on both targets. All 65,536
single-byte string pairs and additional prefix/embedded-NUL cases pass. Existing
symbol/layout/legacy-value checks, the hash/owned-table regression, instruction
audits and both x86-64 rebuild/reboot generations pass.

The 292360-byte standalone kernel still passes the complete 8 MiB QEMU/486
source/module/keyboard/VGA and timer checks. The member helpers require exclusive
live-tree ownership and add no allocation or IRQ synchronization. Member/symbol
construction and destruction, compiler control records and native initialization,
the HolyC shell, full environment, self-hosting and strict 386 validation remain
unfinished. See `i386-symbols.md`.

## Shared symbol initialization and explicit-heap constructors

Class/function initialization now shares the original five-record pointer-variant
scheme between compiler targets. The x86-64 constructors keep their task code heap;
native try constructors take an explicit heap and restore interrupt state after
allocation and initialization. Raw-type constants are shared without changing
their values or the legacy pointer tag.

The symbol fixture passes host/native initialization, pointer stride and size,
member-list sentinel use, inherited lookup, hash attachment/detachment, high-bit
function values, allocation failure, rejected interior frees and full reclamation.
Existing legacy symbol values, layouts, member/string checks and instruction audits
pass, as do both x86-64 rebuild/reboot generations. Public task-selected allocation,
OutMem behavior, nested symbol destruction, compiler initialization and native
source execution remain required. See `i386-symbols.md`.

The standalone 292360-byte kernel also passes its complete 8 MiB QEMU/486
source/module, keyboard/VGA, timer and invalid-module boot checks. This remains
a development profile, with strict 386 and native self-hosting gates open.

## Shared symbol and member destruction

The kernel/compiler symbol cleanup now shares the legacy ownership rules through
an explicit release callback. Existing x86-64 public entry points retain ordinary
Free behavior; native adapters use a supplied heap and mask interrupts around
each release. Compiler calls to the shared kernel functions are declared as
imports through KernelC.HH. Both x86-64 rebuild/reboot generations pass.

The host/native symbol fixture passes nested signatures through pointer variants,
member-list reset, dimensions, source data, string defaults and metadata, aliases,
defines, exports, file payloads and dictionary names. Tracked releases verify that
owned allocations are freed once and borrowed allocations survive; the native
heap is fully reclaimed. Existing layout/legacy-value/member/string/constructor
checks and instruction audits also pass. The 292360-byte standalone kernel still
passes its complete 8 MiB QEMU/486 source/module, keyboard/VGA, timer and invalid
module checks.

Deletion requires a detached live acyclic ownership graph and does not validate
arbitrary pointers or roll back failed releases. Public task-selected allocation,
module-code lifetime, compiler-control initialization, native source execution,
the full environment, self-hosting and strict 386 verification remain unfinished.
See `i386-symbols.md`.

## Shared member construction and signature comparison

Member insertion now shares the existing name tree, base-type index and ordered
list updates between targets. A callback preserves the parser's duplicate-name
errors and duplicate-type warnings while letting native callers use the same
operations without a full compiler control record. Native member allocation takes
an explicit heap, zeroes records and preserves the signed register field.

Host/native tests pass direct/inherited duplicate rejection, repeatable names,
warning counts, pointer-variant normalization, declaration/search ordering and
lookup counters. Shared signature comparison passes I64/string defaults and
the original finite-count boundary behavior. Allocation failure, initialization,
destruction/reclamation and the existing symbol suites pass, including instruction
audits. Both x86-64 rebuild generations and the standalone 292360-byte kernel's
complete 8 MiB QEMU/486 boot checks pass.

These are frontend dependencies. Full compiler-control initialization, native
parser diagnostics, public task/code-heap selection, source execution, DolDoc,
self-hosting and strict 386 validation remain unfinished. See `i386-symbols.md`.

## Resident built-in type registry

The original 17 internal type descriptors and class-root initialization now share
one implementation between the x86-64 compiler and native runtime. Native registry
creation owns its table, class arrays and names, preserves pointer variants and
last-alias raw-type selection, and releases all allocations on initialization
failure. Lookup leaves ownership intact; deletion requires detached references.

Host/native fixtures pass independent descriptor expectations, root/variant
semantics, aliases, lookup, reinitialization/locked-delete rejection and full
reclamation across 1,022 aligned arena sizes. The symbol runner now uses a 160 KiB
transfer ending at 0x38000, below its first heap at 0x40000. Existing symbol suites,
instruction audits and both x86-64 rebuild generations pass.

Standalone startup now chains its export table to the resident type registry and
verifies every type name through that chain. The full 8 MiB QEMU/486 boot checks
pass with a 314504-byte kernel and 7,672 bytes of registry heap use, including
startup-module execution/rejection, keyboard/VGA and timer behavior. The builder
records and checks the type count and allocation footprint. Opcode tables,
compiler-control initialization, native source execution, the full environment,
self-hosting and strict 386 validation remain unfinished. See `i386-symbols.md`.

## Shared compiler control declarations and initialization

Compiler/lexer/IR/assembler declarations now live in a shared header, extracted
byte for byte from KernelA.HH. Type-name guards avoid shadowing complete document
types with forward declarations. Native code can now use the real CCmpCtrl and
its embedded structures with target-width pointers and unchanged numeric fields.

The production x86-64 CmpCtrlNew now calls shared helpers for control/stream queue
sentinels, flags/options, symbol/bitmap bindings and lexical buffer/line state.
Filename, prompt-buffer and include-stack ownership remain on its existing path.
Both x86-64 rebuild generations pass. Host/native fixtures pass default/zeroed
state, borrowed-reference bindings, retained file metadata, critical offsets and
wide values. Native CCmpCtrl is 344 bytes versus 472 on x86-64, with CLexFile at
52/80 and CCodeCtrl at 28/48. The existing symbol suites, instruction audit and
314504-byte kernel's complete 8 MiB QEMU/486 boot checks pass.

Native file/include ownership, task-selected control constructors, complete lexer
state and source execution remain required. These initializers do not yet run
the parser, JIT shell or self-hosted compiler. See `i386-symbols.md`.


## Shared lexer snapshots and native ownership

Character backup, saved-position linking/detachment and CLexFile restoration now
share one implementation. Existing x86-64 LexPush/Pop entry points retain their
allocator and failure order. Native adapters allocate private ownership metadata,
leave state unchanged on allocation failure, and reject wrong heap/control or a
restore after the active-file pointer changes. Discard remains available after
that boundary. Snapshots borrow buffers, names and document pointers.

The new `--lex-state` suite passes 512 saved-byte/flag combinations on both targets,
nested restore/discard, wide control/line values, file padding and active include
link preservation. Native allocation failure, ownership rejection, empty/repeated
pop, interrupt-state preservation and full heap reclamation pass too. Instruction
audits, both x86-64 rebuild generations and the complete 314504-byte kernel's
8 MiB QEMU/486 boot checks pass.

This supplies parser backtracking state. Native file/include loading, tokenization,
control destruction and the complete compiler/JIT environment remain required;
strict 386 validation and self-hosting are still open. See `i386-lex-state.md`.

## Shared lexical file ownership

File attachment and release now share the original depth, root-retention and
raw/document ownership rules. The x86-64 wrappers retain CAlloc/Free/DocDel.
Native records add heap/control metadata; native pop refuses outstanding save
points or a missing required document service before changing the stack. File
names and owned raw buffers use the supplied heap; document callbacks receive
separate caller context. Buffer-position changes remain the lexer's responsibility.

The expanded lexer suite passes raw/document and root-retention combinations,
nested depths, null documents, callback routing and full native reclamation.
Native minimum/exhausted allocation, wrong heap/control, pending snapshots,
missing callbacks, retained payloads and interrupt-state checks pass. Existing
snapshot cases, instruction audits, both x86-64 rebuild generations and the
314504-byte kernel's complete 8 MiB QEMU/486 boot checks also pass.

Native source loading, document destruction, full control teardown, tokenization
and the compiler/JIT environment remain required; self-hosting and strict 386
validation are still open. See `i386-lex-state.md`.

## Native raw source character input

The x86-64 lexer and native raw-input reader now share buffer stepping, cursor
skipping, plain-file line accounting and shift-space normalization. Character
constants are extracted unchanged. Native raw input supports replay, stable EOF,
null buffers and owned include returns; unavailable document/prompt/echo handling
and rejected file pops produce an explicit error.

The host/native fixture passes all nonzero byte values, replay, cursor chains,
wide counters, repeated EOF and nested inputs with parent saved bytes. Native
unsupported-mode and snapshot-boundary recovery cases pass. The x86-64 document
text/tab/newline path and cleanup also pass, as do prior lexer state/ownership
cases, instruction audits and both x86-64 rebuild/reboot generations.

The standalone kernel now reads its source into a stable terminated allocation
and consumes it through a native CCmpCtrl/CLexFile and raw character reader.
The boot verifier independently matches 14027 source characters, 360 newlines,
checksums and reclamation of 14488 heap bytes at this revision. Its 331352-byte
image passes the complete 8 MiB QEMU/486 source/module, keyboard/VGA and timer
checks. Only this source file is loaded; the distribution remains on disk.

Tokenization, native document and prompt services, general compiler-control
lifecycle, source execution, the full environment, self-hosting and strict 386
validation remain unfinished. See `i386-lex-state.md`.

## Shared lexer character bitmaps

All seventeen 512-bit character/token tables now come from the same byte-preserved
`Kernel/CharBitmaps.HC` on x86-64 and i386. The native source compiler control uses
the original alpha-numeric bitmap. Public names, writable storage, U32 widths,
extended identifier bytes and the upper token halves retain their original values.

Both x86-64 rebuild/reboot generations pass. The lexer fixture passes the original
1088-byte table checksum (FNV32 0x778A63C3), decimal/hex membership over 512 indices,
extended identifiers, `@` policy and upper token bits on both targets, alongside
all existing input/state/ownership cases and the native instruction audit. The
fixture uses explicit word/bit indexing; it does not establish native `Bt` support.

The 332448-byte standalone kernel passes the complete 8 MiB QEMU/486 boot suite,
including startup module rejection, keyboard/VGA and timer checks. Its source
reader consumes 14082 characters and 361 newlines, matches FNV32 0x8C353D1A and
reclaims 14544 heap bytes. The distribution remains on disk. General bit-test
services, tokenization, resident compiler/JIT, document/editor integration,
self-hosting and strict 386 validation remain unfinished.

## Native bit-test and bit-scan intrinsics

The backend now lowers Bt/Bts/Btr/Btc, their three locked mutation variants, and
Bsf/Bsr. Bit strings retain signed I64 indices and canonical previous-bit Bool
results; address calculation uses both index halves before narrowing to the
32-bit target. Scans cover full I64 values, including -1 for zero. Locked variants
emit actual LOCK-prefixed memory instructions and preserve IF. The raw source
reader now uses Btr on replay flag bit 33; shared character-table tests call Bt.

Both x86-64 rebuild/reboot generations pass. Host/native tests cover indices
-512..511, unchanged surrounding bytes, all mutation return values, unaligned
bases (also locked), every scan position, 512 mixed scan inputs against a separate
shift-loop oracle, zero, side effects and nested calls. Native cases also pass
negative offsets beyond 32 bits and both IF states. All earlier lexer input,
ownership, snapshot and bitmap cases pass with the instruction audit. The fixture
requires all three locked forms to appear in audited executable code.

The 332376-byte kernel passes the full 8 MiB QEMU/486 boot, startup rejection,
keyboard/VGA and timer suite. Source character/line/hash/reclamation checks remain
14082/361/0x8C353D1A/14544 bytes. These results do not establish strict 386 or
multiprocessor contention behavior. Tokenization, full compiler/JIT residency,
DolDoc/editing and native self-hosting remain required. See
[i386-bit-intrinsics.md](i386-bit-intrinsics.md).

## Shared quoted-string decoding

The production x86-64 LexInStr and native I386LexStringChunk now share escape,
hexadecimal, dollar and chunk decoding through a character-reader callback. The
native adapter uses the existing raw reader and reports service failures as -1
with done false, retaining partial-consumption semantics. The compiler also lowers
ToUpper with the existing wide-argument behavior. These supply string-body parsing
dependencies; they do not implement native tokenization or source execution.

Both x86-64 rebuild/reboot generations pass. A new `--lex-string` fixture passes
24 raw-byte cases at seven capacities, all 256 hex values with both prefixes at
three capacities, long strings, guards/state checks, injected read failures,
ToUpper boundary/wide/side-effect cases, and the production x64 string-token path.
Native tests include invalid/unsupported requests and an escape crossing an owned
file boundary, first rejected by a pending save point and then restarted with full
child reclamation. The prior `--lex-state` suite and instruction audits also pass.

The 340480-byte kernel includes the shared decoder/native adapter and passes the
complete 8 MiB QEMU/486 boot suite. Its raw source pass checks 14160 characters,
363 newlines, FNV32 0x52B06B53 and 14624 reclaimed heap bytes. String decoding itself
executes in the dedicated native fixture. Full tokenization, resident compiler/JIT,
DolDoc/editing, self-hosting and strict 386 validation remain open. See
[i386-lex-string.md](i386-lex-string.md).

## Shared numeric and dot-token parsing

The x86-64 lexer and native I386LexNumber now share integer, fractional/exponent
and dot/range/ellipsis parsing. String and numeric adapters also share the explicit
native character-reader context. The native adapter performs the common final
lookahead and propagates body/final-read failures without claiming rollback.

Both x86-64 rebuild/reboot generations pass. The new `--lex-number` suite checks
1089 original token/state captures from revision 43e619b. Integer results and
lexical state match exactly. Native F64 values instead match an independent exact
oracle for the previously established native power/rounding policy; all 243 F64
bit differences from x86-64 are recorded. Cross-build host literal evaluation
versus native numerical semantics remains a required integration boundary.

The suite also passes consecutive dot tokens, injected read failures, unsupported
modes, invalid arguments, final-lookahead failure and an owned hex-prefix input
boundary with rejection/restart/reclamation. The existing `--lex-string` and
`--lex-state` suites and instruction audits pass. Native numeric execution runs
with CR0.EM set. Its dedicated 256 KiB test stage and heap at 0x60000 keep the
larger oracle corpus separate from live allocations.

The 384664-byte resident kernel includes the software numerical runtime, power
table and parser and passes the full 8 MiB QEMU/486 boot suite. Raw source checks
are 14306 characters, 367 newlines, FNV32 0xF8D086D1 and 14768 reclaimed heap bytes.
Boot does not yet perform full tokenization or source execution, and the current
conventional-memory stage has little growth room. Extended-memory compiler/module
layout, full lexer/JIT integration, DolDoc, self-hosting and strict 386 validation
remain open. See [i386-lex-number.md](i386-lex-number.md).

## Retained extended-memory compiler runtime

Quoted-string/number parsing and the software numerical runtime now build as
CompilerRuntime.t32m instead of enlarging the conventional-memory bootstrap link.
The native RedSea loader allocates and relocates it in extended memory, binds two
kernel reader functions and the shared decimal/hex bitmaps, validates its versioned
service interface, and retains the image for the kernel lifetime. No unload is
exposed while those code pointers remain borrowed.

Boot calls both services before display startup and again from a task after timer/
VGA/task activity, checking values, source state and the retained allocation. Host
verification matches service addresses to the actual exported function offsets.
Wrong CPU, missing import and wrong interface-version boots all reject before
publication and verify reclamation. Existing startup rejection, keyboard/VGA,
source, timer and unchanged-disk checks pass, as do both x86-64 rebuild generations.

The split exposed a parser name-lifetime bug when an extern function is redeclared
as an import. The import now copies the retained function symbol's name instead
of the consumed incoming string. The expanded --redsea-bind fixture passes that
sequence along with its previous loader/binding cases.

The bootstrap shrinks from 384664 to 346912 bytes. The runtime retains 52536 heap
bytes for a 52520-byte image, observed at 0x11F008 on the 8 MiB QEMU/486 profile.
Raw source checks are 19309 characters, 454 newlines, FNV32 0x5D4679C6 and 19768
reclaimed heap bytes. The conventional boot reservation remains 384 KiB. Full
compiler/JIT residency, target-aware literal evaluation, public runtime APIs,
DolDoc/editing, self-hosting and strict 386 validation remain open. See
[i386-compiler-runtime.md](i386-compiler-runtime.md).

## Shared character constants in the retained runtime

The production lexer and native I386LexChar now share eight-byte packed character
constants, including escapes, shortened hexadecimal forms, dollar handling and
legacy EOF termination. Native reader failures and overlength have distinct status
returns. Body failures preserve token/value sentinels; final-lookahead failure can
retain a successfully decoded token and must still be handled as an error.

The existing string fixture now also passes 536 fixed character cases against
both production Lex and native execution. These expected values and input positions
passed the original lexer at 723d506 before extraction. Injected read failures,
overlength, invalid native arguments, EOF, include-boundary rejection/restart and
reclamation, and final-lookahead failure pass. Existing string/ToUpper checks and
executable instruction audits pass. Both x86-64 rebuild/reboot generations pass.

CompilerRuntime interface version 2 adds the character service, with a 20-byte
interface. The kernel validates all three retained pointers, and boot/task probes
execute character parsing alongside string/number decoding. The complete 8 MiB
QEMU/486 boot suite passes, including runtime wrong-target/import/version rejection,
reclamation, source consumption, timer activity, keyboard/VGA and unchanged disks.

The bootstrap is 349728 bytes; the runtime image is 60544 bytes and retains 60560
heap bytes, observed at 0x121010. Raw source checks cover 20046 characters, 462
newlines, FNV32 0x78FA727D and 20504 reclaimed bytes. Full lexical dispatch,
preprocessing, native compiler/JIT execution, public runtime integration, DolDoc,
self-hosting and strict 386 validation remain required. See
[i386-lex-char.md](i386-lex-char.md).

## Shared operator/comment parsing

The production lexer and native I386LexPunct now share packed token-table lookup,
compound operators, shift assignments, nested block comments, line comments and
dollar-delimited text. The original table initialization is shared while preserving
writable target-owned storage. Token, skip and reader-error returns are distinct;
block-comment EOF preserves its original immediate return without final lookahead.

A dedicated --lex-punct fixture passes 78 fixed cases first checked against the
original x86-64 lexer at afae6fb. Tokens, source positions, final characters,
replay flags and line counts match on the shared production and native paths.
Injected read failures, invalid/unsupported requests, writable token and bitmap
storage, include-boundary rejection/restart/reclamation, and a failure during final
lookahead also pass. Existing string/character tests and both x86-64 rebuild/reboot
generations pass, with executable instruction audits.

CompilerRuntime interface version 3 adds punctuation as its fourth service and is
24 bytes on i386. The retained image owns its token tables and imports the kernel's
actual line-ending bitmap. Boot/task probes skip a line comment and then parse a
shift assignment through relocated code. Full runtime/startup rejection, source,
timer, keyboard/VGA and unchanged-disk checks pass on the 8 MiB QEMU/486 profile.

The bootstrap is 353448 bytes; the runtime image is 77312 bytes and retains 77328
heap bytes, observed at 0x125338. Raw source checks cover 21080 characters,
474 newlines, FNV32 0x5DA32934 and 21544 reclaimed bytes. Full lexical dispatch,
identifiers/macros/directives, native parser/JIT execution, public kernel services,
DolDoc, self-hosting and strict 386 validation remain required. See
[i386-lex-punct.md](i386-lex-punct.md).

## Shared identifier scanning and symbol lookup

The production lexer and native I386LexIdentScan now share identifier-body reading
and local-before-global resolution. The scan retains the production STR_LEN bound,
script mappings, alphabet tables and replay behavior. Lookup preserves class/base
member precedence, global hash masks/parent tables and U32 use-count increments.
The native adapter returns caller-owned text and borrowed symbols; it does not
publish an owned token string, expand macros or perform final lookahead.

The dedicated --lex-ident fixture passes 276 cases first checked against the
original lexer at 4cf47e0, covering lengths 1..143, all extended bytes, script
mappings, at-sign modes, source position and output guards. Native/shared lookup,
U32 counter rollover, read failures, capacity exhaustion, unsupported requests,
EOF, unchanged token/string ownership and include-boundary rejection/restart/
reclamation pass. The punctuation regression and both x86-64 rebuild generations
also pass, including executable instruction audits.

CompilerRuntime version 4 exposes identifier scanning through a fifth retained
service (28-byte interface). It imports the kernel's HashFind and StrCmp and keeps
member lookup in the module. Boot/task probes resolve I64i to the actual eight-byte
primitive registry record without transient allocation. The first boot probe
incorrectly requested the source-defined I64 class; correcting it to the existing
primitive keeps the test faithful to the current bootstrap registry. Loading the
full source-defined type environment remains native frontend integration work.

The full 8 MiB QEMU/486 boot suite passes, including runtime/startup rejection and
reclamation, source, timer, keyboard/VGA and unchanged disks. The bootstrap is
357936 bytes; the runtime image is 86328 bytes and retains 86344 heap bytes,
observed at 0x1277D8. Source checks cover 22348 characters, 491 newlines,
FNV32 0x0F3E515A and 22808 reclaimed bytes. Full lexical dispatch, owned token
strings, macros/directives, native parser/JIT, public runtime ownership, DolDoc,
self-hosting and strict 386 validation remain open. See
[i386-lex-ident.md](i386-lex-ident.md).

## Owned source attachment for native lexer inputs

I386LexIncludeCopy now prepares independent name/source copies and an owned file
record before changing the active input. Allocation failure reclaims temporary
storage and preserves parent cursor/replay state. Success backs up the parent
through the shared LexBackupLastChar helper, initializes the child and publishes
it. Snapshot and include code now obtain that unchanged helper from LexFiles.
String copies run outside the interrupt-masked allocation/publication sections.

The identifier fixture passes copy independence, nested/empty children, define and
line/depth fields, cached-byte narrowing, save-point rejection/release, 25 arena
sizes spanning failure/success and reclamation, and both IF states with the PIC
masked. The lexer-state regression and both x86-64 rebuild generations pass.
Instruction audits pass. The full 8 MiB boot suite scans an owned I64i child through
the retained runtime, returns to the cached parent delimiter and reclaims its
record/name/buffer during both boot and task activity. Runtime/startup rejection,
source, timer, keyboard/VGA and unchanged-disk checks pass.

The bootstrap is 364232 bytes; the retained runtime remains 86328 bytes with a
86344-byte heap span, observed at 0x1277D8. Source checks cover 22520 characters,
494 newlines, FNV32 0xC83D98CE and 22984 reclaimed bytes. Owned token strings,
full dispatch, macro/directive execution and lookahead across includes, native
parser/JIT, public runtime ownership, DolDoc, self-hosting and strict 386 validation
remain required. See [i386-lex-include.md](i386-lex-include.md).

## Native identifier token publication and string macros

LexIdentFinish now shares expansion-versus-publication dispatch with x86-64,
whose callbacks retain its existing allocation/exception behavior. The native
I386LexIdentToken combines scanning/lookup, copied macro input and owned identifier
publication. Expansion returns a distinct resume-dispatch status. Publication
allocates/copies before replacing the old string; allocation failure preserves its
owned text, length, hash entry and token. Scanning and lookup side effects remain.
STR_LEN now has one shared 144-byte definition.

All 276 identifier cases now exercise the actual native token service, including
allocation size and release. Host/native macro tests pass chained and empty
expansion, NO_DEFINES, local shadowing, use counts and parent recovery. Native tests
pass old-token retention during expansion, token/macro allocation failure,
replacement/reclamation and overlength before publication. The punctuation suite,
executable instruction audits and both x86-64 rebuild generations pass.

CompilerRuntime interface version 5 adds a sixth service (32 bytes), importing
explicit kernel heap, IRQ and include-copy providers. Boot/task IDENT PROBE checks
expand Type to I64i, verify the three owned include allocations and the subsequent
single owned token, then free it and recover the heap baseline. The full 8 MiB
QEMU/486 runtime/startup rejection, source, timer, keyboard/VGA and unchanged-disk
suite passes.

The bootstrap is 374992 bytes; the runtime image is 92416 bytes with a
92432-byte heap span, observed at 0x129188. Source checks cover 25883 characters,
547 newlines, FNV32 0x264D8E35 and 26344 reclaimed bytes. Full dispatch,
directive creation/execution and general include lookahead, native parser/JIT,
public runtime destruction/ownership, DolDoc, self-hosting and strict 386 validation
remain required. See [i386-lex-ident-token.md](i386-lex-ident-token.md).

## Owned native string tokens

I386LexStringToken now builds complete strings through the shared chunk decoder,
preserving embedded zeros and publishing an exact-sized owned allocation. Growth
uses explicit byte counts and retains old token text until replacement is ready.
Allocation/body-read failures reclaim temporary builders and preserve old token
fields, with partial input state retained. Final-lookahead failure can leave a
completed string published; callers must honor the error status and clean up.

The string fixture passes 24 escape/EOF/dollar cases, ten lengths through 2048
bytes, and adjacent strings preserving dollar state during replacement. Native
checks pass 253 arena sizes spanning failure/success, old-text preservation,
partial-builder cleanup, include restart/reclamation and final-lookahead failure.
Identifier regressions, executable instruction audits and both x86-64 rebuild
steps pass. The string fixture is now close to its 128 KiB stage limit.

CompilerRuntime version 6 exposes string_token as its seventh service (36-byte
interface). Boot/task probes replace an owned macro-derived identifier with
four binary string bytes, verify metadata/allocation ownership and reclaim the
final string. The full 8 MiB QEMU/486 runtime/startup rejection, source, timer,
keyboard/VGA and unchanged-disk suite passes.

The bootstrap is 378800 bytes; the runtime image is 97440 bytes with a
97456-byte heap span, observed at 0x12A760. Source checks cover 26911 characters,
558 newlines, FNV32 0x26777991 and 27368 reclaimed bytes. Full dispatch,
directives/general include lookahead, native parser/JIT, public control destruction,
DolDoc, native self-hosting and strict 386 validation remain required. See
[i386-lex-string-token.md](i386-lex-string-token.md).

## Native mixed-token dispatch in the retained runtime

`I386LexNext` now connects identifiers/string macros, numeric/dot tokens, owned
strings, packed characters and punctuation/comments. It retains common lookahead,
line metadata and literal-token flags, resuming dispatch after macro expansion.
Directives currently return -4 unless KEEP_SIGN_NUM requests a literal hash;
unavailable reader services, allocation failures and length limits remain explicit
errors. This does not yet provide preprocessing, the parser/JIT or the shell.

The shared mixed-stream fixture passes through actual x64 Lex and native dispatch:
wide integers, exact F64, embedded-NUL strings, nested comments, compound operators,
flags, macro chains, empty replacement, shadowing and mixed F64/string replacement.
Native checks cover cached binary tokens, directive/reader/length errors and
allocation failures retaining previous owned text. All temporary allocations are
reclaimed. `--lex-tokens` uses a 256 KiB stage, heap at 0x60000 and CR0.EM. The
numeric regression also passes after sharing that large-stage runner guard.

CompilerRuntime version 7 adds next_token as its eighth service (40-byte interface).
The 8 MiB QEMU/486 kernel calls its relocated entry during boot and from a task
after timer activity, checking macro expansion, parent recovery and reclamation.
The full boot suite passes service/export offset checks, runtime CPU/import/API
rejection, startup rejection, keyboard/VGA, timer and source checks. The bootstrap
is 382344 bytes; the retained runtime is 103368 bytes with a 103384-byte heap span.
Both x64 rebuild/reboot generations pass. Strict 386 profiles, numerical-policy
integration, public compiler/kernel APIs and complete native self-hosting remain
open. See `docs/i386-lex-tokens.md` and `docs/i386-compiler-runtime.md`.

## Shared #define replacement-text reading

The production lexer now delegates definition-body reading to LexDefineRead, with
its original raw reader and allocation behavior. Native I386LexDefineBody uses the
same continuation, quoting, comment, replay and chunk-boundary logic to return an
exact-sized owned buffer, reclaiming partial output on read/allocation failure.
Definition recognition, source-link metadata, entry ownership and publication
remain outside this helper; native next_token still rejects directives.

Twenty-nine fixed body expectations passed against actual #define at 6841633
before extraction, then against the shared x64 path and native construction.
They include the original initial-double-slash and trailing-backslash EOF quirks,
CR/LF continuations and lengths through 2048 bytes. Failure injection covers every
read and append in all cases. Native tests verify cursor/line state, prompt
rejection and complete success/failure reclamation across 253 small heap arenas.
The combined mixed-token fixture and its instruction audit pass, as do both x64
rebuild/reboot generations and the full native kernel boot/VGA/keyboard/rejection
suite. The runtime remains version 7; full native preprocessing and the compiler/
shell/self-hosting integration gates remain open. See `docs/i386-lex-define.md`.

## Native #define publication and expansion

Native token dispatch now recognizes KW_DEFINE through supplied keyword symbols,
reads the name with NO_DEFINES, builds the replacement text and publishes an owned
CHashDefineStr. Source/help metadata is copied before body reading can pop an
owned include. Private flags, wide source lines, duplicate-definition precedence
and cnt=-1 match the existing lexer. Publication transfers cur_str only after all
allocations succeed; failures leave the name and table intact and reclaim partial
construction. The existing symbol destructor handles detached definitions.

The dedicated --lex-define fixture preserves all 29 original replacement-text
cases and read/append failure injections, and adds full definition/expansion,
redefinition, empty/EOF/malformed-name behavior, local shadowing and metadata tests.
Native checks cover 253 publication heap configurations, name-allocation failure
through dispatch and owned-include source metadata lifetime. This fixture was
split from --lex-tokens when their combined image exceeded 256 KiB; both retain
the original loader/memory contract and pass separately with instruction audits.

CompilerRuntime version 8 retains the eight-pointer, 40-byte interface and imports
HashAdd plus the existing whitespace bitmap. Kernel boot/task probes now define
and expand a macro, verify its metadata and reclaim all four allocations. The
full boot suite passes these probes, runtime/startup rejection, source checks,
VGA/keyboard and timers. Both x64 rebuild/reboot generations pass. The runtime is
126464 bytes with a 126480-byte heap span; the bootstrap is 390760 bytes, leaving
2456 bytes in its reservation. Move subsequent bootstrap growth to extended-memory
modules. General keyword initialization, includes/conditionals/executed directives,
public compiler-control APIs, parser/JIT, DolDoc and self-hosting remain required.
See `docs/i386-lex-define.md` and `docs/i386-compiler-runtime.md`.

## Compiler diagnostics moved out of the bootstrap stage

The token, identifier/string and definition boot/task probes now compile into a
separate CompilerProbe.t32m module. The kernel loads it once during boot, calls it
with a borrowed 44-byte context before startup and after task/timer activity, then
reclaims its image. No callbacks, tasks or caller pointers escape these synchronous
calls. Phase one performs no disk I/O, and the actual compiler runtime stays live.

The bootstrap is now 364504 bytes, a 26256-byte reduction, leaving 28712 bytes in
the unchanged 384 KiB reservation. The temporary probe image is 44208 bytes with a
44224-byte heap span, all reclaimed after its task call. This is code headroom,
not a claim of lower peak physical-memory demand. The manifest distinguishes the
nine packaged modules, six linked bootstrap modules, persistent runtime and two
temporary modules.

Both x64 rebuild/reboot generations and the full native kernel boot suite pass.
All previous service/value/source/metadata tests still execute. New checks enforce
probe placement, phase order and exact reclamation, plus rejection/reclamation for
wrong CPU, missing imports and incompatible probe API versions. Startup-rejection
matching now checks the exact MODULE log prefix so it does not confuse PROBE MODULE
with startup execution. VGA/keyboard/timer and runtime rejection regressions pass.
Native preprocessing, parser/JIT, public compiler/kernel APIs, the complete document
workflow, strict 386 profiles and self-hosting remain open. See
`docs/i386-compiler-probe.md`.

## Owned native language and assembler keywords

The native kernel now initializes all 48 language and 25 assembler keywords from
bootstrap descriptors checked against OpCodes.DD and shared KW/AKW constants.
The x64 path still loads the original opcode source. A dedicated native fixture
compares every descriptor with the actual x64 keyword records, then verifies all
native mappings, owned sizes, parent/mask precedence and registry lifecycle.
Partial initialization is reclaimed across 1021 small heap arenas; locked deletion,
reinitialization rejection and reuse pass. The registry occupies 6208 bytes in 148
allocations and remains live behind primitive types, preserving F64 type precedence.

The compiler definition probe now inherits this real keyword namespace rather
than injecting a define record. Both boot/task phases pass, as do source, runtime/
probe rejection, VGA/keyboard/timer checks and both x64 rebuild/reboot generations.
The bootstrap is 372288 bytes, leaving 20928 bytes of headroom. The temporary
compiler-probe image is 43328 bytes with a fully reclaimed 43344-byte heap span;
the compiler runtime and keyword registry stay resident. Opcode/register loading,
remaining preprocessing, public compiler-control APIs, parser/JIT, DolDoc, strict
386 profiles and native self-hosting remain open. See `docs/i386-keywords.md`.

## Native symbol and mode conditional preprocessing

The native dispatcher now handles ifdef/ifndef, ifaot/ifjit, else/endif and the
CCF_IN_IF expression-boundary tokens. A shared LexSkipConditional replaces six
repeated x64 loops, retaining raw-character traversal and keyword recognition
only after a hash sign. Global-symbol existence, local shadowing, nested depth,
AOT/JIT flags, malformed operands and legacy skipped-comment/quote behavior are
preserved. Active if-expression evaluation still returns -4 natively; the native
expression parser remains unconnected.

Seventeen branch, seven marker and two EOF/raw-quote cases passed against the
original lexer at f0e4307 before extraction, then through x64 and native dispatch.
Tests also cover raw/token failures, depth/delimiter handling, name-allocation
failure and blocked owned-include EOF cleanup. A quoted hash in the new header's
comment initially triggered the same legacy raw-skip behavior during a repeated
include; the comment was reworded without changing language semantics.

Both x64 rebuild/reboot generations, conditional/definition/mixed-token suites and
instruction audits pass. Runtime version 9 executes nested conditional probes at
boot and after task/timer activity through the real namespace, reclaiming token
text. Full kernel source, VGA/keyboard/timer and all module-rejection checks pass.
The runtime is 135952 bytes with a 135968-byte retained span; the temporary probe
is 48232 bytes with a fully reclaimed 48248-byte span. Bootstrap size stays 372288
bytes. Expressions, includes, executed directives, public compiler APIs, parser/JIT,
DolDoc, strict 386 profiles and native self-hosting remain open. See
`docs/i386-lex-conditional.md`.

## Volume paths and owned source-file reads

RedSea now walks volume-scoped absolute/relative slash paths, including repeated
separators, dot and parent entries. Failures preserve the output record; files
cannot be traversed as directories. Owned whole-file readers preserve raw binary
bytes, append a NUL and reclaim allocations after incomplete I/O. Empty files
return a one-byte allocation. Both readers reject enabled interrupts.

The native storage fixture covers path/output behavior, exact binary and source
contents, empty files, 161 exhausted heap arenas, immediate/partial disk errors,
heap reclamation and enabled-interrupt rejection. Instruction audit and unchanged
whole-disk checks pass. Both x64 rebuild/reboot generations and the full native
kernel boot suite pass. KernelStorage now uses the path reader, preserving source
hashing, lexer traversal and heap-reclamation checks. VGA/keyboard/timer and module
rejection regressions pass. The bootstrap is 377480 bytes with 15736 bytes of
headroom in its unchanged reservation.

These are raw, volume-scoped services. Public path/extension behavior,
decompression, include dispatch and compiler-control integration remain required,
along with parser/JIT, documents, strict 386 hardware profiles and native
self-hosting. See `docs/i386-file-read.md`.

## Transferred native source ownership

I386LexIncludeTake now accepts an existing heap source allocation and prepares a
copied filename and file record before transferring ownership. Copied and taken
input share publication and parent lookahead backup. Failure leaves the source
with its caller and preserves input state; known owner aliases and invalid source
allocations are rejected. Native EOF releases the child source/name/record.

KernelStorage uses this boundary for its actual disk-loaded source, without a
second full source copy. Boot checks child line context, complete source hashing,
EOF parent resumption, source reclamation and final heap restoration. The current
source traverses 25561 characters and releases 26144 transient heap bytes. The
bootstrap is 383496 bytes, leaving 9720 bytes in the fixed 393216-byte reservation.
Further substantial services must respect the extended-memory module boundary.

Both x64 rebuild/reboot generations, native state and identifier/macro suites,
instruction audits and the full kernel boot/rejection/VGA/keyboard/timer suite
pass. State tests cover exact source identity, two added allocations, invalid
modes/aliases/storage, thirteen allocation-failure arenas, empty children, saved
positions at EOF, reclamation and interrupt-state preservation. The expanded
state fixture uses a 160 KiB loader reservation and the same separate heap.

Public include path/default-extension rules, .Z fallback, parent-directory search,
resident-file behavior, decompression and directive dispatch remain unconnected.
Parser/JIT, complete public APIs, documents, strict 386 hardware qualification and
native self-hosting remain open. See `docs/i386-lex-include.md`.

## Shared filename extension and compression-suffix rules

The original whole-path FileExtDot scan, uppercase .Z/.C recognition and
extension/toggle writers now live in shared filename code. Existing x64 public
functions use the shared behavior; owned native wrappers use an explicit heap,
exact output sizes and interrupt-preserving allocation. This preserves legacy
cases such as directory dots suppressing a default extension and Test.Z toggling
to Test.Z.Z because compressed-suffix recognition requires two dots.

Before extraction, 21 filename cases and five contiguous-suffix checks passed
against the original x64 functions at 51be92f. The same cases pass against rebuilt
x64 and native functions. Native tests cover null inputs, 32 exhausted heap arenas,
unchanged source storage, allocation sizes, cleanup and interrupt-state retention.
The RedSea fixture also retains its existing path, raw-read, partial-I/O and
unchanged-disk regressions, within the existing 128 KiB test loader reservation.

Both x64 rebuild/reboot generations and the full native boot, module rejection,
VGA/keyboard/timer checks pass. Native filename helpers remain outside the
bootstrap, whose 383496-byte size and 9720-byte headroom are unchanged. Absolute
paths, task directory/drive rules, actual .Z fallback and parent search, resident
file records, decompression and include dispatch remain required. The complete
parser/JIT, document workflow, strict 386 profiles and native self-hosting remain
open. See `docs/i386-file-names.md`.

## Native compression dictionary allocation

Compression types now share Kernel/Arc.HH. The archive header remains 17 bytes;
native dictionary entries and controls use their 32-bit pointer layout (12 and
65664 bytes). The x64 records retain their 16- and 98456-byte layouts and existing
assembly allocator. I386ArcEntryGet implements native dictionary growth, 12-bit
slot reuse and old-chain unlinking with pointer arithmetic, preserving only-bit-
zero consumption of entry_used.

A dedicated arc fixture compares 20000 updates per 7/8-bit mode with original
x64 assembly traces captured at fd119d3. Normalized dictionary state, occupied-slot
skips, chain reuse/traversal and higher entry_used bits are covered; both frozen
hashes match natively. Control allocation/reclamation, layout assertions and the
386 executable audit pass. Both x64 rebuild/reboot generations and the full native
kernel boot, module rejection and VGA/keyboard/timer checks pass. The standalone
bootstrap remains 383496 bytes with 9720 bytes of headroom; the new dictionary
routine is not yet linked there.

This is a compression prerequisite. Native stream decoding, owned controls/stacks,
bounded archive expansion, original compressed-data interoperability and file/
include integration remain open, as do parser/JIT, documents, strict 386 profiles
and native self-hosting. See `docs/i386-compression.md`.

## Owned native compression controls

ArcCtrlSeed now shares fresh-control initialization with the x64 constructor.
I386ArcCtrlNew owns a native control and optional 4096-byte expansion stack,
reclaims a partially allocated control if stack allocation fails and publishes
only initialized state. The private owner records the heap and actual stack
allocation separately from mutable public decoder pointers. I386ArcCtrlDel frees
those allocations while leaving source/destination buffers borrowed; wrong-heap,
raw-control and repeat deletion are rejected. Both paths preserve interrupt state.

The native control occupies a 65696-byte heap span, or 69808 bytes with its stack.
Shared x64/native lifecycle checks cover twelve mode/stack combinations and zero
initial dictionary storage. Native tests cover 33 exhausted arenas, exact-fit
success, default arguments, partial cleanup, ownership rejection, borrowed data,
changed decoder pointers and both IF states. A missing default argument on the
initial native definition was corrected after the fixture exposed it.

Both x64 rebuild/reboot generations, archive lifecycle and frozen 40000-update
dictionary traces pass, along with the native instruction audit. Full kernel boot,
module rejection and VGA/keyboard/timer checks pass with the shared initialization
change. Native archive helpers remain outside the 383496-byte bootstrap, leaving
9720 bytes of headroom. Stream decoding, bounded expansion, original archive
interoperability and file/include integration remain required, along with the
remaining parser/JIT, document, strict 386 and self-hosting work. See
`docs/i386-compression.md`.

## Shared native archive stream expansion

ArcExpandStep now shares the original streaming decoder between x64 and i386.
The x64 path retains its bit-field reader and assembly dictionary allocator;
the native path reads declared bits byte by byte and uses native dictionary
allocation. Source positions remain bit counts, output positions byte counts,
and pending expanded bytes remain on the owned stack. Reader failures record
partial output without advancing the failed code; callers must discard/reset
failed state. Native basic extent/address checks precede the shared loop.

Six fixtures from the unchanged x64 compressor cover repeated/random 32768-byte
sources and single bytes in both modes. Complete/incremental original decoding
passed before extraction at dc55f97. Eighteen native expansions now match every
source byte for full output, output chunks and input extended after its first
code. Tests verify 12-bit dictionary reuse, canaries, final stack/cursor state,
reclamation, forty unaligned bit fields, short input, invalid extents and callback
failure after one output byte. The fixture's vector-address cast was corrected
after disassembly showed it interpreting the array contents as a pointer.

Both x64 rebuild/reboot generations, native expansion and dictionary/lifecycle
suites, instruction audits and full kernel boot/rejection/VGA/keyboard/timer
checks pass. The 256 KiB expansion fixture and separate 128 KiB heap are test-only;
the standalone bootstrap remains 383496 bytes with 9720 bytes of headroom.

This remains an internal codec step requiring valid state and well-formed codes,
not a validator for arbitrary archive contents. Whole-archive size/type validation,
owned output and file/include integration are still required, along with the
remaining parser/JIT, documents, strict 386 and self-hosting work. See
`docs/i386-arc-expand.md`.

## Owned checked archive expansion

I386ExpandBuf now validates the declared archive extent, header sizes/type and
output size before allocation. It copies CT_NONE data or expands compressed data
through a per-call checked reader, returning an exact owned buffer plus NUL.
A bitmap rejects unwritten dictionary references; bounded chain walks reject
cycles and unsafe links before the shared loop follows them. Complete output,
an empty pending stack and fewer than eight trailing padding bits are required.
Temporary controls/stacks and failed output allocations are reclaimed; optional
size output changes only on success and the caller's interrupt state is preserved.

Six owned original-compressor fixtures pass byte, size, terminator and reclamation
checks. Tests also cover binary/empty data, malformed headers, truncation, invalid
codes, current-entry expansion, chain errors and 32 single-bit payload mutations.
Seven exhausted arenas cover each allocation stage; an exact 102600-byte arena
expands 32768 bytes and retains only the 32792-byte output span. All prior eighteen
stream expansions and reader tests remain. Both x64 rebuild/reboot generations,
archive tests/instruction audit and full kernel boot/rejection/VGA/keyboard/timer
checks pass. The bootstrap remains 383496 bytes with 9720 bytes of headroom.

The shared callback interface now takes explicit per-call context, avoiding global
scratch state. Raw streaming remains an internal valid-state API; the checked
whole-archive reader is available for file-service module integration. Public file
paths, .Z fallback, resident records and include dispatch remain unconnected, as
do the remaining parser/JIT, document, strict 386 and self-hosting workflows. See
`docs/i386-expand-buffer.md`.

## Decoded volume-scoped disk reads

I386RedSeaFileLoad now connects path resolution, exact/toggled-name selection,
raw disk reads and checked expansion. FileAttr and RedSea attribute constants are
shared with x64. Compression follows the resolved leaf name, preserving both
misleading stored bits and directory-dot/single-extension behavior. Success retains
one raw/decoded allocation plus NUL; failure reclaims temporary names, archives and
output and preserves optional size/attributes. Only an absent name triggers the
alternate lookup; lookup, I/O, allocation or codec errors stop the load.

Original x64-compressed source/binary fixtures pass native disk loading, byte,
attribute, size and ownership checks. Exact-name precedence, both fallback
directions, empty archives and relative directory blocks pass. A malformed archive
and a partial-I/O file each have valid alternates but correctly fail. Eighteen
small arenas, invalid/null paths and enabled-IF rejection restore heap/output
baselines. The entire 16 MiB disk remains unchanged. Shared filename/attribute/raw
regressions, both x64 rebuild/reboot generations, native instruction audits and
full kernel boot/rejection/VGA/keyboard/timer checks pass.

The new bridge remains a quiescent, IF-clear volume service outside the unchanged
383496-byte bootstrap. Task drive/directory paths, parent search, resident caching,
public exception behavior and include dispatch remain open, along with parser/JIT,
documents, strict 386 profiles and native self-hosting. See `docs/i386-file-load.md`.

## Optional native ancestor file lookup

I386RedSeaFileLoad now accepts an optional scan_parents flag, defaulting to false.
Enabled search uses local exact/alternate candidates first, then all exact-name
ancestors and finally alternate-name ancestors. A distant exact name beats a nearer
alternate; a local alternate beats ancestor files. Directory entries are skipped
as file candidates in search mode. Missing/intermediate-file contexts are rejected
without searching unrelated directories, and selected-file errors still stop the
load rather than triggering another candidate.

Parent traversal resolves on-disk parent entries, stops at the volume root and
uses constant-storage Brent cycle detection plus bounded counters and a volume
hop limit. Prefix and alternate allocations are reclaimed on all search exits.
Tests cover absolute/relative bases, nearest and distant precedence, directory
collisions, disabled search, root misses, suffix quirks, bad ancestors, missing
parents, self/two-node cycles and 22 small prefix/name arenas. Existing decoded,
partial-I/O and heap/output checks remain. Native tests and instruction audit,
both x64 rebuild/reboot generations and kernel boot regressions pass.

The expanded disk fixture uses a 160 KiB test loader, with its separate 128 KiB
heap unchanged. The standalone bootstrap remains 383496 bytes with 9720 bytes of
headroom. Task drive/directory normalization, resident caching, public file/compiler
integration, parser/JIT, documents, strict 386 profiles and native self-hosting
remain open. See `docs/i386-file-load.md`.

## Shared absolute path construction with explicit native context

The original DirNameAbs/FileNameAbs string rules now run through shared helpers.
The x64 public wrappers retain task/drive lookup and optional FileFind behavior;
native owned wrappers accept explicit current/home directory, current/boot drive
and whitespace context. Forty-four cases verified before extraction now pass
against both implementations, including repeated separators, drive/home/parent
components, filename-leaf distinctions, control and extended bytes, trailing
context slashes and absent current directories. Literal copying also removes
path-as-format-string processing, with a separate percent-character test.

Native allocation failure leaves no temporary buffers. Tests cover 105 arenas,
invalid inputs, borrowed input preservation, successful single-result ownership,
reclamation and both IF states. The existing raw RedSea suite and unchanged-disk
check pass, as do executable instruction audits, both x64 rebuild/reboot generations
and full standalone boot checks. The fixture now uses a 160 KiB loader; the
production bootstrap remains 383496 bytes with 9720 bytes of headroom.

These are string services outside the native bootstrap/runtime. Task-to-volume
routing, public file flags and exceptions, resident records, scheduler-aware ATA
ownership, compiler-control lifetime and include dispatch remain open. Parser/JIT,
DolDoc, strict 386SX/DX profiles and self-hosting are still required. See
`docs/i386-file-paths.md` for contracts, original evidence and deliberate safety
changes.

## Drive-routed native file reads and owned compiler disk input

I386FileReadAt combines explicit path context, a borrowed drive-letter volume table
and decoded RedSea loading. It preserves case in names while routing letters
case-insensitively, supports current/boot/home selection and returns owned bytes
with optional size, attributes and requested absolute name. Failures preserve
optional outputs and reclaim temporary paths. Two separately mounted test volumes
provide distinct source contents for routing checks.

I386LexIncludeFile adds the compiler's HC.Z default, retains its first absolute
name, and passes that name through the reader's second normalization before
transferring decoded bytes into the existing owned file stack. Nested plain and
compressed sources preserve parent replay, line counts and EOF reclamation.
Missing/corrupt/unbound input and real partial disk-read failures leave the active
compiler control and heap unchanged. Eighty-six small arenas exercise failed and
successful input publication with complete reclamation. The test also distinguishes
the two normalization steps using a noncanonical current-directory context.

Native integration tests and executable instruction audits pass, along with both
x64 rebuild/reboot generations and the unchanged standalone boot regression.
These services remain outside the standalone bootstrap/runtime and require
quiescent volumes with IF clear. The expanded integration fixture uses a 256 KiB
loader and separate heaps; the production bootstrap remains 383496 bytes. Public
task/drive binding, resident-file semantics, error/exception integration,
scheduler-aware ATA ownership, native include-directive dispatch and full compiler
context lifetime remain open. Raw include-service success does not establish
parser/JIT execution, DolDoc, strict 386 support or native self-hosting. See
`docs/i386-file-context.md` for contracts and validation commands.

## Native include dispatch with an explicit provider

I386LexNextWithIncludes carries a synchronous include callback through recursive
token reads and conditional scanning. Active string filenames publish owned
children; parent lookahead, semicolon tokens and EOF cleanup follow the original
lexer. The existing I386LexNext remains a providerless wrapper. Missing providers
return -4, provider failures return -1 at the filename token, and token errors
propagate before loading. The disk bridge has an adapter with the same signature.

Eight scenarios pass against original x64 Lex with real source files and native
owned-buffer providers. They cover nested includes, macro and recursive filename
production, child definitions, empty input, skipped conditional branches,
semicolons and non-string arguments. Fixture text equality is checked on the host.
Native callback counts, failure snapshots, token/definition/file reclamation and
providerless compatibility pass. Existing conditional regressions, disk-adapter
routing/nested input/partial-I/O/86-arena checks, instruction audits, both x64
rebuild/reboot generations and standalone boot checks also pass.

The bootstrap remains 383496 bytes. The retained compiler module now occupies
138168 image bytes and 138184 heap bytes, increasing resident use by 2216 bytes.
Its version-9 service table still uses the providerless lexer entry. Publishing
the include-capable resident interface and binding the disk provider, along with
task-aware I/O, public file semantics, complete compiler lifetime, parser/JIT,
DolDoc, strict 386 validation and self-hosting, remain required. The dispatcher
and disk adapter have separate integration tests; the combined resident command
path is still open. See `docs/i386-lex-includes.md`.

## Retained include-capable compiler interface

Compiler service version 10 appends next_token_with_includes, making the native
include dispatcher available through the resident module's table. The i386 record
is 44 bytes with nine function pointers. Kernel publication validates all nine
addresses against the owned image; the host independently matches the include
entry to its export. The existing providerless entry remains available. An older
version-9 interface, wrong target and missing import are rejected with reclamation.

A callback in the temporary CompilerProbe module now supplies nested owned sources
through that relocated entry during boot and after task/IRQ activity. The probe
checks 11/22/33, inactive include skipping, parent delimiter/EOF, a failed load and
recovery at 44, providerless rejection, interrupt state and complete reclamation.
The runtime retains no callback/context, and every callback call finishes before
the probe module is reclaimed. Both phases are required by the host verifier.

Both x64 rebuild/reboot generations and full native boot/rejection/VGA/keyboard/
timer checks pass, including executable instruction audits. The bootstrap is
384208 bytes, leaving 9008 in its fixed reservation. CompilerRuntime has 138664
image bytes and a retained span of 138680; CompilerProbe has 59760 image bytes
and reclaims 59776 heap bytes. These boot artifacts were built with local changes
before commit; their manifests contain the build revision and source hashes.

Disk-provider packaging/binding, scheduler-aware ATA ownership, public task/file
and resident-record semantics, full compiler-context lifetime, parser/JIT, DolDoc,
strict 386SX/DX validation and self-hosting remain open. See
`docs/i386-compiler-runtime.md` and `docs/i386-lex-includes.md`.

## Retained file provider connected to compiler includes

FileRuntime now packages path/filename rules, archive expansion, decoded loading,
drive contexts and the compiler source bridge in extended memory. Its version-1
16-byte interface publishes include/read entries only after ownership, version,
size and code-range validation. The host verifies both exact export addresses.
Nine existing kernel imports avoid duplicating ATA and allocation services.
Shared native service-table validation/logging keeps the fixed boot reservation.

CompilerProbe's version-2 record supplies the stable disk context to the retained
lexer. Boot consumes a plain outer file and an original-compressor inner archive,
checks 11/22/33 and 68 lines, returns to the parent, then recovers at 44 after a bad
archive despite its valid plain alternate. All input/codec temporaries are reclaimed.
The task check explicitly enables IF, verifies rejection before I/O and restores
prior flags. Both retained images remain live after diagnostic-module release.

Both x64 rebuild generations, the complete native boot/VGA/keyboard/timer/source
suite, instruction audits across ten packaged modules and file-runtime rejection
boots pass. Wrong target, missing import and wrong file-service version reclaim
allocations before publication; every test disk remains unchanged.
The bootstrap has 389112 bytes plus 2160 loaded-stage bytes, leaving 1944 bytes in
the 393216-byte reservation. CompilerRuntime retains 138680 heap bytes, FileRuntime
retains 69392, and the 68272-byte diagnostic span is reclaimed after the task check.
Artifacts were built with local changes before commit; manifests retain hashes.

Public task/drive and resident-file semantics, scheduler-aware ATA ownership,
public errors, full compiler-control lifetime, parser/JIT, DolDoc/persistent editing,
strict 386SX/DX validation and self-hosting remain open. See
`docs/i386-file-runtime.md` for the connected path, contracts and measurements.

## Current-task file ownership and retained reads

Native tasks now inherit owned directory/drive state before becoming runnable.
The retained FileRuntime version-3 interface initializes root state and resolves
reads/includes through the FS-bound current task. Workers require bound volume
sessions. A borrow keeps the directory alive through disk polling/yields; reap
reclaims state before the task arena, and rejects a still-borrowed context.

The ATA task fixture passes independent C:/One and D:/Two relative reads,
allocation-failure cleanup, busy-state replacement/reap rejection, parent
independence and final heap reclamation. The host compares both complete disk
images and the exact command suffix, including queued poison suppression.
The standalone kernel passes direct read success/error checks in boot and worker
phases and repeats nested includes with interrupts enabled and preserved.
All temporary file/codec/probe allocations are reclaimed. Two x64 rebuild/reboot
generations, native task/exception/message/file checks and the full standalone
rejection/VGA/keyboard suite pass; this remains QEMU/486 development evidence.

The native kernel is 386320 bytes; including the 2160-byte loaded stage leaves
4736 bytes in the unchanged 393216-byte reservation. Bounded export-index tables
reduce repeated module-binding setup. Retained FileRuntime now uses 115592 heap
bytes; CompilerProbe uses 74384 temporary bytes, fully reclaimed after its task
phase. See `docs/i386-task-files.md` and `docs/i386-file-runtime.md` for contracts
and verification scope. Public task/drive/file behavior, compiler-control
lifetimes, parser/JIT, DolDoc and native self-hosting remain required.

## Owned native compiler controls

The x64 public destructor and native controls now share `CmpCtrlRelease`, retaining
file/root ownership, snapshot and saved-hash-context cleanup, parser/string storage
release and borrowed symbol-table lifetimes. Native construction allocates a full
control, root file and copied resolved display name, with rollback that leaves an
owned input buffer with its caller until success. Document release requirements
are checked before destruction changes the graph.

CompilerRuntime version 11 publishes checked constructor/destructor entries in its
52-byte record. Its seventeen imports include native file creation and shared file
release; the kernel exposes 37 bindings. Both boot and worker disk probes now use
owned controls and reclaim their entire temporary graph after nested plain/
compressed includes and malformed-input recovery, including IF-set reads.

Two x64 rebuild/reboot generations, the extended lexical-state fixture and the
complete standalone suite pass. The lifecycle fixture exercises small arenas with
borrowed and owned inputs, snapshot/file graphs, saved hash contexts, parser and
string allocations, foreign heaps, document callbacks, prompt retention and IF
preservation. Its 192 KiB test transfer stops at its existing 0x40000 arena; the
standalone reservation is unchanged.

The native kernel is 386608 bytes, leaving 4448 bytes after its 2160-byte loaded
stage in the 393216-byte reservation. CompilerRuntime retains 151112 heap bytes;
CompilerProbe uses and reclaims 73704 bytes. These are QEMU/486 integration results.
Public task/code heap and symbol selection, filename/default-name and character
bitmap selection, parser/code-generation unwind, prompt/DolDoc input, JIT and
self-hosting remain required. See `docs/i386-compiler-control.md`.

## Task-owned symbol scopes and parent lifetime

Native tasks now own local symbol tables chained to a parent, matching the public
lookup structure. Child scope ownership pins its parent task until destruction;
file borrows use the same lifetime counter so reap checks references before
releasing either resource. Spawn failure rolls back both file and symbol state.
Owned local definitions are reclaimed through the existing public symbol-release
policy, while root symbols and borrowed code remain live.

CompilerRuntime version 12 has a 56-byte interface and twenty imports. It supplies
root scope initialization and retained clone/destructor code. Forty kernel exports
bind these services. The compiler worker constructs controls using its own scope
and heap, so future definitions can obey the table's allocation ownership. Its
128 KiB arena accommodates include decompression; the keyboard arena is 8 KiB.
The combined reservation grows by 128 KiB over the prior two 4 KiB arenas.

Two x64 rebuild generations and native scope, task, ATA/file, hash and exception
checks pass. Scope tests cover local shadowing, parent/root fallback, independent
siblings, a live grandchild with a finished parent, rejected early reap, saturated
references, small-arena rollback and complete owned-symbol reclamation. The full
standalone rejection/VGA/keyboard/include suite passes on QEMU/486 with 8 MiB.

The native kernel is 389512 bytes, leaving 1544 bytes after the loaded stage in
its fixed reservation. An unused 3296-byte hash resize routine is separately
linked by general hash users; the bootstrap retains the remaining core operations.
CompilerRuntime retains 173192 heap bytes, FileRuntime 116064, and the temporary
probe reclaims 74392. See `docs/i386-task-symbols.md` for lifecycle and allocation
contracts. Complete public task/control and heap behavior, constructor name/bitmap
selection, parser/JIT, DolDoc, strict 386 profiles and self-hosting remain open.

## Current-task compiler construction and control lifetime pins

FileRuntime version 4 now constructs controls from the current task's scope heap,
symbol table and file context. It resolves explicit filenames, copies the original
`~/Tmp.DD.Z` default unchanged and selects the original normal/no-at bitmap using
`CCF_KEEP_AT_SIGN`. CompilerRuntime version 13 accepts a task owner and pins its
lifetime only after successful allocation. Destruction holds the pin through
file/document callbacks, allowing a control to survive its task's finish safely.

Two x64 rebuilds, the native lifecycle fixture, the expanded task-scope fixture
and the complete standalone suite pass. Checks cover relative paths in C:/ and
D:/Child, default-name preservation, bitmap selection, root-only configuration,
ABI rejection, saturated references, failed allocation with an owned source reused
successfully, missing-document-callback rejection and releasing a finished task's
control before reap. The standalone boot and worker include probes now use the
factory and verify name, scope, pin accounting and temporary reclamation.

The native kernel is 389800 bytes; with the 2160-byte loaded stage it leaves 1256
bytes in the unchanged reservation. CompilerRuntime retains 176352 heap bytes,
FileRuntime 123272, and the temporary probe reclaims 74776. FileRuntime's six-entry
service record is 32 bytes; compiler record size remains 56 bytes with a versioned
constructor calling-convention change. The scope/constructor test now uses a
256 KiB transfer ending at its 0x50000 arena. See `docs/i386-task-compiler.md`.
Public task/heap/error policy, automatic control-list cleanup, actual prompt/DolDoc
input, parser/JIT, strict 386 profiles and self-hosting remain unfinished.


## Active compiler controls and task-exit reclamation

Native controls now distinguish construction from active compilation, matching
public `CmpCtrlNew` and its callers. Construction stays detached and pins the
owner; enter appends to the current task's active queue, leave restores self-links
without releasing that pin, and deletion detaches an active control after release
preflight. The scheduler invokes compiler cleanup after user cleanup and before
finishing the task. Drain validates all document callbacks before any mutation and
releases tail first. Missing cleanup leaves the full queue intact and records
failure while allowing the task to finish. Explicit recovery from another task
can supply a callback, drain remaining controls and then reap the owner.

A busy flag prevents callback reentry into the same owner's control operations;
callbacks may yield but must return normally. Pins remain held throughout shared
release. These rules cover valid exclusively owned graphs, not arbitrary heap
corruption or throws through destructors. Public parser/code-generation unwind,
prompt/DolDoc input and full task/code-heap semantics remain integration work.

CompilerRuntime version 14 exports enter, leave and drain in its 68-byte record,
with twenty imports unchanged. FileRuntime version 5 validates that dependency
without changing its own 32-byte format or eighteen imports. The standalone disk
probe enters/leaves its control in boot and worker phases. Scheduler join and
current-task allocation convenience functions are separately linkable; complete
scheduler/task wrappers still include them, while the boot kernel needs only the
scheduler core and task lifetime operations.

Verification:

- Both x86-64 source rebuild/reboot generations pass.
- `--task-symbols` adds six exit scenarios: normal LIFO cleanup, non-tail detach
  surviving owner finish, and missing-document-callback rejection/recovery, each
  with IF initially clear and set. It checks user cleanup ordering, callback
  yields, reentrant mutation rejection, early-reap protection and exact final
  heap accounting, alongside the existing symbol/factory tests.
- `--lex-state`, `--tasks` and `--except-tasks` pass with executable instruction
  audits, covering shared release and existing scheduling/exception behavior.
- The standalone 8 MiB QEMU/486 suite passes: retained service validation and
  rejection, disk reads/includes, source checks, temporary-module reclamation,
  timer/keyboard/VGA behavior and executable-region audits across all ten modules.

The native kernel is 388888 bytes; its 2160-byte loaded stage brings the total to
391048 bytes, leaving 2168 in the fixed 393216-byte reservation. CompilerRuntime
uses 189472 image / 189488 heap bytes, FileRuntime 123560 / 123576, and the diagnostic
probe 75872 / 75888 (reclaimed after its task phase). These are local-change build
artifacts with source hashes in their manifests. This remains QEMU/486 development
evidence; strict 386SX/DX/no-387 acceptance and the full native HolyC environment
are not complete.


## Compiler catch boundaries and native retry

`I386CmpCtrlUnwind` now releases the active suffix after a preserved enclosing
control. It validates membership and preflights every selected document callback
before mutation, then releases tail first. Missing cleanup in the preserved prefix
does not block a valid suffix. Detached/null boundaries reject without mutation;
an empty suffix succeeds. Full task-exit drain delegates to this operation using
the task sentinel. Partial recovery of a finished task keeps its cleanup-failure
flag while active controls remain.

Cleanup stays explicit in compiler catches. The public compiler uses controls
inside exception handlers, so unconditional teardown on every throw would change
its semantics. Owner pins and the busy guard cover callbacks and yields just as
in full task-exit drain. Complete parser/AOT/generated-code release remains work;
this operation reclaims the control/input state covered by shared control release.

CompilerRuntime version 15 adds the unwind entry in a 72-byte record with twenty
imports. FileRuntime version 6 validates that dependency, with its 32-byte record
and eighteen imports unchanged. CompilerProbe version 4 adds resident SysTry,
SysUntry and throw imports, taking the kernel export index to 43 entries.
The probe translates a malformed compressed-include status into `Compiler`, catches
it natively, unwinds its child control, preserves its enclosing control/input, and
tokenizes `42;` from a new child. This verifies service reuse after recovery; it
is not native parsing/JIT or public error reporting.

Both x86-64 rebuild/reboot generations pass. Native `--task-symbols` passes added
boundary/preflight checks with IF clear and set, including callback yields/reentry,
a prefix document with no callback and partial finished-owner recovery.
`--lex-state` passes the existing unbound ownership and shared-release checks.
The complete standalone 8 MiB QEMU/486 suite passes with recovery in both boot and
worker phases, exact exception/control reclamation, all service rejection cases,
disk/input/VGA/timer checks and executable-region audits across ten modules.
See `docs/i386-compiler-unwind.md` for commands and contracts.

The kernel is 389296 bytes; its 2160-byte loaded stage brings the total to 391456,
leaving 1760 bytes in the unchanged 393216-byte reservation. CompilerRuntime uses
190768 image / 190784 heap bytes, FileRuntime 123664 / 123680, and CompilerProbe
83240 / 83256, reclaimed after its task call. Manifests record the local source
hashes used for these pre-commit builds. Public task/heap policy, complete native
parser/JIT, DolDoc and persistent editing, strict 386SX/DX/no-387 acceptance and
native self-hosting remain unfinished.


## Shared parser code contexts and native IR reclamation

`Compiler/CodeCtrl.HC` now shares intermediate-code/auxiliary initialization and
payload release between the public parser and native control services. IC fields
retain wide values/line numbers, precedence, type pointers and trace/lock flags.
The original I64_MAX invalid-pointer marker is preserved on x64 and converted to
the native pointer width. Release covers all eight auxiliary kinds, including
jump/float arrays, dimension lists and detached symbol graphs. Public unused-label
warnings and the final undefined-label diagnostic remain; earlier deferred names
are now freed when multiple undefined labels exist.

Native constructors seed an empty code context. Explicit-heap instruction/misc
allocation leaves queues unchanged on failure; discard silently reclaims the
current graph for recovery. Control destruction releases that graph and each
saved enclosing context before input/control release. Saved headers follow the
original fixed active-sentinel convention. Missing document callbacks are checked
before graph mutation. The standalone catch/retry probe now owns temporary IR in
the failed child and exercises fresh instruction allocation/discard after recovery.

CompilerRuntime version 16 has an 84-byte record and twenty imports. FileRuntime
version 7 validates this dependency while retaining its 32-byte format and eighteen
imports. Kernel bindings remain 43. Public parser/AOT and detached-context error
cleanup, diagnostics, generated-code publication and public heap/error semantics
remain required; this does not establish a native parser/JIT.

Verification passes both x86-64 rebuild/reboot generations, all 233 native function
cases, `--task-symbols`, `--lex-state`, and the full standalone 8 MiB QEMU/486 suite
with executable-region instruction audits and module rejection tests. The expanded
task fixture executes all auxiliary kinds, duplicate undefined-label cleanup,
64-bit metadata, allocation exhaustion, nested saved graphs and final reclamation
with IF clear/set. Its test loader is now 320 KiB with heap at 0x60000; lexical
state uses 256 KiB with heap at 0x50000 and scratch arenas at 0x61000/0x62000.
The standalone reservation is unchanged.

The kernel is 389312 bytes, or 391472 including its 2160-byte loaded stage, leaving
1744 bytes in the fixed 393216-byte reservation. CompilerRuntime uses 204888 image /
204904 heap bytes, FileRuntime 123968 / 123984, and the temporary probe 85608 /
85624, reclaimed after its task phase. These pre-commit manifests record the local
source hashes. See `docs/i386-code-context.md`; strict 386SX/DX/no-387 validation,
DolDoc/editing and native self-hosting remain unfinished.


## Saved code headers with independent native allocation ownership

Native instructions, auxiliary records and saved headers now embed per-control
allocation records independently of their queue links. The shared parser sometimes
copies headers that alias a graph and detaches headers before appending their
lists. Cleanup therefore walks allocation ownership once, not every header view.
It reclaims IR even when all views were detached or reset, without double frees
from aliased views. Current-graph discard unregisters its nodes; remaining header
views must not be restored after their graph has been discarded.

Copy/save/restore/append now share helpers with the public parser. Exact alias
append leaves the active list's backlinks intact. Native save/push/pop/header-free/
append enforce same-control ownership and reject release of a header still on the
saved stack. Diagnostic discard guards reentry for bound and unbound controls;
callbacks may yield and must return normally. Payload release still uses the shared
legacy policy. Public allocator and optimizer-node replacement integration remains
necessary; raw freeing of managed native records is not supported.

CompilerRuntime version 17 has a 104-byte record and twenty imports. FileRuntime
version 8 validates its dependency with the same 32-byte format and eighteen
imports; kernel exports remain 43. The standalone failed child now has saved and
detached headers aliasing its IR, and retry exercises every retained header
operation before full reclamation.

Verification passes both x86-64 rebuild/reboot generations, all 233 native function
cases, task-symbol and lexical-state ownership tests, and the full standalone
8 MiB QEMU/486 suite with module rejection and executable instruction audits.
Added tests cover the original loop-increment header sequence and 1,2,3 list order,
forward/backward links, same-list append, foreign/live-stack header rejection,
fragmented-heap exhaustion, abandoned views, and unbound diagnostic reentry. IF
clear/set paths pass. Existing 320 KiB task and 256 KiB lexer test transfers remain.

The kernel is 389328 bytes, or 391488 with the 2160-byte loaded stage, leaving 1728
in the unchanged 393216-byte reservation. CompilerRuntime uses 223432 image /
223448 heap bytes, FileRuntime 124480 / 124496, and the temporary probe 87896 /
87912, reclaimed after its task phase. Manifests record local source hashes for
these pre-commit builds. See `docs/i386-code-views.md`. Full native parser/JIT,
public task/heap/error contracts, strict 386SX/DX/no-387 workflows, DolDoc and
self-hosting remain unfinished.


## Native optimizer instruction retirement

Native instructions can now be unlinked while retaining their allocation and
fields for borrowed optimizer tree references. The shared `ICDetach` operation
preserves the removed node's links and is also used by public OptFree. Native
retirement rejects foreign/sentinel/null/already-retired entries and needs no new
allocation, including under heap exhaustion. The public optimizer's immediate
Free policy is otherwise unchanged; routing it to native services remains work.

After current-graph discard and its callbacks finish, retired entries are collected
only if no other code records remain in the owner registry. Saved/detached headers,
auxiliary records and live instructions defer collection. Header release alone is
not a collection boundary. Full control deletion/catch unwind/task exit always
reclaims the remaining owned records, including retired entries.

CompilerRuntime version 18 adds retirement in a 108-byte table with twenty imports;
FileRuntime version 9 validates it without changing its 32-byte format/eighteen
imports. The standalone failed child retains a tree reference to a retired node
alongside aliased headers; exception recovery reclaims it. Retry retires and
collects an instruction through complete discard before deleting the child.

Both x86-64 rebuild/reboot generations, all 233 native function cases, task-symbol
and lexical-state ownership tests, and the full standalone 8 MiB QEMU/486 suite
pass with instruction audits and module rejection checks. Tests cover exhausted
fragmented heaps, preserved I64 data/links, allocation pressure, invalid transitions,
saved-header deferral, unbound controls and 64 complete retire/discard cycles without
heap growth. See `docs/i386-ir-retirement.md` for scope and reclamation rules.

The kernel is 389336 bytes, or 391496 with the 2160-byte loaded stage, leaving 1720
in the fixed 393216-byte reservation. CompilerRuntime uses 227448 image / 227464
heap bytes, FileRuntime 124584 / 124600, and the temporary probe 89256 / 89272,
reclaimed after its task phase. Test transfers remain unchanged; pre-commit build
manifests record local source hashes. Public allocator/optimizer routing, full
parser/JIT/AOT recovery, strict 386 workflows, DolDoc and self-hosting remain open.


## Native shared branch optimizer and allocation-failure recovery

The resident compiler now executes the original `OptBrZero`/`OptBrNotZero`
transformations through `code_branch`. `OptBranch.HC` and `OptCode.HC` are shared
with the x86-64 compiler. All parser/optimizer calls to `OptFree` now pass their
compiler control; the native branch implementation uses owned instruction
retirement, while the public x86-64 implementation retains its `Free` policy.
Native label allocation throws `OutMem`. Partially rewritten graphs remain
owned for discard or control unwind, rather than being reused as valid input.

The task-symbol fixture passes 136 native rewrites across both IF states:
comparisons with zero through three negations, AND/OR short-circuit labels and
carry/bit intrinsics. It checks queue/tree/flag/target behavior, borrowed retired
nodes, invalid entries and exact heap reclamation. Its expanded stage uses a
384 KiB reservation and a 64 KiB heap at 0x70000; the standalone OS memory contract
is unchanged.

The standalone disk-loaded probe fills the heap after native try registration,
then catches an actual `OutMem` raised while the shared optimizer creates a
fall-through label. It reclaims filler allocations, unwinds the partially
rewritten control to the enclosing compilation and retries with a fresh control.
Both boot and task phases pass exact heap/lifetime and IF checks.

Verification completed successfully:

- `python3 tools/test-rebuild.py`: both x86-64 rebuild/reboot generations.
- `python3 tools/test-i386.py --task-symbols`: all scope/control/IR and branch cases.
- `python3 tools/test-i386.py --functions`: all 233 generated-function cases.
- `python3 tools/build-i386-kernel.py --test`: complete standalone boot, input,
  module-rejection, recovery and executable instruction-audit suite.
- `git diff --check`.

CompilerRuntime ABI 19 is 112 bytes with 21 imports. FileRuntime ABI 10 keeps
its 32-byte record and 18 imports. CompilerProbe keeps ABI 4/52 bytes and now
uses 17 imports. Kernel binding counts derive from their index arrays.
Measured image/heap spans: CompilerRuntime 256216/256232 bytes, FileRuntime
124688/124704, temporary CompilerProbe 100000/100016. The kernel remains 389336
bytes; with 2160 bytes of loaded stage overhead, it occupies 391496 of the fixed
393216-byte reservation, leaving 1720 bytes.

See [i386-branch-optimizer.md](i386-branch-optimizer.md) for the integration
contract. Full native parser/optimizer/backend execution, public allocator and
task/CPU integration, interactive HolyC, DolDoc/editing and self-hosting remain
unfinished. QEMU/486 development success is not strict 386SX/DX acceptance.


## Software F64 remainder and compiler lowering

`I386F64Mod` now computes truncating binary64 remainders by integer significand
reduction. Finite results are exact, including subnormals and signed zero. The
backend lowers F64 `%` and `%=` through its checked runtime ABI, including mixed
integer/F64 operands, integer destinations and single-evaluation pointer updates.
This supplies a numerical dependency needed by the shared constant-folding pass;
the remaining pass/runtime/frontend integration is still required.

The expanded native F64 fixture passes 8192 remainder results over 2048 operand
pairs using the helper, indirect F64 call, already-defined helper relocation and
compound assignment. An exact-rational Python oracle covers signed boundary
patterns, extreme exponent gaps, subnormal divisors and deterministic random
pairs. Actual x64 HolyC agrees exactly on all 1808 cases without NaN inputs. All
240 NaN-input pairs quiet their result; six differ in payload selection from the
native first-NaN policy. Eleven additional mixed-update checks pass on x64 and
i386; absent/malformed remainder providers are rejected. The fixture executes
with CR0.EM set and uses a 160 KiB test-stage reservation.

Successful verification:

- `python3 tools/test-rebuild.py`: both native x64 rebuild/reboot generations.
- `python3 tools/test-i386.py --float`: existing arithmetic/condition/chain tests,
  8192 remainder results, eleven mixed updates and eight rejection checks.
- `python3 tools/test-i386.py --soft-f64`: all 8192 existing arithmetic results.
- `python3 tools/test-i386.py --functions`: all 233 integer/call/function cases.
- `python3 tools/build-i386-kernel.py --test`: full standalone suite, including
  input, VGA, compiler recovery and module rejection checks.
- `git diff --check`.

The retained CompilerRuntime image grows to 260080 bytes with a 260096-byte heap
span. Its service record remains ABI 19/112 bytes; FileRuntime remains ABI 10,
124688/124704 image/heap bytes. The temporary probe remains ABI 4,
100000/100016 bytes. The kernel remains 389336 bytes, or 391496 including its
loaded stage overhead, leaving 1720 bytes in the unchanged 393216-byte reservation.

See [i386-f64-remainder.md](i386-f64-remainder.md) for semantics and oracle scope.
Floating-point status/traps, remaining numerical operations, full native parser/
optimizer/JIT, public task/allocator integration, DolDoc/editing, self-hosting and
strict 386SX/DX acceptance remain unfinished.


## Native F64 bitwise/shift lowering and effective-type selection

F64 binary `&`, `|`, `^`, `<<`, `>>` and their compound forms now lower through
the existing integer-pair instructions. Ordinary forms use raw binary64 bits after
mixed-operand promotion. The shared frontend converts an F64 right operand to I64
for compound forms before applying the operation to stored destination bits.
No new runtime helper, service pointer or module-interface version is introduced.

Mixed tests exposed a shift-selection defect: an operand promoted from U64 to
F64 still selected a logical right shift using its original type. Variable and
constant shifts now query the operand's effective value class, including its
conversion flags. The corrected promoted-F64 case matches x64 arithmetic shift.

The expanded F64 suite compares actual x64 output to independent Python bit and
conversion oracles: 30720 ordinary/compound/stored-result checks and 53248 mixed
checks. The same 83968 checks pass natively with CR0.EM set. Four further counted
pointer checks cover NaN bit preservation, converted counts, narrow storage and
U64 logical shift. A known narrow result difference is exact and explicit:
addressed `I8(-127) ^= F64(254.5)` stores 127 on both targets, but the x64 expression
returns -129; native returns its normalized stored value, 127.

Successful verification:

- `python3 tools/test-rebuild.py`: both x64 rebuild/reboot generations.
- `python3 tools/test-i386.py --float`: all bitwise/shift checks, destination checks,
  existing 8192 remainder results, arithmetic/condition/chain cases and rejection tests.
- `python3 tools/test-i386.py --functions`: all 233 integer/function cases.
- `python3 tools/build-i386-kernel.py --test`: full standalone boot/input/recovery/
  module-rejection suite and executable instruction audits.
- `git diff --check`; the rebuilt manifest matches the final backend source hash.

Measured image sizes and service ABIs are unchanged: CompilerRuntime ABI 19 is
260080 image/260096 heap bytes; FileRuntime ABI 10 is 124688/124704; the temporary
ABI-4 probe is 100000/100016. The kernel remains 389336 bytes, or 391496 with its
loaded stage overhead, leaving 1720 bytes in the fixed 393216-byte reservation.

See [i386-f64-bitwise.md](i386-f64-bitwise.md) for the two operand rules and oracle
scope. These supply additional numerical dependencies for the shared optimization
pass; complete native pass/frontend/backend integration, public task/allocator
interfaces, interactive HolyC/DolDoc, self-hosting and strict 386SX/DX acceptance
remain unfinished.

## Shared native constant folding and type analysis

The retained compiler now executes `OptPass012Core` on native owned IR. The x64
wrapper and native wrapper share the transformation body, operand type helpers,
parser stack helpers and target-size queries. Per-call services supply internal
types and diagnostics; the native control owns its allocated pass stack. Opcode
metadata now initializes explicitly from one shared list of 185 descriptors,
avoiding native AOT static string-pointer relocations.

The standalone probe runs seven folded expressions through each of passes 0, 1
and 2 in both boot and task phases: 42 cases in total. It checks signed and unsigned
integer arithmetic, F64 addition/remainder/raw bit operations and mixed promotion,
with tree/NOP/stack and exact heap accounting. A U0 dereference triggers the real
warning callback; two unconsumed values trigger the real stack diagnostic and
`Compiler` unwind. Heap exhaustion triggers `OutMem` before stack publication;
control cleanup restores heap counts, task references, active controls and IF.

Successful verification:

- `python3 tools/test-rebuild.py`: both x64 rebuild/reboot generations.
- `python3 tools/test-i386.py --task-symbols`: native control/ownership and 136
  existing shared branch rewrites; the factory fixture provides a rejecting full-pass
  callback because full-pass execution is covered by the production module probe.
- `python3 tools/test-i386.py --float`: 83968 bitwise/shift checks, 8192 remainder
  paths, destination, condition, chain and rejection cases.
- `python3 tools/test-i386.py --functions`: all 233 function cases.
- `python3 tools/build-i386-kernel.py --test`: boot/task optimizer probes, complete
  boot/input/recovery/module-rejection suite and executable instruction audits.
- `git diff --check` and Python build-tool syntax compilation.

CompilerRuntime ABI 20 is 116 bytes, retaining a 444680-byte image in a
444696-byte heap span. FileRuntime ABI 11 remains a 32-byte record; its image/span
are 124784/124800 bytes. CompilerProbe ABI 5 is 56 bytes and borrows the resident
internal-type array; its temporary image/span are 120824/120840 bytes, reclaimed
after the task phase. Compiler and probe imports remain 21 and 17 respectively.
The kernel is 389416 bytes, or 391576 with loaded stage overhead, leaving 1640
bytes in the fixed 393216-byte bootstrap reservation. The retained compiler grew
184600 bytes in extended memory; low-memory self-hosting still requires measurement.

See [i386-constant-optimizer.md](i386-constant-optimizer.md) for the valid-IR and
failure contracts. The tests exercise a subset of pass behavior. Native parsing,
later passes, backend/JIT publication, source execution, public task/allocation
interfaces, DolDoc, self-hosting and strict 386SX/DX acceptance remain unfinished.

## Native owned code emission

`EmitCore.HC` now supplies the same byte/dword/string writer to the cross-host
backend and native callers. A reserve callback supplies buffer growth; the x64
backend initializes its host callback explicitly. Native `out_new`/`out_del`
services allocate a compiler-control-owned builder whose current byte storage is
reclaimed on explicit deletion or full control unwind. IR discard and saved-view
release do not invalidate output. Growth publishes capacity only after successful
allocation/copy, preserving output across `OutMem` and supporting retry.

Boot and task probes each generate, byte-check and execute 64 native buffers.
Each buffer crosses 64/128/256-byte boundaries and returns a distinct 64-bit value.
They check foreign-control deletion rejection, survival across IR/view cleanup,
failed growth and constructor allocation on a fragmented exhausted heap, successful
retry after reclamation, overflow rejection, and native exception unwind with live
output. Exact heap counts, references, active controls and IF return to baseline.

Successful verification:

- `python3 tools/test-rebuild.py`: both x64 rebuild/reboot generations.
- `python3 tools/test-i386.py --functions`: all 233 cases.
- `python3 tools/test-i386.py`: all nine expression cases through the other emitter entry.
- `python3 tools/test-i386.py --task-symbols`: control lifetime and existing branch cases.
- `python3 tools/build-i386-kernel.py --test`: both emitter phases, boot/input/VGA,
  recovery, all module rejection checks and executable-range instruction audits.
- `git diff --check` and Python build-tool syntax compilation.

CompilerRuntime ABI 21 is 124 bytes; its image/span are 455496/455512 bytes.
FileRuntime ABI 12 keeps its 32-byte record with a 124992/125008-byte image/span.
The ABI-5/56-byte probe uses 140488/140504 temporary bytes, reclaimed after the task
phase. Compiler/probe imports remain 21/17. The kernel is 389424 bytes, or 391584
with loaded stage overhead, leaving 1632 bytes in the unchanged 393216-byte
bootstrap reservation.

See [i386-code-emitter.md](i386-code-emitter.md) for borrowing, failure and growth
latency constraints. The probe executes emitted instructions, not parsed source.
Persistent code publication and references, the complete native backend/parser,
interactive source execution/DolDoc, self-hosting and strict 386SX/DX acceptance
remain unfinished.

## Native shared function lowering

The production target backend now lives in `Compiler/I386/BackendCore.HC`, shared
by the cross-host compiler and retained native module. Explicit services provide
allocation, release, internal types, folding, inline-assembly relocation and
reporting. Native `backend` consumes valid function IR into a fresh owned output;
control ownership covers temporary lowering records and attached relocation
metadata. It retains private borrowed function/AOT/symbol context rather than
publishing persistent code. The x64 wrapper retains host constant evaluation,
assembler-expression execution, output copying and original graph cleanup.

Both boot and worker probes execute 16 natively compiled functions. Argument loads
prevent arithmetic from reducing to constant-only emission. Cases cover signed and
unsigned 64-bit arithmetic/comparisons, division/remainder, cross-word shifts,
short-circuit branch paths, and literal-pool bytes plus relocation metadata. Each
control unwind restores exact heap and reference counts. Exhausting the heap after
pass-stack allocation forces `OutMem` on the first byte emitted by the lowering
loop, then checks full unwind, exception/control state and preserved IF.

The shared 185-byte division template now uses code-marker exports. Its audit
checks contiguous instruction coverage, frame setup/teardown and internal branch
targets, rejects calls/returns and applies the ordinary executable opcode checks.
The real template passes; mutations of the prologue, branch destination and return
ending are rejected. It is an inline fragment, not a callable function.

Successful verification:

- `python3 tools/test-rebuild.py`: both x64 compiler/kernel rebuild generations.
- `python3 tools/test-i386.py --functions`: all 233 cases.
- `python3 tools/test-i386.py --float`: existing floating-point expressions,
  bitwise/shift, remainder, destination, condition and rejection coverage.
- `python3 tools/test-i386.py --inline-asm`: assembly and relative relocation cases.
- `python3 tools/test-i386.py --task-symbols`: native control/symbol ownership.
- `python3 tools/build-i386-kernel.py --test`: both backend phases, complete
  boot/input/VGA/recovery and module-rejection suite, executable instruction audit.
- `git diff --check` and Python build-tool syntax compilation.

CompilerRuntime ABI 22 is 128 bytes, with image/span 607360/607376 bytes.
FileRuntime ABI 13 keeps its 32-byte record, with image/span 125096/125112 bytes.
CompilerProbe remains ABI 5/56 bytes; its 170248/170264-byte image/span are temporary
and reclaimed after the worker phase. Compiler/probe imports remain 21/17.
The kernel remains 389424 bytes, 391584 including loaded stage overhead, leaving
1632 bytes in the fixed bootstrap reservation. The retained compiler grew 151864
bytes in extended memory; self-hosting memory use remains unmeasured.

See [i386-native-backend.md](i386-native-backend.md) for ownership and diagnostic
contracts. These native cases cover part of the shared lowering loop. Native source
parsing, import resolution and persistent publication, top-level execution/`#exe`,
public task/allocation interfaces, DolDoc, self-hosting and strict 386SX/DX acceptance
remain unfinished. The full OS goal remains active.

## Expression frontend service extraction

The original full expression parser now lives in `PrsExpressionCore.HC`. Its
operator insertion, state machine, calls, unary terms/modifiers, `sizeof` and
`offset` all receive an explicit environment. Host allocation, lexer advancement,
diagnostics, saved-view operations, optimization, string handling, symbol
publication, type parsing and recursive entry use service callbacks. Existing
`PrsExp.HC` entry points, compiler-exception handling and immediate expression
execution remain host wrappers. Precedence/associativity and type-parser flags are
shared headers; the complete binary-operator table has one initializer.

This removes host globals and direct host allocation from the expression core
while retaining the production grammar. It does not publish a native parser
service yet. The next adapter needs an owned recursive parser stack separate from
the optimizer's `cc->ps`, the original type/declaration parser, adjacent-string
ownership, unresolved symbols/assembler references, and native diagnostics.
See [i386-expression-parser.md](i386-expression-parser.md) for the concrete service
mapping and failure contracts. Native declarations/statements, source-to-code
execution, durable publication, DolDoc and self-hosting remain required.

Successful verification includes both x64 compiler/kernel rebuild/reboot
generations, 233 cross-generated function cases, 16 data cases, the existing
floating-point and inline-assembly suites, and the complete standalone boot,
VGA/input, native backend/recovery and module-rejection suite. The kernel remains
389424 bytes and the resident service ABIs are unchanged. These checks exercise
the extracted parser through the existing compiler, including source used to
build native modules; they do not prove native frontend execution.

## Type and array parser service extraction

`PrsTypeCore.HC` now shares production type parsing and variadic member
construction; `PrsArrayDimsCore.HC` shares the array-dimension loop. Existing
`PrsVar.HC` entries provide host services for tokens, snapshots, expression
execution, class/function joining, allocation, strings and members. The expression
parser's type callback reaches this same implementation. Keyword recognition now
lives in a shared pure helper. Pointer-depth rules, function-pointer syntax,
class/union forwarding, identifier ownership, anonymous names, array bounds,
warnings and argc/argv construction retain their existing behavior.

The dimension traversal previously began at `&dim`, then wrote `total_cnt` through
that pointer-containing stack slot before following its link to the root. It now
begins at `dim`, updating only real dimension objects. A new i386 function case
executes the shared helper for five dimension shapes: absent, one/three explicit,
and one/three with an unsized first dimension. Bounded fixture callbacks supply
tokens, integer bounds and dimension storage. The case checks root/suffix products,
individual counts, exact links, allocation counts, final token position and object
guards. It does not exercise native bound-expression execution or failed allocation.
The function runner now exports its compiler document on compilation failure.

Successful validation:

- Both x64 compiler/kernel rebuild/reboot generations.
- All 234 i386 function cases, including the native dimension helper.
- All 16 data cases and the floating-point and inline-assembly suites.
- The complete standalone boot, native backend/recovery, VGA/input and module
  rejection suite; the kernel remains 389424 bytes and resident ABIs are unchanged.
- Whitespace checks and Python runner syntax compilation.

See [i386-type-parser.md](i386-type-parser.md) for the service/ownership contract.
Native type/expression services still need task-owned adapters, variable-list and
class/function parsing, initialization, bound evaluation and persistent code
publication. DolDoc, native self-hosting and strict 386SX/DX validation remain
unfinished; the full OS goal stays active.

## Shared declaration and symbol construction

The production member/local/static/argument loop now lives in
`PrsDeclarationCore.HC`; class construction and function-header joining now live in
`PrsSymbolCore.HC`. Host entry points compose the existing expression/type services
with explicit allocation, execution, AOT storage, source attribution, options and
symbol lifetime callbacks. Function modifier constants have a common header.

The extraction retains recursive union/class layout, explicit offsets, register
hints, metadata/defaults, `lastclass`, static/local initialization order, inheritance,
forward-header replacement, signature warnings and target argument offsets. Static
fill settings and warning options are queried at the original execution points.
Default-expression storage stays alive until conversions/string duplication finish.
Detached old argument lists remain available for signature comparison before release.

Both x64 compiler/kernel rebuild/reboot generations, all 234 function cases, all
16 data cases and the floating-point/inline-assembly suites passed. The complete
standalone boot, compiler recovery, VGA/input and module-rejection suite also
passed; the kernel remains 389424 bytes and resident ABIs are unchanged. These
checks exercise the shared parser through the existing compiler. They do not establish
native declaration execution or ownership of published native symbols.

See [i386-declaration-parser.md](i386-declaration-parser.md) for the service contracts.
Native adapters, static/aggregate initialization, global declarations, statement and
function-body parsing, target evaluation and persistent publication remain required.
No new retained parser service is published by this change; the full OS goal remains
active, including DolDoc, self-hosting and strict 386SX/DX acceptance.

## Shared initializer parsing

`PrsInitializerCore.HC` now contains the production scalar, aggregate, array, global
and static initializer paths. Existing entries compose expression, type and
declaration services with memory copy/fill, AOT byte storage and IR compilation.
Recursive row assembly, snapshot replay, scalar conversion and static passes use
the same implementation. Scratch/AOT queues use explicit next/last stores.
The scalar path now captures incoming flags before its AOT string branch; that
branch previously read uninitialized restoration flags.

The data suite adds inferred multidimensional globals, inferred aggregate arrays
and static multidimensional arrays. Generated native programs check sizes and
values after host-side initializer parsing. Both x64 compiler/kernel rebuild/reboot
generations, all 234 function cases, all 19 data cases, floating-point and inline-asm
regressions, and the full standalone boot/recovery/VGA/input/module-rejection suite
passed. The kernel remains 389424 bytes; retained compiler ABIs are unchanged.
Whitespace and Python runner syntax checks also pass.

See [i386-initializer-parser.md](i386-initializer-parser.md) for lifetimes. Native
initializer execution still requires adapters, owned destination/temporary storage,
software-F64 conversion and durable code/data publication. Initialized i386 string
pointers still require target relocation support and remain explicitly rejected.
Global declarations, statement/function-body parsing, native source execution,
DolDoc, self-hosting and strict 386SX/DX acceptance remain unfinished.

## Shared globals and function-body construction

`PrsGlobalCore.HC` now shares the production global declaration loop, including
function dispatch, imports/externs, alias updates, allocation/alignment, source
attribution and initializer passes. `PrsFunctionCore.HC` shares function-body IR
construction, leave/return handling, compilation, trace handling and final symbol
state. Existing host entries provide composed services; statement parsing remains
an explicit callback. No retained native frontend ABI is added.

The immediate inferred-array fill previously used a loop variable uninitialized
on that path. It now fills the computed `tmpg->size`. A host regression enables
allocation fill, compiles and executes an explicitly sized multidimensional global,
checks every initialized value, and restores the prior fill settings. The existing
native data corpus covers inferred arrays through AOT compilation; these checks do
not prove native immediate inferred-array execution.

Both x64 compiler/kernel rebuild/reboot generations, all 234 function cases, all
19 data cases (including the required host-fill marker), floating-point and
inline-assembly suites passed. The complete standalone boot, compiler recovery,
VGA/input and module-rejection suite also passed. Kernel size remains 389424 bytes
and retained ABIs are unchanged. Whitespace and Python runner syntax checks pass.
These exercise the shared frontend in the existing compiler, not a natively
executing frontend.

See [i386-global-function-parser.md](i386-global-function-parser.md) for alias,
publication and output-padding contracts. Statement parsing, native service
adapters, assembler/AOT integration, target compile-time execution and durable
code/data/symbol ownership remain required. The full OS goal, including DolDoc,
self-hosting and strict 386SX/DX acceptance, remains active.

## Shared statement parser

`PrsStatementCore.HC` now shares the complete production statement parser,
including loops, nested switch sections, declarations, stream execution, assembly
dispatch and both target try/catch call paths. Existing entries supply environment
callbacks; native frontend adapters are still required. Switch jump-table fills
now use pointer-width assignments, and range enumeration stops before incrementing
past `I64_MAX`. Queue operations likewise use typed pointer fields.

Both x64 compiler/kernel rebuild/reboot generations passed. All 235 function cases
passed, including a new singleton range at `I64_MAX` executed on the host and in
generated i386 code. All 19 data cases (with host-fill marker), floating-point and
inline-assembly suites passed, as did the full standalone boot, recovery, VGA/input,
module-rejection and instruction-audit checks. Kernel size remains 389424 bytes;
retained ABIs are unchanged. Python syntax and whitespace checks passed.

See [i386-statement-parser.md](i386-statement-parser.md) for callback and ownership
contracts. The shared parser still needs native allocation registration and error
unwind, target assembly/linking and compile-time execution adapters, and durable
code/data/symbol publication. These results exercise host parsing and generated
native execution, not a native frontend. The full OS goal remains active.

## Native shared expression execution

CompilerRuntime ABI 23 (132 bytes) now publishes the complete shared expression
parser with a caller-supplied service environment. Root parser stacks register as
control-owned allocation kind 7, remain separate from the optimizer stack, and are
released on success or full control unwind. Recursive calls validate stack ownership.
Shared push/pop operations reject array overflow/underflow, and native entry checks
the task stack with a 4096-byte reserve before descending into the core. The service
loader's temporary table now follows the compiler interface size.

The native probe parses arithmetic source, runs the shared optimizer/backend and
executes the resulting code. Eight successful programs cover precedence, parentheses,
division, wide shifts, chained comparisons and 64-bit values. Four error cases cover
malformed input, allocation failure, deep parentheses and excessive unary operators.
All 12 cases pass on both boot and worker tasks, with exact heap, control, task
reference and interrupt-state restoration. Test tables and long source fixtures
live on the heap so they fit the worker's existing 8 KiB stack. Callback paths beyond
this coverage deliberately fail the fixture; they are not general native adapters.

Both x64 compiler/kernel rebuild/reboot generations passed. All 235 function cases,
19 data cases, floating-point and inline-assembly suites passed after the shared
stack changes. The complete standalone suite passed with 8 MiB and the emulated
486, including pixel-exact VGA/input and module rejection. Instruction audits pass;
strict 386SX/DX acceptance remains open. Python syntax and whitespace checks pass.

The kernel is 389432 bytes, within the existing reservation. The retained compiler
image is 739096 bytes (739112 heap bytes); the temporary probe image is 193256 bytes
and reclaims all 193272 heap bytes after both phases. Compiler/probe imports remain
21/17. FileRuntime remains ABI 13/32 bytes; CompilerProbe remains ABI 5/56 bytes.

See [i386-native-expression.md](i386-native-expression.md) for the API and limits.
This is native source-to-code evidence for the tested expressions, not a complete
frontend. Full type/declaration/string/symbol adapters, statement integration,
assembler/linker execution and durable code/data publication remain required, along
with DolDoc, self-hosting and the rest of `PLAN.md`. The full OS goal stays active.

## Native shared type parsing

CompilerRuntime ABI 24 (136 bytes) now exposes `parse_type`, which calls the full
shared type core with a borrowed service environment. Expression casts connect to
this entry through the native lexer and intrinsic type registry. Expression and
type parsing share the current-task stack reserve check. Class/function joins,
snapshots, array-bound execution and allocation remain callback contracts, with
partial-graph cleanup still the provider's responsibility.

The native corpus now has 22 cases on each of the boot and worker tasks: the prior
12 expression/recovery cases plus eight successful type/width programs and two
invalid-type cases. All 44 checks pass with exact heap, task-reference, control and
interrupt-state restoration. New execution checks cover narrow integer casts,
32-bit pointer truncation, pointer stride/difference and sizes; diagnostics cover
unknown types and too many pointer stars. The fixture uses intrinsic names such as
`U32i` and `I64i`. Public `U32`/`I64` and related scalar unions are declarations in
`Kernel/Types.HH`, and must still be compiled natively with their member views.

Both x64 compiler/kernel rebuild/reboot generations passed, as did all 235 function
cases, 19 data cases, floating-point and inline-assembly suites. The complete
standalone suite passed instruction auditing, pixel-exact VGA/input and module
rejection with the emulated 486 and 8 MiB. Strict 386SX/DX acceptance is still open.
Whitespace and Python syntax checks pass.

The kernel remains 389432 bytes. The retained compiler image is 761344 bytes
(761360 heap bytes). The temporary probe image is 197800 bytes and reclaims all
197816 heap bytes after both phases. Imports remain 21/17 for compiler/probe;
FileRuntime remains ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes.

See [i386-native-type.md](i386-native-type.md) for contracts and coverage. Complete
native declaration/class/statement integration, compile-time execution, linking,
durable publication, DolDoc and self-hosting remain unfinished. The full OS goal
remains active.

## Native parser allocation registry

CompilerRuntime ABI 25 (144 bytes) adds exact-size `parser_alloc`/`parser_free`
services. Each native compiler control now has a separate parser allocation list.
Tracking metadata is separate from payloads so existing class/member/dimension
size checks remain valid. Failure to allocate tracking metadata releases the newly
allocated payload before throwing. Explicit release rejects foreign or already
released allocations.

IR and final lexer cleanup remove matching tracking records when releasing a
payload. Control deletion then frees detached parser temporaries that never became
part of a completed graph. This covers storage allocated before or after its misc
node without depending on allocation order. It does not automatically adopt existing
lexer strings, support live lexer replacement of parser buffers, or make published
symbols durable beyond the compiler control.

Native boot/worker probes pass exact-size and zero-fill checks, explicit/foreign/
double release, string-payload discard, linked array dimensions and detached
allocation cleanup. Exhausted-heap tests separately force payload and metadata
allocation failure, checking immediate rollback inside the catch and exact final
heap, control, task-reference and interrupt-state restoration.

Both x64 compiler/kernel rebuild/reboot generations passed. The full standalone
suite passed, including all 44 native expression/type cases, parser-memory probes,
compiler recovery, module rejection and pixel-exact VGA/input. Dedicated lexer-state
and task-symbol ownership suites also passed their native execution and instruction
audits. Python syntax and whitespace checks pass. The guest remains an emulated
486 with 8 MiB; strict 386SX/DX acceptance is still open.

The kernel is 389440 bytes. The retained compiler image is 768184 bytes (768200
heap bytes). The temporary probe image is 212480 bytes and reclaims all 212496 heap
bytes after both phases. Compiler/probe imports remain 21/17; FileRuntime remains
ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes.

See [i386-parser-memory.md](i386-parser-memory.md). Native declaration/class
adapters, ownership of transferred lexer buffers, compilation of the original
public scalar unions, durable publication and the complete frontend remain open,
along with DolDoc, self-hosting and the full `PLAN.md` acceptance requirements.

## Parser token ownership

CompilerRuntime ABI 26 (148 bytes) adds `parser_token`, which uses the existing
native lexer/include implementation and registers returned identifier/string
buffers. Clearing `cur_str` to transfer a token now leaves its allocation owned by
the compiler control. Ordinary lexer replacement temporarily clears the tracking
slot's payload and then reuses the slot, avoiding stale pointers or a new tracking
allocation for each punctuation token. Empty pending slots are reclaimed if token
reading fails. Negative raw lexer results become compiler exceptions; tracking
allocation failure leaves the new string owned by final lexer cleanup.

The 44 native expression/type cases now use this token entry. Additional probes
pass on boot and worker tasks for detached identifier ownership, ordinary token
replacement, quoted-string transfer into an IR payload, EOF cleanup, replacement
failure and first-record allocation failure after successful lexing. Every path
restores heap use/counts, active controls, task references and interrupt state.

Both x64 compiler/kernel rebuild/reboot generations passed. The complete standalone
suite passed expression/type, parser-memory/token recovery, instruction auditing,
module rejection and pixel-exact VGA/input checks. Dedicated lexer-state and
task-symbol ownership suites also passed. Python syntax and whitespace checks pass.
The guest remains an emulated 486 with 8 MiB; strict 386SX/DX acceptance is open.

The kernel is 389448 bytes. The retained compiler image is 772624 bytes (772640
heap bytes). The temporary probe image is 227520 bytes and reclaims all 227536 heap
bytes. Compiler/probe imports remain 21/17; FileRuntime remains ABI 13/32 bytes and
CompilerProbe ABI 5/56 bytes.

See [i386-parser-token.md](i386-parser-token.md). Parser environments must use this
entry consistently for tracked token strings. General declaration/class adapters,
compilation of the original scalar unions, durable publication and the full native
frontend remain required, along with DolDoc, self-hosting and `PLAN.md` acceptance.

## Native declaration bodies and array-bound execution

CompilerRuntime ABI 27 (156 bytes) adds the complete shared declaration core
through `parse_declarations`, with owner/service validation and the existing task
stack reserve. The new `code_init` operation resets an active IR view while keeping
allocation ownership available for cleanup. Native adapters in the probe supply
lexer snapshots, owned strings and member construction/insertion. Arithmetic array
bounds run through the native expression parser and backend, then restore the
previous IR view.

All 18 declaration checks pass across boot and worker tasks: packed fields, union
overlap, arithmetic bounds, nested unions, comma declarations, unknown types,
duplicate members, snapshot allocation failure and malformed bound expressions.
Successful bound evaluation preserves pre-existing IR; failures restore exact heap
usage/allocation counts, task references, active controls and interrupt state.

Both x64 compiler/kernel rebuild/reboot generations passed. The complete standalone
suite passed, including the existing 44 expression/type cases, parser ownership
and recovery, instruction auditing, module rejection and pixel-exact VGA/input
checks. Dedicated lexer-state and task-symbol ownership suites also passed. Python
syntax and whitespace checks pass. This remains an 8 MiB emulated 486 development
profile; strict 386SX/DX validation is still required.

The kernel is 389456 bytes. The retained compiler image is 813304 bytes (813320
heap bytes). The temporary probe image is 276368 bytes and reclaims all 276384 heap
bytes. Compiler/probe imports remain 21/17; FileRuntime remains ABI 13/32 bytes and
CompilerProbe ABI 5/56 bytes.

See [i386-native-declaration.md](i386-native-declaration.md). This milestone parses
bodies into private class descriptors. Complete native class/function headers,
local/static/default initialization providers, original public scalar unions,
durable publication and the full interactive frontend remain open, along with
DolDoc, self-hosting and the other `PLAN.md` acceptance requirements.

## Native scalar unions and symbol headers

CompilerRuntime ABI 28 (164 bytes) adds native class and function-header joining
through the complete shared symbol core. Native controls now select the i386 target
at creation, before function argument layout. The shared header core uses existing
bit-set/clear intrinsics for its public flag instead of an unavailable helper.
The lexer supports `#help_index`, including immediate backslash continuation and
replacement, with partial strings owned by the control through error recovery.

The native fixture reads the unchanged `Kernel/Types.HH` from RedSea and parses all
six public scalar unions into a private compiler-owned symbol table. It checks
intrinsic forwarding, member names and lookup, overlapping offsets, array shapes,
cross-references and 32-bit pointer variants. Eight expressions per task compile
and execute using these types, covering scalar/pointer and member-view sizes,
narrow signed/unsigned casts, unsigned shifts and signed/unsigned division.

Those execution checks exposed a backend error: a parsed `U32` cast retained its
high word because the union wrapper shares the raw `I64` tag. Scalar code generation
now follows class forwarding when selecting width, signedness and floating-point
behavior, while retaining the union's member graph. The previously failing
`sizeof(U64)+sizeof(U64 *)+0x100000001(U32)` expression now returns 13.

All 20 symbol cases and 16 scalar-expression executions pass across boot and worker
tasks. Additional cases cover inheritance, extern completion with owned metadata,
public function headers and 32-bit argument offsets, partial class/function errors,
and help-index replacement/continuation/malformed-string recovery. Every case
restores exact heap use and allocation counts, task references, active controls,
exception state and interrupt state after full compiler-control unwind.

Both x64 compiler/kernel rebuild/reboot generations passed. The complete standalone
suite passed, including the existing 18 declaration and 44 expression/type checks,
parser ownership/recovery, instruction audits, module rejection and pixel-exact
VGA/input checks. The 235 function and 19 data cases passed, as did the floating-point,
inline-assembly, lexer-state and task-symbol suites. Python syntax and whitespace
checks pass. The guest remains an 8 MiB emulated 486; strict 386SX/DX acceptance is
still required.

The kernel is 389920 bytes. The retained compiler image is 847880 bytes (847896
heap bytes). The temporary probe image is 312872 bytes and reclaims all 312888 heap
bytes. Compiler/probe imports remain 21/17; FileRuntime remains ABI 13/32 bytes and
CompilerProbe ABI 5/56 bytes.

See [i386-native-symbol.md](i386-native-symbol.md). These parsed symbols are private
and expire with their compiler control. Durable bootstrap registration, complete
source links/metadata and function/default/initializer providers, full statement/
global integration, interactive compilation, DolDoc and native self-hosting remain
open under the full `PLAN.md` goal.

## Durable class publication

CompilerRuntime ABI 29 (168 bytes) adds `publish_classes`. Completed private class
graphs can move from parser ownership into the current task's symbol table without
changing class/member addresses. Validation collects the graph's allocation records
before changing any ownership or table contents; successful publication detaches
those records and moves the roots without further allocation. Private table storage
and unrelated parser temporaries still expire with the originating control.

A shared nonmutating `SymbolHashVisit` traversal now supplies the ownership policy
for both publication and deletion. Explicit member-list deletion still resets its
containing class/function. Borrowed type/code/static references retain their existing
lifetime contract; this API does not publish executable bodies or global data.

All 20 publication checks pass across boot and worker tasks. The success case parses
the original `Kernel/Types.HH`, publishes all six scalar unions, destroys its control,
and compiles/executes a member-size, pointer-size and narrowing-cast expression from
a fresh control. After all users are gone, detachment and ordinary symbol deletion
restore exact heap use/counts, task references, active controls, exception state and
interrupt state. Rejection cases cover destination collisions, foreign/duplicate
payload ownership, scratch OOM, the destination supplied as source, active IR,
compiler errors, current-token aliases and lexer-filename aliases. Failed transfers
preserve the private graph and allocation accounting. The filename case checks that
lexer cleanup cannot free transferred symbol storage.

Both x64 compiler/kernel rebuild/reboot generations passed. The complete standalone
suite passed the publication cases and existing symbol/scalar execution, declaration,
expression/type, parser ownership/recovery, instruction auditing, module rejection
and pixel-exact VGA/input checks. The shared symbol and task-symbol suites passed,
including nested/default/metadata/global ownership cleanup, as did all 235 function
cases. Python syntax and whitespace checks pass. The development guest remains an
8 MiB emulated 486; strict 386SX/DX acceptance remains open.

The kernel is 390456 bytes. The retained compiler image is 863464 bytes (863480
heap bytes). The temporary probe image is 344152 bytes and reclaims all 344168 heap
bytes. Compiler/probe imports remain 21/17; FileRuntime remains ABI 13/32 bytes and
CompilerProbe ABI 5/56 bytes.

See [i386-class-publication.md](i386-class-publication.md). Permanent native bootstrap
registration and a complete retained frontend environment are still required, along
with function/code/data publication, complete metadata and initializer providers,
interactive compilation, DolDoc and native self-hosting under `PLAN.md`.

## Permanent scalar bootstrap in the retained compiler

CompilerRuntime ABI 30 (180 bytes) supplies a retained frontend environment and
loads the original `C:/Kernel/Types.HH` during native boot. The shared expression,
type, declaration and class/header grammar parses its six unions; array bounds
compile and execute through the native backend. The loader validates intrinsic
forwarding, scalar widths, member views, dimensions, pointer variants and help
metadata before publishing the class graphs into the root task's symbol table.
Compiler controls, input and parser temporaries are then reclaimed.

Source links retain the original filename and declaration lines, and the help
index remains `Data Types/Simple`. The root classes survive startup, worker
inheritance and release of the temporary CompilerProbe image. The final worker
check validates their schemas and the addresses recorded by the boot load service.

All 14 bootstrap cases pass across boot and worker tasks. They cover successful
loads and duplicate rejection, malformed array bounds, truncated input, wrong
intrinsic signedness, missing input, exhausted heap and invalid help metadata.
Temporary successful loads verify all twelve source links against the original
file, then detach and delete the classes. Each case restores exact heap use and
allocation counts, active controls, task references, exception state and interrupt
state. Help metadata is checked before publication so invalid metadata cannot leave
new symbols in the task's table.

Both x64 compiler/kernel rebuild/reboot generations passed. The complete standalone
suite passed the new bootstrap cases and existing publication, symbol, declaration,
expression/type, parser ownership/recovery, instruction-audit, module-rejection and
pixel-exact VGA/input checks. The lexer-state suite passed the shared lexer backup
helper split. Python syntax and whitespace checks also pass.

The kernel is 391008 bytes. With the early boot stage it uses 393168 of the fixed
393216-byte reservation, leaving 48 bytes. The retained compiler image is 934696
bytes (934712 heap bytes); the temporary probe image is 360536 bytes and reclaims
all 360552 heap bytes. Compiler/probe imports are 23/17: the retained loader now
uses the existing `SysTry` and `SysUntry` exports for recovery. FileRuntime remains
ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes.

See [i386-scalar-bootstrap.md](i386-scalar-bootstrap.md). Complete retained
statement/global/default/static/initializer providers, executable function/code/
data publication, public compiler APIs, interactive compilation, DolDoc and native
self-hosting remain open. The 8 MiB QEMU/486 development guest does not establish
strict 386SX/DX acceptance.

## Retained expression output and function defaults

CompilerRuntime ABI 31 (184 bytes) exposes its retained frontend services for an
owned control. Its expression provider runs the shared parser, determines the
actual result type, generates native code and retains an independent copy of code
and literal data. The caller's saved IR and compilation context are restored.
Outputs remain registered until explicit release or full control unwind; execution
rejects released or foreign output pointers.

Generated software-F64 calls bind to private typed helper descriptors and are
patched against the retained runtime after final output allocation. Link records
are freed through the backend ownership routine, including their code-registry
links. Numeric results that used literal bytes no longer trigger the default-string
copy path; returned addresses into the literal pool are copied before code release.
The complete shared function-header parser now handles computed numeric defaults,
F64/integer conversion, concatenated default strings and `lastclass` through these
retained providers. Array bounds use numerical conversion of F64 results to I64.

All 34 frontend cases pass across boot and worker tasks. Coverage includes wide
and narrow integers, constant and generated F64 arithmetic/comparison, an integer
update using F64, string results, six defaults in one function header, partial
header failure after an owned string default, malformed/empty expressions,
released-code rejection, two live outputs preserving a caller IR node, exhausted
heap and F64 array bounds. Each case restores exact heap bytes/allocation counts,
active controls, task references, exception state and interrupt state.

Both x64 rebuild/reboot generations and the complete standalone suite passed,
including existing scalar bootstrap/publication, parser recovery, executable
instruction audits, module rejection and pixel-exact VGA/input checks. Python
syntax and whitespace checks pass. The kernel remains 391008 bytes, leaving 48
bytes in the fixed boot reservation including its early stage. The retained
compiler image is 955840 bytes (955856 heap bytes); the temporary probe image is
381608 bytes and reclaims all 381624 heap bytes. Compiler/probe imports remain
23/17. FileRuntime stays ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes.

See [i386-frontend-expressions.md](i386-frontend-expressions.md). Named function/
global linking, full statement/function-body/static/initializer integration,
function/code/data publication, public APIs, interactive HolyC, DolDoc and native
self-hosting remain open. This remains an 8 MiB QEMU/486 development result;
strict 386SX/DX acceptance is still required by `PLAN.md`.

## Retained native statements, functions and initializers

CompilerRuntime ABI 32 (188 bytes) appends a private JIT statement entry. The
retained environment now composes the original shared statement, function, global
and initializer cores. Code, globals, static storage and private function symbols
remain owned by the active compiler control. Per-call descriptor copies hold
temporary fixups; call-start/end identity is preserved, and recursive calls bind
to the final generated entry address. Completed private functions can call one
another without modifying published symbol relocation lists.

All 40 native cases pass across boot and worker tasks: loops, switch ranges,
goto, computed defaults, recursion, nested calls, F64 conversion, global arrays,
static state, aggregate members, indirect calls, variadics and automatic register
hints. Invalid declarations, unresolved calls/gotos, pointer-string initialization,
explicit x64 register assignments, excessive statement nesting and automatic-local
references in static initializers fail with complete resource recovery. Each case
restores exact heap bytes/allocation counts, task references, active controls,
exception state and IF. Function pointers use separate declaration and assignment,
also verified in the x64 guest; the combined declaration/initializer experiment
entered the x64 parser debugger.

Cross-compiling the shared statement parser exposed a host constant-folding gap:
the first pass resolves size placeholders from addition/subtraction but can leave
the arithmetic unfinished. The host constant evaluator now folds twice, matching
the native backend. Switch-label, array-bound and default-argument arithmetic
regressions bring the function corpus to 238 passing cases. All 19 data cases,
executable instruction audits and both x64 rebuild/reboot generations pass.

The full standalone suite passes, including the earlier frontend/scalar/publication
and recovery cases, module rejection, pixel-exact VGA and keyboard checks. The
kernel is 391016 bytes; with the 2160-byte early stage it leaves 40 bytes in the
fixed 393216-byte reservation. The retained compiler image is 1176232 bytes
(1176248 heap bytes). The temporary probe image is 396456 bytes and reclaims all
396472 heap bytes. FileRuntime remains ABI 13/32 bytes and CompilerProbe ABI 5/56
bytes. These are measured development footprints, not proof of the complete
interactive or self-hosting RAM targets.

See [i386-native-statements.md](i386-native-statements.md). Assembly/stream/try
providers, pointer-string initialization, unresolved program linking, durable
function/code/data publication, the interactive command loop, public APIs, DolDoc
and native self-hosting remain open. Strict 386SX/DX and physical-machine acceptance
remain separate from this QEMU/486, 8 MiB integration result.

## Native top-level command compilation

CompilerRuntime ABI 33 (192 bytes) appends `command`, compiling one top-level
statement through the complete shared parser. Parsing retains global scope;
an empty native function frame is introduced only for code generation. The
caller's IR, pass and AOT/misc-data state are restored. Declarations return no
command output and remain available to later statements in the same control.
Executable outputs use the existing registered execution and release providers.

The native backend now implements `IC_RETURN_VAL2` as the zero-operand operation
defined by the shared instruction table, preserving the existing EDX:EAX result.
A used end-of-expression node places its value into those registers instead of
discarding the evaluation slot without extracting the result. This closes the
statement-result path used by the original `LexStmt2Bin` convention.

All 32 native command cases pass across boot and worker tasks. They cover mixed
definitions/execution, global scope inside a block, loops, arrays, calls/recursion,
integer and F64 results, literal ownership, malformed and partially executed
source, invalid top-level return, two retained outputs and load-only behavior.
Every command preserves a caller IR sentinel; each complete unwind restores exact
heap byte/allocation counts, task references, active controls, exception state
and IF. Load-only tests verify that runtime assignment is skipped while global
initialization is retained.

Both x64 rebuild/reboot generations, all 238 function/ABI cases and the software
F64 expression suite pass, including executable instruction audits. The complete
standalone verifier passes the previous parser/function/scalar recovery checks,
module rejection, pixel-exact VGA and keyboard checks. Source and build-input
hashes match the tested working tree; syntax and whitespace checks pass.

The kernel remains 391016 bytes, leaving 40 bytes in the fixed boot reservation
with its early stage. The retained compiler image is 1184488 bytes (1184504 heap
bytes). The temporary probe image is 411320 bytes and reclaims all 411336 heap
bytes. FileRuntime remains ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes.

See [i386-native-commands.md](i386-native-commands.md). The keyboard console still
collects lines without invoking this compiler entry. Durable function/code/data
publication and error recovery that retains previous definitions, answer formatting
and public task integration, compile-time generators, assembler/try services,
DolDoc and native self-hosting remain required. This remains a QEMU/486 development
result, not strict 386SX/DX or physical-machine acceptance.

## Task-owned native program publication

CompilerRuntime ABI 34 (196 bytes) adds publication of completed private
definitions into the current task's symbol table. Symbol metadata and global data
use the existing ownership traversal; executable code, literal pools and static
storage move to a separate task-owned allocation group. Destroying the originating
compiler control now leaves published definitions usable by fresh controls.
Validation and allocation finish before any ownership changes. Name collisions
and incomplete definitions are rejected; replacement and unloading remain open.

All 24 native publication cases pass across boot and worker tasks. They cover
calls/defaults, recursion, static state, aggregates, literal pools, a resolved
borrowed alias at address zero, empty repeated publication and invalidation of old
executor handles. Later malformed input unwinds without deleting earlier
definitions. Collision, foreign/duplicate payload, allocation exhaustion, pending
IR, compiler-error and unresolved-function cases preserve the private graph and
exact allocation counts. Each complete fixture restores heap, task references,
active controls, exception state and interrupt flags.

The task-symbol suite separately verifies production storage reclamation and
parent/child lifetime retention. Both x64 rebuild/reboot generations and the full
standalone verifier pass, including previous compiler recovery tests, module
rejection, pixel-exact VGA and keyboard checks. All 1031 packaged source hashes
and eight build-input hashes match the tested tree; Python syntax and whitespace
checks pass.

The kernel is 391024 bytes; with the 2160-byte early stage it leaves 32 bytes in
the fixed 393216-byte boot reservation. The retained compiler image is 1204760
bytes (1204776 heap bytes). The temporary probe image is 442296 bytes and reclaims
all 442312 heap bytes. FileRuntime remains ABI 13/32 bytes and CompilerProbe ABI
5/56 bytes. The keyboard harness now allows 60 seconds for diagnostic startup,
matching the main boot verifier; individual input/screen deadlines remain 30
seconds. This run measured 36.245 seconds from the startup wait to readiness.
These diagnostic footprints and timings do not establish the complete interactive
or self-hosting hardware requirements.

See [i386-program-publication.md](i386-program-publication.md). Publication still
masks interrupts during validation and transfer; large-program latency needs
measurement and bounded work. Console/public API integration, full language
providers, DolDoc and native self-hosting remain required. Strict 386SX/DX and
physical-machine acceptance remain separate from this QEMU/486, 8 MiB result.

## Native submitted-source lifecycle

CompilerRuntime ABI 35 (200 bytes) appends `input`, a synchronous entry that owns
one private compiler control through parsing, command execution, publication and
unwind. It forwards results and frontend diagnostics through borrowed callbacks,
accepts load-only mode, preserves an enclosing control/IR, and publishes completed
definitions only after the submitted buffer succeeds. Earlier execution side
effects are not rolled back. Non-compiler exceptions are rethrown after cleanup,
including valid exception code zero.

Result callbacks receive a borrowed value-class descriptor alongside raw result
bits. The initial test exposed why raw types alone are insufficient: `RT_PTR`
and `RT_I64` both equal 10, so pointer depth is required before deciding to inspect
an address. Generated output metadata now retains that descriptor for synchronous
result delivery. Diagnostic callbacks also honor the existing parenthesis-warning
option/define policy and receive the standard message for enabled warnings;
suppressed parser requests are not exposed as user diagnostics.

All 22 input cases pass across boot and worker tasks. They cover 64-bit integer
and software F64 results, literal inspection, multiple results before a syntax
error, load-only suppression, callback exceptions (named and zero), failed private
definitions, invalid flags and published functions using pointers to global data.
Fresh inputs reuse those definitions after another input fails. The outer IR
sentinel survives every call, and complete fixture teardown restores exact heap,
control, task-reference, exception and interrupt state.

Both x64 rebuild/reboot generations and the full standalone verifier pass,
including prior compiler recovery, module rejection and pixel-exact VGA/keyboard
checks. All 1034 packaged source hashes and eight build-input hashes match the
tested tree; Python syntax and whitespace checks pass. The kernel remains 391024
bytes, leaving 32 bytes in the fixed reservation with the 2160-byte early stage.
The retained compiler image is 1213912 bytes (1213928 heap bytes). The temporary
probe image is 461288 bytes and reclaims all 461304 heap bytes. FileRuntime stays
ABI 13/32 bytes and CompilerProbe ABI 5/56 bytes. Diagnostic startup measured
36.950 seconds in the keyboard harness. These are development measurements, not
complete interactive or self-hosting memory/performance acceptance.

The keyboard console still collects lines without invoking this service. Moving
the console implementation into retained extended memory, wiring input/output,
answer formatting, multiline editing, public APIs, complete language providers,
DolDoc and native self-hosting remain required. See
[i386-command-input.md](i386-command-input.md). These are QEMU/486 development
results; strict 386SX/DX and physical-machine acceptance remain open.

## Retained VGA HolyC console

ConsoleRuntime ABI 1 (20 bytes) now connects keyboard submissions to native
compilation, execution, publication and recovery. The module contains the existing
VGA/text code and original font, plus command presentation and scalar formatting.
Its image remains resident; the temporary startup module calls a checked resident
display wrapper and is reclaimed as before. Initialization and display are one-shot,
and the loader validates the three service addresses before publishing them.

The console task starts after boot/worker heap-accounting diagnostics finish.
It has a 64 KiB stack and borrows the shared kernel heap, allowing compilation to
use available memory rather than a small fixed private arena. Input takes its heap
from the current task's symbol scope. The first integration run correctly rejected
a mismatched heap before parsing; that exposed and corrected the caller wiring
without weakening compiler ownership validation.

All 25 hardware-keyboard command checks pass: native evaluation, four-byte pointers
and eight-byte I64, globals/functions retained between submissions, static state,
syntax-error recovery, integer extrema, pointers and F64 boundary values. Together
with editing, cancellation, wrapping, tabs and scrolling, the harness submits 88
lines and compares every VGA pixel at each checkpoint. These are source commands
compiled inside the native guest, not host-generated answers.

Scalar answers use decimal integers, hexadecimal addresses and integer-only F64
formatting with exact expansion and nearest-even rounding to 17 significant
digits. Tests include NaN/Inf, signed zero, the smallest subnormal, largest finite
value and rounding-sensitive fractions. Wide-integer testing exposed a signed
radix in the unsigned formatter; both operands now remain U64. The tests also
preserve the shared parser's treatment of high-bit integer literals as U64, using
an explicit I64 cast for the minimum-signed case.

Both x64 rebuild/reboot generations and the full standalone verifier pass,
including all prior compiler probes, executable instruction audits and module
rejection/reclamation checks. Console target, import and version corruption are
rejected before startup uses the module. All 1038 packaged source hashes and eight
build-input hashes match the tested tree; Python syntax and whitespace checks pass.

The boot kernel is 373768 bytes, down 17256 bytes. With the 2160-byte early stage it
leaves 17288 bytes in the unchanged 393216-byte reservation. The retained console
image is 39440 bytes (39456 heap bytes); its planar buffer remains 153600 bytes.
CompilerRuntime remains ABI 35/200 bytes, with a 1213912-byte image (1213928 heap
bytes). FileRuntime remains ABI 13/32 bytes. CompilerProbe remains ABI 5/56 bytes,
with a 461288-byte image and complete reclamation of its 461304 heap bytes.
Diagnostic startup measured 37.151 seconds in the keyboard harness.

See [i386-console-runtime.md](i386-console-runtime.md). Full-frame VGA uploads and
worst-case numerical rendering need vintage-hardware latency work. Multiline
editing, public APIs, complete language/runtime providers, CPU-fault/debugger
integration, DolDoc, startup-source execution and native self-hosting remain open.
This initial console passes on QEMU/486 with 8 MiB; it does not establish complete
interactive memory/performance acceptance or strict 386SX/DX/physical support.


## Bounded VGA console updates

The console now merges changed text rows into a pending interval and uploads only
those scanlines. A normal character or backspace uploads 2560 bytes, compared with
153600 for a full screen. Clean events skip presentation; initialization and
scrolling invalidate the full screen. The 32-byte private text record clears its
interval only after a successful upload. VGA rejects invalid ranges and wrapping
buffer addresses before hardware access. No additional framebuffer or allocation
is required. See [i386-console-runtime.md](i386-console-runtime.md).

Both x64 rebuild/reboot generations, the targeted VGA suite and the full standalone
verifier pass. The VGA suite checks all 307200 pixels after full and partial
uploads, empty ranges, invalid requests and preserved pending state. The keyboard
harness retains all 25 native command and 88 submitted-line checks, with exact
pixels at every checkpoint, and verifies single-row edits and full-scroll updates.
It records 544 uploads spanning 2731 text rows, or 6991360 requested payload bytes.
These are span-based counts, not measured hardware traffic or latency.

All 1040 packaged source hashes and eight build-input hashes match the tested
files. The boot kernel remains 373768 bytes, with 17288 bytes spare after the
2160-byte early stage in its fixed reservation. ConsoleRuntime remains ABI 1/20;
its image is now 44688 bytes (44704 heap bytes), and its framebuffer remains
153600 bytes. CompilerRuntime, FileRuntime and CompilerProbe versions are unchanged.
Startup measured 37.403 seconds on QEMU/486 with 8 MiB. Full-scroll optimization,
strict 386SX/DX and physical-machine latency checks, complete language/public API
integration, DolDoc and native self-hosting remain open.


## Native source startup in the console task

The retained console now reads and executes `/Kernel/I386/StartOS.HC` from RedSea
before its first prompt. It uses the native command-input service and the console
task's symbol/file context, after worker heap-accounting diagnostics finish.
The default source supplies `NULL`, `TRUE` and `FALSE`; custom source can execute
commands and retain functions, globals and macros for keyboard submissions.
The early display module remains cross-compiled and is reclaimed as before.
The startup-complete diagnostic now follows source execution and prompt display.

Changing only source bytes in a disk copy proves native compilation and startup
execution: a macro initializes a global, a function increments it during startup,
and subsequent keyboard calls reuse both the function and its state. Two further
boots verify syntax-error recovery and a missing file. A failed source's private
global is absent and can be declared afresh, while an earlier preprocessor define
remains visible according to the existing immediate define-table behavior. All
three cases compare every displayed pixel and verify that execution leaves their
disks unchanged. Together they run ten follow-up keyboard commands. The ordinary
keyboard suite now checks 27 commands and 90 submitted lines, including the default
startup macros.

The custom source exposed a lexer ownership restriction: macro expansion inside a
global initializer could not release its exhausted child file while a parser save
point borrowed the parent. `I386LexFilePop` now validates each native snapshot and
rejects release only when a snapshot borrows that file (or has invalid ownership).
The snapshot layout is unchanged. The native lexer suite verifies parent snapshot
restoration, nested pins, invalid owners, preserved interrupt state and complete
reclamation. Both x64 rebuild/reboot generations also pass.

The boot kernel is 374760 bytes, leaving 16296 bytes after the 2160-byte early stage
in the fixed reservation. ConsoleRuntime remains ABI 1/20, with a 45480-byte image
and 45496 retained heap bytes. CompilerRuntime remains ABI 35/200, FileRuntime ABI
13/32 and CompilerProbe ABI 5/56; their image sizes are unchanged. The source tree
has 1041 packaged files. The complete standalone verifier passes, including module
rejection/reclamation and executable instruction audits. All 1041 source hashes and
eight build-input hashes match the tested files. The default startup-to-prompt
measurement is 37.199 seconds on QEMU/486 with 8 MiB; this is development evidence,
not vintage-hardware performance acceptance. Python syntax and whitespace checks
also pass. See [i386-console-runtime.md](i386-console-runtime.md).

This is native console-source startup, not the complete original StartOS/DolDoc
workflow or self-hosting. Native source editing/writing, complete public APIs and
language providers, execution interruption, CPU-fault/debugger integration and
strict 386SX/DX/physical-machine acceptance remain open.


## Native JIT string-pointer initialization

The shared initializer now permits i386 string-pointer initialization when parsing
native JIT source. It uses the existing expression executor and misc-data lifetime:
the initialized value points into registered literal storage, the scalar store is
four bytes, and successful program publication transfers that storage to the task.
No compiler/console service ABI changes are required. The AOT path remains rejected
until stored pointers have a target-address relocation contract for both runtime
modules and the flat cross-built boot image.

The native statement corpus now has 26 cases per boot/worker phase. String cases
cover empty strings, concatenation with embedded NULs, writable storage, signed-byte
pointers, globals, statics, aggregate members and inferred pointer arrays. A failed
source after string allocation must unwind completely. Publication tests retain
initialized global/static strings across control destruction, read and mutate them
from later inputs, then verify that a failed later string declaration leaves the
earlier data usable. Existing collision, invalid-ownership and allocation-failure
publication checks now exercise these literal pools too; fixture teardown restores
exact heap, control, task-reference, exception and interrupt state.

All 38 keyboard command checks pass, including string declarations, mutation,
static state and failed-input recovery; the harness submits 101 lines and compares
every displayed pixel at its checkpoints. Both x64 rebuild/reboot generations and
the 19-case cross-compiler data suite pass. The latter retains its explicit AOT
string-pointer rejection, rather than allowing a compiler-host address or an
eight-byte patch to enter a four-byte target field.

The boot kernel remains 374760 bytes with 16296 bytes spare in its reservation.
CompilerRuntime remains ABI 35/200; its image is 1214040 bytes (1214056 heap bytes).
CompilerProbe remains ABI 5/56; its image is 465040 bytes (465056 temporary heap
bytes). ConsoleRuntime and FileRuntime image sizes and ABIs are unchanged.
The expanded diagnostic startup measured 42.477 seconds on QEMU/486 with 8 MiB;
this includes the larger probe corpus and is not vintage-machine latency evidence.
The full standalone verifier passes, including source-startup variants, module
rejection/reclamation and executable instruction audits. All 1041 source hashes and
eight build-input hashes match the tested files, and the temporary probe reclaims
all 465056 heap bytes. Python syntax and whitespace checks pass. See
[i386-initializer-parser.md](i386-initializer-parser.md).

AOT relocation, full language/runtime providers, public APIs, DolDoc, native
self-hosting and strict 386SX/DX/physical-machine acceptance remain required.

## Complete shared public task and CPU layouts

`KernelA.HH` now includes the complete original records from shared task, CPU,
job-control and window-scroll headers. The extraction retains every public task
and CPU field, including the wide saved-register image, document/window state,
exceptions, answers, compiler controls, jobs, callbacks and user data. An
eight-byte slot for the dying-task queue's last pointer preserves its wake-field
overlap on both architectures; task and CPU tail alignment is now explicit.

The original x86-64 task metadata was captured before extraction. The rebuilt
guest preserves all 105 task member entries, their order, offsets, sizes and
pointer shapes, and the 1192-byte total size. Supporting x86-64 record sizes are
also checked. The committed fixture records the corresponding i386 expectations;
the native probe asserts all 103 unambiguous task offsets, the dying-task overlap,
and sizes of 992 bytes for `CTask`, 232 for `CCPU`, 24 for `CJobCtrl` and 32 for
`CWinScroll`. Boot and worker executions round-trip pointers and wide values,
call a task callback, check a guard after the allocation and reclaim the records.

Both x86-64 rebuild/reboot generations and `tools/check-task-layout.py` pass.
All 56 keyboard checks and 119 submitted lines still match exact VGA pixels.
The live kernel remains 380632 bytes with 8488 bytes spare after its 4096-byte
prefix. CompilerRuntime remains ABI 35/200 with 1242576 image bytes and 1242592
retained heap bytes. CompilerProbe remains ABI 5/56 with 537032 image bytes and
537048 temporary heap bytes, reclaimed after diagnostics. ConsoleRuntime and
FileRuntime are unchanged. Diagnostic startup measured 65.024 seconds on QEMU/486
with 8 MiB; this is not a vintage-hardware performance acceptance result.

The live scheduler still uses its private task/CPU records. Adopting the shared
records, connecting their public state and services, and installing correctly
typed `Fs`/`Gs` getters remain required. The fixture cross-compiles the headers;
it does not prove their full native JIT loading or cross-input completion.
See [shared task records](i386-task-records.md).

The complete standalone verifier passes, including source-startup variants,
module rejection/reclamation and executable instruction audits. All 1052 source
hashes, eight native build-input hashes and the disk hash match the tested files.
The separate x86-64 layout manifest also matches its source and three test-input
hashes. Python syntax and whitespace checks pass. Full public service adoption,
DolDoc, native self-hosting and strict 386/physical-machine acceptance remain open.

## Stored string pointers in cross-compiled modules

The shared initializer now emits four-byte i386 AOT string-pointer relocations.
Version-3 modules describe a zero-filled data slot and a module-local data target;
version-2 modules keep their existing format. Validation rejects code targets,
slots outside a single data range, overlapping slots, nonzero placeholders and
invalid version/record combinations before the loader writes anything. This
supports strings in globals, statics, packed records and inferred pointer arrays.
Symbolic stored function/import pointers and general executable initializers
remain open.

`I386LoadBoundAt` separates the future execution address from the writable output
buffer. Existing runtime loading APIs use the actual allocation address. The host
flat-image linker requires an explicit address when stored pointers are present,
even when its own heap happens to lie below 4 GiB. The BIOS stage now has a fixed
4096-byte prefix and links the kernel at `0x11000`; the build verifies this placement
and the flattened pointer values. The kernel ready message and retained console
title exercise fixed-address and runtime-allocation relocation on every boot.
Images containing stored pointers must be reloaded when moved.

The boundary tests also exposed a loader range-check defect: pointer addition can
retain a wide intermediate instead of wrapping at the target pointer width. The
loader now compares the actual buffer base against an explicit address-space
limit. Invalid actual or future destinations fail before output mutation.

The data corpus passes 27 cases, including imported pointer globals in both module
orders. The native loader passes 37 cases, including simultaneous allocations,
address reuse, source-buffer destruction and malformed pointer records. The module
validator passes 46 cases. All 238 compiler function cases and resident function/data
binding checks pass, as do both x64 compiler/kernel rebuild generations. The binding
test's boot transfer grows to 160 KiB, ending at `0x38000` below its `0x40000` heap.

The kernel is 380632 bytes; the fixed 4096-byte early stage leaves 8488 bytes in
the existing 393216-byte reservation. CompilerRuntime remains ABI 35/200 with a
1214720-byte image and 1214736 retained heap bytes. ConsoleRuntime remains ABI 1/20
with a 45488-byte image and 45504 retained heap bytes. CompilerProbe remains ABI
5/56 at 465040 image bytes; FileRuntime remains ABI 13/32 at 125168 image bytes.
All 38 keyboard command checks and 101 submitted lines pass with exact VGA pixels.
Diagnostic startup-to-prompt measured 44.030 seconds on QEMU/486 with 8 MiB; this
is development evidence, not physical-386 performance acceptance.

The complete standalone verifier passes, including source-startup variants,
module rejection/reclamation and executable instruction audits. All 1041 source
hashes and eight build-input hashes match the tested files. Python syntax and
whitespace checks pass. See [i386-modules.md](i386-modules.md) and
[i386-module-bindings.md](i386-module-bindings.md). Native module generation,
complete language/public runtime providers, DolDoc, self-hosting and strict
386SX/DX/physical-machine acceptance remain required.

## Native private forward function calls

The native JIT now compiles calls to private forward declarations and patches them
when their definitions arrive in the same compiler control. This includes mutual
recursion and software-F64 arguments/results. Pending records own their call-site
location and a snapshot of the declared return/argument classes and calling
convention. Resolution rejects incompatible definitions before publishing code.
The backend's temporary import records are still reclaimed after generation;
private pending records remain in the parser's allocation ledger.

Until resolution, a pending call targets the existing compiler-exception helper.
An early call therefore raises a recoverable compiler exception, while unrelated
constant evaluation can proceed during later function definitions. Output release
retires its pending patches, and control unwind frees the remaining records.
Task publication rejects outstanding fixups. Resolved callees and callers retain
the existing task-storage lifetime; no compiler service ABI changes are required.
Cross-control unresolved linking, module imports and definition replacement/unload
remain separate work.

The statement corpus now has 34 cases per boot/worker phase. New cases cover
multiple forward calls, mutual recursion, F64, parameter/return mismatch rejection,
constant array bounds in a later definition and failed source with pending work.
The 14 submitted-input cases include load-only discard of an unresolved command,
subsequent definition and execution, early-call recovery and syntax-error unwind.
The publication corpus now retains a resolved forward call across control
destruction and checks it from fresh controls after later failed input.

All 42 keyboard command checks and 105 submitted lines pass with exact VGA pixels,
including later use of a forward-defined function and recovery after rejecting an
unresolved program. Both x64 compiler/kernel rebuild generations pass. The kernel
remains 380632 bytes with 8488 bytes spare after the fixed stage prefix.
CompilerRuntime remains ABI 35/200: 1222824 image bytes and 1222840 retained heap
bytes. CompilerProbe remains ABI 5/56: 470336 image bytes and 470352 temporary heap
bytes. ConsoleRuntime and FileRuntime sizes and ABIs are unchanged. Diagnostic
startup-to-prompt measured 49.653 seconds on QEMU/486 with 8 MiB; the expanded corpus
is not a vintage-machine performance acceptance result.

The complete standalone verifier passes, including startup source variants, module
rejection/reclamation and executable instruction audits. All 1041 source hashes
and eight build-input hashes match the tested files. Python syntax and whitespace
checks pass. See [i386-native-statements.md](i386-native-statements.md) and
[i386-program-publication.md](i386-program-publication.md). Full public runtime
integration, assembler/stream/try providers, DolDoc, native self-hosting and strict
386SX/DX/physical-machine acceptance remain required.

## Native resident declarations and exception calls

Native `extern` declarations now use visible system-export addresses while owning
only their ordinary HolyC metadata. The frontend records each borrowed function
or data binding and validates its export identity/address before publication.
A declaration can coexist with its underlying system export in a root table;
other destination definitions still collide. Registered frontend outputs retain
the existing executable-storage path. Resident code/data and export records are
never transferred to, or freed with, the compiler control.

The new resident probe runs seven cases during boot and from the worker task.
It publishes declarations, destroys their original control, and uses them from
fresh controls, including generated `try/catch` against `SysTry`, `SysUntry` and
`throw`. A temporary data export refers to the active task's catch flag. Changed
function/data addresses, changed or removed exports and conflicting destination
symbols reject publication without changing heap/storage counts; restoring them
permits the same control to publish. A declaration-only input retains no executable
storage. Teardown removes all owned symbols and temporary exports before the probe
module is unloaded and restores heap, control, task-reference and interrupt state.

Disk-backed `StartOS.HC` now publishes `StrCmp`, `SysTry`, `SysUntry` and `throw`
declarations before the prompt. Public `CTask`/`Fs` views, complete original
runtime headers, automatic provider lifetime tracking and unload/replacement rules
remain open. The export table supplies addresses rather than function signatures;
declarations retain the original HolyC responsibility for the resident ABI.
See [i386-resident-declarations.md](i386-resident-declarations.md).

The expanded diagnostic corpus exceeded the old 60-second observation cutoff in
a repeated boot while still advancing through input cases. Native boot/rejection
and keyboard-startup observation now allow 90 seconds; command and screen-response
deadlines remain unchanged. This is a diagnostic-run allowance, not a relaxation
of the vintage-machine performance goals. The keyboard driver harness also maps
comma and apostrophe to their QEMU key names for multi-argument/character-literal
source submissions.

All 47 keyboard command checks and 110 submitted lines pass with exact VGA pixels,
including `StrCmp`, a published function containing `try/catch`, explicit `throw`
and successful execution afterward. Both x64 compiler/kernel rebuild generations
pass. The kernel remains 380632 bytes, leaving 8488 bytes after its fixed 4096-byte
stage prefix. CompilerRuntime remains ABI 35/200 with a 1232440-byte image and
1232456 retained heap bytes. CompilerProbe remains ABI 5/56 with a 487688-byte image
and 487704 temporary heap bytes. ConsoleRuntime and FileRuntime sizes and ABIs are
unchanged. The measured diagnostic startup-to-prompt time is 53.022 seconds on
QEMU/486 with 8 MiB; this remains development evidence, not strict vintage-hardware
performance acceptance.

The complete standalone verifier passes, including source-startup variants, module
rejection/reclamation and executable instruction audits. All 1043 source hashes
and eight build-input hashes match the tested files. Python syntax and whitespace
checks pass. Full public runtime/task integration, assembler/stream providers,
DolDoc, native self-hosting and strict 386SX/DX/physical-machine acceptance remain
required.

## Native intrinsic publication and console interrupts

The native frontend now publishes supported `_intern` declarations as owned
metadata whose `exe_addr` holds an IR opcode. These declarations do not own
executable storage or borrow a resident export. Signature validation checks
argument/result types and pointer depth separately: TempleOS's `RT_PTR` shares
the `RT_I64` value, so raw type alone cannot distinguish an address from a wide
integer. Invalid opcodes and incompatible import, relocation and function flags
reject publication before any ownership transfer.

The startup source includes 32 canonical public intrinsic declarations, matching
the original header signatures and opcode constants. Boot and worker probes each
validate and publish 34 declarations, including private FS/GS getters, reject 12
metadata mutations, and run 14 cases from fresh compiler contexts. These cover
wide numeric/bit operations, software F64, flags, and task/CPU/frame addresses.
Removing the symbols restores tracked heap, task-reference, compiler-control,
storage and interrupt state. Public `CTask`/`CCPU` layouts remain unfinished; the
private getter fixtures do not replace their APIs.

The new keyboard flags check exposed a console integration bug: fresh tasks start
with IF clear, and the console never enabled interrupts. A focused first-command
VGA check confirmed this before any exception recovery. Keyboard input could
still arrive during root idle, hiding disabled interrupts while commands ran.
The initialized console now enables interrupts before source startup. Both its
early flags check and the check after syntax/exception recovery pass.

All 52 keyboard commands and 115 submitted lines pass with exact VGA pixels.
Both x86-64 rebuild/reboot generations pass. The kernel remains 380632 bytes with
8488 bytes spare after its 4096-byte stage prefix. CompilerRuntime remains ABI
35/200, with a 1239720-byte image and 1239736 retained heap bytes. CompilerProbe
remains ABI 5/56, with a 513464-byte image and 513480 temporary heap bytes, fully
reclaimed after diagnostics. ConsoleRuntime remains ABI 1/20, with a 45528-byte
image and 45544 retained heap bytes; its framebuffer is still 153600 bytes.
FileRuntime is unchanged. Diagnostic startup-to-prompt measured 64.631 seconds
on QEMU/486 with 8 MiB; no strict 386 performance claim follows from this result.
See [intrinsic publication](i386-intrinsic-publication.md).

The complete standalone verifier passes, including all source-startup variants,
module rejection/reclamation and executable instruction audits. All 1046 source
hashes, eight build-input hashes and the disk-image hash match the tested files.
Python syntax and whitespace checks pass. Full public task/runtime integration,
remaining language providers, DolDoc, native self-hosting and strict 386SX/DX and
physical-machine acceptance remain required.

## Native opaque class dependencies

Native publication now transfers ordinary empty forward class declarations and
their metadata to the task scope without creating executable storage. Pointer
users remain valid after the defining compiler control is destroyed. Publication
rejects unfinished classes used as values or base classes, and checks the empty
descriptor shape before accepting an opaque declaration.

Top-level class and extern-class statements now dispatch through the existing
type-service class callback, matching nested type declarations. Previously they
bypassed the native frontend's ownership boundary. The host callback still uses
the original shared parser. Completing an already-published opaque declaration
remains rejected before parsing its definition; private declarations completed
within one input preserve pointer identity and can form mutually linked records.
A transaction for completion across inputs remains required.

Seven cases run on both boot and worker tasks. They cover ordinary publication,
three malformed-descriptor rejections with successful retry after restoration,
incomplete value/base rejection, and same-input completion followed by real
pointer/member access. Failed cross-input completion preserves the published
class and existing users. Each case restores heap usage, allocation counts,
compiler controls, task references, retained storage and interrupt state.

All 56 keyboard checks and 119 submitted lines pass with exact VGA pixels,
including separate submissions that declare an opaque dependency, retain a
12-byte record containing its four-byte pointer, and store/read an I64 member.
Both x86-64 rebuild/reboot generations pass. The kernel remains 380632 bytes,
with 8488 bytes spare after the fixed 4096-byte stage. CompilerRuntime remains
ABI 35/200, with a 1242576-byte image and 1242592 retained heap bytes. The temporary
CompilerProbe remains ABI 5/56, with a 530760-byte image and 530776 reclaimed heap
bytes. ConsoleRuntime and FileRuntime are unchanged. Diagnostic startup-to-prompt
measured 66.288 seconds on QEMU/486 with 8 MiB; this is development evidence.
See [opaque class dependencies](i386-opaque-classes.md).

The complete standalone verifier passes, including source-startup variants,
module rejection/reclamation and executable instruction audits. All 1047 source
hashes, eight build-input hashes and the disk-image hash match the tested files.
Python syntax and whitespace checks pass. Public task/CPU migration, completion
transactions across inputs, the complete language/document environment, native
self-hosting and strict 386SX/DX/physical-machine acceptance remain required.


## Live public task and CPU prefixes

The native scheduler now embeds the complete shared `CTask` and `CCPU` records
as bases of `CI386Task` and `CI386Cpu`. Private context and scheduler fields follow
the 992-byte and 232-byte public prefixes. Task identity/signature and CPU binding
are initialized by the scheduler/platform; reaping clears the task identity.
Exception state, symbol tables and active compiler-control links use their public
fields without duplicate ownership. Ready queues remain private and distinct from
public task-family and all-task links.

The catch flag now uses the public one-byte `Bool`, with adjacent answer-field
canaries in native resident-binding probes. Captured frame pointers are explicitly
zero-extended into the public eight-byte diagnostic field. Typed private FS/GS
probes inspect the live root and worker records, alongside the existing full
layout, callback, wide-value and allocation-guard checks.

CompilerRuntime, FileRuntime, CompilerProbe and ConsoleRuntime advance to ABI
36/200, 14/32, 6/56 and 2/20 respectively (version/bytes). The interface sizes stay
unchanged, but old task offsets are incompatible. Loader rejection fixtures now
substitute the previous version tags explicitly. See
[shared task records](i386-task-records.md).

Both x86-64 rebuild/reboot generations and all 105 original task-field layout
comparisons pass. The full standalone verifier passes: boot/worker probes,
source-startup variants, module rejection/reclamation and all 56 keyboard commands
(119 submitted lines) with exact VGA output. The kernel is 382368 bytes, leaving
6752 bytes after the fixed 4096-byte stage in the 384 KiB reservation.
CompilerRuntime uses 1242576 image bytes and 1242592 retained heap bytes;
FileRuntime uses 125168/125184. CompilerProbe uses 539248 image bytes and fully
reclaims its 539264 temporary heap bytes. ConsoleRuntime uses 45536/45552; its
framebuffer remains 153600 bytes. Diagnostic startup measured 66.126 seconds on
the QEMU/486 8 MiB development profile. All 1053 source hashes, eight native
build-input hashes, three layout-test inputs and the disk-image hash match the
tested files. These measurements do not establish strict 386 performance.

Focused `test-i386.py` regressions also pass for `--tasks`, `--except-tasks`,
`--task-symbols`, `--input`, `--messages` and `--ata-tasks`, including their
executable instruction audits. These cover owned task creation/destruction,
catch-time context switches, inherited symbol lifetime, IRQ-driven wakeups,
message delivery and cooperative disk transactions with the enlarged records.
Python syntax and whitespace checks pass.

Public header loading and cross-input class completion, the complete heap/stack/
exception and task-family APIs, DolDoc, native self-hosting and strict 386 hardware
acceptance remain unfinished. The complete records and private getter probes do
not establish those services or expose public `Fs`/`Gs` through startup source.

## Native class completion transactions

Ordinary forward classes can now be completed across source submissions in the
owning task's symbol scope. The native frontend builds a private definition and
uses an optional expression-service class view for type/member lookup and emitted
types. Publication validates the target again, then transfers the member graph
into the stable public descriptor. Existing pointer variants retain their
addresses. Private class, global, callback and function references are reconnected
to that identity, including forward function fixups and local type indexes.
A nested successful completion invalidates an older pending definition.

Completion rejects earlier objects, members, bases and defined functions whose
layout already used the incomplete type by value. Such storage cannot be resized
retroactively; pointer uses and inactive forward signatures remain valid. Failed
parsing, abandoned inputs and allocation failure preserve the old layout and
reclaim private state. Empty classes also retain a valid member-list sentinel.
The canonical name allocation remains live for generated `lastclass` arguments.
See [class completion](i386-class-completion.md).

CompilerRuntime, FileRuntime, CompilerProbe and ConsoleRuntime advance to ABI
37/200, 15/32, 7/56 and 3/20 (version/bytes). Their outer record sizes are unchanged;
expression-service providers now initialize the optional class-view callback.
Host and isolated parser providers use the original descriptors through a null
callback. Native completion uses the compiler control's private view.

Both x86-64 rebuild/reboot generations and all 105 original task-field layout
comparisons pass. Fourteen completion cases run in each native task phase. The
full standalone verifier passes, including source-startup variants and previous
module-version rejection/reclamation. All 63 keyboard commands and 126 submitted
lines pass with exact VGA pixels; QMP input now maps shifted `<`/`>` punctuation
for pointer-member expressions. Diagnostic startup measured 72.393 seconds on
the QEMU/486 8 MiB development profile.

The kernel remains 382368 bytes, leaving 6752 bytes after the 4096-byte stage in
its reservation. CompilerRuntime uses 1271600 image bytes and 1271616 retained
heap bytes. CompilerProbe uses 576248 image bytes and fully reclaims its 576264
temporary heap bytes. FileRuntime remains 125168/125184 and ConsoleRuntime
45536/45552 (image/retained heap bytes); the framebuffer remains 153600 bytes.
All 1055 source hashes, eight native build-input hashes, three layout-test input
hashes and the disk-image hash match the tested files. These measurements do not
establish strict 386 performance or the complete low-memory document workflow.

Focused regressions pass for functions (238 cases), data, inline assembly and
task symbol lifetime, including their instruction audits. Python syntax and
whitespace checks pass.

Actual public-header loading, include-guard behavior after failed input, remaining
language providers, public kernel services, DolDoc, native self-hosting and strict
386 hardware acceptance remain required. This transaction does not roll back
already executed command side effects or the existing immediate macro publication.


## Native public task/CPU header loading

The console now compiles `/Kernel/I386/PublicKernel.HH` before user startup. It
loads the actual shared task, CPU, hash, job-control and scroll records and
publishes typed `Fs`/`Gs`. This is a separate input, so missing or invalid user
startup does not remove the public interfaces. The complete public kernel-service
contract remains unfinished; record access is not proof of every field's service
semantics. See [native public headers](i386-public-headers.md).

`I386_INPUT_ATOMIC_DEFINES` makes header macros and declarations commit together.
A private macro table belongs to the compiler control, covering both ordinary
unwind and task cleanup. Failure preserves existing guards and types; repeated
macros keep lookup order. Ordinary input retains immediate macro publication.
Staged class completion also preserves its prior diagnostic use count. Program
publication still rejects a missing parent link when no private macro table exists;
a regression checks rejection without mutation and successful retry after repair.

An optional lexer directive callback connects native `#assert` to expression
compilation and execution. False assertions warn as in the original system;
invalid expressions fail. Recursive token reads reuse their final string's
tracking record. The real-header probe accepts the existing count-only unused
forward warning for `CCPU` while requiring no layout-assertion diagnostic.

CompilerRuntime, FileRuntime, CompilerProbe and ConsoleRuntime now use ABI
38/200, 16/32, 8/56 and 4/20 (version/bytes). Their outer record sizes remain
unchanged. Lexer service records add the optional parser-directive callback;
providers initialize it explicitly. The console import set adds `KernelHex` for
header memory accounting.

Both task phases pass real-header failure/retry, stable class identity, repeated
include and live-field checks, followed by 108 native layout assertions and full
reclamation. The assertions cover 103 named non-padding task offsets, four record
sizes and the dying-task wake offset. The independent x86-64 layout fixture
preserves all 105 original task fields. Both x86-64 rebuild/reboot generations
pass. The command-input corpus now has 22 cases in each native phase.

Focused regressions pass for conditional preprocessing, macro definitions, token
streams, task-symbol lifetime, RedSea reads and functions (238 cases). The macro
and token runners now allow 320 KiB of loaded test code below their existing
`0x60000` heap, preserving explicit load/heap separation. The expanded diagnostic
boot exceeded its former 90-second test allowance during worker checks; boot
verification now allows 180 seconds while keyboard response deadlines stay fixed.

The native kernel is 382512 bytes, leaving 6608 bytes after its 4096-byte stage
in the existing reservation. CompilerRuntime uses 1284344 image bytes and
1284360 retained heap bytes. CompilerProbe uses 608296 image bytes and reclaims
its 608312 temporary heap bytes. FileRuntime remains 125168/125184;
ConsoleRuntime uses 46680/46696 (image/retained heap bytes). The framebuffer is
153600 bytes, and the console's public headers retain 38488 additional heap bytes.
These measurements do not establish strict 386 performance or the complete
low-memory document workflow.

Public heap/stack/exception and task-family services, remaining language providers,
DolDoc, native self-hosting and strict 386 hardware acceptance remain required.

Final full native verification passes, including custom startup, syntax-error and
missing-startup recovery, and all startup/runtime/file/probe/console module
rejection and reclamation cases. The keyboard suite executes 78 commands across
141 submitted lines with exact VGA pixels at every checkpoint. Its diagnostic
startup takes 124.211 seconds on the QEMU/486 development profile; this is not a
physical 386 performance measurement. All 1057 source hashes match the native,
x86-64 rebuild and task-layout results. The eight native build inputs, three
layout inputs and final disk hash also match. Python syntax and staged whitespace
checks pass.


## Public native stack ownership

The scheduler's live stack bounds now come from the original shared `CTaskStk`.
Spawned tasks place its 20-byte prefix immediately before the eight-byte-aligned
stack payload in the task's owned allocation. The optional private heap follows
the stack and is excluded from its public bounds. Reaping clears `task->stk`;
the owning allocation is freed from another stack after task cleanup. The boot
reservation contains its descriptor at `0x88004`, leaving 32744 usable bytes
starting at `0x88018`. No independent private stack-bound fields remain.

Exception registration and dispatch, caller walking and the compiler's 4096-byte
stack-reserve check use those public bounds. Native `GetRSP` now implements the
original pointer-returning intrinsic and is declared by both standalone CPU and
interactive intrinsic headers. Public-header probes compile live stack access and
stack-pointer range checks in boot and worker phases. These are actual contiguous
stacks, not descriptors pointing at unrelated payloads. Stack growth, full public
saved-register synchronization and the complete debugger contract remain absent.
See [public stack ownership](i386-public-stacks.md).

Module versions are CompilerRuntime 39/200, FileRuntime 17/32, CompilerProbe 9/56
and ConsoleRuntime 5/20. The private task layout changed when its duplicate bounds
were removed, while the public layouts and outer service-table sizes are stable.

Two x86-64 rebuild/reboot generations pass, and all 105 original x86-64 task fields
retain their layouts. Focused task, exception-record, exception-context,
exception-runtime, exception-task, function (238 cases) and task-symbol suites
pass. The exception-record fixture now initializes compiler-control queue heads
before testing reaping. Exception record/context/runtime runners permit 128 KiB
of test code, below their existing heap arenas; their previous 64 KiB allowance
was insufficient for the expanded records and helpers.

The initial full native boot passes on the 8 MiB QEMU/486 development profile.
Both phases pass public stack checks and 108 public layout assertions. The kernel
is 384232 bytes, leaving 4888 bytes with its 4096-byte stage in the existing
reservation. CompilerRuntime is 1285432 image/1285448 retained heap bytes;
CompilerProbe is 610688 image/610704 temporary heap bytes, fully reclaimed.
FileRuntime and ConsoleRuntime remain 125168/125184 and 46680/46696 respectively.
Public headers retain 38488 heap bytes; the framebuffer remains 153600 bytes.
Strict 386/no-387 and physical-hardware acceptance, the full document workflow,
public heap services and native self-hosting remain required.

Final full native verification passes: 81 keyboard commands across 144 submitted
lines, exact VGA pixels at every checkpoint, custom startup, syntax-error and
missing-file recovery, and all incompatible module rejection/reclamation cases.
The diagnostic keyboard boot takes 125.579 seconds on QEMU/486; this does not
measure physical 386 performance. All 1057 OS source hashes match the native,
x86-64 rebuild and layout results. The eight native build inputs, three layout
inputs and final disk hash also match. Python syntax and staged whitespace checks
pass.


## Shared public memory records and native allocation core

The six original allocation, block, range, pool and heap-control records now live
in shared headers. All 43 captured x86-64 member layouts are preserved. The native
policy keeps explicit integer widths and the 1024-byte heap hash while shrinking
pointers. Normal `CMemUsed`/`CMemUnused` records are 12 bytes, `CMemBlk` is 16,
`CMemRange` 28, `CBlkPool` 1276 and `CHeapCtrl` 1088. The original debug record
source is retained, but the native core currently uses normal headers only.

The native internal core uses actual public lists and counters for page bins,
heap-owned blocks, small free fragments and size bins. Payloads remain eight-byte
aligned by placing their 12-byte headers at four modulo eight. Page-backed large
objects put their used header at offset 20 and payload at offset 32. No shortened
public records or bootstrap-heap casts are involved. See
[public memory](i386-public-memory.md) for ownership, alignment and remaining work.

The heap fixture passes 49 native layout checks, page-bin reuse, larger-block
fallback, small-bin boundary cases, two owners, 1024 allocation/free rounds with
payload/accounting checks, and three bulk teardown/reinitialization cycles with
live allocations. Its arena is 256 KiB below the boot stack. The fixture loader
now permits 128 KiB of code below its existing first arena. Both x86-64 rebuild
and reboot generations pass; memory and task layout checks preserve all 43 and
105 original fields respectively.

The existing arena test exposed reliance on pointer-expression wraparound when
rejecting a range crossing 4 GiB. The arena allocator now checks the wide sum
explicitly. Both crossing and exact-end boundary cases reject before mutation.
This fix applies to the running kernel's bootstrap allocator as well.

The new allocation core is not yet connected to live public task heaps or exposed
as `MAlloc`/`Free`/`MSize`. Retained service loading, task/current/explicit heap
selection, throwing allocation failure and automatic task teardown remain next.
Aligned-allocation markers, debug/logging support, fragment tidying and adjacent
page merging, full low-memory document workflows, self-hosting and strict 386
acceptance remain unfinished.

Final verification passes on the final sources, including native boot, all 81
keyboard commands across 144 submitted lines with exact VGA pixels, custom
startup, syntax-error and missing-file recovery, and all module rejection and
reclamation cases. The kernel is 384200 bytes, leaving 4920 bytes after its
4096-byte stage in the existing reservation. The diagnostic keyboard boot takes
123.866 seconds on the 8 MiB QEMU/486 development profile, not physical 386 hardware.
The new memory core is tested by the native heap fixture and is not linked into
the current boot image yet.

All 1062 OS source hashes match the native, rebuild and layout results. The eight
native build inputs, four memory-layout inputs, three task-layout inputs and final
disk hash also match. Python syntax and staged whitespace checks pass. Growing
backing pools, original public pool metadata accounting and migration of compiler
allocation provenance/capacity checks remain part of public service integration.

## Public task heap ownership

The internal public-memory core now has task lifetime integration in
`Kernel/I386/TaskHeaps.HC`. Each task owns a complete `CHeapCtrl`, shared by its
public code/data heap pointers on the flat native target. Bootstrap storage owns
the control record; the public control owns its pages. Children retain their
parent's heap state through the existing task lifetime-reference mechanism.

Spawn constructs heap state before inheriting file and symbol resources, and
unwinds it on failure. Normal task cleanup and compiler cleanup run with public
allocations still live. Reap drains file and symbol state before destroying the
heap, and leaves remaining state available for retry when a heap is locked.
Root detach is explicit provider shutdown from the root task. See
[public memory ownership](i386-public-memory.md#task-ownership).

The dedicated native task-heap fixture passes four cycles with two workers each,
including allocation/control exhaustion during spawn, later inheritance failure,
parent retention, partial-hook rejection, cleanup-time allocation and yields,
locked-heap retry and complete final reclamation. Its compiler/file/symbol
callbacks are synthetic ordering checks around the actual scheduler; compiler
allocation migration is still outstanding. The existing task, task-symbol and
exception-task suites also pass with instruction audits. Both x86-64 rebuild
and reboot generations pass, and layout verification preserves all 105 task and
43 memory fields. All 1064 OS source hashes match those rebuild/layout results.

Private task records gain heap state and two callbacks; dependent module versions
are CompilerRuntime 40, FileRuntime 18, CompilerProbe 10 and ConsoleRuntime 6.
Repeated heap-hook validation is shared to keep the kernel within its existing
bootstrap reservation: 386912 kernel bytes plus 4096 early-stage bytes leave 2208
bytes free. The complete shared public task and CPU layouts are unchanged.

These hooks do not yet install a retained public-memory provider in the boot
kernel. That provider, growing backing pools, public allocation/exception and
alignment semantics, and compiler allocation migration remain required before
console applications can use the full public heap API. Full DolDoc, native
self-hosting and strict 386/no-387 hardware acceptance remain open.

Final native verification passes on these sources: all 81 keyboard commands over
144 submitted lines, exact VGA checkpoints, custom startup, syntax-error and
missing-file recovery, and every startup/runtime target/import/API rejection with
reclamation checks. Diagnostic console startup takes 129.812 seconds on the 8 MiB
QEMU/486 development profile. This is not strict 386 or physical-machine evidence.
All 1064 native source hashes, eight build-input hashes and the final disk hash
match; the layout input hashes, Python syntax and staged whitespace checks pass.

## Registered memory regions and bootstrap backing

The internal public page pool now accepts discontiguous regions, using the
complete shared `CMemRange` inside an ownership extension. Allocation and release
validate region membership and account used pages per region. Overlapping arenas
or metadata, overflow, foreign blocks and cross-region blocks are rejected.
Removing an unused region unlinks its raw fragments and both page-bin kinds
before the caller can return or overwrite its storage. Cached heap pages keep
their region owned until heap teardown returns them.

`Kernel/I386/MemoryBacking.HC` provides demand growth from the bootstrap allocator.
It reserves no arena at initialization. Page exhaustion invokes the provider once
with a recursion guard; growth tries the configured quantum and then the required
page span. A region's record and alignment padding share one tracked bootstrap
allocation. Provider accounting includes the actual allocation span, while the
public pool reports usable page bytes. Explicit trim returns wholly unused
regions after callers finish reading freed page headers. See
[region ownership and growth](i386-public-memory.md#regions-and-demand-growth).

The native heap fixture passes its existing 49 layout checks, 1024 churn rounds
and three bulk heap lifetimes, plus three region and three backing-provider
lifetimes. Tests cover live owners in separate regions, overlap and hole checks,
all free-list bin kinds, memory pressure, smaller growth fallback, unchanged
state after failed growth, fragmentation, one-time large-page rounding, and
bootstrap reuse of returned memory while other allocations remain live. The
larger fixture uses a 192 KiB loader below the unchanged first heap address.
The task-heap lifecycle fixture also passes against this pool implementation.
Both x86-64 rebuild/reboot generations and the 43-field memory and 105-field task
layout checks pass.

The provider is still internal and is not loaded by the boot kernel. Retained
service integration must bind actual task heaps and place trim calls after public
free/heap teardown, before the allocation API can be exposed to console programs.
Original public pool metadata accounting, aligned allocation, compiler allocation
migration and the full document/self-hosting/hardware gates remain outstanding.

Final native boot/console verification passes: 81 commands across 144 submitted
lines, exact VGA checkpoints, all startup-source variants, and all target/import/
API rejection and reclamation checks. Diagnostic console startup takes 126.733
seconds on the 8 MiB QEMU/486 development profile. Kernel size remains 386912 bytes
plus the 4096-byte early stage, leaving 2208 bytes in the existing reservation.
All 1066 OS source hashes match the native, rebuild and layout results; eight
native build inputs, four memory-layout inputs, three task-layout inputs and the
final disk hash also match. Python syntax and staged whitespace checks pass.
These are development results, not strict 386/no-387 or physical-machine evidence.

## Retained public-memory provider and live task heaps

`Kernel/I386/MemoryRuntime.HC` now loads as a retained, versioned service before
compiler diagnostics and worker creation. Its module entry only fills the
candidate interface; the kernel validates the target, imports, version and entry
addresses before binding the root heap. Root, pulse and console tasks now have
real public heap controls, with code/data aliases within each task and distinct
controls between tasks. Backing regions grow on demand from the bootstrap heap.

Task heap teardown now invokes an optional provider notification after releasing
its control, dropping the parent reference and clearing task heap hooks. The
provider can then trim unused regions without invalidating page headers still
being read by allocator callers. It rejects shutdown while a reclamation callback
is attached, leaving state intact. Callback code and provider storage remain
resident for kernel lifetime. Public allocation functions and compiler allocator
migration remain the next integration boundary.

The growing task-heap fixture passes four cycles with eight workers, failed-spawn
rollback and explicit root detach: ten reclamation callbacks in total. Callbacks
check that task heap fields are already cleared and interrupts masked; failed
locked-heap teardown invokes no callback and preserves backing totals. Root data
survives worker cleanup, and root detach returns every backing allocation. The
existing heap corpus, ordinary task suite, both x86-64 rebuild/reboot generations,
43-field memory layout and 105-field task layout checks pass.

Native root and worker probes allocate across two backing regions, retain one
allocation while returning the other region, then verify exact bootstrap
reclamation. The console also checks its inherited heap binding through typed
`Fs`. MemoryRuntime's image is 82840 bytes (82856 retained heap bytes). The
bootstrap kernel is 387848 bytes plus the 4096-byte early stage, leaving 1272 bytes
in the existing reservation. These are implementation footprints, not proof of
the complete 8 MiB interactive or 16 MiB self-hosting targets. Full public memory
semantics, DolDoc, native self-hosting and strict 386/no-387/physical acceptance
remain unfinished.

Final kernel verification passes: 82 commands across 145 submitted lines, exact
VGA checkpoints, custom startup, syntax-error and missing-file recovery, and all
startup/runtime rejection and reclamation checks. MemoryRuntime specifically
rejects wrong-target, missing-import and wrong-API modules before heap binding.
Diagnostic console startup takes 126.883 seconds on the 8 MiB QEMU/486 development
profile. All 1068 OS source hashes match the native, rebuild and layout results;
eight native build inputs, four memory-layout inputs, three task-layout inputs
and the native disk hash also match. This remains development evidence, not
strict 386/no-387 or physical-machine acceptance.

## Native public allocation interface

The retained memory service now publishes `MAlloc`, `Free`, `MSize`, `MSize2`,
`MHeapCtrl`, `CAlloc`, `MAllocAligned` and `CAllocAligned` through native public
headers. It owns the export records and callable addresses for kernel lifetime;
compiler controls own their declarations. MemoryRuntime version 2 retains its
16-byte table and adds symbol publication to the validated binding operation.
The original x64 help-file registration remains in `KernelA.HH`, while shared
memory records retain native-loadable help indexes.

Allocations select the current task, an explicit task or an explicit heap control.
Size queries report base allocation capacity, including for aligned results;
`MSize2` adds the native 12-byte used prefix. Aligned markers hold a signed I64
base displacement, computed after widening both addresses. Public free notifies
the retained provider only after its page-header reads finish. Exhaustion restores
IF before throwing `OutMem`; the command runner records uncaught allocation
failure, and the console reports `Out of memory` rather than a compilation error.
Source-level catches can handle the original exception directly.

Root and worker probes each exercise twelve public-input stages, including
complete memory records, allocation persistence across failed compilation,
alignment, zeroing, ownership, size queries, cleanup and caught `OutMem` with
preserved interrupt state. The retained service also checks two-region growth and
exact bootstrap reclamation. The worker now has a temporary 256 KiB private
compiler arena. Correction: this revision did not exit and reap the worker
after its probes, so the arena remained allocated. Its previous 128 KiB arena held the larger
headers but exhausted while compiling the exception function. Sharing bootstrap
compiler storage passed the source cases but produced a roughly 436-second
diagnostic startup; compiler allocation migration remains a separate measured
change. The existing whole-chain bootstrap validator is unchanged.

The console harness includes 25 additional public-memory commands, a percent-key
mapping and exact VGA expectations for source input spanning multiple text rows.
Each run removes its previous result file so a failed run cannot leave a stale
pass record. These changes do not establish complete public memory services,
compiler allocation migration, the 8 MiB DolDoc workflow, native self-hosting or
strict 386/no-387/physical VGA acceptance. Those gates remain in `PLAN.md`.

The late startup/console module-rejection tests now allow 180 seconds, matching
the full boot deadline, because those modules load after the expanded root
compiler diagnostics. Their required rejection, reclamation and no-execution
markers are unchanged; early runtime rejection tests retain 90-second limits.

Final verification passes: two x64 rebuild/reboot generations, the 43-field memory
and 105-field task layout checks, the existing heap/task-heap fixtures, and the
complete native kernel suite. The console passes 107 commands across 170 submitted
lines with exact VGA pixels; custom, syntax-error and missing-file startup cases
also pass. All startup/runtime target, import and API rejection/reclamation checks
pass. The final console diagnostic startup takes 178.292 seconds on QEMU/486 with
8 MiB. This is a diagnostic workload measurement, not strict 386 hardware or final
interactive-latency acceptance.

MemoryRuntime occupies 95120 image bytes and 95136 retained heap bytes; public
headers retain 59080 bytes in the final boot. The kernel occupies 387896 bytes
plus the 4096-byte early stage, leaving 1224 bytes in the fixed bootstrap
reservation. All 1072 OS source hashes match the native, rebuild and layout
results; eight native build inputs, four memory-layout inputs, three task-layout
inputs and the native disk hash also match. Python syntax and staged whitespace
checks pass. Full public service semantics, compiler ownership migration, DolDoc,
self-hosting and physical-machine acceptance remain unfinished.


## Generated executable storage on public task heaps

Final native compiler output now uses the current task's public code heap.
Parser records retain both allocator provenance and logical byte length;
publication moves those into task storage. Compiler metadata and working buffers
remain on bootstrap arenas. Empty code heaps can return cached pages without
destroying their controls, and the retained provider releases idle backing only
after header access finishes. Symbol teardown preflights retained storage before
deleting definitions, allowing locked heap or pool state to defer cleanup.

Private ownership layouts change across the compiler, file and console modules.
The matching versions are CompilerRuntime 41, FileRuntime 19, CompilerProbe 11,
ConsoleRuntime 7 and MemoryRuntime 3; their public service-table sizes are unchanged.

A native child compiles and publishes a function, executes it after compiler
control cleanup, yields and exits. Its parent confirms that a locked code heap
preserves the symbol and callable code during failed reap, then unlocks and
reaps it with exact bootstrap allocation totals and parent references restored.
Both root and worker phases pass in the integrated QEMU/486 boot. Source probes
also verify that a compiled function belongs to the public code heap.

The diagnostic worker now actually returns and is reaped before console creation,
recovering 271520 bytes, including its 256 KiB compiler arena and 8 KiB stack.
Earlier documentation incorrectly implied that this happened after its probes;
the old worker instead continued sleeping indefinitely. The kernel now checks the
release explicitly. This remains diagnostic workspace, not the final compiler
memory policy.

The isolated task-symbol fixture now allows 400 KiB of loaded code, ending at
0x74000; its first 64 KiB arena starts there and ends at 0x84000, below the
0x90000 stack. The shared BIOS loader keeps its 384 KiB kernel default and allows
the fixture's explicit override. The OS hardware/RAM target does not change.

Two x64 rebuild/reboot generations, both public-layout checks (43 memory
fields and 105 task fields), the heap/task-heap/task-symbol fixtures and the
complete integrated native suite pass. The console passes 108 commands across 171 submitted lines with
all VGA pixels matched at each checkpoint. Diagnostic startup takes 169.894
seconds on the 8 MiB QEMU/486 profile. Custom, syntax-error and missing-source
startup cases pass, as do all 17 module rejection/reclamation cases.
Full public services, the 8 MiB DolDoc workflow, native self-hosting and strict
386/no-387/physical-machine acceptance remain open.

The native kernel is 388872 bytes plus the 4096-byte early stage, leaving only
248 bytes in its fixed bootstrap reservation. Further resident kernel growth
needs an explicit layout or module decision. MemoryRuntime occupies 101216 image
bytes and 101232 retained heap bytes; final public headers retain 59528 bytes.
These measurements do not establish the full interactive memory budget.


All 1074 OS source hashes match the final native, two-generation rebuild and
public-layout results. Eight native build inputs, four memory-layout inputs,
three task-layout inputs and the native disk hash also match. Python syntax and
whitespace checks pass. This closes the generated-executable ownership slice,
not the full port.


## Shared allocation-copy helpers for document code

The native public memory interface now binds `MemCpy`, `MemSet`, `MAllocIdent`
and `StrNew`. The latter two use the original bodies extracted into
`Kernel/Mem/AllocCopy.HC`, also included by the x64 implementation. Literal-zero
defaults avoid resolving the host `NULL` symbol in native cross-compilation.
The native byte primitives return the pointer just past the written bytes,
clear the direction flag, copy forward, fill with the low byte of the supplied
value and avoid pointer access for zero-length calls. This follows the original
`_MEMCPY` and `_MEMSET` assembly rather than the C library return convention.
`StrNew(0)` allocates an empty string; `MAllocIdent(0)` returns null. Allocation
copy uses the source base allocation's reported capacity, with the same readable
source requirement as the shared original implementation.

The retained memory table is version 4, still 16 bytes, and owns twelve export
records. Root and worker probes cover full-capacity copies, explicit heap
selection, null/empty input, byte truncation, overlapping forward copies and
exact backing reclamation. Six added console submissions exercise all four
public declarations through the native compiler. Both x64 rebuild generations
pass. The corrected native boot and console also pass, including end-pointer
returns and direction-flag clearing. The console executes 114 commands across
177 submitted lines with every VGA checkpoint matching; diagnostic startup is
175.472 seconds on QEMU/486 with 8 MiB. All three startup-source cases and
all 17 module rejection/reclamation cases pass.

This removes direct dependencies used throughout `Adam/DolDoc/DocNew.HC`,
`DocBin.HC` and `DocRecalc.HC`. It does not make DolDoc runnable yet. Inspection of
`DocNew.HC` identifies the next integration dependencies: complete document
records/constants, `StrLen` and `StrCpy`, queue operations, public yielding and
break-lock semantics, and the document binary/undo services. Preserve the real
entry lifecycle as these dependencies are connected. In particular, distinguish
`CDocBin`'s fixed-width start/end serialization span from its pointer-bearing
in-memory record and verify both target layouts before using native document
persistence.


The retained memory module now occupies 109480 image bytes and 109496 heap
bytes; final public headers retain 63632 bytes. The kernel remains 388872 bytes
plus its 4096-byte early stage, leaving 248 bytes in the bootstrap reservation.
The preview image is independently copied from the tested disk; its SHA-256
matches the native result. These measurements remain QEMU/486 development
evidence, not strict 386 or full DolDoc acceptance.


The final 43-field memory and 105-field task layout checks also pass. All 1075
OS source hashes match the rebuild, native and layout results; the eight native,
four memory-layout and three task-layout build inputs and both disk copies match
as well. Python syntax checks pass. Full public APIs, document
integration, native self-hosting and strict 386/physical acceptance remain open.


## Separate interactive and diagnostic boot

The default `kernel.img` now skips compiler/memory probes, the kernel-source
lexer/checksum self-check and the temporary diagnostic worker. Necessary service
initialization, scalar/public-header loading, startup source and runtime validity
checks remain on the normal path. `kernel-diagnostics.img` uses the same code and
filesystem, with one validated data byte enabling the existing full root/worker
suite. The build locates the exported flag through module metadata, requires a
zero default inside a declared data range, and verifies that only its selected
byte differs in the diagnostic disk.

The diagnostic boot retains all previous probe, timer and reclamation gates.
The full keyboard/VGA suite now boots the normal image and rejects diagnostic
execution markers. It also checks normal startup with a deliberately corrupted
probe module. Source-recovery and ordinary runtime-rejection cases run on normal
boot; probe-specific rejection cases run on diagnostic boot. The manifest records
both disk hashes, the flag location and mode-specific timing/evidence.

Normal startup measures 21.979 seconds, versus 175.807 seconds with diagnostics,
on QEMU/486 with 8 MiB: approximately eight times faster.
All 114 native console commands across 177 submitted lines pass with every VGA
checkpoint matching. The full diagnostic boot, corrupted-probe independence
check, all three source-recovery cases and all 17 rejection/reclamation cases
pass. This improves manual startup while keeping
the diagnostics available to automated tests and explicit QEMU runs.


Both x64 rebuild/reboot generations pass. All 1075 OS source hashes and eight
native build inputs match the tested artifacts; both disk hashes match, and the
images differ only at boot-flag byte 6216. The preview was refreshed by atomic
replacement so an already running VM can retain its existing open image. Python
syntax and whitespace checks pass. The native kernel is 388928 bytes plus its
4096-byte early stage, leaving 192 bytes in the unchanged bootstrap reservation.
The remaining normal startup cost includes native header/source compilation;
this separation does not claim instant startup or close the full port's gates.


## Public native StrLen intrinsic

The native compiler now validates and lowers the original public `StrLen`
intrinsic (0x84), and startup publishes its canonical `I64 StrLen(U8 *st)`
declaration. A byte scan returns a full-width length without allocation or
reading past the terminating byte. This unblocks the string-length dependency in
`DocEntryNewTag` and binary document handling; DolDoc integration remains open.

Both x64 rebuild generations and all 244 backend cases pass. Six new backend
cases compare native results with original x64 execution, including empty/long
strings, interior pointers, high-bit bytes, embedded terminators, side effects,
nested calls and wide arithmetic. The native intrinsic corpus now publishes 35
declarations, rejects 15 malformed variants, and executes 18 cases on each of the
boot and worker tasks with full cleanup checks. Normal startup exposes 34 public
intrinsic declarations.

The full native suite passes: 116 console commands across 179 submitted lines,
exact VGA checks, startup-source recovery, probe-independent normal boot and all
17 module rejection/reclamation cases. Normal startup is 22.178 seconds and
diagnostic startup 177.808 seconds on QEMU/486 with 8 MiB. The kernel remains
388928 bytes plus its 4096-byte early stage (192 bytes of reservation headroom).
CompilerRuntime occupies 1299168 image bytes and 1299184 retained heap bytes.
These measurements remain development-profile evidence, not full-workflow memory
or strict 386 acceptance. See [intrinsic publication](i386-intrinsic-publication.md).


## Public native StrCpy binding

The retained memory runtime now publishes the original void-returning `StrCpy`
contract. Its HolyC USE32 implementation preserves null-destination no-op,
null-source empty-string and DF-directed byte-copy behavior. Public headers bind
`_STRCPY`; MemoryRuntime is version 5 with the same 16-byte service table.

One shared corpus passes against original x64 code and native boot/worker tasks,
covering null/empty/long strings, high-bit bytes, embedded terminators, neighboring
bytes, self-copy, forward overlap and reverse copying with DF set. Both x64
rebuild generations and the full native suite pass, including 119 console commands
across 182 lines with exact VGA output, startup recovery and 17 module rejection
cases. The keyboard setup uses CAlloc so a setup expression does not introduce an
unrelated pointer result into the expected console output.

Normal startup measures 22.428 seconds and diagnostic startup 179.421 seconds.
The diagnostic-only observation allowance is now 240 seconds after a run reached
source startup at the old 180-second cutoff; normal boot remains independently
tested with a 60-second allowance. The kernel remains 388928 bytes with 192 bytes
of reservation headroom. MemoryRuntime uses 117488 image / 117504 retained heap
bytes, including its shared test corpus; public headers retain 64576 bytes.

This closes the initial public string-copy dependency in DocNew. Queue intrinsics,
shared document records, document lifetime/locking and the integrated editor/file
workflow remain required. See [public memory](i386-public-memory.md) and the
[DolDoc dependency inventory](i386-doldoc-integration.md).


## Shared public circular-queue record

The original `CQue` definition has moved unchanged into `Kernel/QueueTypes.HH`,
used by the x64 kernel header and native public task headers. The original
header's non-UTF-8 bytes are preserved outside the extracted definition.

Both x64 rebuild generations pass. The x64 layout check preserves all 105 task
fields and verifies the queue's 16-byte size, link offsets 0/8 and eight-byte
pointer members. Native cross-compiled and public-header assertions verify the
8-byte record, offsets 0/4 and four-byte links. Boot/worker public-header coverage
now includes 113 layout checks, with rollback/retry and final reclamation intact.
Console tests retain the actual public type and a pointer across submissions.

The full native suite passes: 121 commands across 184 lines with exact VGA
checkpoints, source recovery and all 17 module rejection cases. Public headers
retain 67176 bytes, up 2600 bytes. Normal startup measures 23.584 seconds and
diagnostic startup 187.625 seconds on QEMU/486 with 8 MiB. Kernel size and its
192-byte remaining bootstrap headroom are unchanged. The manual preview was
refreshed from the verified normal image.

This is the record prerequisite for native queue intrinsics, not their
implementation. Original queue operations update next/last pointers directly;
`QueRem` leaves the removed entry's own links unchanged. Preserve those semantics
when adding target-width lowering and lifecycle tests, then integrate the shared
DolDoc records. See [public headers](i386-public-headers.md).


## Public native queue operations

Native `QueInit`, `QueIns`, `QueInsRev` and `QueRem` now use the shared CQue record
and original void-returning signatures. The backend writes four-byte links and
preserves removed entries' own links. Public declaration validation checks the
complete queue layout and self-typed pointer members.

A shared nine-stage corpus passes against original x64 intrinsics, the
cross-generated i386 runner and native compilation in boot and worker tasks.
It covers empty/singleton/multiple entries, both insertion directions, removal,
32 churn rounds, single argument evaluation and adjacent wide markers. Five
malformed declarations per native phase leave symbols and heap counters intact.
Both x64 rebuild generations and the 245-case backend instruction audit pass.
The full native suite passes 123 commands/186 lines with exact VGA output,
startup recovery, probe-independent normal boot and 17 module rejection cases.

The full corpus exposed OutMem in the worker's 256 KiB private compiler arena.
The diagnostic-only arena is now 512 KiB; the same corpus passes and task reap
returns 533664 bytes before console startup. Compiler working-buffer migration
remains open; this is not full-workflow memory acceptance. Normal startup is
24.988 seconds and diagnostic startup 220.877 seconds on QEMU/486 with 8 MiB.

Public headers retain 71048 bytes. CompilerRuntime uses 1307008 image / 1307024
retained heap bytes. CompilerProbe uses 641520 image bytes and reclaims its entire
641536-byte allocation. Kernel size remains 388928 bytes, with 192 bytes of
bootstrap headroom.

Trying the original queue #help_file directive exposed a separate missing
native lexer/publication feature. The native queue header records the original
help reference in a comment; real help-file symbols, shared document records,
locking and document lifecycle integration remain required. The dependency
inventory now records that reproducer and acceptance work explicitly.


## Native help-file metadata

Native command input now accepts the original #help_file directive. It resolves
the default DD.Z extension and absolute path through the current task's retained
file service, then publishes the help index and source link as owned metadata.
The queue header again contains its original help-file directive. Failed inputs
reclaim the entire private graph, and repeated directives retain original lookup
order both within and across inputs.

The shared lexer input passes against original x64 and native boot/worker tasks.
The original comparison confirmed that newline lookahead records line five for
a directive on line four; the initial native assertion incorrectly expected four
and was corrected to the measured original behavior. Public-header tests cover
explicit/default extensions, rollback, retry and full reclamation.

FileRuntime is version 20 with a 36-byte service table, CompilerRuntime 42,
CompilerProbe 12 and ConsoleRuntime 8. The host verifier checks the added resolver
address and rejects the immediately preceding module versions. Its initial
file-service log-width assumption was updated after successful guest startup.

Both x64 rebuild generations, all 245 cross-generated function cases and their
instruction audit pass. The full native suite covers 123 commands across 186
input lines, exact VGA output, source-startup recovery,
normal boot independent of diagnostics and all 17 module rejection cases.
Normal startup is 25.038 seconds and diagnostics 222.073 seconds on QEMU/486
with 8 MiB; the diagnostic worker still returns 533664 bytes before console startup.

Public headers retain 71248 bytes, including 200 bytes for queue help metadata.
CompilerRuntime uses 1313456 image / 1313472 retained heap bytes; FileRuntime uses
126768 / 126784 bytes. The temporary CompilerProbe reclaims all 646816 bytes.
The kernel is 388936 bytes, leaving 184 bytes of bootstrap reservation headroom.

This closes the missing help-file metadata prerequisite identified while adding
queues. Shared document records, locking, document lifecycle and the integrated
editor/help workflow remain open. See [help metadata](i386-help-metadata.md).


## Shared document/editor records

The original DolDoc constants and all eight document/editor records now live in
Kernel/DocTypes.HH, shared by x64 KernelA and native public headers. Extraction
preserves the original bytes outside that block and every original field inside
it. Four explicit tail-alignment directives retain the original record-size
assertions on i386 without changing x64 layouts. CDoc is 680 bytes native,
CDocEntry 160, and the CDocBin serialized span remains exactly 16 bytes.

The pre-extraction x64 fixture captures all 131 fields. Both x64 rebuild
generations and the rebuilt layout comparison pass. Native diagnostics execute
271 layout assertions in each of the boot and worker tasks, check editor format
metadata, and run a shared x64/native corpus for wide fields, callback calls,
embedded records and saved bytes. Batches of 16 assertions verify temporary
reclamation; the behavioral corpus still compiles as one input. Full publication,
rollback, symbol cleanup and worker teardown checks pass.

The full native suite passes 124 commands across 187 input lines, exact VGA
checkpoints, independent normal boot with a damaged diagnostic module,
custom/missing/invalid startup source recovery, and all 17 module rejection
cases. All 1084 recorded OS source hashes match the rebuild and layout evidence.
The temporary CompilerProbe uses 656864 image / 656880 heap bytes, all reclaimed;
worker teardown returns 533664 bytes. The kernel remains 388936 bytes, with
184 bytes of bootstrap reservation headroom. Runtime module versions are unchanged.

Public headers now retain 169920 bytes, up from 71248. Normal QEMU/486 startup
with 8 MiB takes 60.612 seconds (separate measurement 60.617), up from 25.038;
full diagnostics take 726.823 seconds, up from 222.073. Initial runs exhausted
240- and 600-second diagnostic deadlines; batching retained every assertion but
did not bring diagnostics below 600 seconds. A later run passed diagnostics and
missed the normal 60-second deadline. The final harness allows 1200 seconds for
diagnostics and 90 for normal startup. These deadline changes do not resolve the
performance regression. Normal boot still omits diagnostics; repeated whole-heap
validation is a likely scaling cost that needs profiling and ownership-preserving
compiler allocation work before full-editor acceptance.

The preview image is refreshed from this tested normal image. Document lifecycle,
locking/break semantics, palette bindings, persistent files and the integrated
editor remain open. See [document records](i386-document-records.md).


## Bootstrap heap performance and native assembly labels

A QMP sampling tool now profiles normal startup against verified disk/module
hashes. Caller samples of the document-enabled image locate the dominant cost
in I386HeapValid: 297/380 header samples and 179/193 startup-source samples.
Compiler control/task ownership, token handling, allocation and publication
repeatedly reach that full-chain validator.

The loop now uses bounded 386 register operations, preserving the original
region checks and every block/counter invariant. It still validates the entire
chain for all callers; no cache or early successful lookup bypasses corruption
checks. The heap corpus compares 160 metadata/control mutations with the old
HolyC validator, verifies arena immutability, and rejects operations when a later
block is corrupt. Existing heap/backing and reclamation tests pass.

The first valid-heap test exposed native optimizer label forwarding that skipped
an inline-assembly prefix after a conditional. The shared pass now preserves
assembler byte-offset targets for i386. Focused cases check the conditional's
two outcomes and two distinct internal labels; x64 optimization is unchanged.
Both x64 rebuild generations, the heap and inline-assembly tests, all 245 native
function cases and their instruction audits pass.

The complete native suite passes 124 commands / 187 input lines, exact VGA,
startup recovery, independence from diagnostics, all document layout/behavior
checks in both tasks, cleanup and 17 module rejections. Normal QEMU/486 startup
at 8 MiB improves from 60.612 to 15.806 seconds, diagnostics from 726.823 to
137.386 seconds. The normal harness deadline returns to 60 seconds. The kernel
shrinks by 2256 bytes to 386680, leaving 2440 bytes of bootstrap headroom.
CompilerRuntime ABI 42 uses 1314240 image / 1314256 retained bytes; public headers
still retain 169920 bytes. The tested normal preview is refreshed.

Post-change samples still show validation and allocation/size/free scans as
significant costs. Compiler metadata migration, full-editor responsiveness and
physical 386 measurements remain open. See [heap performance](i386-heap-performance.md)
for scope, raw-artifact locations and reproduction instructions.


## Callable bit assignment for document locking

Native public headers now expose original BEqu/LBEqu signatures and the
_BEQU/_LBEQU callable export names. MemoryRuntime version 6 owns the code and
publishes fifteen memory/string/bit exports; version 5 is rejected. Both routines
return the old bit and use full signed I64 offsets with native-width addresses.
Decoded-instruction checks require LOCK BTS and LOCK BTR on the two LBEqu paths.

One shared corpus passes against original x64 and native boot/worker bindings:
168 vectors / 504 calls per context, including negative offsets, offsets beyond
32 bits, noncanonical nonzero Bool values, idempotence, opposite assignments,
old-bit results and neighboring bytes. Native inputs compile the complete corpus
and preserve the existing full publication/rollback/cleanup checks.

The worker initially rejected compilation with a Compiler exception. Saved
frames identified I386ParserStackCheck and expression/statement recursion; the
throw frame had 3768 bytes remaining on the 8 KiB stack, below the parser's
4 KiB reserve. The heap was valid and recovered its previous used size. The
compiler diagnostic worker now has a 16 KiB stack and the same 512 KiB private
arena; the reserve, whole corpus, normal console stack and 8 MiB target are
unchanged. The larger worker reclaims all 541856 bytes at teardown. Automatic
stack growth remains unfinished; this result does not imply arbitrary source
nesting fits a fixed stack.

Both x64 rebuild generations and the full native suite pass with 1087 matching
OS source hashes. There are 127 console commands across 190 input lines, exact
VGA checks, all startup-source recovery cases and 17 module rejections. Normal
startup measures 16.401 seconds and diagnostics 151.783 on QEMU/486 at 8 MiB.
Public headers retain 172504 bytes. MemoryRuntime uses 118344 image / 118360 heap
bytes; CompilerProbe reclaims all 660288 bytes. The kernel remains 386680 bytes,
leaving 2440 bytes of reservation headroom. The normal preview is refreshed.

This closes DocLock's bit-assignment prerequisite. Public Yield, break delivery,
lock contention/exception cleanup and the actual document lifecycle remain open.
See [bit assignment](i386-bit-assignment.md).

## Public live-task ring

Native task attachment now maintains the original public `next_task/last_task`
links. Blocked tasks retain membership; cleanup callbacks observe their live
task, while file/symbol destruction sees it detached. Initialization, attachment
and reaping reject stale public links. The private runnable queue still controls
dispatch, so public Yield eligibility/order and pending-break delivery remain
unfinished. See [public task ring](i386-public-task-ring.md).

Both x64 rebuild generations, the native task and task-heap suites and the full
kernel suite pass. Dedicated tests cover blocked membership, reverse-order and
interrupt wakeups, callback yielding, failed construction, stale-link rejection
and repeated reuse. Native JIT probes check root/worker membership through typed
Fs. The task-heap suite completes four lifecycle cycles and ten backing reclaims.

The integrated run passes 128 commands across 191 input lines, exact VGA checks,
startup-source recovery, normal boot with an invalid diagnostic module and all
17 module rejection cases. All 1087 OS source hashes and eight build-input hashes
match the tested sources. Normal boot takes 16.400 seconds and diagnostics
152.786 seconds on QEMU/486 at 8 MiB. Public headers retain 172504 bytes; the
diagnostic worker reclaims 541856 bytes and the probe image reclaims 661520 bytes.
The kernel grows to 388520 bytes, leaving 600 bytes after the 4096-byte early
stage in its fixed reservation. Substantial new services must use extended-memory
modules. The tested normal preview is refreshed; strict 386 and physical-PC
acceptance remain open.

## Dispatch follows the public task list

Native yield, block and finish now select the next unblocked task in public
`next_task` order. Wakeup changes eligibility without changing that order. The
private runnable list remains for membership/idle checks; unlinking it uses its
own neighbors rather than the chosen public successor. This preserves the
original scheduler's connection between task-list order and round-robin dispatch.
Public Yield flags, wake-time eligibility, idle behavior and break delivery still
need integration before the original public callable interface can be published.

The scheduler regression wakes task 2 before task 1 in both rounds. With the
attachment order intact, dispatch is 1 then 2; with only the public links reordered
while blocked, dispatch is 2 then 1. Both rounds cover repeated yield, finish and
reap, exposing accidental use of the private successor during unlinking.

Both x64 rebuild generations and six native suites pass: tasks, task heaps,
messages, task exceptions, compiler/task symbols and ATA tasks. The first scheduler
test attempt failed during compilation because the new test used unsupported
C ternary syntax; ordinary HolyC conditionals fixed the test. The corrected corpus
and instruction audit pass. The full kernel suite passes all 128 commands / 191
input lines, exact VGA, startup recovery, diagnostic independence and 17 module
rejections. All 1087 OS and eight build-input hashes match the tested sources.

Normal boot takes 16.300 seconds and diagnostics 152.175 seconds on QEMU/486 at
8 MiB. Header and worker/probe reclamation footprints are unchanged. The kernel
is 388912 bytes, leaving 208 bytes in the bootstrap reservation. The next resident
expansion must first move the remaining diagnostic-only KernelStorage source/lexer
checks into the diagnostic module while retaining their evidence. The normal
preview is refreshed. See [task scheduling](i386-public-task-ring.md).

## Source/lexer diagnostics moved out of the resident kernel

KernelStorage now only mounts and reports the boot volume. CompilerProbe's boot
phase owns the original raw source read, owned-buffer lexer traversal, parent
resumption and exact allocation reclamation check. It calls the same resident
read/pop helpers through borrowed pointers; normal boot neither loads nor runs
this module. The worker phase leaves the polled storage check to the boot phase.
ABI 13 adds the volume and helper pointers to the synchronous probe configuration
(68 bytes, previously 56), and imports two existing lexer exports. The host
checks marker ordering and rejects ABI 12 before source traversal.

The kernel shrinks by 5736 bytes to 383176. Together with the unchanged 4096-byte
early stage, it leaves 5944 bytes in the fixed 393216-byte reservation, up from
208. CompilerProbe grows to 668824 image / 668840 heap bytes, all reclaimed after
the task probe. This frees resident capacity without claiming lower diagnostic
peak RAM. The worker's 541856-byte reclamation and 172504-byte retained public
headers are unchanged.

Both x64 rebuild generations and the full kernel suite pass with 1088 matching OS
source hashes and eight matching build-input hashes. The moved check validates
25646 characters, 566 lines and FNV 0xCF55170C, reclaiming 26224 transient bytes.
All 128 commands / 191 input lines, exact VGA checks, three startup-source cases,
normal boot with an invalid diagnostic module and 17 rejection cases pass.
Normal QEMU/486 boot at 8 MiB takes 16.353 seconds; diagnostics take 156.186.
The tested normal preview is refreshed. Public scheduling eligibility and break
delivery remain the next integration work; see
[storage diagnostics](i386-storage-diagnostics.md).

## Public task flags control native eligibility

Native selection now skips suspended and awaiting-message tasks as well as
privately blocked/finished tasks. Original task flag definitions are shared
byte-for-byte through TaskFlags.HH; task_flags remains U32 and record layouts are
unchanged. When all tasks are ineligible, selection uses STI/HLT/CLI and rescans
after an IRQ, preserving the yielding/blocking caller's IF on return. Kernel root
loops consult public eligibility for idle decisions.

Block detaches private runnable membership before selection can enable IRQs. An
IRQ may wake the same task, which resumes without switching its context to itself.
Finish detaches both lists and wakes joiners before selecting a successor, so a
suspended root cannot prevent newly released joiners from running. The task
corpus verifies both flag bits, unrelated bit-31 preservation, root suspension
with IF initially clear/set, all-ineligible block/yield/finish, IRQ wakeups,
detachment, stack guards and heap recovery. Joiners suspended across completion
prevent reaping until individually resumed; a second cycle suspends root and
requires the target's completion to release its joiners and restore progress.

Both x64 rebuild generations and six native suites pass: tasks, task heaps,
messages, task exceptions, compiler/task symbols and ATA tasks. The expanded
scheduler corpus exceeded its old test-loader transfer; it now uses the existing
256 KiB transfer profile and an arena at 0x60000, above the loaded image. The
production bootstrap reservation remains unchanged.

The full kernel suite passes 128 commands / 191 input lines, exact VGA, startup
recovery, normal boot with an invalid diagnostic module and 17 rejections. Its
1089 OS source and eight build-input hashes match. Kernel size is 384120 bytes,
leaving 5000 bytes after the early stage. Public headers retain 176224 bytes;
probe/worker reclaim all 668840/541856 bytes. This QEMU/486, 8 MiB run measured
15.455 seconds for normal boot and 124.155 for diagnostics. The normal preview
is refreshed. Wake-time accounting, public message-wait transitions and break
delivery remain open; see [task eligibility](i386-task-eligibility.md).

## Native message queues maintain the public wait bit

Empty blocking reads now set TASKf_AWAITING_MSG before registering their scheduler
wait. Accepted sends and close clear that bit on the registered reader and any
attached recipient, preserving suspension and unrelated flags. An attached task
can therefore use a public flag wait without entering the private queue reader.
Only the queue's registered reader receives a private wake, so unrelated blocking
conditions remain intact. Generic scheduler wake alone leaves the public bit set;
the message reader remains ineligible until a send or close releases it.

The focused native message suite passes with new bound/unbound queue cases,
unmatched-message re-wait, queued-data and empty close, suspension, invalid sends,
public-only flag waits, unrelated private blocking and bit-31/IF preservation.
The existing keyboard IRQ/broker/focus/consumer, inbox ownership and reclamation
checks also pass, with an instruction audit. Both x64 rebuild generations pass;
all 1089 OS source hashes match the rebuild manifest.

Message.HC is currently linked by this dedicated component runner, not by the
interactive kernel console, which uses direct keyboard input. The full kernel
suite was not rerun for this component-only change, and the previously tested
normal preview remains unchanged. This does not complete original Msg/GetMsg,
job queues, popup propagation, TaskRstAwaitingMsg or break cancellation. See
[message wait flags](i386-message-wait-flags.md).

## Shared jiffy clock and native wake deadlines

The original CCntsGlbls record and time constants are shared verbatim through
TimeTypes.HH. One kernel-owned cnts instance supplies the PIT's counter pointer,
the scheduler's borrowed clock and the native HolyC data export. Native public
headers declare that same record/address. Only jiffies is implemented here;
HPET/TSC calibration and the original SysTimerRead contract remain open.

The PIT keeps its 11932 divisor and delivered-IRQ counter. It precomputes whole
and fractional 1000-Hz-unit credits, then accumulates them per delivered IRQ with
no division in the interrupt path. Missed/coalesced IRQs are not reconstructed.
Scheduler eligibility now includes the original signed I64 wake_jiffy comparison,
under IRQ masking, and neither expiry nor generic wake overrides other wait flags.
All-future task selection idles until an interrupt permits progress.

Both x64 rebuild generations and six native suites pass: tasks, task exceptions,
messages, task heaps, task symbols and ATA tasks. The timer corpus checks six
divisors against whole-interval arithmetic, 10007-step fractional accumulation,
32-bit carry, 64-bit wrap and guards. Deadline tests cross 32 bits and cover root
expiry, signed past deadlines, suspension beyond expiry, private wake before
expiry and finish while root waits for its deadline. The enlarged timer corpus
uses the existing 192 KiB test transfer profile, below its arena at 0x40000.

The full kernel suite passes 129 commands / 192 input lines, exact VGA, startup
recovery, normal boot with an invalid diagnostic module and 17 rejection cases.
Root/worker JIT probes verify the live counter before and after IRQ delivery; the
console reads JIFFY_FREQ and positive jiffies. All 1090 OS source and eight
build-input hashes match. Kernel size is 387992 bytes, leaving 1128 bytes after
the early stage. Public headers retain 179280 bytes. CompilerProbe reclaims all
669992 bytes and its worker reclaims 541856 bytes. Normal QEMU/486 boot at 8 MiB
measured 14.853 seconds and diagnostics 124.943 in this run. The normal preview
is refreshed. See [jiffy clock](i386-jiffy-clock.md) for ownership, non-atomic plain
I64 reads on 386, timing scope and the remaining public scheduling contracts.


## Queued ATA acquisition cancellation

Native ATA channels now cancel queued acquisition without aborting an active
owner. The stack waiter is detached under IRQ masking before the task can resume;
Acquire returns FALSE and ordinary caller cleanup can run. FIFO survivors, public
wait flags, wake deadlines, lock counts and IF are preserved. FileRuntime ABI 21
exposes the operation for its two physical channels through a 40-byte service
table. Full Break delivery and cleanup of other wait types remain open; see
[ATA wait cancellation](i386-ata-wait-cancellation.md).

Both x64 rebuild generations and the native task/ATA suites pass. Six cancellation
scenarios cover head/middle/tail/all removal, poison, suspension, wide wake
deadlines, spurious wake, grant-before-cancel, FIFO completion and full task/heap
reclamation. The full kernel suite passes 129 commands / 192 input lines, exact
VGA, startup recovery, normal boot with an invalid diagnostic module and all 17
rejection cases. Root and worker probes exercise the loaded cancellation callback
with no queued waiter; actual queued behavior is covered by the task corpus.

All 1090 OS source hashes and eight build-input hashes match the test manifest.
Kernel size remains 387992 bytes, leaving 1128 bytes after the early stage.
FileRuntime retains 130344 bytes (130328-byte image); CompilerProbe reclaims all
671000 bytes. Public headers retain 179280 bytes. Normal QEMU/486 boot at 8 MiB
measured 14.200 seconds and diagnostics 124.962 seconds. The normal preview image
has been refreshed from the verified disk. This is still QEMU/486 evidence, not
strict 386 compatibility, a complete DolDoc environment or native self-hosting.


## Native sleep and join cancellation

Sleep cancellation detaches its stack waiter under IRQ masking and resumes the
call with FALSE, retaining a nonzero remaining count to distinguish cancellation
from expiry. Join cancellation removes the target registration and returns FALSE
without dereferencing a target that may already have been reaped. Completed
joins and expired sleeps win over late cancellation. Both preserve public wait
flags, wake deadlines and IF. These are internal prerequisites for coordinated
Break delivery, not public Break or task killing; see
[sleep/join cancellation](i386-sleep-join-cancellation.md).

Both x64 rebuild generations and native tasks, task exceptions and ATA tasks
pass, including instruction audits. Ten new sleep/join scenarios cover queue
positions, complete removal, spurious wake, suspension/bit-31/deadline preservation,
expiry/completion races and heap reclamation. Cancelled joiners resume after the
exact target allocation is freed, reused and overwritten. The task fixture now
uses the existing 640-sector transfer profile below its heap at 0x60000; segment
records move beyond the heap to 0x70000/0x70100. Default fixture segment placement
is unchanged and the ATA task runner passes with that default.

The initial resident addition exceeded the bootstrap reservation. Sharing sleep
unlinking and replacing repeated startup/probe directory walks with the existing
RedSea path resolver keeps the kernel at 388120 bytes, leaving
1000 bytes after the early stage. No service-record layouts changed.

The full kernel suite passes 129 commands / 192 input lines, exact VGA, startup
recovery, normal boot with an invalid diagnostic module and all 17 rejection
cases. All 1090 OS source hashes and eight build-input hashes match. Normal
QEMU/486 boot at 8 MiB measured 14.200 seconds and diagnostics
125.159 seconds. The preview is refreshed from the verified disk. Strict
386 compatibility, full DolDoc, public interruption handling and native
self-hosting remain open.


## Pending message-read cancellation

The native message queue now supports cancellation of its pending blocking read.
It clears the owned awaiting-message bit and detaches the borrowed stack flag
under IRQ masking, preserving messages, recipient, close state, other flags,
wake deadline and IF. The resumed read returns zero with output untouched and
checks its local cancellation flag before touching the queue. An unbound queue
can therefore be reused, or accept another reader, before the cancelled task
resumes. Send/close wakeup is not final read completion; cancellation may still
win without consuming the queued data. See
[message-read cancellation](i386-message-read-cancellation.md).

Both x64 rebuild generations and the native message suite pass with instruction
audits. All 1090 OS source hashes match the rebuild manifest. Six new scenarios
cover blocked/spurious wake, attached/unbound queues, send/close races, output
preservation, suspension/bit-31/deadlines/IF, exact allocation reuse/overwrite and
replacement-reader isolation. Existing message filtering, inbox allocation and
cleanup, keyboard IRQ/broker/focus delivery and public wait-flag tests also pass.
The expanded component runner uses the existing 384-sector profile below its
heap at 0x40000.

Message.HC remains a separately linked component, not part of the interactive
kernel. The full kernel suite was not rerun for this component-only change, and
the previously verified normal preview remains unchanged. This does not complete
original Msg/GetMsg, popup/job propagation or public Break. Raw keyboard waits
still need cancellation, and a coordinated interruption path must preserve
file/compiler cleanup before exception delivery.


## Raw keyboard wait cancellation through retained console services

Raw input reads now borrow a stack cancellation flag while registered. Cancelling
detaches that flag and the reader under IRQ masking, restores private runnable
membership, and leaves queued byte/status pairs, loss accounting, public flags,
wake deadlines and IF intact. The resumed read returns FALSE before accessing
the stream. Decoded reads propagate zero with unchanged event output and retain
partial scan state for the next read. See
[keyboard-read cancellation](i386-keyboard-read-cancellation.md).

Cancellation code lives in retained ConsoleRuntime ABI 9, through its fourth
service callback, cancel_read(task). The kernel keeps its raw producer/read path.
CompilerProbe ABI 14 (72-byte configuration) invokes the loaded callback with null
and nonwaiting tasks only during worker diagnostics; normal boot skips it.
Queued cancellation is exercised separately by the native input corpus.

Both x64 rebuild generations and native input/message suites pass with instruction
audits. Six input cancellation scenarios cover blocked/spurious wake, publication
before cancellation, byte/status retention, suspension/message-bit/bit-31/wide
wake deadlines/IF, exact stream reuse/overwrite, replacement-reader isolation and
completion of a decoded E0 sequence. Existing keyboard controller/IRQ, scan-state,
message broker and inbox lifecycle tests also pass. The enlarged input runner
uses the existing 384-sector transfer profile below its heap at 0x40000.

The full kernel suite passes 129 commands / 192 input lines, exact VGA, startup
recovery, normal boot with an invalid diagnostic module and all 17 rejection
cases, including old console and diagnostic ABIs. All 1091 OS source hashes and
8 build-input hashes match. Kernel size is 388944 bytes, leaving only
176 bytes after the early stage. ConsoleRuntime retains 49072 bytes;
CompilerProbe reclaims all 671568 bytes. Normal QEMU/486 boot at 8 MiB measured
14.200 seconds and diagnostics 125.350 seconds. The normal preview is refreshed.

The plan now requires consolidation of resident loader/diagnostic scaffolding
before growing the scheduler core further. Active-wait selection, break locking,
file/compiler cleanup and original exception/message/job/popup behavior still
need coordinated integration. This does not complete public Break, DolDoc,
strict 386 compatibility or native self-hosting.


## Shared bootstrap module loading and reclamation

The kernel now shares module path resolution/loading, heap accounting checks and
image reclamation across startup, retained-service rejection and temporary
compiler diagnostics. Expected totals remain caller-supplied: rejected services
must return to their pre-load snapshot, probes must leave no transient allocation,
and startup may retain its display allocation while releasing only its image.
The release helper clears the caller's image pointer and checks the heap under
IRQ masking before restoring IF. Retained compiler/file images are still checked
after probe release. No service ABI, publication or rejection contract changed;
see [bootstrap module lifecycle](i386-bootstrap-module-lifecycle.md).

This reduces the kernel from 388944 to 386832 bytes, recovering
2112 bytes and increasing headroom after the early stage from 176 to
2288 bytes within the existing 384 KiB reservation. Additional interruption
logic should remain in retained services where possible; scheduler-core growth
still needs explicit size checks.

Both x64 rebuild generations and the full kernel suite pass. Coverage includes
129 commands / 192 input lines, exact VGA, startup recovery, normal boot with an
invalid diagnostic module and all 17 module-rejection/reclamation cases. All
1091 OS source hashes and 8 build-input hashes match. Normal QEMU/486 boot at
8 MiB measured 14.250 seconds and diagnostics 125.349 seconds. The preview is
refreshed from the verified image. Active-wait coordination, public Break,
DolDoc, strict 386 compatibility and native self-hosting remain open.


## Task-owned sleep/join wait registration

Sleep and join now keep a borrowed wait record on their call stack, referenced
by the native task. It records kind, resource, callback and cancellation state.
Both direct cancellation and the common dispatcher mark that state, so repeated
cancellation cannot call into a resource already released. The dispatcher rejects
recursion, preserves IF and leaves the record until the waiting call resumes.
Task attachment/finish/reap guards prevent reclaiming a registered stack; normal
return clears the slot. The public CTask layout is unchanged. See
[task wait registration](i386-task-wait-registration.md).

ConsoleRuntime's fifth service callback retains the common dispatcher. Its loaded
entry is exercised by the worker diagnostic with null and nonwaiting tasks;
registered cancellation is exercised by the task corpus. Private task-record
and lifecycle changes advance CompilerRuntime to 43, FileRuntime to 22, MemoryRuntime to
7, ConsoleRuntime to 10 (28-byte table) and CompilerProbe to 15 (76-byte config).

Both x64 rebuild generations and seven native suites pass: tasks, task exceptions,
task heaps, task symbols, ATA tasks, messages and input. Registration tests cover
direct/routed cancellation, recursion rejection, repeated dispatch with a failure
sentinel, expiry/completion races, live registration after cancellation,
finish/reap and nested-wait guards, and target reuse before cancelled joins return.
Existing heap, symbol, exception, disk and keyboard/message regressions pass.

The full kernel suite passes 129 commands / 192 input lines, exact VGA, startup
recovery, normal boot with an invalid diagnostic module and all 17 rejection
cases, including the previous native ABI versions. All 1092 OS source hashes and
8 build-input hashes match. Kernel size is 388752 bytes, leaving
368 bytes after the early stage. ConsoleRuntime retains 50840 bytes;
CompilerProbe reclaims 672064 bytes and its worker reclaims
541856 bytes. Normal QEMU/486 boot at 8 MiB measured
14.201 seconds and diagnostics 125.547 seconds. The preview is refreshed.

ATA, message and raw-keyboard waits still need common registration. A dedicated
retained task service, break-lock/pending-break policy, file/compiler cleanup and
original exception/job/popup delivery remain required. This is not public Break,
complete DolDoc, strict 386 compatibility or native self-hosting.


## Task-owned ATA and message wait registration

Queued ATA acquisitions and blocking message reads now publish their cancellation
record through the waiting task. Direct and common-dispatch cancellation share
that record, and repeated dispatch avoids the resource after cancellation.
Normal return clears the slot; existing lifecycle guards protect the registered
stack. Granted ATA ownership wins over late cancellation. Message cancellation
preserves queued data and permits queue reuse or a replacement reader before the
old reader returns. See [resource wait registration](i386-resource-wait-registration.md).

FileRuntime is now version 23 with the same 40-byte table. Other service versions
and private/public record layouts are unchanged. Raw-keyboard registration,
a dedicated retained task service, pending-break locking, outer file/compiler
cleanup and original exception/job/popup delivery remain open.

Both x64 rebuild generations and the native tasks, messages and ATA-task suites
pass. The full kernel suite passes 129 commands / 192 input lines, exact VGA,
startup recovery, normal boot with an invalid diagnostic module and all 17 module
rejection/reclamation cases, including FileRuntime 22 rejection. All 1092 OS
source hashes and 8 build-input hashes match the tested worktree; both boot disk
hashes are unchanged after tests. The build records the pre-commit revision plus
dirty-worktree status and exact input hashes.

Kernel size remains 388752 bytes, leaving 368 bytes after the 4096-byte early
stage. FileRuntime retains 131704 bytes (131688-byte image); public headers retain
179296 bytes. ConsoleRuntime retains 50840 bytes; CompilerProbe reclaims 672064
bytes and its worker reclaims 541856 bytes. Normal boot on QEMU/486 at 8 MiB
measured 14.301 seconds and diagnostics 126.146 seconds. The preview image is
refreshed from the verified normal disk. These checks do not establish strict
386 compatibility, complete DolDoc or native i386 self-hosting.


## Registered keyboard waits and retained input decoding

Raw keyboard waits now register through the common task cancellation entry.
Direct and routed cancellation share the stack record until normal return;
repeated cancellation does not revisit a detached stream. Input tests cover
nested-wait rejection, registration clearing, queued byte/status preservation,
IF/flags/deadlines, partial scan state, stream reuse and replacement readers.
See [keyboard wait registration](i386-keyboard-wait-registration.md).

Task-context raw reading and scan/event decoding now live in retained
ConsoleRuntime. The bootstrap keeps controller setup, stream initialization,
IRQ publication and queue primitives. ConsoleRuntime 11 initializes the decoder
against that stream and imports blocking and raw dequeue operations. Its service
and configuration records remain 28 bytes; the configuration now takes the raw
stream rather than a kernel read callback. Old version 10 is rejected. Other
service versions and task/input layouts are unchanged.

Both x64 rebuild generations and native input/message suites pass. The full
kernel suite passes 129 commands / 192 input lines with exact VGA, startup-source
recovery, normal boot with an invalid diagnostic module, and all 17 rejection
cases. All 1093 OS source hashes and 8 build-input hashes match; normal and
diagnostic disk hashes remain unchanged after verification. The build records
the pre-commit revision and dirty-worktree status alongside those exact hashes.

Kernel size falls from 388752 to 362872 bytes, recovering 25880 bytes. With the
4096-byte early stage, the existing reservation has 26248 bytes free.
ConsoleRuntime retains 77816 bytes (77800-byte image), so this is primarily code
relocation, not a comparable reduction in total RAM use. Public headers retain
179280 bytes. CompilerProbe still reclaims 672064 bytes and its worker 541856.
Normal QEMU/486 boot at 8 MiB measured 15.474 seconds, diagnostics 134.989 seconds;
these single-run timings do not establish a performance trend. The normal preview
image is refreshed from the tested disk.

The active medium goal is the first usable original DolDoc editing session:
edit and execute HolyC, recover from errors and interruption, save, reboot and
reopen at 8 MiB. Its acceptance criteria are recorded in the
[DolDoc integration inventory](i386-doldoc-integration.md). Pending-break locking,
outer resource cleanup and original document/editor integration remain open;
registered waits alone do not deliver that session or public Break.


## Internal pending-break checkpoints

Added internal task break request, lock, unlock and cooperative poll operations.
An unlocked request cancels a registered wait and clears its deadline; delivery
occurs only after normal return at an explicit current-task cleanup checkpoint.
The pending bit remains set while locked or while tracked wait/I/O/lifetime/
compiler ownership prevents delivery. Inbox and Shift-Escape paths defer until
the original message behavior is integrated. See
[pending-break checkpoints](i386-pending-break-checkpoints.md) for the contract
and differences from the original public Break API.

Both x64 rebuild generations and native exception tasks pass. Three sleeping
worker scenarios cover direct request, locked/unlock request and deferred
Shift-Escape, repeated requests, both IF settings, real native 'Break' catch and
recovery, and complete task/exception heap reclamation. Injected ownership guards
check premature-delivery rejection; real file/compiler unwinding still needs
integration. The exception fixture now uses a 512-sector transfer, a 0x50000 heap
and 0x70000 temporary segment records to avoid code/data overlap.

No production checkpoint or public Break binding is installed yet. Production
module versions and the existing normal QEMU preview remain unchanged; the full
kernel suite was not rerun for this component-only change. The DolDoc session
acceptance goal remains open. Next connect actual file/compiler cleanup boundaries
and original Break/message semantics before document-lock and editor integration.


## Compiler input pending-break cleanup

CompilerRuntime 44 checks pending breaks inside the command input catch/unwind
boundary. It permits that boundary to release its own active controls, while
extra lifetime references, waits, I/O ownership, locks and unsupported inbox or
Shift-Escape behavior defer delivery. Checkpoints surround returning compiler
and execution calls and precede publication. A successful unwind clears pending
state and rethrows 'Break' to the caller; failed cleanup preserves the request
and returns failure. See [compiler break cleanup](i386-compiler-break-cleanup.md).

Both x64 rebuild generations and the full native kernel suite pass. Three new
cleanup cases run on both boot and worker tasks, checking preexisting requests,
private function rollback, exact compiler heap totals, lifetime references and
IF. Normal console coverage is now 137 commands / 200 submitted lines, including
pending-break recovery, unpublished-definition rejection, lock-delayed delivery
and successful subsequent commands, with exact VGA comparisons. The keyboard
harness gained missing mappings for vertical bar and tilde after its first run
rejected the QEMU key name; the final full rerun passes. Startup recovery, normal
boot with an invalid diagnostic module and all 17 module rejection cases pass,
including CompilerRuntime 43 rejection.

All 1095 OS source hashes and 8 build-input hashes match. The normal and diagnostic
disks remain unchanged after verification; manifests identify the pre-commit
revision, dirty worktree and exact hashes. Kernel size remains 362872 bytes,
leaving 26248 bytes after the early stage. CompilerRuntime retains 1317280 bytes
(1317264-byte image). CompilerProbe reclaims all 674864 bytes of its temporary
image allocation. Normal QEMU/486 boot at 8 MiB measured 15.162 seconds and
diagnostics 130.344 seconds. The normal preview is refreshed from the tested disk.

This adds production cleanup behavior, not the finished user interruption flow.
Focused Ctrl-Alt-C requests, non-returning code interruption, actual queued-file
cancellation through compiler recovery, and original message/job/popup semantics
remain. The first original DolDoc edit/execute/save/reboot session is still open.


## Queued-file cancellation through compiler recovery

CompilerRuntime 45 converts parser/allocation failure into a pending ordinary
break only after the file call has released borrowed state and the protected
compiler boundary is ready. Conversion records the exception in the existing
catch; control unwind still precedes pending-bit consumption and outer delivery.
This closes the path where a cancelled include reports a compiler error before
reaching a normal-return checkpoint. See
[file break cleanup](i386-file-break-cleanup.md).

The worker diagnostic now holds a real RedSea lease in the parent and blocks a
child compiler include behind that ATA owner. Two cases cover immediate and
lock-delayed cancellation, both IF settings, repeated requests and preservation
of the parent's disk ownership. The cancelled child's file borrow remains live
until resumption; the outer catch checks its release along with compiler-control,
wait, I/O and lifetime cleanup. Private definitions stay unpublished and compiler
heap totals return to baseline. The same child then reads the file successfully
and evaluates 6*7. Reaping it restores the parent's full heap/reference/channel
baseline. The added disk lease imports remain diagnostic-only.

Both x64 rebuild generations and the full native kernel suite pass, including
the two queued-file cases, six prior input-break cases, 137 console commands /
200 input lines, exact VGA, startup recovery, normal boot with an invalid probe,
and all 17 module rejection cases (including CompilerRuntime 44). Initial
validation found a probe include-order issue that hid the imported throw symbol,
then a recovery-test filename missing its .HC extension; both were corrected
before the final successful rebuild and full suite.

All 1096 OS source hashes and 8 build-input hashes match, as do both post-test
disk hashes. Manifests record the pre-commit revision, dirty worktree and exact
hashes. Kernel size remains 362872 bytes, leaving 26248 bytes after the early
stage. CompilerRuntime retains 1317960 bytes (1317944-byte image). The temporary
probe reclaims all 697928 bytes, and its worker reclaims 541856 bytes. Normal
QEMU/486 boot at 8 MiB measured 14.705 seconds and diagnostics 138.000 seconds.
The normal preview is refreshed from the tested image.

Focused keyboard requests, interruption of non-returning execution, original
message/job/popup semantics and original DolDoc integration remain required.
These cleanup results do not complete the editing-session goal.


## Ctrl-Alt-C requests during active console submissions

The retained console now observes keyboard bytes in IRQ context with a separate
copy of the existing decoder state. An unextended C make with Ctrl and Alt requests
a break on the active executable submission. The handler may cancel a registered
wait, but does not allocate, switch or throw; existing compiler/task checkpoints
deliver after cleanup. Triggering C makes are consumed, while releases continue
through the buffered reader. Idle-prompt input behavior is preserved. Required
public-header loading is not a break target. See
[keyboard break requests](i386-keyboard-break-requests.md).

ConsoleRuntime 12 adds the validated key_irq callback, making its six-entry service
table 32 bytes. Configuration stays 28 bytes. The console imports throw for its
task-context poll and clears the active task pointer under IRQ masking on normal
return and catch. A poll inside the outer console try handles requests arriving
after the compiler's last checkpoint. Other module versions remain unchanged.

Both x64 rebuild generations, the native input suite and the full kernel suite
pass. Component coverage includes both left/right modifier combinations, repeat
makes, missing modifiers, releases, auxiliary/no-data bytes, corrupt input and
extended/wrong keys. QEMU sends real Ctrl-Alt-C events after observing a marker
emitted by running HolyC. Immediate and lock-delayed requests recover with exact
VGA output; pending state clears and a subsequent 6*7 returns 42. The test program
cooperates by checking the pending flag: arbitrary non-returning execution is
not yet interruptible by this path.

The console suite now covers 143 commands / 206 input lines and two hardware
hotkey cases. Existing compiler/file break cleanup, startup recovery, normal boot
with an invalid probe and all 17 module rejection cases pass, including console
version 11 rejection. All 1097 OS source hashes and 8 build-input hashes match;
both disk hashes are unchanged after tests. Manifests record the pre-commit
revision, dirty worktree and exact hashes.

Kernel size is 363144 bytes, leaving 25976 bytes after the 4096-byte early stage.
ConsoleRuntime retains 84624 bytes (84608-byte image). The temporary probe still
reclaims 697928 bytes and its worker 541856. Normal QEMU/486 boot at 8 MiB measured
14.816 seconds; diagnostics measured 128.760 seconds. The normal preview is
refreshed from the tested image. Execution-safe delivery for non-returning code,
multi-task focus, original message/job/popup semantics and original DolDoc
integration remain required for the editing-session goal.


## Native generated-loop break delivery

Native JIT backward branches now test pending break state and call a retained
CompilerRuntime poll only when a request exists. The 24-byte checkpoint preserves
registers, flags and stacked expression operands; label order determines the same
placement in both compiler passes. IRQ code continues to request only. Eligible
polls consume the pending bit and throw in task context, so the nearest HolyC
handler can catch and continue. Uncaught breaks unwind the compiler boundary;
failed cleanup restores pending state and prevents outward delivery. See
[loop break checkpoints](i386-loop-break-checkpoints.md).

CompilerRuntime is now version 46, retaining 1322016 bytes from a 1322000-byte
image. The standalone backend ABI is unchanged and emits no checkpoints unless
the internal frontend entry supplies the poll callback. Both x64 rebuild
generations and the full native kernel suite pass. Native root/worker bit tests
still fit the unchanged 512 KiB worker heap; instrumentation of forward branches
was rejected after exceeding that limit.

QEMU keyboard tests cover 153 commands / 216 input lines and six actual
Ctrl-Alt-C cases. Infinite while, backward goto and runtime-conditioned do/while
loops recover to the prompt; a user catch handler receives Break and continues.
Pending state clears and subsequent compilation/execution returns 42. The harness
now types colons for goto labels. Exact VGA, compiler/file cleanup, source startup
recovery, normal boot with an invalid probe and all 17 rejection cases pass.
All 1097 OS source hashes and eight build-input hashes match; both disk hashes
remain unchanged. Manifests record the pre-commit revision and exact tested hashes.

Kernel size remains 363144 bytes, with 25976 bytes of bootstrap headroom after
the 4096-byte early stage. ConsoleRuntime 12 remains 84608 bytes / 84624 retained.
The temporary probe reclaims 697928 bytes and its worker 541856. Normal QEMU/486
boot at 8 MiB measured 15.531 seconds; diagnostics measured 132.803 seconds. The
normal preview is refreshed from the tested image.

This establishes interruption of generated loops, not arbitrary uninstrumented
code or execution with interrupts disabled. Public Break/Yield/message/job/popup
semantics and original DolDoc lifecycle, rendering, editing and persistent saves
remain open. The first usable native DolDoc editing-session goal is not complete.


## Original document lock integration

DocLock and DocUnlock now share their original ownership policy through
`Adam/DolDoc/DocLockCore.HC`. The x64 wrappers retain the original platform
services; the native wrappers use explicit scheduler and cleanup-aware break
adapters. Contending tasks yield and can receive a break before acquisition.
Owning tasks release the document before delivering a pending break. Nested
acquisition, wrong-owner unlock and pre-existing task break locks retain the
original behavior. This does not publish a partial public Yield/Break contract.
See [document locks](i386-document-locks.md).

ConsoleRuntime 13 retains the native adapters and publishes callable DocLock and
DocUnlock bindings to the inherited root symbol scope. Native StartOS loads the
public declarations after console initialization. The console service/config
sizes remain 32/28 bytes; two additional imports supply I386SchedYield and
HashAdd. CompilerRuntime 47 adds the validated break_poll callback, growing its
service table to 204 bytes. Known active compiler controls can unwind at the
existing input boundary; outstanding waits/resource borrows still defer breaks.

Both x64 rebuild generations, the native exception-task suite and the full native
kernel suite pass. Contention tests cover an interrupted waiter, pending delivery
on owner unlock, wrong-owner and nested operations, preservation of caller-owned
break locks, task destruction and full heap reclamation. Interactive tests issue
a real Ctrl-Alt-C while a document lock is held, observe deferred delivery until
unlock, verify cleared ownership/pending state, reacquire the lock and compile
another command. The complete console corpus covers 164 commands / 227 input
lines, seven hardware hotkey cases and eleven document-lock commands with exact
VGA checks. Startup recovery, normal boot with an invalid probe and all 17 module
rejection cases pass.

All 1101 OS source hashes and eight build-input hashes match, as do both disk
hashes. The normal preview is refreshed. Kernel size is 363296 bytes, leaving
25824 bytes after the 4096-byte early stage. ConsoleRuntime retains 88776 bytes
from an 88760-byte image; CompilerRuntime retains 1322096 bytes from a 1322080-byte
image. Normal QEMU/486 boot at 8 MiB measured 15.674 seconds; diagnostics measured
134.584 seconds. Manifests retain the pre-commit revision and exact tested hashes.

The tests use a CDoc record's lock fields; they do not claim a complete initialized
document. Original creation/copy/reset/delete still reaches real callback,
DocTop/DocRecalc, reporting and global-state dependencies. Rendering/editing,
execution from the original editor and persistent save/reboot/reopen acceptance
remain open; the medium goal is not complete.


## Original task-document selection

The original DocPut, DocDisplay and DocBorder bodies are now shared through
`Adam/DolDoc/DocAccess.HC` and compiled into retained ConsoleRuntime 14. Native
public bindings preserve the default current-task argument, signature validation,
one-level input-filter forwarding for DocPut, and the task's own display/border
slots. Queries borrow pointers; they do not initialize or own documents. See
[document selection](i386-document-access.md).

The original platform lock wrappers moved to `Adam/DolDoc/DocLock.HC`, loaded by
MakeDoc before DocBin. DocNew now consumes the supplied lock interface without
requiring the x64 Yield/Break wrappers. The shared lock policy is unchanged.

Both x64 rebuild generations, the native exception/task suite and the full native
kernel suite pass. One eight-case corpus passes against original x64 functions,
native AOT functions and disk-loaded HolyC calling the retained public bindings.
The console suite covers 166 commands / 229 input lines with exact VGA checks,
seven hardware hotkey cases and eleven document-lock commands. Startup recovery,
normal boot with an invalid diagnostic probe and all 17 rejection cases pass.
All 1106 OS source hashes and eight build-input hashes match; both tested disk
hashes remain unchanged. The normal preview is refreshed from the tested image.

ConsoleRuntime 14 retains 91096 bytes (91080-byte image). Kernel size remains
363296 bytes, leaving 25824 bytes after the 4096-byte early stage. Normal QEMU/486
boot at 8 MiB measured 15.004 seconds; diagnostics measured 127.368 seconds.
Manifests record the pre-commit revision and exact tested hashes.

The selection corpus initializes only the fields these queries read. It does not
establish a complete live document. Real document initialization, globals,
reporting, callbacks and DocTop/DocRecalc dependencies remain ahead, followed by
rendering/editing and persistent save/reboot/reopen acceptance. The first usable
native DolDoc editing-session goal remains open.


## Shared document defaults

DocInit now delegates fixed entry/type defaults and derived masks to a shared
DocDefaultsInit helper. The original dictionary setup and document parser remain
unchanged. The helper preserves the dictionary pointer and adds required clean
scan codes without removing caller-added bits. CDolDocGlbls/dictionary kinds and
scan-code constants now have shared headers with unchanged field order and
values. See [document defaults](i386-document-defaults.md).

The former hard-coded default string and parser calculation are retained as an
independent x64 oracle. It compares every byte of the table span, including
repeat-initialization behavior. The native exception/task fixture runs the shared
initializer, preserves an injected dictionary pointer and extra clean-code bit,
and matches the x64 pointer-free fingerprint `c98dfea78567acec`. The fixture's
expected-result slot is verified; the earlier argument-slot error was corrected
before final validation. Native dictionary construction/publication remains open;
this is table initialization, not a complete native DocInit.

Both x64 rebuild generations, the native exception/task suite and the full native
kernel suite pass. The console corpus remains 166 commands / 229 input lines,
with exact VGA, seven hardware breaks, document locking/selection, startup
recovery, normal boot with an invalid probe and all 17 rejection cases passing.
All 1110 OS source hashes and nine build-input hashes match, including the new
independent oracle; both disk hashes remain unchanged. The normal preview is
refreshed. Manifests retain the pre-commit revision and exact tested hashes.

Kernel size remains 363296 bytes, with 25824 bytes of bootstrap headroom after
the 4096-byte early stage. ConsoleRuntime 14 remains 91080 bytes / 91096 retained.
Normal QEMU/486 boot at 8 MiB measured 15.003 seconds; diagnostics measured
127.151 seconds. Native definition-list/hash services and real document globals,
entry lifecycle, rendering/editing and persistence remain required. The usable
native editing-session goal is still open.

## Public hash tables for document initialization

MemoryRuntime 8 now publishes task-owned HashTableNew, HashTableDel, HashDel and
HashLstAdd. Original x64 and native implementations share table/list policy with
pointer-width-correct bucket allocation and exception cleanup for unpublished
allocations. Tests cover aliases, collisions, parent lookup/lifetime, public heap
ownership and failure cleanup on boot and worker tasks.

Both x64 rebuild generations and the full native suite pass: 168 commands / 231
lines, seven hardware breaks, exact VGA, startup recovery and 17 module rejection
cases. All 1117 OS hashes and nine build-input hashes match. Normal boot measured
16.105 seconds; separate diagnostics measured 129.578 seconds. See
[public hash tables](i386-public-hash-tables.md) for size and ownership details.

The original document editor is still pending. Next: native definition lists and
DolDoc dictionary initialization, then document creation, rendering, editing and
the save/reboot/reopen workflow. DolDoc dictionary type bits require their own
matching entry destructor; standard symbol deletion must not be used blindly.

## Owned definition lists for DolDoc

MemoryRuntime 9 retains DefineLstLoad and HashDefineLstAdd. The shared original/
native constructor now indexes its owned text copy, and symbol deletion frees
the index array. Construction is unpublished until complete and cleans up every
allocation-failure path. Public native headers expose the unchanged definition
records. See [definition lists](i386-define-lists.md).

Both x64 rebuild generations and the full QEMU/486 8 MiB suite pass, including
five failure points per task phase, 170 commands / 233 lines, exact VGA, startup
recovery and all 17 module rejection checks. All 1120 source hashes, nine build
inputs and both disk hashes match. Normal boot measured 16.708 seconds; separate
diagnostics measured 130.147 seconds. The preview contains this tested normal
image. Original DolDoc dictionary initialization and the editing workflow remain
open; this is a prerequisite, not completion of the native editor goal.

## Original DolDoc initialization on native startup

Normal native source startup now declares the original doldoc global and runs
DocInit using shared color names and the retained definition/hash services. The
disk includes the 33 original DolDoc source files. A dictionary-specific destructor
handles DHT entries safely and cleans partially constructed dictionaries.

Both x64 rebuild generations and the full native suite pass. Original/native
checks cover all 137 definition entries, 121 dictionary entries, the defaults
fingerprint and three dictionary create/delete cycles with unchanged heap usage.
Interactive validation passes 172 commands / 235 lines and exact VGA; startup
recovery and 17 module rejection checks also pass. All 1123 source hashes, nine
build inputs and both disk hashes match.

Normal startup measured 29.401 seconds, up from 16.708 seconds due to compiling
and running the document initialization sources; diagnostics remain separate
(141.982 seconds). The preview contains the tested normal image. See
[document initialization](i386-document-initialization.md). Document creation,
rendering, editing and save/reboot/reopen remain open; this does not complete the
usable native editing-session goal.

## Original document entry helpers and form navigation

Native startup now loads seven original functions shared with DocNew/DocForm:
text editability, base/tag allocation, entry size/copy, and forward/backward form
navigation. Extracted function bodies match the original source exactly. Shared
original/native tests cover independent text/binary copies, binary numbering and
queue insertion, task heap ownership, size accounting, reclamation and navigation
through forms, links, skips and sentinel recovery. See
[document entries](i386-document-entries.md).

Both x64 rebuild generations and the full native suite pass: 176 commands / 239
lines, exact VGA, startup recovery and 17 module rejection checks. All 1127 source
hashes, nine build-input hashes and both disks match. The preview is refreshed.
Normal boot measured 41.141 seconds (previously 29.401); separate diagnostics
measured 154.589 seconds. Retaining compiled document services should address
this growing startup cost. Full DocNew/reset/delete, reporting, recalculation,
rendering, editor callbacks and persistence remain open; the editing-session
goal is not complete.

## Retained document code and shorter normal startup

ConsoleRuntime 15 now retains the original document global, initialization,
dictionary, entry allocation/copy/size and form-navigation services. StartOS loads
public declarations and invokes initialization in the console task, avoiding
recompilation of these bodies at each boot. The loader binds eleven validated
public memory/hash services. The original x64 path still runs the shared bodies
in its existing order. See [retained document services](i386-retained-document-services.md).

Both x64 rebuild generations and the full native suite pass. All document corpora
now pass through retained bindings, including a repeated initialization that
preserves dictionary identity and heap usage. The prompt suite passes 178 commands
/ 241 lines, exact VGA, startup recovery and all 17 module rejections. All 1130
source hashes, nine build-input hashes and both disk hashes match.

Normal boot improved from 41.141 to 19.067 seconds; separate diagnostics measured
132.162 seconds. ConsoleRuntime retains 117160 bytes. Kernel size is 364664 bytes
with 24456 bytes of reserved-load headroom. The preview is refreshed. This removes
the growing startup compilation cost; full document lifecycle, reporting,
recalculation, rendering, editor callbacks and persistence still remain open.

## Original entry and binary lifetime with visible diagnostics

ConsoleRuntime 16 now retains original entry insertion/deletion, soft-line
removal, undo counting/cleanup and binary lookup/validation/deletion. A literal
reporting boundary uses original RawPrint on x64 and direct native text output
with a PIT-based timed pause and restored IF/display/input-filter state. This
does not publish a reduced substitute for the full RawPrint/formatter API. See
[entry lifetime](i386-document-entry-lifetime.md).

Both x64 rebuild generations and the full native suite pass. The shared lifetime
corpus checks insertion/splitting, cursor/queue state, binary cleanup and full
heap reclamation. Native checks cover visible invalid-deletion messages, their
three-second pauses and report-state restoration. Interactive validation passes
184 commands / 247 lines, exact VGA, startup recovery and 17 module rejections.
All 1138 source hashes, nine build inputs and both disk hashes match.

Normal boot measured 20.270 seconds; separate diagnostics measured 132.778.
ConsoleRuntime retains 137464 bytes; kernel reserved-load headroom is 24256 bytes.
The preview contains the validated normal image. Full document construction,
reset/delete, general formatting, recalculation, rendering, editor callbacks and
save/reboot/reopen acceptance remain open.

## Native text-base drawing primitives

ConsoleRuntime 17 publishes the original TextChar, TextLenStr, TextLenAttrStr and
TextLenAttr signatures over a native 80-by-60 U32 staging surface. Portable HolyC
preserves the original x64 assembly's window/screen clipping, scroll, border,
source-offset, attribute and occupied-cell fill behavior. The original assembly
remains an independent oracle. The surface is not yet attached to document
presentation or the full gr global; see [text base](i386-text-base.md).

Both x64 rebuild generations and the full native suite pass, including 256
original-assembly comparisons and 12 shared native cases with bounds guards.
Interactive validation passes 186 commands / 249 lines and exact VGA. Startup
recovery and all 17 module rejections pass. All 1142 source hashes, ten build
inputs and both disk hashes match. The preview contains the tested normal disk.

Normal boot measured 21.725 seconds; separate diagnostics measured 134.178.
ConsoleRuntime retains 168024 bytes, including the guarded cell surface. Kernel
reserved-load headroom remains 24256 bytes. Document presentation, construction,
recalculation, editor input and persistent editing-session acceptance remain open.

## Calendar provider for original formatting

ConsoleRuntime 20 retains the original calendar conversion, month/year boundary,
day-of-week and BCD routines plus the writable time offset. Shared declarations
preserve the CDate/CDateStruct layouts. Explicit arithmetic shifting preserves
original negative-year behavior across backends; month scanning and December
rollover now avoid the original out-of-bounds accesses. See
[calendar conversion](i386-date-conversion.md) for quantization and wrapping rules.

Both original x64 rebuild generations and the full native suite pass, including
1333 native calendar checks and 146 original comparison vectors. The full run
passes 203 commands / 266 lines, exact VGA and recovery checks, and all 17 module
rejections. All 1160 source hashes, 18 build inputs and both disk hashes match.
ConsoleRuntime retains 200744 bytes; kernel size remains 365760 bytes. Normal
boot measured 25.386 seconds and separate diagnostics 138.591 seconds. The
validated normal preview is refreshed.

The original formatter still needs real file/document serialization, address
formatting and output providers. Document save and recalculation form a dependency
cycle with formatting and must be integrated together. Full document lifecycle,
editor input and save/reboot/reopen acceptance remain open; the native editing
session goal is not complete.

## Original graphics context lifecycle for document rendering

ConsoleRuntime 21 retains 17 original device-context functions, including
construction, aliasing, deletion, reset, depth buffers, transforms and lighting.
Geometry/color/context/global declarations are shared with x64; the native CDC
is 376 bytes and preserves the 32-byte saved bitmap prefix. The standard palette
is shared unchanged. CompilerRuntime 49 supplies the existing software-F64
helpers to retained modules without copying the arithmetic implementation.
See [graphics contexts](i386-graphics-context.md).

Both original x64 rebuild generations and the full native suite pass. The
205-command / 268-line run includes 20 context ownership/behavior groups,
calendar/math regressions, exact VGA, interruption/startup recovery and all
17 module rejections. All 1169 source hashes, 18 build inputs and both disks
match. The native disk now includes all 29 original/shared graphics source files.

ConsoleRuntime retains 231712 bytes and CompilerRuntime 1342672 bytes. Kernel
size is 366496 bytes with 22624 bytes of bootstrap headroom. Normal boot measured
34.269 seconds; diagnostics measured 147.790 seconds. Public graphics headers
added about nine seconds to normal startup. The validated preview is refreshed.

Default framebuffers, sprite rendering, window integration and complete document
layout remain open, alongside the formatter/save/recalculation dependency cycle.
The native edit/execute/save/reboot/reopen goal is not complete.

## Native layered graphics frames on VGA

Normal startup now initializes the original persistent and working screen
contexts and connects the native text base. A retained presenter preserves the
original text/task/persistent/final-callback order, then converts packed pixels
to VGA planes. Graphics owns a separate plane buffer so restoring the raw
console preserves its contents. Context construction and temporary frame aliases
unwind on allocation/callback exceptions. See [graphics frames](i386-graphics-frame.md)
for the QEMU demo and ownership contract.

Both x64 rebuild generations and the full native suite pass: 214 commands /
277 lines, twelve original-renderer comparisons, four composed native RGB frames,
four existing text frames, allocation/callback recovery and all 17 module
rejections. All 1176 source hashes, 20 build inputs and both disks match.
The validated normal preview is refreshed.

The screen backing allocations consume 1314792 heap bytes, including rounding.
ConsoleRuntime 22 retains 241304 bytes; kernel size remains 366496 bytes with
22624 bytes of bootstrap headroom. Normal boot measured 35.121 seconds, separate
diagnostics 152.385 seconds. Demo frames measured 480–490 ms and 545256 temporary
heap bytes at the draw callback, reclaimed after Ctrl-Alt-C. Full-frame redraw
responsiveness remains work for the editor integration.

Original document layout, window/sprite services, the formatter/save/recalculation
cycle and the edit/execute/save/reboot/reopen acceptance workflow remain open.
This is a visible graphics integration step, not completion of the editing goal.

## Window geometry and original text borders

ConsoleRuntime 23 retains original text borders, clipped rectangle fills and
window scroll save/restore. Original and native geometry updates now share the
same arithmetic while preserving interrupt state. Startup initializes the actual
console viewport to 80 by 60 cells / 640 by 480 pixels. The full original
text-global record, both fonts and border glyphs are shared; document text uses
`gr.text_base`, and native frame presentation reads `text.font`.
See [window and text services](i386-window-text.md).

Both x64 rebuild generations and the full native suite pass: 217 commands /
280 lines, ten original/native window-text groups, all existing VGA comparisons,
startup/interruption recovery and 17 module rejections. All 1182 source hashes,
20 build inputs and both disk hashes match. The validated preview is refreshed.

ConsoleRuntime retains 253888 bytes, up 12584 bytes. The kernel remains
366496 bytes with 22624 bytes of bootstrap headroom. Normal startup measured
36.677 seconds and separate diagnostics 150.387 seconds. Graphics backing
allocations remain 1314792 bytes; demo frames measured 490–500 ms, with the
same 545256-byte temporary heap measurement and successful reclamation.

The shared rectangle fill now rejects empty bounds after clipping, preventing a
wholly offscreen rectangle from passing a negative count to the original fill
primitive. Full window-manager controls/z-order, sprite rendering, document
construction/formatting/layout, editor input and save/reboot/reopen remain open.
The native editing-session goal is not complete.

## Native resizing, control updates and visibility

ConsoleRuntime 24 retains the original task validation, window resizing and hit
testing, control lookup/update/hit testing, and visibility-map services. The
full original CCtrl record is shared. Every attached native task has an initialized
control-list sentinel, and reaping rejects attached controls before releasing
symbols or heaps. Shared resize cleanup restores locks and interrupt state when
a control callback throws. See [window services](i386-window-services.md).

Normal graphics startup owns the cell visibility map and uncovered-window
bitmap. Presentation refreshes them from the live public task ring; clearing the
old cell map prevents stale ownership after windows are hidden or shrunk.

Two original x64 rebuild/reboot generations, the focused native run and the full
QEMU/486 suite at 8 MiB passed. The full run covers 221 commands / 284 input lines,
fourteen shared resize/control groups, six visibility groups, both control-lifetime
rejections, all existing VGA comparisons, recovery and 17 module rejections.
All 1192 source hashes, 20 build inputs and both disks match. The validated normal
preview is refreshed.

ConsoleRuntime retains 275968 bytes, up 22080 bytes. Graphics backing allocations
consume 1333176 bytes, up 18384 bytes for the visibility resources. The kernel is
367816 bytes with 21304 bytes of bootstrap headroom. Normal startup measured
40.173 seconds, separate diagnostics 153.589 seconds. Demo frames measured
490–500 ms with 545256 temporary heap bytes, reclaimed after interruption.

Complete control construction/drawing, scrollbar and mouse integration, the
original window manager, sprite rendering, document construction/formatting/layout,
editor input and save/reboot/reopen remain open. The native editing-session goal
is not complete.

## Ordinary-text DolDoc prototype and focused TDD (2026-09-22)

Native normal boot now supports `DocNew`, `DocEd`, `DocWrite`, `DocRead` and
`DocDel` from the HolyC prompt. The editor uses canonical document records and
accepts printable text, cursor-left and backspace; Escape returns to the prompt.
RedSea writes permit saving and reopening a plain-text document across boots.
See [manual commands](../README.md) and [integration scope](i386-doldoc-integration.md).

The harness now offers eleven focused groups and a mutation runner that first
requires a clean baseline. Two representative runtime faults must produce their
specific wrong answers; timeouts and crashes do not count as detection. A separate
writable-copy acceptance drives QEMU keyboard input, compares editor VGA pixels,
saves, reboots the same copy, reopens and checks the serialized text/cursor bytes.
Normal boot remains independent of startup diagnostics.

Validation before wrap-up passed both x64 rebuild generations and the full native
build/boot suite on QEMU/486 at 8 MiB: 227 native commands / 290 submitted lines.
All 1200 recorded OS source hashes match the final implementation. The kernel is
382888 bytes; ConsoleRuntime retains 312232 bytes. Normal startup measured
43.020 seconds and separate diagnostic startup 157.564 seconds. The tooling's
initial mutation run detected both injected faults; its recorded image and scope
are listed in [the TDD workflow](i386-test-workflow.md).

During wrap-up, reporting was corrected: the five-point shared-loader round-trip
check runs under original x64 with original `DocSave`. The full native console
suite does not run that corpus; native persistence is checked separately through
the two-boot acceptance. The source-disk hash check now fails acceptance if the
source changes. Six host tests cover mutation verdicts and that protection.
The reporting gate was checked against the retained cross-build log, and Python
syntax/whitespace checks passed. These host-only corrections followed the full
build run; no OS source changed afterward.

A fresh wrap-up acceptance passed both boots on the final built image, including
all editor VGA checkpoints and persisted bytes. The source disk remained unchanged
(SHA-256 `73b05923a7943d1b007452c4ea46ef285fa2260295a70e542c6d5a98a150b9af`).
Evidence is in `build/i386-doldoc-wrapup/result.json`; startup measured 45.071 and
46.465 seconds. Generated reports and disk images remain local build artifacts.

This is an intermediate prototype, not completion of the original-editor medium
goal or M5. Original layout/recalculation, multiline editing, other navigation,
callbacks and exception cleanup, mouse interaction, executable documents and
embedded-record compatibility remain open. The acceptance covers a root-directory
file; nested-directory persistence is not established. Strict 386 and physical-PC
acceptance also remain open; current evidence is QEMU's 486 development profile.

## Multiline editing TDD slice (2026-09-22)

The first TDD slice for the larger native development-session goal is green. A
seven-point original/shared oracle types `ab`, newline and `cd`, moves left twice,
inserts and removes `X`, backspaces across the line boundary, and inserts `Z` at
the join. Its intended red result was `-5` at the final insertion; newline entry
creation and canonical newline deletion then made the original and shared paths
agree. The focused native `document-editing` group executes the same stable byte
and cursor assertions through retained `DocPutKey`/`DocSave`; 13 commands passed
on QEMU/486 with 8 MiB.

The keyboard/VGA acceptance now creates a second document, enters a visible
two-line state through QEMU key events, joins it back to `abZ<cursor>cd`, saves
both documents and reopens both after a fresh boot of the same copied disk. This
exposed a real storage limit: the original one-sector root had no slot after the
first new file. Native RedSea creation now grows a full root by relocating it to
a contiguous extent one sector larger, updating `.`/`..` and the boot-sector root,
then freeing the old extent. Both acceptance boots passed with exact VGA pixels
and serialized bytes; the source image stayed unchanged. Final evidence against
the full-gate image is in `build/i386-doldoc-multiline-final2/result.json`: the
source disk SHA-256 is
`f89b93acd5bcd6e1ea2b599906acf857a9c2d2f1ff1ce662cf92cadcc8a2d7a9`,
with 43.483 and 44.377 second startup measurements.

The complete native build gate also passes on that revision: both normal and
diagnostic boots, all console groups, original comparisons, module rejection
checks and source/image provenance. The full console log contains 299 submitted
lines and 236 harness commands; reporting now derives both values from the run
rather than relying on constants that predated this slice. The kernel remains
382888 bytes. Normal startup measured 43.404 seconds and diagnostic startup
159.003 seconds.

This adds basic multiline text to the prototype but does not complete original
`DocPutKey`, `DocRecalc`, `DocEd` or `MakeDoc` integration. Tabs, other navigation,
undo, original layout/callbacks, executable documents, nested-directory writes,
failure-atomic root growth and embedded records remain open. Strict 386 and
physical-PC evidence also remain open.

## Horizontal navigation TDD slice (2026-09-23)

The next part of editing slice 2 is green. An eight-point original/shared oracle
now covers Home, Right, Delete, Tab and End, including crossing a structural tab
entry. The native `document-editing` group repeats stable byte/cursor assertions
through retained bindings; its focused run passed 20 commands on QEMU/486 with
8 MiB. The full interactive console run passed 243 commands and 306 submitted
lines, including all eight reported navigation cases.

The writable acceptance adds `NativeNavigation.DD` and sends every new key through
QEMU's emulated keyboard. It verifies the tab-expanded VGA row, saves the
canonical tab and cursor bytes, reboots the same copied disk, reopens the file and
checks the display and bytes again. This exposed two loader defects: tabs were
rejected, then a cursor following a structural entry was restored onto an entry
that the serializer cannot mark. The loader now accepts tabs and normalizes such
a cursor to the following editable entry. A six-point original-`DocSave`/shared-
loader round trip protects that case. Final two-boot evidence is in
`build/i386-doldoc-navigation-final4/result.json`; startup measured 43.021 and
43.372 seconds, the source disk stayed unchanged, and its SHA-256 was
`0310d46fd271a07ac2bacf26e49c696a704b26ad20f368ed04231ea76dd2919b`.

At that point, slice 2 still lacked Up/Down and empty-line coverage. It also
remained open for allocation-failure recovery and integration of the complete original
`DocPutKey` dependency path are next. Original layout/recalculation, executable
documents, strict 386 and physical-PC acceptance also remain open.

## Vertical navigation and empty-line TDD slice (2026-09-23)

Vertical editing now has an eight-point original/shared oracle. It checks
preserved columns while moving between lines of unequal length, repeated Up and
Down, and both document limits. The first red result left the cursor on the
original line. Logical-line traversal now computes visual columns, including tab
widths, and selects the nearest valid position on the adjacent line without
requiring the full layout engine.

A separate thirteen-point boundary oracle covers an empty document, navigation and
editing keys on that document, an empty middle line, cursor serialization at a
newline, movement into and out of that line, and insertion there. It exposed a
backward traversal that skipped an empty line; the shared core now treats the
terminating newline as the empty line's cursor position. The serializer also
emits the cursor before structural entries, matching original `DocSave`, while
`DOCF_NO_CURSOR` suppresses it without overrunning the output allocation. Five
additional cases remove an insertion from the empty line, join it in both
directions, and verify Backspace at the top and Delete at the end are no-ops.
The intended red result occurred when a zero-length text entry prevented the
second join. Backspace now advances after erasing a final character and skips
empty text entries while crossing a line boundary, matching original `EdCharDel`.

The native `document-editing` group passes 51 commands on QEMU/486 with 8 MiB,
including eight vertical and thirteen boundary cases. The writable acceptance sends
Up and Down through the emulated keyboard in a three-line document, compares VGA
pixels, saves five documents, reboots the copied disk, and reopens all five.
Evidence is in `build/i386-doldoc-boundary-matrix/result.json`: startup
measured 43.422 and 43.870 seconds, the source disk stayed unchanged, and its
SHA-256 was
`8147df9f6943006ee376446490453b9f3773893302f7ef176d83f2ad3a50cf0c`.

The complete native gate passes on the same image: normal and diagnostic boot,
all console groups, original comparisons, source provenance, and module rejection
checks. The full interactive run completed 288 harness commands and 351 submitted
lines; normal startup measured 43.122 seconds. Both x86-64 rebuild generations
also pass against the final source inputs.

Editing slice 2 is still open for integration of the complete original
`DocPutKey` dependency path. Layout/recalculation and executable-document work
remain in later slices.

## Deterministic document allocation recovery (2026-09-23)

The retained ordinary-text document path now routes its allocations through a
normally transparent fault injector. `DocNew` reclaims partial construction;
tagged-entry construction reclaims its base record; editing releases `DocLock`
and partial entry/text allocations; and serialization releases the lock if its
output allocation throws. The shared x86-64 entry helper retains its original
successful behavior and now has the same partial-construction cleanup.

`DocAllocationCheck` initially exercised ten recovery outcomes without running at startup:
all three constructor allocations; base-entry and tag allocation for the first
character; replacement-text allocation; newline allocation; save allocation;
then a successful edit/save and final heap balance. Each failed locked operation
also checks that ownership and `DOClf_LOCKED` are clear and that document content
is unchanged. The focused `document-editing` run passed 66 commands on QEMU/486
with 8 MiB and exact VGA checkpoints. Startup measured 43.221 seconds and the
disk SHA-256 was
`9f40718be5491dda6a18528200f838c707e16215a7aac9a05db8bae01ecc72da`;
evidence is in `build/i386-doc-allocation-1/result.json`. Both x86-64 rebuild
generations and the original/shared oracles also pass.

The subsequent complete gate passes against the same source and disk: normal and
diagnostic boot, every console group, original comparisons, module rejection and
source/image provenance. The interactive run completed 289 harness commands and
352 submitted lines; normal startup measured 43.171 seconds and diagnostic
startup 157.379 seconds. The kernel remains 382888 bytes. The full result records
the same normal-disk SHA-256 above in `build/i386-kernel/result.json`.

That checkpoint closed allocation recovery for construction, the retained basic
editing operations and serialization; disk-backed loading was the next gap.

The check now adds two disk-backed outcomes. `DocRead` catches a load-time
`OutMem`, frees the owned RedSea read buffer and deletes its partial document.
The test writes `C:/AllocRead.DD`, fails the first loaded entry after successful
document construction, verifies exact heap balance, then reopens and serializes
the same content and cursor successfully. The intended first red result was the
oracle's assumption that adjacent characters occupy one entry; comparing public
serialized bytes instead captures the persistent contract. The twelve-outcome
focused run passed 66 commands on QEMU/486 with 8 MiB, 43.320-second startup and
disk SHA-256
`726d5f35f8b1c68addfae36c62a8e47ca451460e7d90d760883eab7277ebbd51`.
Evidence is in `build/i386-doc-read-allocation-3/result.json`. Persistent
file-replacement failure and the complete original editor graph remain open.

The final complete gate passes on the resulting image: 289 interactive harness
commands / 352 submitted lines, all console groups, normal and diagnostic boot,
original comparisons, module rejection and source/image provenance. Normal
startup measured 43.172 seconds, diagnostic startup 158.779 seconds, and the
kernel remains 382888 bytes. The normal disk SHA-256 is
`99a2de8deefafc3bb8d4092cd1a2bd93bc6d9d6c9592624f98f4af6c14f0c765`.

The writable five-document acceptance also passes after the `DocRead` cleanup
change. Its create/edit/save boot measured 42.968 seconds; its fresh reopen boot
measured 43.472 seconds. Every hardware-keyboard/VGA and persisted-byte assertion
passed, and the source image stayed unchanged. Evidence is in
`build/i386-doldoc-read-recovery-final/result.json`.

## First executable document and reboot (2026-09-23)

The retained public `DocExe` adapter now locks a canonical document, temporarily
suppresses cursor serialization, restores its flags and lock on every path, and
executes the resulting source through the live console compiler. This preserves
the console's definition scope, diagnostics and break boundary while the complete
original `ExeDoc` dependency graph remains open.

The intended red run reached normal startup and document construction, then
failed because `DocExe` was undefined. The focused green run constructs a
multiline function document, executes it with visible result `42`, and calls the
retained definition afterward. All 75 `document-editing` commands passed on
QEMU/486 with 8 MiB and exact VGA checkpoints; startup measured 43.521 seconds.
Evidence is in `build/i386-doc-execute-green-5/result.json` and the normal disk
SHA-256 is
`8fb30b9dc374dd8d638d66c772eea5bf1de266ffe93998980f858f64eb856232`.

Native compiler statement case 34 now retains the DolDoc investigation's queue
boundary. Generated i386 code walks four mixed-type records in a circular linked
list, snapshots each next pointer, dispatches on an eight-bit type and returns the
expected aggregate 19. Both root and worker compiler phases pass, showing that
ordinary generated queue traversal did not cause the abandoned foreground-record
serializer to emit only its first text entry. The full QEMU/486 8 MiB gate passes
with all 35 statement cases in both phases, 298 interactive commands and 361
submitted lines; normal startup measured 43.824 seconds. The kernel remains
382888 bytes, its SHA-256 remains
`2c5d325753ea202b5a39b7df79cffa3d587ab72f1d6fb682b30654f82acc8500`, and the
new normal-disk SHA-256 is
`ebc3aeda01a6ddcf7fa7df780badf6beb3938717a2730c5f16643b9161105b79`.

## First structured DolDoc persistence (2026-09-23)

Native `DocSave` and `DocRead` now preserve foreground and background color
records in addition to the ordinary-text subset. The supported `FG` and `BG`
encodings accept attributes 0 through 15 or the default attribute; literal
dollar bytes are doubled on save and collapsed on load so text cannot become a
record after reopen.

The first fixture corrupted the public heap because `DocEntryNewBase` allocates
only `CDocEntryBase`, while foreground `attr` lives in the larger `CDocEntry`.
The corrected fixture and loader follow the original parser's full-record
allocation contract. `DocAllocationCheck` now performs an exact 37-byte
foreground/background save, structured load and second save, then verifies heap
balance. A focused normal boot passed that check on QEMU/486 with 8 MiB.

The full gate passes after connecting the record-aware functions to public file
I/O: both x86-64 rebuild generations, both native compiler phases, normal and
diagnostic boots, 298 interactive commands / 361 submitted lines, exact VGA
checks, provenance and rejection cases. The kernel remains 382888 bytes. Normal
startup measured 43.974 seconds; the normal disk SHA-256 is
`629de2b7a1741ebdf33d794be57d873372358099aaf50c489f45d040c3a75c0d`.
The native editor now renders this first structured record directly from the
canonical entry queue. It changes `CI386Text.foreground` and
`CI386Text.background` for subsequent glyphs and restores the respective
document defaults at reset records, while retaining the existing cursor behavior
for text and structural entries. The routine no longer shows color-record
serialization syntax in the editing view.

A focused eight-command boot compares the complete framebuffer: only `red` is
VGA red and the following ` plain` plus cursor are black. The regular
`document-editing` group passes 83 commands with the same colored-pixel oracle
at 43.875-second startup. The writable acceptance passes three QEMU/486 8 MiB
boots at 43.624, 43.826 and 43.825 seconds. It writes `NativeColor.DD`, reopens
and renders it after reboot, verifies its exact 20 serialized bytes, and audits
the same bytes independently from RedSea. The final image contains 17
directories, 720 files and 12516 uniquely owned sectors with a matching bitmap;
the source image is unchanged and the writable candidate SHA-256 is
`2fe21d6380ea791a5844057a1a093709a89402c135cae1c1111dbadf57df7677`.

Background color then extended the same gate. The regular `document-editing`
group passes 87 commands: `red` has VGA-red foreground, ` blue` has VGA-blue
background, and both following text and cursor return to their defaults. The
three-boot writable acceptance passes at 43.523, 43.772 and 43.771 seconds. Its
independent disk walk finds the exact 39-byte color document, 17 directories,
720 files and 12531 uniquely owned sectors with a matching bitmap. The source
image is unchanged; the writable candidate SHA-256 is
`28f82f3c6f5152e7f14210e93504e566ac89acd269e584810bd05d87dfc38cab`.

Invert and underline now use the same serializer/loader pipeline through `IV`
and `UL` records with boolean attributes. The renderer keeps logical foreground
and background state so inversion swaps the current pair without losing later
color resets. `CI386Text` now draws underline as the eighth glyph scanline and
initializes that state for every console/editor frame.

The expanded 76-byte core fixture survives an exact structured round trip with
heap balance. The regular `document-editing` group passes 95 commands with exact
pixels for red foreground, blue background, inverted text, underlined text and
all four resets; startup measured 43.873 seconds. The three-boot writable
acceptance passes at 43.472, 43.925 and 43.973 seconds, reopens the styled file,
and independently verifies its exact 78 persisted bytes. The resulting RedSea
image has 17 directories, 720 files and 12561 uniquely owned sectors with a
matching bitmap. Its SHA-256 is
`c687712bc9472f14051f2e96d457889285cebd3e6792c1a12cc0777dcafee3be`;
the source image remained unchanged.

Other DolDoc commands, blink/highlight behavior, binary records and
original/native cross-reading remain open.

The native editor can now author two of those styles through the original
keyboard contract. Ctrl-U and Ctrl-Z insert underline/invert-on records;
Shift-Ctrl-U and Shift-Ctrl-Z insert their off records. Record construction uses
the full canonical `CDocEntry`, task-owned allocation and normal `DocInsEntry`
cursor semantics. The focused hardware-keyboard group creates styled text from
an empty document, verifies its pixels and exact 39-byte serialization, and now
passes 101 commands at 43.922-second startup.

The three-boot acceptance also saves this keyboard-authored document, reopens it
after reboot and repeats the pixel comparison. Its boots pass at 43.572, 43.772
and 43.925 seconds. The independent disk audit finds the exact record stream,
17 directories, 721 files and 12569 uniquely owned sectors with a matching
bitmap. The candidate SHA-256 is
`5668958e65d955225d374274c0b580a631ebca7c91c61b88e27955a2cc0401c8`;
the source image remained unchanged.

## Editor execution and recovery (2026-09-23)

Native `DocEd` now uses F5 to open a clean document-execution view and Escape to
return to the unchanged editor. `DocExe` copies the cursor-free source and
filename while locked, then releases `DocLock` before entering generated code.
This corrects the first implementation's interruption deadlock: document locks
set `TASKf_BREAK_LOCKED`, so retaining that lock around an infinite program
prevented pending breaks from being delivered.

The hardware acceptance first failed on the old image precisely at the missing
F5 action. It now exercises three recovery paths within live editor sessions: a
syntax error is displayed, corrected with keyboard edits and rerun to produce
`42`; a thrown runtime exception returns to the document, which is replaced with
a successful expression; and a program emits a runtime marker, loops, and is
interrupted with Ctrl+Alt+C before the console proves continued execution. The
multiline saved program also executes through F5 before writing and again after
reboot.

The final acceptance adds a software-F64 document whose F5 result is exactly
`3.75`. Evidence is in `build/i386-doldoc-editor-complete-green-1/result.json`.
Its create/edit/save boot ran 46 commands in 44.075 seconds; its reopen boot ran
31 commands in 46.179 seconds. Every keyboard/VGA checkpoint passed on QEMU/486
with 8 MiB, the source disk SHA-256 was
`939228ce9c47bdbe09cb56dd1713f8c051e51923969363a4c53bb75bea575d4f`,
the source disk remained unchanged, and the writable candidate SHA-256 was
`f58c26dc6fc6471bf71768046cb1706d4745d60c2a556b76951fa4a8fb3c3bb5`.

The complete gate passes on the final editor-execution source. Both x86-64
rebuild generations, original/shared comparisons, normal and diagnostic native
boot, all console groups, source provenance and module rejection checks pass.
The interactive run completed 298 commands and 361 submitted lines with
43.372-second startup; diagnostic startup measured 157.570 seconds. The kernel
remains 382888 bytes and the normal-disk SHA-256 is
`97b8b0ef80ef43fd040f6b2cb565183158f844ca27b5bbcb984aedae38001353`.

F5 now follows the original editor's save-before-execute order. The intended red
run executed the program but failed after reboot at `saved_program!=0`, proving
that persistence no longer depended on a harness-side `DocWrite`. The green
two-boot run in `build/i386-doldoc-f5-save-green-1/result.json` passed every exact
VGA and keyboard checkpoint on QEMU/486 with 8 MiB. Its first boot ran 46 commands
in 43.874 seconds and its reopen boot ran 31 commands in 43.672 seconds. The
source disk remained unchanged with SHA-256
`97b8b0ef80ef43fd040f6b2cb565183158f844ca27b5bbcb984aedae38001353`;
the writable candidate SHA-256 was
`85c467173d14a99b33c1f65955678e2635b6008f6f6af47905785718a2398044`.

The writable acceptance now proves replacement persistence across three boots.
It creates a multiline program that returns `42`, reopens it, changes the literal
to produce `48` using hardware-keyboard events, and saves the replacement through
F5. The third boot reopens the exact revised source and executes `48` again. The
three QEMU/486 8 MiB startups measured 43.723, 43.773 and 43.672 seconds; every
VGA checkpoint passed. Evidence is in
`build/i386-doldoc-revision-green-4/result.json`; the source image remained
unchanged and the candidate SHA-256 was
`30b8b42eb85cf002dc85da4ab592f12896980f0d31fed3d26bb9476e7f841d70`.

F5 save failure is now user-visible. A document at the deliberately missing-parent
path `C:/Missing/Unsaved.HC` reports `Save failed` in the result view, still
executes its in-memory source as `42`, returns to the unchanged editor and passes
an exact serialization check. The intended red run logged the failure but omitted
the VGA message. The green case is part of
`build/i386-doldoc-save-failure-green-1/result.json`: its three startups measured
43.626, 43.672 and 43.621 seconds, and its writable candidate SHA-256 was
`089c414f0d276239d3de649cd5360f1af6b7ef022d082f41a92eb60780646a94`.
This proves application-level recovery from a rejected path; injected device I/O
failure and crash-safe replacement remain open.

Public native `DirMk` and nested project persistence now pass. FileRuntime ABI 25
adds a directory callback and uses the original RedSea `0x810` directory layout
with `.` and `..` entries. File create/replace now owns the ATA session across
parent resolution as well as mutation; resolving before acquisition was the
defect exposed by the first nested-file test. The three-boot acceptance creates
`C:/Project/Sub/Main.HC`, executes `49`, and reopens and executes it after reboot.
Evidence is in `build/i386-doldoc-deep-integrity-green-1/result.json`; its
startups were 43.574, 43.773 and 43.874 seconds, all VGA checkpoints passed, the
source disk remained unchanged, and the candidate SHA-256 was
`bcc9dda8236d5853a9427f498d4fdcc21310dc10f042f7fc56514e48fc879a4b`.

The same acceptance now independently walks the resulting RedSea image. Before
the fix, that audit found direct child directories whose `..` records referenced
freed historical root extents after root growth. Root relocation now repairs all
direct child parent records after publishing the new root and before reclaiming
the old extent. The green disk contains 17 directories, 716 files and 12441
uniquely owned sectors; every reachable extent agrees with the allocation bitmap,
and `Project/Sub/Main.HC` contains the exact five serialized bytes.

Relative project paths now pass the same three-boot acceptance. The first boot
creates `Project/Sub/Relative.HC` through F5 and executes `64`; the third boot
reopens it with the same user-visible relative name and executes `64` again. The
disk walk resolves it at `/Project/Sub/Relative.HC` with exact serialized bytes.
Evidence is in `build/i386-doldoc-relative-green-2/result.json`: startups were
43.824, 43.925 and 43.777 seconds, all VGA checkpoints passed, the source image
was unchanged, and the candidate SHA-256 was
`e772adc675204815c7d27d72b4596fc2cb9dc895580e738582190a19dcee7ded`.

The complete gate passes with root-parent repair and the directory service in the
retained FileRuntime ownership evidence. Both x86-64 rebuild generations, normal
and diagnostic native boot, all console groups, source provenance and module
rejection checks pass. The interactive QEMU/486 run at 8 MiB completed 298
native commands and 361 submitted lines with 43.773-second startup; diagnostic
startup measured 156.980 seconds. The kernel is 382888 bytes, the normal-disk
SHA-256 is `9ffca1f65a83ac6c4a7abb9a77f5963c483444e75cf5d0c3c30c7a3cfb606695`,
FileRuntime retains 179336 bytes from a 179320-byte image, and the kernel SHA-256 is
`2c5d325753ea202b5a39b7df79cffa3d587ab72f1d6fb682b30654f82acc8500`.

The complete gate passes on the save-failure source: both x86-64 rebuild
generations, all original/shared comparisons, normal and diagnostic native boot,
every console group, source provenance and module rejection. The interactive run
completed 298 native commands and 361 submitted lines with 43.424-second normal
startup; diagnostic startup measured 157.969 seconds. The kernel remains 382888
bytes and the normal-disk SHA-256 is
`5bec532c6c6eba2eaf0fbec0d702e98dd5a54a184188ddac6fdebbcd2108c435`.

The writable acceptance also creates and executes `C:/NativeProgram.HC`, saves
it to RedSea, boots the modified disk copy, reopens it and executes it again.
Both visible results are `42`, and the definition is callable after reopen. Its
create/save boot measured 43.673 seconds and its reopen boot 43.828 seconds; all
61 commands and VGA checkpoints passed, and the source disk stayed unchanged.
Evidence is in `build/i386-doldoc-execute-session-1/result.json`; the candidate
disk SHA-256 is
`e9fecca74fd3a555818641ecfee0d6599eb069e19999a43a1f4f48deb3658943`.

The complete gate passes on the final source: both x86-64 rebuild generations,
all original/shared comparisons, normal and diagnostic native boot, every
console group, source provenance and module rejection. The interactive run
completed 298 native commands and 361 submitted lines with 43.472-second normal
startup; diagnostic startup measured 157.770 seconds. The kernel remains 382888
bytes and the final normal-disk SHA-256 is
`8fb30b9dc374dd8d638d66c772eea5bf1de266ffe93998980f858f64eb856232`.

## Timed blinking DolDoc text (2026-09-23)

The retained editor now supports original Ctrl-K and Shift-Ctrl-K blink-on/off
authoring. `BK` entries pass through the record serializer and loader alongside
color, invert and underline records. The renderer follows TempleOS text-layer
semantics by swapping foreground and background during the active half of a
500 ms clock phase. `DocEd` polls the keyboard cooperatively and redraws only on
an edit or phase transition, so blinking continues while the editor is idle.

The clock crosses the retained module boundary explicitly: ConsoleRuntime ABI
25 receives the kernel jiffy pointer in `CI386ConsoleConfig`. This avoids direct
console-module relocation against the kernel `cnts` global. The exact record
round-trip check includes both `BK,1` and `BK,0`, including the `BG`/`BK` prefix
distinction that the first reboot test exposed.

The writable three-boot acceptance in
`build/i386-doldoc-blink-session/result.json` creates blinking text with the
hardware Ctrl-K sequence, observes both opposite VGA frames, writes it to
RedSea, reboots, reloads it and observes both frames again. All pixel checkpoints
passed at 43.624, 43.875 and 43.776 seconds. The independent filesystem audit
found 17 directories, 722 files and 12588 uniquely owned sectors with a matching
bitmap; the source disk was unchanged and the candidate SHA-256 is
`735ffbc83ba2a991698e3efb437fedede1e4b4d1b583af13d53f2b2fc0e6699f`.
The focused `document-editing` run also passed 106 native commands at 43.924
seconds with exact pixels for both phases. Two x86-64 rebuild generations, the
native build, Python runner tests and source-format checks pass.

## Direct editor save command (2026-09-23)

Native `DocEd` now implements the original Ctrl-S save binding. It calls the
public `DocWrite` path without executing the document and reports `Saved` or
`Save failed` in the editor heading. Editing after either result clears the
status and continues in the same canonical document.

The focused hardware-keyboard test writes `C:/CtrlSave.DD` with Ctrl-S, exits the
editor, reopens it from RedSea and compares the exact cursor-bearing bytes. A
second case targets a missing parent, checks the visible failure, continues
editing the unchanged in-memory document and confirms no file appeared. The
expanded `document-editing` group passed 116 native commands at 43.977 seconds
with every VGA checkpoint exact. The three-boot writable acceptance also saves
the blinking fixture through Ctrl-S rather than a harness-side `DocWrite`; its
boots measured 43.624, 43.824 and 43.873 seconds, its independent RedSea audit
found 17 directories, 722 files and 12592 owned sectors, and its candidate
SHA-256 is `c49e2903cff48bf083297ae041c71b31b7a515cd3dd0316b75f9acef15f97cb6`.

The complete gate passes on this source. The normal interactive QEMU/486 run at
8 MiB completed 339 native commands and 402 submitted lines with 43.925-second
startup; diagnostic startup measured 157.376 seconds. Original/shared oracles,
normal and diagnostic native boots, all console groups, source provenance and
module rejection checks passed. The kernel is 382936 bytes, its SHA-256 is
`cdfdc84628aacfc0909f08d9c011ff83c819b21df66c9026e988b65b2706a9e4`,
and the normal disk SHA-256 is
`dfa69c6a3b580dcd56b533cb54197de114330a472ab23d79d06794a3aa1a298c`.

## Standalone file editor workflow (2026-09-23)

The native prompt now exports `Ed(path)` as a file-level editor service through
ConsoleRuntime ABI 26. It loads an existing document or creates a new one,
enters `DocEd`, saves and releases it after Escape, and releases it without a
write after Shift-Escape. `DocEd` now returns the original accept/cancel result
instead of treating both exit keys alike.

The focused hardware-keyboard group creates `C:/FileEditor.DD` with `Ed`, exits
with Escape and verifies its exact disk bytes. It then visibly appends a byte,
exits with Shift-Escape, receives a false result and proves the stored bytes did
not change. The expanded group passed 124 native commands at 44.176 seconds with
all VGA checkpoints exact.

The writable three-boot acceptance repeats the workflow on
`C:/StandaloneEdit.DD`: the first boot creates and saves `standalone`, the second
boot appends a visible `X` and cancels, and the independent final disk walk still
finds exactly `standalone` plus the cursor marker. All checkpoints passed at
43.771, 44.074 and 44.073 seconds. The audited image contains 17 directories,
723 files and 12597 uniquely owned sectors with a matching bitmap; its SHA-256
is `2a9d2a925d7919999f44494ea93dc97792a010be48dd8a95e2cabd18000cc146`.

The complete gate passes with ConsoleRuntime ABI 26. The normal interactive
QEMU/486 run at 8 MiB completed 347 native commands and 410 submitted lines with
44.175-second startup; diagnostic startup measured 157.776 seconds. All
original/shared comparisons, normal and diagnostic boots, console groups,
source-provenance checks and module rejection checks passed. ConsoleRuntime
retains 413232 bytes from a 413216-byte image. The kernel SHA-256 is
`13d325b857d7a7528cd00e3c7d0db1b427bb9ceebd9016c5974594aa6bab61b2`;
the normal disk SHA-256 is
`797fb4e6b7c88d04533ec623cc0dc06fd1aa666a9d533d079d50337705358837`.

## Cursor-following document viewport (2026-09-23)

The retained editor no longer feeds an arbitrarily long document into the
whole-screen terminal scroller. It first measures the canonical cursor row,
chooses a 56-row body viewport, and then renders only that range beneath the
four fixed heading rows. Both passes share tab expansion, newline handling and
80-column wrapping. Color, blink, invert and underline state still advances
through clipped entries before visible text is drawn.

The hardware/VGA acceptance constructs a 65-line document with numbered lines.
At entry it shows lines 09 through 64 with the cursor after `64`; one Up key
shows lines 08 through 63 with the cursor after `63`. In both exact 60-row
captures the TempleOS/editor/path heading remains fixed. The expanded focused
`document-editing` group passed 128 native commands at 44.073 seconds. This is a
bounded native viewport; original `DocRecalc`, horizontal scrolling and embedded
graphics remain part of the open editor-integration slice.

The complete gate passes on the viewport source. The normal interactive QEMU/486
run at 8 MiB completed 351 native commands and 414 submitted lines with
44.025-second startup; diagnostic startup measured 157.570 seconds. All
original/shared comparisons, boot modes, console groups, provenance checks and
module rejection checks passed. ConsoleRuntime ABI 26 retains 422424 bytes from
a 422408-byte image. The kernel SHA-256 is
`9083b8f67d1235c75d4c43ca4d185e0c921149b73ff911ce6ee27264da5750ae`;
the normal disk SHA-256 is
`9b939c98521c1c9ac4be6702a38327eda5b1d437c85f26029dadb10ef420fd3b`.

## Cursor-following horizontal viewport (2026-09-23)

The same two-pass document renderer now respects `DOCF_WORD_WRAP`. Wrapped
documents retain 80-column row advancement; unwrapped documents keep their
logical line and choose an 80-column horizontal viewport that contains the
cursor. Clipped prefixes still update style and tab state before visible cells.

The hardware/VGA check creates one 100-character line. At End it shows the final
79 characters followed by the cursor block; Home pans back to show the cursor
followed by the first 79 characters. The heading remains fixed and both frames
match exactly. The expanded focused `document-editing` group passed 132 native
commands at 44.075 seconds.

The complete gate passes on the horizontal-viewport source. The normal
interactive QEMU/486 run at 8 MiB completed 355 native commands and 418
submitted lines with 44.072-second startup; diagnostic startup measured
157.576 seconds. All original/shared comparisons, boot modes, console groups,
provenance checks and module rejection checks passed. ConsoleRuntime ABI 26
retains 425216 bytes from a 425200-byte image. The 382936-byte kernel SHA-256 is
`13d325b857d7a7528cd00e3c7d0db1b427bb9ceebd9016c5974594aa6bab61b2`;
the normal disk SHA-256 is
`b4e12b8adc9d3a5aeb5cf23d5cc1c4b8fbeaf1f7ac99c55639b8a44ee2228053`.

## Bounded repeated development sessions (2026-09-23)

A native resource acceptance now performs one warm-up followed by 20 complete
document-development cycles. Each cycle creates and saves a HolyC document,
deletes it, reopens it from RedSea, edits and serializes the cursor-bearing
source, saves it again, executes it in the live compiler, and deletes it. It
then executes a separate document that throws at runtime and verifies recovery.
The program increments retained state exactly once per cycle, proving execution
rather than merely successful parsing.

After warm-up, every cycle must return both `Fs->data_heap->used_u8s` and
`Fs->code_heap->used_u8s` to their exact baselines. The check also records both
warmed live-byte counts and their reserved heap capacities, requiring each
capacity to cover its live allocations. The focused `document-resources`
hardware/VGA group passes all 20 measured cycles, observes all 21 caught
exceptions including warm-up, and ends with the expected 21 executions. The
expanded three-command group starts QEMU/486 at 8 MiB in 44.189 seconds and
matches every VGA checkpoint exactly. The two heap handles currently alias one
shared task heap; they are not independent pools.

The complete gate passes with the resource acceptance in the accumulated
interactive session. It completed 357 native commands and 420 submitted lines
with 44.407-second normal startup; diagnostic startup measured 159.598 seconds.
All original/shared comparisons, boot modes, console groups, provenance checks
and module rejection checks passed. ConsoleRuntime ABI 26 retains 425216 bytes
from a 425200-byte image. The 382936-byte kernel SHA-256 is
`13d325b857d7a7528cd00e3c7d0db1b427bb9ceebd9016c5974594aa6bab61b2`;
the normal disk SHA-256 is
`7e1b1fdbdd70ac06146b7524dc156aeddd6242449cefdbb720ab1618705912c3`.

MemoryRuntime ABI 10 adds scoped high-water measurement at the public allocator
boundary, so document and compiler temporaries are observed at allocation time
rather than sampled after `DocExe` has already released them. After the warm-up
cycle, the 20-cycle workflow starts from 1,352,216 live bytes, reaches a
1,355,832-byte live peak (3,616 bytes temporary growth), and reaches a
1,356,800-byte reserved-capacity peak. It returns to the exact live baseline
after every cycle. The expanded four-command `document-resources` group passes
at 44.287-second startup with exact VGA output, and the compiler/kernel
self-rebuild provenance gate passes. Full-gate evidence for ABI 10 remains open.

The complete ABI 10 gate passes. Its normal QEMU/486 run at 8 MiB completed 359
native commands and 422 submitted lines with 44.125-second startup; diagnostic
startup measured 158.783 seconds. All original/shared comparisons, boot modes,
console groups, provenance checks and module rejection checks passed. The
382936-byte kernel SHA-256 is
`67e8b01ac75a8c85209f8b8975f4072664274b3d780c1e2a0a30b20a398ffdc2`;
the normal disk SHA-256 is
`ecf9449c12182da81f1a4d3eb17bb8663eb633b5a5746aea33e5866b4ea4fe35`.
MemoryRuntime retains 161552 bytes from a 161536-byte image.

A focused `document-latency` hardware/VGA group now times the complete path from
an injected Up-key event to the exact 60-row long-document frame. On the
QEMU/486, 8 MiB development profile it measured 0.204 seconds and passed a
one-second key-to-visible-update budget; startup measured 44.173 seconds. This
includes QMP injection, guest keyboard handling, document traversal, redraw and
host screendump comparison, so it is a conservative end-to-end measurement.
The existing nonterminating-program acceptance now applies the same method from
Ctrl-Alt-C injection through the exact recovered execution frame. It measures
0.217 seconds, passes the one-second budget, returns to the intact editor and
then evaluates `6*7` as `42`, proving continued compiler usability.

The complete writable acceptance also passes with latency recording enabled.
Its create/edit/save, reopen and revised boots measured 43.674, 43.884 and
43.672 seconds; the accumulated interrupt-to-recovered-VGA measurement was
0.275 seconds. It ran 90, 52 and 13 commands, matched every VGA checkpoint, and
left the source disk unchanged. The independent RedSea walk found 17
directories, 724 files and 12640 uniquely owned sectors with a matching bitmap.
The writable candidate SHA-256 is
`7ffc17b542ea4bce4c7fccf34acbacfd052dc3f07d3b2b71dce7b2eff752d79d`.
A repeatable human long-document checklist is now in the test workflow; an
observed human run remains open.

## Page-sized document navigation (2026-09-23)

The canonical ordinary-text edit core and native `DocEd` now handle Page Up and
Page Down. Because four rows are reserved for the fixed heading, each key moves
55 logical lines through the 56-row body while preserving the desired column.
The existing 65-line hardware/VGA fixture first moves from line 64 to 63, Page
Up lands exactly on line 08, and Page Down returns to line 63. All three
60-row frames match exactly. The focused `document-latency` group passes four
commands at 44.173-second startup; its single-line Up path measured 0.263
seconds against the one-second budget.

The corresponding complete gate passes 359 native commands and 422 submitted
lines. Normal startup measured 44.176 seconds, diagnostic startup 158.980
seconds, and the accumulated long-document Up path measured 0.258 seconds. The
kernel SHA-256 is
`ecb594d5d15c15141e0c945216971bd89f4694e8852960b9d050cb2189357421`;
the normal disk SHA-256 is
`111bb929482659cc384f8f02a4c9687dcf35558747232628263b0b28d33bc5d1`.

Original Ctrl-Up and Ctrl-Down document-boundary navigation is now present as
well. The native core admits only those two Ctrl-modified scan codes, mapping
them to document start and end while continuing to reject unsupported modified
navigation. The 65-line hardware sequence proves Page Down to line 63,
Ctrl-Up to the cursor before line 00, and Ctrl-Down to the cursor after line 64.
The expanded exact-frame group passes at 44.124-second startup with 0.203-second
single-line Up latency.

The corresponding complete gate passes 359 native commands and 422 submitted
lines. Normal startup measured 44.177 seconds, diagnostic startup 158.782
seconds, and the accumulated long-document Up path measured 0.257 seconds.
All original/shared comparisons, boot modes, console groups, provenance checks
and module rejection checks passed. The kernel SHA-256 is
`580425fd6155522e4bcbf9fc89574e64a8cc5f001b064395ad7d57dc5dfacd36`;
the normal disk SHA-256 is
`98ab69aa5666c0450927b34db1dc7470f46b067b5682babafec08fd3560e681f`.

## Exceptional editor exit recovery (2026-09-23)

The native editor now places its keyboard/VGA loop inside an exception cleanup
boundary. A propagated exception restores the task's previous put and display
documents and reconstructs the HolyC console surface before the outer console
handler reports the error. Its idle loop also provides an explicit pending-break
checkpoint, allowing Ctrl-Alt-C to interrupt an editor waiting for input.

The focused hardware test enters an empty document through `DocEd`, sends a real
Ctrl-Alt-C key chord, observes the editor exception boundary and the recovered
console, and then verifies the exact prior document pointers, an unlocked
document, a consumed pending break and a subsequent `6*7` result of `42`. The
expanded `document-editing` group passes 132 commands with exact VGA output at
44.172-second startup. Original border/input handlers and the complete original
editor path remain open; this result covers the native task state currently
installed by `DocEd`.

The complete gate passes 363 native commands and 426 submitted lines. Normal
startup measured 44.511 seconds, diagnostic startup 162.208 seconds, and the
accumulated long-document Up path measured 0.432 seconds, within its one-second
budget. All original/shared comparisons, boot modes, console groups, provenance
checks and module rejection checks passed. ConsoleRuntime ABI 26 retains 428992
bytes from a 428976-byte image. The kernel SHA-256 is
`ecb594d5d15c15141e0c945216971bd89f4694e8852960b9d050cb2189357421`;
the normal disk SHA-256 is
`149620e810331ef400408fc7b25f53f62c11fcfd756850d8a9760c499fd914f9`.

The writable three-boot acceptance also remains green on this source. Its boots
measured 43.673, 43.872 and 43.623 seconds, with 90, 52 and 13 commands and exact
VGA checkpoints; interrupt-to-recovered-VGA measured 0.277 seconds. The final
walk found 17 directories, 724 files and 12650 uniquely owned sectors with a
matching bitmap. The writable candidate SHA-256 is
`b9a4094f09204d0469ee60e9812028a42761b8c415893956d3ab7d6b632ffa2e`.

## Embedded binary-record persistence (2026-09-23)

The native document reader and writer now preserve the original binary trailer
used by embedded graphics: a NUL after the textual DolDoc stream, the fixed
16-byte `CDocBin` saved span (`num`, `flags`, `size`, `use_cnt`), and the exact
payload bytes. The bounded command parser accepts the canonical
`$SP,"tag",BI=n$` form, validates and renumbers the referenced binary, and
reconnects the loaded entry to its payload. Other sprite command flags and the
sprite renderer remain open.

The internal exact-byte check uses a five-byte payload containing zero and
`0xFF`, verifies the 37-byte serialized document, loads and serializes it a
second time byte-for-byte, and rejects a one-byte-truncated trailer. Injected
allocation failures cover sprite entry, tag, binary header and payload creation;
each path unwinds to its exact heap baseline. A separate native source check
writes the same document through `DocWrite`, reopens it from RedSea, verifies
the restored link and bytes, and returns to its exact task-heap baseline. The
focused three-command normal boot passes at 45.238-second startup, and the
expanded 134-command `document-editing` group passed the initial persistence
implementation at 44.566 seconds.

The allocation-complete version passes the full gate with 365 native commands
and 428 submitted lines. Normal startup measured 44.561 seconds, diagnostic
startup 160.394 seconds, and the long-document Up path measured 0.259 seconds.
All original/shared comparisons, boot modes, console groups, provenance checks
and module rejection checks passed. ConsoleRuntime ABI 26 retains 457600 bytes
from a 457584-byte image. The kernel SHA-256 is
`ecb594d5d15c15141e0c945216971bd89f4694e8852960b9d050cb2189357421`;
the normal disk SHA-256 is
`979f68fc2c971f835d7a7664574cf3f536962bf872fc0be759e53fcf76564c80`.

The writable three-boot acceptance remains green. Its boots measured 44.690,
44.635 and 43.949 seconds; the interrupt-to-recovered-VGA path measured 0.277
seconds. It ran 90, 52 and 13 commands with exact VGA checkpoints. The final
walk found 17 directories, 725 files and 12723 uniquely owned sectors with a
matching bitmap. The writable candidate SHA-256 is
`7baf2b53fc5617041fa333f473e158f6ac532e243b4d69fdf64dbd80ac72c411`.

## First persisted sprite rendering (2026-09-23)

The native document editor now renders a bounded subset of original sprite
payloads through the retained graphics compositor. It supports color changes,
points, Bresenham lines and filled rectangles, rejects truncated or unsupported
operations, clips every pixel, and places each sprite at its current document
text cell. The editor decodes its proven planar text surface into the graphics
frame before drawing the sprite, preserving the normal heading and body text.

A native fixture creates an original `SPT_COLOR`/`SPT_RECT` payload, saves it to
RedSea, destroys the source document, reopens it and enters `DocEd`. The focused
`document-sprites` QEMU group independently constructs the expected font frame
and verifies the exact 16x8 red VGA rectangle at `(0,32)`. This is the first
end-to-end persisted embedded graphic; full `Sprite3`, arbitrary sprite records,
original `DocRecalc` layout, selection and mouse interaction remain open.

The focused group passes four native commands at 44.617-second startup. The
expanded normal 8 MiB QEMU/486 run passes 369 native commands and 432 submitted
lines at 44.614-second startup; every VGA checkpoint matched, and the measured
long-document input-to-VGA path was 0.262 seconds. Both native x86-64 rebuild
generations and all cross-build source checks also pass. The kernel SHA-256 is
`ecb594d5d15c15141e0c945216971bd89f4694e8852960b9d050cb2189357421`;
the normal disk SHA-256 is
`5739b0f5552ae2fb0476918af0e3627fc09cc1d3e558a0be61b113b663d1eb55`.

The writable three-boot development session also remains green. Its boots took
44.061, 44.613 and 44.062 seconds, running 90, 52 and 13 commands with exact VGA
checkpoints; interrupt-to-recovered-VGA measured 0.276 seconds. The final RedSea
walk found 17 directories, 726 files and 12761 uniquely owned sectors with a
matching bitmap. The writable candidate SHA-256 is
`e73435a4a860f84e0932936099127e05607b9ee355af7b0559f8bafe5f0e57fb`.

## Native directory browsing (2026-09-24)

The retained FileRuntime ABI 26 now supplies bounded two-pass directory
enumeration through the current task's drive and directory context. It keeps the
task-owned ATA session across resolution and every sector read, skips deleted
records, preserves RedSea order and marks directories with `/`. The public
`Dir(path)` command prints the owned result at the live HolyC console and frees
its temporary buffer afterward.

The focused QEMU test creates a nested project and source file, compares exact
VGA output for absolute and relative paths, and checks missing-path recovery. It
passes seven commands at 44.667-second startup. The complete normal gate passes
376 commands and 439 submitted lines at 44.719-second startup; all pixels match
and long-document input latency is 0.258 seconds. The diagnostic boot, all module
rejection cases and both native x86-64 rebuild generations pass as well.
FileRuntime retains 189880 bytes from a 189864-byte image. The kernel SHA-256 is
`50713aae8ff9ab962558de8fea0ad88eed795373a7159fab6973800aa1831d0b`;
the disk SHA-256 is
`ea60fdc47658acd5947cfe9d70aa999410458bef77886e0d7bcc165f042f8dd6`.

`EdDir(path)` now supplies an interactive VGA file picker. Up/Down changes the
selection, Enter descends into a directory or opens a file through `Ed`, Backspace
returns to the parent, returning from the editor redraws the picker, and Escape
returns to the prompt. Each directory reload allocates its replacement listing
before releasing the current view, so an allocation or read failure leaves the
existing picker usable. Synthetic `./` and `../` records stay hidden.

The focused test creates two files and a nested `Sub/Nested.HC`, checks exact
initial and moved-selection frames, enters `Sub`, returns to `Browse`, opens
`Main.HC`, and checks both editor and prompt return paths. Its ten native commands
pass at 44.670-second startup with exact pixels. Wildcards, sorting, original help
browsing and the original file browser remain part of the standalone
development-environment goal.

The picker now also provides an integrated file-creation path. `N` enters a
bounded filename mode with a visible cursor; Backspace edits the name, Escape
cancels it, and Enter opens the joined path through `Ed`. Path separators and a
drive delimiter are rejected. Returning from the editor reloads the directory
transactionally and selects the new file when it was saved. The expanded focused
test creates `New.HC`, types and saves `6*7;`, checks the refreshed exact VGA
frame, and reads back the five canonical document bytes. All eleven commands pass
at 45.022-second startup with exact pixels.

The complete build gate with picker-based creation passes 380 commands and 443
submitted lines at 45.028-second normal startup; all pixels match and measured
long-document input latency is 0.375 seconds. Diagnostic startup takes 161.812
seconds, and all module rejection cases plus both native x86-64 rebuild
generations pass. ConsoleRuntime retains 502376 bytes from a 502360-byte image.
The kernel SHA-256
is `50713aae8ff9ab962558de8fea0ad88eed795373a7159fab6973800aa1831d0b`;
the normal disk SHA-256 is
`e3fa89cdc9f8b6c55c0c09b73f326e11461236d83e55aaa242a20cea82539d67`.

The writable three-boot session remains green with picker-based creation. Its
boots took 44.524, 44.473 and 44.572 seconds and ran 90, 52 and 13 commands with
exact VGA checkpoints; interrupt recovery measured 0.278 seconds. The final
RedSea walk found 17 directories, 726 files and 12866 uniquely owned sectors with
a matching bitmap. The source image remained unchanged, and the writable
candidate SHA-256 is
`4c04d44b81d49532f7ab65e8054742590a24aea1d24992c850c0a204eded59f8`.

## Confirmed file deletion and FileRuntime ABI 27 (2026-09-24)

FileRuntime ABI 27 appends a regular-file delete service to its 56-byte public
record. `I386TaskFileDelete` resolves through the calling task's drive and current
directory, owns one RedSea session across lookup and mutation, and restores the
borrowed task-file state on every exit. RedSea deletion publishes and flushes the
tombstoned directory record before releasing the file's sectors. Directories are
rejected.

Public `FileDel(path)` exposes the service to native HolyC. In `EdDir`, Delete on
a regular file enters a visible `Y/N` confirmation; `Y` deletes and transactionally
reloads the listing, while `N` or Escape returns without changing the disk.
Delete on a directory does nothing. The focused `file-navigation` QEMU/486 test
creates and saves `New.HC`, reads its exact five bytes, reopens the picker, confirms
deletion, checks the exact refreshed VGA frame, then proves `DocRead` and a repeated
`FileDel` both report absence. It passes 14 commands at 46.729-second startup.

The rebuilt normal image passes the exhaustive interactive suite with 383 native
commands and 446 submitted lines at 46.581-second startup; all VGA checkpoints
match and long-document input-to-VGA latency is 0.379 seconds. The complete build
gate passes on the same sources. The writable three-boot test starts in 45.879,
45.778 and 45.778 seconds, runs 90, 52 and 13 commands, and measures 0.276-second
interrupt recovery. Its final walk finds 17 directories, 726 files and 12904
owned sectors with a bitmap matching reachable extents. The source disk SHA-256
is `e3ee1a40ee030c41f4115f8e5f9e2cd36fdd8cca143dbafae0e384c24b11b565`;
the writable candidate is
`c3c56ef2acaf945cbbcf0e2eb257deb9a1cf50b0740a011ec68bc8677a8884f1`.

## Same-parent entry rename and FileRuntime ABI 28 (2026-09-24)

FileRuntime ABI 28 extends its service record to 60 bytes with a file/directory
rename entry. `I386TaskFileRename` resolves both names through the current task,
requires the same mounted volume and parent directory, and owns one RedSea
session through mutation and flush. The RedSea operation rejects missing sources,
existing destinations and invalid names, rewrites only the 38-byte name field,
and flushes the directory sector. File and directory extents and the allocation
bitmap do not change. A directory's internal `.` and `..` records refer to blocks,
so a same-parent name change requires no child rewrite. Cross-directory moves are
deliberately outside this atomic operation.

Public `FileRename(old,new)` exposes the operation to native HolyC. In `EdDir`,
`R` on a file or directory opens a bounded `New name:` mode, performs the rename
and transactionally reloads and selects the new entry. The focused QEMU/486 group
verifies exact file entry and refreshed VGA frames, exact bytes under the new
name, absence of the old name, and missing-source, collision and cross-directory
rejection. It then renames `Sub/` to `Code/`, enters it, returns to the parent,
proves the old path is absent and lists the intact nested file through the new
path. The expanded group passes 23 native commands at 45.829-second startup.

The writable three-boot acceptance creates a temporary nested source, renames
and reads it, deletes it, and proves both names remain absent after reboot. It
also renames `/Project/MoveMe` to `/Project/Moved`; after reboot the new empty
directory retains canonical `.`/`..` records and the old path is absent. The host
walk finds 18 directories, 727 files and 12960 uniquely owned sectors; all extents
are nonoverlapping and the bitmap matches the reachable tree. Boots took 45.779,
45.931 and 45.880 seconds, running 98, 55 and 13 commands; interrupt recovery
measured 0.279 seconds. The candidate SHA-256 is
`fe7c859414a7d8aeeb0476870a2065469ea5850e3935b073ef03243c4518eb27`.

The complete ABI-28 gate passes 392 native commands and 455 submitted lines at
45.830-second normal startup. Every VGA checkpoint matches and long-document
input latency is 0.375 seconds. FileRuntime retains 213784 bytes from a 213768-byte
image, and wrong-target, missing-import and wrong-ABI mutations are rejected.
The native kernel SHA-256 is
`8fe150877d5403b4755990aebaaa7701671e891900bed980843a5b11c7d5051b`;
the normal disk SHA-256 is
`5b547640e31dd2c281c9e5c035ed099a9f8da4c5810eae6d3018a833be62db9c`.

## Empty-directory deletion and FileRuntime ABI 29 (2026-09-24)

FileRuntime ABI 29 extends its service record to 64 bytes with an empty-directory
delete entry. `I386RedSeaDirDelete` rejects root, traversal names, regular files
and nonempty directories. It validates the directory terminator after `.` and
`..`, ignores deleted slots, publishes and flushes the parent tombstone, then
releases and flushes the directory extent. `I386TaskDirDelete` supplies the same
task-relative path, volume-session and cleanup guarantees as file deletion, and
public `DirDel(path)` exposes it to native HolyC.

Delete in `EdDir` now accepts directories. Its confirmation says `Delete empty`
to make the constraint visible; a rejected nonempty delete redraws the unchanged
listing. The focused QEMU/486 group rejects deletion of populated `Code/`, creates
`Empty/`, verifies the exact confirmation and refreshed VGA frames, deletes it
and proves repeated absence. It passes 27 commands at 46.081-second startup with
all pixels matching.

The writable acceptance persists `/Project/MoveMe` renamed as `/Project/Moved`
into its second boot, rejects `DirDel` on populated `/Project/Sub`, deletes the
empty renamed directory, and proves both names absent in the third boot. The host
walker now correctly skips RedSea tombstones while retaining terminator, live
attribute, extent-overlap and bitmap checks. It finds 17 directories, 728 files
and 12997 live owned sectors with a bitmap exactly matching reachable extents.
Boots took 46.132, 46.131 and 46.081 seconds, running 98, 56 and 15 commands;
interrupt recovery measured 0.279 seconds. The candidate SHA-256 is
`e6581057218bbe36bced5dedf4c43aaea1ffed05c0266dfb7ccc44396de311f5`.

The complete ABI-29 gate passes 396 native commands and 459 submitted lines at
46.031-second startup. Every VGA checkpoint matches and long-document input
latency is 0.434 seconds. FileRuntime retains 225784 bytes from a 225768-byte
image, and all module rejection gates pass. The native kernel SHA-256 is
`108069d1b8bca9b04bc62530c6291db8ef325061e89ff96d68f313400664eb22`;
the normal disk SHA-256 is
`91f6d7d1c9d925ac707718548a987c0f377cb2ca3f2e64fe3bc3f04ae31e2e05`.

## Cross-directory regular-file move and FileRuntime ABI 30 (2026-09-24)

FileRuntime ABI 30 extends its service record to 68 bytes with a move entry.
Public `FileMove(old,new)` resolves both names through the current task and
requires one mounted volume. Same-parent moves retain the atomic rename path.
For different parents, `I386TaskFileMove` accepts regular files, reads the source
into task-owned memory, creates and publishes the destination with the original
date and attributes, and then deletes the source. A failed source delete triggers
a best-effort destination rollback. Missing sources, collisions, directory
sources and cross-volume paths are rejected. Because publication and deletion
are separate filesystem mutations, this is not yet a crash-atomic move; the
failure-injection milestone remains open.

The focused QEMU/486 group creates `Archive/`, moves `Other.HC` to
`Archive/Moved.HC`, reads its exact two bytes, proves the old path is absent and
checks all rejection cases. It moves the file back and removes the now-empty
directory. The group passes 35 native commands with exact VGA checks at
46.133-second startup.

The writable three-boot acceptance moves a newly written source from
`/Project/Sub/Renamed.HC` to `/Project/Moved/Transferred.HC`, verifies its exact
bytes and source absence, deletes the destination, and proves all temporary names
remain absent across later boots. Boots took 46.133, 45.982 and 46.084 seconds,
running 101, 56 and 15 commands; interrupt recovery remained covered. The final
walk finds 17 directories, 728 files and 13031 live owned sectors with a bitmap
exactly matching reachable extents. The source image remains unchanged and the
writable candidate SHA-256 is
`3e6244faeb512a6d469b38eb8a11f8b93c2c4ebb254ac1de46ecae76fc9e71fa`.

The complete ABI-30 gate passes 404 native commands and 467 submitted lines at
45.679-second normal startup. Every VGA checkpoint matches and long-document
input latency is 0.256 seconds. FileRuntime retains 237872 bytes from a
237856-byte image, and wrong-target, missing-import and wrong-ABI module mutations
are rejected. The native kernel SHA-256 is
`501a11241a8b18cceab69d325d6860106a5eb6c55563341ce75da767bc9a8b40`;
the normal disk SHA-256 is
`21e6d823fddf885724308d3f795fc5530b0b5aed226da4e6c59532dd480db834`.

## Move failure recovery and FileRuntime ABI 31 (2026-09-24)

FileRuntime ABI 31 grows its private service record to 72 bytes with an internal
move-probe callback. The public `FileMove` API and its normal path are unchanged.
The internal staged implementation can stop before source reading, before
destination creation, after destination publication or before source deletion.
At the two post-publication boundaries it removes the destination before
returning failure. A native diagnostic worker verifies the exact four-byte source
and absent destination after every injected stage, then completes a normal move
and removes all fixtures.

Mutation testing uses a dedicated writable image. Build tooling validates and
enables separate exported diagnostic and file-mutation data flags, runs the
probe, clears both flags, independently walks the resulting RedSea tree and
compares every allocation bit with reachable extents, then boots that same disk
normally. The reboot runs three native absence checks, matches every VGA
checkpoint and leaves the disk unchanged. The post-probe tree has 15 directories,
712 files and 13030 live owned sectors with an exact bitmap; its SHA-256 is
`3cc4d2b880e288bb2377c7e9f525b2c9093a360c5ea58b2bc4aa226b206de2ad`.
The ordinary diagnostic image explicitly rejects any mutation marker and remains
byte-for-byte read-only.

The first probe run also forced root-directory growth and exposed a stale parent
block in `I386TaskDirMk`: after `I386RedSeaCreate` relocated the root, directory
initialization searched the old block. `DirMk` now records a root parent and
refreshes it from `volume->root` before locating and writing the new directory's
`.` and `..` entries. The dedicated mutation boot and subsequent normal reboot
exercise this relocation path.

The complete ABI-31 gate passes 404 native commands and 467 submitted lines at
45.479-second normal startup. Every VGA checkpoint matches and long-document
input latency is 0.370 seconds. FileRuntime retains 243952 bytes from a
243936-byte image, and all module rejection gates pass. The native kernel
SHA-256 is
`818eba2ff43612244af5b1c6af2f232582a4060c0f982ba805b3cde6fcd8f35a`;
the normal disk SHA-256 is
`a6c05097992d1b0e354feae71b491b0383bee65ebbca013f0311994f00e72cdc`.

## Raw move I/O recovery and FileRuntime ABI 32 (2026-09-24)

FileRuntime ABI 32 extends the private service record from 72 to 76 bytes with a
disposable-image move callback that can fail an exact task-owned sector write or
flush. The initial gate interrupted all five writes and four flushes used by the
two-byte cross-directory move fixture, always after fixture setup. Each case
then boots the same writable image in a recovery-only mode and an independent
host walker validates directory structure, complete file contents, all live
extents and every allocation bit.

The recovery boot reconstructs the bitmap from the reachable tree before task
I/O is bound. It rejects malformed entries, cycles, overlapping extents, invalid
parent records and disagreement between a child directory entry's size and the
child's self record. It marks reserved and out-of-volume bits, writes only
bitmap sectors that differ, and flushes before exposing the volume to normal
allocation. This repairs the unreachable reserved or released extent left by
an interrupted bitmap update without trusting the damaged bitmap as ownership
truth.

All nine cases pass and retain only complete `IO` contents. Write failures 1–3
leave the source; write 5 leaves the destination. Flush 1 leaves the source;
flushes 3–4 leave the destination. Write 4 and flush 2 leave both complete
names, exposing the next TDD contract: persist move intent and require exactly
one name after recovery. Bitmap ownership matches reachable extents in every
case, with 15 directories, 714 files and 13090 owned sectors for single-name
outcomes, and 715 files/13091 sectors for the two duplicate-name outcomes.

The larger kernel now reserves an explicit 800-sector BIOS stage; its 403768
native bytes still end below the fixed low-memory task-stack reservation. The
complete ABI-32 promotion passes both self-rebuild generations, the diagnostic
boot, all module rejection gates, 404 native console commands and 467 submitted
lines. Normal startup took 45.980 seconds and long-document input latency was
0.370 seconds. The kernel SHA-256 is
`1cc328a7a38d8097dbf36cd81ed2820b742fd6f1b3a415d8f661019e62a0b9e6`;
the normal disk SHA-256 is
`0552005028856741a81f21b03f81a5b5d9ba3cbffeb3b9881c4cd95500e69975`.

The next TDD increment closes the duplicate-name gap with a checksummed move
intent in the otherwise unused RedSea volume-header bytes. The intent records
root-aware source and destination parents, both names, and the source extent,
size, timestamp and attributes before destination publication. Normal success
clears it only after the source tombstone and extent reclamation are durable.
Mount recovery validates the record and both live entries, rolls back the
destination if the source still exists, or accepts the destination if the
source is absent.

The expanded matrix covers all seven writes and six flushes, including intent
publication and clearing. All thirteen fresh-image cases recover to exactly one
complete `IO` file and an allocation bitmap matching reachable extents. Write
failures 1–5 and flush failures 1–3 recover the source; writes 6–7 and flushes
4–6 recover the destination. The kernel export table and bounded FileRuntime
binding set now include the two intent services. The final 422008-byte image
uses an 848-sector stage ending at `0x7A000`, still 56 KiB below the fixed
`0x88000` task-stack reservation.

The complete journal promotion passes both self-rebuild generations, diagnostic
and normal boots, every module rejection gate, the four-stage logical rollback
probe and all thirteen raw interruption cases. The normal suite runs 404 native
commands and 467 submitted lines with exact VGA pixels; startup took 46.184
seconds and long-document input latency was 0.427 seconds. The kernel SHA-256 is
`af6354255464d55c1528f93eb3f98950a25ff1c13d2a9048b316579a774f42d2`;
the normal disk SHA-256 is
`ff812ec0247e07869ece2c58c752418d93082dbe450c863db6ba78142f887a7a`.

## Failure-atomic replacement matrix (2026-09-24)

The disposable raw-I/O probe now selects regular-file replacement as well as
move. It creates `C:/Probe/ReplaceIo.HC` with exact `OLD` bytes, arms injection
only after fixture publication, and replaces it with exact `NEW` bytes through
the normal task-owned `FileWrite` path. Fresh images interrupt all four sector
writes and three flushes spanning allocation, data, publication, old-extent
reclamation and their durability boundaries.

All seven recovery boots pass. Write failures 1–3 and flush failure 1 retain
`OLD`; write failure 4 and flush failures 2–3 retain `NEW`. The independent host
walk requires one live fixture, exact three-byte content, a valid tree, no stale
move intent and allocation bits matching every reachable extent. This closes
the raw replacement interruption item for the project-workflow persistence
slice; broader document-format coverage remains open.

## Original-to-native DolDoc compatibility fixture (2026-09-24)

The real original x86-64 `DocSave` now emits `OriginalCompat.DD` during the i386
cross-build. The 48-byte document contains ordinary text, a canonical sprite
reference and the original 16-byte `CDocBin` header plus a five-byte payload.
The build packages those exported bytes unchanged at
`C:/Probe/OriginalCompat.DD`. A focused 8 MiB QEMU/486 boot opens it through the
native `DocRead`, serializes it through native `DocSave`, and verifies the text,
record boundary and binary payload. The eight-command `document-compatibility`
group passes with exact VGA output and 46.181-second startup.

This establishes original-to-native cross-reading through both real
implementations. The reverse test copies the normal disk, creates and writes
`BinaryRecord.DD` through native i386, extracts the exact 37 bytes through an
independent RedSea walk, and boots original x86-64 TempleOS with that artifact.
Original `DocRead` validates the sprite entry and binary ownership, and original
`DocSave` reproduces all bytes exactly. The fixture SHA-256 is
`73d58bdbb0bf929d9db33d5cfec27a614aaea98b176baed4637ab3c1e58c046d`.
This closes bidirectional cross-reading for the implemented structured/binary
subset; unsupported general DolDoc commands remain outside that bounded claim.

The complete promotion passes both self-rebuild generations, diagnostic and
normal boots, all module rejection gates, 404 native commands, 467 submitted
lines, the logical move rollback probe, 13 move interruptions and seven
replacement interruptions. Normal startup took 46.080 seconds and
long-document input latency was 0.375 seconds. The resident kernel is unchanged
at 422008 bytes with SHA-256
`af6354255464d55c1528f93eb3f98950a25ff1c13d2a9048b316579a774f42d2`;
the replacement-enabled normal disk SHA-256 is
`de4058dcd386334bb25c716f00c0383a57983117047effdbe6cd964e2d06cf2e`.

## Nested RedSea directory growth and complete compatibility promotion (2026-09-24)

Adding the original document fixture filled `C:/Probe` through its last available
directory slot. The first raw move-interruption reboot exposed that creation had
overwritten the required zero-name terminator, so mount correctly rejected the
tree. `I386RedSeaCreate` now grows a root or nested directory before consuming
that slot. Nested growth allocates and flushes a one-sector-larger copy, relinks
the parent entry, updates direct child `..` records, and then releases the old
extent.

The independent move matrix passes all seven write and six flush interruptions
after this change. Each recovered image contains 15 directories, 716 files and
13,173 reachable sectors, with exactly one complete move fixture and an exact
allocation bitmap. Both original x86-64 rebuild generations also pass.

The complete promotion now includes bidirectional document compatibility and
passes diagnostic and normal boots, every module/source rejection gate, 412
native commands, 475 submitted lines, the logical rollback probe, all 13 move
interruptions and all seven replacement interruptions. Normal startup took
46.081 seconds; long-document input-to-VGA latency was 0.256 seconds. The native
compatibility boot took 45.878 seconds and original `DocRead`/`DocSave` reproduced
its 37-byte file exactly. The resident kernel remains 422008 bytes with SHA-256
`af6354255464d55c1528f93eb3f98950a25ff1c13d2a9048b316579a774f42d2`;
the normal disk SHA-256 is
`ed963c91329f7650830593d399f4ce2dffeaa565dcdc58265f1fa9be8be91005`.

## Read-only native help browser (2026-09-24)

The packaged RedSea image now includes all original files under `Doc`. Console
runtime ABI 27 publishes `Help(name)`, defaulting to
`C:/Doc/HelpIndex.DD`. The viewer reads the original file through the task-owned
file service, projects common `TX`, `TR`, `LK` and `MA` display labels while
discarding layout-only commands and binary trailers, and never writes the source.
Page Up/Page Down and the arrow keys move by VGA page, Home returns to the first
page, and Escape restores the same HolyC prompt.

The focused 8 MiB QEMU/486 check opens the original
`CompilerOverview.DD`, verifies its title and six displayed link labels against
exact VGA pixels, and exits successfully in 46.380 seconds. A task-heap recovery
assertion covers the source buffer, projected text and viewer lifetime. This is a
read-only text projection; help-index symbol navigation, colors, tree widgets and
original `DocRecalc` layout remain open.

The complete promotion after adding the packaged help tree and ConsoleRuntime 27
passes both rebuild generations, diagnostic and normal boots, every module/source
rejection gate, 414 native commands, 477 submitted lines, all 13 move and seven
replacement interruption cases, and bidirectional document compatibility. Normal
startup took 46.279 seconds and long-document input-to-VGA latency was 0.198
seconds. The resident kernel is 422008 bytes with SHA-256
`87d703a00b7b15159757c2989d79ab99049e89292e4df63ce866f2c2c7eb279c`;
the normal disk SHA-256 is
`854f05b969d12650c830f6024e4cfbe9bcde726302ead35f7cd4ea4bf6627844`.

## Native help file-link navigation (2026-09-24)

The read-only viewer now retains up to 128 direct file-link spans and their
normalized `C:/` targets while projecting an original DolDoc. Left/Right selects
visible links with an exact VGA highlight, Enter follows original `FI:`, `FF:`
and `FL:` targets, and Escape returns from the nested viewer to the same selected
parent link. Link tables live on the task heap, which keeps nested navigation off
the exception stack and makes their ownership visible to the allocator.

The focused 8 MiB QEMU/486 acceptance selects `::/Doc/Asm.DD` in the original
`CompilerOverview.DD`, checks its highlight, opens the original assembler help,
checks the complete first-page VGA projection, returns to the selected compiler
index link, and exits with an exact zero heap delta. It passed with 46.481-second
startup. `HI:` category links and file anchors still need native resolvers.

## Native man-page link resolution (2026-09-24)

The help projection now resolves `MN:name` against the running task's retained
`HTG_SRC_SYM` table. A published symbol with a source link becomes selectable;
its original `FL:` metadata is normalized to the packaged `C:/` source path and
opened through the same nested viewer. Symbols absent from the native environment
or lacking source metadata remain plain labels rather than misleading links.

The focused 8 MiB QEMU/486 acceptance opens the original command-line overview,
selects its `Dir` man-page link after the preceding HolyC file link, verifies the
exact highlight, resolves it to `C:/Kernel/I386/PublicFiles.HH`, enters the source
viewer, returns to the selected overview link and exits with exact heap recovery.
Together with the direct-file case, the help group now passes six native commands
with exact VGA checkpoints and 46.430-second startup. Source line/anchor
positioning remains open.

## Native help-index category resolution (2026-09-24)

`HI:index` links now scan the running task's chained hash tables for a public,
non-private `HTT_HELP_FILE` whose semicolon-delimited help index contains the
exact requested category component. The viewer follows the registered path
through the same task-owned file service and nested return path used for file and
man-page links. This keeps category navigation synchronized with successfully
published native compiler metadata and excludes rolled-back or private entries.

The focused 8 MiB QEMU/486 acceptance opens the original `DolDoc.DD`, selects
`HI:Data Types/Circular Queue`, verifies its exact VGA highlight, resolves the
category to the public queue help registration at `C:/Doc/Que.DD.Z`, enters and
returns, then exits with an exact zero heap delta. The complete focused help group
passes seven native commands with exact VGA checkpoints and 46.532-second startup.
Generated category listings remained open at this slice; a later slice below
adds them after file search and anchor positioning.

## Native help source-line positioning (2026-09-24)

The link projection now preserves the one-based line suffix from `FL:` targets.
The nested viewer maps that source line into its read-only projection and uses the
resulting byte offset as the first page. This also applies to `MN:` navigation,
because published symbols resolve to their retained `FL:` source link before the
file is opened. Home still provides an explicit route to the top of the file.

The focused 8 MiB QEMU/486 acceptance follows `MN:Dir` from the original
command-line overview and verifies that the nested VGA page starts with line 4 of
`PublicFiles.HH`, the actual `Dir` declaration, followed by the remaining public
file interface. It returns to the highlighted parent link and completes the full
seven-command help group with exact heap recovery and 46.330-second startup.
The later slices below add text-search and DolDoc-anchor positioning.

## Native help text-search positioning (2026-09-24)

`FF:file,needle[:occurrence]` links now preserve an unescaped search string and
optional positive occurrence number. After projecting the target without
rewriting it, the nested viewer finds that occurrence and begins at the containing
text line; if it is absent, the normal file/line start remains the fallback.

A packaged two-document probe contains a repeated `Needle heading`. The focused
8 MiB QEMU/486 acceptance highlights its `FF:` link, requests occurrence two,
verifies that the nested page begins with the second heading followed by `Second
body`, returns to the same selected link, and exits with exact heap recovery. The
eight-command help group passes all exact VGA checkpoints with 46.482-second
startup. Generated category listings remain open.

## Native help anchor positioning (2026-09-24)

`FA:file,anchor` links now retain the anchor name. During read-only projection,
the viewer recognizes an original `AN` command whose `A=` attribute matches that
name and records the current visible-text offset without emitting the hidden
command. The nested page begins at that offset and falls back to the normal file
start if no anchor matches.

A packaged probe places `Wanted` on an invisible anchor between two text sections.
The focused 8 MiB QEMU/486 acceptance selects the `FA:` link, verifies that the
nested VGA page begins with `Wanted heading` and `Anchor body`, returns to the
highlighted parent and exits with exact heap recovery. The complete focused help
group passes nine native commands with exact VGA checkpoints and 46.178-second
startup. Generated `HI:` category listings and full DolDoc layout remain open.

## Native generated help-index listings (2026-09-24)

`HI:index` now opens a live category page instead of selecting the first matching
registration. The page scans every chained task hash table, includes each public,
non-private help file and source-linked symbol whose semicolon-delimited index has
the exact category, and exposes their file or source targets as normal selectable
links. Empty categories show an explicit message. Nested Escape restores the
selected category entry and then the selected link in the original parent document.

The focused 8 MiB QEMU/486 acceptance follows `Data Types/Circular Queue` from
the original `DolDoc.DD`, checks the queue help file plus eight indexed native
symbols and the exact first-link highlight, opens `C:/Doc/Que.DD.Z`, and returns
through both viewer levels with an exact zero heap delta. The full nine-command
help group passes every VGA checkpoint with 46.380-second startup. Full original
DolDoc layout remains open.

## Editor compiler-diagnostic navigation (2026-09-24)

The native compiler console now records the source filename and `last_line_num`
for the first error. Using the token line matters when lexical lookahead has
already advanced the file cursor to the following line. After an F5 failure,
Escape compares that source with the active document and positions its canonical
cursor at the first editable byte of the reported line. Diagnostics in included
files do not move the current document.

The three-boot writable acceptance starts at line 3 of a document containing a
missing expression on line 2. It verifies the visible diagnostic, returns to an
exact VGA frame with the cursor before line 2, repairs the line through hardware
Delete/text events, and reruns the document to display `1`, `42` and `3`. All
107 create/edit/save commands, 56 reopen commands and 15 revised-boot commands
pass on QEMU/486 with 8 MiB. Startup measured 46.431, 46.481 and 46.584 seconds;
the independent RedSea audit found 18 directories, 833 files, 14005 uniquely
owned sectors and an exact reachable-allocation bitmap. The source image stayed
unchanged; the writable candidate SHA-256 is
`57a114b338ebaf4e826eaa78c4ca5d50ce74371561a493905b1e37ab97e51f75`.

## In-editor help workflow (2026-09-24)

Native `DocEd` now follows the original unmodified F1 action by opening the
packaged `C:/Doc/HelpIndex.DD` in the read-only help viewer. Shift-F1 opens
`AboutTempleOS.DD`. Leaving either view with Escape redraws the active editor
without serializing or replacing its canonical document, so unsaved text and
cursor state remain intact.

The three-boot writable acceptance edits `NativeEdit.DD`, opens help before its
first save, observes a new viewer lifetime, exits and requires the exact prior
editor pixels before continuing. All 107 create/edit/save commands, 56 reopen
commands and 15 revised-boot commands pass on QEMU/486 with 8 MiB. Startup was
46.431, 46.280 and 46.381 seconds, and interrupt-to-recovery VGA latency was
0.273 seconds. The independent filesystem audit reports 18 directories, 833
files, 14008 uniquely owned sectors and a matching bitmap. The source image was
unchanged; the writable candidate SHA-256 is
`6d8dd9c83f5740858501e8dbb186138a36404630d84a6d4c6a08b7c8a352d866`.

## In-editor project browser (2026-09-24)

Native `DocEd` now binds F4 to the file picker rooted at the active document's
parent directory. The picker retains its existing directory traversal, nested
editing, create, rename and confirmed-delete behavior. Escape returns through
the picker stack and redraws the original canonical document, preserving its
cursor and unsaved state. This provides a direct project-navigation action while
the original F4 filename-insertion popup remains open.

The focused 8 MiB QEMU/486 `file-navigation` suite opens
`C:/Browse/Main.HC`, presses F4, verifies the exact `C:/Browse` picker and its
three entries, exits and checks the exact restored editor pixels. All 36 native
commands pass, including the surrounding directory/file lifecycle and
cross-directory regular-file move cases, with 46.376-second startup and exact
VGA checkpoints. The tested disk SHA-256 is
`70ac4ba764a32d3409ad6f4cf6676c3140a5511b08021b85f22c391ef4294dc2`.

## Native editor find and repeat (2026-09-24)

Native `DocEd` now opens a bounded search prompt with Ctrl-F. F3 repeats forward
and Shift-F3 repeats backward, with a single wrap in either direction. Ordinary
typing at the document sentinel can produce adjacent `DOCT_TEXT` records, so the
implementation creates a temporary logical projection of text, newline and tab
records together with an exact entry/column map. A hit moves the canonical cursor
without rewriting, merging or serializing document records.

The focused 8 MiB QEMU/486 `document-editing` group types `one two one`, checks
the prompt and query pixels, wraps from the ending cursor to the first `one`,
moves to the second with F3 and returns with Shift-F3. All 137 native commands
pass with exact VGA checkpoints; an absent second query also preserves the first
cursor and renders `Not found`. Projection allocations now unwind inside the
search helper, releasing partial buffers and the document lock without ending
the editor. Startup measured 46.530 seconds. The tested disk
SHA-256 is
`ebc1613814577833c633472da67b7d2952eacc6ce420181d4f5f6aa2f2880d3b`.

## Native editor go-to-line (2026-09-24)

Native `DocEd` now implements the original Ctrl-G navigation action with a
bounded numeric VGA prompt. A positive one-based line walks canonical text and
newline entries and places the cursor at its first editable byte. An absent line
does not move the cursor and reports `Line not found` in the editor heading.

The focused 8 MiB QEMU/486 `document-editing` group types three lines, opens the
prompt, selects line 2 from a line-3 cursor, checks the exact cursor pixels, then
rejects line 9 with the same cursor. All 140 native commands pass with exact VGA
checkpoints and 46.682-second startup. The tested disk SHA-256 is
`6eabd7f616a1722b047e27372a2e86882112627cb4bcfb9d338c3f2894125094`.

## Explicit CPU profile and no-FPU smoke test (2026-09-24)

The native keyboard/VGA runner now accepts `--cpu`, passes that model directly
to QEMU and records the same value in every result shape. Its default remains
`486`, preserving existing callers. This prevents a run using a stricter CPU
configuration from being mislabeled as the former hard-coded profile.

The normal image passed the focused keyboard group on QEMU `486,-fpu` with
8 MiB: startup took 46.481 seconds, all VGA pixels matched, and the tested disk
SHA-256 was
`6eabd7f616a1722b047e27372a2e86882112627cb4bcfb9d338c3f2894125094`.
The installed QEMU exposes no 386 CPU model, so this is useful no-coprocessor
evidence but not 386 execution evidence. M7 now assigns the true 386SX/DX run to
a 386-capable emulator and retains QEMU/486 as the development profile.

## Native editor single replacement (2026-09-24)

The Ctrl-F editor prompt now accepts Tab after a nonempty search term to enter a
bounded replacement field. Enter locates the next match with the existing
cross-record search map, deletes the matched logical bytes and inserts the
replacement through shared canonical `DocPutKey` operations. An empty
replacement therefore performs deletion without a separate document model.

The focused `document-editing` group enters `one two one`, exercises find and
forward/reverse repeat, checks the missing-result state, then enters `one`, Tab,
and `ONE`. Exact VGA checkpoints cover both prompt fields and the resulting
`one two ONE` document with its cursor after the replacement. All 140 native
commands pass on the normal QEMU/486 8 MiB image; startup took 46.481 seconds.
The tested disk SHA-256 is
`8ed8fe4b55e19c27c01b7876f417123351b7b7863973511d235d5e53bc9919d0`.
Both original x64 rebuild generations and the native cross-build pass. Full
original replace-all, replace/skip choices, options and selection semantics
remain open.

## Native editor bounded undo (2026-09-24)

Native `DocEd` now captures a complete canonical snapshot before ordinary text,
newline, tab, backspace, Delete, style and replacement mutations. It publishes
the new snapshot only after serialization succeeds, preserving the previous
undo point if allocation fails. Alt-Backspace restores the snapshot through the
structured loader, including cursor and embedded-record state, consumes it and
keeps the editor active. Editor exit and exception cleanup release the snapshot.

The exact VGA acceptance replaces the second `one` with `ONE`, sends a real
Alt-Backspace hardware chord and requires `one two one` with the cursor restored
to the original match. The complete focused `document-editing` group passes all
140 native commands on QEMU/486 with 8 MiB; startup took 46.581 seconds. Both
x64 rebuild generations and the native cross-build pass. The tested disk
SHA-256 is
`bd6730b783ac1f0eef0638902ad608a64bf3f71fa9e3a8c55e26cbeed4a496c1`.
At that point, original multi-level/coalesced undo and full selection-aware editing remained open.

## Canonical horizontal editor selection (2026-09-24)

The shared ordinary-text editor core now accepts Shift-Left and Shift-Right.
It splits text records at exact cursor boundaries only after both the new entry
and copied suffix exist, marks traversed records with the original `DOCET_SEL`
bit, and retains non-text record boundaries. Plain navigation clears selection;
typing, Backspace and Delete remove the selected records before continuing at
their canonical insertion point. The native renderer inverts selected records.

The hardware/VGA acceptance types `abc`, returns Home, selects `ab` with two
real Shift-Right chords, requires exact inverted-cell colors and a cursor before
`c`, then types `X` and requires `X` followed by that cursor and `c`. The focused
`document-editing` group passes 143 native commands with exact VGA pixels on
QEMU/486 at 8 MiB; startup took 46.633 seconds. Both x64 rebuild generations
and the native cross-build pass. The tested disk SHA-256 is
`6646913178451dee1ab16b445bd6cbc39dfc522e5a541fbc9fd516eb914ff436`.
At that point, reversible vertical and shifted page selection remained open.

## Multiline editor selection (2026-09-24)

The shared editor core now extends selection with Shift-Up and Shift-Down. It
normalizes the old cursor to an exact canonical boundary, performs the existing
column-preserving line move, splits the destination record when necessary and
marks every record between the two boundaries, including newlines. Existing
typing, deletion and clipboard operations then consume the selected multiline
range.

The hardware/VGA acceptance types three two-character lines, sends Shift-Up from
the end of line three, and requires the cursor after line two with the newline
and complete third line selected. Typing `X` replaces that range to produce
two lines ending in `bbX`. The focused `document-editing` group passes 152
native commands with exact VGA pixels on QEMU/486 at 8 MiB; startup took 46.684
seconds. Both x64 rebuild generations and the native cross-build pass. The
tested disk SHA-256 is
`ea9947b0a8faaea3bdd6250f37dd80e47a1868d36094bea14ac7c62cc42f9195`.
Reversible vertical/page contraction remains open.

## Viewport-sized editor selection (2026-09-24)

Shift-Page-Up and Shift-Page-Down now call the same canonical multiline selection
operation with the editor's existing 55-line page distance. The move preserves
the visual column, splits both range boundaries when needed and marks all
intervening text and newline records for replacement or clipboard use.

The exact VGA acceptance enters three two-character lines and invokes
Shift-Page-Up from line three column 2. It requires the cursor at line one column
2 and selects both following newline/line spans, then types `P` to produce
`aaP`. The focused `document-editing` group passes 155 native commands on
QEMU/486 with 8 MiB; startup took 46.780 seconds. Both x64 rebuild generations
and the native cross-build pass. The tested disk SHA-256 is
`b19deaf13a20842e0327f46165fb4d38b1b83bacf765a9285ec5be0a7db2d28f`.
Reversible vertical/page contraction and original undo coalescing remain open.

## Bounded multi-level editor undo (2026-09-24)

Native `DocEd` now retains sixteen complete pre-mutation canonical snapshots.
Each successful serialization appends atomically; once full, a new snapshot
releases the oldest and shifts the bounded history. Alt-Backspace restores and
consumes the newest snapshot only after the structured loader succeeds. Normal
editor exit and exception cleanup release every retained body.

The hardware/VGA acceptance types `a`, `b`, and `c` as separate mutations, then
sends Alt-Backspace three times and requires exact `ab`, `a`, and empty document
frames with their serialized cursors. The focused `document-editing` group
passes 158 native commands with exact VGA pixels on QEMU/486 at 8 MiB; startup
took 46.684 seconds. Both x64 rebuild generations and the native cross-build
pass. The tested disk SHA-256 is
`6f5044a1333e6084c7cb4c29c3b793b0587c2d07f0d42722c1abcf7ef0395d4e`.
Original time-based undo coalescing remains open.

## Reversible multiline and page selection (2026-09-24)

The shared multiline selection operation now toggles every canonical record in
the traversed range. Shift-Up followed by Shift-Down, or Shift-Page-Up followed
by Shift-Page-Down, therefore restores the unselected document and its original
cursor; moving back again re-extends the identical range. This matches the
already reversible horizontal selection model.

Exact VGA checkpoints now cover select, contract and re-extend for both a
one-line move and the 55-line page action before typing over each selection. The
focused `document-editing` group passes 158 native commands on QEMU/486 with
8 MiB; startup took 46.731 seconds. Both x64 rebuild generations and the native
cross-build pass. The tested disk SHA-256 is
`6b94a64b06ed82c43fd172f8112084963d77c31b89ad423c182127d44879231a`.
Original time-based undo coalescing remains open.

## Document-boundary selection (2026-09-24)

The shared editor core now implements the original Ctrl-Shift-Up and
Ctrl-Shift-Down document-boundary chords. It splits a partial text record at the
cursor when necessary, marks every canonical record to the start or end, and
places the cursor at that boundary. Existing clipboard and selected-span
replacement then operate on the complete range.

The hardware/VGA acceptance types `xyz`, sends Ctrl-Shift-Up, and requires the
cursor at the start plus all three inverted characters. It cuts the full
document to an empty editor and pastes it back with the cursor at the end. Exact
VGA pixels pass for every state. The focused `document-editing` group passes
149 native commands on QEMU/486 with 8 MiB; startup took 46.780 seconds. Both
x64 rebuild generations and the native cross-build pass. The tested disk
SHA-256 is
`10cab821dc2761a4b6a55d428d092d31abeb09468da349af4b233f968f622480`.
At that point, vertical line-wise selection remained open.

## Native canonical clipboard (2026-09-24)

Native `DocEd` now binds the original Ctrl-C, Ctrl-X and Ctrl-V actions to the
canonical selection records. Copy builds a complete replacement document before
discarding the prior retained clipboard and then clears source selection. Cut
copies before deleting the selected records. Paste splits an editable text record
at the cursor when necessary and inserts copied records before the surviving
canonical insertion point. Cut and paste take the same bounded undo snapshot as
other mutations.

The hardware/VGA acceptance selects `ab` in `abc`, copies it, pastes at the end
to form `abcab`, selects and cuts the first `ab`, then pastes it back before `c`.
Every intermediate cursor and exact VGA frame is asserted using real Ctrl key
chords. The focused `document-editing` group passes 146 native commands on
QEMU/486 with 8 MiB; startup took 46.532 seconds. Both x64 rebuild generations
and the native cross-build pass. The tested disk SHA-256 is
`8ce63e6fde6f8516d3f77c696ac446e19ca3500825f6d38f76d3a47a5719c052`.
At that point, vertical/document-wide selection and multi-level undo remained open.

## Reversible horizontal selection (2026-09-24)

Shift-Left and Shift-Right now toggle the canonical character they traverse.
Moving into unselected text extends the selection; reversing over a selected
character contracts it while retaining the exact split-record boundary and
cursor position.

The hardware acceptance selects `ab` in `abc`, reverses once to leave only `a`
selected with the cursor between `a` and `b`, re-extends across `b`, and then
types over the restored two-character selection. Exact VGA cells check both
selection colors and both cursor positions. The focused `document-editing`
group passes 146 native commands on QEMU/486 at 8 MiB; startup took 46.533
seconds. Both x64 rebuild generations and the native cross-build pass. The
tested disk SHA-256 is
`ba036af81f352a7ec068f2c84aaa0e8ffd311e1267eaaa79c13b7efe96d50ba5`.
At that point, vertical/document-wide selection remained open.

## Time-coalesced native editor undo (2026-09-24)

Native `DocEd` now groups a continuous run of insertion, Backspace or Delete
keystrokes into one pre-mutation canonical snapshot. A one-second pause, a
change of edit operation, cursor movement or command action closes the group;
the existing failure-atomic sixteen-level snapshot stack remains the storage
boundary.

The hardware-keyboard/VGA acceptance types `abc` and restores the empty
document with one Alt-Backspace. It then types `a`, waits past the coalescing
window, types `b`, and requires two separate undo states before returning to
empty. The focused `document-editing` group passes all 158 native commands and
exact VGA checkpoints on QEMU `486,-fpu` with 8 MiB; startup took 46.629
seconds. Both x64 rebuild generations and the native cross-build pass. The
tested disk SHA-256 is
`f024dc3eb3c7764a69efd4d3ad50b2b729b108d754f27716b9fd6fccc7085032`.

## Original F4 path insertion (2026-09-24)

Native `DocEd` now implements the original F4 action over the existing VGA file
picker. Enter on a file returns its absolute path and inserts it at the canonical
cursor; Shift-F4 returns a selected directory path. The entire path uses one
undo snapshot, Escape cancels without mutation, and public `EdDir` retains its
existing browse/edit/create/rename/delete behavior through the same picker core.

The focused hardware test selects `C:/Browse/Other.HC`, checks the exact inserted
text and cursor, undoes it, then selects `C:/Browse/Code` with Shift-F4 and
checks and undoes that insertion. The surrounding file-navigation workflow also
passes. All 36 native commands and exact VGA checkpoints pass on QEMU
`486,-fpu` with 8 MiB; startup took 46.681 seconds. Both x64 rebuild generations
and the native i386 cross-build pass. The tested disk SHA-256 is
`111e8a72e9e87b619dc211052a8e8eb1ef1513a34d1e1e1d59548261e99a5e1d`.

## Failure-atomic canonical paste (2026-09-24)

Native clipboard paste no longer publishes copied records one at a time. It
serializes the retained clipboard, loads the complete canonical record graph
into a temporary document, and completes any required cursor-boundary split.
Only then does it splice the staged entries and renumbered binary records into
the destination, with no allocation or other recoverable failure point left.

The retained allocation gate discovers the complete paste allocation count and
injects `OutMem` at every step. Each case requires byte-identical target
serialization and exact task-heap recovery. The ordinary hardware copy, cut and
paste sequence continues to pass exact VGA checks. The focused
`document-editing` group passes all 158 native commands on QEMU `486,-fpu` with
8 MiB; startup took 46.729 seconds. Both x64 rebuild generations and the native
i386 cross-build pass. The tested disk SHA-256 is
`82955fcbb28d0ad43b6fb542cdc94bbb5a4e6144aa5522528cb9eec253c42581`.

## Native PC-speaker service (2026-09-24)

The normal i386 HolyC scope now exports the original `Snd(I8 ona=0)` primitive
and `SndRst`. Nonzero Ona values program PIT channel 2 from the twelve-tone
TempleOS scale (`60` is 440 Hz), then enable the PC-speaker data and gate bits
at port `0x61`; zero disables both bits. The short critical section restores the
caller's interrupt-enable state, and the implementation has no FPU dependency.

The focused normal-boot hardware check calls `Snd(60)`, immediately latches PIT
channel 2 and verifies the divisor range, speaker gate and interrupt state. It
then checks both direct stop and `SndRst`. All three commands pass on QEMU
`486,-fpu` with 8 MiB; startup took 47.134 seconds. Both x64 rebuild generations
and the native i386 cross-build pass. The tested disk SHA-256 is
`09ddf4bf98a49ce067baca74c6335481992862e22126ccb233688621c7012dcf`.
This proves emulated PIT/speaker programming; audible output and timer coexistence
on a named physical PC remain open promotion evidence.

## Native PS/2 mouse input (2026-09-24)

Normal boot now enables the 8042 auxiliary port, configures its interrupt bit,
starts a standard PS/2 mouse and unmasks IRQ12 together with the PIC cascade.
The IRQ path distinguishes auxiliary status from keyboard traffic, resynchronizes
on the packet header, rejects overflow/error bytes and decodes signed relative
motion into coordinates clamped to the 640×480 VGA surface. It retains the low
three button bits, packet count and dropped-byte count.

ConsoleRuntime ABI 28 carries the installed state into the normal console and
exports `MouseGet(&x,&y,&buttons,&packets)` to HolyC. QEMU hardware injection
verifies the initial center, relative X/Y movement and left-button down/up.
Mouse setup is optional: if auxiliary initialization fails, normal boot continues
with IRQ12 masked and `MouseGet` reports unavailable, preserving the keyboard-only
baseline required by older machines.

The combined keyboard, mouse and speaker run passes all seven submitted commands
and exact VGA checks on QEMU `486,-fpu` with 8 MiB; startup took 47.885 seconds.
Both x64 rebuild generations and the native i386 cross-build pass. The tested
disk SHA-256 is
`2b66e3e8629baafc7893e2d323fce09ded71e85b43dcaf7c8f09e62e77735dc5`.
VGA cursor composition, window-manager routing, wheel negotiation, serial
mouse support and physical-machine evidence remain open.

## Native mouse-to-editor routing (2026-09-24)

`DocEd` now polls the installed PS/2 packet sequence alongside nonblocking
keyboard input and handles a left-button transition as an insertion-point move.
Its hit test walks the canonical `CDoc` entries with the renderer's text, tab,
newline, word-wrap, cursor-cell and viewport rules, clears an existing selection,
and redraws the ordinary block caret at the selected canonical position. The
mapping therefore works after vertical or horizontal editor panning without a
separate flattened document copy.

The QMP interaction harness now has reusable relative-pointer and button actions.
The `mouse` group clicks between characters, checks the exact VGA caret, types at
that position and verifies the serialized cursor and neighboring bytes. A second
60-line document starts with lines 4–59 visible, clicks line 4 through that
scrolled viewport, observes the viewport return to lines 0–55 and verifies the
cursor marker at byte 12. The resulting 14-command group passes on QEMU
`486,-fpu` with 8 MiB; startup took 47.836 seconds and every VGA checkpoint
matched. The tested disk SHA-256 is
`7ccc2da15705db8adf3ae07b75b862b598de32a1fe3ebde0c1f1efbe03fd7deb`.
The combined `mouse` plus `document-editing` regression passes 172 native
commands against the same image, including all existing keyboard editing,
selection, clipboard, search, undo, style and persistence checks.

This establishes editor click routing, not a globally composited pointer.
Global pointer display, drag selection, window/control dispatch, wheel negotiation,
serial-mouse support and physical-machine evidence remain open.

## Native editor mouse pointer (2026-09-24)

`DocEd` now displays a compact 8×10 XOR arrow after the first mouse packet. The
overlay is applied only while uploading VGA rows and is immediately removed from
the retained planar surface, so text rendering, canonical documents and composed
sprite frames remain cursor-free. Movement restores the old ten scanlines from
the current clean backing surface and uploads the new ten-line overlay; it does
not rebuild the full 640×480 graphics frame for each PS/2 packet. Editor exit
clears pointer state before restoring the HolyC console.

The QEMU oracle independently constructs the pointer mask over the expected VGA
palette. It checks motion before a click, the pointer over the clicked caret and
edited text, and a later move to a scrolled document whose exact frame would
detect stale pixels at the former location. The 14-command `mouse` group passes
on QEMU `486,-fpu` with 8 MiB, with 47.885-second startup and disk SHA-256
`bd757ba39252d3a27f037b67208f3c0ccd2aac05bae10043285e16a555444f0f`.
The combined `mouse` and `document-editing` run passes 172 native commands and
all exact VGA checkpoints against the same image, proving pointer visibility is
reset across keyboard-only editor sessions.

Pointer display is currently scoped to `DocEd`. Global console/help/file-picker
composition, window/control dispatch, wheel negotiation and
physical-machine evidence remain open.

## Native editor drag selection (2026-09-24)

Holding the left mouse button in `DocEd` now records a stable logical anchor and
extends selection as PS/2 movement packets arrive. Visible endpoints are mapped
through the same viewport hit test as clicks. The selection core resolves the
high endpoint first, splits text records at both canonical offsets, marks the
intervening entries with `DOCET_SEL`, and leaves the caret at the moving endpoint.
This produces the same retained selection records used by keyboard extension,
clipboard commands, deletion and typed replacement. Reverse dragging keeps the
caret before the selected range as expected.

QEMU tests drag forward over `bc` and backward over `cde`, check exact inverted
VGA cells under the XOR pointer, release the button, replace each selection with
`X`, and verify the resulting text and cursor marker in serialized documents.
The expanded 22-command `mouse` group passes on QEMU `486,-fpu` with 8 MiB;
startup took 47.938 seconds and the tested disk SHA-256 is
`c612471d13947d244068f781461373b548bb94f9963df670442345f926d19725`.
The combined `mouse` and `document-editing` regression passes 180 native
commands and every exact VGA checkpoint against the same image.

Automatic viewport scrolling during a drag, global pointer/event dispatch,
wheel negotiation and physical-machine evidence remain open.

## Native file-picker mouse routing (2026-09-24)

The native file picker now polls the shared PS/2 sequence in its nonblocking
keyboard loop and composites the same transient XOR pointer over its clean text
planes. A left-button transition maps VGA rows 4–59 through the current picker
scroll offset and updates the existing selected index. Keyboard navigation and
Enter continue through the same selection and open paths. Nested `Ed` sessions
temporarily own and clear their editor overlay; returning restores picker pointer
ownership before redrawing the selected row.

The QEMU mouse acceptance creates two RedSea files, clicks `Two.HC`, checks the
exact selected picker frame and pointer, opens the file through public `EdDir`,
verifies its canonical contents in `DocEd`, returns to the still-selected picker,
and exits normally. The expanded 27-command `mouse` group passes on QEMU
`486,-fpu` with 8 MiB. The combined `mouse` and `file-navigation` run passes 63
native commands and every exact VGA checkpoint, including the existing
keyboard-only picker sessions; startup took 48.036 seconds and the disk SHA-256
is `1449f8850e9aa126907a48b25f382a266d9a039e9b12454cd0fd1df4d5395429`.

Mouse-driven picker dialogs and operations, console pointer composition, wheel
negotiation and physical-machine evidence remain open.

## Native help-viewer mouse routing (2026-09-24)

The native help viewer now polls the shared PS/2 packet sequence and composites
the same transient XOR pointer used by the editor and file picker. Its hit test
projects plain text with the viewer's newline, carriage-return, tab and wrapping
rules, maps the clicked VGA cell back to a source offset, and selects the link
whose visible range contains that offset. Enter continues through the existing
link-opening path. A nested help document temporarily owns the overlay; returning
restores the parent pointer and selected link.

The QEMU mouse test clicks `::/Doc/Asm.DD` in the packaged compiler overview,
checks the exact selected cells and pointer, opens the assembler document, then
returns to the same selected parent frame with the pointer restored. The focused
28-command `mouse` group passes on QEMU `486,-fpu` with 8 MiB; startup took
47.986 seconds and every VGA checkpoint matched. The tested disk SHA-256 is
`a818307ae661b1bf6a9bb1082d006912553623d754817accbbf4a2873c28124a`.
The combined `mouse` and keyboard-driven `help` regression passes 37 native
commands and all exact VGA checkpoints against the same image, with 47.936-second
startup. This checks that a later keyboard-only help session starts without a
stale mouse overlay.

The picker and help viewer now recognize a second press on the same selected item
within 500 ms and send it through the same activation path as Enter. This opens
files or directories and follows help links without creating a parallel mouse-only
action path.

The focused `mouse` group passes 28 native commands, and the combined mouse,
file-navigation and help regression passes 73 commands on QEMU `486,-fpu` with
8 MiB. Startup took 47.883 seconds, every exact VGA checkpoint matched, and the
tested disk SHA-256 is
`23ec15f93be5e9cd8efda42413be43ff3d8eae3b225bd0a348d8998aa0d3bde6`.

Mouse-driven picker operations, wheel negotiation and physical-machine evidence
remain open.

## Native HolyC-console mouse pointer (2026-09-24)

The normal HolyC shell now polls keyboard and PS/2 input cooperatively instead of
sleeping inside a keyboard-only read. The first mouse packet composites the same
transient XOR arrow over the clean console planes, and later movement restores
the old scanlines before displaying the new position. A keyboard event restores
the clean pointer rows before changing or presenting text; subsequent mouse
activity makes the pointer visible again. Entering an editor, picker or help
viewer therefore hands the physical frame to that surface without retaining
pointer pixels in console history.

The QEMU mouse group now waits for the console to consume injected relative
movement and compares the complete 640x480 prompt frame, including the pointer,
before typing the next command. The focused 28-command group passes on QEMU
`486,-fpu` with 8 MiB; startup took 48.035 seconds, every exact VGA checkpoint
matched, and the tested disk SHA-256 is
`eeaf055cf935c20fec4c49d2b5abe8f426f100283c0d2e83dbc16e715fbc77b8`.
The combined keyboard, mouse, file-navigation and help regression also passes
73 native commands against the same image with 47.987-second startup. Its normal
prompt checkpoints contain no stale pointer after typing, while nested editor,
picker and help frames retain their own pointer ownership.

## Native editor drag autoscroll (2026-09-24)

While a left-button selection drag is active, additional PS/2 packets at the
clamped bottom screen edge now project one row beyond the current viewport.
Horizontal offsets are implemented but lack dedicated acceptance coverage; the
top-edge branch is currently rejected by the hit test and remains unfinished. The existing canonical hit test chooses that logical endpoint,
the selection core updates the same `DOCET_SEL` records used by keyboard and
clipboard actions, and the cursor-following renderer advances the viewport.
Repeated relative motion therefore continues scrolling even while the visible
mouse coordinate remains clamped at the VGA boundary.

The QEMU acceptance starts from a 60-line canonical document, anchors at its
beginning, drags to y=479 and then injects another downward relative packet. It
checks that the viewport advances twice, compares all selected text cells and
the edge pointer in the exact 640x480 frame, and verifies the serialized cursor
between line 57 and its newline. The expanded focused `mouse` group passes 31
native commands on QEMU `486,-fpu` with 8 MiB; startup took 48.430 seconds and
the tested disk SHA-256 is
`3d4ec2c78bb98427bb293e7544e8943cb3190efe551561b88e1ef92f29357cac`.
The combined `mouse` and `document-editing` regression passes 189 native
commands and every exact VGA checkpoint against the same image, with
48.437-second startup.

## Native editor upward drag autoscroll (2026-09-24)

The editor's fixed header occupies VGA y=0–31, while the first editable text
row starts at y=32. The earlier top-edge test at y=0 never reached the document
hit test. During an active left-button drag, y=32 or a pointer in the header now
projects through the first text row with a one-row upward offset; an ordinary
click in the header still does not start a drag. A 60-line QEMU case first
scrolls downward, then drags back to y=32 and sends another upward PS/2 packet
at y=24. It verifies two upward-scroll events, the exact selected VGA cells and
pointer, and the 179-byte canonical `DocSave` output beginning with `00\n`.
The focused `mouse` group passes 34 native commands on QEMU `486,-fpu` with
8 MiB and exact VGA checks; startup took 48.738 seconds. The combined mouse
and document-editing regression passes 192 native commands on the same image,
with exact VGA checks and 50.082-second startup. The tested disk
SHA-256 is `10e71c170e264825e59063a36b221ec61ea93ef6a4cfdf41ce8867764eea98b3`.
Stationary-hold and horizontal edge behavior remain open.

## Native editor horizontal drag autoscroll (2026-09-25)

A 100-column unwrapped document exposed a false positive in the right-edge
logging: the hit test accounted for the visible block caret and stopped at
logical column 79, so repeated packets logged autoscroll without moving the
selection or viewport. The right-edge projection now reaches the first
offscreen insertion point. A QEMU case drags to x=639, sends another clamped
rightward packet, and verifies the exact selected VGA frame and a `DocSave`
cursor marker at column 81. It then reverses across the left edge in bounded
PS/2 moves, sends another clamped packet, checks the restored start viewport
and verifies the 100-byte canonical save with no start-of-document cursor
marker. The focused `mouse` group passes 44 native commands on QEMU
`486,-fpu` with 8 MiB and exact VGA checks; startup took 49.671 seconds.
The tested disk SHA-256 is
`add1e106a2d162cc1463ab64b12e260cdafae2e74bcbc631d9c13a2c13256143`.
The combined mouse and document-editing regression passes 202 native commands
with exact VGA checks on the same image; startup took 49.976 seconds.
Stationary-hold scrolling remains open.

## Native editor held-edge autoscroll (2026-09-25)

The mouse drag path previously advanced only when `MouseGet` reported a new
PS/2 packet. A QEMU test holding the left button at the bottom edge without
further packets timed out waiting for a second viewport advance. `DocEd` now
arms a 350 ms timer while an active drag rests on a vertical or horizontal
edge, then repeats at 250 ms intervals. The timer is canceled when the button
is released or the pointer leaves the edge, and a repeat redraws only when the
canonical insertion point moves. The new test verifies the second advance,
selected VGA frame, saved cursor, and absence of further scroll events during
a 700 ms post-release wait. The focused `mouse` group passes 46 native commands
on QEMU `486,-fpu` with 8 MiB and exact VGA checks; startup took 48.178
seconds. The combined mouse and document-editing regression passes 204 native
commands on the same image with 48.132-second startup. The tested disk
SHA-256 is `18962f93d172b9c34ef2d291272c4aed8786698e9a22ff58e20e5e60ad05c648`.

## No-FPU writable project and help return (2026-09-25)

The existing three-boot project acceptance previously used QEMU's default
`486` CPU profile. It now defaults to `486,-fpu` on every boot, with an explicit
`--cpu` override. During the first boot, the saved HolyC program opens packaged
help with F1; Escape must restore its exact editor frame before F5 saves and
executes it. The subsequent boots reopen, revise and re-execute the saved
program. The current run passes 107, 56 and 15 guest commands respectively at
8 MiB. Its independent host audit finds 18 reachable directories, 838 files
and 14,371 owned sectors, with the RedSea bitmap matching reachable extents;
the source image remains unchanged. The source disk SHA-256 is
`18962f93d172b9c34ef2d291272c4aed8786698e9a22ff58e20e5e60ad05c648`.
This proves the tested project workflow across three boots, while the broader
graphics/sound concurrency, resource limits and native self-hosted rebuilds
remain open.

## Later 32-bit QEMU project regression (2026-09-25)

The same writable three-boot project test also passes on QEMU
`pentium3,-fpu` at 8 MiB: 107, 56 and 15 guest commands, including help return,
F5 execution, project revision after reboot and the independent RedSea
extent/bitmap audit. It starts from the same source disk SHA-256
`18962f93d172b9c34ef2d291272c4aed8786698e9a22ff58e20e5e60ad05c648`
and produces the same final candidate SHA-256
`2ed9539fa5e61967ecd300eae91dc8c21ed74a50741633ccc7f722157a9c0bb4`.
The tested QEMU profiles and open compatibility gates are published in
`docs/i386-support-matrix.md`. This verifies that the workflow is not tied to
one emulated CPU model; it does not establish the 80386 instruction baseline or
native self-hosting.

## 386 boot executable-region audit (2026-09-25)

The i386 build now emits a NASM listing and derives the exact executable
boundaries before the BIOS loader's drive data and before the protected-mode
stage's early IDT. `tools/audit-i386-boot.py` disassembles all 325 16-bit code
bytes and 104 32-bit stage code bytes, checks contiguous decoding and rejects
instructions outside the boot's 386 allowlist. The gate passes 96 BIOS and 33
protected-mode instructions in the current image; `result.json` records the
range hashes and counts. Four host mutation tests pass, and injected BSWAP,
CPUID and x87 bytes in the actual image are rejected. The rebuilt image passes
a normal QEMU `486,-fpu` keyboard/VGA boot check at 8 MiB. The existing kernel
build also classifies and audits linked T32M code. Live native JIT output and
other executable paths still need comprehensive audit coverage before the full
386 instruction baseline can be claimed.

## Native JIT code-span contract (2026-09-25)

The native compiler now exposes each generated function's allocation length
and executable/data split through version 50 of its service table while the
compilation control remains live. Publication checks that the split is inside
the allocation before transferring code to task-owned storage. The program
publication probe corrupts the split to zero and past the allocation, then
checks that both attempts are rejected without publishing symbols or leaking
storage. This establishes bounds for a future QEMU capture of live JIT bytes;
it does not yet audit those bytes or prove full 386 ISA coverage.
The x86-64 two-generation rebuild and `python3 tools/build-i386-kernel.py --test`
pass. The latter boots the 8 MiB diagnostic image, observes all 14 program
publication cases in both probe phases, runs the normal interactive suite and
file-recovery matrix, and confirms original TempleOS can read and reproduce a
native i386 document.

## First live native JIT instruction audit (2026-09-25)

The diagnostic compiler probe now exports exact allocation bytes and code/data
boundaries for six functions compiled inside the i386 guest: a direct call,
recursion, a default argument, a literal-returning function, static state and
a static string initializer. The host checks that both probe phases provide
all twelve captures, disassembles only the executable ranges and applies the
same 386 instruction allowlist as the linked-module audit. The current QEMU
diagnostic run passes 1,238 code bytes and 622 instructions; `DurableText` has
six literal-pool bytes excluded by the recorded boundary. Five host mutation
checks reject forbidden opcodes, an incorrect code/data boundary, mismatched
payload length and missing capture metadata. The 8 MiB normal QEMU boot also
passes all 137 compiler-group commands with matching VGA pixels. This is direct
evidence for the sampled live JIT paths, not a claim
that every possible generated function has been audited.

## Shared native T32M serialization (2026-09-25)

An allocation-free T32M serializer now accepts emitted code, relocation/export
records and a string table, and validates the finished module with the shared
loader contract. Both the x86-64 bootstrap writer and the retained i386
compiler runtime use this serializer. In two QEMU diagnostic phases the native
compiler packages a guest-compiled constant function into a 101-byte module,
loads its 48-byte executable image, executes it for value 42 and reclaims the
temporary allocations. The probe also rejects an out-of-range name offset and
a short output buffer without touching its sentinel byte. This establishes
guest-side module creation and loading; full native AOT relocation generation,
disk installation and two-generation self-hosting remain open.

The x86-64 two-generation rebuild and full `python3 tools/build-i386-kernel.py
--test` gate pass on this change, including 495 native commands and exact VGA
checks in the normal 8 MiB QEMU boot, file-failure recovery and original
document cross-compatibility. `build/i386-kernel/result.json` records the two
native module phases and all twelve live-JIT captures.

## Native module RedSea round trip (2026-09-25)

The writable diagnostic image now uses the guest compiler's T32M serializer to
save `C:/Probe/DurableConst.t32m`, read the exact bytes back, load and execute
the module, and reclaim its temporary allocations. The test boots that same
image again and requires the pre-existing module to load and return 42 before
replacing it. The ordinary diagnostic image remains read-only. This establishes
disk persistence for a native-generated module, while complete relocatable AOT
generation and a bootable native installation remain M7 work.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The latter records `native_module_disk: pass` in
`build/i386-kernel/result.json`, including both QEMU/486 writable boots, the
normal 8 MiB session, and the filesystem failure/recovery matrix.

## Native call relocation capture (2026-09-25)

The native frontend now retains named `CALL rel32` sites with each compiled
function until its compilation control releases the code. A compiler service
reports their offsets and names. The guest packages its own compiled recursive
`DurableFact` function as a T32M export plus relocation, loads it at a new
address, and executes `DurableFact(5)` for 120 in both diagnostic phases.
This moves native output beyond a fixed-address function. Packaging complete
source units still requires multi-function layout, data and external binding
records, and the disk-to-disk native build path.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The QEMU/486 manifest records the 324-byte guest-built
relocatable module, its 256-byte loaded image, execution in both diagnostic
phases, the normal 8 MiB session, two-boot RedSea persistence and filesystem
failure recovery.

## Guest-built multi-function module (2026-09-25)

The native frontend now exposes a module packer for selected live HolyC
functions. It lays out function bodies, emits named exports and call
relocations, then uses the shared T32M serializer. The guest compiles
`DurableLeaf` and `DurableRoot`, packages them into one module, loads it at a
new address and executes the cross-function call for 42. The writable QEMU
diagnostic disk saves this module to RedSea, reopens it and executes it; a
second boot must execute the existing file before replacing it. Functions
with embedded data are rejected until native data records are implemented.
Full source-unit compilation and native installation remain M7 gates.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The QEMU/486 result manifest records a 212-byte native
multi-function module, its 104-byte loaded image, both diagnostic phases,
the two-boot RedSea round trip, the normal 8 MiB session, and the filesystem
failure/recovery matrix.

## Native function literal pools in T32M (2026-09-25)

The native multi-function packer now emits `DATA_RANGE` records for the
literal pool at the end of each compiled function. The QEMU probe includes
`DurableText` alongside `DurableLeaf` and `DurableRoot`, loads the guest-built
module, and checks that `DurableText()` returns `"hello"` from within the
new loaded image. The same module is saved, reopened and executed from RedSea
on the writable boot and on the following reboot. Global and static variable
storage and address relocations remain separate M7 work.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The guest-built module is 312 bytes and its loaded image is
160 bytes. An independent host walk of the writable RedSea disk confirms three
exports, the `DurableRoot` to `DurableLeaf` call relocation, and a six-byte
data range covering `"hello"`. The new retained disk assertion passes against
that QEMU artifact; the normal 8 MiB session and filesystem recovery matrix
also pass.

## Native load-time function binding (2026-09-25)

The guest compiler now packages `DurableRoot` alone as a T32M whose named
`DurableLeaf` call remains unresolved on disk. The loader rejects that module
without a binding, then binds the call to the currently resident `DurableLeaf`
function and executes the loaded `DurableRoot` for 42. The probe writes the
module to RedSea, reopens and binds it, and repeats that operation after a
second writable boot. A host-side RedSea audit checks that the saved module
contains one export and one zero-placeholder named call to `DurableLeaf`.

This establishes external function binding for guest-built modules; it does
not yet provide a stable system binding table or a complete source-unit build.
`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The module is 144 bytes and its bound image is 64 bytes;
both diagnostic phases, the normal 8 MiB session, the two writable boots,
filesystem recovery, and document compatibility pass.

## Native two-file T32M link (2026-09-25)

The native compiler now packages `DurableRoot` and `DurableLeaf` into separate
T32M files. The guest loader resolves the root's named call from the leaf
module, loads both into one image, and executes the root for 42 without a
resident binding. The probe writes the leaf file alongside the earlier root
file, reopens both and links them again, then repeats that operation after a
writable reboot. The retained host audit checks the leaf file's sole export.
This is a cross-module link from guest-built artifacts; full source-unit
compilation and globals remain M7 work.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The root and leaf modules are 144 and 100 bytes, and the
combined loaded image is 104 bytes. Both diagnostic phases, the normal 8 MiB
session, the two writable boots, filesystem recovery, and document
compatibility pass. The host RedSea audit confirms the saved leaf export.

## Native function-address relocation (2026-09-25)

The shared expression parser now lets the native JIT retain a named
`&function` node while it parses in non-AOT mode. The frontend records the
generated `ADD imm32` address site as a T32M `ADDRESS` relocation, patches the
live JIT copy for immediate use, and zeros the serialized placeholder for
load-time resolution. Host expression parsing keeps its previous behavior.

The QEMU probe compiles `DurableAddress()` to return `&DurableLeaf`, packages
the two functions as separate guest-built modules, and loads them together.
It verifies that the returned pointer names the leaf entry in the newly loaded
image and that calling through it returns 41. The address module is saved to
RedSea and checked again after a writable reboot; the host audit inspects its
named address record. Data-address relocations, global/static storage, and
complete source units remain M7 work.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The address module is 147 bytes; linking it with the leaf
module produces a 104-byte image. Both diagnostic phases, the normal 8 MiB
session, two writable boots, filesystem recovery, and document compatibility
pass. The host RedSea audit confirms one `DurableAddress` export and one
zero-placeholder `ADDRESS` record targeting `DurableLeaf`. After removing
temporary trace output, a fresh rebuild and diagnostic QEMU boot passed again.

## Native global-data address binding (2026-09-25)

Native JIT parsing now retains named address sites for allocated global
variables as well as functions. The frontend patches each live JIT site for
immediate execution and serializes it as a T32M `ADDRESS` record for load-time
binding. Deliberate zero-address aliases keep their previous immediate
behavior. A guest-built `DurableLater` module carries a named reference to
`DurableData`; the loader rejects it without a binding, then binds it to the
resident global and observes 42 and 43 as that global changes from 20 to 21.
The probe restores the value, writes the module to RedSea, and repeats the
load and mutation check on a writable reboot. A host audit checks the saved
module's `DurableData` address record. Packaging global and static storage
itself inside guest-built modules remains an M7 task.

`python3 tools/test-rebuild.py` and the full `python3 tools/build-i386-kernel.py
--test` gate pass. The module is 193 bytes and its loaded image is 112 bytes.
Both diagnostic phases, the normal 8 MiB session, two writable boots,
filesystem recovery, and document compatibility pass. The retained host
RedSea audit confirms the `DurableLater` export and zero-placeholder
`DurableData` address record.

## Guest-built module owns a scalar global (2026-09-25)

Compiler services version 54 adds `program_pack_data`, which serializes
selected 64-bit scalar globals with functions into one T32M. It emits a data
range and named `DATA_EXPORT` for each selected global, alongside the
function's named `ADDRESS` relocation. The QEMU probe packages `DurableLater`
and `DurableData` together, loads without a resident binding, checks the
initial value 20, changes the loaded copy to 21, and sees the function result
change from 42 to 43. It saves and reloads the module from RedSea on two
writable boots. A host audit checks the saved function export, data range,
data export, address record and initial bytes. Static variables, aggregates,
and pointer initializers still need native packaging.

Validation: `tools/test-rebuild.py` passes. Both phases of the native QEMU
diagnostic boot pass with a 245-byte module and 120-byte loaded image. A
separate writable QEMU boot writes, reads, and executes the module; a second
boot reads and executes that existing file before replacing it. The host
RedSea audit confirms all four module records and the initial scalar value.
The full `build-i386-kernel.py --test` promotion run reached the normal
workstation session, where the 60-second startup deadline expired during
source startup under a heavily loaded host. The full gate remains pending.

Checkpoint `4a861e3` is committed and pushed. A subsequent focused retry with
`python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img --out
build/i386-kernel/owned-data-normal-retry --group compiler` also expired at
the unchanged 60-second startup deadline, before any compiler-group commands
ran. Its log ends after `STARTUP source begin` and `COMPILER BREAK ready`.
Host CPU load was high during both attempts, but its causal role is unproven;
rerun on an idle host and investigate startup if the timeout persists before
claiming full promotion. The successful writable-boot evidence is in
`build/i386-kernel/owned-data-writable` and
`build/i386-kernel/owned-data-reboot`; both reached normal startup completion.
The saved module's SHA-256 is
`cb439e19622a3264c40455b46204b9e34e37d3793a3600aecc302dd1d756170c`.

On 2026-09-26, `python3 tools/build-i386-kernel.py --test` passed from clean
revision `7590ffd` on an idle host. Its manifest is
`build/i386-kernel/result.json`: both diagnostic phases, the normal 8 MiB
workstation session (48.57-second startup and 558 input lines), two writable
module boots, file interruption/recovery, and original/native document
compatibility passed. The manifest records compiler services version 54 and
the owned-global disk audit above. This closes the promotion gap recorded in
the preceding paragraph; the earlier timeout occurred under heavy host load.

## Guest-built module carries initialized class storage (2026-09-26)

The native module packer now copies a selected global's full initialized byte
range and checks its class members recursively for pointer fields. This admits
pointer-free aggregates and arrays while keeping live guest pointers out of
serialized data. The QEMU probe packages `DurablePairSum` with the initialized
16-byte `DurablePairData` class, loads the module without resident bindings,
checks 20+22=42, mutates the loaded second member to 23, and observes 43.
Both diagnostic phases pass with a 335-byte module and 168-byte loaded image.
`python3 tools/test-rebuild.py` and the full
`python3 tools/build-i386-kernel.py --test` gate pass. The normal 8 MiB boot took
48.49 seconds; the 558-line workstation session, two writable boots, file
recovery and document compatibility passed. The host RedSea audit confirms
the 16 initialized bytes, data range/export, named address records and SHA-256
`27dd6d800cedcf77d3d7d16babc62f98d74daae76348e2411ad161771d96316e`.
Array sizing is handled by the packer but has no dedicated disk probe yet.
Static member storage and pointer initializer fixups to external targets remain open.

## Guest-built module relocates initialized data pointers (2026-09-26)

The module packer now finds pointer fields from the native type layout and
records non-null initialized pointers that target selected module data. The
shared T32M serializer writes a version 3 stored-pointer record and zeros its
slot; the loader restores a pointer to the relocated data. The guest probe
packages `DurableByteRead`, `DurableBytes[4]="abc"`, and
`DurableBytesPtr=DurableBytes` in one 309-byte module. It loads the module
without resident bindings, checks that the pointer targets the loaded array,
changes the loaded `b` to `Z`, and observes the function result change from
98 to 90. The probe also confirms that packaging the pointer without its
target array is rejected. `python3 tools/test-rebuild.py` and the full
`python3 tools/build-i386-kernel.py --test` gate pass: both diagnostic phases,
the normal 8 MiB boot (48.00 seconds), all 558 workstation input lines, two
writable module boots, file recovery and document compatibility. The host
RedSea audit confirms the version 3 pointer record, its target, the zeroed
pointer slot, initial array bytes and SHA-256
`ba49dd76740f1c94014d5ca7b18a2b6e6234cb6a4a55ba25b207573c2f431a4f`.
Pointers to data outside the selected module are rejected until named pointer
imports have a module contract.

## Guest-built modules link an initialized pointer across files (2026-09-26)

T32M version 4 adds a named stored-pointer record for an initialized data slot.
The shared validator requires a zero slot wholly inside a data range, a valid
name and no overlap with another pointer record. The loader resolves that name
uniquely against the selected modules or explicit bindings before writing the
image, then stores the absolute loaded address. Versions 2 and 3 retain their
existing meanings. The native packer emits version 4 when an initialized
pointer exactly matches a function or global symbol outside its selected
module; a selected local data target still uses version 3.

The QEMU probe builds a consumer containing `DurableByteRead` and
`DurableBytesPtr`, and a separate provider containing `DurableBytes[4]="abc"`.
It loads the pair, checks pointer identity and the byte value, changes the
loaded `b` to `Z`, and checks the read again. Both diagnostic phases pass with
269-byte consumer and 154-byte provider modules and a 152-byte loaded image.
Focused native loader tests cover execution, unresolved-name rejection and
wrong-version rejection. Both writable boots pass: the first writes, reads and
executes the pair; the second reads the existing files, executes them, then
replaces and executes them again. The independent host audit confirms the
version-4 consumer's named zero-slot record and the version-2 provider's
initial `abc` bytes. Their SHA-256 hashes are
`97e5e162223740df6561cd7cb05a7c1806c9c8a4e36d6db02394d647a34e796e`
and `f8ca89713d829fd20c1e6183843e18ece6c0ea52fc8c7854fe0921c311d289d7`.

The additional resident validator and loader code exceeded the former
848-sector BIOS load reservation by 4184 bytes. The reservation is now 880
sectors, ending at `0x7E000`, 40 KiB below the task-stack reservation at
`0x88000`. The 434264-byte kernel plus 4096-byte early stage leaves 12200
bytes in the new load area. The 386 boot instruction audit and both x86-64
self-rebuild generations pass. The full promotion invocation completed both
diagnostic phases, all 558 normal-workstation input lines, the startup rejection
checks and both writable boots. It then stopped at a Python closure mistake in
the new host audit; that audit was corrected and passed directly on the saved
disk. The remaining mutation reboot, all 13 move and seven replacement
interruption/recovery cases, and original/native document compatibility passed
in a resumed run. One uninterrupted `--test` invocation after the audit fix
had not been repeated at that checkpoint. The later version-55 full gate below
closes that verification gap. This is still an incremental native module
contract, not complete source-unit packaging or self-hosting.

## Guest compiles and persists a complete small source unit (2026-09-26)

Compiler services version 55 adds `program_pack_unit`. It walks one private
source symbol table, selects all owned function and global definitions, sorts
them by name and serializes them through the shared T32M packer. The native
probe compiles `UnitBase=20`, `UnitAdd(x)` and `UnitMain()` as one source unit.
It releases the compiler control, loads the resulting version-2 module, sees
42, changes the loaded global to 21 and sees 43. The 331-byte module loads as
a 168-byte image. A writable QEMU boot saves and executes it from RedSea; the
next boot loads the existing file, executes it, replaces it and executes again.
The independent disk audit confirms both function exports, the global's data
range/export, call and address relocations, initial value 20, and SHA-256
`fda02988470fc9022196f760bb976bb54a38dbc5beb1996531d05f4c0b049d84`.

The packer now rejects functions with local `static` members. Their JIT
storage lies outside the function's code/data image, so serializing those
functions today would retain invalid live addresses. Static relocation,
complete delivered source-tree packaging, system bindings, installation and
self-hosted rebuilding remain open. Both x86-64 self-rebuild generations, the
native cross-build and 386 boot instruction audit, two diagnostic phases and
both writable module boots pass.
The uninterrupted `python3 tools/build-i386-kernel.py --test` gate now passes.
The normal 8 MiB startup took 48.35 seconds and the workstation submitted all
558 input lines. Both writable module boots, the independent saved-file audit,
all 13 move and seven replacement interruption/recovery cases, and
original/native document compatibility passed. The builder manifest is
`build/i386-kernel/result.json`.

## Guest-built source units retain local static data (2026-09-26)

The native expression parser now preserves addresses of function-local `static`
storage for module relocation while leaving the original x86-64 compiler's JIT
path unchanged. Before JIT code is emitted, the i386 frontend gives each local
static a stable private name derived from its function and member ordinal. The
source-unit packer includes that initialized storage as owned data and records
the code-to-data address relocation. Packing a function without its static data
still fails, rather than writing a live heap address into a module.

The guest source-unit probe adds `UnitNext`, whose `static I64i n=40` advances to
41 and 42 after the module is loaded. The 536-byte guest-built module contains
three functions, the existing global, the local static data export, and both
address relocations; its loaded image is 256 bytes. A writable QEMU boot saved
and executed it, and the independent host audit checked all records and initial
values (SHA-256 `a819af3b9fab1955bf9d65afba88409f2416314bab5333140b5008c41454d0f1`).
The second writable boot loaded the existing module, executed it, replaced it,
and completed startup. The x86-64 two-generation rebuild and native cross-build
pass. The full `--test` invocation reached the native diagnostic and normal
interactive phases, then was stopped in favor of these two focused writable
boots; a complete uninterrupted promotion run for this revision remains open.
This closes the
basic scalar-local-static packaging gap, but complete source-tree packaging and
native self-hosting remain open. At that checkpoint, static data containing
pointers to separately allocated literals still needed an owned representation.

## Guest-built units own retained string literals (2026-09-26)

The source-unit packer now scans initialized global and function-local static
storage by type for pointers into retained compiler literal pools. It includes
only referenced pools as private data ranges and emits local stored-pointer
relocations. The pool remains anonymous in the T32M export table, so separate
modules can each contain literals without sharing a generated export name.
The compiler allocation tracker verifies the pool's lifetime and size; a
regular data-heap size check cannot validate code allocations.

The guest fixture adds `UnitLetter`, whose `static U8i *p="AZ"` increments the
loaded literal through that pointer twice. Both QEMU diagnostic phases and the
first writable boot execute it successfully. The 819-byte version-3 module
loads as a 384-byte image; the independent saved-file audit checks its four
function exports, three data exports, anonymous three-byte literal range,
stored-pointer target, initial bytes, and SHA-256
`bfa4f710c6cd3a295f1af31efa036e1a3bdd68ee4d85b67984387b58e57d62a5`.
The second writable boot loaded and executed the existing module, replaced it,
and passed the same byte audit. The x86-64 two-generation rebuild and native
cross-build pass. The complete `--test` promotion sequence has not been rerun
for this revision; the two focused writable boots and saved-file audit cover
the changed path. Source-tree
packaging, multi-module system bindings, and native self-hosting remain open.

## Guest packages a delivered production source file (2026-09-26)

The native compiler now reads `/Kernel/KMathInt.HC` from RedSea through its
ordinary include service, compiles all five original integer-multiple
functions, packages them as one T32M, releases the compiler control, then
loads and calls the relocated code. The diagnostic checks signed negative
rounding and unsigned cases. It temporarily loads the public scalar classes
from `/Kernel/Types.HH`, matching production boot order, and removes them after
the isolated probe. Both diagnostic phases and two writable QEMU boots pass;
the second boot loads the previously saved module before replacing it.

The guest-built version-2 file is 3,123 bytes and loads as a 2,976-byte image.
The independent disk audit finds exactly the five function exports, with no
extra imports or data records, and SHA-256
`d9e8428dfaff85686e00a9de8efc97234dfcbd3c7c26a18a1be7364624ce8e6f`.
The delivered source SHA-256 is
`2bfea2345cd06ca8beccfd8f717f3b62c75303cc29ef4fc51755184754eb00cf`.
The x86-64 two-generation rebuild and native cross-build pass. The full
`--test` sequence has not been rerun for this revision; the focused diagnostic
and two writable boots cover the new source-file path. This is one production
file, not a compiler/kernel rebuild. Header-rich files, resident bindings,
installation and two self-hosted generations remain open.

## Guest packages delivered Arc source through nested headers (2026-09-26)

The native compiler now reads `/Kernel/ArcSeed.HC` and its nested headers from
RedSea, packages the original `ArcCtrlSeed` function, and loads and executes it
for both 7-bit and 8-bit compression modes. Unlike the earlier integer-math
source, these headers define macros. The direct source-unit path originally
left 24 allocations (1,120 heap bytes) in the global define table. Compiler
services version 56 now lets direct users install the same private define table
used by ordinary transactional input. Control unwind reclaims the macros; the
QEMU probe checks that heap use and allocation count return to baseline.

The x86-64 two-generation rebuild, native cross-build and 386 boot audit pass.
Both QEMU diagnostic phases execute the guest-built 1,116-byte module, loading
1,064 image bytes. A first writable boot saved, reloaded and executed it from
RedSea. The second writable boot loaded and executed the existing module
before replacing it; both boots completed normal startup. The independent
disk audit found exactly one `ArcCtrlSeed` export and
SHA-256 `f24533ab0c49541e4115da4847a49700e7c8f120a060259d3dd68a0bf708e0ed`.
The source SHA-256 is
`01c83057f7f28f40a9116a10962bcb6bc0231c7ac5ab75052e47266274703721`.
The full `python3 tools/build-i386-kernel.py --test` promotion subsequently
passed on commit `713dd07`, including the normal 8 MiB interactive QEMU
session, two writable boots, file-failure recovery and original document
compatibility. `build/i386-kernel/result.json` records that run.
This is a production source file with nested headers, not a complete
compiler/kernel build or a native installation.

## Guest packages original Arc expansion source (2026-09-26)

The native compiler now reads `/Kernel/ArcExpand.HC` through its shared Arc
header, packages the original `ArcExpandStep`, and loads and executes it with
borrowed callbacks. The probe checks a one-byte decode and a negative reader
result, then requires the heap to return to baseline. The source normally
inherits `TRUE` and `FALSE` from `KernelA.HH`; the isolated compilation unit
defines those two standard prelude macros in its private, unwind-owned table.
The delivered Arc source itself is unchanged. This exposes a requirement for
the eventual complete native build: reproduce the kernel prelude before
compiling its dependent files, rather than relying on ambient host state.

Both QEMU diagnostic phases and normal startup pass. The guest-built version-2
module is 6,398 bytes and loads as a 6,344-byte image. The first writable boot
saved, reopened and executed the module. The independent disk audit finds
exactly one `ArcExpandStep` export and SHA-256
`f4b4d7aa8c23b76fbc93d9ce5020d1f28f96d477798a28467aaf2f5b22c71e22`.
The delivered source SHA-256 is
`e38458ee926e203cd2e5e3d754249ecd3f96fab0b89ecac99f834c1d9527acdc`.
The second writable boot loaded and executed the previously saved module,
replaced it and completed normal startup. The x86-64 two-generation rebuild,
i386 cross-build, and 386 boot audit pass. The full `--test` promotion has not
been rerun for this revision; the focused diagnostic and two writable boots
cover the changed source-file path. This is another production source file,
not a native compiler/kernel rebuild.
