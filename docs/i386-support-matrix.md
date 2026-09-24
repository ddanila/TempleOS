# i386 QEMU support matrix

This matrix records observed behavior for the current native disk image. It is
QEMU verification, not certification of physical 386 hardware. The final M7
workstation and self-hosting gates in `PLAN.md` remain open.

## Tested emulator

| Item | Recorded value |
| --- | --- |
| Emulator | QEMU 10.2.1 (Debian `1:10.2.1+ds-1ubuntu3.2`), TCG |
| Machine | `pc`, resolving to `pc-i440fx-10.2` on this QEMU build |
| RAM | 8 MiB installed for the interactive tests below |
| Disk | Raw IDE hard-disk image, legacy BIOS boot, writable RedSea candidate |
| Display and input | Standard QEMU VGA, AT keyboard and PS/2 mouse |
| Network | Disabled with `-nic none` |
| Source image SHA-256 | `18962f93d172b9c34ef2d291272c4aed8786698e9a22ff58e20e5e60ad05c648` |

The command manifests in each result directory contain the exact QEMU argv.
The host has SeaBIOS `bios-256k.bin` at SHA-256
`e26615f9ad430328f49ca105e570b2dc4490a08a34ea73d27cae8b809a30ee06`
and `vgabios-stdvga.bin` at SHA-256
`c944f5fd404a6553a32e1e0527081d40e6040d3ce1740d39766bff01871e4fde`.
The test command uses QEMU's default firmware selection rather than explicit
firmware paths, so those installed-file hashes do not prove which ROM bytes
QEMU loaded.

## Verified profiles

| CPU | Evidence | Result |
| --- | --- | --- |
| `486,-fpu` | `build/i386-doldoc-session-no-fpu-help/result.json`: three writable boots, 107/56/15 guest commands; F1 help return, F5 execution, saved revision and independent RedSea audit | Pass at 8 MiB |
| `pentium3,-fpu` | `build/i386-doldoc-session-pentium3-no-fpu/result.json`: the same three-boot workflow and persisted-format audit | Pass at 8 MiB |
| `486,-fpu` | `build/i386-mouse-held-combined/result.json`: 204 mouse and document-editing commands with exact VGA checkpoints | Pass at 8 MiB |

Both writable runs used separate copies of the same source image, left that
image unchanged, and produced the same final candidate SHA-256:
`2ed9539fa5e61967ecd300eae91dc8c21ed74a50741633ccc7f722157a9c0bb4`.
The host audit found 18 reachable directories, 838 files, 14,371 owned sectors
and a bitmap matching the reachable extents. These results cover the tested
project workflow, not every public TempleOS service.

To repeat a profile after building the image:

```sh
python3 tools/test-i386-doldoc-session.py --cpu 486,-fpu
python3 tools/test-i386-doldoc-session.py --cpu pentium3,-fpu --out build/i386-doldoc-session-pentium3-no-fpu
```

The normal i386 build now audits the exact 325-byte 16-bit BIOS code and
104-byte 32-bit protected-mode stage, using NASM label boundaries and a 386
instruction allowlist. Its existing T32M classifier audits resident and loaded
module code separately. The boot result is recorded in
`build/i386-kernel/boot-instruction-audit.json` and `result.json`; mutation
checks reject injected BSWAP, CPUID and x87 instructions. Comprehensive audit
coverage of live native JIT output and any remaining executable paths is still
needed before claiming the 80386 instruction baseline. A diagnostic QEMU boot
now exports and audits twelve sampled native JIT functions across two compiler
probe phases (1,238 executable bytes and 622 instructions); the exact captures
are recorded in `build/i386-jit-live-boot/live-jit-audit.json`.
QEMU on this host does not offer a 386 CPU model; neither a no-FPU 486 run nor a
later-CPU run proves strict 386 compatibility. Complete 8 MiB resource and
latency acceptance, integrated graphics/speaker activity, the 16 MiB native
compiler/kernel rebuild, installation and second native rebuild generation
remain open. Physical hardware and dedicated SX/DX certification are deferred
under the current plan.
