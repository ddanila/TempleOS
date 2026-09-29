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
| All kernel, compiler and retained runtime sources build in the guest | Six retained T32Ms in `retained-build-fixed/result.json`; six flat kernel/boot T32Ms and an independently booted installed disk in `selfhost-install-fixed/result.json`. The second generation repeats the build. `selfhost-install-gen3-tcg-nofpu-long/result.json` passes the flat kernel and five boot helpers under `486,-fpu` TCG, and the installed disk cold-boots at 8 MiB. Focused no-FPU `ConsoleRuntime` and `CompilerProbe` rebuilds match their installed modules byte for byte. | Pass in 16 MiB QEMU/KVM; no-FPU flat-kernel build/install and two focused retained rebuilds pass, while the complete no-FPU retained rebuild is still running. |
| Development session survives source errors and interruption | The complete workstation suite exercises source-linked error recovery and keyboard break handling; the [manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) includes an interrupted loop and subsequent compilation. | Automated cases pass; human source-edit/rebuild observation open. |
| Native installation and interrupted-install recovery | `selfhost-install-gen2-fixed/result.json` cold-boots the installed image. Both `install-recovery-committed/result.json` (KVM) and `install-recovery-tcg-nofpu/result.json` cover hard stops at LBA 128, 850 and after LBA 0; each source and all three resulting disks match the release image after recovery or publication. | Pass for tested QEMU hard stops on KVM and `486,-fpu` TCG. Physical power-loss durability is deferred. |
| Two independent guest-built generations | `generation-identity-fixed/result.json` verifies Generations 1 and 2. `generation-identity-gen2-gen3-tcg-nofpu/result.json` verifies Generation 3 built under no-FPU TCG: all twelve T32Ms, the 457,000-byte linked image and boot area are byte-identical to Generation 2; both RedSea volumes pass ownership/bitmap audits. | Pass through Generation 3 for audited artifacts; its full workstation suite also passes. |
| 386-targeted executable regions | `selfhost-install-gen2-fixed/instruction-audit/result.json` and `selfhost-install-gen3-tcg-nofpu-long/instruction-audit/result.json` check linked and retained modules plus BIOS/protected-mode boot ranges, including guest compiler template data. | Pass for audited regions on both images. QEMU here has no 386 CPU model; physical 386 certification is deferred. |
| 8 MiB PC workstation on no-FPU and later 32-bit CPUs | `selfhost-install-gen2-fixed/full-tcg-nofpu/result.json`, `full-pentium3-nofpu/result.json`, and `selfhost-install-gen3-tcg-nofpu-long/full-tcg-nofpu/result.json` each pass 506 native commands, 569 input lines, exact VGA and 20 document cycles. `full/result.json` passes under KVM. | Pass on the exact Generation 2 disk and the no-FPU-built Generation 3 disk. |
| Persistent DolDoc development and memory budget | `selfhost-install-gen2-fixed/doldoc-tcg-nofpu/result.json` and `selfhost-install-gen3-tcg-nofpu-long/doldoc-tcg-nofpu-final/result.json` each pass three writable boots with independent RedSea audit. `resource-profile/resource-result.json` measures 20 cycles, 3,616-byte temporary live growth and exact recovery in 8 MiB. | Pass on the exact Generation 2 disk and the no-FPU-built Generation 3 disk. |
| TempleOS programming model and public services | The full suites exercise HolyC compilation, DolDoc, cooperative task/break recovery, direct VGA/PS/2/PIT/speaker paths, RedSea, graphics, sound, help and source-linked diagnostics. `doc-compat-provenance-retry/result.json` records the exact Generation 2 image producing a 37-byte DolDoc file that original TempleOS reads and saves byte for byte. A focused `ExeDoc` probe executes a canonical document containing a foreground record and returns 42. The [support matrix](i386-support-matrix.md) defines the tested surface. | Tested integrated surface, original-reader compatibility and formatted-document execution pass; the original document-attached compiler control and complete `DocEd` action set are not yet established. |
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
The separate 16 MiB no-FPU TCG console build now passes and matches the
installed module byte for byte after an independent RedSea read
(`retained-console-gen3-tcg-nofpu-long/result.json`). The package requires and
bundles this focused evidence. It does not close the all-six retained source
build gate; the integrated resume still needs its final audit.
Human manual QEMU observation is deferred at the user's request; the automated
QEMU gates continue.
The expanded 169-command document-editing group, including the formatted
`ExeDoc` case, passes under 8 MiB QEMU/486 KVM with exact VGA checkpoints
(`document-editing-formatted-exedoc-kvm/result.json`).
The local release package requires and includes that exact-image result and
its QEMU command.
The focused formatted `ExeDoc` sequence also passes seven commands on the
no-FPU-built Generation 3 disk under 8 MiB `486,-fpu` TCG with exact VGA
(`exedoc-format-record-gen3-tcg-nofpu/result.json`).
The local release package requires and includes this no-FPU result and QEMU
command as well.
Original x64 TempleOS executes a `DOCT_INS_BIN_SIZE` document record and
returns 3 (`tests/guest/i386-exedoc-bin-size/Once.HC`). The corresponding
i386 standalone test currently fails because `ExeDoc` returns 0 after its
serializer rejects that record (`tools/test-i386-exedoc-bin-size.py`). This
was a concrete open programming-model gate outside the passing release suite.
The focused `CompilerProbe` source rebuild also passes under 16 MiB
`486,-fpu` TCG and matches the installed 1,209,705-byte module exactly
(`retained-compiler-probe-gen3-tcg-nofpu-long/result.json`). The package
requires and bundles that focused result; the six-module no-FPU audit remains
open.

