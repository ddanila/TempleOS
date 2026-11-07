# 386 DVD first-stage loader

`tools/i386-dvd-stage.asm` replaces the original DVD stage1's x86-64 CPUID gate
with a 386 instruction path. It relocates itself to 0x96600, reads one 2,048-byte
DVD sector per BIOS extended-read call, removes zero to three leading 512-byte
blocks, and transfers to 07C0:0000. EAX carries `(shift<<16)|BOOT_SRC_DVD` and
EBX the initial DVD LBA, matching the original BootDVD handoff.

The fixed patch fields are a 32-bit LBA at offset 20, a 16-bit DVD block count
at 24 and a 16-bit leading-block count at 26. A four-byte I3CD marker is at 16.
Counts zero or above 285 and shifts above three are rejected before reading.
285 sectors fit below the relocated loader. Copying uses segment-bounded
512-byte chunks and only bytes actually read. BIOS read failure prints R to
port E9 and halts; invalid parameters print V and halt.

`tools/build-i386-dvd-loader.py` reproducibly emits the checked-in HolyC byte
array `Kernel/I386/DVDStageBytes.HC`, with the original BDVD patch labels as
native preprocessor definitions. `--check` verifies exact assembly regeneration.
No host assembler is needed to compile this byte array in the native system.

`build/i386-dvd-stage-v1/result.json` passes twelve real BIOS boot cases under
QEMU TCG 486 without an FPU. Each of the four alignments runs a 4,097-byte
payload and the maximum payload for that alignment. Synthetic stage2 checks
EAX, EBX, CS and every padding byte, including beyond 64 KiB. Zero/oversized
counts, invalid shift and out-of-range BIOS reads produce the expected rejection
markers. All execution inputs remain unchanged. The assembly uses 386-era
instructions; physical 386 execution is not qualified.

These tests qualify the loader primitive, not a complete native OS boot from
CD. Integration with original RedSeaISO, its generated loader patch fields,
a real native stage2, optical filesystem startup and full C1–C5 workflows
require separate evidence.

```
python3 tools/build-i386-dvd-loader.py --check
python3 tools/test-i386-dvd-stage.py --out build/dvd-stage
```
