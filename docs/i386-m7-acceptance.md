# M7 self-hosting workstation acceptance

This is the current evidence map for [M7 in PLAN.md](../PLAN.md#following-big-goal-m7-self-hosting-32-bit-templeos-workstation).
The current candidate is
`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/target.img`
(SHA-256 `a7c111f8f139f4121283916ff80e1d173069753b173e1bb1e4c90ace191db96c`).
It contains twelve guest-built modules and a 482,384-byte flat image, and
its installed executable regions, boot payload and RedSea volume pass audit.
The installed lexer, boot-image builder and installer source files match
the committed tree byte for byte. The current local bundle at
`build/i386-release-current/` packages this candidate and independently
verifies its compressed image and evidence-file hashes. The older
`build/i386-release-candidate/` bundle remains tied to an earlier source
revision. `build/` is ignored by Git, so result files and bundles are local
evidence rather than repository contents.

| M7 requirement | Current evidence | Status |
| --- | --- | --- |
| All kernel, compiler and retained runtime sources build in the guest | `retained-build-capacity-lexfix-kvm/result.json` and `selfhost-install-capacity-lexfix-gen2-retained-build-kvm/result.json` audit two guest-built sets of six retained modules; `retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json` independently audits all six retained modules rebuilt under `486,-fpu` TCG against the installed second generation. Both `selfhost-install-capacity-lexfix-kvm/result.json` and `selfhost-install-capacity-lexfix-gen2-kvm/result.json` audit six guest-built flat modules, install the 482,384-byte image and cold-boot it. | Pass for both current guest-built generations; retained rebuild also passes without FPU. |
| Development session survives source errors and interruption | The complete workstation suite exercises source-linked error recovery and keyboard break handling; the [manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) includes an interrupted loop and subsequent compilation. | Automated cases pass; human source-edit/rebuild observation open. |
| Native installation and interrupted-install recovery | Both guest-built targets cold-boot. The first generation passes hard stops at LBA 128, 850 and after LBA 0 under KVM; `selfhost-install-capacity-lexfix-gen2-kvm/install-recovery-tcg-nofpu-stdio-retry/result.json` passes the same cuts under `486,-fpu` TCG, with byte-identical retry and independent boot. `build/i386-kernel/result.json` also passes native boot-area publication and interrupted install-copy checks. | Pass for both generations in tested QEMU scenarios; physical power-loss durability is deferred. |
| Two independent guest-built generations | `generation-identity-capacity-lexfix-kvm/result.json` checks all twelve modules, the flat image and boot area byte for byte; both volumes pass RedSea ownership/bitmap audit. | Pass for the current source under QEMU/486 KVM. |
| 386-targeted executable regions | Both generations' `instruction-audit/result.json` check linked and retained modules, guest compiler template, and BIOS/protected-mode boot ranges. | Pass for both current guest-built generations' audited regions. |
| 8 MiB PC workstation on no-FPU and later 32-bit CPUs | Both installed generations pass 513 commands, 576 lines, exact VGA and 20 document cycles under `486,-fpu` and `pentium3,-fpu` TCG, each with writable-copy provenance. The first also passes under `486` KVM. | Pass on both guest-built generations under no-FPU 486 and later-CPU TCG, and on the first under 486 KVM. |
| Persistent DolDoc development and memory budget | Both guest-built generations' `doldoc-tcg-nofpu*/result.json` pass 107/56/15 commands over three writable boots with exact VGA, unchanged source disks and RedSea audits. Both complete no-FPU workstation suites pass 20 cycles with exact task-heap recovery. | Pass on both current guest-built generations. |
| TempleOS programming model and public services | The current full suites exercise HolyC compilation, DolDoc, task/break recovery, direct VGA/PS/2/PIT/speaker paths, RedSea, graphics, sound, help and source-linked diagnostics. Original x64 TempleOS reads and saves both generations' native binary-record and styled DolDoc files byte for byte. Both i386 generations then read and save an original-edited styled document byte for byte. The [support matrix](i386-support-matrix.md) defines the tested surface. | Pass for the integrated tested surface; complete original feature parity remains open. |
| Release artifact and human usability | `build/i386-release-current/` packages the current disk and evidence, including bidirectional original-document compatibility, install recovery and the six-module no-FPU retained rebuild; its standalone `verify.py` passes for 88 files. The [manual workflow](i386-test-workflow.md#manual-self-hosted-workstation-session) and [observation form](i386-manual-observation-template.md) are ready. | Local current-source package passes; human observation and publication remain open, with the manual session deferred by request. |

The 16 MiB `486,-fpu` TCG retained rebuild in
`build/i386-kernel/retained-build-gen3-tcg-nofpu/` has since passed its
all-six-module disk audit. Earlier attempts reached host command timeouts;
the resumed run completed and verified every retained module. A separate
7,200-second run passed the full no-FPU flat-kernel build, installation and
cold boot. Command checkpoints alone were not treated as passing verdicts.
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
The separate 16 MiB no-FPU TCG console build also passes and matches the
installed module byte for byte after an independent RedSea read
(`retained-console-gen3-tcg-nofpu-long/result.json`). The package requires and
bundles this focused evidence; the integrated all-six audit is recorded above.
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

The enlarged boot area now passes the prior layout generation's
guest-built flat-image installation: 480,952 linked bytes, exact reserved
boot-area comparison, RedSea extent/bitmap audit and independent 8 MiB
KVM `486` and no-FPU TCG `486,-fpu` cold boots with two native commands
and exact VGA (`build/i386-kernel/boot-capacity-layout-link-kvm/result.json`,
`build/i386-kernel/boot-capacity-layout-install-kvm/result.json`,
`build/i386-kernel/boot-capacity-layout-cold-boot-kvm/result.json`,
`build/i386-kernel/boot-capacity-layout-cold-boot-tcg-nofpu/result.json`).
The latest control-record source still needs its own full guest-built
installation. The manual session remains deferred.

The current source's 8 MiB `486,-fpu` compiler group passes 144 native
commands and exact VGA
(`build/i386-kernel/lexident-compiler-tcg-nofpu/result.json`). Its
source-matched KVM guest rebuild is on the sixth retained module; the
complete 386 `--test` is active in follow-up boot and filesystem probes.
Exact-source guest installation and human observation remain open. The
manual QEMU session remains deferred.

All six current-source retained modules pass KVM guest rebuild and audit,
byte-identical replacement and independent 8 MiB KVM cold boot
(`build/i386-kernel/retained-build-capacity-lexfix-kvm/result.json`,
`build/i386-kernel/retained-install-capacity-lexfix-kvm/result.json`). The
candidate embeds current lexer, boot-image builder and installer source.
Its guest-built flat-kernel installation and the complete 386 `--test`
are still running. Manual QEMU observation remains deferred.

The current-source first fully guest-built image now passes all-twelve
module installation, 482,384-byte flat linking, exact boot-area check,
independent 8 MiB KVM cold boot, RedSea ownership audit and 386
executable/guest compiler-template audit
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/result.json`,
`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/instruction-audit/result.json`).
The installed target embeds current lexer, boot builder and installer
source byte-identically. Full no-FPU workstation and second-generation
identity checks are active. Human manual observation remains deferred.

The complete current-source `tools/build-i386-kernel.py --test` passes:
513 workstation commands, 576 lines, exact VGA, 20 document cycles with
exact task-heap recovery, diagnostic startup, boot-area publication,
interrupted install-copy recovery and original TempleOS document
cross-compatibility (`build/i386-kernel/result.json`). The installed
guest-built image's no-FPU workstation and second-generation identity
checks are still active. Human manual observation remains deferred.

The current fully guest-built target passes its three-boot writable
8 MiB no-FPU DolDoc session: 107/56/15 native commands, exact VGA,
unchanged source disk, persistent create/reopen/revision, and verified
RedSea extent/bitmap ownership
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doldoc-tcg-nofpu/result.json`).
Full no-FPU workstation and second-generation identity checks remain
active. Human manual observation remains deferred.

The first exact-source fully guest-built installed image passes the full
8 MiB `486,-fpu` workstation suite: 513 commands, 576 lines, exact VGA,
20 document cycles with exact task-heap recovery and a 0.387-second
long-document visible update
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-tcg-nofpu/result.json`).
The installed-disk KVM suite and second-generation identity work are
active. Human manual observation remains deferred.

The current installed image also passes the full 8 MiB `486` KVM
workstation suite: 513 commands, 576 lines, exact VGA, and 20 bounded
document cycles with exact task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-kvm-retry/result.json`).
The second-generation retained rebuild persisted five byte-identical
modules before interruption during its last module; that module is being
resumed. Human manual observation remains deferred.

