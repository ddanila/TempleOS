# i386 QEMU support matrix

This matrix records observed behavior for the last fully guest-built i386
disk image. The current U32 startup optimization is a development revision
and requires new all-module qualification; older image passes do not prove it. It is QEMU verification, not certification of physical 386
hardware. The second-generation rebuild matches all twelve modules, the
flat image and installed boot area byte for byte. Final M7 publication remains open. Human observation is optional exploratory
feedback under the 2026-10-03 acceptance revision in `PLAN.md`.

Functional pass entries below do not imply every resource target passes.
Current first/second-generation no-FPU startup measures 73.868/73.265 seconds,
exceeding the plan's 60-second target. The startup-budget checker reports that failure. Both generations now pass
automated audio waveform and off/reset emission checks.

## Tested emulator

| Item | Recorded value |
| --- | --- |
| Emulator | QEMU 10.2.1 (Debian `1:10.2.1+ds-1ubuntu3.2`), KVM and TCG |
| Machine | `pc`, resolving to `pc-i440fx-10.2` on this QEMU build |
| RAM | 8 MiB installed for the interactive tests below |
| Disk | Raw IDE hard-disk image, legacy BIOS boot, writable RedSea candidate |
| Display and input | Standard QEMU VGA, AT keyboard and PS/2 mouse |
| Network | Disabled with `-nic none` |
| Current first-generation image SHA-256 | `a7c111f8f139f4121283916ff80e1d173069753b173e1bb1e4c90ace191db96c` (`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/target.img`) |
| Current second-generation image SHA-256 | `158a4b809c40d9cff75940c1facf5a53bccf6ef78f9f19a3a585fbd8f150d2c6` (`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img`) |

The command manifests in each result directory contain the exact QEMU argv.
`build/i386-release-current/` contains the first current-source disk and its
verified QEMU evidence. `tools/package-i386-current.py` checks two-generation
identity, source hashes, 386 audits and current workstation and writable
session results before creating that local bundle. Its standalone verifier
checks the compressed image and 95 bundled files and independently rechecks
both audio waveforms and their off/reset emission observations. All six current-source
retained modules were rebuilt in the guest under 16 MiB `486,-fpu` TCG and
match the installed second-generation modules byte for byte. The installed
image also passes the complete no-FPU workstation and writable-session suites.

## Previously qualified source profiles