A fresh cross-built kernel now compiles directly from the locked `CDoc`,
without serializing the document first. The same embedded-binary-size test
passes with exact VGA under 8 MiB QEMU/486 KVM
(`exedoc-bin-size-direct-kvm-root/result.json`) and `486,-fpu` TCG
(`exedoc-bin-size-direct-tcg-nofpu/result.json`). The complete KVM suite
passes 513 commands, 576 submitted lines, exact VGA and 20 document cycles
under both KVM (`direct-doc-full-kvm/result.json`) and `486,-fpu` TCG
(`direct-doc-full-tcg-nofpu/result.json`). This
source change is not yet installed in the release candidate.
Focused include/resume and embedded-binary insertion tests pass under KVM and
`486,-fpu` TCG (`exedoc-include-direct-*/result.json` and
`exedoc-binary-direct-*/result.json`). Quoted formatting, source diagnostics
and unwind behavior still need focused verification. Human manual observation
remains deferred by the user.
The first direct-document writable-session run found the document lexer
resetting a multiline error's line number to 1. After correcting newline
tracking, the new `486,-fpu` run passed the previously failing editor check
and logged diagnostic line 2. That run then found a document lock suppressing
keyboard breaks during `ExeDoc`; break delivery is now permitted while the
document remains locked. The fresh three-boot `486,-fpu` session passes
107/56/15 commands, exact VGA and an independent RedSea audit
(`direct-doc-breakfix-doldoc-tcg-nofpu/result.json`). The latest full
workstation regressions now pass on both KVM and `486,-fpu` TCG: 513 commands,
576 lines, exact VGA and 20 document cycles with exact heap recovery
(`direct-doc-breakfix-full-kvm-fixed-help/result.json` and
`direct-doc-breakfix-full-tcg-nofpu/result.json`). The exact-source
six-module guest rebuild and installation remain pending.
An original x64 fixture now identifies another open programming-model case:
quoted foreground formatting yields `A$FG,4$B` (length 8), while the current
i386 `ExeDoc` yields `AB` (length 2). The standalone red test is
`tools/test-i386-exedoc-quote.py`; it is not a passing release gate.
The direct-document source now passes a KVM guest rebuild and installed-disk
cold boot for all six retained modules
(`retained-build-direct-doc-breakfix-kvm/result.json`,
`retained-install-direct-doc-breakfix-kvm/result.json`). Its flat-kernel
guest build/install followed; the new release image is not yet accepted.
The first full guest-built generation now passes native flat-kernel and boot-
helper construction, installation and independent 8 MiB KVM cold boot
(`selfhost-install-direct-doc-breakfix-kvm/result.json`). The second
generation then ran from that installed disk; no-FPU workstation checks on
the new target remained open at that point.
The second generation now passes from the first installed disk. All twelve
guest-built T32Ms, linked image and boot area match byte for byte, and both
RedSea volumes pass ownership/bitmap audits
(`generation-identity-direct-doc-breakfix-kvm/result.json`). Both installed
generations pass the 386 executable audit with guest compiler templates. The
first installed target's no-FPU workstation and writable three-boot runs
followed. Its writable three-boot run now passes 107/56/15
commands, exact VGA and independent RedSea audit on the exact guest-built
target (`selfhost-install-direct-doc-breakfix-kvm/doldoc-tcg-nofpu/result.json`).
The full no-FPU workstation suite now passes on this same guest-built target
(`selfhost-install-direct-doc-breakfix-kvm/full-tcg-nofpu/result.json`):
513 native commands, 576 submitted lines, exact VGA and 20 bounded document
cycles with exact task-heap recovery under 8 MiB `486,-fpu` TCG. Quoted
`ExeDoc` formatting remains a known gap. Human observation remains deferred.
