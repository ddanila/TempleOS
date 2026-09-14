# Native PIT interrupt counter

`Kernel/I386/Timer.HH` and `Timer.HC` provide a single-CPU 64-bit serviced-tick
counter over the existing PIT channel-0 driver. `PicPit.HH` declares the shared
PIC/PIT operations. The caller exclusively owns channel 0 and supplies a live,
initially zeroed `CI386Timer` record.

`I386TimerInit(timer,divisor)` requires IF clear, an uninitialized timer and a
divisor from 2 through 65536. It programs the PIT, clears the counter, records
the divisor and marks the timer ready. Invalid inputs leave the record and PIT
unchanged. The caller installs the IRQ path and controls PIC masks separately.
Initializing multiple records does not arbitrate ownership of the single channel;
callers must not do that while another owner uses it.

`I386TimerStep(timer)` requires IF clear and a ready timer. Call it exactly once
for an accepted IRQ0, then acknowledge the PIC in the caller. It increments the
U64 count modulo 2^64 without allocation or yielding. It neither validates that
hardware delivered the call nor sends EOI itself.

`I386TimerTicks(timer)` takes a snapshot with maskable interrupts disabled and
restores the original IF state. Null or uninitialized records read as zero.
This prevents torn 64-bit reads on the single CPU; it is not an SMP/NMI protocol.
The count measures serviced interrupts, not guaranteed elapsed time: long masking
can lose/coalesce deliveries. Wall-clock conversion, sleep queues and public timer
integration remain separate work.

The exception-task fixture links task, exception and interrupt modules together,
installs its own GDT/IDT, and unmasks only IRQ0. Root and both workers receive
real PIT interrupts through native dispatch. Each catch waits for a hardware tick
after its cooperative yield, checking FS/GS, current task/CPU, IF state and
exception/local preservation. The counter starts near a 32-bit rollover; a
separate direct step checks U64 wrap. No runner function pointers are supplied.
The fixture masks IRQs and restores the runner's IDTR/GDTR before returning.

The combined fixture passes hardware delivery to root and both workers, all
48 catch-time waits, IF-enabled atomic snapshots across the 32-bit rollover,
rejected IF-enabled configuration/update, and direct U64 wrap. The linked IRQ
regression, instruction audits and both x86-64 rebuild/reboot generations pass.