The resumed final module now completes the all-six second-generation
retained audit; each module is byte-identical to the first generation
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-retained-build-kvm/result.json`).
Replacement installation and independent 8 MiB KVM cold boot pass
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/result.json`).
The current build manifest matches all 1,233 worktree sources and all 814
delivered source files on the first installed target. The second-generation
flat build and twelve-module/boot-area identity check remain open. Human
manual observation remains deferred.

Both current-source guest-built generations now pass native flat-kernel
installation and independent 8 MiB KVM cold boot. The second target passes
the 386 executable and guest compiler-template audit. All twelve modules,
the 482,384-byte flat image and installed boot area match byte for byte;
both RedSea volumes pass extent/bitmap ownership audit
(`build/i386-kernel/generation-identity-capacity-lexfix-kvm/result.json`).
`tools/package-i386-current.py` builds the local current-source bundle,
and its standalone verifier passes the compressed disk and 72 bundled file
hashes (`build/i386-release-current/manifest.json`). Human manual QEMU
observation remains deferred, and this bundle is not published.

The exact current installed disk passes the native/original DolDoc round
trip: original x64 TempleOS reads and saves its 37-byte document byte for
byte (`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doc-compat-current/result.json`).
Its boot-image installer survives hard stops at LBAs 128 and 850 with exact
retry and independent boot; a hard stop just after LBA 0 leaves the complete
reference disk bootable
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/install-recovery-current-kvm/result.json`).
The current local bundle now includes these results and verifies 72 files.
Human manual QEMU observation remains deferred.

The exact current candidate also passes the complete 8 MiB
`pentium3,-fpu` TCG workstation suite on a verified writable copy: 513
commands, 576 lines, exact VGA and 20 document cycles with exact task-heap
recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-pentium3-nofpu-stdio-cli-retry/result.json`).
QMP stdio avoids the restricted host's socket prohibition. The sound test
now samples a full PIT interval, preserving its 440 Hz divisor check while
avoiding a host-scheduling race. The current local bundle includes the
later-CPU result and verifies 72 files. Human observation remains deferred.

