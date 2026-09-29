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
| All kernel, compiler and retained runtime sources build in the guest | Six retained T32Ms in `retained-build-fixed/result.json`; six flat kernel/boot T32Ms and an independently booted installed disk in `selfhost-install-fixed/result.json`. The second generation repeats the build. `selfhost-install-gen3-tcg-nofpu-long/result.json` now passes the flat kernel and five boot helpers under `486,-fpu` TCG, and the installed disk cold-boots at 8 MiB. | Pass in 16 MiB QEMU/KVM; no-FPU flat-kernel build/install passes, while the complete no-FPU retained rebuild is still running. |
| Development session survives source errors and interruption | The complete workstation suite exercises source-linked error recovery and keyboard break handling; the [manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) includes an interrupted loop and subsequent compilation. | Automated cases pass; human source-edit/rebuild observation open. |
| Native installation and interrupted-install recovery | `selfhost-install-gen2-fixed/result.json` cold-boots the installed image. Both `install-recovery-committed/result.json` (KVM) and `install-recovery-tcg-nofpu/result.json` cover hard stops at LBA 128, 850 and after LBA 0; each source and all three resulting disks match the release image after recovery or publication. | Pass for tested QEMU hard stops on KVM and `486,-fpu` TCG. Physical power-loss durability is deferred. |
| Two independent guest-built generations | `generation-identity-fixed/result.json` verifies Generations 1 and 2. `generation-identity-gen2-gen3-tcg-nofpu/result.json` verifies Generation 3 built under no-FPU TCG: all twelve T32Ms, the 457,000-byte linked image and boot area are byte-identical to Generation 2; both RedSea volumes pass ownership/bitmap audits. | Pass through Generation 3 for audited artifacts; its full workstation suite also passes. |
| 386-targeted executable regions | `selfhost-install-gen2-fixed/instruction-audit/result.json` and `selfhost-install-gen3-tcg-nofpu-long/instruction-audit/result.json` check linked and retained modules plus BIOS/protected-mode boot ranges, including guest compiler template data. | Pass for audited regions on both images. QEMU here has no 386 CPU model; physical 386 certification is deferred. |
| 8 MiB PC workstation on no-FPU and later 32-bit CPUs | `selfhost-install-gen2-fixed/full-tcg-nofpu/result.json`, `full-pentium3-nofpu/result.json`, and `selfhost-install-gen3-tcg-nofpu-long/full-tcg-nofpu/result.json` each pass 506 native commands, 569 input lines, exact VGA and 20 document cycles. `full/result.json` passes under KVM. | Pass on the exact Generation 2 disk and the no-FPU-built Generation 3 disk. |
| Persistent DolDoc development and memory budget | `selfhost-install-gen2-fixed/doldoc-tcg-nofpu/result.json` and `selfhost-install-gen3-tcg-nofpu-long/doldoc-tcg-nofpu-final/result.json` each pass three writable boots with independent RedSea audit. `resource-profile/resource-result.json` measures 20 cycles, 3,616-byte temporary live growth and exact recovery in 8 MiB. | Pass on the exact Generation 2 disk and the no-FPU-built Generation 3 disk. |
| TempleOS programming model and public services | The full suites exercise HolyC compilation, DolDoc, cooperative task/break recovery, direct VGA/PS/2/PIT/speaker paths, RedSea, graphics, sound, help and source-linked diagnostics. `doc-compat-provenance-retry/result.json` records the exact Generation 2 image producing a 37-byte DolDoc file that original TempleOS reads and saves byte for byte. The [support matrix](i386-support-matrix.md) defines the tested surface. | Tested integrated surface and this original-reader compatibility case pass; the original document-attached compiler control and complete `DocEd` action set are not yet established. |
| Release artifact and human usability | `tools/package-i386-release.py` produces a verified local disk/evidence bundle. [Manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) and [observation form](i386-manual-observation-template.md) are ready. | Local package prepared; human observation and publication open. |

The 16 MiB `486,-fpu` TCG retained rebuild is running in
`build/i386-kernel/retained-build-gen3-tcg-nofpu/`. An earlier kernel
attempt with the default 2,400-second per-command limit reached 191 of 225
function outputs, then the host screen check timed out without a guest build
error. The separate 7,200-second run passed the full no-FPU flat-kernel build,
installation and cold boot. A command checkpoint alone is not a passing verdict.
The initial retained build reached its host command timeout during
`ConsoleRuntime`; after QEMU exited, the first three persisted T32Ms matched
their installed Generation 2 copies byte for byte. A `--resume` run is active
for the remaining three. The complete retained-build row still requires an
all-six disk audit.
The independent no-FPU flat-kernel build passes its eight-command native
build/install run and 8 MiB cold boot. Its Generation 3 disk has a different
whole-disk hash because filesystem metadata differs, while all twelve module
bytes, the flat image and boot area match Generation 2 exactly. The 386
instruction and RedSea audits pass. The full Generation 3 workstation suite
passes 506 commands, 569 lines, exact VGA and 20 bounded document cycles
with exact heap recovery. The three-boot writable Generation 3 session also
passes 107/56/15 commands and an independent RedSea audit. Its runner now
saves a verified post-creation snapshot for reopen retries and checks each
caret movement before revising the program; the source image stays unchanged.
