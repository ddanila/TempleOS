# Initial native PIC/PIT/RTC interrupts

`Kernel/I386/PicPit.HC` configures the legacy 8259 controllers and PIT through
native HolyC port instructions. It requires single-CPU boot ownership with IF
clear. There is no APIC, TSC, HPET, FPU, or protected-mode BIOS dependency.

- `I386PicInit` remaps IRQ0–15 to vectors 0x20–0x2F and leaves every IRQ masked.
- `I386PicMask` writes an exact 16-bit mask; a caller using a slave IRQ must also
  unmask master IRQ2. `I386PicMaskGet` reads the mask back.
- `I386PicAccept` rejects invalid IRQ numbers and checks ISR bit 7 for IRQ7/15.
  A rejected spurious IRQ7 sends no EOI; a spurious IRQ15 acknowledges only the
  master's cascade. Accepted interrupts require one `I386PicEoi` at completion.
  That sends slave EOI before master EOI for IRQ8–15.
- `I386PitStart` programs channel 0 in binary mode 2 with a divisor from 2 through
  65536, encoding 65536 as zero. `I386PitRead` latches and reads its raw low/high
  counter bytes in order. It uses the 8253 latch operation, not an 8254-only
  read-back command. Tick periods follow the PIT input frequency and divisor;
  no calibrated wall-clock API is provided yet.

