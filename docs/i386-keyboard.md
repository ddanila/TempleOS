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
not yet provide blocking reads or scheduler wakeups.

Controller register and transaction references:
[SeaBIOS PS/2 implementation](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.c)
and [definitions](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.h).
