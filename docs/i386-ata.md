# Native ATA PIO transfers

`Kernel/I386/Ata.HH` and `Ata.HC` implement boot-owned compatibility-port ATA
IDENTIFY, single-sector LBA28 or CHS reads/writes, and explicit cache flush. Channel 0 uses 1F0/3F6
and channel 1 uses
170/376; drive 0/1 selects master/slave. Calls require IF clear, exclusive ownership
of the channel and a quiescent device. They leave device interrupts disabled
through the control register. PCI discovery, DMA and an IRQ handler are not used.

Identify validates channel/drive/poll arguments, selects the device, issues EC,
and reads 256 words through InU16. For LBA devices it records capacity capped at
2^28 sectors. Otherwise capacity comes from CHS geometry: words 1/3/6, or current
translation words 54/55/56 when word 53 bit 0 declares them valid. Geometry must
have 1–65535 cylinders, 1–16 heads and 1–255 sectors per track. Invalid current
translation is not replaced with possibly different default geometry. An LBA
device can still work with unavailable geometry, recorded as zero fields; a
CHS-only device cannot. Reported logical sectors other than 512 bytes and ATAPI
are rejected. The output record is written only on success.

The driver uses the device's existing translation and does not issue INITIALIZE
DEVICE PARAMETERS. Firmware must have initialized drives that require it.
ATA CHS geometry is distinct from BIOS INT 13h geometry; the BIOS cylinder/sector
limits must not be substituted for native ATA register limits.

Read accepts one in-range LBA and a writable 512-byte destination outside the
disk profile. The initialized profile and all buffers must remain live and valid.
It uses LBA28 when the profile reports LBA support. Otherwise it converts the
zero-based block number to a one-based sector, head and cylinder using the
identified geometry, checks that geometry's capacity, and clears the device
register's LBA bit. Both paths program a count of one, issue READ SECTORS (20),
wait for DRQ and transfer 256 words. A stack buffer holds the data until completion status succeeds; failed reads leave the
caller buffer unchanged. Identify/read/write use about 512 bytes of temporary stack
storage in addition to normal frames.

`I386AtaWrite` accepts a readable 512-byte source outside the disk profile and
uses the same address validation as read. It stages the source before issuing
WRITE SECTORS (30), waits for DRQ, transfers 256 words through OutU16 and waits
for successful command completion. It never modifies the caller's source.
A failed write may already have changed some or all of the sector: there is no
rollback or atomic-sector guarantee. Success reports command completion only;
call `I386AtaFlush` separately when write ordering/durability requires it.

`I386AtaFlush` issues FLUSH CACHE (E7) only when IDENTIFY word 83 has valid
capability bits and advertises bit 12. The profile's `flush` flag reports that
capability; zero means unsupported or unknown, not that writes are already durable.
Unsupported profiles and invalid arguments return FALSE before I/O. Supported
calls select the device, wait for readiness with no pending data, issue E7, then
wait for non-busy/ready completion with DRQ clear and no error/fault. The same
exclusive boot ownership and bounded polling contract applies. Flush neither
changes cache policy nor runs implicitly after writes. Success is the device's
reported flush completion; a failure leaves durability uncertain. Legacy disks
without this capability still need a separately verified cache policy.

Each wait allows 1–100000 polls. Busy status defers interpretation of other bits;
zero/floating status, device error/fault, or exhausted polling fails the operation.
Four alternate-status reads provide the conventional selection/command settling
pause. Port 80 reads separate busy polls. These are iteration limits, not a
calibrated timeout; physical vintage timings remain unverified. A failure can
leave channel state requiring recovery. There is no soft-reset/retry service yet.

