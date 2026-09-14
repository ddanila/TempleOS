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
