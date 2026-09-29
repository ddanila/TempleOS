# M7 self-hosting workstation acceptance

This is the current evidence map for [M7 in PLAN.md](../PLAN.md#following-big-goal-m7-self-hosting-32-bit-templeos-workstation).
The candidate disk is `build/i386-kernel/selfhost-install-gen2-fixed/target.img`
(SHA-256 `c3a1dae46d76ebb8b2062216cb3724856324a3be14f9104b70fc2a950df795b8`).
The package checks all 1,233 build-input file hashes against the checkout and
records committed source revision `78f66cfc72370cf7d508196950521bf8535b1f2e`.
It also reads all 814 delivered source files from the Generation 2 RedSea
image and checks each byte hash against that manifest.
The older cross-build manifest revision reflects a dirty worktree at build
time, so its revision alone is not the source identifier.
The local bundle is `build/i386-release-candidate/`; run its `verify.py` before
using it. `build/` is ignored by Git, so the linked result files are local
evidence rather than repository contents.

| M7 requirement | Current evidence | Status |
| --- | --- | --- |
| All kernel, compiler and retained runtime sources build in the guest | Six retained T32Ms in `retained-build-fixed/result.json`; six flat kernel/boot T32Ms and an independently booted installed disk in `selfhost-install-fixed/result.json`. The second generation repeats the build. | Pass in 16 MiB QEMU/KVM; complete `486,-fpu` TCG rebuild in progress. |
| Development session survives source errors and interruption | The complete workstation suite exercises source-linked error recovery and keyboard break handling; the [manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) includes an interrupted loop and subsequent compilation. | Automated cases pass; human source-edit/rebuild observation open. |
| Native installation and interrupted-install recovery | `selfhost-install-gen2-fixed/result.json` cold-boots the installed image. `selfhost-install-gen2-fixed/install-recovery-committed/result.json` covers hard stops at LBA 128, 850 and after LBA 0; the source and three resulting disks match the release image after recovery or publication. | Pass for tested QEMU hard stops. Physical power-loss durability is deferred. |
| Two independent guest-built generations | `generation-identity-fixed/result.json` verifies all twelve T32Ms, the 457,000-byte linked image and boot area are byte-identical; both RedSea volumes pass ownership/bitmap audits. | Pass; Generation 2 independently boots and runs HolyC. |
| 386-targeted executable regions | `selfhost-install-gen2-fixed/instruction-audit/result.json` checks linked and retained modules plus BIOS/protected-mode boot ranges, including guest compiler template data. | Pass for audited regions. QEMU here has no 386 CPU model; physical 386 certification is deferred. |
| 8 MiB PC workstation on no-FPU and later 32-bit CPUs | `selfhost-install-gen2-fixed/full-tcg-nofpu/result.json` and `full-pentium3-nofpu/result.json` each pass 506 native commands, 569 input lines, exact VGA and 20 document cycles. `full/result.json` passes under KVM. | Pass on the exact Generation 2 disk. |
| Persistent DolDoc development and memory budget | `selfhost-install-gen2-fixed/doldoc-tcg-nofpu/result.json` passes three writable boots with independent RedSea audit. `resource-profile/resource-result.json` measures 20 cycles, 3,616-byte temporary live growth and exact recovery in 8 MiB. | Pass on the exact Generation 2 disk. |
| TempleOS programming model and public services | The full suites exercise HolyC compilation, DolDoc, cooperative task/break recovery, direct VGA/PS/2/PIT/speaker paths, RedSea, graphics, sound, help and source-linked diagnostics. The [support matrix](i386-support-matrix.md) defines the tested surface. | Tested integrated surface passes; the original document-attached compiler control and complete `DocEd` action set are not yet established. |
| Release artifact and human usability | `tools/package-i386-release.py` produces a verified local disk/evidence bundle. [Manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) and [observation form](i386-manual-observation-template.md) are ready. | Local package prepared; human observation and publication open. |

The 16 MiB `486,-fpu` TCG retained rebuild and flat-kernel installation are
running in `build/i386-kernel/retained-build-gen3-tcg-nofpu/` and
`build/i386-kernel/selfhost-install-gen3-tcg-nofpu/`. A command checkpoint is
progress information, not a passing verdict. Record their final result and
compare their artifacts before promoting this row.