The independently rebuilt second-generation disk also passes the full
8 MiB `486,-fpu` TCG workstation suite: 513 commands, 576 lines, exact VGA
and 20 document cycles with exact task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-tcg-nofpu-stdio-cli/result.json`).
Its writable-copy provenance binds the run to the unchanged second disk.
The local bundle verifies this additional result and 72 files. Human manual
observation remains deferred.

The second-generation installed disk now passes a three-boot writable
DolDoc project under 8 MiB `486,-fpu` TCG: 107/56/15 commands, exact VGA,
persisted create/reopen/revision, unchanged source disk, and an independent
RedSea bitmap audit
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doldoc-tcg-nofpu-stdio/result.json`).
The local bundle includes both generations' persistent-session evidence and
verifies 72 files. Human manual QEMU observation remains deferred.

The independently guest-built second-generation disk also passes the
original x64 TempleOS DolDoc read/save round trip: its native 37-byte
document returns byte for byte, with unchanged source-image provenance
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doc-compat-stdio/result.json`).
`tools/test-i386-doc-compat.py --qmp-stdio` runs this through the restricted
host's QEMU transport. The current bundle includes both generations'
original-reader results and verifies 72 files. The human manual session
remains deferred.

The independently guest-built second-generation disk passes all three
interrupted boot-image install cuts under 16 MiB `486,-fpu` TCG. Cuts after
LBAs 128 and 850 leave LBA 0 blank, and retry reconstructs the reference
disk byte for byte before independent boot. A cut after LBA 0 leaves the
complete disk bootable. The source image stays unchanged; QMP stdio and a
separate writable independent-boot copy avoid host socket and snapshot
restrictions
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/install-recovery-tcg-nofpu-stdio-retry/result.json`).
The local release bundle requires this result and its QEMU command records
and verifies 72 files. Human manual observation remains deferred.

The independently guest-built second-generation disk now passes the complete
8 MiB `pentium3,-fpu` TCG workstation suite on a verified writable copy:
513 commands, 576 lines, exact VGA and 20 document cycles with exact shared
task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-pentium3-nofpu-stdio-cli/result.json`).
Provenance binds the run to the unchanged second disk. Both generations now
pass the complete no-FPU suites on 486 and later 32-bit CPU profiles. The
local bundle requires this evidence and verifies 72 files; human manual
observation remains deferred.

The retained-build and flat self-host-install harnesses now accept
`--qmp-stdio`; the installer boots a writable copy for its independent
check when host snapshots are unavailable. A focused current-source
`Startup` guest rebuild passes under 16 MiB `486,-fpu` TCG and matches the
installed second-generation module byte for byte
(`build/i386-kernel/retained-startup-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json`).
The complete current-source retained rebuild now passes under 16 MiB
`486,-fpu` TCG on the installed Generation 2 disk. All six persisted T32Ms
pass export and structure checks and match their installed counterparts byte
for byte, including the 1,209,705-byte `CompilerProbe` and 1,699,847-byte
`CompilerRuntime`
(`build/i386-kernel/retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json`).
The audit records the source and comparison disk hashes and each module hash.
The long build was resumed after host interruption; its final guest command
completed, and a post-write, read-only audit supplied the verdict. The local
release bundle requires this result and independently compares all six module
bytes; its standalone verifier passes 76 files. Human manual QEMU observation
remains deferred, and complete original feature parity remains open.
