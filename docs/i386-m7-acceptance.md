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
| All kernel, compiler and retained runtime sources build in the guest | Six retained T32Ms in `retained-build-fixed/result.json`; six flat kernel/boot T32Ms and an independently booted installed disk in `selfhost-install-fixed/result.json`. The second generation repeats the build. `selfhost-install-gen3-tcg-nofpu-long/result.json` passes the flat kernel and five boot helpers under `486,-fpu` TCG, and the installed disk cold-boots at 8 MiB. `retained-build-gen3-tcg-nofpu/result.json` verifies all six no-FPU retained rebuilds byte-identical to installed Generation 2 modules. | Pass for older audited Gen2/Gen3 sources. The newer direct-document source's no-FPU retained rebuild is still running; quoted-foreground source still needs a guest build. |
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
requires and bundles that focused result. The six-module no-FPU audit has now
passed for the older Generation 2 image
(`retained-build-gen3-tcg-nofpu/result.json`).

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
An original x64 fixture identified quoted foreground formatting as another
programming-model case: `A$FG,4$B` has length 8. The i386 lexer now passes
the canonical single-document test and a repeated color-4/15/default test
under KVM and `486,-fpu` TCG on a cross-built image. Other quoted formatting
records and a guest-built image with this source still need verification.
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
cycles with exact task-heap recovery under 8 MiB `486,-fpu` TCG. A newer
cross-built source passes quoted foreground records, including two-digit and
default colors, on KVM and no-FPU TCG. The rest of quoted record semantics
and the human observation remain open; the manual session is deferred.
Original x64 background and style fixtures now specify `$BG,1$`, `$BK,1$`,
`$IV,1$` and `$UL,1$` inside quoted document strings. New native probes first
failed on the old image and now pass on an isolated cross-built source under
both KVM and `486,-fpu` TCG, with exact VGA; the documents group passes both
profiles. The full workstation and guest-built installation checks on this
source remain pending. Human observation stays deferred by request.
The complete 8 MiB KVM workstation suite now passes on the expanded quoted-
format source: 513 commands, 576 lines, exact VGA and 20 bounded document
cycles with exact heap recovery
(`../TempleOS-quote-next/build/i386-kernel/style-full-fixed-kvm/result.json`).
The full no-FPU suite and guest-built installation are still pending.
The same expanded source now also passes the complete 8 MiB `486,-fpu` TCG
workstation suite: 513 commands, 576 lines, exact VGA and 20 bounded
document cycles with exact heap recovery
(`../TempleOS-quote-next/build/i386-kernel/style-full-tcg-nofpu/result.json`).
The preceding foreground-only source passed six-module guest rebuild and
replacement installation with independent KVM cold boot. The expanded-source
guest-built image and second-generation identity are still open; manual
observation remains deferred.
The foreground-only guest-installed image passes the 21-command quoted
foreground repeat test under 8 MiB `486,-fpu` TCG with exact VGA
(`retained-install-quote-fg-kvm/quote-repeat-tcg-nofpu/result.json`). The
expanded-source guest rebuild and installed-generation checks remain open.
The expanded-source six-module retained rebuild has since passed export and
structure audit, replacement installation, and independent 8 MiB KVM cold
boot (`../TempleOS-quote-next/build/i386-kernel/retained-build-style-kvm/result.json`,
`retained-install-style-kvm/result.json`). Background and style quotation
probes also pass with exact VGA on this guest-installed disk under 8 MiB
`486,-fpu` TCG. The complete installed-disk no-FPU workstation and native
flat-kernel installation are active; second-generation identity and manual
observation remain open.
The first fully guest-built expanded-source generation now passes native
flat-kernel and boot-helper construction, installation, independent 8 MiB KVM
cold boot, and the guest 386 executable/boot/filesystem audit. The linked
image is 471,992 bytes
(`../TempleOS-quote-next/build/i386-kernel/selfhost-install-style-kvm/result.json`,
`selfhost-install-style-kvm/instruction-audit/result.json`). Second-generation
identity, the full installed-disk no-FPU run, and human observation remain
open; manual observation is deferred by request.
The second fully guest-built expanded-source generation now passes from the
first installed target. All twelve guest-built modules, the 471,992-byte
linked image, and the installed boot area are byte-identical; both RedSea
volumes pass extent/bitmap audit
(`../TempleOS-quote-next/build/i386-kernel/generation-identity-style-kvm/result.json`).
Both installed generations pass the 386 executable and guest compiler-template
audit. Quoted background/style probes pass on the first fully guest-built
target under no-FPU TCG. Its complete no-FPU workstation and three-boot
writable session remain active; human observation is deferred.
The first fully guest-built target's three-boot writable session now passes
under 8 MiB `486,-fpu` TCG: 107/56/15 commands, exact VGA, 0.224-second
break recovery and independent RedSea extent/bitmap ownership
(`../TempleOS-quote-next/build/i386-kernel/selfhost-install-style-kvm/doldoc-tcg-nofpu/result.json`).
The complete no-FPU workstation suites are still active; human observation
remains deferred by request.
The first fully guest-built expanded-source target now passes the complete
8 MiB workstation suite under both KVM/486 and `486,-fpu` TCG: 513 native
commands, 576 lines, exact VGA and 20 bounded document cycles with exact
heap recovery on each profile
(`../TempleOS-quote-next/build/i386-kernel/selfhost-install-style-kvm/full-kvm/result.json`,
`selfhost-install-style-kvm/full-tcg-nofpu/result.json`). Its three-boot
writable session, two-generation byte identity and 386 audits also pass.
The preceding retained-module installation's full no-FPU suite passes as
well. The earlier direct-document source's no-FPU retained rebuild of
ConsoleRuntime and CompilerRuntime now matches its installed modules byte
for byte (`retained-build-direct-doc-breakfix-tcg-nofpu/result.json`),
separate from the newer generation. M7 human observation remains deferred;
further quoted-record semantics still need original-behavior fixtures.
An original x64 fixture now establishes quoted shifted-X/Y behavior:
`A$SX,12$$SY,-34$B`, length 17. The old i386 image fails the matching
native probe; the updated cross-built image passes nine commands with exact
VGA under both KVM and `486,-fpu` TCG. The 33-command documents group and
foreground/style quotation regressions pass both profiles. Full workstation
and exact-source guest-built installation checks for this newest lexer are
still active. Manual observation remains deferred by request.
The shifted-record source now also passes the complete 8 MiB KVM workstation
suite: 513 commands, 576 lines, exact VGA and 20 bounded document cycles
with exact heap recovery (`build/i386-kernel/shifted-full-kvm/result.json`).
The full no-FPU suite and exact-source guest-built generation are still
running; manual observation remains deferred.
The complete 8 MiB `486,-fpu` TCG workstation suite also passes on this
shifted-record cross-built source: 513 commands, 576 lines, exact VGA and
20 bounded document cycles with exact heap recovery
(`build/i386-kernel/shifted-full-tcg-nofpu/result.json`). The exact-source
guest-built installed-generation gates remain open; manual observation is
deferred by request.
The shifted-record source now passes a complete six-module guest rebuild,
post-exit export/structure audit, replacement installation and independent
8 MiB KVM cold boot (`build/i386-kernel/retained-build-shifted-kvm/result.json`,
`build/i386-kernel/retained-install-shifted-kvm/result.json`). Native
flat-kernel installation and second-generation identity are still active;
manual observation remains deferred.
The first fully guest-built shifted-record generation now passes native
flat-kernel and boot-helper construction, independent 8 MiB KVM cold boot,
and the 386 executable/boot/filesystem audit. The linked image is 475,216
bytes (`build/i386-kernel/selfhost-install-shifted-kvm/result.json`,
`build/i386-kernel/selfhost-install-shifted-kvm/instruction-audit/result.json`).
Second-generation identity and no-FPU workstation/persistence checks on this
installed image remain open; manual observation is deferred.
An original x64 fixture establishes quoted default color records:
`A$FD,7$$BD,2$B`, length 14. The preceding i386 image fails the matching
native probe. The updated source passes the nine-command probe, documents
group and complete workstation suite under 8 MiB KVM and `486,-fpu` TCG
on an isolated byte-identical build; each full suite checks 513 commands,
576 lines, exact VGA and 20 document cycles with exact heap recovery.
Exact-source guest-built installation and repeated-generation identity
remain open; human observation is deferred by request.
The preceding shifted-record source now passes two fully guest-built
generations with byte-identical twelve modules, linked image and boot area;
both installed RedSea volumes pass extent/bitmap audit
(`build/i386-kernel/generation-identity-shifted-kvm/result.json`). The second
installed image passes the 386 executable/guest compiler-template and
boot/filesystem audit
(`build/i386-kernel/selfhost-install-shifted-gen2-kvm/instruction-audit/result.json`).
The newer default-color source's guest rebuild is running. The human M7
usability gate remains deferred by request.
The first fully guest-built shifted-record target also passes the
nine-command quoted shifted-X/Y probe under 8 MiB `486,-fpu` TCG with exact
VGA (`build/i386-kernel/selfhost-install-shifted-kvm/shifted-tcg-nofpu/result.json`).
The same target passes the three-boot writable DolDoc session at 8 MiB
`486,-fpu`: 107/56/15 commands, exact VGA, 0.285-second break recovery,
unchanged source disk and RedSea extent/bitmap ownership audit
(`build/i386-kernel/selfhost-install-shifted-kvm/doldoc-tcg-nofpu/result.json`).
The quoted page-layout fixture was red on i386: original x64 `ExeDoc`
produces `A$PL,80$$LM,-2$B` (length 16), while the preceding i386 image
times out at the matching `ExeDoc` check
(`tests/guest/i386-exedoc-layout/Once.HC`,
`build/i386-kernel/exedoc-layout-x64/debug.log`,
`build/i386-kernel/exedoc-layout-red-kvm/`). The new lexer passes the
matching nine-command probe on an isolated byte-identical cross-build under
KVM and `486,-fpu` TCG with exact VGA. Default-color and shifted-record
regressions pass under KVM. The latest source's complete workstation and
guest-built installed-generation gates remain open; human observation is
deferred.
The preceding fully guest-built shifted-record target now passes the
complete 8 MiB `486,-fpu` TCG workstation suite: 513 native commands,
576 submitted lines, exact VGA, a 0.209-second long-document visible-update
latency and 20 bounded document cycles with exact task-heap recovery
(`build/i386-kernel/selfhost-install-shifted-kvm/full-tcg-nofpu/result.json`).
The newer page-layout source's installed-generation gates remain open.
Original x64 now establishes the whole simple numeric layout quotation:
`A$PL,80$$LM,-2$$RM,3$$HD,4$$FO,5$$ID,6$$WW,1$$HL,1$B` (length 52).
The earlier two-record i386 image fails at the matching `ExeDoc` check;
the new byte-identical isolated-source build passes all 14 commands under
8 MiB KVM and `486,-fpu` TCG with exact VGA, along with x64 rebuild and
386 cross-build/audit. Full installed-generation checks remain open for
this latest source. The preceding default-color source passes its
six-module guest rebuild and post-exit audit
(`build/i386-kernel/retained-build-default-colors-kvm/result.json`).
Human manual observation stays deferred.
The preceding default-color source now passes replacement installation of
all six guest-built retained modules, independent 8 MiB KVM cold boot, a
first fully guest-built flat-kernel installation and independent cold boot.
The 476,360-byte installed image passes the 386 executable, guest compiler-
template, boot-payload and filesystem audit
(`build/i386-kernel/selfhost-install-default-colors-kvm/result.json`,
`build/i386-kernel/selfhost-install-default-colors-kvm/instruction-audit/result.json`).
A second guest-built generation is running. The latest eight-layout-record
source passes main cross-build, the 14-command focused probe and 33-command
documents group on KVM and `486,-fpu` TCG with exact VGA. Its complete
workstation and installed-generation gates remain open; human observation
stays deferred.
The first fully guest-built default-color target itself passes the
nine-command quoted default-color probe under 8 MiB `486,-fpu` TCG with
exact VGA
(`build/i386-kernel/selfhost-install-default-colors-kvm/default-colors-tcg-nofpu/result.json`).
Its complete no-FPU workstation suite is running. The latest
eight-layout-record source has started its
six-module guest rebuild. Human manual observation remains deferred.
The next original-behavior fixture establishes quoted page-break and clear
records: x64 `ExeDoc` yields `A$PB$$CL$B` (length 10), while the preceding
i386 image reaches `ExeDoc` but fails the matching nine-command probe
(`tests/guest/i386-exedoc-controls/Once.HC`,
`build/i386-kernel/exedoc-controls-red-kvm/`). The isolated byte-identical
new source passes the nine-command control probe, 14-command numeric layout
regression and 33-command documents group on KVM and `486,-fpu` TCG with
exact VGA; its x64 rebuild and 386 cross-build/audit pass. Complete
workstation and guest-built installed-generation checks remain open.
The preceding default-color source passes two fully guest-built generations
with all twelve modules, linked image and boot area byte-identical; both
RedSea volumes pass extent/bitmap audit
(`build/i386-kernel/generation-identity-default-colors-kvm/result.json`).
The second installed image passes the 386 executable/guest compiler-template
and boot/filesystem audit. The first fully guest-built target passes the
complete 8 MiB `486,-fpu` TCG workstation suite: 513 commands, 576 lines,
exact VGA, 0.268-second long-document visible-update latency and 20 bounded
document cycles with exact task-heap recovery
(`build/i386-kernel/selfhost-install-default-colors-kvm/full-tcg-nofpu/result.json`).
Focused default-color and shifted-record no-FPU probes pass on that target.
The three-boot writable session is running; human observation stays deferred.
That session now passes under 8 MiB `486,-fpu` TCG: 107/56/15 commands,
exact VGA, 0.346-second break recovery, unchanged source disk and RedSea
extent/bitmap ownership audit
(`build/i386-kernel/selfhost-install-default-colors-kvm/doldoc-tcg-nofpu/result.json`).
Human observation stays deferred.
The installed default-color disk embeds compiler lexer source byte-identical
to commit `18463db3`, while the cross-built input disk for the active
layout guest rebuild embeds that path byte-identical to `36da99b0`.
The newer control-record source has not yet completed guest installation;
human observation remains deferred.
The eight-layout-record source passes a six-module guest rebuild, replacement
installation and independent 8 MiB KVM cold boot
(`build/i386-kernel/retained-build-layout-all-kvm/result.json`,
`build/i386-kernel/retained-install-layout-all-kvm/result.json`). Its native
flat-kernel installation remains active.
The newer control-record source passes main cross-build and the focused
quoted-control probe on KVM and `486,-fpu` TCG. Its isolated byte-identical
image passes the full no-FPU workstation suite: 513 commands, 576 lines,
exact VGA, 0.382-second long-document visible-update latency and 20 bounded
document cycles with exact heap recovery. A 509-command KVM functional run
excluding the timing-sensitive latency group also passes. Full KVM and
installed-generation gates remain open; human observation stays deferred.
The control-record source's main cross-built image passes the standalone
8 MiB KVM document-latency group: four commands, exact VGA and a
0.620-second long-document visible update
(`build/i386-kernel/controls-latency-main-kvm/result.json`). Main-image
complete workstation runs and guest rebuild are active. The preceding
layout source's flat-kernel install remains at boot-image linking; no
installed-image pass is counted. Human observation stays deferred.

The exact-source control-record workstation now passes the full 513-command,
576-line suite with exact VGA on both 8 MiB KVM `486` and no-FPU TCG
`486,-fpu` (`build/i386-kernel/controls-full-main-kvm/result.json`,
`build/i386-kernel/controls-full-main-tcg-nofpu/result.json`). The earlier
layout flat-kernel install is not accepted: its guest-built payload needs
480,952 bytes, beyond the previous 479,232-byte limit. The expanded
960-sector reservation and guest size preflight pass x64 rebuild, 386
cross-build/boot audit and normal 8 MiB QEMU keyboard/VGA boot
(`build/i386-kernel/boot-capacity-preflight-keyboard/result.json`).
Guest-built flat installation under that limit and the diagnostic boot
remain open; the latter also fails on the unchanged 944-sector baseline.
The manual session and observation template remain deferred.

The diagnostic stop after `RUNTIME PROBE` was caused by duplicate
source-define lookup in the 386 identifier scanner. With that lookup
removed, the diagnostic guest completes both probe phases and native
startup. The host verifier now includes the retained compiler runtime's
existing `frontend_bind_files` service pointer. The complete `--test`
run is active in its interactive QEMU phase. Guest-built flat install
and human observation are still open; the manual session is deferred.
