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

Controller register and transaction references:
[SeaBIOS PS/2 implementation](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.c)
and [definitions](https://github.com/coreboot/seabios/blob/master/src/hw/ps2port.h).
