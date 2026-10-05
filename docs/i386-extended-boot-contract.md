# Extended native boot contract (integration pending)

The isolated prototype in `tools/i386-extended-stage.asm` streams a kernel
larger than the legacy flat-image limit. It does not yet boot TempleOS.
Legacy images retain their existing contract until extended integration passes.

## Disk and memory layout

| Item | Location | Contract |
| --- | --- | --- |
| BIOS first stage | LBA 0 | Existing bootstrap; signature published last during installation |
| Protected/real mode loader | LBA 1–8, physical `0x10000` | Exactly 4096 bytes; first stage loads eight sectors |
| Extended payload | LBA 9–2047, physical `0x100000` | 8 through 1,043,968 declared bytes; sector padding excluded from checksum |
| RedSea volume | LBA 2048 onward | Loader and boot-area installer must preserve it |
| BIOS read buffer | physical `0x6000` | One sector; copied with flat protected-mode addressing |
| Real-mode stack | top `0x9000` | Separate from buffer, metadata, loader and payload |
| Protected-mode stack | top `0x90000` | Existing kernel stack reservation `0x88000..0x90000` remains required |
| Legacy memory/disk handoffs | `0x5000`, `0x5020` | Existing layouts preserved |
| Extended image handoff | `0x5030` | Four U32 fields: magic, version, base, exact bytes |

Stage metadata offsets are relative to disk byte 512:
magic +16 (`0x42323345`, E32B), version +20 (1), payload length +24,
base +28 (`0x100000`), FNV-1a checksum +32. Hash every declared payload byte
with seed 2166136261, XOR byte then multiply by 16777619 modulo 2^32.
The payload starts with E9 and a signed 32-bit displacement; bytes 5–7 are
zero. Its target offset must be at least 8 and below the declared length.

## Required coordinated implementation

1. Link all six boot modules at `0x100000` in guest cross-build and
   `I386BuildBootImage`; make the selected format explicit rather than silently
   interpreting an old low-linked flat file as an extended payload. Update
   absolute-address checks in host module auditing along with link base.
2. Validate the new handoff before allocating any kernel heap. Add a second
   reserved range for the complete sector-rounded high-memory image to the
   existing stack reservation. Keep the A20 scratch reservation and reject an
   image exceeding reported memory. A heap starting at `0x110000` without this
   extra range would overwrite most extended kernels.
3. Native installation must recognize the source stage format, validate the
   new payload before writing, regenerate exact length and checksum in LBA 1,
   write/pad payload sectors only within LBA 9–2047, flush, and publish LBA 0
   last. Preserve every filesystem sector and legacy format behavior. Reading
   unchanged source-stage metadata after replacing payload would be incorrect.
4. Teach cross-build packaging and independent guest-image verification the
   same explicit disk layout, without trusting builder success alone. Audit
   all executable real-mode and protected-mode ranges for 386 instructions;
   preserve initial exception handling and add verified BIOS/KBC A20 fallback.
5. Build the oversized frame-walking kernel, boot it with 8 MiB/no FPU, rerun
   the trace test, then qualify two native rebuild/install/reboot generations
   with independent byte and filesystem comparisons. Repeat workstation,
   DolDoc, cleanup and resource gates on that exact source/image.

## Current evidence and remaining boundary coverage

`python3 tools/test-i386-extended-loader.py --out <fresh-directory>` builds an
independent payload and verifies its first/tail markers and all four image
handoff fields under QEMU TCG 486 without an FPU. Thirteen cases pass in
`build/extended-loader-handoff-entry/result.json`: valid, corrupt checksum,
insufficient memory, five invalid metadata cases, four independently rehashed
invalid entry cases, and a missing payload sector represented by zero-filled
media. This last case proves checksum rejection of missing data, not BIOS
read-error recovery. Snapshot disks and pinned sources remain unchanged.

Still required: maximum-capacity valid payload, non-sector-aligned payload and
padding semantics, BIOS read failure, complete high-image reservation checks,
source/target native installation safety, and integrated OS/release gates.
Physical hardware verification remains deferred.
