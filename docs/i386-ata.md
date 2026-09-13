# Native ATA PIO reads

`Kernel/I386/Ata.HH` and `Ata.HC` implement boot-owned compatibility-port ATA
IDENTIFY and single-sector LBA28 reads. Channel 0 uses 1F0/3F6 and channel 1 uses
170/376; drive 0/1 selects master/slave. Calls require IF clear, exclusive ownership
of the channel and a quiescent device. They leave device interrupts disabled
through the control register. PCI discovery, DMA and an IRQ handler are not used.

Identify validates channel/drive/poll arguments, selects the device, issues EC,
and reads 256 words through InU16. It accepts ATA devices reporting LBA support,
records their LBA28 capacity (capped at 2^28 sectors), and rejects a reported
logical sector size other than 512 bytes. Its output record is written only on
success. This path does not support ATAPI or CHS-only drives.

Read accepts one in-range LBA and a writable 512-byte destination outside the
disk profile. The initialized profile and all buffers must remain live and valid.
It selects the drive/LBA high nibble, programs a count of one and the low LBA
bytes, issues READ SECTORS (20), waits for DRQ and transfers 256 words. A stack
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

`python3 tools/test-i386.py --ata` identifies a 16 MiB IDE disk in the native
QEMU 486/8 MiB runner. The host fixture places distinct patterns at LBAs 2048,
2049 and 32767 before boot. Native code checks the boot signature, repeated
pattern reads, the last sector, guard bytes, invalid arguments and unchanged
outputs. Overstating the profile capacity deliberately reaches the device's
out-of-range error; a subsequent valid read succeeds. Absent secondary/master and
primary/slave probes leave their profile unchanged, and master reads resume.
Generated code passes the existing instruction audit.

The bootstrap still reads its stage through BIOS CHS. Native CHS-only disk access,
PIO writes, multi-sector requests, channel locking across tasks, block-device and
RedSea integration, recovery/reset and physical 386/IDE testing remain pending.
This is not a filesystem or a complete production disk driver.