The command/PIO sequence and legacy control-register policy were cross-checked
against [SeaBIOS ATA code](https://github.com/coreboot/seabios/blob/master/src/hw/ata.c).
The current-translation and flush-capability field selection was checked against
[Linux ATA definitions](https://github.com/torvalds/linux/blob/master/include/linux/ata.h).

`python3 tools/test-i386.py --ata` identifies a 16 MiB IDE disk in the native
QEMU 486/8 MiB runner. The host fixture seeds sectors 512–32767 with patterns
that depend on the block number, leaving the bootstrap intact. Native code checks the boot signature, repeated
pattern reads, the last sector, guard bytes, invalid arguments and unchanged
outputs. Overstating the profile capacity deliberately reaches the device's
out-of-range error; a subsequent valid read succeeds. Absent secondary/master and
primary/slave probes leave their profile unchanged, and master reads resume.
Synthetic IDENTIFY records exercise CHS-only capacity, current/default geometry,
invalid geometry, LBA capacity clamping, ATAPI and sector-size rejection. Tests
clear LBA support in the QEMU profile to exercise the normal CHS read branch,
checking the boot sector, both sides of head/cylinder boundaries and the final
CHS-addressable sector against the host patterns. Malformed geometry and CHS
range errors leave output unchanged. This forces CHS commands on an LBA-capable
emulated disk; it does not prove detection or timing on a CHS-only physical disk.
Writes cover two LBA operations (including the final disk sector), two forced
CHS operations, overwriting a previously written sector, and LBA readback of CHS
writes. Source and destination guards are checked along with source preservation.
Invalid calls and a real out-of-range write fail before subsequent valid writes.
After QEMU exits, the host compares all 16 MiB against the original image with
exactly the three expected sector replacements; bootstrap and neighboring sectors
must remain unchanged. Capability fixtures cover missing, invalid, and supported
flush bits; unsupported/invalid flush calls are rejected. Four write/flush/read
sequences and a final repeated flush pass. QEMU's `ide_bus_exec_cmd` trace is
checked for that exact command suffix, independently confirming E7 commands.
`ata-commands.log` and `write-check.json` record the evidence. This proves emulated
command execution and backing-image contents, not physical-media power-loss
durability or fault-injected flush recovery.
Generated code passes the existing instruction audit.

The bootstrap still reads its stage through BIOS CHS. Multi-sector requests,
legacy cache policy, routing transfers through task-owned channel gates, public
block-device integration, recovery/reset and physical 386/IDE testing remain pending.
This is not a filesystem or a complete production disk driver.

## Cooperative channel ownership

`AtaChannel.HH/HC` provides a FIFO ownership gate for each compatibility channel.
The caller must keep one canonical, initially zeroed gate per physical channel,
shared by both drives, and keep it and its scheduler alive until it can be closed.
An idle channel can be acquired by root or a worker. A contending worker blocks;
root fails immediately so it remains available to run the scheduler. Recursive
acquisition and release by another task fail. Multiple channels can be held, but
callers must impose a consistent acquisition order to avoid deadlock.

Queue changes and direct ownership handoff run with interrupts masked. Each
waiter lives on its blocked task's stack; spurious wakeups recheck the grant and
block again. The gate restores the caller's original IF state. An `io_locks`
count pins the owning task against finish/reap, including the interval between
handoff and the recipient's next execution. A held or queued gate cannot close.
The contract is task-context use with no cancellation or exception unwinding
through a pending acquisition; acquisition does not allocate or access hardware.

This is an ownership prerequisite, not a task-aware ATA driver. Existing ATA,
RedSea and retained file services still use their quiescent IF-clear contract.
The next adapter must bind both drive profiles to their canonical gate, retain
ownership through selection, command, data and completion, and yield only at
explicit safe polling points. On timeout or device error it must establish
quiescence/reset or poison the channel before admitting another request. Merely
releasing the software gate is not evidence that hardware is ready.

`python3 tools/test-i386.py --tasks` includes three real workers contending behind
root, FIFO handoff across yields, spurious wake/reblock, IF-clear and IF-set
callers, held-task finish/reap rejection, independent channel counts, overflow,
close/reinitialization and complete stack reclamation. It performs no disk I/O;
transfer latency, IRQ service during disk access and hardware recovery remain
separate acceptance tests.

Validation also passes the two-generation x86-64 compiler/kernel rebuild, native
`--input`, `--messages` and `--except-tasks` regressions, and
`python3 tools/build-i386-kernel.py --test`. The standalone native kernel is
389,552 bytes; with its 2,160-byte stage overhead it leaves 1,504 bytes in the
fixed 393,216-byte reservation. The gate itself is exercised in the task test,
not linked into the standalone disk path. These are QEMU development results,
not strict 386 or physical-machine validation.
