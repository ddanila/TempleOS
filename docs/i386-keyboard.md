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

Controller register and transaction references:
[SeaBIOS PS/2 implementation](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.c)
and [definitions](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.h).
