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
