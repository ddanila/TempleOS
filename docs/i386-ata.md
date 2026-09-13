# Native ATA PIO reads

`Kernel/I386/Ata.HH` and `Ata.HC` implement boot-owned compatibility-port ATA
IDENTIFY and single-sector LBA28 or CHS reads. Channel 0 uses 1F0/3F6 and channel 1 uses
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
wait for DRQ and transfer 256 words. A stack
buffer holds the data until completion status succeeds; failed reads leave the
caller buffer unchanged. Identify/read use about 512 bytes of temporary stack
storage in addition to normal frames.

Each wait allows 1–100000 polls. Busy status defers interpretation of other bits;
zero/floating status, device error/fault, or exhausted polling fails the operation.
Four alternate-status reads provide the conventional selection/command settling
pause. Port 80 reads separate busy polls. These are iteration limits, not a
calibrated timeout; physical vintage timings remain unverified. A failure can
leave channel state requiring recovery. There is no soft-reset/retry service yet.

The command/PIO sequence and legacy control-register policy were cross-checked
against [SeaBIOS ATA code](https://github.com/coreboot/seabios/blob/master/src/hw/ata.c).
The current-translation field selection was checked against
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
Generated code passes the existing instruction audit.

The bootstrap still reads its stage through BIOS CHS. PIO writes, multi-sector requests, channel locking across tasks, block-device and
RedSea integration, recovery/reset and physical 386/IDE testing remain pending.
This is not a filesystem or a complete production disk driver.
