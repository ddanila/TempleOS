# Linked native interrupt runtime

`Kernel/I386/Interrupt.HH` and `Interrupt.HC` bind the native entry modules to
kernel services and install their IDT. Link the runtime with `IrqEntry.HC` and
`ExceptionEntry.HC` using the ordinary module linker: the runtime imports all
33 entry addresses, and the entry modules import its two dispatcher functions.
There is no fixed-address callback slot or host-patched call in this linked path.

`I386InterruptInstall(table,count,fallback,services)` requires IF clear, a live
writable table of 48–256 gates, a raw fallback entry and both service callbacks.
It rejects repeat installation. Invalid inputs are rejected before table writes,
service publication or IDTR changes. All gates start with the fallback; vectors
0–16 receive the CPU-exception entries and vectors 32–47 receive the PIC IRQ
entries. Selectors are fixed at CS=8 and flat DS/ES=16 to match entry code.

The runtime copies the two service pointers, publishes them before loading the
IDTR, and leaves IF clear. The caller may discard the services record after a
successful installation, but the table, code modules, GDT entries and callbacks
must remain live. The caller must mask/configure the PIC and initialize callback
state before enabling IRQs. This interface does not initialize devices or provide
an atomic update under NMI; installation belongs to controlled boot setup.

`I386IrqDispatch` validates the frame pointer and IRQ range, then calls the copied
IRQ service. The service owns PIC spurious handling and EOI. `I386ExceptionDispatch`
checks the normalized exception vector and invokes the exception service. Both
callbacks must preserve IF clear and must not yield. The original hardware frame
is restored by the assembly entry after a returning service. Calling dispatch
before installation or with an invalid frame halts with maskable IRQs disabled;
this is a boot failure policy, not the final debugger interface. Non-null pointers
must be trusted readable frames; this is not arbitrary-memory validation.

The IRQ fixture links all three modules, installs a new IDT through this runtime,
and then uses real IRQs and recoverable faults. Its service callbacks forward to
test handlers for changing device scenarios. The old runner entry copies remain
only for the initial emergency table and independent task fixtures. The IRQ test
checks that the installed entry differs from that initial copy and records visits
to the native service callbacks.

Production boot integration, task/CPU initialization ordering, NMI/double-fault
policy, debugger recovery and native compiler execution remain unfinished.

The IRQ suite passes with this linked path, including invalid/IF-enabled/repeated
installation, preservation of rejected table/IDTR state, service-record lifetime
independence, hardware IRQs and three recoverable faults. Instruction audits,
the exception-task regression and both x86-64 rebuild/reboot generations pass.