| CPU | Evidence | Result |
| --- | --- | --- |
| `486`, KVM | `build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-kvm-retry/result.json`: 513 commands, 576 lines, exact VGA and 20 document cycles with exact task-heap recovery | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-tcg-nofpu/result.json`: the same complete workstation suite | Pass at 8 MiB |
| `pentium3,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-pentium3-nofpu-stdio-cli-retry/result.json`: 513 commands, 576 lines, exact VGA and 20 document cycles; `provenance.json` binds the writable copy to the unchanged current image | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-tcg-nofpu-stdio-cli/result.json`: the complete 513-command workstation suite on the independently rebuilt second-generation disk; provenance binds its writable copy to the unchanged second disk | Pass at 8 MiB |
| `pentium3,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-pentium3-nofpu-stdio-cli/result.json`: the complete 513-command workstation suite on the second-generation disk, with unchanged-source writable-copy provenance | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doldoc-tcg-nofpu/result.json`: 107/56/15 commands over three writable boots, exact VGA, unchanged source disk and RedSea audit | Pass at 8 MiB |
| `486,-fpu`, TCG | `build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doldoc-tcg-nofpu-stdio/result.json`: the same 107/56/15-command persistent project workflow on the rebuilt second disk, exact VGA and independent RedSea audit | Pass at 8 MiB |
| `486`, KVM | `build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/boot/result.json`: independently booted second generation and two native commands | Pass at 8 MiB |
| 386 instruction audit | Both current generations' `instruction-audit/result.json`: linked and retained executable ranges, boot code and guest compiler template | Pass for audited regions |
| Generation identity | `build/i386-kernel/generation-identity-capacity-lexfix-kvm/result.json`: twelve modules, 482,384-byte flat image and boot area byte-identical; both RedSea bitmaps match reachable extents | Pass |
| Native/original DolDoc | `build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doc-compat-current/result.json` and `build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doc-compat-stdio/result.json`: original x64 TempleOS reads and saves each generation's native 37-byte document byte for byte | Pass for both generations |
| Native/original styled DolDoc | Both generations' `doc-style-compat-stdio/result.json`: original x64 TempleOS reads and saves each generation's persisted 78-byte color, background, invert and underline document byte for byte, edits it to 79 bytes, and the i386 guest reads and saves those original-authored bytes byte for byte | Pass in both directions for both generations |
| Interrupted install | First-generation `install-recovery-current-kvm/result.json` and second-generation `install-recovery-tcg-nofpu-stdio-retry/result.json`: cuts at LBAs 128 and 850 recover by retry; a cut after LBA 0 leaves the complete disk bootable | Pass under KVM and `486,-fpu` TCG |

The later-CPU run uses the runner's `--qmp-stdio --writable-copy` options
because this restricted host cannot bind a QMP Unix socket or create QEMU's
snapshot file in `/var/tmp`. A focused compiler group and keyboard check pass
through the same transport. The sound check samples PIT channel 2 across a
timer interval so a host scheduling pause between programming and one read
does not masquerade as a guest sound failure; it still checks the 440 Hz
divisor range, speaker-enable bits and preserved interrupt flag. The revised
focused sound group passes on both `486,-fpu` and `pentium3,-fpu` TCG.

The focused speaker-output test boots unchanged snapshots of both generations
under 8 MiB `486,-fpu` TCG. The WAV recordings contain 440 Hz then 880 Hz;
each settled 1.5-second `Snd`-off and `SndRst` interval emits zero new WAV bytes.
QEMU's WAV backend omits inactive-voice intervals, so file emission observations
provide the silence oracle rather than invented zero-valued PCM. Result paths
are `build/i386-speaker-output-gen{1,2}-emission/result.json`; the local bundle
includes the recordings, observations and exact commands.

## Startup optimization development image

The fresh source revision passes 46 validator and 40 loader cases, the heap
stress/corruption corpus and two x64 bootstrap rebuilds. Six flat modules now
build inside the guest, install and cold boot at 8 MiB; the retained modules
for this development image remain cross-built. Its installed 386 and RedSea
audits pass, and an unprofiled `486,-fpu` TCG keyboard session boots in
51.264 seconds. This is a development timing pass, not full self-hosting
qualification. The fresh cross image passes the full no-FPU workstation suite (513 commands,
20 exact heap-recovery cycles, 50.501-second startup, 0.314-second visible
update). The guest flat development image passes three writable boots
(107/56/15 commands), exact saved bytes and RedSea audit, with 0.271-second
interrupt recovery. Retained rebuilding continues. These development passes
do not replace the fully guest-built promotion profiles.

A current-source public function probe confirms `MAlloc` and `Dir`, but fails
for `Spawn`, `Exit`, `Yield`, `Sleep` and `Dbg`. See the
[coverage audit](i386-m7-coverage-audit.md) for the required task/terminal and
debugging behavior still to implement and verify.

## Earlier-source evidence

The earlier candidate in `build/i386-release-candidate/` bundles the
compressed Generation 2 disk, source-input hashes, command records and these
acceptance results; `tools/package-i386-release.py` verifies their linkage.
The final Generation 2 disk passes two guest-built boot-image hard-stop/retry
cases at LBA 128 and 850 with blank LBA 0, exact RedSea bitmap, byte-identical
retry and independent boot. A third hard stop after LBA 0 publication leaves
the complete reference disk byte-identical and bootable
(`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-committed/result.json`).
The same three cuts also pass under 16 MiB `486,-fpu` TCG for installation
and retry; the resulting installed disk independently boots at 8 MiB
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

### Earlier-source profiles

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
compatibility. The current 16 MiB native compiler/kernel build and
installation pass for two complete generations, and a local current-source
package is verified. Human observation and publication remain open.
Physical hardware and dedicated SX/DX certification are deferred under the
current plan.

For the current two-generation candidate, all six retained modules also pass
a separate guest rebuild on the installed Generation 2 disk under 16 MiB
`486,-fpu` TCG. Each persisted module matches the installed bytes, and the
current local release bundle verifies 76 files. This extends the no-FPU build
evidence; human QEMU usability observation remains deferred.
