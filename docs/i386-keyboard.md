# Native keyboard-controller transport

`Kernel/I386/Kbc.HH` and `Kbc.HC` provide raw 8042 access through ports 0x64
(status/command) and 0x60 (data). These are bootstrap interfaces requiring one
CPU, IF clear, and exclusive controller ownership. They do not initialize the
keyboard or implement a command-response protocol.

- `I386KbcWrite(controller,value,polls)` waits for input-buffer bit 1 to clear,
  then writes to the command or data port. It preserves queued output.
- `I386KbcRead(data,status)` consumes one available output byte and returns its
  original status. It preserves AUX bit 5 and timeout/parity bits 6/7 so callers
  can route or reject the byte. Null or identical output pointers are rejected;
  failed reads leave outputs unchanged. Output storage must be writable.
- `I386KbcReadWait(data,status,polls)` polls the same read operation.
- `I386KbcDrain(polls)` discards pending output during exclusive boot setup.
  Runtime callers must route bytes instead of discarding keyboard/mouse events.

Poll budgets must be 1–100000; invalid budgets perform no I/O. Busy iterations
read port 0x80 for a bus delay. This bounds iterations, not elapsed time. Status
0xFF is treated as unavailable. Drain succeeds only after observing an empty
buffer within its budget, even if its final permitted read emptied the buffer.
Write success means the byte was submitted, not acknowledged or executed.
Callers must serialize complete transactions and distinguish controller replies,
keyboard replies, scan codes, and auxiliary-device traffic.

`python3 tools/test-i386.py --irq` reads the BIOS-initialized controller command
byte, enables keyboard IRQ delivery, and sends four keyboard echo commands
(0xEE). Each response is consumed by a native HolyC IRQ1 callback through the
production entry stub. The test checks response/status, register and flag
restoration, one interrupt per command, configuration restoration, invalid
arguments, and empty-buffer polling without output changes. The fixture assumes
quiescent keyboard/mouse input and resets the PIC before echo delivery to clear
requests left by polled controller replies.

This passes on QEMU's 486/8 MiB profile. Physical 386/8042 behavior, keyboard
reset and ACK/RESEND handling, scan-set selection and decoding, input queues,
task wakeups, and public keyboard APIs remain pending. No interactive input or
full-kernel boot is claimed by the echo test.

## Deferred byte consumption

`KbcQueue.HH` / `KbcQueue.HC` provide a fixed 64-entry FIFO of raw byte/status
pairs for IRQ producers and task-level consumers. Init, Put and Get save IF,
mask interrupts for the operation, and restore incoming IF. They require one
CPU and exclude NMI access. Initialize live writable queue storage before use;
callers must not modify its head, count or backing array. Reset discards prior
input and must be coordinated with consumers.

Put returns false when full, drops the newest arrival and increments `dropped`
up to 0xFFFFFFFF. Retained input remains in order. A future scan-code decoder
must treat a changed loss count as a stream discontinuity and reset partial
prefix/modifier state appropriately. Once the counter saturates, further losses
cannot be distinguished; recovery must coordinate a queue reset. No queue
allocation occurs in IRQ context.
The status byte is retained without filtering, including AUX and error bits.

Get returns false on empty input or invalid arguments without changing outputs
or removing input. Its two output bytes must be distinct writable storage outside
the queue. Null queue pointers fail harmlessly (Init is a no-op). These APIs
assume a valid initialized record; they do not validate arbitrary memory or
protect against other ring-0 code corrupting queue metadata. Count and loss
snapshots should be read with IF clear when consistency across fields matters.

The IRQ fixture exercises fill, overflow and saturated loss counting, partial
drain followed by wraparound, FIFO order and all status bits, invalid output
pointers, empty reads, and IF restoration. Actual IRQ1 echo replies are queued
by the callback and consumed after the interrupt wait returns. The queue does
not itself provide blocking reads or scheduler wakeups; the input interface
below adds those operations.

## Blocking input broker

`KbcInput.HH` / `KbcInput.HC` associate a raw FIFO with a scheduler and at most
one pending reader. This supports a keyboard input broker that will eventually
decode and distribute events. It is not a broadcast queue or a terminal API.

- `I386KbcInputInit` requires a zeroed persistent record and an initialized
  scheduler. Reinitializing an associated stream is rejected.
- `I386KbcInputPut` publishes a byte/status pair and wakes a registered reader.
  It is usable from a maskable IRQ and never switches the current task. A reader
  already made runnable needs no further wake; additional bytes remain queued.
- `I386KbcInputRead(input,data,status,wait=TRUE)` consumes queued data or blocks
  the current worker. The queue check, waiter registration and blocking all occur
  with IF clear. On resumption it rechecks the queue, so unrelated wakeups do not
  produce phantom input. The original IF is restored on return.

