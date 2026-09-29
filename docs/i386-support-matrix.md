# i386 QEMU support matrix

This matrix records observed behavior for the fully guest-built i386 disk
image. It is QEMU verification, not certification of physical 386 hardware.
The second-generation rebuild is byte-identical in its installed boot code
and twelve guest-built modules. Final M7 publication and human observation
in `PLAN.md` remain open.

## Tested emulator

| Item | Recorded value |
| --- | --- |
| Emulator | QEMU 10.2.1 (Debian `1:10.2.1+ds-1ubuntu3.2`), KVM and TCG |
| Machine | `pc`, resolving to `pc-i440fx-10.2` on this QEMU build |
| RAM | 8 MiB installed for the interactive tests below |
| Disk | Raw IDE hard-disk image, legacy BIOS boot, writable RedSea candidate |
| Display and input | Standard QEMU VGA, AT keyboard and PS/2 mouse |
| Network | Disabled with `-nic none` |
| Fully guest-built image SHA-256 | `593e914a4769a53bd987fa5a3978e0e14018bbf4b2825820d37a1d4f958bc023` (`build/i386-kernel/selfhost-install-fixed/target.img`) |
| Generation 2 image SHA-256 | `c3a1dae46d76ebb8b2062216cb3724856324a3be14f9104b70fc2a950df795b8` (`build/i386-kernel/selfhost-install-gen2-fixed/target.img`) |

The command manifests in each result directory contain the exact QEMU argv.
The locally prepared candidate in `build/i386-release-candidate/` bundles the
compressed Generation 2 disk, source-input hashes, command records and these
acceptance results; `tools/package-i386-release.py` verifies their linkage.
The final Generation 2 disk passes two guest-built boot-image hard-stop/retry
cases at LBA 128 and 850 with blank LBA 0, exact RedSea bitmap, byte-identical
retry and independent boot. A third hard stop after LBA 0 publication leaves
the complete reference disk byte-identical and bootable
(`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-committed/result.json`).
The same three cuts also pass under 16 MiB `486,-fpu` TCG for installation
and retry; the final published disk independently boots at 8 MiB
(`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-tcg-nofpu/result.json`).
The exact Generation 2 image also writes a 37-byte DolDoc compatibility file
under 8 MiB 486 TCG. Original TempleOS under x64 TCG reads and saves it
byte-identically; the source image remains unchanged
(`build/i386-kernel/selfhost-install-gen2-fixed/doc-compat-provenance-retry/result.json`).
The no-FPU-built Generation 3 disk also passes the complete 8 MiB
`486,-fpu` TCG workstation suite: 506 commands, 569 input lines, exact VGA
and 20 document-development cycles with exact task heap recovery
(`build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/full-tcg-nofpu/result.json`).
The same Generation 3 image passes a writable three-boot DolDoc project under
`486,-fpu` TCG: 107/56/15 commands, exact VGA and independent RedSea audit,
with the source disk unchanged
(`build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/doldoc-tcg-nofpu-final/result.json`).
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
| `486`, KVM | `build/i386-kernel/selfhost-install-fixed/full/result.json`: 506 native commands, 569 input lines, exact VGA, document resource cycles | Pass at 8 MiB |
| `486`, KVM | `build/i386-kernel/selfhost-install-gen2-fixed/result.json`: independent Generation 2 boot, `6*7` = 42, `DocAllocationCheck` = 12 | Pass at 8 MiB |
| `486`, KVM | `build/i386-kernel/selfhost-install-gen2-fixed/full/result.json`: Generation 2 full 506-command workstation suite, exact VGA and 20 document resource cycles | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-fixed/full-tcg-nofpu/result.json`: same complete 506-command workstation suite, exact VGA and heap recovery | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-gen2-fixed/full-tcg-nofpu/result.json`: Generation 2 complete 506-command suite, exact VGA and heap recovery; 73.68 s startup, 0.265 s long-document key-to-VGA update | Pass at 8 MiB |
| `pentium3,-fpu`, TCG | `build/i386-kernel/selfhost-install-gen2-fixed/full-pentium3-nofpu/result.json`: Generation 2 complete 506-command suite, exact VGA and heap recovery; 73.38 s startup, 0.382 s long-document key-to-VGA update | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/sf-doldoc/result.json`: three writable boots on the fully guest-built image, 107/56/15 commands, saved revision and independent RedSea audit | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-gen2-fixed/doldoc-tcg-nofpu/result.json`: three writable boots on the Generation 2 image, 107/56/15 commands, saved revision and independent RedSea audit | Pass at 8 MiB |
| `486,-fpu`, KVM | `build/i386-kernel/resource-profile-third/resource-result.json`: 7,143,424-byte heap arena and 20 document cycles with exact live-heap recovery | Pass at 8 MiB |
| `486,-fpu`, KVM | `build/i386-kernel/selfhost-install-gen2-fixed/resource-profile/resource-result.json`: final-image 7,143,424-byte heap arena and 20 document cycles with 3,616-byte peak live growth and exact recovery | Pass at 8 MiB |
| `486,-fpu` | `build/i386-doldoc-session-no-fpu-help/result.json`: three writable boots, 107/56/15 guest commands; F1 help return, F5 execution, saved revision and independent RedSea audit | Pass at 8 MiB |
| `pentium3,-fpu` | `build/i386-doldoc-session-pentium3-no-fpu/result.json`: the same three-boot workflow and persisted-format audit | Pass at 8 MiB |
| `486,-fpu` | `build/i386-mouse-held-combined/result.json`: 204 mouse and document-editing commands with exact VGA checkpoints | Pass at 8 MiB |

The two earlier writable runs used separate copies of the same source image, left that
image unchanged, and produced the same final candidate SHA-256:
`2ed9539fa5e61967ecd300eae91dc8c21ed74a50741633ccc7f722157a9c0bb4`.
The host audit found 18 reachable directories, 838 files, 14,371 owned sectors
and a bitmap matching the reachable extents. These results cover the tested
project workflow, not every public TempleOS service.

To repeat a profile after building the image:

```sh
python3 tools/test-i386-doldoc-session.py build/i386-kernel/selfhost-install-fixed/target.img --cpu 486,-fpu --out build/sf-doldoc
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
The installed images pass the executable-region audits in
`build/i386-kernel/selfhost-install-fixed/instruction-audit/result.json` and
`build/i386-kernel/selfhost-install-gen2-fixed/instruction-audit/result.json`,
including the guest compiler's division-template data. The two-generation
audit in `build/i386-kernel/generation-identity-fixed/result.json` finds all
twelve T32Ms, the 457,000-byte flat image and the installed boot area
byte-identical; the whole disk hashes differ because the native builds leave
different files on RedSea. QEMU on this host does not offer a 386 CPU model;
neither a no-FPU 486 run nor the static allowlist proves strict physical 386
compatibility. The 16 MiB native compiler/kernel build and installation now
pass for two complete generations. Final release packaging and human
observation remain open. Physical hardware and dedicated SX/DX certification
are deferred under the current plan.
