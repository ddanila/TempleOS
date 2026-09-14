# Native i386 interrupt descriptor tables

`Kernel/I386/Idt.HH` and `Idt.HC` provide descriptor construction and IDTR
load/read operations for the flat ring-0 kernel. Tables contain 1–256 eight-byte
32-bit interrupt gates. The caller supplies live writable storage; these routines
do not allocate memory or validate whether addresses are mapped.

`I386IdtInit(table,count,fallback,selector)` fills every gate with a non-null
fallback entry. `I386IdtSet(table,count,vector,handler,selector)` replaces one
gate. Both validate the table extent against the 32-bit address space, count,
non-null handler, and a nonzero GDT selector with RPL 0. Set also validates the
full-width vector. Invalid arguments leave the table unchanged. The caller must
ensure that the selector actually names a present executable segment and that
all handlers satisfy the interrupt entry ABI.

Each gate encodes the low/high handler address words, selector, a zero reserved
byte and attributes 0x8E (present, DPL 0, 32-bit interrupt gate). The API does not
install trap gates, task gates, privilege transitions or a double-fault stack.
Building an inactive table is permitted while interrupts run. Editing an active
table requires interrupt masking and exclusive ownership; byte stores are not
an atomic gate replacement, and NMI-safe updates are not provided.

`I386IdtLoad(table,count)` requires IF clear and a valid table extent. It forms
the six-byte limit/base descriptor on the stack and executes LIDT through the
native HolyC assembler. The limit is count*8-1. It preserves the interrupt-enable
state and returns false without loading on invalid arguments or IF set. The
caller must construct all gates first and keep the table, segment descriptors,
entry modules and dispatchers alive while the IDTR can reference them. Loading
an IDT does not initialize the PIC or make an arbitrary handler safe to call.

`I386IdtRead(descriptor)` writes the current six-byte limit/base descriptor using
SIDT. It requires six writable bytes and rejects null/wrapping ranges. It is
useful for boot handoff inspection and checking which table is installed.

The native IRQ fixture builds a separate 256-entry table, installs the generated
IRQ and CPU-exception entry addresses, loads it, and reads the actual IDTR back.
The existing hardware IRQ and recoverable-fault tests then execute through that
table. The runner's initial emergency IDT still exists before native code starts;
production boot handoff, NMI/double-fault policy and debugger integration remain
unfinished.

The IRQ fixture passes gate-byte and guard checks, invalid/bounds rejection,
IF-enabled load rejection, IDTR readback, hardware IRQ delivery and three
recoverable faults. Native instruction audits, the exception-task regression and
both x86-64 compiler/kernel rebuild/reboot generations also pass.

[Native interrupt installation](i386-interrupt-runtime.md) now binds the entry
modules and dispatcher services through the native linker and uses these IDT
operations. The IRQ fixture's final hardware/fault phase runs through that path.