The initialization sequences can be compared with SeaBIOS's
[PIC implementation](https://github.com/coreboot/seabios/blob/master/src/hw/pic.c)
and [PIT definitions](https://github.com/coreboot/seabios/blob/master/src/hw/timer.c).

## RTC periodic source

`Kernel/I386/Rtc.HC` provides boot-owned MC146818-compatible CMOS access and
periodic IRQ8 configuration. All calls require one CPU, IF clear, and exclusive
CMOS ownership with NMI disabled. Accesses keep port 0x70 bit 7 set; they do not
infer or restore an earlier NMI policy from that write-only selector. Production
NMI handling and general shared CMOS access remain future work.

Zero a `CI386RtcState` before first use and keep IRQ8 masked during start/stop.
`I386RtcStart(state, rate)` accepts codes 3–15, requires the running 32768 Hz
divider and register B's SET bit clear, saves configuration A/B, disables alarm
and update interrupts, clears old status C, and enables periodic interrupts.
The nominal rate is 32768 / 2^(rate-1) Hz. The fixture uses codes 10 and 11
(64 and 32 Hz). Date representation and other B bits are preserved.

The IRQ8 callback must read `I386RtcAck()` (status C) before PIC EOI; this clears
the device's interrupt flags. `I386RtcStop` disables RTC interrupts, restores A,
clears pending flags, restores B, and releases the state for reuse. Configuration
restoration cannot replay events consumed during ownership. Saved state must stay
intact, and only one state may own the hardware. Null state, invalid rate, repeated
start, and inactive stop fail. These calls do not install gates or change PIC masks.

Register definitions and setup can be compared with SeaBIOS's
[RTC source](https://github.com/coreboot/seabios/blob/master/src/hw/rtc.c) and
[register definitions](https://github.com/coreboot/seabios/blob/master/src/hw/rtc.h).
QEMU's [RTC implementation](https://github.com/qemu/qemu/blob/master/hw/rtc/mc146818rtc.c)
provides the emulated IRQ source used in the test.

## Entry ABI

`Kernel/I386/Irq.asm` contains sixteen 386 entry stubs and a common entry path.
The current bootstrap assembles it with NASM into a fixed-address stage. It is
not yet emitted as a relocatable HolyC module. Install its entry addresses in
32-bit interrupt gates, with code selector 8 and flat data selector 16, and set
`i386_irq_dispatch` before unmasking anything. A missing callback halts.

The callback is `U0 handler(CI386IrqFrame *frame)` using the normal eight-byte
HolyC argument slot. The frame contains sixteen U32 fields:

| Offset | Contents |
| --- | --- |
| 0–12 | GS, FS, ES, DS |
| 16–28 | EDI, ESI, EBP, PUSHAD's saved ESP |
| 32–44 | EBX, EDX, ECX, EAX |
| 48 | IRQ number, 0–15 |
| 52–60 | Interrupted EIP, CS, EFLAGS |

Only the low 16 bits of saved segment-selector slots are significant. The common
entry saves all general registers and segment selectors, clears DF, and loads
flat DS/ES. FS/GS retain their interrupted task/CPU selectors. The callback must
keep IF clear, avoid yielding, and handle PIC acceptance/EOI. The exit restores
segments and general registers, discards the IRQ number, and uses IRETD to restore
the interrupted flags and instruction pointer. The layout assumes a same-ring
hardware IRQ with no CPU error code. Exceptions use the separate entry path below. Privilege-level transitions
are outside both frame contracts.

## Native interrupt-state operations

The i386 compiler implements the existing `GetRFlags` and `SetRFlags` intrinsics
with PUSHFD/POPFD. Values retain HolyC's eight-byte ABI: reads zero-extend EFLAGS,
and writes consume the low 32 bits. Standalone declarations are in `Cpu.HH`;
the full kernel's declarations remain in `KernelB.HH`. Arithmetic flags can be
changed by ordinary generated expression/return code surrounding an intrinsic;
these operations do not make a HolyC expression a carry-preserving assembly block.
The [architectural POPFD restrictions](https://pdos.csail.mit.edu/6.828/2008/readings/i386/POPF.htm) still apply.

`Kernel/I386/Cpu.HC` adds `I386IrqSave()` and `I386IrqRestore(flags)` for single-CPU
critical sections. Save clears IF and returns the prior flags. Restore changes only
IF; restore nested sections in reverse order, using each section's own saved value.
The compiler may emit instructions between reading flags and disabling interrupts;
shared protected work must start after Save returns. These calls do not block NMI,
provide multiprocessor exclusion, or implement an atomic enable-and-halt operation.

The native fixture enables IF with all PIC lines masked, nests two Save calls,
restores the inner disabled state followed by the outer enabled state, and disables
again before device configuration. It also checks zero-extension, upper-half
truncation, DF set/read/clear, and the native flag reader inside IRQ callbacks
against the assembly reader. Generated PUSHFD/POPFD are included in the instruction
audit.

## Exception entry

`Kernel/I386/Exception.asm` supplies entries for vectors 0–16 and a separate
`i386_exception_dispatch` callback: `U0 handler(CI386ExceptionFrame *frame)`.
Install 32-bit interrupt gates with the same selectors as the IRQ path. Entries
normalize the CPU error code: vectors 8 and 10–14 retain the hardware word; the
others push zero. Do not invoke error-code entries using software INT, which does
not push that word. The mapping follows Intel's
[386 error-code table](https://pdos.csail.mit.edu/6.828/2008/readings/i386/s09_10.htm).

The first twelve U32 fields match the IRQ frame. Offset 48 holds the vector,
52 the error code, 56 EIP, 60 CS, and 64 EFLAGS (total 68 bytes). PUSHAD's saved
ESP points to offset 48, not the interrupted stack top. The callback runs with
IF/DF clear and must not yield or acknowledge the PIC. It may edit saved registers
and EIP for an explicitly recognized recovery site. Entry restores the saved frame,
discards vector/error, and returns with IRETD. A missing callback halts.

This requires an intact ring-0 stack and does not provide stack-fault recovery,
an emergency double-fault task/stack, safe NMI handling, page-fault address capture,
debugger integration, or HolyC throw/catch unwinding. The table encodes 386 vectors;
later CPUs' additional exceptions need their own entries before enabling associated
features. As with IRQ entry, this is currently assembled by NASM at a fixed address.

## Verification

`python3 tools/test-i386.py --irq` compiles the actual PIC/PIT/RTC implementations and
handler into an i386 module. The test-only bootstrap builds an IDT and exposes an
interrupt wait function to the HolyC entry. That function is test instrumentation,
not the production kernel's scheduler or interrupt-control API.

The fixture receives at least 32 timer IRQs at divisor 11932, then at least four
at divisor 65536. It checks the saved register values and frame offsets, IF/DF
inside the callback, and general registers, FS/GS and DF after IRETD. The outer
wait deliberately sets DF, while the callback must observe it cleared. A 64-bit
HolyC counter crosses the 32-bit boundary; it is sampled with IF clear to avoid
torn reads. Mask readback, invalid divisors/IRQ numbers, and changing latched PIT
counts are checked too.

Software INT 0x27 and INT 0x2F exercise spurious acceptance when the corresponding
PIC ISR bits are clear. These are not physical line-glitch tests.
Two additional phases mask IRQ0 and unmask IRQ8 plus master IRQ2 (mask 0xFEFB).
Each receives at least eight periodic RTC interrupts, checking status C's IRQF/PF,
the same saved/restored frame invariants, and the 64-bit count. Repeated delivery
exercises RTC acknowledgement and both PIC EOIs. The fixture also checks invalid
rates/state transitions, A/B programming, restoration, and restart. Generated HolyC code, production entry-stub code,
and test-only IDT/wait code are audited as separate executable ranges; descriptor
and entry-pointer tables are excluded from instruction decoding.

Before the hardware IRQ phases, the native callback handles actual DIV-by-zero
(#DE), loading DS with an out-of-GDT selector (#GP, error 0x18), and INT3 (#BP).
The test verifies fault EIP versus post-breakpoint EIP, normalized errors, saved
registers/segments/DF, live IF/DF, and balanced stack restoration. HolyC sets a
known recovery EIP and changes saved EAX; assembly checks the resumed register value
and all other registers. The production exception stubs have a third independently
audited executable range. Recovery addresses belong only to these test sites;
this is not a general fault-skipping policy.

This passes on the QEMU 486/8 MiB runner. Timer calibration, missed-tick accounting,
interrupt latency on vintage CPUs, calendar reads, full exception handling, keyboard/mouse
initialization, task integration, and production boot wiring remain pending.
The standalone test is not a complete 32-bit kernel or physical-386 validation.