Read is task-context only. Root can consume available data but cannot block.
`wait=FALSE` fails immediately on empty input. While a reader is registered,
other tasks' reads fail without taking its pending bytes. Once the read returns,
that reservation ends. Invalid arguments, empty nonblocking reads and competing
readers preserve outputs. Output bytes must be distinct, writable and outside the
input record. The raw queue's overflow and status-retention contracts still apply.

All operations require one CPU and exclude NMI access. Keep the input record and
scheduler alive throughout use, and do not reset or directly consume its embedded
queue while a reader is pending. A waiting task remains owned by the scheduler;
the existing runtime has no forced cancellation/destruction of blocked tasks.
Timeouts, close/cancel, reader handoff and exception-safe abandonment are pending.

`python3 tools/test-i386.py --input` uses a separate native fixture with the
existing context/IRQ/idle assembly. It checks immediate and nonblocking reads,
argument rejection, a competing reader, spurious wake/reblock, and four real
keyboard echo IRQs waking a blocked worker from root idle. A second publication
before each worker resumption checks retained ordering when the waiter is already
runnable. Worker IF restoration, root IF restoration, no switching inside IRQ,
reader reservation, completion/reaping and controller restoration are checked.
This is QEMU 486/8 MiB evidence. Scan-code decoding, device initialization and
interactive shell input remain pending.

## Scan-set-1 packet decoding

`ScanSet1.HH` / `ScanSet1.HC` decode an established scan-set-1 byte stream,
including the form produced by controller translation of scan set 2. The caller
must configure/verify that format; these functions do not select a scan set.
Use one `CI386ScanSet1` per stream, initialize it with `I386ScanSet1Reset`, and
serialize access in the input consumer. No ports, clocks, allocation or scheduler
operations are used by the decoder.

`I386ScanSet1Feed(state,data,status,scan)` returns 1 for an event, 0 for an
incomplete/ignored byte, or -1 for invalid arguments or corrupt keyboard input.
The output is unchanged unless an event is returned. Output storage must be a
writable U32 outside the decoder record. The value carries the physical base code
in bits 0–6, TempleOS's E0 marker in bit 7, and its release flag in bit 8.
Modifier/lock flags, key mapping, the full paired 64-bit TempleOS scan value and
character conversion are subsequent layers and are not synthesized here.

E0 prefixes apply to the next code. Extended fake left/right Shift bytes are
suppressed, so Print Screen's E0 2A / E0 AA wrappers cannot change actual Shift
state. E0 37/B7 yields physical Print Screen make/release events. The complete
six-byte Pause sequence yields `SC_PAUSE` (0x61) once; the device sends no ordinary
Pause release. Ctrl-Break remains the raw E0 46/C6 pair for later mapping.

Auxiliary bytes and statuses without OBF are ignored without disturbing keyboard
prefix state. Keyboard parity/timeout status, overrun bytes 00/FF and malformed
Pause sequences clear partial state and return -1. The mismatching Pause byte is
discarded. ACK, RESEND and echo replies are ignored and clear partial state;
command ownership must still route replies before decoding. In particular, 0xAA
is a valid left-Shift release in an established stream and cannot be globally
filtered as a reset reply. Explicit reset is required after known input loss or
a stream change; this decoder has no timeout or pressed-key state to repair.

The `--input` fixture checks make/release pairs for ordinary codes 01–5F and
their E0 forms, both fake shifts, complete Print Screen/Pause sequences, auxiliary
interleaving, malformed/error recovery, ignored replies, argument rejection and
unchanged outputs. These are synthetic decoder streams; the separate hardware
phase still uses keyboard echoes. Real key injection, modifier/lock processing,
character mapping and production input-loop integration remain pending.

Raw code/flag conventions come from `Kernel/KernelA.HH` and
`Kernel/SerialDev/Keyboard.HC`. Special sequence behavior is cross-checked against
[QEMU's PS/2 implementation](https://github.com/qemu/qemu/blob/master/hw/input/ps2.c).

Controller register and transaction references:
[SeaBIOS PS/2 implementation](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.c)
and [definitions](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.h).

## TempleOS character conversion

`ScanChar.HH` / `ScanChar.HC` provide `I386ScanCode2Char(I64 scan)`, matching
the existing x64 `ScanCode2Char` behavior. The caller supplies a mapped scan value
with modifier flags; this function does not track key presses or perform keypad
mapping. Extended codes and base codes at or above 0x50 return zero. Ctrl takes
precedence and maps letters to TempleOS's 1–26 control characters. Otherwise
Shift XOR Caps selects the shifted table, including punctuation, Shift-Escape
(0x1C) and Shift-Space (0x1F). Release flags do not suppress character conversion;
the eventual message producer must still distinguish key-down and key-up events.

The native input fixture's x64 compilation step calls the existing OS function
for all 32,768 combinations of bits 0–14 and writes the results into an exported
target data array. Native execution compares every result, then repeats each
comparison with the high 32 bits set. All 65,536 comparisons pass. This provides
an independent compatibility reference rather than a duplicate implementation
in the test. Modifier state, keypad remapping, event dispatch and live keyboard
configuration remain separate work.
