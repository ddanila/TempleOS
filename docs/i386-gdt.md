# Native i386 GDT construction and loading

`Kernel/I386/Gdt.HH` and `Gdt.HC` build the baseline five-entry GDT and provide
GDTR load/read operations through HolyC inline assembly. `I386GdtInit` requires
forty writable bytes and live task/CPU records with sizes from 1 byte to 1 MiB.
Null or wrapping ranges and invalid sizes are rejected before table mutation.
The caller owns separate table and record storage and must initialize the records.

The entries are null, flat 4 GiB code (selector 8), flat 4 GiB data (selector 16),
a byte-granularity task data segment (FS selector 0x18), and a CPU data segment
(GS selector 0x20). Task/CPU descriptors use the existing `I386DataSegment`
implementation. Changing the current task still requires updating its descriptor
and reloading FS so that the hidden descriptor cache sees the new base/limit.

`I386GdtLoad(table,count)` accepts 3–8192 entries, requires IF clear, constructs
the six-byte limit/base operand and executes LGDT. Invalid bounds/counts or IF set
leave the GDTR unchanged. It does not validate table contents, reload segment
registers or perform a far control transfer. The caller must preserve the flat
code/data descriptors used by the cached CS/SS/DS/ES and arrange valid FS/GS
reloads. This is a protected-mode boot integration operation, not a transition
from real mode or a general address-space switch.

`I386GdtRead(descriptor)` writes six bytes using SGDT, rejecting null or wrapping
output ranges. The table, descriptors and referenced records must remain live
while selectors or their cached state can refer to them. NMI-safe descriptor
replacement, TSS/double-fault setup and privilege transitions are not provided.

The exception-task fixture links `TaskContext.HC` with its native runtime,
builds and loads its own GDT, reloads FS/GS through the linked entry, and runs
its worker lifecycle and catch-time switching checks with those descriptors.
It saves and restores the original GDTR and FS/GS selectors before returning.
The runner still owns the initial protected-mode entry; production task/CPU
records and complete boot sequencing remain unfinished.

The exception-task suite passes with this setup, including bounds/no-mutation,
flat descriptor encoding, guard bytes, IF-enabled load rejection, GDTR readback,
48 catch-time yields and restoration. General task and linked IRQ regressions,
instruction audits and both x86-64 rebuild/reboot generations also pass.

[Native task platform initialization](i386-task-platform.md) now owns the GDT,
scheduler binding and root stack/heap registration sequence used by the
exception-task fixture. It replaces that fixture's custom binding callback.
