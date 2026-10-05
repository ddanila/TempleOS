# TempleOS architecture plan: 32-bit 386+ and VGA

## Objective and status

Latest qualification state (2026-10-05): main OS services remain ABI 40.
The latest unpromoted ABI-47 candidate adds public Caller to the extended
high-memory BIOS loader, early IDT, extent-transfer moves, renderer buffer
reuse, corrected native TEST encoding and trimmed memory-probe baseline.
Its integration artifact is
[the public Caller candidate patch](docs/patches/i386-public-caller-integrated-candidate.patch).
Public Caller passes normal-stack, corrupt-frame and five-cycle dedicated CPU
debugger-stack gates. Its complete suite and retained native build remain live.

The preceding memory-baseline candidate completes both fully native generations:
12 identical modules, flat kernel and boot area, independent installation/boot
and executable/filesystem audits. Deterministic packaging also makes their whole
disk images byte-identical while preserving all live file contents, attributes
and dates. This does not automatically qualify the newer Caller sources.
The earlier TEST-fixed generation2 passes three-boot DolDoc, captured speaker
and bounded-resource gates; its full workstation remains running. Its packaged
image passes native audits and no-FPU boot within the unchanged 60-second budget;
full packaged-image workflows are running with independently recomputed native
origin. No complete M7 or release claim is made. Historical checkpoint entries
below retain their source-specific evidence.

Current promoted filesystem services remain ABI 40. The newer integrated
public resident-cache/Cd candidate is ABI 47 and is not yet promoted. Its fresh
original bootstrap/cross/386 audits, 32-command public Cd contract, 32-command
compressed cold-cache/directory-state contract, 29-command allocation recovery
and 45-command resident twenty-cycle recovery pass. Ordinary cold mutation
and combined include/DolDoc/write/child also pass. Its full 513-command
workstation and six native retained modules pass; installed-generation
qualification is still running. Its first fully native twelve-module installed
image and 386 audit now pass. The preceding ABI-46 candidate already passes
full native twelve-module installation/audit and two-generation byte identity.
Neither candidate's partial evidence establishes complete M7 or release readiness.

The promoted CPU-trap epoch now passes fully native twelve-module
construction/install/boot/audits and five-cycle continuation. Its native
workstation passes 513 commands, exact VGA and 20 exact heap-recovery cycles:
startup 33.068 seconds and long-document update 0.205 seconds. Formal startup
budget passes. Second-generation retained rebuilding passes: all six modules
match the installed first generation byte for byte. Exact installation and
independent 8 MiB boot pass. Second-generation self-hosted flat construction,
installed audits and twelve-module/flat/boot byte comparison also pass.
Ordinary/compressed FileWrite is now promoted: exact cluster/date/attribute
semantics, original archive parity/replacement and the full 513-command
workstation suite pass on its prototype. Main's fresh original rebuild/cross
audits pass and all thirteen emitted artifacts match that qualified prototype.
Native retained rebuilding passes all six providers, and main-image archive
requalification passes. Native installation/boot and fully native twelve-module
flat construction/installed audits pass for two generations. All twelve modules,
flat kernel and boot area match between generations; whole-volume bytes differ.
Archive replacement and full no-FPU workstation requalification on the second
fully native FileWrite image are now running.
Public FileRead and FileFind are now promoted with file-service ABI 40. Their
public contracts, fully native twelve-module build/install/audit and native
513-command workstation pass. Main's fresh bootstrap/cross/386 audits pass and
all thirteen emitted artifacts match the qualified prototype. Two fully native
generations match across all twelve modules, flat kernel and boot area.

Current unpromoted work is public filesystem compatibility. Cd passes its
32-command focused contract, 513-command no-FPU workstation and native
construction/install/audits; broader errors and integration remain open.
The public resident cache has passed binary, compressed, dotless and empty
cold ownership/removal tests and original adam_task namespace ownership.
ABI-45 canonical public-cache bridges qualify FileRead, compiler includes and
DolDoc mutation/removal/default-name parity, child teardown and allocation
failure with exact caller/root/private recovery. Bare rethrow loops and missing
file-loader exception bindings were found and fixed in that candidate.

Current ABI-46 stages attempted serialized write bytes for canonical cache
publication. Original and native rejected-write publication/removal pass for
ordinary and .Z names (13 commands each); exact resident twenty-cycle recovery
passes 45 commands. Fault recovery, child parity and retained native building
are being requalified on ABI 46. Missing-parent FileWrite semantics now have
an original-oracle gate; native verdict is pending. Full workstation and native
generation/install reproducibility must qualify before promotion. Main remains
on qualified ABI 40. Current candidate source is preserved in
`docs/patches/i386-public-resident-write-attempt-candidate.patch`; earlier epoch
patches and results remain separate evidence. Broad errors, full debugger
behavior and release requirements remain open.

CPU breakpoint continuation is now promoted to main: task-owned saved CPU
frames, normal-context debugger entry and full exception-frame return. Five
repeat cycles, six general-register markers and forced child exit/survivor
debugging pass on the prototype; full workstation passes 513 commands.
Main's fresh original rebuild and i386 instruction/keyword audits pass,
and all thirteen emitted artifacts match the corrected tested prototype.
Guest flat-development construction/install/boot/audits pass at 487304 bytes
(120 spare), using cross-built retained providers. The first fully native
generation and second-generation artifact comparison pass as described above. Single-step, managed breakpoints,
register inspection/editing and concurrent debugger sessions remain open.

The fully guest-built optimized image passes installed 386/boot/filesystem and
keyword audits plus ordinary 8 MiB no-FPU keyboard/exact-VGA startup at
32.920 seconds, below the unchanged 60-second gate. Full native workstation
qualification now passes all 513 commands, exact VGA checkpoints and 20
document cycles with exact shared task-heap recovery. Startup is 33.014 seconds
and long-document update is 0.372 seconds, meeting the 60-second and one-second
budgets. The second-generation retained rebuild passes: all six providers
are byte-identical to the installed first generation. Exact installation and
independent 8 MiB boot pass. Second-generation flat construction and installed
image audits pass. All twelve modules, the 486472-byte flat kernel and installed
boot bytes match the first generation exactly; both RedSea volumes pass.
Current fully native three-boot DolDoc qualification passes exact VGA,
persistence/filesystem checks and 0.216-second interrupt recovery; all three
33-second boots pass the startup budget. Captured PC-speaker tone and
off/reset silence checks also pass. CPU-trap debugging and release qualification remain
open; this timing pass does not establish the whole OS goal.

The heap-search optimization is now promoted to main. Both heap corpora, the
matching original rebuild and i386 build/audits pass. All thirteen module/flat
artifacts match the qualified prototype exactly. That image passes 513
workstation commands, exact VGA and 20 exact heap-recovery cycles, with
23.639-second startup and 0.255-second visible update. Its guest flat-development
build fits at 486472 bytes and boots at 23.939 seconds, using cross-built retained
providers. All six retained providers now pass native construction and payload/export
checks for this source epoch in `build/i386-heap-seek-native-build`. Exact installation and independent 8 MiB boot pass in
`build/i386-heap-seek-native-install`. The six-module guest flat rebuild, installation and independent 8 MiB boot
pass in `build/i386-heap-seek-selfhost`; all twelve modules are guest-built.
Flat size is 486472 bytes (952 spare). Installed-image audits and no-FPU
startup checks are underway; two-generation qualification remains open.

The CPU-trap continuation test now also requires an EAX marker to survive
resumption. Its preparation passes on the pre-heap main image, then vector 3
still halts the kernel (`build/i386-debug-cpu-trap-register-red`). No continuation
or register-preservation assertion has passed yet.

The native startup profile in `build/i386-root-declarations-native-profile`
attributes 442/506 root-header samples to heap allocation/free/scan and
110/148 foundation samples to module validation. Sampling is not a benchmark.
An isolated heap-search prototype retains whole-arena validation before any
mutation and uses bounded U32 assembly for the later block search. Both heap
corpora pass, including 49 public layout checks and 1024 churn rounds each.
Its integrated build and instruction/keyword audits pass, with a 482440-byte
cross-built boot kernel (944 bytes smaller). No-FPU 8 MiB keyboard/exact-VGA
boot passes at 23.484 seconds and meets the unchanged startup budget. Full workstation testing is running. The guest flat-development build,
installation, independent boot and audits pass at 486472 bytes (952 spare).
No-FPU startup on that guest flat image passes at 23.939 seconds. Its retained
providers remain cross-built, so fully guest-built timing remains unproven;
main heap sources are unchanged.

The pre-Help fully guest-built image passes a same-call empty User create/kill
cycle in 0.352 seconds (`build/i386-root-declarations-native-cycle`), confirming
shared-root header speed on native-built providers. Its measured no-FPU 8 MiB
startup is 66.404 seconds: the unchanged 60-second budget fails. Functional
self-hosting and this task cycle therefore do not close startup qualification.

Native inline assembly now recognizes the original `INT3` and `BPT` mnemonics
and emits 0xCC. The same six-command checker rejects the old compiler and
passes on the isolated updated image without executing a trap. The promoted
main original rebuild, i386 build and audits pass; all thirteen module/flat
artifacts match that tested prototype. The existing inline-assembly regression passes on main. CPU-trap dispatch/resumption remains a separate failing
contract; opcode support does not establish debugger completion.

All six retained providers at the pre-Help root-declaration source epoch now
pass native construction/export checks and exact installation with independent
8 MiB boot (`build/i386-module-inheritance-native-build-long` and
`build/i386-module-inheritance-native-install`). The six-module guest flat-kernel rebuild, installation and independent boot
pass in `build/i386-module-inheritance-selfhost`; all twelve modules are now
guest-built at that epoch. The installed 386/boot/filesystem and keyword audits
pass. Flat size is 487384 bytes, only 40 bytes below the loader limit. This
proves neither the newer Help/assembly source epoch nor current two-generation
release qualification.

A new debugger CPU-trap contract is red in
`build/i386-debug-cpu-trap-byte-red-v2/result.json`. Verified native code bytes
execute an actual `INT3`; the kernel logs vector 3 and halts before a debugger
prompt. Required next behavior is captured CPU state, inspection and `G`
continuation after the trap with IF restored and TF cleared. Native assembler `INT3`/`BPT` encoding now passes a separate red/green
contract and is implemented on main. The CPU-trap fixture uses supported NOP
bytes and an independently checked 0xCC patch to isolate runtime dispatch.

The current-source full workstation attempt terminated at `help-index-link`
(`build/i386-module-inheritance-main-workstation`): the live category contained
the expected entries but their hash enumeration order differed after root
declaration sharing. It is a failed integration run, not a workstation pass.
Original `Adam/AHash.HC` sorts entries by name. An isolated alphabetical
category prototype passes the original two-generation rebuild and i386 build.
The unchanged main image fails the alphabetical oracle; the prototype passes
all nine focused no-FPU Help commands with exact VGA (58.120-second startup).
Its full workstation suite passes all 513 commands, 576 lines, exact VGA and
20 document cycles with exact heap recovery in `build/i386-help-sort-workstation`.
Startup passes the unchanged budget at 58.169 seconds; the long-document update
is 0.433 seconds. The sorting implementation and alphabetical fixture are now promoted to main.
Its matching original rebuild, i386 build and keyword/instruction audits pass;
all 13 module/flat artifacts match the qualified prototype byte-for-byte.
A focused main-image Help check is running.

Full self-hosting qualification now requires the retained-build and installation
verdicts to form a matching disk/payload chain before flat-kernel construction.
All six providers must match both reports; the resulting report records their
evidence hashes. The 17-test harness suite passes, including eight mismatched
chain rejection cases. Current-source native builds and workstation checks
remain in progress; this gate alone does not establish release readiness.

**Acceptance revision (2026-10-03):** Repeatable QEMU automation is the
functional acceptance gate. A person is not required to repeat the automated
boot, edit/execute/error/interrupt, persistence, rebuild or installation checks.
Human sessions are optional exploratory feedback on usability and host display,
input and audio integration. Record discovered failures and turn reproducible
ones into automated regressions. This supersedes mandatory manual-observation
gates in the historical progress notes; it does not waive missing automated
coverage, latency budgets, source provenance or release publication.

**Acceptance revision (2026-09-24):** QEMU/TCG is the required execution
platform for the current port milestones, including the standalone development
environment and M7 self-hosting. Physical-PC verification and dedicated 386SX/DX
emulator certification are deferred follow-up work, not completion blockers.
Keep the 80386 instruction baseline, no-FPU runtime, VGA/legacy-device design,
8 MiB interactive and 16 MiB native-rebuild targets. Passing this plan establishes
a QEMU-verified system with audited 386-targeted code; it does not certify a real
386 motherboard or vintage timing. This revision supersedes earlier hardware
promotion requirements in historical progress records.

Build a native, standalone 32-bit TempleOS variant for 386-class and later
PC-compatible machines with VGA. Preserve the interactive HolyC programming
system, ring-0 execution, one shared flat address space, DolDoc, and simple
software graphics and sound. Keep the working x86-64 system as a regression target.

This replaces the 16-bit feasibility track and makes native i386 the next
architectural target. Cross-platform QEMU launchers remain useful supporting
work; they are not a substitute for native 386 compatibility. ARM, RISC-V, UEFI,
and broad modern-device support are deferred.

A previous fully guest-built native i386 candidate established self-hosting: two guest-built generations
reproduce all twelve modules, the flat image and boot area byte for byte.
Both generations pass the 8 MiB no-FPU workstation suites and persistent
three-boot document workflow. All six retained modules also rebuild under
16 MiB no-FPU TCG. The local 95-file release bundle for that earlier checkpoint verifies, including both generations’ audio output. The authoritative
current evidence is [M7 acceptance](docs/i386-m7-acceptance.md); detailed
chronology is in [port progress](docs/port-progress.md).

M7 remains open. Complete original feature parity is not established, release
publication is pending, and startup qualification of a fully guest-built image
with the latest source remains open. The latest integration image with guest-built
MemoryRuntime and ConsoleRuntime passes the full no-FPU workstation suite:
513 commands, 53.657661-second startup and a 0.257098-second long-document
update. Its boot kernel and remaining providers are cross-built. A newer
cross-built image passes terminal creation and focus shortcuts; the updated native
providers have built and passed the independent twelve-module instruction/ABI audit.
The current cross-image programmatic User regression passes all 16 cases;
installation and the native creation-shortcut gate pass; User and focus runtime
gates pass. Repeated User resource qualification remains open. Older
fully guest-built startup results exceed the 60-second target. Functional passes and package
hash verification do not by themselves close these gaps. The historical
“next” sections below record the implementation sequence; the following work
queue supersedes their stale status and priority statements.

All work stays in our fork, `ddanila/TempleOS`, directly on `main`, without
feature branches or PRs. The former `archive` branch was removed after verifying
that its history is contained in `main`.

### Latest implementation checkpoint (2026-10-04)

- Guest-built User providers pass the 16-case User oracle, 41 formatter cases
  and the complete 513-command workstation suite on the mixed-provider image.
  Evidence: `build/i386-user-native-providers-workstation/result.json`.
- Ctrl-Alt-T and Ctrl-Alt-Esc now create a User task asynchronously in the keyboard
  worker; the child focuses itself after loading declarations. Ctrl-Alt-N and
  Ctrl-Alt-Tab cycle focus. The current cross-built image passes focused QEMU
  creation/input/Exit/cleanup and focus-history/heap-recovery tests. Plain and
  Ctrl-Alt-Shift creation variants do not create a task. New boot imports are
  unnecessary; boot-kernel size stays 483384 bytes.
- The current cross-image User regression passes all 16 cases (28 commands,
  48.720395-second startup on 8 MiB no-FPU TCG). Updated MemoryRuntime and
  ConsoleRuntime build inside TempleOS and pass the independent all-module
  instruction/ABI audit. Installation passes; native creation and User regressions
  creation passes all 15 commands with exact VGA checkpoints (52.185862-second
  startup). The native Tab-focus gate also passes its 11 commands, exact VGA
  history/refocus checks and parent-heap recovery (56.120742-second startup).
  The native programmatic User gate passes all 16 cases/28 commands with
  52.391379-second startup. Full workstation regression is running.
- A new experimental repeated-User recovery fixture fails on original TempleOS
  at its first measured cycle. Exact shared-pool recovery after one warmup is
  therefore an unvalidated compatibility requirement. A separate observation
  run completes nine original-system cycles: root child count stays at three,
  reserved bytes stay fixed, and shared-pool used bytes grow by 4539904.
  Compare native measurements and investigate ownership before defining the
  recovery acceptance invariant; do not copy original retention into the port.
  The native exact-recovery experiment times out during its first measured
  cycle after header loading; it does not establish a counter mismatch.
  The public-pool observation passes all nine separate-command cycles with
  exact recovery in every snapshot. Bootstrap recovery is measured through
  four cycles only; the fifth creation times out during header loading.
- The extended same-call User/Kill observation passes: header loading takes
  about 111 seconds and retirement about 19 seconds, exceeding the earlier
  120-second combined-command limit. An indefinite cancellation stall is not
  established. Optimize declaration-loading and teardown latency rather than
  changing cancellation policy on that evidence.
- A CPU-root declaration-sharing prototype passes its matching original rebuild
  and i386 build/audit in an isolated checkout. Same-call creation/retirement
  drops from about 130 seconds to 0.35 seconds; User and creation-shortcut gates
  pass. Startup ranges from 59.83 to 63.55 seconds in these runs, so the
  60-second target is not reliably met.
  nine-cycle exact public/bootstrap recovery and Tab isolation pass. The change
  is now applied to main; its original rebuild and i386 build/audit pass.
  Main-image strict recovery passes all nine cycles (58.411265-second startup).
  The six-provider build fails its first CompilerRuntime unit at inherited
  CHashFun forward completion. Repair module-source handling of inherited
  forward declarations before native promotion. The focused matching red/green
  gate now passes on the isolated repair, preserving the root forward class.
  The module-only inherited lookup fix and explicit keyword-byte initialization
  are applied to main; its original rebuild and i386 build/audit pass.
  The keyword-data gate is integrated into the normal build audit. Main-image
  module and full workstation regressions are running.
  The full isolated native-provider build hits its 900-second command limit
  during CompilerRuntime function generation. A fresh main-image build is
  running with a 3600-second diagnostic build limit; provider acceptance
  remains open. Native runtime and startup qualification remain open. Updated all-native/two-generation release
  qualification remains required.

Earlier source-epoch checkpoints below are historical; they do not supersede
this status or close the outstanding qualification gates.

The public-delay slice now passes its focused cross-image no-FPU test:
`Yield`, `Sleep` and `SleepUntil` reuse the original delay core and preserve
wake deadlines, task identity, the prior idle bit and caller IF. The native
compiler also rebuilds the updated memory provider, and its installed output
passes the same 8 MiB no-FPU delay test and independent code/ABI audit. This is incremental
required-behavior evidence. The public task package now passes its 43-command
positive contract on the cross-built image: Spawn/Exit, inherited state, nested
creators, default task records and dormant activation with exact public-pool
recovery. The guest-built memory provider installs and passes its executable
audit and the same 43-command no-FPU public contract. The following descendant
policy also passes five original-behavior cases and the expanded 55-command
lifecycle contract on cross-built and guest-built providers. Five original exit
callback cases, including descendant recovery during parent termination, now
pass on both providers, with 107-command bootstrap accounting. Public cancellation,
dormant disposal, multiple interactive terminals, source-linked debugging,
full current-source two-generation qualification and
publication remain open. See [the M7 coverage audit](docs/i386-m7-coverage-audit.md).
The still-running startup-optimization retained build predates this delay change;
keep its source epoch and export references separate.

The optimized fully guest-built image now installs all six native retained
outputs and passes its independent executable/boot/filesystem audit. Its
8 MiB `486,-fpu` TCG normal boot takes **71.383183 seconds**, so the startup
budget still fails. This image uses the pre-delay optimized source epoch;
it is not qualification for the newer public services. Evidence:
`build/i386-kernel/retained-startup-u32-installed/result.json` and
`build/i386-retained-startup-u32-keyboard-budget.json`.

## Next goal: an automatically qualified M7 release

Deliver a reproducible, published QEMU workstation release whose required
behavior, source provenance and resource budgets are checked automatically.
A human checklist is not a prerequisite. Preserve the existing M7 requirements;
removing redundant manual steps does not establish missing functional coverage.

| Order | Work | Completion evidence |
| --- | --- | --- |
| 1. Audit required coverage | Map each M7 requirement to an executable test and independent oracle on the current image. Check source-linked diagnostics, cooperative work in multiple terminals, public services and the original-document workflow explicitly; distinguish required behavior from broader feature parity. Add focused failing tests for uncovered required behavior and implement the missing behavior. | Every required outcome has a current-source result or a named open failing case; no blanket “complete OS” claim based only on the existing suite count. |
| 2. Close observable gaps | Profile normal startup and bring the no-FPU reference run within the existing 60-second target. Enforce the existing one-second edit/interrupt budget, 8 MiB interactive and 16 MiB rebuild profiles, and bounded heap use. Capture emulated speaker output to a WAV file and check tone/silence automatically; PIT register checks alone do not prove audio output. | Machine-readable timings and memory bounds fail the gate when exceeded; audio waveforms show the requested tones, and settled off/reset intervals produce no new audio samples. Any proposed budget change requires measured justification and an explicit plan revision, not merely a longer harness timeout. |
| 3. Make qualification reproducible | Provide one entry command that runs or validates the required pipeline for an explicit source revision and candidate, with named stage outputs, safe resume and provenance checks. Separate fresh qualification from verification of cached evidence. Include the matching x86-64 regression and executable-region 386 audit. | A clean output directory produces a complete pass/fail report; stale source hashes, wrong images, missing verdicts, excessive latency and targeted broken behavior are rejected. |
| 4. Publish the qualified candidate | After the required gates pass, publish a versioned image, matching source reference, hashes, support matrix, known limitations and standalone verifier on our fork. Smoke-boot a downloaded artifact on a writable copy automatically. | The downloaded published artifact verifies and reaches the normal prompt; the report identifies precisely what was tested. No manual approval checkbox is used as evidence of functionality. |

### Scalable test policy

- **During implementation:** run the affected focused tests. For a functional
  change, first observe the intended failing assertion, then implement the fix.
  Rebuild the image when OS sources change. A passing old image is not evidence
  for new source.
- **At integration checkpoints:** run the complete workstation suite and any
  affected persistent-session, compatibility or recovery tests. Check resource
  regressions with the same host/QEMU profile and retain the raw measurements.
- **For release qualification:** run the required two-generation guest builds,
  CPU/RAM profiles, installation recovery, x86-64 regression, instruction audits
  and downloaded-artifact smoke test. Resume verified stages after interruption;
  never accept stale or partial stages. Do not repeat hours of guest builds for
  documentation-only edits when their source inputs are unchanged.
- **Human use:** optional exploration for awkward controls, readability and host
  integration. Record actual observations only. Convert reproducible failures
  into automatic tests; do not ask users to retype arithmetic, build commands,
  save/reopen sequences or other deterministic acceptance cases.

The startup-budget checker now reports the second-generation 73.265-second
no-FPU result as failing the 60-second target. An installed-image profile uses
the candidate's own retained modules and preserves the disk; its samples point
to module validation/symbol resolution during foundation loading and heap
operations during source compilation. Next, complete the requirement-to-test
audit and optimize these measured costs without weakening validation. Both previous guest-built
generations now pass the PC-speaker waveform and off/reset emission checks;
packaging and its standalone verifier independently recheck that evidence.
After M7 qualification, prioritize
broader original-source/API compatibility using an explicit inventory and
original x64 behavioral oracles, rather than adding isolated passing examples.

The [requirement-to-test audit](docs/i386-m7-coverage-audit.md) now names
concrete remaining behavior gaps. A current-source publication probe fails for
`Spawn`, `Exit`, `Yield`, `Sleep` and `Dbg`, with working memory/file controls.
Scheduler/window corpora and generic exception recovery do not establish
multiple interactive terminals or usable runtime exception inspection. These
are required implementation work, followed by visible behavioral tests.

Startup optimization now uses validated U32 counters and symbol-name length
filtering while preserving wide input bounds, duplicate-symbol checks and
full heap validation. The fresh guest flat-kernel development image boots in
51.264 seconds under 8 MiB `486,-fpu` TCG and passes the 386/filesystem audit.
Its retained modules are cross-built, so it is not a replacement for the
fully guest-built qualification. The current-source cross image now passes the complete no-FPU workstation
suite (513 commands, 50.501-second startup and 0.314-second visible update).
The guest flat-kernel development image also passes the writable three-boot
document workflow, including 0.271-second interrupt recovery and exact
filesystem/VGA checks. All-six retained rebuilding remains underway.

### Remaining startup work: measured fully guest-built paths

`build/i386-retained-startup-u32-profile/result.json` samples the installed
native modules rather than host-built stand-ins. Of 285 foundation samples,
160 are in `I386FindSymbol` and 86 in `I386ModuleValid`; 320 of 347 startup-source
samples are in bootstrap heap allocate/free/size/validation. Sampling pauses
make profile elapsed time unsuitable for budget measurement.

Next optimize these measured paths while retaining malformed-module rejection,
duplicate/missing binding checks, full heap metadata validation, allocation
failure rollback and load failure's no-write guarantee. Prefer a per-call
symbol index or explicit scratch workspace over shared mutable lookup state;
keep valid large modules supported. Inspection of the installed kernel confirms that it already contains the
assembly validator; the older portable fallback explanation does not apply
to this image. For heap costs, investigate whether repeated full walks can
be reduced without trusting corrupt metadata. Use the loader/heap mutation corpora and
native executable audit before timing an installed image. Do not relax the
60-second budget or use KVM/profile times as the TCG reference verdict.

The symbol-loader implementation now builds a bounded, invocation-local export
index and retains the original scan for export sets larger than 512 entries.
The i386 kernel explicitly selects the compact native builder; host linking
keeps the portable builder. The no-FPU loader corpus compares lookup results
against the original scan and checks collisions, duplicate matches and the
512/513-entry boundary without changing valid-module acceptance. Native image
size and installed timing must still pass before this work closes the budget.
The first portable-builder native image was rejected at 488,776 bytes against
the existing 487,424-byte load limit; that failed build is not a candidate.

The compact builder exposed another native frontend gap: inline assembly
lacked register-immediate moves, memory stores from registers, byte zero
extension, shifts, masking, stack register operations and several arithmetic
forms. The cross-built loader corpus cannot prove that the guest compiler
accepts those forms. `tools/test-i386-native-inline-asm.py` compiles and executes
the required forms at the normal guest prompt, including a block beyond the
former 256-byte limit and a forward jump across that span. The focused test now fails at native compilation on the old compiler and passes
on the updated compiler. Class-member LEA addressing avoids unsupported offset
immediates. All six flat modules compile, link, install and boot in the guest;
the 486,088-byte image passes its executable audit and boots in 46.971996 seconds
on 8 MiB no-FPU TCG. Retained inputs are still cross-built in that development
image: require fully guest-built installation and timing before closing the
self-hosting startup gate. The current retained rebuild and full workstation
suite have passed for that loader checkpoint: all twelve modules build natively
and the installed image boots independently, while the development workstation
suite passes within its latency targets. The fully guest-built image passes its 386 executable audit and normal
8 MiB no-FPU TCG keyboard/VGA boot in 56.381575 seconds, within the 60-second
budget. Its full workstation suite also passes: 513 commands, exact VGA,
20 document cycles with exact shared-heap recovery, 55.820355-second startup
and 0.378412-second long-document navigation. That source epoch predates
the conditional frontend below; it does not qualify the new compiler source.

Expression `#if` now uses the existing native expression evaluator, with the
shared raw skip grammar, preserved directive lookahead and flag restoration
on errors. The JIT test has an observed fail-to-pass result across true/false
and nested conditions, macro arithmetic, pointer `sizeof`, floating-point truth,
skipped invalid code and post-error definition preservation. The separate
`tools/test-i386-native-conditionals-aot.py` checks source-mode semantics: the
same source returns 98 under JIT, then its guest-built AOT module returns 99
inside the no-FPU loader corpus (41 cases). It caught two real mode/lookahead
errors before passing. Raw lexer compatibility tests still pass. The frontend
uses explicit module-source mode because interactive controls also use AOT
backend staging internally; source-language mode cannot follow that temporary
backend flag. Allocation-failure and exact owned-heap cleanup still need
separate oracles before the complete conditional ownership contract closes.
The final compiler-provider native rebuild passes (1,722,646 bytes, 3,594
records, 407 exports). Installation verifies its bytes and independently boots
with 8 MiB and no FPU. Installed-provider JIT/AOT qualification is running;
installation alone does not establish that language behavior.
The installed-provider JIT contract now passes all 23 keyboard/VGA commands.
Its AOT contract also passes: 15 compile commands and 41 loader cases verify
JIT result 98 versus loaded AOT result 99. The installed native provider passes
the 386 instruction audit, including its division template, and the filesystem
allocation audit. Other modules in this focused image remain cross-built.
Five new diagnostic input cases require exact private-heap recovery after
nested and floating conditions, JIT mode selection, a failed expression with
atomic macro rollback, and an answer-callback exception. Both compiler phases
must also preserve the outer control, sentinel, references and interrupt flag.
All five cases have run successfully in both diagnostic phases; the full
integration runner remains active. Allocation exhaustion remains separate.
A new conditional pressure contract now reserves 0, 1,024, 4,096 or 65,536
payload bytes after frontend initialization, exhausts the remaining private
arena, and advances into an expression conditional. Zero space must throw
`OutMem`; the largest reserve must parse successfully. Every attempt must
restore conditional flags, controls, references, interrupt state and exact heap
counters. Its diagnostic run is active; this does not cover every individual
allocation site or close the release gate.
The first pressure run stops during attempt zero before recording a completion.
Diagnostic checkpoints have been added to distinguish exception registration,
flag cleanup and unwind failures; the cause remains under investigation.
The diagnostic rerun identifies an identifier-publication allocation failure
reported as `Compiler` rather than `OutMem`, with conditional flags clear.
The parser-backed lexer now preserves that allocation distinction; the original
raw entry retains its ABI and error values. Raw identifier compatibility and
the explicit allocation-error test pass. Conditional flag mutations now occur
inside their registered cleanup handlers. Full pressure qualification is running.
The fixed boot phase passes all four pressure attempts: 0, 1 KiB and 4 KiB
throw `OutMem` with cleared conditional flags and exact recovery, while 64 KiB
succeeds. All four attempts also pass in the task phase. The normal-console
regression passes 23 exact-VGA commands; the new guest compiler-provider rebuild
and full integration qualification remain active for this source.

### Next public task package: ownership through exit

The original failing contract is `tools/test-i386-public-tasks.py`. On the
public-delay image its lookup controls pass and `Spawn`/`Exit` fail. The
behavior branch is specified but cannot execute until those services exist;
its presence-only red result is not evidence of working task lifecycle.
The contract now also creates a task from inside a child while selecting the
root as its explicit parent, then requires root-based symbol inheritance and
child-ring membership. This distinguishes the chosen parent from the creator;
these behavior checks remain unexecuted while `Spawn` and `Exit` are absent.
The public contract also requires `TaskQueIns` and specifies deferred creation:
`Spawn(..., flags=0)` must leave scheduler links pointing to the task itself,
omit the parent's child ring and remain dormant through 20 yields. Explicit
`TaskQueIns` then activates it; entry return must reclaim its shared public-pool
allocations even though it was never inserted into the parent's child ring.
Deferred creation/activation also repeats 20 times, with exact public-pool
usage and reserved-capacity recovery required after each cycle. This is 43
behavior commands, all within the console limit. Private allocation recovery
and pending-task disposal still require separate oracles.
The compact-guard image reproduces the public presence baseline under 8 MiB
`486,-fpu` TCG: `MAlloc`, `Dir`, `Yield` and `Sleep` are present, while `Spawn`,
`Exit` and `TaskQueIns` are absent. The source disk is unchanged; none of the
43 behavior commands executed (`build/i386-creator-compact-owner32-public-tasks/result.json`).
The private `I386TaskSpawnFrom` helper now accepts a selected live parent and
clones its heap/file/symbol hooks without changing scheduler current. The
original `I386TaskSpawn` entry keeps its ABI and current-parent behavior.
Selected-parent heap pinning, failed construction rollback, finished-parent
rejection, deferred parent destruction and exact private/control-heap recovery
pass the native heap fixture; the legacy task corpus also passes. This does
not establish public child rings, creator-code retention or managed reaping.
Creator retention now has an observed failing-to-passing private contract:
when the chosen parent differs from current, the owned task retains current
until destruction. A returned creator cannot be reaped while its child is
alive; overflow rejects construction before allocation. Native heap, symbol
and legacy task fixtures pass with exact recovery. Public reaping and task
descriptor behavior remain open. The updated cross-built flat image is
484,704 bytes. Rebuilding all six flat modules inside the guest produced
488,680 bytes, exceeding the unchanged 487,424-byte boot region by 1,256 bytes.
The boot-image builder correctly rejected that image; this is not an install
pass (`build/i386-creator-pin-native-flat/capacity-result.json`).
Compact native creator validation now passes the heap, symbol and legacy
task fixtures plus their instruction audits. Two bootstrap generations also
pass (`build/i386-creator-compact-owner32-bootstrap.log`). The heap diagnostic
first isolated failed-construction rollback: the compact implementation released
a creator reference before acquiring it. Rollback checks the owned record's
creator field, which is set only when acquisition occurs. The next failure
exposed an eight-byte owner comparison in assembly where native pointers occupy
four bytes: the extra comparison read the adjacent `finished` field. Correcting
that comparison restores child destruction, with 14 heap reclamations and exact
recovery across selected-parent and creator-lifetime cases. Regression logs are
`build/i386-creator-compact-owner32-task-heaps.log`,
`build/i386-creator-compact-owner32-task-symbols.log` and
`build/i386-creator-compact-owner32-tasks.log`. These fixtures use the hosted
compiler's i386 backend; guest-frontend full-kernel size and execution still
require separate qualification. Public task implementation and latest-source
native generations remain pending.
The compact-guard guest rebuild completed all six flat modules, totaling
488,208 bytes. The boot-image builder returned zero: this reduces the prior
excess by 472 bytes but still exceeds the boot region by 784 bytes
(`build/i386-creator-compact-owner32-native-flat/capacity-result.json`). This
snapshot predates the scheduler preparation split below and is not an install
pass. Boot-region capacity remains a required architectural constraint.

The private scheduler now separates `I386SchedPrepare` from
`I386SchedActivate`. Preparation sets owner, identity, signature and control
sentinels but leaves public queue links pointing to the task itself; activation
attaches once without switching context. Existing `I386SchedAdd` keeps immediate
attachment under one interrupt-masked operation. The new fixture initially
failed compilation before these APIs existed; after implementation it passes
20 dormant yields, invalid/finished/malformed/repeated activation rejection,
IF preservation and completion/reaping across two reused-record cycles.
The heap and symbol fixtures also pass, and two bootstrap generations pass
(`build/i386-deferred-scheduler-bootstrap.log`,
`build/i386-deferred-scheduler-after.log`,
`build/i386-deferred-scheduler-task-heaps.log`,
`build/i386-deferred-scheduler-task-symbols.log`). The cross-built flat kernel
is 486,952 bytes and passes its boot/instruction audit. Normal 8 MiB no-FPU TCG
keyboard boot matches every VGA checkpoint in 48.084802 seconds, within the
60-second budget (`build/i386-deferred-scheduler-keyboard/result.json`).
Owned-task construction still uses immediate attachment; public deferred
`Spawn`, queue insertion, child rings, pending disposal and managed reaping
remain to be wired and qualified. Latest-source guest-built boot capacity
is not established by the cross-build or private fixture passes.
Native task guards and activation insertion now use compact assembly with
matching C implementations retained for other targets. The guards preserve
parent identity/owner checks, live-state checks, creator overflow handling,
destruction from another stack and one-time dormant-task activation. Size
validation rejects nonzero high words, negative and misaligned sizes, minimum
violations and total-allocation overflow. Both queue insertions remain under
the original IRQ mask and store task-base pointers, preserving private and
public ring membership.
The task fixture adds null-parent/scheduler, broken parent identity, finishing
parent and aligned/wider-than-32-bit allocation boundaries. Task, heap and
symbol fixtures pass with instruction audits, and two bootstrap generations
pass (`build/i386-task-compact-rings-bootstrap.log`,
`build/i386-task-compact-rings-tasks.log`,
`build/i386-task-compact-rings-heaps.log`,
`build/i386-task-compact-rings-symbols.log`). The cross-built image is 482,584
bytes, 4,368 bytes below the first scheduler-split image, with unchanged boot
capacity. Its normal 8 MiB no-FPU TCG boot matches every keyboard/VGA checkpoint
in 49.032234 seconds, passing the 60-second startup budget
(`build/i386-task-compact-rings-keyboard/result.json`). Its guest rebuild
rejected the first kernel module in `I386SchedActivate` at
`CMP EAX,TASK_SIGNATURE_VAL`: the native assembler accepted integer immediates
but omitted HolyC character constants. No native size or installation pass
was produced (`build/i386-task-compact-rings-native-flat/failure-result.json`).
The native operand parser now accepts `TK_CHAR_CONST` using the same integer
payload as HolyC expressions. A focused guest-compiler test reproduces the old
include failure, then passes after the fix: word/byte immediate stores and a
character-immediate comparison execute correctly, the older 270-NOP/rel32 case
still returns 41, and ordinary HolyC returns 42. All 20 console commands match
exact VGA at 8 MiB no-FPU TCG, with the source disk unchanged
(`build/i386-asm-char-before/result.json`,
`build/i386-asm-char-after/result.json`). Two bootstrap generations and the
cross-build audit pass; flat size remains 482,584 bytes. A fresh guest-native
rebuild/install passes in `build/i386-asm-char-native-flat`: all six flat modules
are guest-built, the 486,568-byte image fits with 856 bytes remaining, and the
installed image independently cold-boots at 8 MiB no-FPU KVM, returning 42 and
passing all 12 document-allocation checks. Its executable/boot audit passes
(`build/i386-asm-char-native-flat/result.json`,
`build/i386-asm-char-native-flat/instruction-audit/result.json`). Retained modules
remain cross-built development inputs; this does not qualify a guest-built
compiler provider, all-module self-hosting or two native generations. It also
predates the dormant owned-task constructor now under test.
The older creator-pin full integration run is terminal: it completed earlier
checks but failed while reading the final isolated install-copy result. Its
child checker used the hard-coded default build directory rather than the
selected `--out`. This is not a complete integration pass. The driver now
passes the chosen build directory to install-copy and the selected image and
output directory to document compatibility. The isolated checks pass on the
character-immediate-fix image: installation, independent target boot and both
interrupted-copy/retry boundaries preserve the input image and record its
exact hash (`build/i386-asm-char-kernel/install-copy/result.json`); original
TempleOS reproduces the native 37-byte document byte for byte, with an unchanged
input image (`build/i386-asm-char-kernel/doc-compat/result.json`). The full
integration run with corrected final-stage paths is active in
`build/i386-asm-char-integration`; it cannot yet be counted as a full pass.

Dormant owned construction is now available through `I386TaskCreateFrom`.
Its default leaves the descriptor, stack, private heap and inherited state
prepared without scheduler insertion. The existing `I386TaskSpawnFrom` and
`I386TaskSpawn` signatures retain immediate-queue behavior through the shared
constructor, including rollback and creator retention. The new fixture failed
compilation before the constructor existed, then passes 20 complete
create/20-yield-idle/activate/finish/destroy cycles with exact bootstrap-heap
recovery and alternating caller IF modes. The selected-parent heap fixture now
also leaves a child dormant while its selected parent returns: parent and
creator references remain held, parent destruction is deferred, and activation
followed by teardown recovers the original heaps and public pool.
The task, heap and symbol suites plus instruction audits pass, as do two
bootstrap generations (`build/i386-owned-deferred-bootstrap.log`,
`build/i386-owned-deferred-if-modes.log`,
`build/i386-owned-deferred-parent-heaps.log`,
`build/i386-owned-deferred-symbols.log`). The cross-built image is 483,408 bytes;
normal 8 MiB no-FPU TCG boot matches all keyboard/VGA checkpoints in 49.002025
seconds, within budget (`build/i386-owned-deferred-keyboard/result.json`).
All six current flat modules also rebuild in the guest, link, install and
independently cold-boot at 8 MiB no-FPU KVM. The 487,392-byte guest-built flat
image passes its 386 executable/boot audit and leaves only 32 bytes in the
487,424-byte boot region (`build/i386-owned-deferred-native-flat/result.json`,
`build/i386-owned-deferred-native-flat/instruction-audit/result.json`). Retained
modules are still cross-built inputs: all-module native rebuilding and two
current-source generations remain required. Never-activated disposal, public
metadata/child rings, service publication and managed reaping remain open.

**Placement of the next lifecycle work:** put public task policy in the retained
service layer, loaded after bootstrap, rather than adding it to the flat kernel.
Keep the boot-region limit and reserved stack unchanged. Provide a versioned,
validated callback interface to the existing create/activate/finish/destroy
primitives and bootstrap allocator; reject incomplete or mismatched bindings
before publication. The retained service owns task numbers, public descriptors,
child links and the managed registry, including tasks created without queue
insertion. Wire reaping from another live stack into the cooperative execution
path and prove never-activated disposal and construction rollback before
publishing `Spawn`, `Exit` and `TaskQueIns`. If this needs an additional module,
update the complete module list, installation/provenance checks and both native
generation gates together; a selected-module pass must not replace those gates.
The symbol/file fixture now also passes selection from root context of a
different live parent with its own `Shared` definition and `/Selected` directory
on drive D. It verifies inherited values, independent file state, parent pinning
through exit and exact arena recovery. Normal no-FPU boot of the updated
cross-built kernel passes exact VGA in 48.895514 seconds, within the boot budget.

1. **Create through the original public contract.** Keep `Spawn`'s original
   signature and defaults. Bind the single CPU's `Gs->seth_task` to its root,
   honor an explicit parent, name/title, requested/default stack, task number,
   signature and child/sibling links. Clone the selected parent's symbol chain
   and directory while giving the child its own public heaps. Separate native
   creation from queue insertion so flags without `JOBf_ADD_TO_QUE` retain
   their meaning; add the matching public queue/activation path. Reject
   unavailable CPU destinations explicitly. Failed creation must roll back
   allocations, references and queues and preserve caller IF.
2. **Retain every owner until it is safe to release.** Existing heap/symbol
   clone references protect the selected parent. Also retain the creator's
   compiled entry code when the selected parent is different. Do not change
   scheduler `current` to impersonate another parent during creation. Pass
   ownership through the private creation helper instead.
3. **Finish on one stack, reclaim on another.** Explicit `Exit` and entry
   return retire the task; another live task performs managed reaping. Respect active
   compiler controls, pending waits, file/symbol storage and lifetime refs.
   Remove public child links only when destruction is safe. Preserve original
   descendant termination semantics, and ensure a child's completion cannot
   leave its parent or creator permanently unreapable.
4. **Make the failing behavior branch pass.** The fixture covers explicit
   parent inheritance, distinct task heaps, copied directory, child-ring
   membership, task record/defaults, entry return, explicit exit without
   executing subsequent statements, and 20 repeated cycles with exact public
   pool recovery. Add independent bootstrap-allocation accounting to prove
   stack/control/node reclamation too; public pool counters do not cover it.
   Add creation-failure, nested-parent and unqueued/activation cases before
   claiming the full public task contract. Require exact VGA, a usable prompt,
   8 MiB no-FPU TCG and an unchanged input disk, then repeat with guest-built
   service code and the executable-region audit.
5. **Integrate multiple interactive terminals.** Once lifecycle works, replace
   singleton input/document/definition state with task-owned terminal state,
   route keyboard focus explicitly, and test two live terminals with separate
   definitions/documents and cooperative work. Window drawing tests alone do
   not establish this required workflow. Source-linked runtime debugging and
   full current-source two-generation release qualification remain separate
   required packages.

## Final goal: a fully working TempleOS on a PC-compatible machine

Deliver a standalone, self-hosting 32-bit TempleOS that a person can boot and use
as their complete offline HolyC development environment on the documented
QEMU PC profile with VGA and a 386-targeted instruction baseline. This is the final product milestone, M7; the current native
console and individual subsystem tests are intermediate evidence toward it.
"PC-compatible" means the reference hardware contract below, not the original
8088 IBM PC or every later PC configuration. Preserve the HolyC language, shared
ring-0 address space, cooperative tasks, executable DolDoc documents, graphics,
sound and on-machine development described in this plan.

M7 requires an integrated acceptance run with the following outcomes:

1. **Boot and operate independently.** Cold-boot a published hard-disk image through
   the machine's legacy BIOS into the normal interactive environment without a
   host compiler, attached test harness or mandatory diagnostic suite. Publish
   reproducible image preparation and boot instructions for the pinned QEMU profile.
2. **Use the original programming environment.** Navigate help and files; edit,
   compile, execute and debug HolyC; retain definitions; and recover from syntax
   errors, caught runtime exceptions and allocation failures. Exercise I64 and
   software F64 without a 387, public task/memory/file services, and cooperative
   work in multiple terminals. Debugging and exception inspection must be usable
   on the machine, rather than depend on host-only traces.
3. **Complete the document and device workflow.** Create and edit an executable
   DolDoc document with embedded graphics, execute it, save it to RedSea, reboot,
   reopen and execute it again. Verify planar VGA, keyboard, the selected supported
   mouse, and PC-speaker sound together with timer and disk activity. Check saved
   content and directory integrity across repeated cycles.
4. **Develop and rebuild on the machine.** Rebuild the native compiler and kernel
   from the delivered source inside the OS, install and boot those outputs, then
   repeat for a second generation. Record artifacts and explain output differences;
   x86-64 bootstrap rebuilds do not satisfy this requirement.
5. **Meet the vintage resource and compatibility gates.** Demonstrate the complete
   interactive workflow at 8 MiB installed RAM and native rebuilds at 16 MiB,
   reporting usable RAM, resident and peak allocations, boot/rebuild time and
   input latency. Exercise repeated compile/error/task-exit cycles to detect
   retained-memory growth. Establish responsiveness budgets on the recorded host
   and QEMU configuration. Pass QEMU no-FPU execution and executable-region 386
   instruction audits; record QEMU version, machine type, BIOS, CPU, RAM, storage
   and peripherals. Timings describe this emulator setup, not a physical 386.
6. **Publish a reviewable result.** Ship the boot image, matching source revision,
   build/boot instructions, support matrix, acceptance results and known limitations.
   Preserve the working x86-64 regression target. Remaining optional hardware and
   application work must be distinguished from failures of the required workflow.

M7 remains open until all required functional and resource outcomes are
demonstrated in QEMU. Physical hardware and strict SX/DX certification do not
block it; label the published support matrix as QEMU-verified. The existing deferrals for networking, modern devices and additional
installation media remain in force. Any change to required functionality or RAM
targets needs an explicit, evidence-backed plan revision.

## Architectural roadmap at a glance

The selected target is native 32-bit protected-mode HolyC on a 386+ PC with
standard VGA. There is no separate 16-bit application target. Preserve the
language, shared ring-0 address space, cooperative tasks, executable DolDoc
documents and on-machine development; change the CPU implementation and hardware
dependencies needed to make that environment practical on the smaller machine.

Use this sequence to prioritize remaining integration work. The detailed work
packages and historical component results below provide supporting context.

| Priority | Architectural deliverable | Completion gate |
| --- | --- | --- |
| 1 | Complete native compiler bindings and the public kernel contract. Validate intrinsic declarations separately from callable resident addresses; migrate task/CPU records and their ownership rules into shared public interfaces. | Ordinary HolyC sources use the public symbols and complete record layouts; rejected declarations and failed compilation preserve existing definitions and reclaim temporary state. |
| 2 | Close remaining ABI and native language gaps, including target layout, compile-time execution, assembly, numerical behavior and diagnostics. | Representative existing sources compile and execute natively with wide integers and software F64; cross-bootstrap and native results agree under a documented target policy. |
| 3 | Integrate the existing document/editor and drawing implementation over VGA, task input and persistent RedSea services. | Edit, execute, save, reboot and reopen an executable document, including embedded graphics, with measured peak memory at the 8 MiB interactive target. |
| 4 | Complete native compiler/kernel construction and installation of the resulting boot artifacts. | Rebuild on the 16 MiB target, boot the outputs and repeat; record memory use, elapsed time and output differences. |

For priority 1, keep the private bootstrap task/CPU records behind the kernel
boundary. Do not expose a shortened replacement for `CTask` or `CCPU` merely to
make `Fs` or `Gs` declarations compile. Inventory public fields and semantics,
define target layouts, then migrate exception, compiler, file and task-lifetime
state with one authoritative owner for each resource. Resolve forward class
identity and completion across compiler contexts before publishing headers that
depend on those identities.

Native intrinsic publication now distinguishes opcode-bearing declarations from
resident addresses and ordinary generated functions. The startup header exposes
38 original public intrinsic signatures (34 in Intrinsic.HH and four queue
operations in Queue.HH); the isolated intrinsic corpus covers 35 including
private FS/GS getters, and public-stack probes cover `GetRSP`. Pointer depth is checked separately from raw numeric type,
because `RT_PTR` and `RT_I64` share a value. This advances compiler binding, while
complete public task/CPU layouts remain required. See
[intrinsic publication](docs/i386-intrinsic-publication.md).

Native publication also accepts owned forward class declarations used through
pointers, and checks that incomplete types are not published as values or base
classes. Top-level class parsing now uses the same ownership-aware type callback
as nested declarations. Private forward declarations can be completed within one
input with pointer identity preserved. Completion across published inputs now
stages a private definition and commits into the stable descriptor in the owning
task scope, with rollback and nested-conflict checks. Native startup now loads the
shared public headers in a separate input with transactional include guards. See [class completion](docs/i386-class-completion.md) and
[opaque class dependencies](docs/i386-opaque-classes.md).

The complete public task/CPU records now live in shared headers used by
`KernelA.HH`, with the original x86-64 task member layout preserved. Cross-compiled
native fixtures validate the 992-byte `CTask` and 232-byte `CCPU`, including wide
state and callbacks. Live `CI386Task`/`CI386Cpu` now inherit those complete public
records, sharing exception, symbol and compiler-control fields while retaining
private scheduler extensions. Typed `Fs`/`Gs` now expose these complete records
through native public-header loading. This closes the header-loading slice only:
complete public service semantics remain part of the priority-1 gate, and private
ready queues remain distinct from public task links.
The original `CQue` record is now shared and loaded natively, with verified
16-byte x64 and 8-byte i386 layouts. All four queue intrinsics now preserve the
original link semantics, with shared x64/cross-generated/native execution tests.
Native #help_file metadata now preserves original path and source-link semantics,
with transactional publication and reclamation; see [help metadata](docs/i386-help-metadata.md).
The complete document/editor records now share Kernel/DocTypes.HH, preserving
all 131 original x64 fields and the 16-byte CDocBin saved span. The native CDoc
record is 680 bytes; explicit tail alignment retains original record-size
requirements. See [document records](docs/i386-document-records.md). Document
locking, lifecycle, palette constants and the actual editor/file workflow remain
source-driven integration work. Callable BEqu/LBEqu now use the original public
signatures and export names, with signed I64 bit addressing and audited locked
branches. Their shared original-x64/native corpus covers 168 vectors; this closes
the bit-assignment prerequisite for DocLock, while public Yield and pending-break
semantics remain required. See [bit assignment](docs/i386-bit-assignment.md).

The compatibility gate now runs both real implementations in both directions.
A 48-byte structured document produced by original x86-64 `DocSave` is packaged
unchanged into the native RedSea image and reproduced byte-for-byte by native
`DocRead`/`DocSave`. Native i386 also persists a 37-byte structured/binary
document to RedSea; an independent host walk transfers those exact bytes into an
original-system ISO, where original `DocRead` validates the live records and
original `DocSave` reproduces the file byte-for-byte. This closes the bounded
structured subset's bidirectional cross-reading gate; general DolDoc command
coverage remains part of the complete editor milestone.

The native disk now ships the original `Doc` tree and publishes a read-only
`Help(name)` viewer. It projects common DolDoc titles, links and menu labels to
VGA text, supports Page Up/Page Down, arrow paging and Home, and returns to the
same HolyC prompt without rewriting the source document. Left/Right selection
and Enter now follow direct `FI:`, `FF:` and `FL:` file links, with nested Escape
returning to the parent document and exact task-heap recovery. `MN:` links for
published native symbols resolve through their retained source metadata and open
the packaged source. `HI:` category links resolve through public retained
`#help_file` metadata and open a generated listing of matching packaged
documents and public source-linked symbols. Full DolDoc layout remains part of
the editor integration milestone.
`FL:` links, including those reached through `MN:`, begin at their recorded
one-based source line; `FF:` links begin at the requested text occurrence; and
`FA:` links map an invisible DolDoc anchor to its visible projection offset.
Native public task links now track attached live tasks, including blocked workers,
and detach before reaping. Native dispatch follows public list order, skipping
blocked, suspended and awaiting-message tasks. If none is eligible, it idles for
an IRQ, including when the root is suspended. Signed I64 wake deadlines now use
the same 1000-Hz-unit cnts.jiffies counter published to native HolyC. The PIT
retains its IRQ rate and accumulates fractional jiffies without per-tick rounding
loss; see [jiffy clock](docs/i386-jiffy-clock.md). Original message/job/popup
integration and pending-break delivery remain integration work.
The native queue component now maintains the public awaiting-message bit during
read/send/close, including flag waits without a private reader. It remains a
separately tested component; the interactive console uses direct keyboard input.
See [message wait flags](docs/i386-message-wait-flags.md).
Pending message reads now have explicit cancellation that preserves queued
messages and detaches the borrowed stack registration before resumption.
Coordinated pending-break delivery remains open. See
[message read cancellation](docs/i386-message-read-cancellation.md).
Raw keyboard read cancellation now preserves queued byte/status pairs and
decoder state, with the cancel callback in retained ConsoleRuntime rather than
the bootstrap core. See [keyboard read cancellation](docs/i386-keyboard-read-cancellation.md).
Sleep and join now publish task-owned wait registrations, and retained dispatch
can cancel either through the same entry while keeping the registration until
normal resumption. Task lifecycle guards prevent freeing a registered stack.
See [task wait registration](docs/i386-task-wait-registration.md). Queued ATA
acquisitions and message reads now register with the same dispatcher; see
[resource wait registration](docs/i386-resource-wait-registration.md). Raw-keyboard
waits now register as well, with task-context reading and decoding retained in
ConsoleRuntime; see [keyboard wait registration](docs/i386-keyboard-wait-registration.md).
An internal pending-break request/lock/checkpoint path now has native exception
coverage; see [pending-break checkpoints](docs/i386-pending-break-checkpoints.md).
Compiler input now checks pending requests inside its catch/unwind boundary; see
[compiler break cleanup](docs/i386-compiler-break-cleanup.md). Queued disk includes now have a compiler error-to-break cleanup path and an
end-to-end diagnostic; see [file break cleanup](docs/i386-file-break-cleanup.md).
IRQ-side Ctrl-Alt-C now requests a break for an active console submission; see
[keyboard break requests](docs/i386-keyboard-break-requests.md). Native JIT backward
branches now provide task-context break checkpoints: while, goto and do/while
loops can be interrupted, and a HolyC handler can catch the break and continue.
See [loop break checkpoints](docs/i386-loop-break-checkpoints.md). Non-returning
uninstrumented code, multi-task focus and original public Break delivery remain.
Original document locking now shares its ownership policy with native adapters:
contending waiters can yield and recover from a break, and an owner releases the
document before pending-break delivery. Retained DocLock/DocUnlock bindings are
available to native HolyC; see [document locks](docs/i386-document-locks.md).
Original DocPut/DocDisplay/DocBorder selection is now retained natively as well,
with shared original source and x64/native selection tests; see
[document selection](docs/i386-document-access.md).
Fixed document policy tables now have a shared initializer verified against the
original parser and a native/x64 table fingerprint; see
[document defaults](docs/i386-document-defaults.md). Native dictionaries and
full global initialization remain open alongside document creation,
rendering/editing and persistence.
Shared module lookup, heap checks and reclamation recovered 2112 bootstrap
bytes. After moving task-context keyboard reading and decoding into ConsoleRuntime,
25824 bytes of bootstrap headroom remain after document-lock bindings
(363296-byte kernel plus 4096-byte early stage). See [module lifecycle](docs/i386-bootstrap-module-lifecycle.md).
Keep additional interruption logic in retained services and measure scheduler-core
growth against this remaining space; preserve the reserved load area and validate
module lifetimes and rejection behavior.
Queued ATA acquisition cancellation is implemented as a prerequisite for
pending-break delivery: detach stack waiters before they resume, preserving
ownership, FIFO survivors and public wait state. Active transfers and the full
Break/unwind contract remain open. See [ATA wait cancellation](docs/i386-ata-wait-cancellation.md).
Sleep and join cancellation are implemented alongside that path. A cancelled
join must release its target pin and return without dereferencing a target that
may already have been reaped; completed joins and expired sleeps win over late
cancellation. See [sleep/join cancellation](docs/i386-sleep-join-cancellation.md).
See [task eligibility](docs/i386-task-eligibility.md).
See [public task ring](docs/i386-public-task-ring.md).
Native stack ownership now uses contiguous public `CTaskStk` descriptors for
spawned and boot tasks. Exception validation and caller walking read those bounds;
stack growth and the full saved-register/debugger contract remain unfinished.
See [stack ownership](docs/i386-public-stacks.md).
The original public memory records are also shared, with a native allocation
core using real `CBlkPool`/`CHeapCtrl` state. Task heap ownership now has native
lifecycle coverage: child construction, parent retention, rollback and teardown
after compiler/file/symbol cleanup. A retained memory service now binds the boot
root and inherited worker heaps and publishes the throwing allocation interface
through native public headers. Final generated executable buffers now carry
public task-heap ownership through compiler cleanup, publication and task reap;
compiler metadata and working buffers still use bootstrap arenas. Complete their
allocation policy and the remaining public memory services as the next
public-contract work. Shared public headers, including document records, callable
bit bindings, task flags and time counters, retain 179280 bytes of metadata. Profiling the complete document headers attributed most header/startup
samples to whole-chain bootstrap heap validation. An equivalent 386 assembly
loop, retaining every invariant, reduces normal QEMU/486 startup from 60.612 to
15.806 seconds and diagnostics from 726.823 to 137.386 seconds. The normal test
deadline is restored to 60 seconds. Differential corruption tests and the full
native suite pass; that optimization grew kernel reservation headroom from 184
to 2440 bytes. Live public task-ring maintenance and dispatch then left 208 bytes.
Moving KernelStorage's source/lexer diagnostics into the temporary probe frees
5736 resident bytes, leaving 5944 bytes for necessary resident additions. Task
flag eligibility and idle integration left 5000 bytes; the shared jiffy clock and
wake deadlines now leave 1128 bytes. The
same disk-read, character/line/hash and reclamation checks run in the boot probe;
ABI 13 rejects older probe modules before those checks. Keep substantial new
services in extended-memory modules; see
[storage diagnostics](docs/i386-storage-diagnostics.md).
See [heap performance](docs/i386-heap-performance.md), including the native
inline-assembly label-forwarding fix exposed by this work.

This does not close compiler allocation or editor responsiveness work. Before
loading the complete editor, measure allocator traversal counts and command,
failed-compilation and teardown latency in addition to boot samples. Migrate
compiler metadata/working storage with explicit ownership and logical-size
tracking, preserving corruption and rollback checks instead of substituting
public MSize capacity for requested size. Registered backing regions and a demand-growth provider now have native coverage, including return of wholly
unused regions to the bootstrap allocator. Task teardown now invokes the retained
provider after releasing heap controls; public free also notifies the provider
after finishing its page-header reads. See
[public memory](docs/i386-public-memory.md).
See [shared task records](docs/i386-task-records.md) and
[native public headers](docs/i386-public-headers.md).

QEMU acceptance runs alongside all four priorities: use the no-FPU profile,
verify emulated legacy BIOS/ATA paths and planar VGA, audit generated and
handwritten code for the 386 instruction baseline, and measure input response
under compilation and disk/display activity. Full public APIs, DolDoc and
self-hosting remain required; physical-machine acceptance is deferred.

### Next implementation slices

Use the following bounded changes to turn the roadmap into reviewable work.
Each slice must preserve the working x86-64 build and report native memory use.
The public-contract slices precede document integration; emulated-device validation can
advance independently throughout.

Drive those public-contract slices with the existing document sources. The
[DolDoc dependency inventory](docs/i386-doldoc-integration.md) identifies the
initial record, intrinsic, allocation, locking and file boundaries from
`MakeDoc.HC`, `DocNew.HC`, `DocBin.HC` and `DocFile.HC`. Integrate available
dependency groups incrementally; completing every unrelated public API is not a
prerequisite for starting this work. The complete public contract remains a final
acceptance requirement.

| Slice | Concrete change | Gate before proceeding |
| --- | --- | --- |
| Live task/CPU layout | Embed the complete shared public records in native task/CPU records; move exception and compiler state to those fields, preserving private scheduler extensions. Version modules whose field offsets change. | Boot and worker tasks observe the same records through segment bindings; task exit and exception recovery reclaim resources; incompatible modules are rejected before callbacks run. |
| Public header loading | Use transactional class completion to load the actual public headers through the native compiler. Publish typed `Fs`/`Gs` after their layouts and bindings agree. | Separate source submissions share class identity; failed completion preserves prior users; ordinary source reads live public task/CPU fields. |
| Public service ownership | Connect task lists, heap selection, compiler contexts and file lifetime to the existing public API. Specify initialization and teardown for every migrated field. | Task creation, compilation, file failure and task exit leave no dangling symbols, callbacks or owned allocations. A field's presence alone does not count as an implemented service. |
| Native language closure | Maintain a source-driven list of remaining blockers encountered when compiling the existing editor, documents and compiler. Resolve ABI, constant evaluation and assembly behavior in the shared implementation. | Representative existing sources compile and run with consistent cross-bootstrap/native results; every remaining blocker has a reproducer. |
| VGA document workflow | Connect existing drawing and DolDoc code to planar presentation, keyboard/mouse input and RedSea persistence. Bound display and disk work so interrupts and cooperative tasks remain responsive. | Edit, execute, save, reboot and reopen an executable document at the 8 MiB design target, with measured peak memory and input latency. |
| Native rebuild | Build compiler and kernel from source inside the resulting environment, install the generated boot artifacts and repeat the cycle. | Two native rebuild/reboot generations at the 16 MiB design target, with QEMU no-FPU execution and 386 instruction audits. |

Treat the RAM figures as acceptance targets pending full-workload measurements.
If the complete environment exceeds them, first identify retained versus temporary
allocations and unnecessary duplication. Any proposed change to the hardware
contract or HolyC/DolDoc behavior requires an explicit plan revision supported by
those measurements.

Public task-owned hash tables and list insertion now have retained native
bindings and shared original/native ownership tests; see
[public hash tables](docs/i386-public-hash-tables.md). Native definition-list
construction and expansion are also retained, with owned indices and allocation
failure cleanup; see [definition lists](docs/i386-define-lists.md). Original list
lookup/matching and definition lookup now have retained native bindings, with
alias/ambiguity, table inheritance/shadowing and missing-definition recovery
checks; see [definition lookup](docs/i386-definition-lookup.md). The existing
software F64 rounding/logarithm/power-of-ten helpers and original integer-multiple
operations now have retained public bindings; 4107 native numerical checks cover
this production path. See [public numerical providers](docs/i386-public-math.md).
Original calendar conversion and the writable time offset now have retained
native bindings, with 1333 checks covering signed dates, leap boundaries and
fractional time behavior; see [calendar conversion](docs/i386-date-conversion.md).
The formatter/document-save/recalculation dependency cycle still needs integration.
Original graphics device-context lifecycle, transform/lighting callbacks and
depth-buffer operations now have retained native bindings, with shared x64/native
ownership and arithmetic checks; see [graphics contexts](docs/i386-graphics-context.md).
Normal startup now creates the two working screen contexts and a retained VGA
conversion buffer. Native presentation preserves the original layering with
exact pixel and recovery checks; see [graphics frames](docs/i386-graphics-frame.md).
Original text borders, clipped rectangle fills, scroll save/restore and window
geometry now have retained native bindings. Startup initializes the real console
viewport; the original text-global record, fonts and border glyphs are shared.
See [window and text services](docs/i386-window-text.md). Original resizing,
control updates/hit testing and window visibility now also have retained native
providers, including callback failure cleanup and control lifetime checks; see
[window services](docs/i386-window-services.md). Sprite drawing, complete control
and window-manager integration, and full document layout remain required.
Native startup
now runs the original DocInit, with all 137 definition and 121 dictionary entries
verified; see [document initialization](docs/i386-document-initialization.md).
Original entry allocation/copy/size and form-navigation helpers now run natively
with shared x64 tests; see [document entries](docs/i386-document-entries.md).
Those document services now execute from retained ConsoleRuntime 15, reducing
normal startup from 41.141 to 19.067 seconds; see
[retained document services](docs/i386-retained-document-services.md).
Original entry insertion/deletion, binary lifetime/validation, soft-line removal
and undo cleanup now run through ConsoleRuntime 16, with visible literal
reporting and original/native lifetime tests; see
[entry lifetime](docs/i386-document-entry-lifetime.md). The four text-base write
primitives now have retained native bindings, checked against original x64
assembly; see [text base](docs/i386-text-base.md). The cell surface now has a
retained VGA presentation boundary, preserving the original text-layer attributes,
panning and glyph offsets. Twelve original-renderer frame comparisons and four
native VGA frames cover this boundary, including hardware-break restoration;
see [text rendering and manual demo](docs/i386-text-rendering.md).
Next are complete document construction/reset/delete,
general formatting, recalculation and editor callbacks, then editing and
persistence. These services do not yet provide an editable document.

### Next public-memory integration package

The boot environment now loads the retained backing provider and binds public
task heaps. The basic allocation interface and the document-facing `MemCpy`, `MemSet`,
`MAllocIdent`, `StrNew` and `StrCpy` bindings are implemented; complete their integration
gates before making the editor and compiler depend on public allocation services.
Use the complete shared `CHeapCtrl` and `CBlkPool` records; the bootstrap arena descriptor is not a public heap control.

1. **Define ownership and teardown.** A retained memory service owns backing
   regions; each task owns its heap controls and allocations. Specify whether
   `code_heap` and `data_heap` share a control on the flat i386 target, and destroy
   each distinct control exactly once. Initialize child memory state before task
   publication and unwind partial construction on failure. Reclaim task heaps
   only after compiler controls, file state and symbol references have drained.
   The existing task cleanup callback runs before compiler cleanup and is therefore
   too early for final heap destruction. Keep root resources alive for the kernel
   lifetime and retain service code while any callback can reach it.
2. **Publish the actual allocation contract.** Load the shared memory headers,
   preserving their help metadata, and bind current-task and explicit task/heap
   selection through the public interfaces. Implement allocation-failure
   exceptions with interrupt state restored, plus public free, size and aligned
   allocation behavior. Public size queries report capacity; bootstrap size
   queries report the exact request. Audit callers before migrating them instead
   of substituting one allocator for the other mechanically.
3. **Share scarce backing memory.** Add tracked backing regions and growth with
   explicit ownership of alignment padding and pool metadata. Avoid a permanent
   fixed public arena beside a separate compiler arena that strands free memory.
   Migrate compiler, generated-code and task allocations incrementally, preserving
   their required lifetimes. Normal interactive boot skips diagnostic probes.
   The separate diagnostic image retains all root/worker checks; its temporary
   worker uses a 512 KiB private compiler arena after the complete queue corpus
   demonstrated OutMem at 256 KiB. Explicit worker exit and reap must release
   it before the console starts; verify the returned bytes rather than assuming
   teardown occurs. This is test workspace, not the final compiler allocation
   policy. Measure fragmentation and latency before changing that policy. Account for fragmentation and cached
   pages as well as live payload; complete pool accounting and reclamation before claiming the
   8 MiB interactive target.
4. **Validate the integration boundary.** Version runtime modules when task
   extension layouts change. Exercise root and worker allocations, explicit heap
   selection, failed spawn, allocation failure during compilation, retained
   definitions after errors, and repeated task exit/reap. Verify incompatible
   modules are rejected before callbacks run, and that final reclamation restores
   the expected backing-memory totals. Preserve x86-64 layout and rebuild checks.

Completion means ordinary native HolyC can allocate through the public API and
survive compiler cleanup, with task-owned storage reclaimed at the correct final
lifetime boundary. It does not establish the full low-memory target: measure the
complete VGA document workflow at 8 MiB and native rebuilds at 16 MiB separately.
Keep QEMU no-FPU execution, VGA checks and 386 instruction audits alongside
this work. Physical VGA acceptance is deferred.

## Principles and deliberate amendments

Preserve:

- HolyC as the shell and implementation language, with on-machine editing,
  compilation, execution, debugging, and eventual compiler/kernel self-hosting.
- Kernel and applications sharing ring 0 and one flat address space. No process
  isolation, syscall boundary, or permissions framework.
- Direct function calls and accessible internals, memory, and I/O ports.
- DolDoc executable documents, embedded graphics, extended ASCII, and the 8×8 font.
- Software-rendered 640×480, 16-color VGA and simple PC-speaker sound.
- Offline operation, no guest networking, a small understandable core, and no
  third-party runtime libraries hidden underneath it.
- Existing cooperative task semantics and the explicit multicore programming
  model where the target actually provides multiple supported CPUs.

Amend the x86-64-only and mandatory multicore assumptions in `Doc/Charter.DD` for
this variant. A single-core 386 runs real cooperative tasks but cannot provide
parallel execution. Preserve the x86-64 multicore implementation; report one CPU
on the baseline i386 build and reject unsupported CPU selections clearly.

Do not turn `I64` into `I32`, remove floating-point semantics, replace HolyC with
C, or present an integer-only monitor as completion. Existing x86-64 machine code
will need recompilation; explicitly architecture-specific source needs porting.

## Reference hardware contract

These are design targets to verify, not measured minimum requirements:

| Component | Baseline decision |
| --- | --- |
| CPU | 80386 instruction set, 32-bit protected mode, one CPU; SX/DX certification deferred |
| RAM | Aim for an interactive system at 8 MiB and self-hosted rebuilds at 16 MiB installed RAM; usable RAM excludes firmware/device holes |
| Floating point | No coprocessor required: software F64 baseline; optional 387 acceleration later |
| Graphics | Standard planar VGA, BIOS mode 0x12, 640×480 and 16 colors; no VBE/GPU requirement |
| Firmware | Legacy PC BIOS; no dependency on UEFI, ACPI, PCI, E820, or extended INT 13h support |
| Interrupts/time | 8259 PIC, PIT, CMOS RTC; no APIC, HPET, or TSC requirement |
| Keyboard | AT-compatible keyboard controller; PS/2 mouse only where available |
| Mouse | Add a specific serial-mouse protocol for older machines lacking a PS/2 mouse port; keyboard must suffice for first bring-up |
| Storage | Legacy IDE/ATA PIO and a modest BIOS-CHS-compatible boot disk; RedSea filesystem |
| Boot image | Prebuilt hard-disk image first; BIOS CHS boot path required, extended reads optional |
| Sound | PC speaker through PIT, preserving the existing simple sound model |

The CPU baseline is not a promise to support every motherboard or peripheral
sold with a 386. Publish exact tested machine, BIOS, controller, VGA, and RAM
profiles. The 386SX physical-address limit also rules out treating large-memory
QEMU success as sufficient. Start emulator bring-up with more RAM if necessary,
but meeting the stated memory targets remains required work; any change to those
targets must be explicit and supported by measurements.

A full floppy driver, CD installation, additional storage controllers, and
physical installation tooling can follow the first hard-disk-image path.
Neither El Torito CD boot nor a large RAM disk may be a baseline dependency.

### QEMU acceptance now; physical verification deferred

QEMU is the functional acceptance platform. Pin its version, resolved machine
version, CPU flags, BIOS and VGA firmware hashes, RAM, storage geometry and
peripherals in build/test manifests. Use TCG, not host-CPU passthrough. The local
QEMU CPU list starts at 486 and has no 386 model: `486,-fpu` exercises the software
floating-point path but does not enforce every 80386 instruction restriction.

| Profile | Required evidence |
| --- | --- |
| QEMU/TCG `486,-fpu`, 8 MiB | Normal boot, complete HolyC/DolDoc workflow, VGA and input, emulated speaker/timer activity, writable-disk reboot persistence, failure recovery, memory and latency measurements. |
| QEMU/TCG `486,-fpu`, 16 MiB | Native compiler/kernel build, installation onto a fresh disk, boot and second native rebuild generation; peak memory and elapsed time. |
| QEMU/TCG later 32-bit CPU, explicit model | Regression of the same public behavior and saved formats; no host CPU dependency. |
| Existing x86-64 QEMU target | Preserve the original-system regression and source rebuild checks. |

The writable three-boot project workflow now passes on both `486,-fpu` and
`pentium3,-fpu` at 8 MiB. The tested configuration and the remaining limits
are recorded in `docs/i386-support-matrix.md`; this does not close the native
rebuild, resource or 386 instruction-audit gates.

Keep executable-region 386 instruction audits for boot code, runtime helpers,
cross-generated code, native JIT output and inline assembly. Combine these with
absent-FPU runs and forced legacy BIOS fallbacks; none alone proves universal
386 compatibility. Exercise missing optional BIOS calls, absent mouse, failed
I/O, low memory and timer wrap through automated tests.
The current i386 build audits the exact 16-bit BIOS and 32-bit protected-mode
boot ranges and classifies linked T32M code/data before applying its instruction
allowlist. Comprehensive live JIT output coverage remains open.

QEMU measurements set reproducible development budgets on a recorded host; do
not infer real 386 clock speed, device timing or electrical behavior from them.
Verify speaker programming and emulated audio output; physical audibility is
not required. A normal manual QEMU session still must demonstrate usability
without the automated harness or mandatory startup diagnostics.

Deferred follow-up: validated 386SX/DX emulator profiles, a named physical VGA PC,
real BIOS/controller quirks, speaker audibility and vintage-machine performance.
These remain future compatibility evidence, not M0–M7 completion requirements.
See [QEMU system emulation](https://www.qemu.org/docs/master/system/introduction.html)
and [TCG implementation](https://www.qemu.org/docs/master/devel/tcg.html).

## Architectural work packages

### Architectural assessment and review rules

The 32-bit target preserves the central programming model: a native HolyC system
with direct calls, ring-0 execution and a shared flat address space. VGA preserves
the existing logical display size and palette. The substantial architectural cost
lies in compiler and runtime semantics, bootstrap execution and memory use; it is
not primarily a display-driver project. Treat this as a native port with shared
subsystems, rather than a rewrite of the language or document environment.

Review each change against these decisions:

- Separate address width from value width. Audit pointer-bearing structures and
  interfaces individually; retain wide arithmetic, dates and floating-point
  values. Do not mechanically replace every eight-byte field or stack slot.
- Keep frontend grammar and user-visible behavior shared. Put target layout,
  calling conventions, instruction selection and relocation policy behind explicit
  compiler interfaces; keep bootstrap host execution distinguishable from native
  target execution.
- Keep platform mechanisms small: boot, context/interrupt state, timing, device
  transfers and VGA presentation. Shared task, file, document and drawing behavior
  should use the established public interfaces as bootstrap services mature.
- Make ownership and resource limits architectural contracts. Specify which task
  or module retains generated code, globals and callbacks, and how failed
  compilation unwinds. Measure complete interactive and rebuild workloads against
  the RAM targets before choosing caches or eager startup work.
- Require end-to-end evidence at integration boundaries: native source input,
  compilation, execution, recovery and persistence, followed by the document
  workflow and native rebuild. Keep 386 instruction audits, QEMU no-FPU execution
  and x86-64 regression evidence alongside these gates.

There is no separate 16-bit application port in this plan. Firmware-facing real
mode remains a bootstrap concern. Optional newer hardware acceleration must not
change the baseline ABI or become necessary for the complete HolyC environment.

### Architecture decisions to validate early

The CPU and display targets are settled: 32-bit 386+ and standard VGA. Keep
implementation choices that affect the full environment subject to executable
evidence. Prioritize the following risks before expanding peripheral support:

| Risk | Architectural work | Evidence needed |
| --- | --- | --- |
| A working prompt hides incompatible language behavior | Drive ABI and compiler closure from existing compiler, editor and DolDoc sources. Track each unsupported construct with a small reproducer and its dependent subsystem. | Cross-bootstrap and native execution agree; wide arithmetic, callbacks, exceptions and compile-time execution work beyond isolated expressions. |
| Private bootstrap services become a second application API | Complete public task, memory, file and compiler ownership contracts, then migrate callers incrementally. Retain private mechanisms only behind those contracts. | Existing HolyC source uses the public interfaces; failed compilation and task teardown reclaim storage without invalidating retained definitions. |
| Separate arenas and resident copies exhaust vintage RAM | Account for retained modules, compiler scratch space, generated code, task stacks, documents, display buffers and allocator fragmentation together. Release temporary modules and share backing memory where lifetimes permit. | Measure peak use during edit/execute/save and rebuild workloads, including failure recovery; an idle boot measurement does not establish either RAM target. |
| VGA output works but interactive documents are too slow | Preserve logical drawing semantics and bound planar presentation work. Measure dirty-region updates, compiler scheduling points and disk transfer batches before choosing optimizations. | Input remains usable during document redraw, compilation and disk activity on the named acceptance profile; record latency and workload rather than emulator wall time alone. |
| Development hardware conceals a later CPU or firmware dependency | Run QEMU without an FPU and audit 386 instructions while public services are integrated. Audit executable regions and exercise legacy firmware fallbacks on every affected change. | Boot and generated-code tests pass on that profile before full document integration is declared complete; physical-machine acceptance is deferred. |

The next implementation package remains the retained public-memory service
described above. Follow it with a source-driven compiler/API gap inventory for
the existing document and editor code, rather than another standalone feature
demonstration. Keep a dependency list that connects each gap to the first blocked
end-to-end workflow. Hardware-profile validation can proceed independently and
must not wait until native self-hosting.

### Implementation boundaries

Organize the port around these concrete boundaries. Keep shared behavior in the
existing implementation and isolate changes that depend on pointer width, CPU
instructions or PC hardware. Extract shared helpers incrementally as native
integration needs them; avoid maintaining a second reduced compiler or desktop.

| Boundary | Shared responsibility | i386 responsibility |
| --- | --- | --- |
| HolyC frontend | Language grammar, preprocessing, symbols and diagnostics | Target layout queries and native input/allocation services; compiler-host evaluation must remain explicit during bootstrap |
| Code generation and modules | Language operations, symbol binding and module lifetime rules | Register-pair I64 operations, software F64, 32-bit ABI, instruction selection and relocations |
| Kernel services | Public task, allocation, file and exception semantics | Protected-mode entry, context switching, FS/GS binding, interrupt delivery and physical memory accounting |
| Documents and graphics | DolDoc, editor behavior, drawing coordinates, palette and font | VGA presentation and keyboard/mouse delivery through small concrete interfaces |
| Persistent data | RedSea, compression and document-format contracts | ATA transfers, bounded buffers and checked conversion from disk offsets to native addresses |

Use the existing `Compiler/I386` and `Kernel/I386` implementations for target
mechanisms. Their private bootstrap records and explicit-heap helpers must connect
to the public TempleOS interfaces as integration proceeds. Do not propagate a
parallel task, file or allocation API throughout applications merely because it
was convenient for isolated bring-up.

Keep three distinctions visible in reviews: numeric width versus pointer width,
compiler-host execution versus target execution, and logical graphics versus VGA
memory access. These determine where architecture-specific work belongs without
changing the user-facing programming model.

### Scope decision: preserve the programming model on a smaller machine

Use native 32-bit protected mode as the architectural baseline. Keep the flat
address space and direct-call programming model; do not introduce segmented
application pointers or a parallel 16-bit application ABI. Treat VGA presentation
as a separate hardware boundary, so drawing and DolDoc code retain their existing
coordinates and color semantics.

The 16-bit portion is limited to firmware-facing bootstrap code before the
protected-mode handoff. The kernel, native compiler and applications use the
32-bit ABI. “386+” sets the minimum instruction set, rather than permitting
unconditional use of instructions from later 32-bit processors. Standard VGA
must remain sufficient for the complete document/editor environment, not only
the boot console.

The implementation order is ABI and compiler support, kernel services, resident
HolyC compilation and recovery, then the complete document/editor workflow and
self-hosting. Establish QEMU no-FPU profiles, 386 instruction audits and memory measurements alongside
these stages. Each stage must preserve the shared language semantics and keep the
x86-64 regression target usable; a bootable console is an intermediate result.

### A. Establish a trustworthy bootstrap and regression baseline

Relevant code: `tools/build-iso.py`, `tools/verify-iso.py`, `Misc/DoDistro.HC`,
`Adam/Opt/Boot/BootDVDIns.HC`, and the archived compiler/kernel binaries.

- Rebuild compiler and kernel inside the working x86-64 guest and boot the result.
  Resolve source/binary mismatches before using this as the cross-build host.
- Verify save/restart persistence, representative graphics/audio, and multicore
  jobs. Record artifacts and procedures rather than relying on screenshots alone.
- Inventory architecture assumptions: inline assembly, intrinsic instructions,
  eight-byte pointers/stack slots, pointer casts, code generation, serialized
  structures, fixed memory allocations, and eager startup scans.
- Record source revision and bootstrap binary hashes for every generated image.

Acceptance: a repeatable source-to-rebuilt-x86-64-guest cycle and a bounded
regression suite. Existing successful packaging is not a rebuild test.

### B. Define the i386 data model and ABI before changing the backend

Relevant code: `Kernel/KernelA.HH`, `Compiler/CompilerA.HH`, `Compiler/PrsLib.HC`,
`Compiler/PrsExp.HC`, `Compiler/PrsStmt.HC`, and `Compiler/CMain.HC`.

- Pointers and function pointers are 32 bits on i386 and remain 64 bits on x86-64.
  Explicit `I8` through `I64`, `U8` through `U64`, `F64`, and `CDate` retain their
  documented widths and meaning on both architectures.
- Introduce a minimal pair of signed/unsigned pointer-width aliases (proposed
  names `IPtr`/`UPtr`). Use them for addresses, pointer differences, and appropriate
  memory sizes, not as a blanket replacement for numeric I64 values.
- Specify pointer/integer conversions, sign extension, pointer comparisons,
  overflow checks, and interfaces using negative sentinel values. Audit the
  current signed `RT_PTR` convention and `TaskValidate` address checks explicitly.
- Write an ABI document covering argument order, stack cleanup, default arguments,
  variadic formatting, aggregate layout/returns, callbacks, exception unwinding,
  inline assembly, and stack alignment. Proposed baseline: 4-byte stack alignment,
  EAX for 32-bit scalar returns, EDX:EAX for 64-bit scalar and F64 bit-pattern
  returns, and explicit hidden storage for aggregate returns. Resolve the remaining
  call rules against HolyC behavior before freezing the ABI.
- Use the same software/hardware floating-point calling convention. Do not allow
  an optional coprocessor to silently change interfaces between modules.
- Separate compiler-host structures from target layouts: target `sizeof`,
  `offset`, pointer width, stack slots, and relocations must not use the width of
  the running x86-64 compiler accidentally.

Acceptance: executable layout/calling-convention tests covering mixed-width
arguments, callbacks, variadics, aggregates, signedness, pointer conversions,
and exception paths. Include arithmetic beyond 32 bits; `6*7` alone is inadequate.

### C. Add a real 386 compiler backend and numerical runtime

Relevant code: `Compiler/Back*.HC`, `Compiler/Asm*.HC`, `Compiler/UAsm.HC`,
`Compiler/OpCodes.DD`, and kernel compiler-facing intrinsics.

- Retain the shared lexer, parser, and architecture-independent optimization
  where practical. Select explicit x86-64 or i386 target data/code generation.
  Keep a simple correct backend first; measure before adding optimizations.
- Implement 32-bit register allocation, addressing, prologues/epilogues, calls,
  relocation emission, and debug/disassembly support. Existing REX, R8–R15, and
  RIP-relative assumptions require replacement, not just `USE32` directives.
- Lower I64/U64 operations to register pairs and small in-tree helpers, including
  multiplication, division/remainder, shifts, comparisons, and conversions.
- Implement software F64 arithmetic, comparisons, conversions, formatting, and
  required math operations without relying on an x87 unit. Define and test
  rounding, exceptional values, signed zero, and conversion behavior. Preserve
  HolyC-visible semantics; document any existing implementation quirks explicitly.
- Optional 387 execution comes only after software operation works. Use
  386/387-compatible instructions and save/restore conventions; no FXSAVE or
  newer floating-point opcodes. Define precision behavior across both paths.
- Enforce the 386 instruction baseline in generated code and handwritten runtime
  assembly. No unconditional CPUID, RDTSC, CMOV, CMPXCHG, XADD, BSWAP, INVLPG,
  MMX/SSE, or other later instructions. Keep verified optional paths isolated.
- Preserve the HolyC inline assembler, with target-aware diagnostics for 64-bit
  registers/instructions in an i386 compilation.

Acceptance: a compiler-generated arithmetic/ABI corpus passes in a 32-bit guest,
including I64/U64 and F64 cases without a coprocessor. Instruction validation must
check executable regions, not interpret embedded data as instructions.

### D. Solve cross-compilation and compile-time execution explicitly

HolyC executes code while compiling (`#exe`, generated source, top-level code),
so adding a code emitter alone does not produce a usable cross-compiler.

- Build an i386 cross-compiler running inside the working x86-64 TempleOS guest.
  Keep target layouts distinct from host pointers, compiler objects, and buffers.
- Run compiler-host generators as host code, exposing explicit target-layout
  queries. Audit generators using host `sizeof` or raw structure copies.
- Code that depends on target execution must run in a separate i386 bootstrap
  guest or be refactored into a clearly host-side generator. Never call freshly
  emitted i386 code as though it were x86-64 code in the host address space.
- Design the staging boundary for AOT kernel/compiler construction versus JIT
  shell execution. An early small target runner may be needed to execute target
  generation steps before the full graphical environment exists.
- Produce the first i386 kernel, runtime, and native HolyC compiler from this
  pipeline; then rebuild compiler/kernel inside i386 and boot those outputs.
- Compare a subsequent rebuild after controlling timestamps and other known
  nondeterminism; record any remaining differences.

Acceptance: x86-64-to-i386 bootstrap followed by a native i386 self-hosted rebuild
and boot. Linux/NASM image/loader tools may bootstrap packaging, but must not
replace the native HolyC compiler as the final programming environment.

### E. Add the protected-mode kernel platform implementation

Relevant code: `Kernel/KStart16.HC`, `Kernel/KStart32.HC`, `Kernel/KStart64.HC`,
`Kernel/Mem/*`, `Kernel/Sched.HC`, `Kernel/KTask.HC`, `Kernel/KExcept.HC`,
`Kernel/KMisc.HC`, `Kernel/KUtils.HC`, and `Kernel/MultiProc.HC`.

- Add an i386 entry path: BIOS setup, A20 enable with legacy fallback, conservative
  memory discovery, GDT/IDT, and transition to 32-bit protected mode. Collect BIOS
  data before leaving real mode; do not assume modern memory-map services.
- Use flat code/data segments and paging disabled initially. Addresses then have
  the identity relationship without page-table overhead. Preserve a route for
  386-style 4 KiB identity paging only if a concrete requirement needs it; no
  PAE, long-mode tables, large pages, or uncached aliases above 4 GiB.
- Reserve firmware/VGA holes and boot structures explicitly. Account for usable
  physical RAM independently of the 32-bit linear address space.
- Adapt FS/GS current-task/current-CPU access with protected-mode descriptors;
  use one CPU record on the baseline. Audit descriptor reloads and interrupt
  entry/exit rather than assuming x86-64 segment-base mechanisms.
- Implement task context save/restore, exception frames, debug breakpoints,
  unwinding, and cooperative scheduling for 32-bit registers and stacks.
- Use PIC/PIT/RTC services for interrupts and time. Replace TSC calibration and
  delay assumptions; verify device timeouts on slow and fast supported CPUs.
- Audit lock primitives and shared 64-bit updates. On the single CPU, short
  interrupt-masked sections can protect compound operations; yielding is forbidden
  within them. Preserve separate genuine multicore implementations on x86-64.
- Keep software F64 state per task where needed. Add optional coprocessor context
  handling only with the corresponding tested numerical path.

Acceptance: boot, interrupt handling, allocator checks, two cooperative tasks,
exceptions/debug recovery, and timer behavior on the selected 386 profile.

### F. Keep hardware support small and explicitly vintage-compatible

Relevant code: `Adam/Gr/*`, `Kernel/KEnd.HC`, `Kernel/SerialDev/*`,
`Kernel/BlkDev/*`, and `Adam/Opt/Boot/*`.

- Retain software drawing and the logical framebuffer. Adapt the existing planar
  VGA upload path using byte/word/dword operations; CPU width must not change
  palette, pixel format, or application coordinates.
- Separate a few concrete operations for boot data, VGA presentation, input,
  block reads/writes, and time. Use compile-time platform selection where possible;
  avoid a generic plugin/device framework or wholesale source-tree rewrite.
- Bring up the AT keyboard, then PS/2 and serial mouse implementations against
  named device profiles. Preserve mouse-driven DolDoc workflows in the full target.
- Add a legacy hard-disk boot image writer and CHS loader. Load kernel stages in
  bounded chunks, respect BIOS transfer boundaries, and keep bootstrap data in
  BIOS-addressable disk regions. Hand off to a protected-mode ATA PIO driver;
  do not require BIOS calls for ongoing filesystem access.
- Test the selected ATA CHS/LBA capabilities explicitly. Avoid assuming PCI
  discovery or that every vintage IDE drive has the same addressing features.
- Access RedSea directly on disk and load data on demand. Do not stage the full
  distribution in RAM. Guest installation and persistent editing must work.
- Test PC-speaker audio against PIT scheduling and software-F64 performance.

Acceptance: a bootable hard-disk image with VGA, keyboard/mouse interaction,
persistent RedSea access, and simple sound on the reference machine profile.

### G. Preserve file formats while changing in-memory layouts

Relevant code: `Kernel/KernelA.HH` (`CBinFile`, `CDirEntry`, `CDate`, `CDocBin`),
`Kernel/BlkDev/FileSysRedSea.HC`, `Adam/DolDoc/DocFile.HC`, and graphics serializers.

- Keep fixed-width RedSea metadata, dates, compression, and DolDoc data portable.
  Audit all serializers for raw in-memory pointer/layout dependencies; use explicit
  disk records or conversion where necessary. Do not assume every sprite or
  graphics record is already independent of machine layout.
- Keep 64-bit disk sizes/offsets where encoded, with checked narrowing for target
  buffers and addresses. Reject allocations/files too large for available memory.
- Define an unambiguous i386 module/ABI identifier and relocation rules. Preserve
  legacy x86-64 loading; reject wrong-target binaries before executing them.
- Regenerate compiler maps and architecture-specific generated data. Preserve
  binary tails byte for byte when editing mixed text/binary sources.
- Separate architecture-specific modules from shareable source/data in the image
  layout and prevent target artifacts from overwriting the bootstrap binaries.

Acceptance: cross-target RedSea/DolDoc round trips, compression fixtures, image
verification, and clean wrong-architecture module rejection.

Compression records are now shared, preserving the 17-byte disk header while
using native-width in-memory pointers. A native dictionary allocator matches the
original x64 assembly across 40000 growth/reuse updates, including occupied-slot
skips and chain unlinking. It remains outside the bootstrap. Owned native controls and expansion stacks now share initialization with x64,
preserve interrupt state and reclaim partial allocations. The original stream-expansion loop now runs through architecture-specific bit
readers and dictionary callbacks. Native full/incremental output and input
resumption match six original-compressor fixtures, including dictionary reuse.
Owned whole-archive expansion now validates sizes/types and codes before decoding,
reclaims failed allocations and matches original-compressor fixtures. Volume-scoped
file loading now tries exact/toggled names, derives attributes from the resolved
leaf and returns decoded owned bytes. Optional parent search preserves local
exact/alternate precedence followed by exact ancestors before alternate ancestors;
directory candidates are skipped and cyclic parent walks terminate. Task paths,
resident records and public file/include integration remain required; see `docs/i386-compression.md`,
`docs/i386-arc-expand.md`, `docs/i386-expand-buffer.md` and `docs/i386-file-load.md`.

### H. Meet the memory budget and recover the complete user workflow

- Measure resident kernel/compiler code, heaps, stacks, symbol tables, documents,
  framebuffers, caches, and peak compile-time allocation separately.
- Make startup scans and autocomplete dictionaries lazy/bounded; retain the full
  data on disk. Size stacks, caches, and graphics buffers from concrete needs.
- Avoid duplicating expanded sources and intermediate compiler representations;
  reclaim temporary compilation memory between jobs.
- Retain editing, help, executable documents, graphics, and debugging in the
  low-memory system. Optional content loading is acceptable; silently deleting
  these capabilities to meet a boot-only benchmark is not.
- Exercise repeated compile/edit/run cycles and graceful allocation failure.
  Report time-to-prompt, memory peaks, and compilation times on the reference CPU.

Acceptance: the interactive workflow at the 8 MiB design target, and compiler/
kernel self-hosting at 16 MiB, with no full-image RAM disk or hidden host compiler.

## Milestones and dependency order

### Integration priorities for the 386+ VGA target

Treat the remaining work as an integration sequence, with component tests as
prerequisites rather than substitutes for a working OS:

1. Freeze the implemented i386 ABI and keep compiler-host evaluation separate
   from target execution. Migrate the remaining bootstrap assembly through the
   HolyC assembler, preserving instruction audits and x86-64 rebuild checks.
2. Connect the production boot path, memory map, task/CPU records, exception
   services and resident exports. Bring up disk-backed loading, keyboard input
   and VGA together in one persistent kernel image.
3. Make the compiler resident on i386: complete the required language/runtime
   dependencies, compile-time execution, numerical operations and formatting,
   then demonstrate repeated native shell compile/run/recover cycles.
4. Integrate DolDoc, editing, help, mouse and speaker sound over the same kernel
   services. Measure resident and peak memory against the 8 MiB interactive
   target throughout integration, including allocation-failure recovery.
5. Rebuild and boot the compiler/kernel on the 16 MiB target, then close the
   QEMU no-coprocessor and 386 instruction-audit gates. Use that profile throughout
   the preceding stages; strict SX/DX certification is deferred.

Keep shared language, document and filesystem code above small architecture
boundaries. CPU register width must not change I64/F64 semantics, serialized
formats or the 640×480 application coordinate space. Native JIT and self-hosting
remain required outcomes of this sequence.

### Remaining architecture decisions and integration gates

The current foundation already connects BIOS boot, cooperative tasks, timer
interrupts, disk-backed module loading, keyboard line collection and VGA. The
resident HolyC compiler consumes startup and prompt source and produces executable
i386 code. Build on that path to complete public services and language coverage;
the table below describes integration requirements, some already demonstrated by
the component evidence, rather than a new compiler bring-up from scratch.

| Order | Architectural work | Required integration evidence |
| --- | --- | --- |
| 1 | Finish the compiler-facing kernel contract: public task/CPU records, task/code heap selection, allocation failure, file access, exception reporting, and compiler-control construction/destruction. Keep direct calls and explicit ownership; use the existing retained-module loader. | Create and destroy compiler contexts from a running task; recover from allocation and input failures with temporary allocations reclaimed and resident symbols/code still live. |
| 2 | Complete shared lexical dispatch, identifiers, character constants, operators/comments, macros/directives, and document/prompt input. Connect the parser and symbol lifecycle to these services instead of maintaining a second reduced language. | Tokenize and parse representative existing HolyC sources natively, including includes, save/restore and diagnostics; compare shared behavior with x86-64 fixtures. |
| 3 | Close target-layout and numerical evaluation gaps before native code generation becomes the shell path. Specify unfinished aggregate call/return behavior, address-bearing initialization, and target F64 literal/constant evaluation. | Cross-generated and natively generated i386 programs agree on target layouts and the selected numerical policy, including fractional literals and constant expressions. Record intentional differences from x86-64 separately. |
| 4 | Load the parser/backend and their dependencies into extended memory, then connect native JIT, inline assembly, top-level execution and compile-time generators. Keep compiler-host generators separate during cross-bootstrap. | Repeatedly compile, execute and recover from errors on i386 without a host compiler; exercise I64, F64, callbacks, globals and `#exe`, with measured transient reclamation. |
| 5 | Connect that same command/compiler path to DolDoc, editing/help, software graphics, mouse input, persistent files and speaker audio. | Edit, save, reboot, reopen and execute a document on the 8 MiB target; measure resident and peak memory during the whole workflow. |
| 6 | Rebuild compiler and kernel through the native environment and boot their outputs. | Complete and repeat the rebuild on the 16 MiB target, recording artifacts, peak memory and explained output differences. |

Orders 1–3 may advance together where their dependencies permit, but a raw token
scanner or a separately tested code emitter does not satisfy order 4. The existing
compiler-runtime service table is a versioned bootstrap boundary, not a replacement
for HolyC's public symbols and direct-call programming model. Define ownership of
new code, data, callbacks and compiler contexts before publishing them; retaining
the compiler at boot is acceptable while arbitrary module unloading stays deferred.

Keep three checks running across every integration gate: the x86-64 rebuild
regression, executable-region 386 instruction audits, and resident/peak memory
accounting. Apply QEMU no-FPU and legacy BIOS/device checks as work lands.
QEMU/486 is the current execution acceptance profile; strict SX/DX certification
is deferred.

The largest semantic decision still open is target numerical evaluation: the
native software policy and existing x86-64 literal parsing have recorded bit
differences. Resolve the cross-build/native boundary explicitly rather than
letting the compiler host choose i386 constants accidentally. The largest resource
question is peak memory during native compilation and document editing; measure
it before expanding startup scans or caches. Neither issue authorizes reducing
HolyC functionality or silently raising the stated hardware requirements.

### Immediate integration work after RedSea startup

#### Next bounded work package: source files to a live compiler context

Complete the file/input portion of integration gate 1 before adding more isolated
compiler services. The native volume reader, decompressor and ancestor lookup
are prerequisites; applications must ultimately use the public HolyC file and
compiler interfaces through their current task.

- Extract the original `DirNameAbs` and `FileNameAbs` string behavior behind
  explicit current-drive, current-directory, boot-drive and home-directory inputs.
  Keep task lookup in the public wrappers. Capture x86-64 behavior first,
  including drive prefixes, repeated separators, parent/home components, control
  characters and the distinction between a directory and a final filename.
  Do not replace these rules with a new path syntax during the port.
- Connect absolute names to the selected drive/volume, default extensions,
  resident-file handling and the existing exact/alternate/ancestor lookup order.
  Keep disk offsets 64-bit and check buffer/address conversions. Define how
  missing files, malformed archives, I/O errors and allocation failures reach
  the public exception interface without changing lookup precedence.
- Serialize access to each ATA channel under the cooperative scheduler. The
  current polling reader requires interrupts disabled; measure its worst-case
  service time and introduce task-owned requests or bounded transfers before
  using it for interactive compiler input. Do not yield while holding an
  interrupt-masked hardware transaction or let another task interleave commands.
  Implement this in four steps: (1) a canonical FIFO ownership gate shared by
  both drives on a channel, with task-lifetime protection; (2) a transaction
  adapter that retains ownership across bounded polling/yields and handles
  timeout recovery or channel poisoning; (3) route RedSea and retained file
  services through the adapter with explicit boot/root and task behavior;
  (4) verify competing readers, timer/keyboard progress, error recovery and
  latency before enabling interactive compiler reads. Gate tests alone do not
  satisfy the disk-access acceptance criteria.
- Transfer each successfully loaded source buffer into its lexer file record
  once. Specify ownership of the resolved name, source bytes, resident records,
  include stack and saved lexer positions. On failure, leave the active input
  unchanged; on EOF or compiler-context destruction, reclaim owned temporary
  data while retaining borrowed and resident data for their declared lifetime.
- Package these dependencies with the resident compiler services in extended
  memory. Keep the fixed low-memory bootstrap bounded, and expose the public
  compiler/file symbols through the existing module binding path. Avoid growing
  a second application-facing API around the private explicit-heap helpers.

Acceptance: a running native task creates a compiler context, resolves and loads
nested plain/compressed includes through public interfaces, and destroys that
context with measured reclamation. Exercise relative and absolute names,
parent lookup, missing files, corrupt input, allocation failure and interrupted
compilation. Verify independent current directories in two cooperative tasks,
continued timer/keyboard service during reads, and unchanged resident symbols.
Record resident/peak memory on the 8 MiB development profile, run the x86-64
behavior regression and audit executable code for the 386 baseline. Passing
this package enables parser/JIT integration; it does not establish a working
HolyC shell or strict 386 hardware compatibility.

The FIFO channel gate and task transaction adapter now pass real-task contention,
interrupt-state, task-lifetime and two-drive LBA/CHS tests. The adapter retains
ownership across polling/yields and PIO completion; timer/keyboard IRQs continue.
A touched failure poisons the channel, drains queued requests without I/O and
requires reboot. Argument failures leave it usable. RedSea now supports a
complete-operation session, shared across both drives, so metadata/data operations
cannot interleave between sectors. Retained FileRuntime binds the mounted volume
before task startup; native task includes use this path. Reset/recovery, measured
latency and the public interactive compiler acceptance above remain required.
See `docs/i386-redsea-tasks.md` for contracts and verification limits.

The path-string extraction now passes 44 original x64 cases on both targets,
with native owned-buffer and allocation-failure checks. Explicit-context helpers
are retained in FileRuntime; public current-task/drive binding and the remaining
file/compiler integration above are still required. See `docs/i386-file-paths.md`.

An explicit drive-to-volume reader now connects these path rules to decoded
RedSea loading. The compiler file-input bridge adds HC.Z, preserves the original
two normalization steps and transfers loaded bytes into owned include records.
Two-volume and nested-input tests cover routing, replay, I/O/allocation failures
and reclamation. These IF-clear services now manage bound volume sessions and
allow task switches at ATA polling points. Public current-task binding and
resident-file semantics remain; see `docs/i386-file-context.md`.

Native include dispatch now accepts an explicit synchronous provider and preserves
that binding across recursive token reads and conditional scans. Eight original
x64 include scenarios match native execution; disk-adapter ownership/I/O checks
also pass. Version 10 of the retained compiler table now publishes the include
entry; boot/task callbacks verify relocated execution and reclamation. The disk
provider is packaged in retained FileRuntime with task-owned volume sessions;
public task/file integration remains a gate.
See `docs/i386-lex-includes.md`.

The retained lexer now consumes nested plain/compressed disk includes, restores
parent input after an archive error and reclaims temporary source/codec state.
FileRuntime now has a checked version-3 interface and kernel-lifetime ownership.
Boot/task reads and nested includes use owned current-task directory state; workers
inherit directory/drive values and require bound volume sessions. The wrappers
preserve caller IF, including enabled-IF reads and nested includes.
The bootstrap plus loaded stage now leaves 1720 bytes in the fixed reservation,
so further low-memory growth requires extraction or reduction. See
`docs/i386-file-runtime.md` for evidence and remaining integration work.

#### Next architectural seam: task-owned file and compiler state

Complete current-task binding before expanding the resident compiler API. The
public task record already carries a current drive and directory; native
bootstrap helpers must implement the same behavior through explicit ownership:

1. Give each task its own directory storage and drive selection, inherited before
   the child becomes runnable. Define which configuration remains shared, including
   home-directory state and mounted volumes. A failed inheritance allocation must
   leave no published task or leaked allocation.
2. Keep path state valid throughout a read or nested include, including scheduler
   switches during ATA polling. Prevent replacement or reclamation while a read
   borrows it. Define cleanup ordering relative to task exit, compiler destruction
   and heap release, and preserve the caller's interrupt state.
3. Route retained read/include entry points through the current task and selected
   mounted volume. Require task-owned channel sessions for worker I/O; keep the
   quiescent boot path explicit. Version and validate any changed service table,
   and retain its code for as long as tasks hold callbacks into it.
4. Connect this mechanism to public `CTask`, `CDrv`, `DirCur`, `Cd` and `FileRead`
   semantics. A private directory setter does not implement `Cd`: retain directory
   lookup, home/parent handling, directory creation and existing partial-progress
   behavior on failure. Connect public exception reporting and resident-file
   ownership before claiming file API compatibility.
5. Construct and destroy full compiler controls using the task/code heap policy,
   then connect the shared parser and native execution path. Input buffers, saved
   lexer positions, symbols, generated code and callbacks need distinct lifetimes;
   an allocation failure must leave the shell able to compile again.

Acceptance for the first three steps: two cooperative tasks inherit one directory,
one changes its directory, and both load the same relative filename from their
own locations while timer/keyboard service continues. Verify parent independence,
spawn/update allocation failures, state borrowed across a yield, exit/reap cleanup,
nested includes and exact temporary-memory reclamation. Follow with public API
behavior comparisons against x86-64; private-helper tests alone do not satisfy
steps 4–5. Measure resident and peak memory without increasing the fixed bootstrap
reservation to accommodate routine integration growth.

Native task-state ownership and retained routing now pass the private integration
checks above. Two workers resolve relative names independently on C:/One and
D:/Two, while tests cover inheritance failure, borrowed-state protection and reap
reclamation. The standalone kernel exercises retained reads and nested includes
with IF clear and set. These results leave public `CTask`/`CDrv`, `Cd`, resident
files, exception semantics and compiler-control construction/destruction open;
see `docs/i386-task-files.md`. Continue with steps 4–5 rather than expanding the
private API into an application contract.

Owned native compiler controls now share initialization and the public x64
release sequence. Retained CompilerRuntime version 11 constructs/destroys the
standalone disk-include control in both boot and worker phases, reclaiming its
root, nested input and temporary state. Public task symbol/heap selection,
filename/default-name and bitmap selection, parser/code-generation unwind, and
prompt/document input remain required; see `docs/i386-compiler-control.md`.

Native tasks now own local symbol tables with parent lookup and lifetime pins.
The retained compiler initializes the root scope, and worker compiler controls
use their current scope and its heap. Tests cover sibling shadowing, a finished
parent still needed by a grandchild, spawn rollback across file/symbol state, and
owned definition cleanup. The compiler worker uses a 128 KiB arena for its codec
and control allocations; the keyboard worker uses 8 KiB. This is still a bootstrap
heap policy. Complete public task/control ownership and constructor filename,
default-name and bitmap selection remain open; see `docs/i386-task-symbols.md`.

The current-task constructor now selects the scope heap/table, resolves explicit
filenames, preserves the unnormalized default temporary name and selects the
original bitmap for `CCF_KEEP_AT_SIGN`. FileRuntime version 4 routes construction
to CompilerRuntime version 13, whose optional owner pins the task through control
destruction. Tests cover surviving task finish, failed construction and retry,
document-release rejection, two task directories and IF preservation. Public
heap/error policy, task/control lists and automatic teardown remain open; see
`docs/i386-task-compiler.md`.

#### Next bounded work package: active compilation and task exit

Connect compiler-control lifetime to task completion before adding the resident
parser. Preserve the distinction in the existing public compiler: construction
returns a detached control; compilation explicitly enters the task's active
control queue. A detached control may outlive its task while retaining its owner
pin. Automatic cleanup applies to active controls, not every allocated control.

1. Add a per-task active-control queue and a compiler cleanup hook to the native
   task record. Keep queue manipulation in the compiler service and scheduling
   in the kernel. These bootstrap fields must map to public `CTask` compiler-list
   semantics when the public records are integrated.
2. Provide enter/leave operations and permit deletion to detach an active control.
   Reject new compilation while its owner is finishing. Keep the existing owner
   pin until input, saved lexer state and document callbacks have been released;
   leaving the queue alone must not release that pin.
3. Drain active controls from the tail during task completion, after the user
   cleanup callback and before detaching the task from the runnable list. Preserve
   caller interrupt state around callbacks. Preflight required document-release
   callbacks before changing the queue. If cleanup cannot proceed, record failure
   and allow the task to finish, retaining its resources for explicit recovery.
   Reaping must reject outstanding controls or pins and succeed after recovery.
4. Version the retained compiler interface when adding these operations and
   validate its consumers. Connect the standalone include probe to enter/leave;
   keep constructor-only tests detached. Place compiler cleanup code in the
   retained extended-memory module and measure kernel growth against the existing
   fixed bootstrap reservation.

Acceptance: nested active controls are reclaimed on normal task exit in reverse
entry order; explicit leave preserves a detached control across owner exit;
missing document cleanup preserves ownership and permits a successful retry;
callbacks observe a live owner; and final reap restores heap accounting. Exercise
these paths with cooperative tasks and both initial interrupt states. Run the
x86-64 rebuild regression, native control/task/exception tests and the standalone
image check. Exception unwinding through parser and generated-code frames remains
a separate integration requirement; successful task-exit cleanup does not satisfy
the recoverable HolyC shell milestone.

Native active-control cleanup now implements this bounded package. CompilerRuntime
version 14 supplies enter/leave/drain in a 68-byte record; FileRuntime version 5
validates the new compiler dependency. Task completion drains after user cleanup,
keeps detached owner pins, and preserves the full active queue when document
cleanup is unavailable. Recovery can delete the affected control and drain/reap
the finished task. Six native exit scenarios cover three ownership paths with IF
clear and set, callback yields, reentrant-operation rejection and heap accounting.
The standalone probe exercises retained entry/leave in boot and worker phases.
The kernel links scheduler core and task lifetime helpers separately from join
and task allocation convenience functions; the complete helper wrappers remain
available. The bootstrap plus stage uses 391048 of 393216 bytes. Public task/heap
policy and parser/exception integration are still required; see
`docs/i386-task-compiler.md`.

Explicit compiler-catch cleanup now releases the active suffix after a preserved
enclosing control. Full task-exit drain uses the same operation with the queue
sentinel. CompilerRuntime version 15 exposes bounded unwind in a 72-byte record;
FileRuntime version 6 validates the dependency. CompilerProbe version 4 uses the
resident exception runtime to catch a malformed-include failure, unwind the child
control, preserve the enclosing input and tokenize fresh source in the same task.
This runs in boot/IF-clear and worker/IF-set phases with exact temporary-memory
reclamation. It does not install unconditional cleanup on every throw or claim
complete parser/AOT/generated-code reclamation. The kernel plus loaded stage now
uses 391456 of 393216 bytes; see `docs/i386-compiler-unwind.md`.

The public parser and native controls now share intermediate-code initialization
and auxiliary-payload release. Native control destruction reclaims current and
saved code contexts during task-exit or catch-boundary cleanup. Retained compiler
version 16 exposes temporary instruction/misc allocation and discard in an
84-byte record; FileRuntime version 7 validates the dependency. Tests cover every
auxiliary kind, wide metadata, allocation failures, saved contexts and all 233
native function cases. The standalone recovery path now reclaims temporary IR
with its failed child input. Full parser diagnostics, detached intermediate
contexts, AOT graphs and published machine code still need their own lifetime
integration; see `docs/i386-code-context.md`. The kernel plus loaded stage occupies
391472 of the unchanged 393216-byte reservation.

Native saved and detached code headers now use the shared parser copy/restore/
append behavior. Their IR allocations have separate per-control ownership, so
cleanup does not traverse aliased headers as independent graphs. Retained compiler
version 17 exposes header operations and guarded diagnostic discard in a 104-byte
record; FileRuntime version 8 validates the dependency. The loop-increment pattern,
aliased append, fragmented allocation failure and recovery with detached views
pass native tests and the standalone probe. Public allocation/optimization-node
replacement and complete parser/AOT error paths still need integration; see
`docs/i386-code-views.md`. The kernel and loaded stage occupy 391488 of 393216 bytes.

Native instruction retirement now unlinks optimizer entries without reusing storage
still referenced by tree links. A completed discard collects retired nodes only
when no other code allocation or saved header remains; full control cleanup always
reclaims them. CompilerRuntime version 18 exposes this in a 108-byte record and
FileRuntime version 9 validates it. Exhausted-heap retirement, saved-view deferral,
64 repeated retire/discard cycles and standalone exception recovery pass. Public
allocator/OptFree routing and complete optimizer execution remain integration
work; see `docs/i386-ir-retirement.md`. The kernel and loaded stage occupy 391496
of the unchanged 393216-byte reservation.

The resident compiler now executes the shared zero/nonzero branch transformations
with native allocation and retirement. `OptFree` receives its compiler control
throughout the parser/optimizer; the native branch implementation retires nodes
and throws `OutMem` on failed label allocation. The full parser and remaining
optimizer passes still require public allocation/runtime integration. See
`docs/i386-branch-optimizer.md` for the ownership contract. All 136 native branch
rewrites and standalone OutMem/unwind/retry checks pass, alongside both x86-64
rebuild generations and the complete standalone suite. CompilerRuntime ABI 19
is 112 bytes; FileRuntime ABI 10 validates it. The bootstrap reservation remains
unchanged with 1720 bytes free.

Native F64 remainder now supplies another dependency of the shared constant-folding
pass. The software helper computes exact finite results without an FPU; `%` and
`%=` lower through it for F64 and mixed integer/F64 operands. All 8192 native
remainder checks and eleven mixed-update checks pass, with actual x64 comparison
and an exact-rational oracle. Six NaN payload-selection differences are recorded
separately. Full native pass execution still requires the remaining numerical,
allocation and diagnostic dependencies; see `docs/i386-f64-remainder.md`.

F64 bitwise and shift operations now execute natively as well. Binary forms use
raw floating-point representations; compound forms first convert an F64 right
operand to I64, matching the shared frontend. All 83968 x64/native matrix checks
and four destination checks pass. Shift signedness now follows the operand's
effective type after conversion. The known x64 narrow-temporary result difference
is recorded explicitly in `docs/i386-f64-bitwise.md`. These close further numeric
dependencies of the shared constant-folding pass; full pass/frontend integration
remains the next work.

The retained compiler now runs the shared pass 0/1/2 constant-folding and type-analysis
core through `code_optimize`. Type tables and diagnostics are explicit per-call
services; the native parser stack belongs to its compiler control. Shared opcode
metadata initializes before service publication, avoiding unsupported static string
pointer initialization. Native boot/task probes cover 42 folded expressions,
warning/error reporting and OutMem/unwind cleanup. Both x64 rebuild generations,
the floating-point and function regressions, task/control tests and the full
standalone suite pass. CompilerRuntime ABI 20 is 116 bytes; FileRuntime ABI 11
validates it, and the temporary probe uses ABI 5/56 bytes. The retained compiler
image is 444680 bytes, while the kernel and loaded stage occupy 391576 of the
unchanged 393216-byte reservation. See `docs/i386-constant-optimizer.md`.
Complete native parsing, later optimization passes, backend/JIT publication and
source execution remain integration work; this is not yet a native compiler loop.

The target backend's byte writer now shares an allocator-independent core with
native owned code buffers. The retained compiler's `out_new`/`out_del` services
register output lifetime with the control; full unwind reclaims both builder and
byte storage independently of IR views. Failed growth preserves existing output
and can be retried. Boot/task probes generate, byte-check and execute 128 buffers,
exercise growth/construction OutMem, retry, overflow rejection and unwind. Both
x64 rebuild generations, 233 function cases, nine expression cases, native control
tests and the complete standalone suite pass. CompilerRuntime ABI 21 is 124 bytes;
FileRuntime ABI 12 validates it. The compiler image is 455496 bytes, and kernel plus
stage occupy 391584 of 393216 bytes. See `docs/i386-code-emitter.md`. These remain
temporary output buffers; persistent JIT publication and complete backend/parser
execution still require integration.

The production i386 function-lowering loop now has a shared service-based core,
used by both the x64 compiler and retained native compiler. Native `backend`
compiles valid function IR into a fresh control-owned buffer; temporary lowering
records and relocation metadata use the same control lifetime. Boot/task probes
execute 32 generated functions covering arithmetic, division, shifts, comparisons,
branches and literal pools, plus lowering allocation failure and full unwind.
CompilerRuntime ABI 22 is 128 bytes; FileRuntime ABI 13 validates it. See
`docs/i386-native-backend.md` for borrowed AOT/symbol context and diagnostic lifetime.
This closes native IR-to-code integration for the tested cases. Native source
parsing, import resolution, persistent code publication, top-level execution and
`#exe` remain the next compiler work; the standalone image cannot yet compile its
startup source or provide the HolyC shell.

The complete production expression state machine now uses explicit services for
lexing, types/operator tables, IR and saved views, allocation, diagnostics, strings,
symbol insertion and type parsing. `PrsExp.HC` retains host entry/exception/execution
behavior; precedence and type-mode constants have shared definitions. This prepares
the original HolyC grammar for native integration without introducing a second
parser. `docs/i386-expression-parser.md` maps the remaining native adapters,
including separate recursive parser-stack ownership, `PrsType`, adjacent strings,
and unresolved symbols. No native expression service is published yet.

Type parsing, array dimensions and variadic member construction now also use
shared cores with explicit lexer/snapshot, allocation, class/function, member and
expression-evaluation services. The array-dimension traversal begins at the real
root object, avoiding a write through the stack slot containing its pointer.
The native helper probe checks dimension products, list links and token position;
this is component evidence, not native declaration execution. See
`docs/i386-type-parser.md`. Variable-list parsing, initialization and native
class/function ownership remain needed before publishing a full frontend service.

The member/local/static/argument declaration loop and class/function-header
joining now also use shared cores. Their services preserve snapshot ordering,
layout, defaults/metadata, forward declarations and header comparisons while making
allocation, compile-time execution, source attribution and publication explicit.
The existing host entries call these cores; native ownership/evaluation adapters,
initializers, global declarations and statement/function-body integration remain.
See `docs/i386-declaration-parser.md`. This is frontend preparation, not a native
parser service or interactive shell.

Scalar/aggregate/array/global/static initialization now shares a service-based
core too, preserving snapshot replay, inferred-row assembly and static passes.
Incoming flags are captured before the AOT string path restores them, removing an
uninitialized read. Generated-program checks now include inferred multidimensional
and aggregate arrays and static multidimensional arrays. Native initializer
ownership/evaluation and durable code/data relocation still require adapters;
initialized i386 string pointers remain an explicit unfinished relocation case.
See `docs/i386-initializer-parser.md`. Global declarations and statement/function-body
parsing remain the next frontend extraction/integration work.

Global declaration handling and function-body construction/compilation now also
have shared cores. Explicit services cover alias heap identity, import resolution,
statement parsing, output compilation, trace disassembly and diagnostics. The
non-AOT inferred-array fill uses its computed byte size rather than an uninitialized
loop variable. Native immediate compilation still needs durable code/debug/symbol
ownership; native adapters remain open. See
`docs/i386-global-function-parser.md` for contracts and validation limits.

The complete statement parser now uses shared services, including stream blocks,
nested switch sections, assembly dispatch and both target exception-call paths.
Switch table initialization uses pointer-width stores, and case ranges stop before
incrementing beyond `I64_MAX`. Native ownership/recovery, compile-time execution
and assembler adapters remain required; general native source compilation is unfinished.
See `docs/i386-statement-parser.md`.

The retained runtime now exposes the complete shared expression parser through an
explicit caller-supplied service environment (ABI 23, 132 bytes). Parser stacks are
owned separately from optimizer stacks and reclaimed on control unwind. Shared
stack bounds and a native task-stack reserve check guard parser entry. Native
arithmetic probes connect source tokens, shared parsing, optimization and code
execution; a complete native environment for types, symbols and statements still
needs integration. See `docs/i386-native-expression.md` for the API and limits.

Native type parsing now calls the complete shared core through a borrowed type
service environment (CompilerRuntime ABI 24, 136 bytes). Expression casts use this
entry with the native lexer and type registry. Native probes cover narrow integers,
pointer width/stride/difference and invalid intrinsic types. Declaration, array-bound
and scalar-union progress is recorded below; durable publication and complete
parser environments remain required. See `docs/i386-native-type.md`.

Native parser allocation services now retain exact payload sizes in a separate
compiler-control registry (CompilerRuntime ABI 25, 144 bytes). IR/lexer payload
release removes tracking records, and control deletion reclaims detached parser
temporaries. Native probes cover ordinary cleanup and both allocation-failure
points. Existing lexer-buffer transfers, declaration/class adapters and durable
publication remain required; see `docs/i386-parser-memory.md`.

The parser now has an owned token entry (CompilerRuntime ABI 26, 148 bytes).
Returned identifier/string buffers stay registered when parsing clears `cur_str`
to transfer them, while ordinary lexer replacements update the tracking record.
Native expression/type probes use this entry, with additional transfer and failure
cleanup checks. This closes returned-token ownership plumbing; class/declaration
adapters and durable publication remain open. See `docs/i386-parser-token.md`.

The complete declaration core now has a native entry (CompilerRuntime ABI 27,
156 bytes), alongside an owned active-IR initialization operation. Native probes
construct packed class/union members with snapshots and owned strings/allocations.
Arithmetic array bounds are parsed, compiled and executed natively while preserving
an existing IR view. General initializers and publication still require integration;
see `docs/i386-native-declaration.md` and the class/header milestone below.

Native class and function-header entries now call the full shared symbol core
(CompilerRuntime ABI 28, 164 bytes). The native fixture reads the unchanged
`Kernel/Types.HH` from RedSea, handles its help-index directive, and parses all six
public scalar unions into a private table. Checks cover their member views,
forwarding, sizes and pointer variants; compiled expressions exercise narrowing,
signedness, division and member-view sizes. Scalar code generation now follows
class forwarding, and native controls select the 32-bit target before argument
layout. Inheritance, extern completion and partial parse cleanup also pass.
These symbols remain compiler-owned: durable bootstrap registration, full source
metadata, complete function/default/initializer providers and interactive parsing
remain required. See `docs/i386-native-symbol.md`.

A native class-publication operation now transfers complete owned class graphs
into the current task's table (CompilerRuntime ABI 29, 168 bytes). It validates the
shared symbol ownership traversal before detaching any parser allocations; name
collisions, foreign/duplicate payloads, aliases to lexer-owned storage, scratch OOM,
outstanding IR and compiler errors leave the private graph intact. Native probes destroy the originating
control, compile against the six transferred scalar unions from a fresh control,
then detach/delete them and verify full resource restoration. See
`docs/i386-class-publication.md`.

The retained compiler now supplies a frontend environment for permanent scalar
bootstrap (CompilerRuntime ABI 30, 180 bytes). Native boot reads the original
`Kernel/Types.HH`, parses its six unions through the shared grammar, executes array
bounds through the native backend, validates scalar layouts and help metadata,
and publishes the complete class graphs into the root task's table. Input,
controls and parser temporaries are reclaimed; workers inherit the same classes
after the temporary probe module is released. Source links retain the original
filename and declaration lines. Bootstrap failures and duplicate loads restore
allocation/control ownership without replacing published classes. See
`docs/i386-scalar-bootstrap.md`.

The retained frontend now exposes its parser services and produces owned native
expression output (CompilerRuntime ABI 31, 184 bytes). Result types and literal
pools survive temporary IR cleanup; software-F64 calls bind to the retained
runtime. The shared function-header parser evaluates numeric and string defaults,
including mixed F64 calculations, while array bounds use numerical I64 conversion.
Two live outputs preserve the caller's IR, and released-code execution is rejected.
Native boot/worker cases verify exact cleanup after success and parse/OOM failures.
See `docs/i386-frontend-expressions.md`.

The retained compiler now connects the shared statement, function, global and
initializer cores through a private JIT entry (CompilerRuntime ABI 32, 188 bytes).
Native boot/worker tests compile and execute loops, switch/goto, default arguments,
recursive/nested calls, F64 conversion, globals, static state, aggregates,
function pointers and variadics. Per-call descriptor copies bind generated calls
without attaching temporary fixups to published symbols. Statement nesting checks,
undefined-label rejection and control unwind cover failures and resource recovery.
The host constant evaluator also needs two folding passes to resolve arithmetic
in switch labels, array bounds and defaults. See `docs/i386-native-statements.md`.

CompilerRuntime ABI 33 (192 bytes) now supplies a top-level command compiler.
It parses with global scope before adding the native execution frame, preserves
the caller's IR, and returns registered output for the existing executor. One
source stream can define globals/functions and execute later commands against
them. Native boot/worker checks cover mixed execution, F64 results, loops, literal
lifetime, retained outputs, load-only mode and error cleanup. The backend's
zero-operand `RETURN_VAL2` now preserves the statement result. See
`docs/i386-native-commands.md`.

CompilerRuntime ABI 34 (196 bytes) now publishes complete private definitions into
the current task's table. Symbol metadata/global data use the existing ownership
walk; code, literal pools and static storage move to a separate task-owned list.
Fresh controls can call the published functions after the original control is
destroyed, and a failed later input can be unwound without losing earlier
definitions. Validation and allocation finish before ownership changes; collision,
alias, incomplete-code and OOM cases retain the private graph. Child scope references
protect parent storage until task teardown. See `docs/i386-program-publication.md`.

CompilerRuntime ABI 35 (200 bytes) adds a synchronous submitted-source entry. It
creates a private control, compiles and optionally executes commands, forwards
results/diagnostics, publishes completed definitions and unwinds temporary state.
It preserves an enclosing active control and rethrows non-compiler exceptions
after cleanup. See `docs/i386-command-input.md`.

ConsoleRuntime ABI 1 (20 bytes) now connects that input service to keyboard entry
and VGA results/diagnostics. The console, font and scalar formatting live in a
retained extended-memory module, releasing space in the fixed boot reservation.
The console task starts after diagnostic heap checks, uses a 64 KiB stack and
shared heap, and retains its own symbol scope. Keyboard-driven tests cover
persistent definitions, recovery, wide integers and software F64 boundary values.
Multiline editing, public APIs and the complete document workflow remain open.
The console now tracks changed text rows and presents bounded VGA scanline ranges.
Ordinary edits upload 2560 bytes instead of 153600; initialization and scrolling
remain full-screen. Pixel checks and invalid-range checks pass, but this payload
reduction does not establish vintage-machine latency acceptance.
See `docs/i386-console-runtime.md`.

Native JIT string-pointer initialization now retains literal storage through the
existing initializer and task-publication lifetimes, including globals, statics,
aggregate members and pointer arrays. AOT string-pointer initializers now use
version-3 module records with a four-byte data slot and module-local target. The runtime loader resolves them at the actual
allocation address; the flat boot image links explicitly at `0x11000` behind a
fixed 4096-byte BIOS-stage prefix. Version-2 position-independent modules remain
supported. Symbolic stored function/import pointers and general executable
initializers still need integration.
See `docs/i386-initializer-parser.md`.

Private forward function calls now retain control-owned relocations and resolve
when their definitions compile, including mutual recursion. Signature checks and
task-publication validation keep unresolved calls out of retained storage.
See `docs/i386-native-statements.md`.

Native declarations now bind visible resident system exports and publish their
owned metadata while borrowing the resident code/data. Startup declares `StrCmp`,
`SysTry`, `SysUntry` and `throw`; generated exception calls and publication lifetime
checks pass. Complete public `CTask`/`Fs` views and original runtime headers remain
open. See `docs/i386-resident-declarations.md`.

Complete assembly/stream providers and public exception headers, symbolic stored-pointer relocation,
unresolved cross-control function/global linking, definition replacement/unload
rules, complete public API/console integration, DolDoc and native
self-hosting remain required. This bootstrap milestone does not satisfy
the full native programming-environment acceptance gate; strict SX/DX
certification is deferred.

#### Continuing integration sequence

Early display initialization still executes a cross-compiled module. The retained
console now compiles, executes and publishes `/Kernel/I386/StartOS.HC` from RedSea
before its first prompt, then accepts keyboard source in that same task scope.
Missing or malformed startup source recovers to the prompt; complete original
StartOS/bootstrap integration remains open. Advance the resident programming environment through
these concrete steps:

1. Load a separately packaged i386 startup module from RedSea using the existing
   checked module loader. Bind its code/data imports to explicit resident kernel
   exports. Verify execution and temporary-buffer reclamation, and define image
   ownership before allowing callbacks or tasks to retain module addresses.
   The synchronous startup path now passes execution/reclamation and wrong-target/
   unresolved-import boot checks. The compiler runtime now supplies retained
   service pointers used during boot and task activity; general unloadable module
   callbacks and module-owned tasks still need lifetime rules.
2. Connect keyboard delivery and VGA text rendering to a recoverable command
   loop. Integrate public task, allocation, file and exception interfaces needed
   by the compiler; keep disk access ownership explicit as tasks become active.
   Keyboard line collection, cancellation and VGA scrolling now pass in the
   standalone image. A synchronous native submitted-source service now supplies
   compilation, execution, publication and recovery. The retained console now
   connects that service and result/diagnostic rendering. Complete multiline
   editing and the compiler-facing public APIs, and measure/reduce presentation
   and compilation latency against the vintage hardware profiles.
3. Inventory the compiler's remaining native dependencies against that resident
   interface, including symbol storage, formatting, software F64, generators and
   target execution. Bring up a native compile/run path, then repeat editing,
   compilation, execution and error recovery without host assistance.
   Shared symbol declarations, value access, member lookup and class/function
   initialization now pass host/native checks. Native hash primitives supply the
   resident loader's export index; explicit-heap table creation, resizing,
   detachment and deletion pass lifecycle and allocation-failure tests.
   Target-sized class/function pointer variants and legacy symbol/member cleanup
   also pass nested ownership and reclamation tests. Cleanup requires detached,
   privately owned symbol graphs and retains borrowed code/data references.
   Member insertion and signature comparison now share the frontend's list/tree,
   duplicate-diagnostic and default-value semantics, with explicit-heap native
   member allocation. Host/native fixtures cover construction and reclamation.
   The original 17 built-in type descriptors and root initialization are shared.
   A native registry now supplies the standalone kernel symbol table's parent,
   with alias-map checks, allocation-failure cleanup and a measured 7,672-byte
   heap footprint. Opcode tables and full compiler-control startup remain open.
   Compiler/lexer/IR declarations now share a target-sized header, and the
   existing control/file initialization runs through shared helpers. Native
   CCmpCtrl layout, queue bindings and wide-value tests pass; file/include
   ownership and native lexer execution remain to be connected.
   Lexer save/restore now shares CLexFile snapshot semantics, with native heap,
   control and active-file ownership checks. Native failures leave the save state
   unchanged before publication; input loading and tokenization remain open.
   Lexical file attachment/release now shares root-buffer retention and document
   cleanup rules. Native file records check heap/control ownership, reject pops
   with live save points and require a document release service when needed.
   Native source loading and full control destruction remain to be connected.
   Buffer character consumption is now shared with the x86-64 lexer. The native
   raw-input path handles replay, normalization, line accounting, EOF and include
   returns, while explicitly rejecting unavailable document/prompt/echo services.
   Standalone startup reads its source into a stable buffer, consumes it through
   that path and verifies full temporary reclamation. Tokenization, general input
   services and full control destruction remain open.
   Character tables and native bit intrinsics now support shared classification.
   Quoted-string body decoding also shares escapes, dollar state and chunking
   with the production lexer; native tests cover read failures and file-boundary
   recovery. Full token recognition, macros/directives and compiler execution
   remain required; these helpers do not establish a native shell.
   Numeric and dot-token bodies now share parsing and replay semantics, checked
   against original x86-64 records. Native F64 uses the established software
   numerical policy; recorded bit differences and cross-build literal evaluation
   remain an explicit compatibility boundary. Lexer/numerical services now load
   from a retained extended-memory module with a versioned interface and explicit
   kernel function/data imports. Boot/task calls and rejection/reclamation checks
   pass. Character-constant decoding now shares packed I64, escape and replay
   semantics and executes through a retained service. Operator/comment parsing and
   packed token-table initialization are now shared too; a fourth service supplies
   skip/token/error results with the original final-lookahead behavior. Identifier
   scanning and local-before-global lookup now share a fifth retained service,
   returning caller-owned text and borrowed records without token publication or
   macro expansion. The version-4 interface requires rebuilding kernel and runtime
   together. Identifier completion now also shares macro-versus-token dispatch.
   The version-5 token service expands string macros through owned inputs or
   publishes an owned identifier, preserving previous text on allocation failure.
   Chained/empty macros, NO_DEFINES, local shadowing and boot/task reclamation pass.
   Complete native string construction now publishes exact-sized owned buffers,
   including embedded zero bytes, and reclaims partial builders on failure. The
   version-6 runtime tests identifier-to-string replacement during boot/task activity.
   Native token dispatch now joins these handlers, resumes string-macro expansion
   internally and preserves lookahead and token flags. Mixed x64/native streams,
   allocation/length failures and retained version-7 boot/task calls are tested.
   Unsupported directives return an explicit error; remaining directive
   processing, prompt/document input and parser/JIT integration remain required.
   The production #define replacement-text reader is now shared with an owned
   native builder, preserving continuations, quoting, comment/EOF quirks and
   chunk boundaries. Original-lexer fixtures and native failure/reclamation checks
   pass. Native #define now builds copied source/help metadata, preserves private
   flags and publishes the complete definition before transferring name ownership.
   Definition/redefinition, expansion, metadata and failure/reclamation tests pass;
   the version-8 runtime executes definition probes at boot and after task activity.
   All 48 language and 25 assembler keywords now initialize as an owned native
   registry behind primitive types. The definition probes use this real namespace.
   Native ifdef/ifndef, AOT/JIT selection, else/endif and expression-boundary
   markers now share skipped-branch traversal with x64. Original behavior cases,
   native error/reclamation tests and version-9 boot/task conditional probes pass.
   Active if expressions, includes and executed directives remain unsupported.
   Volume-scoped slash lookup and owned whole-file reads now support the native
   source-loading path, with failure cleanup and exact source traversal tested.
   Connect these lower-level services to include path/extension rules,
   decompression and compiler file ownership next; see `docs/i386-file-read.md`.
   The bootstrap with this reader is 377480 bytes, leaving 15736 bytes in its
   unchanged reservation. Keep further compiler growth in extended-memory modules.
   Opcode/register initialization and remaining directives are still required.
   Compiler diagnostics now load as a temporary extended-memory module, retained
   through boot/task checks and then reclaimed. This reduces the bootstrap from
   390760 to 364504 bytes within the unchanged 393216-byte reservation; its 44224-byte
   temporary heap span is measured separately from the retained compiler runtime.
   Preserve that placement/lifetime discipline as remaining services are integrated.
   With keyword initialization, the bootstrap is 372288 bytes, leaving 20928 bytes
   of headroom. The resident keyword registry uses 6208 heap bytes in 148 allocations.
   Full lexical dispatch and remaining directive processing are required. Owned native source attachment now prepares record/name/buffer copies
   before changing parent state, then uses the shared lookahead backup. Boot/task
   scanning crosses that include and reclaims it. Pending save points still block
   native EOF pop; general lookahead across includes needs integration.
   Owned-source transfer now shares publication with copied attachment and avoids
   duplicating a disk-loaded source allocation. Kernel source traversal transfers
   its file buffer into a child, crosses EOF and verifies reclamation and parent
   resumption. Failure leaves ownership with the caller. Include dispatch, public
   path/extension rules and decompression still need integration. The original
   whole-path extension-dot scan, default-extension writer and uppercase .Z/.C
   suffix rules are now shared with owned native filename helpers. Original x64
   cases, native allocation failures and storage regressions pass; these helpers
   remain outside the bootstrap until file/include services are connected. See
   `docs/i386-file-names.md`. The bootstrap
   with transferred source input is 383496 bytes, leaving 9720 bytes in its fixed
   reservation; place further substantial services in extended-memory modules.
   Place remaining compiler modules here, defining
   their code/data lifetimes; arbitrary unloading remains unsupported.
   Public task/code-heap selection, allocation-failure exception behavior,
   module-code lifetime and compiler-control initialization remain.

Disk-loaded cross-compiled modules are an intermediate integration check, not
native JIT or self-hosting. At each step record resident and peak allocations,
retain the x86-64 rebuild regression, and audit executable bytes for the 386
instruction baseline. Exercise the QEMU no-FPU acceptance profile alongside this
work; strict SX/DX certification is deferred.

| Milestone | Work and required evidence |
| --- | --- |
| M0: Verified starting point | A: source rebuild and regression baseline; pin QEMU/TCG CPU, machine, BIOS, VGA, storage, and memory profiles |
| M1: Architecture contract | B and G: ABI/data-layout specification, module identification, format fixtures, memory accounting plan, instruction policy |
| M2: Compiled 32-bit code | C and initial D: cross-generated integer/I64 code executed by a minimal protected-mode runner; numerical and ABI tests underway |
| M3: Bootable 386 kernel | E and minimum F: CHS disk boot, VGA, keyboard, PIC/PIT, memory allocation, task switching; strict instruction checks |
| M4: Interactive HolyC | Complete essential C/D: native JIT/compiler, F64 without a coprocessor, shell, storage, exceptions; no integer-only completion claim |
| M5: TempleOS environment | F/G/H: DolDoc, editing/help, mouse, graphics, audio, persistence, portable data, measured low-memory workflow |
| M6: Self-hosting and portability proof | Native i386 compiler/kernel rebuild and reboot; QEMU no-FPU and later-CPU checks plus 386 instruction audits; x86-64 regressions and published support matrix |
| M7: Fully working PC system | Complete the integrated QEMU-PC acceptance workflow in the final-goal section: independent boot, HolyC/DolDoc development and debugging, graphics/input/sound, persistent documents, two native rebuild generations, measured RAM/latency and published artifacts. Pending; M0–M6 component evidence alone does not close this gate. |

M2's target runner and early M3 boot/interrupt work can be developed alongside
the backend after M1. Do not require the full compiler before running backend
tests, or the complete desktop before resolving compile-time execution.

The following records foundation work in implementation order; current remaining
priorities are the integration gates above. Detailed results and limitations are
maintained in [port progress](docs/port-progress.md).

The protected-mode runner executes HolyC-generated integer functions with
32-bit pointers, 64-bit arithmetic, and basic control flow. The architecture-tagged
bootstrap linker and shared module validator now have target execution tests.
Indirect fixed-arity calls and same-module function addresses now pass target
execution tests, including callbacks in linked modules. Global/static storage and
relative address imports now have a version-2 module path with explicit data ranges.
The shared loader now executes on i386 and loads code/data into caller-owned
memory. Byte/word/dword port-I/O intrinsics now pass target tests, including VGA
sequencer register readback. Native palette programming and a full planar VGA
upload now pass a 640×480 pixel comparison in the protected-mode runner; integration
with the graphics/window-manager path remains pending.
The native arena allocator now passes allocation, coalescing, corruption and
exhaustion checks; VGA uses it for its framebuffer. Allocated module images now
pass execution, exhaustion, release/reuse, and source-lifetime tests. BIOS
conventional-memory discovery and reservation-aware arena selection now serve
VGA and module loading. Native A20 verification/enabling and bounded legacy
extended-memory selection now pass target tests; VGA and loaded modules use
arenas above 1 MiB. PIC/PIT IRQ0 and periodic RTC IRQ8 delivery through saved
32-bit frames now pass native callback and register/flag restoration checks,
including real slave PIC delivery and RTC configuration restoration. Separate
exception stubs now pass #DE/#GP/#BP delivery and controlled saved-frame recovery
through native HolyC. EFLAGS intrinsics and nested save/restore of interrupt state
now pass native tests. Heap operations wrapped in interrupt masking pass shared
foreground/PIT-callback allocation tests. Cooperative context switching now passes
two native workers on separate heap-owned stacks, including entry/exit and stack
reclamation. A native circular runnable queue now passes round-robin yield,
completion, retirement and record reuse tests. Blocking removes tasks from the
runnable queue; explicit wakeup passes ordered-resume and lifecycle tests;
a combined PIT/task test now passes IRQ-driven event publication and wakeup
through 16 waits. Root-only idle now checks the queue with IF masked and halts
through an adjacent STI/HLT sequence, with IRQ wakeup and IF restoration tested.
Native Fs/Gs intrinsics now pass pointer and field-access tests through distinct
protected-mode segment bases. Scheduler binding now rewrites/reloads the incoming
task's FS descriptor with IF masked, preserving a shared CPU GS binding through
switches and hardware IRQs. Heap-owned task creation, automatic finish on entry
return, and destruction from another stack now pass lifecycle and exhaustion tests.
Blocking joins now wake on completion, reject dependency cycles, and keep finished
targets alive until registered joiners resume; native tests cover spurious wakeups
and rejected early destruction. Computed-pointer member accesses, including
pointer-to-pointer field addresses, now pass native compiler regressions. Optional
private task arenas now pass allocation, exhaustion, cross-arena free rejection,
and bulk reclamation checks across task completion/destruction. Normal-return
cleanup hooks can yield with task memory and bindings intact; completion is
published only after cleanup returns, with recursive completion rejected.
Bounded 8042 transport now passes keyboard echo delivery through IRQ1, status
capture and controller configuration restoration. Scan-set-1 packet decoding now
passes make/release, extended-key, Pause/Print Screen and error-recovery tests;
Native modifier/lock state now preserves paired mapped/raw scan values, independent
left/right modifiers and held-key mappings across Num Lock changes. Character conversion matches
the x64 implementation across all 32,768 low scan/flag combinations. Function-body
string literals now use position-independent addresses and explicit data ranges.
Boot keyboard setup now explicitly requests scan set 2 and controller translation,
with bounded ACK/RESEND handling. QMP-injected ordinary, extended, Print Screen
and Pause keys now pass through IRQ1, a blocked worker and decoding/conversion;
a reusable event interface now returns TempleOS key-down/up types, characters
and scan pairs. A bounded native message queue now delivers live keyboard events
from a broker to a second blocked task, with masked reads and close wakeups.
Task-addressed inboxes now enforce recipient-only reads and prevent reaping
until close/detach, including completion with unread messages. Heap-backed inbox
allocation and self/post-completion cleanup now pass failure and reclamation tests.
Native focus selection now routes broker messages and pins the selected task
until focus is moved or cleared. A blocking keyboard-event reader now detects
raw queue loss, discards ambiguous backlog and resets local decoding state;
client key-state reconciliation remains pending.
Full CTask/CJob and public message/focus integration, LED updates and input-loss
reconciliation remain.
A fixed raw-input FIFO now passes IRQ1-to-foreground
delivery, wraparound, overflow accounting and interrupt-state preservation;
blocking raw input now passes worker wakeup through actual IRQ1 delivery, spurious
wakeup handling and pending-reader reservation. See `docs/i386-keyboard.md`
for the transport and queue contracts.
Native ATA IDENTIFY and 16-bit PIO LBA28 sector reads now pass disk-pattern,
error and absent-device tests. Geometry decoding now accepts CHS-only profiles;
forced CHS reads on QEMU pass head/cylinder boundaries and final-sector checks.
Single-sector writes now pass LBA/CHS readback, source preservation and a complete
backing-image comparison after QEMU exits. Actual CHS-only hardware, parameter
initialization, legacy cache policy and filesystem integration remain pending.
Explicit FLUSH CACHE now uses validated capability detection; native tests and
QEMU command traces cover write/flush/read ordering and unsupported rejection.
See `docs/i386-ata.md`.
A native RedSea reader now validates volume/root metadata, streams exact-name
directory lookup and reads raw file ranges through ATA. Tests cover nested HolyC
source, sector boundaries, 64-bit dates, malformed extents and partial I/O errors.
Raw writes within existing extents now preserve partial-sector neighbors and
report confirmed progress on failures, with flush/readback and whole-image checks.
Contiguous bitmap allocation/release now passes fragmentation, cross-sector bits,
exhaustion/reclamation and I/O-failure invalidation checks. Native raw file creation
now connects allocation, data flush and directory publication, with deleted-slot
reuse, cross-sector append and remount/readback tests. Regular-file deletion now
flushes tombstones before bitmap release, with empty-file, reclamation and reuse
tests. Replacement now writes and flushes new storage and publishes the updated entry
before freeing old storage, with growth/empty/no-space preservation tests.
Root and nested RedSea directories now relocate into a larger contiguous extent
before creation consumes their final zero terminator; parent entries and child
`..` records are relinked. Public CDrv/CFile integration, decompression and
crash-atomic directory relocation remain pending.
See `docs/i386-redsea.md`. A disk-to-module bridge now reads uncompressed RedSea
modules into temporary heap storage, validates/loads them and releases the file
buffer before execution. Native tests cover mutable 64-bit data, buffer-lifetime
independence, malformed files and both allocation-failure stages. Explicit file
sets now resolve cross-module functions and data in either order, with missing/
duplicate dependency rejection and cleanup at every allocation stage. Automatic
dependency discovery and production boot/JIT integration remain pending; see
`docs/i386-module-file.md`. Explicit resident function/data bindings now resolve
imports without copying providers, with ambiguity/type/overlap checks and native
execution tests. A production kernel export table and provider lifetime tracking
remain pending; see `docs/i386-module-bindings.md`.
Integer-only binary64 addition/subtraction/multiplication/division helpers now
pass 2,048 operand pairs (8,192 result checks) with CR0.EM set and generated-function instruction audits.
The bit-pattern API specifies nearest-even rounding, subnormals, signed zero,
infinities and NaN propagation. Native HolyC same-type F64 arithmetic, literals,
storage, unary minus and fixed-arity direct/indirect calls now pass target tests.
Same-type compound assignments and prefix/postfix increment/decrement also pass,
including single destination evaluation and preservation of original postfix bits.
Same-type F64 relations now compile to integer booleans and drive branches;
12,288 branch predicates plus comparison-result arithmetic pass native tests.
Explicit `ToF64`/`ToI64` calls now use the software runtime, with 5,120 native
conversion checks and x64 signed-conversion evidence. Implicit conversions now
cover supported mixed arithmetic/relations, assignments, arguments, returns and
F64 compound updates. Integer destinations now also support the four F64
arithmetic updates, with truncation and declared-width normalization; 62 positive
fixture checks pass. Eight x64 checks cover wide values and addressed narrow
storage; the register-held narrow overflow difference is documented. The remaining
arithmetic/formatting/math surface still needs integration. Raw F64 conditions
and logical operators now test the complete bit pattern, including negative
zero as true, matching x64 branch behavior. Shared x64/native tests cover 144
condition pairs and 12 loop cases. Logical branch conditions short-circuit;
value expressions evaluate both operands. The x64 uncast `!F64` arithmetic
metadata quirk remains an explicit compatibility difference. Chained comparisons
now retain middle operands once in frame storage and pass 512-triple native
corpora for integer, unsigned, F64 and mixed types, plus nested-chain tests.
Actual x64 NaN-leading branches and integer-middle mixed chains have documented
result differences; the native corpus requires consistent pairwise numeric
comparisons. Full x64 quirk compatibility remains unresolved.

Integral switch dispatch now uses relocatable four-byte jump-table entries,
including full-width selector bounds, ranges, unchecked dispatch and HolyC
`start`/`end` local calls. Twenty native switch cases bring the integer/function
corpus to 199 cases; nineteen also check actual x64 results. Native early return
from a prefix restores the enclosing frame; its x64 compatibility remains under
investigation after an oracle guest stall. This completes another control-flow
primitive needed by kernel and compiler source, with full unit integration still
pending. See `docs/i386-abi.md`.

Variadic definitions and direct/forward, recursive, indirect and imported calls
now preserve HolyC's hidden argc and eight-byte argv slots with caller cleanup.
Sixteen native cases cover stack lifetime, raw F64/pointers, defaults, recursion
and mutable argv; a linked-module case covers variadic imports. The function
corpus now has 215 cases. Full formatting/shell integration remains pending.

The `ToBool` intrinsic now normalizes full I64 arguments, including high-word-only
values, with coverage in the integer/function corpus. The F64-to-integer corpus now includes numeric and raw-bit Boolean
interpretations, with 4,096 native checks and 2,048 x64 Boolean outputs. Existing
constant/variable ToBool differences are preserved and documented. Integer
absolute/sign, signed/unsigned min/max and square intrinsics now pass 8,192
results against actual x64 execution and an independent Python oracle, plus
nested/side-effect checks. ModU64 now stores the quotient and returns the
remainder from one unsigned division, bringing the math corpus to 10,176
result checks. Decimal digit extraction, shared operands and zero-divisor #DE
also pass. These unblock arithmetic used by kernel message,
memory and mouse code; full unit integration remains pending. F64 Abs, Sqr
and Sqrt now lower through the software runtime. The expanded unary corpus has
13,312 native checks and 7,168
x64 result comparisons, including NaNs, signed zero and square underflow/overflow.
Square root uses an exact integer algorithm; x64 intermediate-precision
square and square-root rounding differences are documented while native results
match the exact oracle.
The five production integer-multiple routines now share `Kernel/KMathInt.HC`
between x64 and i386, with standalone declarations in `KMathInt.HH`. Their
implementations are unchanged; 320 new x64/native/Python result comparisons
cover positive steps, signed extrema and existing rounding/overflow quirks.
This brings the integer-math corpus to 10,496 checks and makes the production
FloorI64 dependency available without CPU-dependent random-number routines.
Public software Round, Trunc, Floor and Ceil now preserve full binary64 range,
signed zero and quieted NaN payloads, matching x64 and a Python oracle across
1,024 inputs each. They supply whole-number rounding needed by StrPrintJoin;
General powers and production formatting integration remain pending.
Native Pow10I64 now uses a generated 617-entry table of correctly rounded
binary64 values without an FPU or allocation, preserving the -308..308 range
contract. Every entry and extreme input branches pass; the combined unary/power
corpus has 13,929 native results. Existing x64 power approximations differ at
607 exponents (at most 683 ULPs); this is recorded separately from the exact
native oracle. Both x64 initialization paths and their lookup also now use
indices 0..616, fixing the previous one-entry allocation overrun.
Software Ln and Log10 now adapt fdlibm's range reduction and polynomial routines
with attribution, using the existing software F64 arithmetic. A 1,024-input
high-precision/x64 corpus now checks 3,072 native results at one-ULP (Ln) and two-ULP
(Log10 and Log2) limits, with exact special-value behavior. All 617 exponent-extraction
cases Floor(Log10(Pow10I64(i))) also pass. These are tested corpus limits, not
universal correct-rounding or full x64 precision claims. Log2 now keeps the binary
exponent separate from the reduced Ln calculation and passes exact-result checks
for all 2,098 representable powers of two, including subnormals. General powers,
exception state and production formatting integration remain pending.
Template-call nesting and malformed-provider rejection also have tests;
trigonometry and remaining numerical/formatting integration are still pending. See `docs/i386-f64-backend.md`. Signed
and unsigned integer-to-F64 helpers now pass 2,048 conversion checks, including
64-bit extrema and nearest-even halfway cases. Signed F64-to-I64 truncation now
passes 1,024 inputs against actual x64 HolyC and an independent host oracle,
including invalid-result bits. Remaining mixed-operation cases, explicit unsigned output
semantics and floating-point exception state remain pending. Numerical
comparison now passes 2,048 checks, including unordered NaNs, signed zeros and
reversed operands; same-type relational operators now use this runtime path. See
`docs/i386-soft-f64.md`.
Native try-block lowering now supplies typed SysTry/SysUntry call contexts,
position-relative catch/cleanup label addresses, and balanced cleanup calls on
early returns. Five recording-provider cases pass for normal, nested and repeated
registration/cleanup, bringing the function corpus to 220 cases. This is a
compiler prerequisite only: throw, catch execution in the enclosing frame,
propagation, exception records and task-owned lifetime are not implemented yet.
Native GetRBP and bounded frame-header traversal now provide the active frame,
parent and saved return address using four-byte pointers. Thirteen ABI and
malformed-frame cases bring the function corpus to 233 cases, including a real
nested call reading its caller's I64 argument slots. Traversal requires live
readable stack bounds and does not perform unwinding. Task bounds, exception
record lifetime and register capture/restore remain pending.
Owned-task creation now records the actual stack base/size separately from the
private arena, and reap clears those bounds. A native public Caller uses current
FS task binding and checked frame traversal, returning zero for invalid depths,
unknown bounds and invalid links. Task tests verify caller addresses across
yields, stack/private-arena separation and record reuse; the message regression
also passes with the expanded task layout. Root boot-stack registration, saved
foreign-task inspection and exception capture/restore remain pending.
Native exception records now have explicit task and heap ownership, nested
push/pop/clear operations and a reap guard that keeps referenced stacks alive.
The ownership fixture uses synthetic captures; actual register capture,
SysTry/SysUntry runtime entry, throw/catch execution and propagation remain
required before the exception milestone can pass. See `docs/i386-exceptions.md`.
Bootstrap assembly now supplies exception capture, invocation with the enclosing
frame and nonlocal cleanup resumption. Native tests cover physical register/flag
restoration and compiled catch blocks reading/writing enclosing I64 locals,
including skipping the remainder of a try body. Fixture-only registration does
not yet connect these primitives to production SysTry or task-owned propagation.
Native registration now captures caller state before calling the record allocator
and returns a task-owned record or null. Register/flag, provider ABI, nested-record
allocation, exhaustion and reclamation tests pass. The five-argument bootstrap
entry still needs the compiler's two-argument SysTry binding and a defined
non-returning allocation-failure path before production try blocks can use it.
An explicit native task dispatcher now propagates through rejected records and
resumes accepted catches at compiler cleanup. Tests cover nested and cross-frame
catches, full-width exception values, unhandled cleanup and malformed state.
Production SysTry/public throw binding, allocation-failure policy, recursive
throw behavior and debugger/logging integration remain pending.
The compiler's two-argument SysTry now has a native T32M assembly provider.
It captures the caller before HolyC runs, imports record/failure services and
prevents failed registration from entering the try body. Linked tests now use
this entry for nested/cross-frame catches, OutMem recovery through an outer
catch and early returns from try/catch bodies. Current-task service binding,
public throw, unhandled/debug recovery and native assembler integration remain.
Standalone SysUntry and public throw now use FS current-task binding, the task's
record heap, and installed report/fatal services. Native tests exercise two FS
bindings, logging/no_log, nested propagation, OutMem recovery, early return and
unhandled-hook routing. Production boot/public CTask binding, concrete debugger
and logging hooks, caller traces and catch-time task switching remain pending.
Public throw now records a bounded eight-address caller trace and its diagnostic
frame pointer before reporting. Two heap-owned native workers pass 48 catch-time
yields across creation/destruction cycles, preserving exception state, caller
snapshots and locals with full reclamation. Full CTask migration, recursive throw
semantics, debugger/logging UI and production boot integration remain pending.
The native backend now accepts HolyC inline assembly with a default USE32 mode,
relative label fixups and branches between assembly and HolyC. Assembler symbol
expressions execute as validated host expressions with target-size folding;
target instruction bytes are never executed on the compiler host. Tests cover
wide frame writes, loops, local calls, numeric branch addends and local offsets.
Inline imports/exports, absolute/storage relocations and full native assembler/
bootstrap integration remain unfinished; see `docs/i386-inline-asm.md`.
The two-argument SysTry provider is now compiled from HolyC top-level USE32
assembly, replacing its hand-built NASM module. Context, public-runtime and
catch-time task-switch suites pass with the generated provider, including
instruction audits; both x86-64 rebuild/reboot generations also pass. Remaining
context/interrupt/boot assembly and native compiler-host execution still need
integration before this constitutes self-hosting.
Exception save, catch invocation, nonlocal resume and capture/registration now
also compile from HolyC assembly into a four-export module. The native exception
runner uses those generated bytes instead of NASM context code. Register/flag,
public-runtime and catch-time task-switch checks pass; task-switch, interrupt
and boot assembly outside this exception module still require migration.
Task switching, interrupt-driven idle and FS/GS reload now also compile through
HolyC as one TaskContext module. Task, blocking-input, message and exception-task
suites pass with the generated entries, including instruction audits and the
x86-64 rebuild regression. The remaining production binding and interrupt/boot
assembly work is still required; injected runner callbacks are not the final
public kernel integration.
IRQ and CPU-exception entries now also compile through HolyC, exporting their
vectors and importing dispatchers with ordinary REL32 calls. The IRQ suite and
all four task-related suites pass with generated entry code; x86-64 rebuilds also
pass. Kernel/I386 no longer contains NASM sources. Test boot/IDT setup still uses
NASM, and production dispatcher binding and native compiler execution remain open.
Native IDT construction, vector replacement and LIDT/SIDT operations now pass
through a 256-entry table built by HolyC. Hardware IRQ and recoverable-fault tests
use that installed table, with gate-byte, bounds, IF-state and IDTR-readback checks.
The bootstrap emergency IDT remains; production handoff and exceptional-stack
policy are still required. See `docs/i386-idt.md`.
Native interrupt installation now links entry-address imports and dispatcher
exports through the module linker, copies runtime services and loads its own IDT.
Hardware IRQs and recoverable faults pass through this linked path; invalid and
repeated installation checks, instruction audits and x86-64 rebuilds also pass.
Production boot/device/task setup and debugger policy remain pending. See
`docs/i386-interrupt-runtime.md`.
Native GDT construction and LGDT/SGDT now support linked task-context setup.
The exception-task suite creates its own table, uses linked switch/reload entries,
passes catch-time switching and restores the original GDTR/selectors. Bounds,
IF-enabled load rejection, descriptor/readback checks, task/IRQ regressions and
x86-64 rebuilds pass. Full production task records and boot sequencing remain
required; see `docs/i386-gdt.md`.
The native task platform now initializes scheduler, root stack/heap, CPU record,
GDT and the kernel binding callback together. Root exception/caller diagnostics
and worker catch-time switching pass through it, including FS/GS identity and
reclamation. Public CTask integration and complete boot ordering remain open;
see `docs/i386-task-platform.md`.
Native exception installation now binds invocation/resumption through linked
context imports. The exception-task fixture links all four runtime/context
modules and passes root/worker exception tests with zero entry arguments, using
no runner-supplied function pointers. Concrete report/debugger handlers and the
production boot environment remain required.
The linked task/exception runtime now also installs native interrupt dispatch
and receives PIT ticks on root and both workers. A 64-bit serviced-tick counter
provides atomic snapshots; rollover, IF preservation and hardware delivery after
all 48 catch-time yields pass. Public time/sleep services and production boot
integration remain pending; see `docs/i386-timer.md`.
A cooperative tick-sleep queue now blocks tasks with stack-owned waiters and
wakes them from timer IRQs without switching there. Catch-time sleeps pass
spurious-wake, IF-preservation, full-width countdown and reclamation checks.
Public time conversion/cancellation and full boot integration remain pending;
see `docs/i386-sleep.md`.
A first standalone native kernel image now boots through the shared BIOS-CHS
loader, consumes the memory handoff, enables A20 and initializes the linked
memory/task/exception/interrupt/timer runtime. The 8 MiB QEMU boot check verifies
VGA output and delayed task wakeups; see `docs/i386-kernel.md`.
Standalone startup now mounts a packaged RedSea source/module volume through
ATA PIO and streams its complete kernel source. Host directory/file/bitmap checks
and the native byte-count/checksum agree; the disk remains unchanged during boot.
The first BIOS-drive/controller mapping is explicit. The current standalone image
also has resident symbol binding, native keyboard compilation/execution, retained
definitions, software F64 and source startup from RedSea, as recorded above.
Remaining public filesystem/task/CPU APIs, complete language providers and the
document/self-hosting workflow are governed by the integration gates. Runner and component success remain intermediate
milestones, not the final OS.

## Verification strategy

- Use the QEMU profiles above for required M0–M7 execution acceptance. The
  installed QEMU lists 486 and newer CPUs, not 386; `qemu32` is not a 386
  compatibility specification. Retain executable-region 386 instruction audits.
- Test missing optional BIOS calls, absent mouse/FPU, failed disk reads, constrained
  RAM, timer wrap, arithmetic boundaries and repeated task/exception transitions.
- Exercise cross-generated and natively generated code, including JIT and
  compiler-generated assembly blocks; inspect runtime helpers and boot code too.
- Run the complete normal-boot development workflow both automatically and in a
  documented manual QEMU session. Require writable-disk persistence, recovery,
  public API semantics and two native self-hosted generations for M7.
- Record bootable artifacts, source/tool versions, configuration, commands,
  results, memory peaks and host-qualified timing. Preserve the x86-64 target.
- Defer physical PCs and dedicated 386SX/DX emulator certification. Publish the
  achieved scope as QEMU-verified; those deferred checks cannot block current
  completion and remain necessary before claiming physical 386 compatibility.

## Principal risks and decision discipline

1. **Compiler host/target confusion:** compile-time execution and pointer-dependent
   layouts can invalidate a superficially working backend. Resolve at M1/M2.
2. **Low-memory self-hosting:** compiler, symbol tables, and document startup may
   exceed vintage RAM budgets. Measure early; do not defer this until the desktop.
3. **Software floating point:** correctness and speed are significant work. Do not
   silently raise the CPU/FPU requirement or substitute fixed-point semantics.
4. **Accidental newer instructions:** handwritten code and compiler helpers may
   pass QEMU tests while failing on a 386. Audit and test the strict baseline.
5. **Legacy firmware/storage:** modern virtual BIOS behavior can conceal missing
   old-PC boot paths. Test the CHS/legacy profile independently.
6. **Source compatibility and complexity:** layout-dependent HolyC and assembly
   need explicit changes. Keep the common implementation shared and architecture
   code localized; track core line count against the charter's 100,000-line intent.

Architecture decisions above are the working plan. If measured constraints force
changes to RAM targets, full HolyC behavior, the no-FPU baseline, or the standalone
self-hosting requirement, report the evidence and revise scope explicitly. Do not
redefine a smaller demonstration as the requested result.

## References

Repository sources are authoritative for the existing implementation:
`Doc/Charter.DD`, `Doc/Requirements.DD`, `Doc/HolyC.DD`, `Doc/MultiCore.DD`,
`Doc/RedSea.DD`, and the source paths in each work package.

- [Intel 80386 Programmer's Reference Manual (1986), archived scan](https://www.bitsavers.org/components/intel/80386/230985-001_80386_Programmers_Reference_Manual_1986.pdf)
- [Intel IA-32 architecture manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) — check feature generation; modern IA-32 does not imply 386 support.
- [QEMU CPU model documentation](https://www.qemu.org/docs/master/system/qemu-cpu-models.html)
- [86Box 5.0 release notes, including 386SX/DX machine models](https://86box.net/2025/08/24/86box-v5-0.html)

## Focused TDD infrastructure

The console harness now exposes twenty selectable groups through `--group`;
omitting it retains the complete console suite. See
[the test workflow](docs/i386-test-workflow.md) for commands and scope. A separate
mutation runner requires a clean windows baseline and injects two representative
public-runtime faults in disposable guest RAM. Only the expected behavioral
failure counts as detection; survivors and infrastructure failures fail the run.
This strengthens the test feedback loop without changing native OS behavior or
advancing the still-unfinished native DolDoc editing milestone. Complete build
validation and original-target comparisons remain the integration gate.

The DolDoc TDD work now has shared lifecycle, ordinary-text editing,
serialization, and load/save round-trip corpora plus retained native `DocNew`,
`DocRst`, `DocDel`, `DocSize`, `DocPutKey`, `DocSave`, `DocWrite`, and `DocRead`
services. A writable-disk acceptance enters retained `DocEd` from the live
HolyC prompt, drives hardware key events, verifies VGA text/cursor state, saves,
boots the normal 8 MiB image again, and reopens the document in `DocEd` from the
same RedSea image. This establishes an ordinary-text editing/persistence
prototype; the medium goal requiring the original editor and edit/execute/reopen
remains open.
The second slice now also has original/shared navigation oracles and native
prompt assertions for all four arrows, Home, End, Delete and Tab. The writable
acceptance sends those keys through QEMU, saves the tab-bearing document, and
verifies cursor and bytes for tabbed and multiline documents after reboot.
Deterministic native allocation injection now covers all three `DocNew`
allocations, both stages of first-character creation, replacement text, newline
creation and serialization. Each failure releases the document lock, restores
heap use and permits a later edit/save. `DocRead` also reclaims its partial
document and owned disk buffer after an injected load failure, then successfully
reopens the same file. Full document layout and the remaining original `DocPutKey` commands and editor
callbacks, executable documents, embedded records, mouse input, and execution
after reopen remain later M5 work.

## Next big goal: standalone native HolyC development environment

**Goal:** Turn the normal 8 MiB i386 image into a coherent offline programming
system: boot it on the 386+/VGA contract, browse and edit real DolDoc/HolyC files,
compile and run them through the resident native toolchain, diagnose and recover
from mistakes, save the work, and resume it after reboot without a host-side
compiler or test harness. This is the next major integration milestone toward
M7. It is complete only when the original public services and editor/compiler
paths support the workflow; prototype adapters remain acceptable while they
drive tests, but do not close the goal.

Deliver it through four test-driven workstreams:

1. **Daily edit/run loop.** Complete the original DocEd/ExeDoc action path,
   layout, scrolling, help and file navigation. A user can create a multiline
   program, press F5 to save and execute it, correct diagnostics, interrupt it,
   and continue editing the same document.
   A first public `Dir(path)` workflow now enumerates RedSea directories through
   the current task's drive and path context, marks subdirectories, accepts
   absolute and relative paths, and reports missing paths. `EdDir(path)` now adds
   a keyboard-driven VGA picker: Enter descends into directories or opens a file
   through `Ed`, Backspace returns to the parent, and `N` creates a named file
   through the same editor and refreshes the listing after save. Delete now asks
   for `Y/N`, removes regular files through public `FileDel`, refreshes the
   listing. Empty directories use the same explicit confirmation and nonempty
   directories are protected. `R` now renames a file or directory
   within its parent, rejects collisions and preserves every data extent and
   directory parent link. Public `FileMove` now moves a regular file between
   directories on one volume with exact-byte and three-boot integrity coverage.
   Cross-parent directory moves, wildcard filtering, sorting options and full
   original DolDoc help layout remain open.
2. **Durable projects.** Make replacement writes failure-aware; support relative
   paths and nested directories; preserve DolDoc records across native and x64
   readers; and prove repeated save/reboot/reopen/execute cycles without directory
   damage or lost editable state. The writable three-boot project test now uses
   QEMU `486,-fpu`: F1 returns from packaged help to the same editor, F5 executes
   and saves the program, two later boots reopen and revise it, and an independent
   RedSea extent/bitmap audit verifies the persisted tree.
3. **Native programming services.** Close the public memory, task, file, compiler,
   exception and debugging contracts reached by representative programs. Cover
   I64, software F64, retained definitions, multiple cooperative tasks and
   allocation/error recovery through user-visible workflows.
4. **Integrated workstation acceptance.** Add embedded graphics, mouse and
   PC-speaker use; measure peak memory, retained growth and input/interrupt
   latency under editing, compilation and disk activity. Pass a normal manual
   QEMU session at 8 MiB, no-FPU execution and 386 instruction audits. Native self-rebuild at
   16 MiB remains the following major goal and M7 gate.
   The normal HolyC scope now exports `Snd` and `SndRst`. `Snd` maps the
   original Ona note scale to PIT channel 2, gates the PC speaker through port
   `0x61` and preserves interrupt state. QEMU/486-no-FPU checks latch the 440 Hz
   divisor and verify on/off/reset gate transitions. Emulated audio output and
   timer coexistence remain integration checks; physical speaker tests are deferred.
   The boot kernel now enables the auxiliary 8042 port and IRQ12, decodes
   standard three-byte PS/2 packets and exposes bounded VGA coordinates, three
   buttons and a packet counter through `MouseGet` in normal HolyC. QEMU hardware
   injection verifies relative motion and left-button transitions while the
   combined keyboard/mouse/speaker group proves shared PIC/8042/PIT operation.
   Auxiliary setup is optional: failure retains normal keyboard-only boot with
   IRQ12 masked and an unavailable `MouseGet` result.
   `DocEd` now consumes left-button transitions and maps VGA cells back to
   canonical insertion points using the same tabs, newlines, wrapping and
   horizontal/vertical viewport projection as rendering. Exact VGA and saved-byte
   checks cover insertion on a clicked line and a click through a vertically
   scrolled viewport. `DocEd` also composites a visible XOR arrow directly during
   VGA upload while retaining clean text/graphics backing planes; movement restores
   only the old and new cursor rows. The file picker now uses the same overlay;
   clicking a visible row selects it, and the existing Enter path opens the
   selected file. The help viewer now composites the same pointer, maps clicks
   through its visible text projection, selects a link, opens it through the
   existing Enter path, and restores pointer ownership on nested return. Pointer
   composition in the console, broader
   window-manager routing, wheel negotiation and the planned serial-mouse profile
   remain open. Holding the left button now extends a canonical selection in
   either direction; the editor splits text at both endpoints and reuses the same
   selected entries as keyboard selection, clipboard operations and replacement.

Each workstream starts with an outcome-level failing test. Use original x64
behavior where it is the semantic oracle, exact file bytes for persistent
formats, and real QEMU keyboard/VGA observations for the integrated experience.
The goal closes with one documented manual session and an automated writable-disk
scenario covering the whole daily loop; isolated component checks alone do not
satisfy it.

The end-to-end acceptance story is deliberately user-sized: boot a clean normal
image, use the mouse and keyboard to browse the packaged help and source tree,
create a project directory and a multiline HolyC/DolDoc program, compile and run
it, inspect a source-linked error, repair it, interrupt a runaway version, add a
small graphic and sound, save, reboot, reopen and run the same project again.
The session must finish with the editor and compiler still usable and with no
unbounded task-heap growth or RedSea damage.

Build toward that story in these medium-sized increments, each leaving the normal
image useful on its own:

1. Finish pointer ownership and activation across help, file dialogs, the console
   and the editor. File-picker items and help links now share a 500 ms
   double-click/open path with keyboard Enter. The idle HolyC console now displays
   the same transient pointer and hides it on keyboard input. Editor dragging at
   the bottom screen edge now advances the viewport and canonical selection;
   dragging into the fixed header advances it toward earlier rows. Dragging at
   either horizontal edge also advances the viewport and selection
   on a long unwrapped line. Held-edge scrolling now repeats on the timer without
   another PS/2 packet; keyboard-only fallback acceptance remains. Keep wheel
   and serial-mouse support optional
   until the core workflow is stable.
2. Replace the remaining reduced editor actions with the original DocEd/ExeDoc
   paths needed by create, open, edit, diagnose, save and execute. Expand DolDoc
   layout only as the acceptance project reaches records that the current
   projection cannot preserve or operate.
3. Join compiler diagnostics, source links, breaks and allocation failures into
   the editor loop. Every failure case must return to an editable document and
   preserve successful prior definitions and exact saved bytes.
4. Run the workflow on a writable disk over several boots, then add concurrent
   task, graphics, speaker and disk activity while measuring input latency, peak
   memory and post-session heap use on the 8 MiB no-FPU profile.
5. Audit executable code for the 386 instruction contract and repeat the final
   workflow on the pinned QEMU no-FPU profile. Record memory and responsiveness
   before beginning self-hosting; physical and SX/DX certification are deferred.

## Following big goal: M7 self-hosting 32-bit TempleOS workstation

**Goal:** Starting from a normal bootable disk on the 32-bit 386+/VGA target,
use TempleOS itself to browse, edit, compile, link and rebuild the complete
native system without an x86-64 host compiler or test harness. Install that
build onto a fresh RedSea disk, boot it, and repeat the rebuild from the system
it produced. Preserve the defining model: HolyC as the system language, DolDoc
as the development interface, one privileged address space, cooperative tasks,
direct hardware access, RedSea storage, interactive compilation, graphics,
sound, help and source-linked diagnostics.

The standalone-development goal above is the entry gate. M7 then requires:

1. **Complete native source build.** All sources needed by the i386 kernel,
   compiler and runtime compile inside the installed OS. The build consumes
   only files and tools on the guest disk, reports source-linked failures, can
   be interrupted, and leaves the running development session usable. Build on
   the shared T32M serializer now exercised by both bootstrap and guest code:
   teach the native frontend to emit complete relocatable modules, then compile
   the delivered source tree on the guest before claiming this gate.
   The first durable step writes a guest-serialized T32M to RedSea, reopens and
   executes it, then repeats the load on a second writable QEMU boot. Extend
   this path to complete source-built modules and installation artifacts. The
   native frontend now retains named call relocation sites long enough to
   package a recursive compiled function as T32M. A native compiler service
   now packs multiple live functions with internal named calls, and a writable
   QEMU image persists that module across boots. The same packer emits T32M
   data ranges for function literal pools. A one-function module now retains
   its unresolved named call, binds it to a resident function at load time,
   and survives the two-boot RedSea round trip. The guest also packages the
   call target as a second T32M and links both files without a resident
   binding. The native frontend now retains named function-address relocations,
   so a guest-built module can return a pointer to a function in the second
   module after loading at a new address. It also retains named global-data
   address sites for load-time binding to resident storage. The native packer
   now places selected pointer-free initialized globals, including scalar and
   class storage, in the same module as their referring functions, with named
   data exports and mutable loaded storage. The guest packer now emits stored
   pointer records for initialized pointers that target another selected data
   range in the module. Version-4 named stored-pointer records now allow an
   exact exported symbol in a second module to be resolved at load time; the
   native probe packages and persists a pointer-bearing consumer and its data
   provider separately. Compiler services version 56 now collects and packages
   every owned function and global definition from a private source unit; a
   guest-built unit with three functions, one global and scalar function-local
   static storage survives two writable boots. Local static code references
   now relocate to owned data in the module; packing the function without its
   static data is rejected. The source-unit packer now retains separately
   allocated literal pools referenced by initialized global or static pointers
   as private data ranges, with local pointer relocation. A guest-built unit
   exercises mutation through such a pointer across writable boots. The guest
   now reads the delivered `/Kernel/KMathInt.HC` from RedSea, packages its five
   original functions as one relocatable module, and executes signed and
   unsigned I64 cases after loading it. This is the first production source
   file on the guest-built module path, not a complete source-tree rebuild.
   The guest also compiles `/Kernel/ArcSeed.HC` through its nested headers,
   packages `ArcCtrlSeed`, and checks both compression modes after loading.
   Direct source-unit compilation now owns preprocessor definitions in a
   private table, so header macros are released when the compilation control
   unwinds; the two-phase QEMU probe checks the heap returns to baseline.
   The guest now also packages the delivered `/Kernel/ArcExpand.HC` through
   its shared Arc header and runs its callback success and reader-error paths.
   This file needs the normal kernel prelude's `TRUE` and `FALSE` definitions;
   the isolated source unit supplies those definitions transactionally. The
   retained file module now enumerates selected named exports through a
   versioned service. The kernel validates and publishes these as resident
   symbols; the guest compiles `/Kernel/I386/ArcExpand.HC` against its retained
   `I386ArcEntryGet` dependency, packages only functions generated in that
   source unit, and binds the import when loading the module. This establishes
   one real cross-module source-build path. The same resident-export contract
   now covers `CompilerRuntime`: the kernel publishes its `I386ModulePackRaw`
   entry, and the two-phase guest probe verifies that the root symbol and
   compiler service point to the same retained code. The compiler runtime
   also exports `I386ModuleValid`. Using an explicit validator declaration,
   the guest now compiles `/Kernel/I386/ModulePackCore.HC`, links its validator
   call to the retained compiler module, and compares its serialized T32M
   byte-for-byte with the resident serializer across two writable boots.
   This exercises rebuilding a function whose name already exists in the
   root scope. The guest also compiles the original validator and serializer
   together as one source unit: the call resolves internally, both functions
   load without resident bindings, and the saved module survives two writable
   boots. This larger unit exposed the diagnostic worker's 512 KiB private-heap
   limit; the worker now gets 1 MiB and returns it at exit on the 8 MiB QEMU
   profile. The guest now also compiles the original `/Kernel/I386/ModuleLoad.HC`
   and its included validator: eight owned functions and 18 internal calls
   survive two writable boots. Its source-built loader produces the same image
   as the resident loader for a simple module, executes that image, and rejects
   malformed input without writing the destination. The guest now compiles
   `/Kernel/I386/ModuleAlloc.HC` through the original heap and loader sources:
   sixteen owned functions and 28 internal calls build into one T32M. A private
   source-build definition selects a HolyC heap validator; the boot kernel
   retains its faster 386 assembly validator. The guest-built allocator owns a
   private heap, loads and executes a module, rejects malformed heap/module
   input, and frees its allocations. The HolyC validator's performance in a
   fully native-built kernel remains to be measured. The guest now also compiles
   `/Kernel/I386/ModuleFileSingle.HC` through that heap/loader source graph.
   Three validated kernel RedSea exports satisfy its disk dependencies, and
   the guest-built loader reads the original Startup T32M inside an explicit
   RedSea I/O session, matching the resident loader's image across two writable
   boots. The guest now compiles `/Kernel/I386/ModuleFile.HC` as well: its
   original file-set loader reads two linked modules from RedSea, resolves a
   cross-file data pointer, executes the result, and reclaims its heap image
   across two writable boots. The full `tools/build-i386-kernel.py --test`
   promotion also passes for this file-set milestone: interactive console and
   document checks, persisted-module reboot, 13 move-I/O interruption cases,
   seven replacement-I/O interruption cases, and the original DolDoc reader.
   The guest now also compiles the original `/Kernel/I386/RedSeaCreate.HC`
   through ten validated resident disk services. Its saved module creates,
   rereads, and deletes a file on a writable QEMU disk across two boots;
   the duplicate-name and invalid-name paths are checked. Next build the
   native installation path from this creation primitive. A guest-built
   `/Kernel/I386/RedSeaFormat.HC` now initializes a separate blank 16 MiB
   secondary IDE target under QEMU. The host audits its empty RedSea root,
   bitmap and reserved boot area; a second boot reloads the saved formatter
   and verifies that the existing volume is not changed. The guest now mounts
   that target and uses its source-built RedSea creator to publish
   `InstallSeed.HC`; the host checks its bytes, directory entry and bitmap,
   while a second boot confirms the file and target image remain unchanged.
   The same guest-built creator now lays out `/Kernel/I386` on the target and
   copies the actual `RedSeaCreate.HC` source file from the boot volume. The
   host verifies the exact source bytes, directory links and bitmap; a second
   boot finds the existing tree without changing the target. The file-level
   tree copy now covers the complete source and module set. From an ordinary
   HolyC console,
   `I386BuildModule` compiles the delivered `RedSeaCreate.HC` into a T32M on
   the mounted installation disk. Two writable boots produce identical module
   hashes; after the target boots alone at 8 MiB, its installed compiler
   builds the same source again. It also packages the original
   `Compiler/I386/LexNumber.HC` and its included lexer body into a second,
   byte-stable T32M across boots and rebuilds both components at 8 MiB.
   These are real native source modules, not a native rebuild of the complete
   compiler or boot kernel.
   A normal boot now detects and mounts a formatted secondary volume as `D:` through the retained
   task file service. The interactive HolyC console reads the copied source,
   creates a directory and writes a document on `D:` at 8 MiB; the host audits
   the saved bytes and bitmap. This gives the future installer a standard
   guest file-service path to both volumes.
   The BIOS load reservation is now 896 sectors, ending at `0x80000`, with
   32 KiB before the task-stack reservation; the current image has 1,648
   bytes of load-area headroom. More native code belongs in retained modules
   or must be paired with a revised boot/memory layout.
   A normal guest boot can now copy its complete host-built Generation 0 disk
   to a blank second IDE disk, flush all nonboot sectors, publish LBA 0 last,
   and boot the exact copied image independently. This validates boot-media
   transport, including source and module bytes, but does not build those bytes
   on the target. Controlled interruptions after sector 8192 and after the
   final nonboot-sector flush now leave an unbootable but retryable target;
   exact-sector audits and retries pass in QEMU. Abrupt power-loss recovery
   remains unverified. Next replace the image clone with publication of
   guest-built artifacts and extend the interruption matrix to that path.
   The remaining compiler/kernel dependency graph still needs validated resident
   exports, the full kernel prelude, and complete in-guest compilation.
   Broader pointer-target identity and full source-tree coverage remain open.
2. **Bootable native installation.** The native build can format or initialize
   a fresh RedSea target, publish the rebuilt system failure-atomically, and
   produce an independently bootable disk. An interrupted installation leaves
   either the prior bootable system or a recoverable target. The blank-target
   RedSea formatter, guest target mount and source-built seed-file creation pass
   a two-boot QEMU test. A separate exact-image-copy test boots the copied
   host-built Generation 0 disk alone. Publishing rebuilt kernel/compiler
   artifacts remain open. A normal guest boot now copies all 828 packaged
   source/module files to their real paths through the mounted task file API;
   independent host checks verify every file hash and the target bitmap after
   both an initial copy and an existing-tree retry. A bounded 200-file pass
   also leaves a valid partial RedSea tree that a second boot completes and
   independently audits. A normal HolyC command, `I386InstallBoot`, publishes
   only the reserved boot sectors after file installation; it leaves RedSea
   sectors unchanged and boots the file-installed disk independently in QEMU.
   Guest-built RedSea creator and compiler-lexer T32Ms also persist on that
   installed disk.
   This still publishes host-built Generation 0 boot bytes. The clone transport
   has two injected interruption/retry cases;
   actual power-loss and rebuilt-artifact recovery remain open.
3. **Two-generation self-hosting.** A host-built Generation 0 produces native
   Generation 1; Generation 1 boots and produces Generation 2. Generation 2
   has equivalent public behavior and persistent formats, and can rebuild the
   same source tree again without retained host-built compiler state.
4. **QEMU PC-class acceptance.** Automated promotion covers the pinned QEMU/TCG
   `486,-fpu` profile and a later 32-bit CPU profile, with executable-region
   audits preserving the 386 instruction baseline. Interactive acceptance uses
   8 MiB and the complete native build uses 16 MiB. Dedicated SX/DX emulators
   and physical 386+ VGA machines are deferred and do not block M7.
5. **Release evidence.** Compiler semantics, allocation ownership, task and
   exception recovery, persistent compatibility and installation interruption
   are automated. A documented manual session creates and fixes a program,
   follows help and diagnostics, runs and interrupts it, reboots, rebuilds the
   OS, installs the result and boots the rebuilt disk.

M7 closes only with the second native generation booted and verified. A
cross-compiled image, a native rebuild that cannot install itself, or component
tests without the complete disk-to-disk workflow do not satisfy it.

### Next major TDD milestone: original-source project workflow

**Goal:** Starting from a normal 8 MiB boot, complete a small HolyC project using
the OS itself: browse to a nested project, create and rename source files, edit a
multiline executable DolDoc through the original editor path, follow help and
compiler diagnostics, run and interrupt the program, save it with failure-atomic
replacement, delete an obsolete regular file with confirmation, reboot the same
disk, and resume the project with its source, document records and output intact.
No step may require a host compiler, injected command, diagnostic boot or host-side
filesystem repair.

Develop this as one vertical acceptance with smaller red/green contracts:

1. **Project mutations — regular-file lifecycle complete.** File and directory rename,
   collision and missing-path behavior, directory protection on delete,
   transactional picker refresh and exact allocation-bitmap ownership after
   create/rename/delete cycles now pass, including safe removal of empty directories
   and rejection of nonempty ones. Cross-directory regular-file moves now pass
   exact-byte, rejection and three-boot filesystem-integrity coverage.
   Deterministic move-transaction injection now stops before source reading,
   before destination creation, after destination publication and before source
   deletion; every stage preserves the source, removes the destination and passes
   a clean reboot plus exact bitmap audit. Raw sector-write/flush injection now
   covers all seven writes and six flushes in a journaled cross-directory move.
   A persistent header intent lets mount recovery roll back a duplicate
   destination while the source remains, or accept the destination once the
   source tombstone is durable. Mount-time reconstruction repairs allocation
   bits from the reachable tree; every case retains exactly one complete file
   and an exact bitmap. Cross-parent directory moves remain.
2. **Original editor path.** Drive the original `DocEd`/`DocRecalc` action and
   handler dependencies from real keyboard events. Compare text, cursor,
   scrolling, embedded-record placement and saved bytes with original x86-64
   behavior. Replace prototype expectations only after the equivalent original
   path is green.
3. **In-place development recovery.** From that editor, compile and run I64 and
   software-F64 code, retain a definition, navigate a source-linked diagnostic,
   correct it, catch a runtime exception and interrupt a loop. Prove the document,
   prior definitions, locks and task heap remain usable after every recovery.
4. **Atomic persistence and compatibility.** Inject failures before allocation,
   data flush, directory publication and old-extent reclamation. After every
   failure, reboot and require either the old or complete new file, a mountable
   tree and a bitmap matching reachable extents. Cross-read representative
   ordinary and embedded-record documents with the original x86-64 target.
   Raw replacement injection now covers all four writes and three flushes: every
   recovery retains exact `OLD` or `NEW` bytes, clears transaction state and
   matches the reachable allocation bitmap. Original/native cross-reading
   remains open.
5. **Promotion.** Repeat the complete workflow after reboot, run twenty bounded
   edit/run/error/save cycles, and record live/peak memory, input and interrupt
   latency. Finish with a documented manual QEMU session on the normal image,
   386 instruction audits, QEMU no-FPU execution and the complete build/rebuild gates.

Use the focused group for the current failing contract during development. A
matching image hash qualifies a prior exhaustive interactive result for the same
artifact; the release promotion still rebuilds, boots, audits the writable disk
and runs the full suite once. This keeps TDD feedback bounded while preserving
the complete integration evidence.

### First workstream: TDD-driven native DolDoc development session

**Goal:** On the normal 8 MiB native image, use the original DolDoc editor to
create and edit a multiline HolyC program, execute it, recover from a syntax
error and an interrupted program, save it to RedSea, reboot the same disk,
reopen it and execute it again. Preserve canonical documents, shared ring-0
execution, task ownership, and the original file format. This completes the
editing-session medium goal in [the dependency analysis](docs/i386-doldoc-integration.md)
and advances M4/M5; it does not complete all of M5, self-hosting or full QEMU-PC
acceptance. Status: **in progress; multiline editing, navigation, executable
documents, replacement persistence, relative/deep project paths, timed blink
rendering, file-level `Ed` save/cancel, direct Ctrl-S save and allocation integrity pass, while original-editor integration,
full DolDoc compatibility and failure durability remain open**.

### Readiness and test boundaries

We have enough infrastructure to start TDD now: focused native console groups,
original-x64 comparisons, QEMU keyboard/VGA checks, writable-copy two-boot
acceptance, mutation verdict checks, and full rebuild/boot regressions. These
provide different evidence. Existing window mutations demonstrate that those
assertions detect two faults; they do not establish editor coverage. The current
native persistence test covers five root-directory plain-text files. The shared
loader round-trip corpus runs under original x64, not the native console.

Add missing tests with each implementation slice. Use three complementary
oracles: original x64 behavior for document semantics, explicit expected text and
file bytes for stable format contracts, and hardware-input/VGA checks for the
integrated native user experience. Shared code agreeing with itself is
insufficient. Keep assertions on outcomes and ownership, not incidental native
addresses, allocation order or the prototype's extra cursor cell.

### Ordered implementation slices

1. **Establish the next failing contract — complete for the prototype.** Extend the session acceptance with
   Enter/newline, cursor movement across lines, an insertion and a backspace
   joining lines. Capture expected text, cursor position and serialization from
   the original editor; add native assertions for the same sequence. Preserve
   the current passing single-line acceptance separately. The new test must
   fail at the missing multiline behavior on the current image, after successful
   boot and editor entry. A boot failure or timeout is not the intended red result.
   The original/shared oracle first failed at post-join insertion, then passed
   after newline insertion and newline deletion were added. A 13-command native
   focused run and a two-boot hardware-keyboard/VGA acceptance now pass the same
   sequence. This closes the first test slice only; it does not substitute the
   prototype for the original editor work in slices 2–4.

2. **Integrate original editing and document lifetime — in progress.** Connect the required
   original `DocNew`, `DocPutKey` and entry/navigation dependencies rather than
   extending the small native editor into a permanent replacement. Add newline,
   tab, arrows, Home/End, Delete and Backspace vectors, including empty documents
   and line boundaries. Compare contents, cursor and serialization on both
   targets. Exercise repeated create/reset/delete and allocation failures;
   document queues, task heaps and locks must remain valid after failure.
   Home, Right, Delete, Tab and End pass an eight-point original/shared oracle.
   Up/Down now pass a separate eight-point preserved-column oracle, including
   short lines and top/bottom limits. Eight more cases cover an empty document,
   an empty middle line, structural cursor serialization, `DOCF_NO_CURSOR`, and
   insertion there. Five further cases cover removing that insertion, Delete and
   Backspace line joins, and no-op behavior at the document limits.
   Native focused assertions and a real QEMU keyboard/VGA save/reboot/reopen
   session cover the same behavior. Tab restoration is included in the six-point
   original-save/shared-load round trip. Twelve deterministic allocation and
   recovery outcomes now cover construction, entry creation, text replacement,
   newline insertion, serialization, load cleanup, lock release, heap balance
   and subsequent successful editing and reopening. Failure-atomic persistent
   file replacement and
   replacement by the complete original
   `DocPutKey` dependency path remain open, so this slice is not complete.

3. **Integrate original layout and editor input.** Bring up the required
   `DocRecalc`, `DocEd` and `MakeDoc` handler dependencies over the retained VGA
   and task services. Test wrapping, scrolling beyond the viewport, cursor
   placement and return to the existing prompt using real keyboard events.
   Verify put/display/border document pointers, input handlers and locks are
   restored on normal exit and exception. Add one bounded embedded-graphics
   fixture and callback/handler case. Replace prototype-only rendering
   expectations with the original document semantics as this slice lands.
   The retained renderer now has a bounded 56-row body viewport. A 65-line
   hardware/VGA case proves that the heading stays fixed and Up moves the
   viewport with the canonical cursor. A separate 100-column case proves
   cursor-following horizontal panning from End to Home when word wrap is off.
   Page Up and Page Down now move 55 logical lines through the 56-row body; an
   exact 65-line hardware/VGA case proves line 63 to 08 and back to 63.
   Original Ctrl-Up/Ctrl-Down document-boundary bindings now move to the cursor
   before line 00 and after line 64 in the same exact-frame sequence.
   A real Ctrl-Alt-C while the native editor is waiting now propagates through
   its exception boundary after restoring the task's put/display documents and
   console surface. The hardware test also proves the document lock and pending
   break are clear and the compiler remains usable. Original `DocRecalc`,
   border/input-handler integration and the rest of the
   original editor restoration contract keep this slice open.
   The first bounded embedded-graphics increment is also present: after an
   exact RedSea save/reopen, the native editor interprets original color,
   point, line and filled-rectangle sprite records and composes them over its
   text on the VGA framebuffer. The dedicated `document-sprites` QEMU group
   checks exact pixels independently of the larger editor suite. Full `Sprite3`,
   original `DocRecalc` placement and malformed-record coverage remain open.
   F1 now opens the packaged Help Index through the native viewer, while
   Shift-F1 opens About TempleOS. A hardware acceptance opens help from an
   unsaved document and requires Escape to restore its exact text, cursor and
   editor frame before the session continues.
   F4 now opens the native file picker at the active document's parent path and
   inserts the selected absolute filename through canonical editor input.
   Shift-F4 selects and inserts a directory name. Each complete path is one
   undo point; Escape cancels without changing the document. Standalone `EdDir`
   retains directory traversal, file editing and project mutation behavior.
   Ctrl-F now captures a bounded search string, F3 repeats forward and Shift-F3
   repeats backward with wrapping. Search projects adjacent canonical text,
   newline and tab records into a temporary logical stream and maps a match back
   to its exact entry and column. Exact VGA tests cover the prompt, first match,
   next match, reverse repeat and visible `Not found` state. Temporary projection
   allocations unwind locally and preserve the document lock on failure.
   Tab from the Ctrl-F search field now accepts replacement text and replaces
   the next match through canonical `DocPutKey` deletion/insertion. Exact VGA
   checks cover both prompt fields and the resulting document. Replace-all,
   confirmation/skip choices, options and selection-scoped semantics remain open.
   Alt-Backspace now walks a sixteen-level stack of pre-mutation canonical snapshots for
   ordinary typing, deletion, style changes and replacement. The snapshot is
   published only after complete serialization, includes the cursor and embedded
   records. A seventeenth edit evicts the oldest complete snapshot; editor exit
   releases the entire stack. Continuous insertion, Backspace and Delete runs
   now coalesce for one second; operation changes, cursor movement and command
   actions close the run. Exact VGA coverage proves that a typed word undoes as
   one operation while timed-apart edits retain distinct document/cursor states.
   Shift-Left and Shift-Right now split
   canonical text records at exact character boundaries, mark the traversed
   records with the original selection bit, render them inverted and let typing,
   Backspace or Delete replace the selected span. Exact VGA coverage selects two
   characters and types over them. Ctrl-C, Ctrl-X and Ctrl-V now copy, cut and
   paste selected canonical records through a retained native clipboard; a new
   complete copy replaces the prior clipboard, cut/paste participate in undo,
   and exact VGA checks cover the full sequence. Paste now serializes and loads
   the complete clipboard into a staging document, completes any cursor split,
   then publishes entries and binaries without another failure point. The
   allocation gate fails every discovered step and requires identical target
   bytes and heap ownership. Reversing Shift-Left or
   Shift-Right toggles the traversed canonical character back out of the
   selection, with exact selection-color/cursor coverage. Vertical/document-wide
   selection. Ctrl-Shift-Up and Ctrl-Shift-Down now select canonical records
   from an exact cursor boundary to the document start or end, enabling
   whole-file cut/copy/paste with exact VGA coverage. Shift-Up and Shift-Down
   now select multiline canonical ranges between equal visual columns, including
   newline records; typing over the range has exact VGA coverage. Shift-Page-Up
   and Shift-Page-Down use the same canonical range operation across the 55-line
   viewport while preserving the visual column. Reversing either vertical/page
   movement toggles the same canonical range out of the selection, with exact
   VGA cursor and selection-state coverage.
   Ctrl-G now captures a bounded positive line number and positions the
   canonical cursor at that line's first editable byte. An out-of-range request
   preserves the prior cursor and renders `Line not found`; exact VGA tests cover
   the prompt, successful move and rejection.

4. **Execute and recover within the document workflow.** Add an acceptance that
   types a small multiline program through the editor, invokes the original
   execution path, and checks visible output and a retained definition. Include
   I64 and software-F64 results. Then introduce and correct a syntax error,
   exercise a caught runtime exception, and interrupt a nonterminating program
   through keyboard input. The document, prior definitions and subsequent
   execution must survive. Calling the compiler directly from the harness is
   component coverage, not completion of this user-visible gate.
   Retained `DocExe` now converts a locked canonical document to cursor-free
   source and feeds the live console compiler. A focused check executes a
   multiline program, observes `42` and reuses its retained definition. The
   writable acceptance uses F5 to save and execute that program, reboots the same
   disk and executes it again. This save-before-execute order matches the original
   F5 command and is proved without a harness-side `DocWrite`. Native `DocEd` now
   binds F5 to a result view: hardware-keyboard
   acceptance reports and corrects a syntax error, survives a thrown runtime
   exception, and interrupts a marked infinite loop with Ctrl+Alt+C before
   returning to the same document. Native diagnostics retain the current token's
   source line; after Escape, an error in the edited file places the cursor at
   the first byte of that line. A multiline hardware test navigates from line 3
   to the error on line 2, corrects it and reruns all three expressions. A
   separate F5 document produces the expected
   software-F64 `3.75` result. The source snapshot releases `DocLock` before
   execution so breaks are deliverable. The original `ExeDoc`/editor action
   remains open.

5. **Persist the complete session and verify compatibility.** Extend the writable
   two-boot acceptance to save the edited program, replace it with changed
   contents, reboot, reopen and execute the saved revision. Assert text/cursor
   state, embedded-record contents and output; check directory/allocation
   integrity and include a nested-directory file. Cross-read original-x64 and
   native saved fixtures, preserving the fixed-width binary-record span. Add a
   controlled failed-write case: report failure, retain the editable document,
   release file ownership, and verify the filesystem's documented failure
   behavior. Do not infer crash-safe saving from successful writes.
   The acceptance is now a three-boot scenario: it creates and executes `42`,
   reopens and changes the program to `48` with hardware keys, saves through F5,
   then reboots and executes the persisted revision as `48`. Exact source/cursor
   and VGA checks pass. F5 on a missing-parent path now visibly reports `Save
   failed`, executes the in-memory source, and returns to the intact editable
   document. Public `DirMk` now creates `C:/Project`, and F5 saves and executes
   `C:/Project/Sub/Main.HC` before a later boot reopens and executes it again.
   The same session saves `Project/Sub/Relative.HC` through relative-path
   resolution, reboots, reopens it by the same spelling and executes `64` again.
   An independent disk walk verifies directory parents, nonoverlapping reachable
   extents, exact project bytes and a bitmap matching all reachable allocations.
   Embedded records, original/native cross-reading and injected I/O failure
   remain open; a missing parent proves application recovery but does not
   establish crash-safe replacement.
   Ctrl-S now provides the original save-without-execution path with a visible
   success/failure result. Hardware-keyboard checks reopen the resulting exact
   bytes and verify that failed saves preserve the editable in-memory document.
   A retained file-level `Ed(path)` workflow now loads or creates a document,
   saves on Escape and discards the session on Shift-Escape. Its create/save and
   cancel behavior pass hardware-keyboard checks and a three-boot disk audit.
   The native reader/writer now preserves the original 16-byte `CDocBin` trailer
   and a bounded canonical `$SP,"tag",BI=n$` reference. Exact in-memory and
   RedSea save/reopen tests verify renumbering, entry-to-payload linkage, flags,
   sizes, arbitrary bytes, truncated-input rejection and all four allocation
   failure points. General embedded commands, original/native cross-reading and
   injected disk-write failure remain open.

6. **Close resource and automated regression acceptance.** At 8 MiB, run at least
   20 edit/execute/error/save/reopen cycles after warm-up. Account for intentional
   persistent definitions and caches separately; temporary document, compiler,
   file and exception state must return to a bounded baseline without per-cycle
   growth. Record usable RAM, resident/peak allocations, bootstrap headroom,
   normal boot time, key-to-visible-update latency and interruption latency.
   Include a small program and a document longer than one screen. Keep the normal
   boot check's existing 60-second development deadline; establish and record
   latency budgets from the first original-editor measurements before closing
   this slice. Finish with full regression and recorded QEMU evidence.
   A manual QEMU run is optional exploratory feedback, not a completion gate.
   A guest-side acceptance now completes one warm-up plus 20 create, edit,
   save, reopen, execute, runtime-exception and cleanup cycles. Every measured
   cycle returns the shared task heap, exposed through both the data and code
   handles, to its exact warmed baseline, and retained execution state advances
   exactly once per cycle. MemoryRuntime ABI 10 measures allocations at their
   source: the warmed baseline is 1,352,216 live bytes, the live peak is
   1,355,832 bytes and reserved capacity peaks at 1,356,800 bytes. The focused
   `document-resources` QEMU/VGA group and native self-rebuild gate pass.
   The focused long-document Up-key-to-exact-VGA measurement is 0.204 seconds
   and interrupt-to-recovered-VGA measures 0.217 seconds; both pass a one-second
   development budget. The complete writable three-boot gate records a
   conservative accumulated interrupt value of 0.275 seconds and passes. A
   repeatable long-document human checklist is documented; an observed manual
   run remains open. The
   complete gate also passes with the pre-instrumentation resource case in the
   accumulated interactive session: 357 native commands, 420 submitted lines,
   44.407-second normal startup and 159.598-second diagnostic startup.

### TDD execution and completion rules

- For each slice, add a focused assertion, observe the intended failure, implement
  the smallest coherent original-code integration, then refactor with the tests
  green. Retain the previous passing session throughout. Missing compiler/runtime
  dependencies become bounded prerequisites with their own failing tests; do not
  stub away original semantics to pass the outer scenario.
- Use the existing `documents`, `text`, `windows`, `graphics`, `sound`, `compiler` and
  `breaks` groups as appropriate. Add focused cases or groups where needed.
  Rebuild the image after OS changes; tests against an older image are not
  evidence for the current source. Commands are in [the test workflow](docs/i386-test-workflow.md).
- Before closing the goal, add representative editor and persistence mutations,
  such as dropping a newline edit and reporting save success without writing.
  Require the corresponding content or post-reboot assertion to detect each
  fault after a clean baseline. Crashes, timeouts and unrelated failures remain
  inconclusive. Keep injections in disposable guest state or copied test disks.
- At each completed slice, run the affected focused checks and full
  `tools/build-i386-kernel.py --test`; run `tools/test-rebuild.py` first when
  Kernel/Compiler sources change. Run the expanded two-boot acceptance for
  changes affecting the session. Record source/image hashes, tested profile,
  actual checks, logs and screenshots with each milestone result.
- Close this goal only when the original editor path and the complete
  edit/execute/recover/save/reboot/reopen/re-execute acceptance pass together,
  resource measurements and budgets are recorded, and the workflow is usable
  manually without startup diagnostics or host assistance. Keep all six slices
  open until their evidence exists; the current prototype does not close them.

The current acceptance gate is QEMU/TCG with VGA and 8 MiB, with native rebuilds
at 16 MiB. Continue 386 instruction audits and no-FPU execution as relevant code
changes land. Physical-machine and dedicated SX/DX certification are deferred;
QEMU success is sufficient for current milestones once their complete functional
and resource gates pass. Full help layout, mouse/window-manager integration,
emulated speaker behavior, broader DolDoc features and native rebuilds retain
their M5–M7 gates.

For the next M7 self-hosting slice, compile the full
`Kernel/I386/CompilerRuntime.HC` source from a normal 16 MiB QEMU HolyC session.
Its existing host-built T32M is about 1.5 MiB, so the source builder permits a
4 MiB output. Parsing originally stopped at the line-14 `I386HeapAlloc` import;
the focused resident-import check and private module-source declaration path now
cover that boundary. Rebuild the full runtime and
verify its exports and relocations independently. Require two byte-identical
guest builds before replacing the retained Generation 0 compiler; run the
existing smaller RedSea and lexer builds as regressions. A guest-built compiler
artifact alone does not close M7: execution, second-generation rebuild and boot
verification still follow.

The resident-import prerequisite now has a two-boot regression: a guest-built
fixture must export two functions and retain one named `I386HeapAlloc` call and
one named `char_bmp_hex_numeric` address reference. Both module imports work in
the focused QEMU run. The full compiler runtime now passes its original first
import and first lexer-function boundary, but its 16 MiB compile exceeded a
900-second command deadline while QEMU remained CPU-bound. The builder logs a
source location and live heap use every sixteen top-level commands. Use that
evidence in the next bounded full-runtime run to distinguish slow parsing or
code generation from an allocation limit. A packaged T32M and independent
export/relocation audit remain the immediate acceptance target.
The first instrumented 16 MiB run reached command 336 at
`CompilerRuntime.HC` line 34 in 360 seconds, with about 5.7 MiB live heap and
no reported compiler error. Continue with a longer bounded run using these
checkpoints; avoid treating the prior timeout as a parser rejection.

A 16 MiB QEMU/KVM development run now reaches the optimizer source. Its first
rejection was an internal `Bsf`/`Bsr` call in `OptPass012Core`: the 32-bit
backend already emits these operations, but the intrinsic signature validator
omitted them. The validator now accepts their original declarations, and
focused intrinsic probes cover high 64-bit positions and zero input. The next
run compiled `OptPass012Core` and advanced to the top-level `asm` block in
`Compiler/I386/Divide.HC`, where the native source frontend rejects the unit.
The next prerequisite is a relocatable representation of this division
template that the guest can build while preserving its i386 instruction
semantics and the host/guest byte contract. QEMU/KVM is only a development
accelerator for this long source build; TCG remains the promotion profile.

The native two-generation rebuild and cross-build/386 audit pass. Both TCG
intrinsic-probe phases publish all 37 declarations and return the expected
bit-scan results. The current complete `--test` attempt is incomplete: it
reached install-tree interruption/resume verification, then exceeded the normal
60-second boot limit in `target-tree-copy/partial/resume` before submitting the
resume command. Revalidate that boot boundary and finish the remaining gates;
do not treat this checkpoint as a complete promotion or a guest-built compiler.

The division prerequisite is now met for module-source builds. The original
`Divide.HC` assembly still produces the host compiler's template; a private
module-source define selects a 185-byte data copy for the guest frontend. The
cross-build compares every byte of that copy with the host-assembled template.
Two independent 16 MiB QEMU/KVM source builds produced the same 1,596,488-byte
`CompilerRuntime.t32m` (SHA-256
`eaf79254f6d1a78644303e7c436766e3e7dd7e46fdadf497a3fba437b6aa7df9`).
The standalone auditor checks all records, the public export set, resident
imports, zeroed relocation slots, data ranges and division bytes. The second
artifact replaced the host-built compiler on a writable disk. Its next boot
executed HolyC and built the original `LexNumber.HC` under both KVM and TCG;
the two lexer artifacts were byte-identical. The complete current-source
`tools/build-i386-kernel.py --test` gate also passes, including the previously
timed-out install-tree resume. These results establish a working Generation 1
compiler. They do not yet prove a Generation 2 compiler or native kernel
rebuild. Next, rebuild the full compiler from a Generation 1 session, audit
byte identity and boot/use the result, then close the remaining M7 kernel,
workstation and resource gates. The Generation 1 TCG boot took 72.917 seconds
at 16 MiB, above the 60-second normal-boot development budget; improve and
remeasure it before claiming that latency gate. General source assembly
support remains a later language-completeness task; keep the template parity
check until the native assembler can build this block directly.

The first Generation 2 source build completed, but its T32M differed from
Generation 1 at 3,273 code bytes while its record and string sections matched.
The differing sites were loop break checkpoints containing the current
compiler's absolute `I386ExecutionBreakPoll` address. That address changes
when the next compiler loads and can become stale after reboot. The module
source backend now emits a named relative-call relocation for each checkpoint;
ordinary interactive code retains its direct runtime call. Before accepting
Generation 2, rebuild both generations with this change, require byte-identical
T32Ms, verify the break-poll relocation count and zeroed patch slots, then
boot and use Generation 2 in QEMU. A pre-fix Generation 2 artifact must not
be treated as self-hosting evidence.

The repaired two-generation compiler gate now passes. A 16 MiB QEMU/KVM
Generation 0 boot built Generation 1; a fresh boot from that compiler built
Generation 2. Both T32Ms are byte-identical (1,640,255 bytes, SHA-256
`2ec70524f3a103bbbf51de170111c4318b2d670c5e06d185d85490450aaceb89`).
The independent audit found 396 function exports, ten data exports, 1,092
named break-poll calls, and valid zeroed relocation slots. Generation 2 then
booted and built the original lexer source under both KVM and 486 TCG; those
lexer T32Ms also matched byte for byte. This closes the compiler-generation
subgate, not M7. Next, require Generation 2 to rebuild the native kernel and
publish a bootable disk from the installed source tree, then boot and verify
that disk under TCG. Complete the workstation/manual workflow and resource
gates as specified above. The Generation 2 TCG boot took 84.778 seconds at
16 MiB, so the 60-second normal-boot development budget remains open.

The first Generation 2 attempt to compile `Kernel/I386/Kernel.HC` reached
line 168, `asm { CLI }`, then returned a native-frontend-unavailable error.
No target module was published. This confirms the next kernel-build boundary
is the guest frontend's assembly service (currently rejecting assembly and
join requests), rather than compiler-generation drift. Implement its i386
assembly path with instruction, local-label, symbol and relocation handling;
exercise the actual kernel assembly sites, then build a native kernel module.
After that, close the distinct image/link/boot-sector publication and
installed-disk boot gates. A successful T32M compile by itself does not prove
a rebuilt bootable OS.

The first native inline-assembly slice is implemented through the shared
`IC_ASM`/AOT backend path for 386 zero-operand instructions (`CLI`, `STI`,
`HLT`, `CLD`, `STD`, `NOP`, `CLC`, `STC`). A compile-only fixture verifies their
exact bytes on both KVM and 486 TCG; the installed-disk module test also
rebuilds and audits it twice. A new Generation 2 kernel-source probe passed
the former `Kernel.HC` line-168 boundary and reached `Heap.HC` line 77,
`MOV EBX,U32 &hc[EBP]`. Continue the same assembler path with register and
memory operands, typed structure offsets, local labels and 386 relative
branches; keep rejecting forms whose encoding or relocation is not yet
defined. Then rerun the kernel source build to expose the following boundary.

That heap assembler slice is now implemented and measured. The guest accepts
the register, typed stack/structure memory, local-label and 386 relative
branch forms used by the original `I386HeapValid`, while rejecting unknown
forms. Compile-only operand and branch fixtures have identical KVM/486 TCG
bytes. The guest also built the original `Heap.HC` as a byte-identical T32M
under both accelerators; an independent instruction audit matched all 41
heap-assembly instructions and 14 branch targets against the host build.
The current Generation 2 kernel-source probe passes `Heap.HC` and stops at
`Gdt.HC` line 27 on `LEA EAX,U32 &descriptor[EBP]`. Extend the same assembler
for `LEA`, descriptor-table instructions and the remaining actual kernel
assembly sites, then require a complete guest-built kernel module. Keep image
linking/publication and boot of an installed disk as distinct M7 gates. The
full promotion suite has not been rerun for this slice; the focused installed
tree module regression passes with all three assembly fixtures rebuilt twice
and 840 expected target files verified.

The next native assembly slice now covers `LEA` on typed stack storage and
`LGDT`/`SGDT`/`LIDT`/`SIDT` on register-indirect descriptor operands. A 16 MiB
QEMU/KVM guest compiled the complete original `Kernel/I386/Kernel.HC` source
and published a 520,534-byte `GuestKernel.t32m`. The module parser validates
225 function and 85 data exports, 1,015 named calls, 454 address relocations,
106 nonoverlapping data ranges and its local data pointer. The inline-assembly
auditor matches the host's heap instructions/branches and the exact descriptor
instruction sequences in all four GDT/IDT functions. This establishes a
complete guest source-module build, not a bootable rebuilt kernel: next add a
native image/link and boot-sector publication path from that module, verify
its imports and entry/data layout against the installed source tree, then
boot and exercise the resulting disk under QEMU/486 TCG. Repeat kernel-source
builds and the complete promotion suite remain open.

The bootstrap-kernel source path now has an explicit `I386BuildModule` mode
that omits interactive loop-break checkpoints from early boot code. An ordinary
module retains them; the previous guest kernel had 223 unresolved calls to
`I386ExecutionBreakPoll`, which is only loaded later. With this mode, the
guest built a 506,909-byte kernel T32M with zero such imports. The six-module
flat image using that kernel and the five current boot helpers is 456,872
bytes. The BIOS load reservation is now 944 sectors, ending at `0x86000` and
leaving 8 KiB before the task stack at `0x88000`. A diagnostic host linker
first reproduced the existing host image byte for byte, then linked the guest
kernel into a disk without changing RedSea sectors. That disk booted under
QEMU/KVM and 486 TCG; HolyC evaluated `6*7`, and KVM rebuilt the lexer source.
The 386 boot audit passed. This proves the guest-compiled kernel can run, but
the link step and five helper modules were still host supplied. Next build
those helper modules in the guest and provide an on-machine linker plus safe
boot-area publication to an installed target; repeat the boot from wholly
guest-built outputs before claiming native kernel self-hosting.

The OS can now perform the six-module flat link itself. `I386BuildBootImage`
reads a selected kernel T32M and the five helper modules from mounted RedSea
drives, validates/resolves them with the native module loader at `0x11000`,
and writes a bounded flat-image file. Linking the guest-built kernel from a
second drive produced the same 456,872 bytes as the diagnostic host linker;
a missing helper set published no file. The installed-volume regression also
linked the six packaged modules twice across reboot, matching host
`Kernel32.BIN` byte for byte both times. This closes native file-level image
linking. Next publish that file into the reserved boot area with the boot
sector written last, then independently boot the installed target. The helper
assembly sources still need native compilation before the entire boot image
can count as guest-built.

The native installer now accepts a linked flat-image file. It validates the
entry trampoline and size, copies the trusted source BIOS/stage and reserved
sectors to a separate blank-boot target, substitutes the linked image in the
944-sector load range, flushes, and writes LBA 0 last. The installed target's
RedSea sectors remain unchanged. A guest-linked 453,016-byte image built from
the packaged six modules was published this way; its sectors matched the
expected image exactly, and the target independently booted under 16 MiB
QEMU/KVM and 486 TCG. HolyC executed `6*7`, and KVM rebuilt the lexer source.
An 8 MiB KVM boot also passed. This closes native link and boot-area
publication for the currently packaged boot modules. The guest must still
compile the five top-level assembly helpers, rebuild the kernel against this
latest file-service ABI, install a wholly guest-built image and repeat it for
a second generation. The broader M7 workstation/resource acceptance remains
open.

Build the five boot helper sources in source order, starting with
`SysTry.HC`. For each, require a guest-built T32M with the expected exports,
named relocations and independently audited 386 instructions. Rebuild the
kernel against the current file-service ABI, link all six guest-built modules
on the machine, install to a separate target, and cold-boot two successive
generations under QEMU. A first `SysTry.HC` assembler prototype passed the
x64 and i386 host builds but failed the actual QEMU source-module build; it
was removed. The next test must identify the exact frontend rejection.

That rejection was a dispatch error: the native command parser cleared AOT
mode before parsing, so module-level `asm` reached the inline join service.
Module sources now route it to a bounded top-level assembler. The original
`SysTry.HC` builds in the guest as a 220-byte T32M with one export and two
named calls. An instruction audit matches the host module's code, allowing
the guest's near branches in place of equivalent short branches. A guest
linked and installed mixed-source image using this `SysTry` cold-booted in
16 MiB QEMU/KVM and 486 TCG and evaluated `6*7`. This closes the first of
five helper source-build gates. Extend the assembler for the remaining four
helpers, then rebuild the current kernel and prove the wholly guest-built
two-generation boot and workstation gates.

`TaskContext.HC` now builds in the guest too. The top-level assembler publishes
its three exports as separate aligned function bodies and supports the
observed task, idle and segment-reload encodings. Its 187-byte guest T32M
matches every host instruction per function; export offsets differ only for
the module packer's alignment. The installed-volume regression rebuilt both
guest assembly helpers twice with identical bytes. A mixed image containing
guest-built `SysTry` and `TaskContext` linked and installed in the guest, then
cold-booted independently under 16 MiB QEMU/KVM and 486 TCG. Three helper
sources remain: `ExceptContext.HC`, `IrqEntry.HC` and `ExceptionEntry.HC`.
After those, rebuild the kernel against the current ABI and close the fully
guest-built two-generation and workstation gates.

`ExceptContext.HC` is the third guest-built boot helper. The assembler now
encodes the source's memory push, indirect memory call, register jump and XOR
forms. The guest emits four exports whose function bodies match the host
module byte for byte; the module is 380 rather than 364 bytes because the
native packer reorders and aligns the bodies. The installed-volume regression
rebuilt all three guest helpers twice with identical outputs. A guest-linked,
guest-installed mixed image containing them cold-booted independently in
16 MiB QEMU/KVM and 486 TCG and evaluated `6*7`. `IrqEntry.HC` and
`ExceptionEntry.HC` remain. Their exported stubs branch to shared assembly
code, so the next assembler step must preserve cross-export labels/branches
and publish correct entry offsets, before rebuilding the current kernel and
attempting a wholly guest-built boot image.

All five boot helper sources now compile in the guest. The top-level assembler
keeps an assembly block contiguous and records exports at their original
offsets, so IRQ and exception vector stubs can branch to one shared handler.
Its direct T32M publication preserves named dispatcher calls. Audits verify
all 16 IRQ and 17 exception entry exports, every vector push and branch
target, both shared handler bodies, and the named relocations. The earlier
TaskContext and ExceptContext modules now use the same contiguous layout;
their code matches the host assembly block exactly. A guest-linked image
with all five guest-built helpers and the currently packaged kernel was
installed to a separate target and cold-booted under 16 MiB QEMU/KVM and
486 TCG; HolyC evaluated `6*7`, and KVM rebuilt the lexer source. The
installed-volume regression rebuilt all five helpers twice with identical
bytes. Rebuild the current kernel source in the guest, then link/install a
wholly guest-built image, repeat for a second generation and close the M7
workstation/resource gates.

The current kernel source now builds in the guest against the live file-service
ABI. Its 506,917-byte T32M has 225 function exports and 792 named calls.
Together with all five guest-built boot helpers, it linked and installed a
456,992-byte flat image to a separate blank target. That target independently
cold-booted in 16 MiB QEMU/KVM, evaluated `6*7`, and rebuilt the lexer;
installation preserved its filesystem sectors. This establishes the first
fully guest-built installed generation. The same target also booted and ran
HolyC under 16 MiB 486 TCG and 8 MiB QEMU/KVM. Next, boot that generation to rebuild
and install a second generation, then complete the integrated M7 workstation
and resource acceptance.

That second generation now exists: the first wholly guest-built disk rebuilt
the kernel and five boot helpers, linked and installed a new image on a blank
target, and the target independently booted under 16 MiB QEMU/KVM. Its kernel
module and boot image are byte-identical to Generation 1; the booted system
evaluated `6*7` and rebuilt `LexNumber.HC`. The same boot and compiler check
also passed under 16 MiB 486 TCG; the focused 8 MiB help/text VGA checks pass.
The complete 8 MiB QEMU/KVM workstation suite also passes on Generation 2:
495 native commands and 558 submitted lines exercise compiler recovery,
graphics/input, DolDoc editing, RedSea navigation and source-linked help with
exact VGA checks. The writable three-boot DolDoc project acceptance also
passes on the installed Generation 2 disk under 8 MiB `486,-fpu`: it edits,
executes, saves, reopens and revises source across boots, then independently
audits file bytes, directory ownership and the RedSea bitmap. Rebuilt-artifact
installation interruption/recovery now passes two QEMU hard-stop points:
after LBA 128 and LBA 850 have been written, LBA 0 remains blank, the RedSea
bitmap remains exact, a retry reproduces the clean Generation 2 disk byte for
byte and that disk independently boots. This covers a recoverable unbootable
target before the final LBA-0 publication, not physical power-loss durability
after LBA 0. Bidirectional original/native cross-reading for the implemented
structured/binary DolDoc subset also passes on the installed Generation 2 disk:
native reads the original 48-byte fixture, and original x86-64 TempleOS saves
the native 37-byte binary fixture byte for byte. Broader DolDoc commands,
remaining manual workflow and release evidence still need explicit
verification before M7 closes.

The installed Generation 2 artifact now has a repeatable executable-region
audit: `tools/audit-i386-guest-image.py` extracts its guest-built T32Ms from
the source disk, verifies the installed flat payload, audits all linked and
retained module code against the 386 instruction allowlist, and audits the
BIOS/protected-mode stage ranges. It passes on the 456,992-byte Generation 2
image. Independent 16 MiB TCG boots pass on both `486` and `pentium`, each
evaluating HolyC and rebuilding the lexer. A manual source/edit/rebuild/install
session is specified in `docs/i386-test-workflow.md` for human observation.
The full 8 MiB `486,-fpu` TCG workstation suite also passes on Generation 2:
495 native commands, 558 submitted lines, exact VGA checks and 20 bounded
document-development cycles with heap recovery. The manual observation and
broader original DolDoc/editor behavior remain open.

The native console now publishes the original `ExeDoc(CDoc *,I64)` entry and
returns the last executed expression value. The existing `DocExe` Boolean
entry and F5 editor workflow retain their behavior, and nested compiler input
restores the outer break target. This is a compatible public execution adapter;
the original document-attached compiler control and complete `DocEd` action
path remain open. The six retained runtime/compiler T32Ms are still packaged
by the cross-build, so M7's full native-source gate is not closed by the two
guest-built boot generations. A 16 MiB guest probe compiled 151 functions of
`ConsoleRuntime.HC` before rejecting `MemSetU32` while parsing the shared
graphics unit; an isolated `GraphicsContext.HC` build reproduces the rejection.
The complete 8 MiB QEMU/KVM workstation suite passes with the new `ExeDoc`
case: 499 native commands, 562 submitted lines and exact VGA checkpoints.
Resolve that parser/source-unit boundary, then guest-build and load all six
retained modules before claiming the complete self-hosted system.

The `#help_file` source-unit boundary is now fixed: native module builds borrow
the same file-name service as interactive compilation. An 8 MiB QEMU/KVM guest
builds a module containing `#help_file`, and a 16 MiB guest builds the complete
`GraphicsContext.HC` source. `ConsoleRuntime.HC` now compiles through its final
function, but `program_pack_unit` returns zero when packaging that larger unit.
The full 8 MiB QEMU/KVM workstation suite passes with 504 native commands and
exact VGA checkpoints after this change.
Diagnose the packer rejection, then guest-build and load the retained modules;
source compilation alone is not the M7 self-hosting gate.

The packer rejection was a real duplicate export: a bare forward declaration
of `NativeDocClipPasteAtomicCheck` emitted a second function in the native AOT
path. Moving `DocAllocationCheck` after the real clip-check body removes the
forward declaration and leaves one export. Running the actual clip-check then
exposed an unhandled injected `OutMem`; the clipboard paste catch now consumes
that expected failure, and the 8 MiB `DocAllocationCheck` returns 12. A 16 MiB
QEMU/KVM guest builds and persists the full `ConsoleRuntime.HC` T32M; an
independent RedSea walk verifies unique exports and required console/editor
APIs. The full 8 MiB QEMU/KVM workstation suite passes with the real
`DocAllocationCheck` and 504 native commands. The retained image still boots
the host-built runtime. Next, guest-build the other retained T32Ms, replace
the packaged copies, and boot/test two wholly guest-built generations.

A 16 MiB QEMU/KVM guest now also builds `Startup.HC`, `MemoryRuntime.HC`,
and `FileRuntime.HC` as retained T32Ms. `MemoryRuntime.HC` needed its
`MemoryStrCopy` inline assembly expressed as a HolyC byte loop; the original
`StrCopyCheck` corpus passes in the guest, including null pointers, overlap,
long copies, and direction-flag behavior. That corpus is now in the regular
workstation input suite. `CompilerProbe.HC` reaches its included task-layout
assertions but rejects during source compilation; `CompilerRuntime.HC` has not
yet been attempted in this sequence. Four of six retained modules can now be
guest-built, but none has replaced the packaged host-built boot copy. Resolve
the compiler probe failure, build the remaining modules, install all six
guest-built copies, and repeat the independent Generation 2 boot and suite.
The full 8 MiB QEMU/KVM workstation run passes with this source: 506 native
commands and 569 submitted lines.

All six retained runtime/compiler modules now build and persist in a 16 MiB
QEMU/KVM guest. The compiler-probe task-layout assertions need semicolon
terminators: without them, directive lookahead nests through the table and
exhausts the compiler task stack. An independent RedSea audit checks module
records and exports. Replacing all six packaged modules with these guest-built
copies boots at 8 MiB; the same retained set also builds and installs the
current flat kernel and five boot helpers in the guest, then cold-boots from
the resulting disk. The retained build is repeatable byte for byte. These
boot and reproducibility results precede the latest compiler fix below.

The first full workstation run on that all-guest-built retained set caught a
regression: private source `#define` aliases lost to identically named
imported functions. The guest-built document loader called raw `CAlloc` and
`MAlloc`, bypassing its allocation-failure wrappers, so
`DocAllocationCheck` returned -9. Native identifier lookup now gives the
active source define precedence. A focused T32M audit checks the five wrapper
calls, and a freshly guest-built console returns 12 from
`DocAllocationCheck` on an independent 8 MiB QEMU boot. The cross-build and
x64 rebuild pass with this fix. The full 8 MiB QEMU/KVM workstation suite
also passes on the six-module disk after replacing its console with the
corrected guest-built copy: 506 commands, 569 submitted lines, and exact VGA
checkpoints. Rebuild and install all six retained modules
from the corrected source, rerun the full workstation/resource suite, then
rebuild a second fully guest-built generation before closing M7.

The corrected six-module retained build now passes its independent T32M and
export audit. All six copies were installed into a candidate disk and cold-booted
under 8 MiB QEMU/KVM; `6*7` returns 42 and `DocAllocationCheck` returns 12.
The same candidate guest-built and installed the current flat kernel and five
boot helpers onto a target disk. That target independently cold-booted at 8 MiB,
returned 42 from `6*7` and 12 from `DocAllocationCheck`, and retained all six
guest-built runtime/compiler modules unchanged. The full 8 MiB QEMU/KVM
workstation suite passes on the corrected six-module retained candidate:
506 native commands, 569 submitted lines and exact VGA checkpoints. The
installed target also passes the linked-module, retained-module and boot-stage
386 instruction audit, including
the guest compiler's division-template data. The fully guest-built installed
target also passes the full 8 MiB QEMU/KVM workstation suite: 506 native
commands, 569 submitted lines, exact VGA checkpoints and 20 bounded document
development cycles with exact heap recovery. The same
installed image also passes the three-boot writable DolDoc project check under
8 MiB `486,-fpu`: create/edit/execute/save, reboot/reopen, revise/reboot,
and an independent RedSea directory, file-byte and bitmap audit.

The current 8 MiB no-FPU resource profile reports a 7,143,424-byte native
heap arena starting at physical 1,114,112. After warm-up, 20 complete
document-development cycles start from 1,352,224 live bytes, reach a
1,355,840-byte live peak and a 1,356,800-byte reserved peak, then return to
the exact live baseline after each cycle. The full 8 MiB `486,-fpu` TCG
workstation suite also passes on the fully guest-built installed image:
506 native commands, 569 submitted lines and exact VGA checkpoints.

Generation 2 now independently guest-builds all six retained modules and the
flat kernel/boot helpers from the fully guest-built Generation 1 disk. It
installs and cold-boots at 8 MiB, evaluates `6*7` and passes
`DocAllocationCheck`. All twelve T32Ms, the 457,000-byte linked flat image and
the installed boot area are byte-identical across generations; both RedSea
volumes pass independent ownership/bitmap audits. The Generation 2 executable
image passes the 386 instruction audit. Its full 8 MiB QEMU/KVM workstation
suite also passes: 506 native commands, 569 submitted lines, exact VGA
checkpoints and 20 document-development cycles with exact heap recovery
(`build/i386-kernel/selfhost-install-gen2-fixed/full/result.json`). The same
Generation 2 disk passes the three-boot writable DolDoc project check at 8 MiB
under `486,-fpu` TCG: 107/56/15 commands, saved revision, and an independent
RedSea extent/bitmap audit
(`build/i386-kernel/selfhost-install-gen2-fixed/doldoc-tcg-nofpu/result.json`).
The complete 8 MiB `486,-fpu` TCG workstation suite also passes on the
Generation 2 disk: 506 native commands, 569 submitted lines, exact VGA
checkpoints and 20 document-development cycles with exact heap recovery.
Startup measured 73.68 seconds and long-document key-to-VGA update 0.265
seconds (`build/i386-kernel/selfhost-install-gen2-fixed/full-tcg-nofpu/result.json`).
A local 2.1 MiB release candidate under `build/i386-release-candidate/` now
contains the compressed Generation 2 disk, source-input hash manifest, QEMU
command records, acceptance results, support matrix and reproduction steps.
The packager verifies all 1,233 recorded source files, the disk hash, both
full-suite verdicts, the three-boot writable verdict and the final-image
installation recovery verdict before producing it.
The final Generation 2 disk also passes the rebuilt-artifact installation
hard-stop/retry gate at LBA 128 and LBA 850: LBA 0 stays blank, the RedSea
bitmap matches reachable extents, retry reproduces the reference disk byte for
byte, and the retried disk boots independently
(`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-committed/result.json`).
A third hard stop immediately after LBA 0 publication leaves the complete
reference disk byte-identical and independently bootable; all four source and
recovered target disk hashes match the release image. This is a QEMU process
hard-stop test, not physical power-loss durability.
The later 32-bit CPU profile now passes the complete 8 MiB workstation suite
on that same image: `pentium3,-fpu` TCG executes 506 native commands and 569
submitted lines with exact VGA checks and 20 document-development cycles
(`build/i386-kernel/selfhost-install-gen2-fixed/full-pentium3-nofpu/result.json`).
An 8 MiB `486,-fpu` focused profile on the exact Generation 2 disk confirms
the 7,143,424-byte heap arena and 20 document-development cycles with 3,616
bytes of temporary live growth and exact return to the 1,352,224-byte live
baseline (`build/i386-kernel/selfhost-install-gen2-fixed/resource-profile/resource-result.json`).
Publication and human manual observation remain open M7 gates.
The current requirement-by-requirement evidence map is
[docs/i386-m7-acceptance.md](docs/i386-m7-acceptance.md).
The local release packager now also binds the image to committed source
revision `78f66cfc`: all 1,233 recorded build-input hashes match the checkout,
and all 814 source files delivered on the Generation 2 RedSea volume match
those same hashes byte for byte. The earlier cross-build manifest revision
recorded a dirty worktree and is not used alone as the source identifier.
The initial 16 MiB `486,-fpu` TCG flat-kernel rebuild reached 191 of 225
function outputs before the host harness's 2,400-second command timeout; no
guest build error appeared. An independent run with a 7,200-second limit is
continuing, alongside the retained-module no-FPU rebuild. Neither is yet a
promotion pass.
The retained-build harness now has an explicit resume mode for a timed-out
multi-module TCG build. It preserves the already written `source.img`, rebuilds
only named unfinished modules after QEMU exits, then uses `--audit-only` across
all six modules to verify final persisted bytes against the installed image.
The running first attempt is still subject to its original per-command limit;
this recovery path does not count as a pass until the final audit succeeds.
The first integrated `486,-fpu` TCG retained build then reached its 3,600-
second host limit during `ConsoleRuntime`. A post-exit RedSea read found the
already persisted `Startup` (407 bytes), `MemoryRuntime` (178,962 bytes) and
`FileRuntime` (301,724 bytes), each byte-identical to the Generation 2 installed
module. `ConsoleRuntime`, `CompilerProbe` and `CompilerRuntime` were absent,
so this is a partial result. The explicit `--resume` run for those three is
now active with a 14,400-second per-command limit. An all-six `--audit-only`
check remains required before the no-FPU retained-build gate passes.
The separate 7,200-second `486,-fpu` TCG flat-kernel acceptance run now
completed all 225 kernel function outputs, packaged the 457,000-byte linked
image, built five boot helpers, installed a Generation 3 disk and cold-booted
that disk at 8 MiB. `audit-i386-generations.py` finds all twelve installed
modules, linked image and boot area byte-identical to Generation 2, with exact
RedSea ownership and bitmaps on both volumes. The Generation 3 executable
regions also pass the 386 instruction audit, including guest compiler template
data. The Generation 3 whole-disk SHA-256 is
`dac4e8d7c23ea1c715c2e0d198cc5ccfaf41b446024dc33943ba76d8d5612d7f`;
filesystem metadata explains the expected difference from Generation 2. Its
complete 8 MiB no-FPU workstation suite was then started, and the resumed retained
build still needs its all-six audit before closing the native-source gate.
The complete Generation 3 `486,-fpu` TCG workstation suite now passes on that
exact disk: 506 native commands, 569 submitted lines, exact VGA checkpoints
and 20 document-development cycles with exact task heap recovery
(`build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/full-tcg-nofpu/result.json`).
The exact Generation 3 disk also passes a three-boot writable DolDoc project
session under 8 MiB `486,-fpu` TCG: 107 commands to create/edit/save, 56 to
reopen and revise, and 15 after the next cold boot. The independent RedSea
walk confirms project bytes, rename/delete cycles, extent ownership and bitmap;
the source image hash is unchanged
(`build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/doldoc-tcg-nofpu-final/result.json`).
Earlier attempts exposed test-navigation assumptions, not a guest rejection:
timed left-arrow events moved the caret to the wrong line, and End moves to
the end of the document rather than the current line. The runner now saves a
hash-checked post-creation disk snapshot, reuses it only after an exact source
and CPU check, and verifies each caret frame while moving from Go to line 2
to the digit being revised. The final release packager requires the three
boots, their QEMU commands and the snapshot hash alongside the Generation 3
build, workstation and ISA evidence. The all-six no-FPU retained rebuild and
human manual observation remain open M7 gates.
The exact Generation 2 disk has now also passed all three installation
hard-stop cases under `486,-fpu` TCG. Stops during boot-sector writes at LBA
128 and 850 left LBA 0 blank and the RedSea bitmap exact; retries reproduced
the reference disk byte for byte and independently booted. A stop just after
LBA 0 publication left a complete byte-identical disk that independently
booted at 8 MiB. The source disk remained unchanged
(`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-tcg-nofpu/result.json`).
The exact Generation 2 release image now also passes a cross-architecture
DolDoc compatibility gate. Its 8 MiB i386 guest wrote a 37-byte document;
original TempleOS under x64 TCG read and saved the same bytes. The runner
records the source-image hash and proves the source unchanged, and the local
release packager verifies and bundles both command records and documents
(`build/i386-kernel/selfhost-install-gen2-fixed/doc-compat-provenance-retry/result.json`).
The local release packager also validates and bundles all 16 KVM/TCG recovery
QEMU command records, so the CPU, accelerator, RAM size and source/target disk
paths are independently reviewable alongside the verdicts.
The focused 16 MiB `486,-fpu` TCG `ConsoleRuntime` source rebuild now passes:
the guest produced an 896,448-byte module with 287 exports, and an independent
RedSea read found its bytes identical to the installed Generation 2 module
(`build/i386-kernel/retained-console-gen3-tcg-nofpu-long/result.json`). The
local packager checks that disk-level identity and bundles the result and QEMU
command. This proves one retained module under no-FPU TCG; the resumed
integrated six-module build and its post-exit audit are still required.
The public `ExeDoc` compatibility probe now builds a HolyC document through
canonical `CDocEntry` and `DocPutKey` calls, verifies that `DocSave` begins with
a DolDoc foreground record, then executes its `6*7;` source and returns 42
with exact QEMU VGA output. This case is part of the document-editing test
group. It tests one formatted document; native `LexAttachDoc`-style compiler
control and the full original editor action path remain open. Human manual
QEMU observation is deferred at the user's request while automated work
continues.
The expanded 169-command `document-editing` group passes on the exact
Generation 2 disk under 8 MiB QEMU/486 KVM with exact VGA checkpoints
(`build/i386-kernel/document-editing-formatted-exedoc-kvm/result.json`).
The release packager now requires that exact-disk verdict and QEMU command
and bundles both in its independently verified local candidate.
The same seven-command formatted `ExeDoc` probe also passes on the
no-FPU-built Generation 3 disk at 8 MiB under `486,-fpu` TCG, including the
DolDoc-record byte check, result 42 and exact VGA
(`build/i386-kernel/exedoc-format-record-gen3-tcg-nofpu/result.json`). This
extends this specific programming-model check to the target CPU profile;
document-attached compiler control remains open.
The packager also requires this Generation 3 no-FPU verdict and QEMU command;
the resulting local candidate passes its standalone verifier.
The focused 16 MiB `486,-fpu` TCG `CompilerProbe` source rebuild now also
passes. A post-exit RedSea read found its 1,209,705-byte, 182-export T32M
byte-identical to the installed Generation 2 module (SHA-256
`835b584c91b156417cfbec66c32f7dde272c28be34df49d23aeb8a10bdff5c91`).
The packager checks the guest-written and installed bytes and bundles the
result and exact QEMU command; its 66-file candidate verifies. The focused
`CompilerRuntime` and integrated six-module no-FPU runs remain live.
The next original-programming-model test has a reference verdict:
original x64 TempleOS executes a canonical `DOCT_INS_BIN_SIZE` entry attached
to a three-byte `CDocBin` and returns 3. The old i386 path returned 0 because
`NativeExeDoc` serialized through `DocSave`, whose record subset rejects that
entry. A direct, borrowed document source in the i386 compiler and lexer now
passes the standalone native test on a fresh cross-built image under both
8 MiB QEMU/486 KVM and `486,-fpu` TCG. The complete workstation suite passes
513 commands, exact VGA and 20 bounded document cycles on both KVM and
`486,-fpu` TCG. Next verify quoted formatting, source positions and unwind
behavior; repeat the writable-project gates, then rebuild/install a
self-hosted generation from
the updated sources. Focused direct-document include/resume and binary
insertion tests already pass under KVM and `486,-fpu` TCG. Human manual QEMU
observation remains deferred by request.
The first writable-session attempt exposed a diagnostic line regression:
ordinary text after a newline reset the compiler line to 1. A source fix
now reaches the formerly failing editor case and logs line 2 under
`486,-fpu` TCG. The next run exposed a document-lock break suppression;
`ExeDoc` now permits break delivery while preserving the document lock and
restores the break state before unlock. The fresh three-boot writable session
passes 107/56/15 commands under `486,-fpu` TCG with exact VGA and RedSea
audit. Exact-source guest rebuild and installation remain.
The complete workstation suite now passes on the break-fixed cross-built
image under both KVM and `486,-fpu` TCG: 513 commands, 576 submitted lines,
exact VGA and 20 document cycles with exact heap recovery. The exact-source
six-module retained rebuild has reached its final module; native installation
and repeat-generation evidence still need to follow. Human observation stays
deferred.
The exact direct-document source has now passed a 16 MiB KVM guest rebuild of
all six retained modules. Their replacement disk independently cold-boots at
8 MiB, and the native guest build/install of the flat kernel and boot helpers
followed from that disk. This is a new generation after the quoted-format
red test; the quoted gap remains open for subsequent compiler work.
The first complete guest-built direct-document generation now passes its
flat-kernel and six boot-helper build, native installation and independent
8 MiB KVM cold boot. Its flat image is 465,952 bytes. A second independent
guest-built generation is running from that installed target; generation
identity was the next check; target-image no-FPU workflow and quoted
formatting remained open at that point.
The second direct-document generation now passes from the first installed
target. An independent audit finds all twelve guest-built T32Ms, the
465,952-byte linked image and installed boot area byte-identical across both
generations; both RedSea volumes have exact bitmap ownership. Both installed
images pass the 386 executable-region audit, including guest compiler
templates. The first target's `486,-fpu` writable session now passes three
boots (107/56/15 commands), exact VGA, 0.29-second break recovery and
independent RedSea audit. Its complete no-FPU workstation suite also passes
513 commands, 576 submitted lines, exact VGA and 20 document cycles with
exact task-heap recovery on the guest-built image. Quoted formatting and
human observation remain open; the manual session is deferred by request.
The next original-programming-model test covered quoted DolDoc foreground
formatting. Original x64 `ExeDoc` turns a foreground entry between `A` and
`B` inside a quoted string into `A$FG,4$B` (length 8). The i386 lexer now
emits that record with the original two-dollar escape behavior. Canonical
foreground entries with color 4, color 15 and default color pass in separate
documents on the fresh cross-built image under both 8 MiB KVM and `486,-fpu`
TCG. The document group passes both profiles. Next complete the other quoted
record types, run the full workstation suite on this exact source, then
guest-build, install and repeat the generation and no-FPU gates. The older
Gen2 source's complete six-module no-FPU retained rebuild now passes a
post-exit byte-identity audit. Human QEMU observation remains deferred.
Original x64 fixtures also establish quoted background and style records:
`A$BG,1$B` has length 8, and `A$BK,1$$IV,1$$UL,1$B` has length 20.
The i386 lexer now preserves those records alongside foreground entries;
focused cross-built 8 MiB KVM and `486,-fpu` TCG probes, plus the 33-command
documents group, pass with exact VGA. A full workstation regression and an
exact-source guest-built installed generation are the next integration gates.
Quoted record types beyond these five still need original-behavior fixtures.
The manual QEMU session remains deferred by request.
The expanded quoted-format source has now passed the complete 8 MiB KVM
workstation suite: 513 native commands, 576 submitted lines, exact VGA at
every checkpoint, and 20 bounded document cycles with exact heap recovery.
The corresponding `486,-fpu` full suite and exact-source guest build remain
running; neither is counted as passed yet.
The complete `486,-fpu` TCG workstation suite has now also passed on this
source: 513 commands, 576 lines, exact VGA and 20 document cycles with exact
heap recovery. An earlier foreground-only source has passed a six-module
guest rebuild, export/structure audit, replacement installation and
independent 8 MiB KVM cold boot. The expanded-source guest rebuild and full
installed-generation gates remain open. Manual observation stays deferred.
The foreground-only guest-installed disk also passes the 21-command quoted
foreground repeat test under 8 MiB `486,-fpu` TCG with exact VGA. The
expanded-source guest rebuild is still compiling its retained compiler
modules; its installation and generation identity are not yet accepted.
The expanded quoted-format source has now completed a six-module guest
rebuild, passed export/structure audit, replaced all six retained modules
on a separate disk and cold-booted independently at 8 MiB KVM. On that
guest-installed disk, quoted background and style probes pass under
`486,-fpu` TCG with exact VGA. A full installed-disk no-FPU workstation
run and native flat-kernel build/install are active; second-generation
identity and human observation remain open.
The first fully guest-built expanded-source generation now passes native
flat-kernel and boot-helper construction, installation and independent
8 MiB KVM cold boot. Its linked image is 471,992 bytes. The installed
image passes the 386 executable-region, guest compiler template, boot-area
and filesystem audit. A second guest-built generation and complete no-FPU
workstation run are active; human observation remains deferred.
The second fully guest-built generation now passes from the first installed
target. All twelve guest-built modules, the 471,992-byte linked image and
installed boot area are byte-identical across generations; both RedSea
volumes pass exact ownership/bitmap audit. Both installed images pass the
386 executable and guest compiler-template audit. Quoted background and
style probes pass on the first fully guest-built target under `486,-fpu`
TCG. Complete no-FPU workstation and three-boot writable-session runs on
that target remain active; human manual observation remains deferred.
The fully guest-built target now also passes the three-boot writable DolDoc
session under 8 MiB `486,-fpu` TCG: 107/56/15 commands, exact VGA,
0.224-second break recovery, unchanged source disk and independently
verified RedSea extent/bitmap ownership. The complete no-FPU workstation
run on the target is still active. Human observation remains deferred.
The complete 8 MiB workstation suite now passes on the first fully guest-
built expanded-source target under both KVM/486 and TCG/`486,-fpu`: each
profile runs 513 native commands, 576 submitted lines, exact VGA at every
checkpoint and 20 bounded document cycles with exact heap recovery. The
same image passes the three-boot writable session, both quoted-format
probes, 386 audit, and two-generation byte identity. The earlier direct-
document generation's no-FPU guest rebuild of ConsoleRuntime and
CompilerRuntime has independently passed byte identity to its installed
modules. M7 human QEMU observation remains deferred by request; other
quoted document record semantics still need original-behavior fixtures.
The next original-behavior fixture covered quoted shifted-X/Y records.
Original x64 `ExeDoc` produces `A$SX,12$$SY,-34$B` (length 17); the old
i386 image returned a three-character result. The i386 direct-document
lexer now emits both records with signed decimal attributes and the
original two-dollar escape count. The nine-command native probe passes
under 8 MiB KVM and `486,-fpu` TCG. The 33-command documents group passes
both profiles, and foreground/style quotations retain their focused
passes. Full workstation regressions and an exact-source guest rebuild
are running. Human observation remains deferred.
The shifted-record source now passes the complete 8 MiB KVM workstation
suite: 513 native commands, 576 submitted lines, exact VGA at every
checkpoint and 20 bounded document cycles with exact heap recovery.
The complete `486,-fpu` TCG suite and exact-source six-module guest
rebuild remain active; neither is counted as passed yet.
The complete `486,-fpu` TCG workstation suite has now also passed on the
shifted-record source: 513 commands, 576 submitted lines, exact VGA and
20 bounded document cycles with exact heap recovery. Both full profiles
are green on the cross-built image; the exact-source guest rebuild and
installed-generation gates remain open. Human observation stays deferred.
The shifted-record source has now passed a complete six-module guest rebuild,
post-exit export/structure audit, replacement installation and independent
8 MiB KVM cold boot. Native flat-kernel build/install from that guest-built
disk is running. The manual QEMU usability session remains deferred.
The first fully guest-built shifted-record generation now passes native
flat-kernel and boot-helper construction, installation, independent 8 MiB
KVM cold boot, and the 386 executable/guest compiler-template audit. Its
linked image is 475,216 bytes. A second-generation identity check and
no-FPU workflow on this installed target remain; manual observation is
still deferred.
The next original-behavior fixture establishes quoted default foreground
and background records: x64 `ExeDoc` produces `A$FD,7$$BD,2$B` (length 14),
while the preceding i386 image fails that native probe. The i386 lexer now
emits both records. An isolated, byte-identical source build passes the
nine-command probe and 33-command documents group on KVM and `486,-fpu`
TCG, plus the complete 513-command workstation suite on both profiles
with exact VGA and 20 document cycles with exact heap recovery. The full
KVM latency checkpoint passes at 0.39 seconds without competing QEMU
builds. Exact-source guest-built installation remains; manual observation
is deferred.
The shifted-record source has now passed a second fully guest-built
generation from its first installed target. All twelve guest modules, the
475,216-byte linked image and installed boot area are byte-identical across
generations; both RedSea volumes pass extent/bitmap ownership audit
(`build/i386-kernel/generation-identity-shifted-kvm/result.json`). The second
installed image independently passes the 386 executable, guest compiler
template, boot payload and filesystem audit
(`build/i386-kernel/selfhost-install-shifted-gen2-kvm/instruction-audit/result.json`).
The newer default-color source is undergoing its exact-source guest rebuild.
The manual QEMU usability session remains deferred by request.
The first fully guest-built shifted-record target also passes the native
nine-command quoted shifted-X/Y probe under 8 MiB `486,-fpu` TCG with exact
VGA (`build/i386-kernel/selfhost-install-shifted-kvm/shifted-tcg-nofpu/result.json`).
That same fully guest-built target passes the three-boot writable DolDoc
session under 8 MiB `486,-fpu` TCG: 107/56/15 commands, exact VGA,
0.285-second break recovery, an unchanged source disk and verified RedSea
extent/bitmap ownership after create, reopen and revision
(`build/i386-kernel/selfhost-install-shifted-kvm/doldoc-tcg-nofpu/result.json`).
The next quoted-record TDD case is page layout. The original x64 fixture
`tests/guest/i386-exedoc-layout/Once.HC` yields
`A$PL,80$$LM,-2$B` (length 16) for page length and left margin entries.
The new native probe `tools/test-i386-exedoc-layout.py` reaches `ExeDoc`
on the preceding i386 image but times out expecting that length, establishing
a red state. The lexer now serializes both records inside quotes with signed
decimal attributes and the original two-dollar escape count. An isolated
byte-identical source passes the native nine-command probe under 8 MiB KVM
and `486,-fpu` TCG with exact VGA, plus default-color and shifted-record
regressions under KVM. Its original x64 rebuild and 386 cross-build/audit
pass. Full workstation and guest-built installed-generation checks for this
new source remain open. Manual observation stays deferred.
The preceding fully guest-built shifted-record target now also passes the
complete 8 MiB `486,-fpu` TCG workstation suite: 513 native commands, 576
submitted lines, exact VGA at every checkpoint, a 0.209-second long-document
visible-update latency and 20 bounded document-development cycles with
exact task-heap recovery
(`build/i386-kernel/selfhost-install-shifted-kvm/full-tcg-nofpu/result.json`).
This result belongs to the shifted-record generation; the newer layout
source still needs full installed-generation verification.
The original x64 fixture for all eight simple numeric layout directives
now yields `A$PL,80$$LM,-2$$RM,3$$HD,4$$FO,5$$ID,6$$WW,1$$HL,1$B`
(length 52). The prior page-length/left-margin i386 image fails the matching
14-command native probe at `ExeDoc`. The lexer now serializes right margin,
header, footer, indent, word wrap and highlight as well. An isolated
byte-identical source passes that probe under 8 MiB KVM and `486,-fpu` TCG
with exact VGA, the original x64 rebuild and 386 cross-build/audit; quoted
default-color and shifted-record regressions pass under KVM. The main-source
full workstation and guest-built generation gates remain open.
The preceding default-color source has completed its exact-source six-module
KVM guest rebuild and post-exit module audit
(`build/i386-kernel/retained-build-default-colors-kvm/result.json`).
Replacement installation and cold boot are in progress. Manual observation
stays deferred.
The default-color source's six guest-built retained modules are now installed
on a separate disk and pass independent 8 MiB KVM cold boot
(`build/i386-kernel/retained-install-default-colors-kvm/result.json`). Its
first fully guest-built flat kernel and boot helper also install and cold
boot independently: 476,360 linked bytes, SHA-256
`7cb3e5e02c680842f153d841c21a8f521565635ee08f482138277671c3ea470e`
(`build/i386-kernel/selfhost-install-default-colors-kvm/result.json`). The
installed image passes the 386 executable, guest compiler-template,
boot-payload and RedSea ownership audit
(`build/i386-kernel/selfhost-install-default-colors-kvm/instruction-audit/result.json`).
A second guest-built generation is running; human observation stays deferred.
The latest eight-layout-record source now passes the original x64 rebuild,
main 386 cross-build/audit, the 14-command quoted-layout probe, and the
33-command documents group under both 8 MiB KVM and `486,-fpu` TCG with
exact VGA. Its complete workstation and guest-built installed-generation
checks remain open.
The first fully guest-built default-color target itself passes the
nine-command quoted default-color probe under 8 MiB `486,-fpu` TCG with
exact VGA
(`build/i386-kernel/selfhost-install-default-colors-kvm/default-colors-tcg-nofpu/result.json`).
Its complete no-FPU workstation suite is running. The latest
eight-layout-record source has started its
exact-source six-module KVM guest rebuild. Human manual observation remains
deferred.
The next original-behavior fixture covers quoted page-break and clear
records. Original x64 `ExeDoc` yields `A$PB$$CL$B` (length 10)
(`tests/guest/i386-exedoc-controls/Once.HC`). The preceding i386 image
reaches `ExeDoc` but times out on the matching nine-command native probe
(`build/i386-kernel/exedoc-controls-red-kvm/`). The lexer now serializes
both records in quotes without an attribute field. The isolated,
byte-identical source passes the nine-command native probe and 33-command
documents group under 8 MiB KVM and `486,-fpu` TCG with exact VGA;
the 14-command numeric layout regression passes both profiles. Original
x64 rebuild and 386 cross-build/audit pass. Its complete workstation and
guest-built installed-generation checks remain open.
The preceding default-color source now has two fully guest-built generations.
All twelve modules, the 476,360-byte linked image and installed boot area
are byte-identical; both RedSea volumes pass exact extent/bitmap ownership
audit (`build/i386-kernel/generation-identity-default-colors-kvm/result.json`).
The second installed image independently passes the 386 executable, guest
compiler-template, boot payload and filesystem audit
(`build/i386-kernel/selfhost-install-default-colors-gen2-kvm/instruction-audit/result.json`).
Its first fully guest-built target passes the complete 8 MiB `486,-fpu`
TCG workstation suite: 513 commands, 576 submitted lines, exact VGA at
every checkpoint, 0.268-second long-document visible-update latency and
20 bounded document-development cycles with exact task-heap recovery
(`build/i386-kernel/selfhost-install-default-colors-kvm/full-tcg-nofpu/result.json`).
The focused default-color and shifted-record probes also pass under no-FPU
TCG on that target. A three-boot writable session is running; the manual
QEMU session stays deferred.
That three-boot writable DolDoc session now passes under 8 MiB `486,-fpu`
TCG: 107/56/15 commands, exact VGA, 0.346-second break recovery, an
unchanged source disk and verified RedSea extent/bitmap ownership after
create, reopen and revision
(`build/i386-kernel/selfhost-install-default-colors-kvm/doldoc-tcg-nofpu/result.json`).
The manual QEMU session remains deferred.
The installed default-color disk embeds `/Compiler/I386/LexInput.HC`
byte-identical to commit `18463db3` (SHA-256
`31170d5c3194de658bf1f340df2d6dde86032d8c3947d5d6ce44d0ad363f0aef`).
The separate cross-built disk feeding the in-flight layout guest rebuild
embeds the same path byte-identical to commit `36da99b0` (SHA-256
`bb27038d48169a9a9e477f7d35afce47a98645e338474b190cccf8bb62646e4b`).
These checks bind the older generation evidence to its source snapshots;
the newer control-record source has not yet completed guest installation.
The eight-layout-record source has completed its exact-source six-module
KVM guest rebuild and post-exit module audit, replacement installation and
independent 8 MiB KVM cold boot
(`build/i386-kernel/retained-build-layout-all-kvm/result.json`,
`build/i386-kernel/retained-install-layout-all-kvm/result.json`). Its native
flat-kernel build/install is active.
The newer control-record source passes a fresh main x64 rebuild and 386
cross-build/audit, and the nine-command control probe on the main image
under KVM and `486,-fpu` TCG with exact VGA. Its isolated byte-identical
image passes the full 8 MiB no-FPU workstation suite: 513 commands, 576
submitted lines, exact VGA, 0.382-second long-document visible-update
latency and 20 document cycles with exact task-heap recovery
(`../TempleOS-controls/build/i386-kernel/controls-full-tcg-nofpu/result.json`).
Its 509-command KVM functional run excluding the timing-sensitive
document-latency group also passes with exact VGA
(`../TempleOS-controls/build/i386-kernel/controls-functional-kvm/result.json`).
The complete KVM suite and latest installed-generation gates remain open;
manual QEMU observation stays deferred.
The control-record source's main cross-built image passes the standalone
8 MiB KVM document-latency group under concurrent QEMU load: four native
commands, exact VGA and a 0.620-second long-document visible update
(`build/i386-kernel/controls-latency-main-kvm/result.json`). Its isolated
cross-built disk embeds `/Compiler/I386/LexInput.HC` byte-identical to
commit `eb3305a4` (SHA-256
`1788eddbb02fea3250bd2c19072e8ccc0f546d5b2e7eca75f907d97159d745dd`).
The complete main-image KVM and no-FPU workstation runs and exact-source
guest rebuild remain active. The eight-layout-record source's first native
flat-kernel install is still active at guest boot-image linking; no pass is
claimed for that installation. Manual observation remains deferred.

The complete exact-source control-record workstation suite now passes on
both 8 MiB KVM `486` and no-FPU TCG `486,-fpu`: 513 native commands, 576
submitted lines, exact VGA checkpoints and 20 bounded document cycles
(`build/i386-kernel/controls-full-main-kvm/result.json`,
`build/i386-kernel/controls-full-main-tcg-nofpu/result.json`). The earlier
layout-generation native flat-kernel install was stopped at guest image
linking: its six modules require 480,952 bytes, above the old 479,232-byte
boot payload limit. A 960-sector BIOS reservation now ends at `0x88000`,
the base of the existing 32 KiB boot stack. It allows 487,424 payload
bytes, leaving 6,472 bytes for that measured generation, while keeping
the 576 KiB conventional-memory requirement. Loader, guest builder,
installer and host verification use the same limit. The guest builder
rejects an oversized module set before symbol resolution. The final
source passes two x64 rebuilds, 386 cross-build/instruction audit and
normal 8 MiB QEMU keyboard/VGA boot
(`build/i386-kernel/boot-capacity-preflight-keyboard/result.json`).
The diagnostic startup currently stops after `RUNTIME PROBE` on both the
unchanged 944-sector baseline and this revision; that diagnostic gate and
the new guest-built flat installation remain open. A later architectural
step must move more code out of the flat boot image or load it above low
memory, since 6,472 bytes is limited headroom. Human observation in
`docs/i386-test-workflow.md` remains deferred.

Follow-up diagnostic work found that `I386LexIdentScan` counted a source
define twice when the normal symbol-chain lookup had already found it.
That violated the native compiler probe's macro-use invariant. The scanner
now skips the redundant lookup for an already-found define; the diagnostic
guest reaches both probe phases and completes native startup. The host
boot verifier now also checks the existing `frontend_bind_files` service
pointer in the retained compiler runtime instead of expecting the older
interface width. The complete `tools/build-i386-kernel.py --test` run is
in progress. The guest-built flat installation and human QEMU observation
remain open; the manual session stays deferred.

The measured layout-generation six-module flat image now passes the new
960-sector installation path on a writable copy of its partial guest-built
target. The guest linked 480,952 bytes
(`build/i386-kernel/boot-capacity-layout-link-kvm/result.json`), published
that image into the reserved boot area with exact byte comparison against
the expected stage and image
(`build/i386-kernel/boot-capacity-layout-install-kvm/result.json`), and
the installed target passed independent 8 MiB cold boots on KVM `486`
and TCG `486,-fpu` with two native commands and exact VGA
(`build/i386-kernel/boot-capacity-layout-cold-boot-kvm/result.json`,
`build/i386-kernel/boot-capacity-layout-cold-boot-tcg-nofpu/result.json`).
The target volume has 16 directories, 836 files and 17,823 owned sectors;
its bitmap matches reachable extents. This combines the earlier layout
guest-built modules with the current boot stage and publisher; it does not
replace the latest control-record source's exact-generation install gate.
The full current-source `--test` and six-module KVM guest rebuild continue.
Human manual observation remains deferred.

For the current source, the 8 MiB `486,-fpu` compiler group passes 144
native commands with exact VGA
(`build/i386-kernel/lexident-compiler-tcg-nofpu/result.json`). The active
six-module KVM guest rebuild disk embeds `Compiler/I386/LexIdent.HC`,
`Kernel/I386/BuildBootImage.HC` and `Kernel/I386/InstallBootArea.HC`
byte-identical to the committed tree. The rebuild has reached the sixth
retained module; the complete 386 `--test` is still running through
follow-up boot and filesystem checks. Exact-source installation remains
open, and the manual QEMU session remains deferred.

The current source's six retained modules now complete the KVM guest
rebuild with post-exit export and module audits
(`build/i386-kernel/retained-build-capacity-lexfix-kvm/result.json`). Their
replacement into a disk copy is byte-identical, and that disk passes an
independent 8 MiB KVM cold boot with native commands
(`build/i386-kernel/retained-install-capacity-lexfix-kvm/result.json`).
The candidate retains `Compiler/I386/LexIdent.HC`,
`Compiler/I386/LexInput.HC`, `Kernel/I386/BuildBootImage.HC` and
`Kernel/I386/InstallBootArea.HC` byte-identical to the committed source.
Its six guest-built flat modules and boot-image installation are running;
the complete 386 `--test` remains active. Manual observation is deferred.

The current source now passes its first fully guest-built 32-bit
installation. Six flat modules compiled inside QEMU link to 482,384
bytes, fit the 487,424-byte payload limit, and are installed beside the
six guest-built retained modules. The target passes independent 8 MiB KVM
cold boot, exact boot-area comparison and RedSea extent/bitmap audit
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/result.json`). Its
386 executable regions and guest compiler template pass instruction audit
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/instruction-audit/result.json`).
The target embeds current lexer, builder and installer sources byte for
byte. A complete no-FPU workstation run on this installed image and a
second guest-built generation are active. The long 386 `--test` remains
active, and manual QEMU observation stays deferred.

The complete current-source `tools/build-i386-kernel.py --test` now passes.
Its 8 MiB interactive QEMU workstation phase executes 513 native commands
over 576 submitted lines with exact VGA, 20 bounded document cycles and
exact shared task-heap recovery (`build/i386-kernel/result.json`). The
diagnostic boot, native and linked boot-area publication, interrupted
install-copy recovery, filesystem mutation checks and original TempleOS
document cross-compatibility checks also pass. The fully guest-built
installed target's no-FPU workstation and second-generation identity runs
continue; manual QEMU observation remains deferred.

The first exact-source guest-built target now passes a three-boot writable
DolDoc session under 8 MiB `486,-fpu` TCG: 107 commands to create/edit/save,
56 after reopening, and 15 after revision, all with exact VGA
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doldoc-tcg-nofpu/result.json`).
The source disk is unchanged; the final RedSea volume has 18 directories,
853 files and 17,855 owned sectors, with its bitmap matching reachable
extents. The complete no-FPU workstation and second-generation guest
rebuild remain active. The manual QEMU session is still deferred.

The first exact-source fully guest-built target now passes the complete
8 MiB `486,-fpu` TCG workstation suite: 513 native commands, 576 submitted
lines, exact VGA at every checkpoint, 20 bounded document-development
cycles with exact shared task-heap recovery, and a 0.387-second
long-document visible update
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-tcg-nofpu/result.json`).
Its installed-disk KVM suite and second-generation guest rebuild are
active. Manual QEMU observation remains deferred.

The current fully guest-built target also passes the complete 8 MiB
`486` KVM workstation suite: 513 commands, 576 lines, exact VGA at every
checkpoint, and 20 document cycles with exact shared task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-kvm-retry/result.json`).
The second-generation guest rebuild remains in progress; manual QEMU
observation remains deferred.

The current first installed disk has now rebuilt all six retained modules
as a second guest generation. The persisted modules pass export and
structure audits and match the installed first-generation modules byte for
byte (`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-retained-build-kvm/result.json`).
Their replacement on a disk copy and independent 8 MiB KVM cold boot also
pass (`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-retained-install-kvm-retry/result.json`).
The second-generation flat-kernel build and full twelve-module identity
check remain open; the manual session remains deferred.

The current source now passes two fully guest-built QEMU/486 generations.
All twelve installed modules, the 482,384-byte flat image and the boot area
match byte for byte; both RedSea volumes pass ownership/bitmap audit
(`build/i386-kernel/generation-identity-capacity-lexfix-kvm/result.json`).
The second target independently cold-boots at 8 MiB and passes the 386
executable and guest compiler-template audit. A local current-source
release candidate is produced by `tools/package-i386-current.py`; its
standalone verifier passes for the compressed disk and 72 bundled files
(`build/i386-release-current/manifest.json`). Human usability observation
and publication remain open; the manual session is deferred.

The exact current installed disk now passes native/original document
compatibility: original x64 TempleOS reads and saves its 37-byte native
DolDoc file byte for byte
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/doc-compat-current/result.json`).
Its guest boot-image installer also survives hard stops at LBAs 128 and 850,
retries to the exact reference disk, and independently boots; stopping just
after LBA 0 publication leaves the complete reference disk bootable
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/install-recovery-current-kvm/result.json`).
The current local bundle now includes both results and verifies 72 files.
Human manual QEMU observation remains deferred.

The exact current guest-built disk also passes the full 8 MiB
`pentium3,-fpu` TCG workstation suite: 513 commands, 576 lines, exact VGA
and 20 document cycles with exact shared task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/full-pentium3-nofpu-stdio-cli-retry/result.json`).
The runner's writable-copy provenance binds that restricted-host QEMU run
to the unchanged candidate hash. The QMP-over-stdio path passes focused
compiler and keyboard checks; a timer-interval PIT sample removes a
one-read host-scheduling race without relaxing the expected speaker period.
The local bundle includes this later-CPU result and verifies 72 files.
Manual human observation remains deferred.

The independently rebuilt second-generation disk now also passes the
complete 8 MiB `486,-fpu` TCG workstation suite: 513 commands, 576 lines,
exact VGA and 20 document cycles with exact shared task-heap recovery
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-tcg-nofpu-stdio-cli/result.json`).
The writable-copy provenance binds the run to the unchanged second disk.
The local bundle includes this direct second-generation result and verifies
72 files. Human manual observation remains deferred.

The second-generation disk also passes a full three-boot writable DolDoc
project under 8 MiB `486,-fpu` TCG: 107/56/15 commands with exact VGA,
persisted create/reopen/revision, unchanged source disk and independent
RedSea extent/bitmap audit
(`build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doldoc-tcg-nofpu-stdio/result.json`).
The current local bundle includes both generations' persistent sessions and
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
The current-source six-module retained rebuild now passes under 16 MiB
`486,-fpu` TCG from the installed Generation 2 disk. All persisted T32Ms
match the installed modules byte for byte, with source-disk, comparison-disk
and per-module hashes recorded in
`build/i386-kernel/retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json`.
The long run was resumed after host interruption and audited after the final
guest command completed. The local package requires this evidence and verifies
76 files. Human manual observation remains deferred; full original feature
parity remains open.

Both guest-built generations' persisted styled DolDoc files now also pass an
original x64 TempleOS read/save round trip. The 78-byte file contains
foreground, background, invert and underline records; the original reader
reproduces it byte for byte. The local package requires both results and
verifies 84 files. Human manual QEMU observation remains deferred.

The original x64 guest now also edits that styled document, producing a
distinct 79-byte file. Each guest-built i386 generation reads and saves the
original-authored bytes unchanged under `486,-fpu` TCG on a copy of its
persistent session disk. The package requires both reverse-path QEMU verdicts
and verifies 88 files. Manual observation remains deferred.

Retained public-task runtime foundation (2026-10-03):
MemoryRuntime now shares task preparation, activation, finish and reap source
under local names, using the installed scheduler switch and binding callbacks.
Heap initialization is shared through HeapInit.HC, without a new resident
kernel export. Public Spawn, Exit and TaskQueIns remain unimplemented; these
private helpers do not satisfy the public lifecycle gate.

Explicit nested preprocessor guards select a numeric implementation flag:
the original compiler expands macros inside defined(...) expressions, which
incorrectly selected the larger C implementation in the boot kernel. The
corrected source passes two original compiler/kernel generations
(build/i386-retained-task-core-guard-bootstrap.log). The isolated cross build
passes and retains the previous 483,408-byte flat kernel size
(build/i386-retained-task-core-guard-kernel/result.json).

The separate retained lifecycle fixture passes 20 dormant-create, idle-yield,
activate, private-allocation, normal-return and destroy cycles against the
core scheduler, with exact bootstrap heap recovery, public/private ring
restoration and FS/GS binding checks
(build/i386-task-runtime-core-test/result.json). The original task corpus
also passes (build/i386-tasks-test/result.json). Both retain their existing
320 KiB transfer bound and first heap arena at physical 0x60000.
The installed native HolyC compiler rebuilds MemoryRuntime successfully
(build/i386-retained-task-core-native-memory/result.json); this is module
build evidence, not an installed guest-built provider or full self-hosting
gate. This foundation's flat native build/install and 386 executable audit now
pass (build/i386-retained-task-core-native-flat/result.json and its
instruction-audit/result.json): 487,392 linked bytes, with only 32 boot bytes
remaining, built with 16 MiB and independently booted with 8 MiB on KVM
486,-fpu. Its retained inputs are cross-built, so it is development evidence.
The original public lifecycle checker still correctly fails for missing
Spawn, Exit and TaskQueIns
(build/i386-retained-task-core-public-tasks/result.json).

Dormant disposal now has a separate retained helper. It rejects attached,
current, referenced or otherwise active contexts, then retires a valid dormant
record before using the same owned-task teardown. A teardown failure leaves
that record retired for retry rather than runnable or freed. The focused
fixture first failed with the helper absent
(build/i386-retained-task-discard-before.log), then passed 20 dormant disposal
cycles, a creator-code retention case and injected file-cleanup failure/retry,
in addition to its 20 ordinary lifecycle cycles
(build/i386-task-runtime-core-test/result.json). Creator destruction remains
blocked until the dormant child is successfully reclaimed. The current source
passes another two-generation bootstrap
(build/i386-retained-task-discard-bootstrap.log) and isolated cross build
(build/i386-retained-task-discard-kernel/result.json); the flat cross kernel
remains 483,408 bytes. The installed native HolyC compiler also rebuilds
MemoryRuntime with the disposal helper successfully
(build/i386-retained-task-discard-native-memory/result.json). That persisted
module has not yet replaced the cross-built provider in an installed image.

The older character-immediate source epoch's complete --test integration
also finished successfully, including keyboard/VGA checks, disk-copy recovery
and original TempleOS DolDoc round-trip
(build/i386-asm-char-integration/result.json and child reports). That source
predates the owned constructor and retained helper changes; it does not
qualify them. Complete public policy, managed reaping and child rings remain
the next work.

Public task runtime development (2026-10-03, positive contract milestone):
A retained TaskRuntimePublic.HC now implements Spawn, Exit, TaskQueIns and
owned-record reaping. MemoryServices version 12 publishes the public calls
and a managed I386SchedYield binding for modules loaded afterward; its own
core-yield import is captured before publication. The retained import contract
remains unchanged. Spawn preserves the default parent, stack size, task naming,
selected-parent heap/file/symbol inheritance and original child-list insertion.
TaskQueIns activates a dormant context and inserts before the predecessor.
A record retains the owned allocation until normal return or explicit Exit has
retired it and its lifetime references permit teardown.

The first cross build and native MemoryRuntime rebuild/install pass
(build/i386-public-task-runtime-reap-kernel/result.json,
build/i386-public-task-runtime-native-memory/result.json and
build/i386-public-task-runtime-native-install/result.json). The flat cross
kernel remains 483,408 bytes. Public lookup finds all required task services,
but this is not a behavior pass. Positive testing exposed two previously
unexecuted checker problems: QMP typing lacked Shift+slash for question marks,
and the fixture used C's unsupported ternary syntax. Direct if/else worker
selection now keeps the same normal-return/Exit assertions. The new original
compiler oracle verifies all 29 contract definitions without executing workers
(build/i386-public-task-definitions-global/result.json).

The behavior gate then exposed that Fs is the interactive console worker,
not the background kernel root. Initializing only memory_root leaves that
worker's public child list uninitialized. The corrected development source
prepares private workers when they enter the public runtime and permits
reaping from any other live stack, retaining current-task and creator/parent
reference guards. Finishing tasks can still yield during cleanup. It also
rejects insertion before the task itself. This source passes a fresh
original two-generation bootstrap
(build/i386-public-task-runtime-live-stack-bootstrap.log), cross build and
private lifecycle regression. Its native MemoryRuntime also builds successfully
(build/i386-public-task-runtime-live-stack-native-memory/result.json).
The public behavior gate then reaches successful Spawn but fails LifeFinish.
An isolated 8 MiB no-FPU KVM probe establishes that the worker reaches stage 2,
is reclaimed, and fails only directory inheritance
(build/i386-public-task-invariants-bits-probe/result.json): the public cur_dir
field was never linked to the task-owned directory bytes.

A focused task-symbol regression now checks public directory initialization,
distinct inherited directory storage and replacement after a directory change.
Before the fix it fails with code 251 (0xFB), the missing root directory field
(build/i386-task-public-directory-symbols-red.log). TaskFiles now publishes the
owned directory pointer on init/clone/set and clears it on successful teardown.
The fresh original two-generation bootstrap, task-symbol regression and cross
build now pass (build/i386-public-task-directory-bootstrap.log,
build/i386-task-symbols-test/result.json and
build/i386-public-task-directory-kernel/result.json). All 43 public lifecycle
commands pass at 8 MiB under 486,-fpu TCG, with exact VGA and unchanged source
disk (build/i386-public-task-directory-contract/result.json). This includes
normal return, explicit Exit, 20 repeated cycles with exact public pool recovery,
default parent/name/stack, nested creators, dormant tasks and repeated activation.
The public-directory regression changed from failure 251 to a passing result.

The current MemoryRuntime builds in the guest and installs successfully
(build/i386-public-task-directory-native-memory/result.json and
build/i386-public-task-directory-native-install/result.json). The installed
candidate passes the 386 executable/boot allowlist and filesystem extent audit
(build/i386-public-task-directory-native-audit/result.json); its flat kernel is
still cross-built, at 483,408 bytes. The same 43-command public behavior contract
passes against the installed provider at 8 MiB under 486,-fpu TCG, with exact
VGA and an unchanged candidate (build/i386-public-task-directory-native-contract/result.json).
Its behavior boot takes 49.282671 seconds; the cross-image behavior boot takes
48.985763 seconds. This does not provide the still-missing public
drive-descriptor service or prove a complete native generation.

Full descendant termination, public cancellation/Kill, automatic disposal of
never-activated managed descendants, source debugging, multiple terminals,
complete current-source native generations and release evidence remain open.

Public failure paths and descendant retirement (2026-10-03):
The public lifecycle contract now contains 55 commands. Six rejection cases
cover unavailable CPU targets, null entry, undersized/misaligned stack and an
8 MiB stack allocation that cannot fit the interactive profile. Each requires
the expected exception, preserved caller IF, unchanged public child membership
and exact public pool usage/reservation, followed by successful creation and
completion. All 33 definitions compile with original HolyC, and all 55 commands
pass on the preceding cross-built and installed guest-built directory milestone
(build/i386-public-task-failure-definitions/result.json,
build/i386-public-task-failures-cross/result.json and
build/i386-public-task-failures-native/result.json). These checks do not measure
bootstrap stack/control/node allocation rollback independently.

The new tools/test-i386-public-task-descendants.py establishes original queued
descendant semantics with five executable x64 reference cases: parent return
before child entry, return with a running child, explicit Exit with a running
child, return with a sleeping child, and Exit with a sleeping grandchild
(build/i386-public-task-descendants-full-reference/result.json).
The first basic case fails on the preceding i386 image: DescDone returns zero
after its bounded wait, while the returned parent remains linked because its
child keeps yielding (build/i386-public-task-descendants-red/behavior/debug.log
and startup-command-09.ppm). A retained reference prevents premature freeing,
but does not preserve the original requirement to terminate queued descendants.

The development policy now enters public tasks through a retained wrapper.
Parent Exit marks queued children for termination, clears their public sleep
and suspension conditions, and yields until they are reclaimed. The wrapper
prevents a canceled task's first user instruction; checks on both sides of
managed yield prevent already-running tasks from resuming user code after a
termination request. Normal entry return follows the same Exit path. An exiting
record rejects new children, and reference/cleanup guards remain in place.
The fresh original two-generation bootstrap and cross build pass
(build/i386-public-task-descendants-bootstrap.log and
build/i386-public-task-descendants-kernel/result.json). All five descendant cases
and the 55-command lifecycle regression now pass at 8 MiB under 486,-fpu TCG
on both the cross-built and installed guest-built provider
(build/i386-public-task-descendants-cross/result.json,
build/i386-public-task-descendants-lifecycle/result.json,
build/i386-public-task-descendants-native/result.json and
build/i386-public-task-descendants-native-lifecycle/result.json). Native
MemoryRuntime builds and installs; its 261,991-byte module passes the installed
386 executable/boot and filesystem audit. The flat kernel remains cross-built
and 483,408 bytes (build/i386-public-task-descendants-native-memory/result.json,
build/i386-public-task-descendants-native-install/result.json and
build/i386-public-task-descendants-native-audit/result.json).

The independent bootstrap accounting checker passes on both candidates
(build/i386-public-task-bootstrap-accounting-extern-cross/result.json and
build/i386-public-task-bootstrap-accounting-extern-native/result.json).
It uses layout declarations extracted from the tested disk's source headers,
checks the backing and heap signatures, and invokes the installed heap validator.
It compares bootstrap used bytes and allocation counts after each of 20
normal-return/Exit cycles, 20 deferred activation cycles, and six creation
rejections. The initial header-import attempt could not compile as a public app;
only layout declarations and a plain extern heap-validator binding are used now.
Both 57-command runs preserve exact VGA and the input/checker hashes under
8 MiB 486,-fpu TCG. Bootstrap accounting for descendant trees, late clone-hook
failure and dormant disposal remains separate from these passing cycles.
Public Kill/break, private I/O-wait cancellation, descendant
callbacks, dormant disposal, the remaining bootstrap accounting cases and complete
current-source generation/release qualification still require work.

Task exception prerequisite and current native-flat evidence (2026-10-04):
The six current flat modules rebuild, link, install and independently boot
without an FPU, using 16 MiB for building and 8 MiB for operation
(build/i386-public-task-descendants-native-flat/result.json). The flat image is
487,392 bytes, leaving 32 bytes in the existing boot region, and passes its
386 executable/boot/filesystem audit. All six retained modules are cross-built
development inputs; this is not a fully guest-built generation.

The expanded bootstrap checker now also passes 20 descendant-tree cycles,
covering all five original-behavior variants four times, on both the cross-built
and installed guest-built memory provider
(build/i386-public-task-tree-accounting-cross/result.json and
build/i386-public-task-tree-accounting-native/result.json). Every cycle restores
raw used bytes/allocation counts and passes heap validation. The checker binds
the descendant definition source by hash as well as the public task contract.
Late clone-hook failure and dormant disposal accounting still remain open.

Before exposing Kill/break, tools/test-i386-public-task-exceptions.py establishes
four original x64 behaviors: a catch after yielding, nested catches/rethrow,
Exit from inside try, and queued descendant termination with an active try
(build/i386-public-task-exceptions-original/result.json). The current i386
baseline fails on the first worker's SysTry entry with UNHANDLED status 1 and
FAIL native kernel (build/i386-public-task-exceptions-red/behavior/debug.log).
The private exception runtime requires task.memory, but public Spawn left it
unset when constructing without a dedicated private arena.

The development fix binds exception scratch allocation to the service's existing
bootstrap heap. Records remain owned by each task's except_top chain; public
code/data allocations retain their separate task heap ownership. Exit drains
that chain through the existing SysUntry service before retirement, including
when it bypasses lexical untry epilogues. No boot-kernel code or import contract
is added. The fresh original bootstrap, private exception-task regression and
cross build now pass (build/i386-public-task-exceptions-bootstrap.log,
build/i386-public-task-exceptions-private-regression.log and
build/i386-public-task-exceptions-kernel/result.json). All four worker cases
pass at 8 MiB under 486,-fpu TCG on cross-built and installed guest-built
providers (build/i386-public-task-exceptions-cross/result.json and
build/i386-public-task-exceptions-native/result.json). The guest-built
262,244-byte memory module installs and passes the 386 executable/boot and
filesystem audit (build/i386-public-task-exceptions-native-memory/result.json,
build/i386-public-task-exceptions-native-install/result.json and
build/i386-public-task-exceptions-native-audit/result.json). The current cross
image also passes all 55 public lifecycle commands.

Both providers pass the expanded 88-command bootstrap accounting gate: 20
ordinary return/Exit, 20 deferred activation, 20 descendant-tree and 20 worker
exception cycles, plus six creation rejections. Every cycle restores raw used
bytes/allocation counts and passes heap validation; source disks and checker
hashes remain unchanged (build/i386-public-task-exception-accounting-cross/result.json
and build/i386-public-task-exception-accounting-native/result.json). Worker
exceptions repeat each of the four original variants five times, including
retirement with live try records. Late clone-hook failure and dormant disposal
remain separate accounting cases. This is selected-provider qualification,
not a complete current-source self-hosted generation.

Uncaught exception policy, public Kill/break, exit callbacks,
I/O cancellation and full native generation/release evidence remain open.


Public task-end callback prerequisite (2026-10-04):
The new tools/test-i386-public-task-end-callbacks.py executes four original
x64 reference cases: callback on normal return, callback on explicit Exit,
a callback that throws to an active catch and resumes execution, and callback
on queued descendant cancellation inside try. The original reference passes
(build/i386-task-end-callbacks-original-v2/result.json); the pre-change i386
image fails its first EndDone console verdict
(build/i386-task-end-callbacks-red/behavior/debug.log).

The retained memory service now consumes task_end_cb before marking the task
exiting, clears kill/suspension/message-wait/wake state, and invokes the callback
with the existing exception chain intact. A recovered task can create a child;
actual retirement still waits for descendants and drains exception records.
The initial cross-build failure was an undefined NULL constant in this isolated
provider, corrected to its existing zero-pointer convention. No boot-kernel
code or import contract is added.

The original two-generation bootstrap and fresh cross build pass
(build/i386-task-end-callbacks-bootstrap-v4.log and
build/i386-task-end-callbacks-kernel-v4/result.json). All four callback cases
pass under 8 MiB 486,-fpu TCG on both the cross-built and installed guest-built
providers (build/i386-task-end-callbacks-cross/result.json and
build/i386-task-end-callbacks-native/result.json). The 262,928-byte guest-built
memory provider installs, independently boots and passes the 386 executable,
boot-stage and filesystem audit (build/i386-task-end-callbacks-native-memory/result.json,
build/i386-task-end-callbacks-native-install/result.json and
build/i386-task-end-callbacks-native-audit/result.json). The current cross image
also passes the existing 55-command public task lifecycle contract
(build/i386-task-end-callbacks-lifecycle/result.json).

The bootstrap accounting checker now includes 20 callback cycles, repeating
each original variant five times and binding the callback source hash. Cross
and guest-provider accounting runs both pass all 105 commands under 8 MiB
486,-fpu TCG (build/i386-task-end-callbacks-accounting-cross/result.json and
build/i386-task-end-callbacks-accounting-native/result.json). Each run covers
20 ordinary return/Exit, 20 deferred activation, 20 descendant-tree, 20 worker
exception and 20 callback cycles, plus six creation rejections. Every cycle
restores raw used bytes/allocation counts and passes heap validation. Exact VGA,
source-disk and checker hashes remain unchanged. This qualifies the selected
provider, not a fully guest-built current-source generation. Public Kill/break,
private I/O cancellation, dormant
disposal, late clone-hook failure accounting, uncaught exception policy and
complete current-source self-hosted generation/release qualification remain open.

The next cancellation work must also cover a descendant callback that recovers
while its parent is trying to terminate: the original TaskEnd repeatedly requests
child termination until the ring is empty. The current callback corpus proves
recovery for an independently exiting worker and callback-driven Exit for a
canceled descendant; it does not yet prove that combined case. The prepared
original Kill reference passes six variants and null/protected-root rejection
(build/i386-task-kill-original-v2/result.json), but its fixture is still a
build-directory prototype and no public Kill implementation is published.


Descendant callback recovery during parent termination (2026-10-04):
The callback corpus adds a fifth original behavior: the canceled child throws
from its one-shot callback into an active catch, resumes a yielding loop, and
is then terminated before its parent retires. Original x64 passes all five
cases (build/i386-task-end-recovery-original/result.json). The existing i386
provider passes the first four but fails EndDone after EndStart(4)
(build/i386-task-end-recovery-red/behavior/debug.log). It requested termination
only once, so the recovered child could clear KILL indefinitely.

Exit now renews queued-child termination requests after each yield until the
child ring is empty, matching the original TaskEnd policy. Ring traversal stays
IRQ-protected; yielding restores the caller's interrupt state. The original
bootstrap and fresh cross build pass (build/i386-task-end-recovery-bootstrap.log
and build/i386-task-end-recovery-kernel/result.json). All five cases pass under
8 MiB 486,-fpu TCG with exact VGA and unchanged source/checker hashes
(build/i386-task-end-recovery-cross/result.json). The guest compiler rebuilds
and installs the 263,107-byte memory provider, which independently boots without
an FPU (build/i386-task-end-recovery-native-memory/result.json and
build/i386-task-end-recovery-native-install/result.json).

The accounting corpus now repeats each of five callback variants four times.
Both cross/native accounting runs pass all 107 commands with exact allocation
recovery after every cycle, including four repetitions of each callback variant
(build/i386-task-end-recovery-accounting-cross/result.json and
build/i386-task-end-recovery-accounting-native/result.json). The installed
guest-built provider passes all five callback cases under 8 MiB 486,-fpu TCG,
and the independent executable/boot/filesystem audit passes
(build/i386-task-end-recovery-native/result.json and
build/i386-task-end-recovery-native-audit/result.json). Source disks and checker
hashes stay unchanged. This remains selected-provider qualification. Public Kill/break,
private I/O cancellation, dormant disposal, late clone-hook failure accounting,
uncaught exception policy and full self-hosted generation/release qualification
remain open.



Public cancellation tests-first contract (2026-10-04):
tools/test-i386-public-task-kill.py replaces the build-directory prototype.
Its eight original x64 variants pass: pre-entry, running, sleeping and suspended
cancellation, callback recovery, caller-side Break, and asynchronous sleeping/
suspended cancellation. It also rejects null, protected-root and retired task
pointers (build/i386-public-kill-original-v2/result.json). Async Kill initially
preserves wake deadlines and all flags except KILL. A waiting Kill may return
when an exit callback clears KILL and resumes the target; it is not a death wait.
The native baseline first passes the MAlloc lookup control, then fails the Kill
lookup before behavior definitions run (build/i386-public-kill-red-v2/behavior/debug.log).
No public Kill implementation has been published; this checker is deliberately
red until that work is completed.

The next cancellation package must:

1. Extend scheduler eligibility so KILL can admit sleeping/suspended managed
   tasks without prematurely changing their public wake/flag state. Verify the
   private scheduler first and remeasure the native flat image's boot budget.
2. Connect public Kill to owned-task validation, protected root rejection,
   asynchronous requests and the original wait-until-KILL-clears rule. Repeat
   all eight original behaviors on cross-built and installed guest-built providers.
3. Specify self-directed break and BREAK_TO_SHIFT_ESC message delivery before
   claiming full just_break behavior. Preserve break-lock/checkpoint semantics;
   the current caller-side Break case does not qualify the other paths.
4. Cancel private wait queues without abandoning caller cleanup or releasing
   task/code ownership early. Prove I/O cancellation, caught break recovery and
   exact allocation recovery, including tasks inside active try blocks.
Public message/break integration and dormant disposal remain separate required
contracts; passing these eight cases alone does not complete cancellation or M7.


Kill scheduling prerequisite and boot budget (2026-10-04):
The native task corpus adds an executable kill-eligibility test. Workers with
future deadlines and suspension/message-wait flags must run when KILL is set,
without changing those public fields. Private blocking must still prevent
execution. Stack guards, task detachment and exact heap recovery are checked.
The original implementation fails at status 174 (00:AE)
(build/i386-kill-eligibility-red.log).

A first HolyC-only change passes the task and exception regressions and builds
a 483,512-byte cross image, but the guest-built six flat modules total 487,496
bytes, exceeding the 487,424-byte boot budget by 72 bytes. The boot-image builder
rejects them. The console wait was stopped after confirming this semantic
failure, not restarted after an observation timeout
(build/i386-kill-eligibility-native-flat/budget-failure.json).

The final implementation follows the existing scheduler's native-assembly /
retained-HolyC split. Both paths prioritize KILL after private-block/finished
checks and before public suspension/message-wait/deadline eligibility. The
native path compares signed high and unsigned low words of the full I64
clock/deadline, preserving wrap-boundary and negative-deadline behavior. No
wake or flag field is changed by eligibility. ISA audit allowlists now include
only the added JL/JG signed branches; these are 386 instructions, not a new CPU
baseline. The original bootstrap, native task corpus, and retained/core
interop test pass (build/i386-kill-eligibility-asm-bootstrap.log,
build/i386-kill-eligibility-asm-tasks-audited.log and
build/i386-kill-eligibility-retained-kill.log). The interop test adds 20 killed
worker cycles, exercising native and retained eligibility with a deadline
above 2^32 jiffies and exact field/allocation preservation.

The current audited cross image is 482,936 bytes, 472 bytes smaller than the
pre-change image (build/i386-kill-eligibility-asm-audited-kernel/result.json).
The message corpus initially exceeded its 192 KiB loader transfer before
execution. Its test-only transfer is now 256 KiB and its temporary heap is at
0x60000, separate from code, segment records and worker stacks. The expanded
message corpus passes on the final native variant, as does the exception-task
regression and all five public callback cases under 8 MiB 486,-fpu TCG
(build/i386-kill-eligibility-asm-messages.log,
build/i386-kill-eligibility-asm-exceptions.log and
build/i386-kill-eligibility-callbacks/result.json). The corrected six-module
guest-flat build stopped at a native frontend rejection of OR register/memory
in SchedulerCore.HC line 198, before a flat image could be linked
(build/i386-kill-eligibility-asm-native-flat/frontend-failure.json).
Keep the first variant and final assembly-source evidence separate. Public Kill/break remains
unpublished, and full native current-source generation/release qualification
remains open.


Guest assembler closure for kill eligibility (2026-10-04):
The original compiler accepts the compact scheduler, but the native frontend
lacked OR register/memory, TEST r/m32 with an immediate, signed JL/JG branches,
integer expressions in immediates and additive class-member displacements.
The failed guest build is confirmed by its source-line/status trace; its
console wait was stopped after compilation rejection. The scheduler source
is retained rather than replacing these HolyC assembly forms with a workaround.

FrontendStatements.HC now adds those encodings and an integer constant-expression
reader with unary operators, parentheses, arithmetic, shifts and bitwise
precedence. Existing accumulator TEST encoding stays unchanged. The operand
fixture and independent expected opcode bytes cover OR with a memory operand,
a shifted/combined TEST mask, parenthesized arithmetic/unary precedence,
member+4 addressing and zero-displacement signed branches. The final original
bootstrap and fresh cross build pass
(build/i386-kill-asm-frontend-final-bootstrap.log and
build/i386-kill-asm-frontend-kernel/result.json). The guest fixture passes the
exact-byte oracle with an unchanged input image
(build/i386-kill-asm-frontend-fixture/result.json). Corrected six-module native
build/install/boot qualification now passes
(build/i386-kill-asm-frontend-native-flat/result.json). All six flat modules
are guest-built; all six retained providers remain cross-built development
inputs. The 486,920-byte flat image leaves 504 bytes in the existing boot region
and passes the independent 386 instruction/boot/filesystem audit
(build/i386-kill-asm-frontend-native-flat/instruction-audit/result.json).
Building uses 16 MiB and the installed image independently boots at 8 MiB
without an FPU. Public Kill remains unpublished,
and complete self-hosted release qualification remains open.


The reusable tools/test-i386-asm-recovery.py also passes nine console commands
with exact VGA and an unchanged input disk
(build/i386-kill-asm-recovery-contract/result.json). DolDoc creates and saves an
invalid assembly source; division by zero is rejected without publishing its
output module. A subsequent valid operand fixture matches the exact byte oracle,
and the prompt still evaluates 6*7. The checker and validator hashes are frozen
through the run. The first probe attempted the still-unpublished FileWrite API;
the successful contract uses the existing DocWrite path. This does not establish
all compiler error paths or full public file-write compatibility.

The kill-scheduling prerequisite is now verified through native and retained
scheduler tests, message/exception/callback regressions, guest assembly byte and
error-recovery tests, and a guest-built flat image that fits and boots. Continue
with the public cancellation package above; its eight-case public Kill checker
remains deliberately red until the API is implemented. These proofs are not full
current-source two-generation or release qualification.

### Public cancellation: caller Shift-Esc reference contract

The public Kill checker now covers nine variants. A fresh original x64 run
passes all of them (build/i386-public-kill-shift-reference-v2/result.json).
The added variant requests just_break on another task while the caller has
TASKf_BREAK_TO_SHIFT_ESC set. It requires delivery to the caller of MSG_KEY_DOWN
with CH_SHIFT_ESC and scan code 0x20100000201, and verifies that the target
remains alive before ordinary cancellation and stale-pointer rejection.
Original Kill returns FALSE after this successful message delivery: Break
returns rather than throws, and Kill falls through to its FALSE return.
The first probe incorrectly expected TRUE and failed; the corrected oracle
passes. Preserve this observed contract when implementing the port.

Public Kill remains unpublished and the native checker remains deliberately
red. Implement original public message/job handling before claiming full
just_break compatibility; the private bounded message queue is not sufficient
proof. Self-directed break and resource-wait cancellation still need dedicated
contracts. This change adds reference evidence, not native runtime support or
release qualification.

### Public messages: original behavior reference

Added tools/test-i386-public-messages.py before implementing public message
services. Five contracts pass on the original x64 OS
(build/i386-public-messages-original/result.json): a 40-event FIFO, destructive
mask filtering, negative-code paired down/up events, flush counts with empty
output clearing, and delivery through PostMsg/GetMsg to a waiting child.
The queue-depth contract deliberately exceeds the private queue's 16 slots.
Keeping the original programming model requires public job-backed message
semantics rather than merely publishing aliases for that private queue.

The native runner is available but was not executed in this source epoch:
Msg, ScanMsg, GetMsg and PostMsg are not published by the current runtime.
Next implement the shared CJob records, task queue initialization/retirement
and public delivery/scan services, with additional contracts for input filtering,
popup routing, resource ownership and allocation recovery. Integrate these
services with Break and Kill, then qualify native builds within the boot budget.
The original five-case pass is reference evidence only; it does not prove
native message support or the broader job subsystem.

### Shared public job records

Moved the original job constants and CJob definition verbatim from KernelA.HH
into Kernel/JobTypes.HH and included it in both original and native public
headers. The port now has a complete public CJob record instead of only a
forward declaration. Native compiler layout probes require its 80-byte size
and all fourteen field offsets. This adds no message service implementation
and does not change existing CTask or CJobCtrl fields.

A byte-for-byte extraction check passes. Current-source original two-generation
rebuild passes (build/rebuild-test/result.json), and the original layout
comparison preserves all 105 task fields (build/task-layout/result.json).
The first native qualification (build/i386-public-job-records-kernel)
passes cross-build and 386 boot audit but terminates with FAIL after the bit
check: its header probe still requires the previous 113 assertions. The fifteen
new CJob assertions make 128; both the guest assertion count and independent
host expectation now require 128 in both boot and task phases. The corrected current-source two-generation rebuild passes. Fresh native
qualification is running in build/i386-public-job-records-kernel-v2; its
both boot and task phases pass all 128 public layout assertions, including
the fifteen new CJob checks. Header rollback/retry and task cleanup also pass.
The broader console/startup and build-suite terminal result remains pending. The native compiler has executed the new layout assertions in both contexts;
this proves the shared record layout, not public message service behavior. Continue queue initialization and
retirement work after this shared-record prerequisite is verified.

### Public task job-queue initialization (new source epoch)

Added shared JobCtrlInit.HC, used by original Job.HC and the native public
task runtime. Its pointer assignments reproduce QueInit's empty circular rings
for both waiting and done queues and clear control flags. Root binding, Spawn
and first managed yield of private workers now initialize their public queues.
The public-message reference adds a sixth contract for constructor ring links
and flags. This is queue initialization only: posting, scanning, job ownership
and retirement of nonempty queues remain unimplemented.

The new-source two-generation rebuild passes. The earlier shared-record
build remains live against its captured image in
build/i386-public-job-records-kernel-v2 and has passed both 128-assertion
layout phases; its broader suite does not qualify these new lifecycle edits.
The first two six-case fixtures called JobCtrlInit directly, but this internal
helper is not declared in the original public API. Both stopped in the compiler
before the start marker. The initial stack-declaration diagnosis was premature;
changing the local declaration did not fix the private-API call. The corrected
fixture checks actual root/child queue links and passes all six original message
contracts (build/i386-public-messages-init-original-v3/result.json).

A dedicated tools/test-i386-public-task-queues.py passes the original root plus
ten-child contract (build/i386-public-task-queues-original/result.json).
The current-source cross-build and 386 boot audit pass
(build/i386-public-task-queues-kernel/result.json), with the flat image unchanged
at 482936 bytes. Native focused queue qualification passes
(build/i386-public-task-queues-native/result.json): 18 console submissions on
486,-fpu with 8 MiB, exact VGA at each checkpoint and unchanged input disk. It does not cover queued-job cleanup or
public message delivery. The previous-source broader suite remains live.

### Task retirement: queued-job ownership

The focused public-task queue contract now has twelve cases, adding retirement
of three jobs across waiting/done rings with separately allocated auxiliary
strings. Nodes and strings belong to the caller heap, allowing exact usage
recovery to be checked independently of Adam's shared system/task allocations.
The first fixture measured the Adam heap and failed on the original OS; the
corrected caller-heap fixture passes all twelve cases
(build/i386-public-task-job-cleanup-original-v2/result.json).

The native baseline observation confirms QueueCleanup=0 against the preceding
immutable queue-initialization image
(build/i386-public-task-job-cleanup-native-red/result.json). The contract
requires 1; all other submitted checks match and the input disk is unchanged.
This is a verified red contract, not native cleanup support.
The native implementation now drains both public job rings, freeing auxiliary
strings and nodes through their owning public heaps at actual Exit, after
callback recovery opportunities and child retirement. Current-source original
two-generation rebuild passes. The fresh native build and 386 boot audit pass
(build/i386-public-job-cleanup-kernel/result.json), retaining the 482936-byte
flat image. Green cleanup qualification passes
(build/i386-public-task-job-cleanup-native/result.json): twelve cases across
24 console submissions at 8 MiB on 486,-fpu, exact VGA and unchanged input
disk. The checker SHA matches the original and verified-red reference.
The existing five-case callback-recovery regression also passes
(build/i386-public-job-cleanup-callbacks/result.json): 28 submissions on the
same immutable no-FPU image. It checks one-shot return/Exit callbacks,
exception recovery and descendant cancellation, but does not specifically
exercise a callback recovering with nonempty job queues. Public message
posting/scanning and full job-service compatibility remain open. This does not implement public message services.

### Public messages: filter and popup routing references

The message checker now has thirteen original-OS contracts. All pass
(build/i386-public-message-popup-original/result.json). The intermediate
nine-case reference also passes
(build/i386-public-message-routing-original/result.json). New checks cover
forward filter routing, explicit DONT_FILTER bypass, backward posting from an
input-filter task, popup fallback to its parent's queued message, rejection of
parent posts while a popup exists without FILTER_INPUT, direct popup delivery
and clearing AWAITING_MSG along the parent/popup chain.

The fixture temporarily constructs a two-task input-filter ring and popup
relationship through public task fields, then restores links before retirement.
This verifies message routing, not the original InputFilterTask job-execution
loop, macro recording or complete window-manager behavior. Public messaging
remains unpublished in the port, and native acceptance is still pending.
Implement posting and scanning against shared job records, preserving these
routes alongside unbounded FIFO and paired-event behavior; initialize native
input-filter self-links and maintain their lifetime as part of that package.
The preceding-source broader native suite is still live and is not a proof of
these new message contracts.

### Input-filter task links

Added tools/test-i386-public-task-filter-links.py. The original OS passes
eleven checks (build/i386-public-filter-links-original/result.json): the
caller starts self-linked, each of ten spawned children starts self-linked,
and each child temporarily joins the caller's input-filter ring before exit
restores the caller's self-links. A preceding-image native observation gives
verified red results, zero where each check requires one
(build/i386-public-filter-links-native-red/result.json), with unchanged disk
and frozen checker hash.

Native root binding, public Spawn and first managed yield now initialize
input-filter self-links; partially initialized private-worker links are
rejected. Actual public task Exit removes the retiring task from its
input-filter ring after job cleanup and resets its own links. This preserves
the original topology/lifetime needed by message routing, without publishing
message services yet. The current-source two-generation rebuild passes.
The fresh native build and 386 boot audit pass
(build/i386-public-filter-links-kernel/result.json), with the flat image still
482936 bytes. Green runtime qualification passes
(build/i386-public-filter-links-native/result.json): eleven cases across
19 console submissions. Queued-job cleanup and callback regressions also pass
(build/i386-public-filter-links-queues/result.json and
build/i386-public-filter-links-callbacks/result.json): twelve queue cases
and five callback cases. All three use the same immutable 486,-fpu image at
8 MiB, exact VGA checkpoints and unchanged input disk.
The focused contract checks caller/child link lifetime, not execution of the
original input-filter job loop or full window-manager behavior.

### Shared public message codes

Moved the original message code definitions and help text verbatim from
KernelA.HH into Kernel/MessageCodes.HH. Native PublicKernel.HH now includes
that same header, providing the original thirteen ordinary message codes
and five paired-event aliases. Previously the native public header did not
define these names, independently of its missing message service APIs.
A byte-for-byte extraction check and both original rebuild generations pass.
Fresh native build and 386 boot audit pass
(build/i386-public-message-codes-kernel/result.json), with the flat image
unchanged at 482936 bytes. Native public-header/code-value qualification
passes (build/i386-public-message-codes-native/result.json): all eighteen
values are evaluated from the loaded public header on 486,-fpu at 8 MiB,
with exact VGA checks and an unchanged input disk. This change
only supplies the shared constants and does not publish message services.

### Task validity at retirement

TaskValidate already exists in the retained window provider and shares the
original signature/range check; do not replace it with a different registry
contract. A tests-first lifecycle check now exposes a scheduler gap: a task
retired while its heap is locked still passes TaskValidate until reaping.
The original OS invalidates its signature at retirement.

The new tools/test-i386-public-task-validity.py passes three original contracts
(build/i386-public-task-validity-original/result.json): current/root validity,
live child validity, and dead child invalidity before releasing its heap lock.
A preceding native image gives verified red, ValidateHold=0 where 1 is required
(build/i386-public-task-validity-native-red/result.json), with frozen checker
and unchanged input disk. Scheduler finish now clears the public task signature
after cleanup and ring detachment, before waking joiners/switching. Callback
recovery remains before actual retirement. Deferred heap/storage cleanup can
continue through private ownership records without advertising a live task.

The original two-generation rebuild, native build and 386 boot audit pass
(build/i386-public-task-validity-kernel/result.json). The cross-built flat
kernel is 483016 bytes, 80 bytes larger than the preceding source epoch.
Native scheduler and retained task-core regressions pass
(build/i386-task-validity-scheduler.log and
build/i386-task-validity-retained.log). Public validity green and callback/queue
regressions also pass (build/i386-public-task-validity-native/result.json,
build/i386-public-task-validity-callbacks/result.json and
build/i386-public-task-validity-queues/result.json). All three runtime checks
use the same immutable 486,-fpu image at 8 MiB, with exact VGA and unchanged
input disk. Guest-built flat-image budget qualification is still required;
these checks do not establish current-source self-hosted release readiness. This fixes a recipient-lifetime prerequisite, not public
message posting; arbitrary unmapped-pointer safety is outside TaskValidate's
original contract.

### Message scanning includes job dispatch

The message reference now passes fourteen original contracts
(build/i386-public-message-job-call-original/result.json). The added case
queues a JOBT_CALL before a message, then uses ScanMsg. The call must run,
return 42 and enter the completed queue with DISPATCHED/DONE flags before
the message is returned. The fixture removes/frees its completed job.
This reflects original ScanMsg calling JobsHndlr for the current task;
a message-only queue scanner would not preserve the programming model.
EXE_STR/SPAWN job execution, macro recording and allocation recovery remain
outside this reference and require further coverage.

Continue implementation in this order:

1. Publish TaskMsg/PostMsg/Msg against root-owned shared CJob allocations,
   preserving metadata, paired events, filter routing and popup wake flags.
   Keep recipient validation based on the shared original signature helper.
2. Provide current-task job dispatch before ScanMsg/GetMsg. Preserve call
   results, completion queues, exception handling, wake/focus flags and
   execution of queued source/spawn requests; connect compiler/window hooks
   where those services belong in separate retained providers.
3. Qualify posting, dispatch, scanning, flushing and waiting together against
   original references, plus cleanup and cancellation regressions. Complete
   keyboard/public-message integration and macro recording coverage rather
   than declaring the private bounded queue to be equivalent.

The preceding-source broad native suite now passes for its version-12 snapshot
(build/i386-public-job-records-kernel-v2/result.json); it is not current-source
qualification.
The signature-retirement snapshot's guest-built flat qualification passes, as
recorded below. Public posting is now published; scanning and dispatch remain open.

### Public message posting (qualified original and native contracts)

Added original-signature TaskMsg/PostMsg/Msg declarations and root-owned
job-backed implementations in the retained memory provider. Posted CJob
records retain master, flags and full-width arguments; negative codes queue
down/up pairs. Posting follows input-filter routes and clears recipient idle
and popup-chain awaiting flags without changing wake deadlines. Task validity
uses the shared original signature helper. The provider now exports 33
services, version 13; its flat imports remain unchanged.

A separate posting contract passes five original cases
(build/i386-public-message-posting-original-v2/result.json): 40-event FIFO,
paired events, invalid recipient/master rejection, full-width metadata,
system-heap ownership and wake flags. It inspects and frees the public job nodes directly and does not
use an alternate scanner to pretend ScanMsg is implemented. Both original
rebuild generations and the fresh native build/386 boot audit pass
(build/i386-public-message-posting-kernel/result.json). Native posting
qualification passes in build/i386-public-message-posting-native-v2: five
contracts and 15 commands on 486,-fpu at 8 MiB, with VGA checkpoints matching
and the source disk unchanged. Twelve queued-job cleanup cases and five
callback cases pass on the same image (build/i386-public-message-posting-queues
and build/i386-public-message-posting-callbacks).
Routing/popup qualification against this provider, failed-allocation recovery,
job-aware scanning/waiting, keyboard adaptation and macro recording remain
open. The posting provider does not yet implement macro recording. This is
partial message-subsystem progress, not complete original message compatibility.

The preceding signature-retirement source snapshot's guest-built flat image
passes (build/i386-public-task-validity-native-flat/result.json): 487000 bytes,
424 bytes spare. All six flat modules are guest-built; all retained modules
remain cross-built development inputs. Build uses 16 MiB and independent boot
uses 8 MiB on 486,-fpu. Its independent instruction audit passes
(build/i386-public-task-validity-native-flat/instruction-audit/result.json). This
proves the earlier snapshot's budget, not current version-13 provider release
qualification or fully guest-built retained generations.

### Expanded posting routing contracts

The posting checker now has eleven cases. Six additional cases directly inspect
public CJob queues after forward filter routing, DONT_FILTER bypass, backward
input-filter posting, popup-parent rejection, direct popup delivery and
popup-chain wakeup. Two live worker tasks provide the fixture; their filter
links and parent/popup relationships are restored before retirement. No scanner
substitute is supplied. The original reference passes
(build/i386-posting-routing-original/result.json); native qualification passes
against the unchanged version-13 provider in
build/i386-posting-routing-native: eleven cases, 44 commands, all VGA pixels
matching at checkpoints, 8 MiB on 486,-fpu, source disk unchanged. Earlier five-case native qualification and
cleanup/callback regression results remain valid for that provider.

### Dispatch callback argument and master completion reference

The original message reference now passes fifteen contracts
(build/i386-message-master-call-original/result.json). The additional queued
JOBT_CALL supplies argument 35 to a callback returning argument+7, names the
current task as master, and checks its completed queue, result 42 and
DISPATCHED/DONE flags before ScanMsg returns the following message. It removes
and frees the completed job. Native dispatch/scanning is still unimplemented;
this reference supplies acceptance evidence rather than native qualification.
Queued source execution, spawned jobs, exception handling, focus/wake flags and
macro recording still need their own coverage and implementation.

### Public suspension for master wakeup (native qualification pending)

Added original-signature Suspend and IsSuspended to the retained memory
provider (version 14, 35 exports, unchanged flat import contract). Suspend
validates the original task signature with interrupts saved, changes only the
SUSPENDED bit and returns its previous state; NULL means the current task.
The existing scheduler already skips suspended tasks. Job completion can use
this API to clear master suspension without changing wake deadlines.

Five original contracts pass
(build/i386-public-suspend-original-v2/result.json): default caller and previous
state, preservation of caller flags/wake deadline, invalid signature rejection,
child exclusion while suspended and scheduling after resume. Rebuild/native
qualification is in progress; this does not publish job dispatch or Kill.

Version-14 cross-build and boot instruction audit pass (483016 flat bytes), but
both native interactive checks fail before commands during PublicKernel header
publication: `Invalid lval`. The new Suspend default used TRUE before StartOS
publishes boolean names in that compilation scope. PublicTask now spells the
same default as literal 1, consistent with bootstrap header dependencies.
Fresh rebuild and native qualification of this correction are pending; the
failed runs are build/i386-public-suspend-native and
build/i386-public-suspend-posting. They do not qualify suspension or posting on
version 14. The preceding version-13 posting results remain separately valid.

### Job callback exception reference

The original message reference passes sixteen contracts
(build/i386-message-call-exception-original/result.json). A queued JOBT_CALL
throws JobTest; original JobsHndlr handles the exception, places the job in the
completed queue with DISPATCHED/DONE flags and its initially zero result, then
ScanMsg returns the following message. The fixture frees the completed node.
This adds a recovery contract for native dispatch; it does not prove general
uncaught child-exception isolation, which remains open.

The Suspend header correction passes both original rebuild generations.
Its fresh native build is running in build/i386-public-suspend-fixed-kernel;
native runtime qualification remains pending.

### Historical broad-suite result and corrected header boot

The broad shared-job-record build/test run is terminal success
(build/i386-public-job-records-kernel-v2/result.json): memory provider version 12,
128 header-layout checks in both phases, interactive VGA/compiler checks,
module rejection, disk/tree installation and original-reader document round
trip. Its manifest records revision a09c03c4 with a dirty worktree, and flat
kernel size 482936. This is historical evidence for that captured source, not
qualification for later posting/suspension changes or full release readiness.

The corrected version-14 build passes its 386 boot instruction audit and
produces a 483016-byte flat kernel
(build/i386-public-suspend-fixed-kernel/result.json). Native logs confirm
PUBLIC HEADERS ok, resolving the earlier startup publication failure.
Suspension runtime qualification passes in
build/i386-public-suspend-fixed-native: five cases and 16 commands at 8 MiB on
486,-fpu, all VGA checkpoints match and source disk is unchanged. Posting
regression passes in build/i386-public-suspend-fixed-posting: eleven cases,
44 commands, matching VGA checkpoints at 8 MiB on 486,-fpu, unchanged source
disk.

### Spawn and source job acceptance contracts

The original message reference now passes eighteen cases
(build/i386-message-spawn-source-original-v2/result.json). A queued
JOBT_SPAWN_TASK must complete before the following message, publish its child
pointer and requested parent, and run that child with argument 42. The child
stays live until explicitly released; the fixture waits for its completion.
A queued JOBT_EXE_STR compiles `6*7;` and must retain result 42 and completion
flags before the following message is returned. Completed jobs and auxiliary
strings are freed. The initial fixture failed to compile due to an invalid
parent cast; the corrected rerun passes. These references cover all three
original dispatch kinds; native dispatch/scanning remains open, as do further
completion-flag, allocation-failure and macro-recording contracts.

### Native public job dispatch implementation (qualification pending)

Added JobsHndlr to the retained memory provider (version 15, 36 exports,
unchanged flat import set). It executes original CALL, SPAWN_TASK and EXE_STR
jobs, records dispatch/completion results, handles callback exceptions,
completes into master/servant queues, honors FREE_ON_COMPLETE and
EXIT_ON_COMPLETE, wakes suspended masters and updates sys_focus_task unless
self-focus is inhibited. The retained console provider publishes a private
source-execution hook and the focus variable; job source compiles in the
servant's live scope. The dispatcher resolves those services through public
symbol tables rather than adding flat imports. Missing services raise JobSvc;
this does not silently convert queued source into a no-op.

Five direct-dispatch contracts pass on original TempleOS
(build/i386-public-dispatch-original/result.json): callback argument/result,
callback exception completion, queued source result, master wake/focus and
spawned-child parent/argument/lifecycle. Both original rebuild generations pass.
Fresh native build and 386 boot audit pass in build/i386-public-dispatch-kernel
(483016 flat bytes). Direct-dispatch qualification is running in
build/i386-public-dispatch-native; posting regressions are running in
build/i386-public-dispatch-posting.
Free/exit completion flags, inhibited focus, failures and cancellation need
further runtime coverage. ScanMsg/GetMsg/FlushMsgs are not yet published;
keyboard adaptation and macro recording remain open.

### Job-aware public message consumption (native qualification pending)

Version-15 direct-dispatch native qualification passes
(build/i386-public-dispatch-native/result.json): five contracts, 32 commands,
matching VGA checkpoints at 8 MiB on 486,-fpu and unchanged input disk. This
qualifies that captured dispatcher image, not subsequent scanning changes.
Its eleven-case posting regression also passes
(build/i386-public-dispatch-posting/result.json): 44 commands with matching VGA
checkpoints on the same unchanged image.

Added ScanMsg/GetMsg/FlushMsgs to the retained memory provider (version 16,
39 exports, unchanged flat imports). ScanMsg executes pending current-task jobs
before consuming messages, destructively filters by mask, zeroes empty outputs,
falls back to popup parents and honors key-description inhibition. It captures
arguments before freeing the job, avoiding the original aux2 read after free.
GetMsg yields with the original idle-bit behavior; FlushMsgs returns the number
of consumed messages. Both original rebuild generations pass. Native build is
running in build/i386-public-message-scan-kernel; runtime qualification remains
pending. The current eighteen-case original reference passes
(build/i386-message-full-source-original/result.json); its native expectations
include the result printed by queued source execution. Keyboard integration,
macro recording, allocation recovery and additional completion flags remain
open. No current-source self-hosted release qualification is claimed.

The initial version-16 cross-build fails before MemoryRuntime export because
SCF_KEY_DESC is absent from the split scan-code header
(build/i386-public-message-scan-kernel/exports/compiler-log.DD). The retained
scanner now uses the original SCf_KEY_DESC bit 31 explicitly, alongside the
original WIf_SELF_KEY_DESC bit 12, and removes the unnecessary scan-code include.
A fresh original rebuild of this correction is running. No version-16 native
runtime pass is recorded; preceding version-15 results remain separately valid.

### Key-description filtering acceptance

The full message reference passes nineteen original cases
(build/i386-message-key-description-original/result.json). With inhibit bit 12
set, a KEY_DOWN carrying scan bit 31 must be discarded, while the following
ordinary key event must be delivered and leave the queue empty. The fixture
restores the caller's inhibit flags. This exercises the scanner path that
captures aux2 before freeing the job. Both rebuild generations pass after the
constant-dependency correction; the fresh version-16 native build and 386 boot instruction audit pass
in build/i386-public-message-scan-fixed-kernel (483016 flat bytes). Native
message qualification is running in build/i386-public-message-scan-native,
including this filtering case. Queue cleanup and callback regressions are
running on the same image in build/i386-public-message-scan-queues and
build/i386-public-message-scan-callbacks.

### Completion flags and current-source retained rebuild

The direct-dispatch reference passes seven original cases
(build/i386-public-dispatch-flags-original/result.json). Added FREE_ON_COMPLETE
checks require both queue rings empty/unlocked and task heap usage restored
after freeing job plus auxiliary text. Added inhibited-focus checks preserve
the chosen focus task and restore fixture state. Expanded native qualification
is running in build/i386-public-dispatch-flags-native on the version-16 image.

On that same image, twelve queued-job cleanup cases and five callback recovery
cases pass (build/i386-public-message-scan-queues/result.json and
build/i386-public-message-scan-callbacks/result.json), at 8 MiB on 486,-fpu with
matching VGA checkpoints and unchanged input disk. Full nineteen-case message
qualification remains running in build/i386-public-message-scan-native.

Current-source guest compilation of all six retained providers is running in
build/i386-public-message-scan-retained, using the version-16 cross-built input
and matching export contracts, 16 MiB and 486,-fpu. This is only a build attempt;
installation, independent boot, flat guest rebuild, subsequent generations and
release qualification are not implied before their own results are verified.

### Native message consumption qualification

Full version-16 message qualification passes
(build/i386-public-message-scan-native/result.json): nineteen contracts, 82
commands, all VGA pixels match at each checkpoint, 8 MiB on 486,-fpu, unchanged
source disk. Seven direct-dispatch contracts also pass on that same image
(build/i386-public-dispatch-flags-native/result.json), including exact heap
recovery for FREE_ON_COMPLETE and inhibited focus. Queue cleanup/callback
regressions pass as recorded above. Keyboard adaptation, macro recording,
allocation-failure contracts and release self-hosting generations remain open.

A new EXIT_ON_COMPLETE reference fixture times out on original TempleOS
(build/i386-public-dispatch-exit-original). The saved screen shows the OS alive;
no exit-contract pass is claimed. A phase-marked reference rerun is running in
build/i386-public-dispatch-exit-original-trace to identify the stalled fixture.
The seven-case dispatch and nineteen-case message passes use the earlier
captured checkers and are not invalidated by adding this unqualified case.
Current-source guest rebuild of all six retained providers remains live in
build/i386-public-message-scan-retained, currently compiling MemoryRuntime.

### Exit-on-completion oracle corrected

The EXIT_ON_COMPLETE fixture's callback now explicitly calls Exit, matching
original TaskEnd's redirected-callback semantics and the existing callback
reference. The original seven-case suite was unaffected; the new fixture's
returning callback was an invalid termination assumption. The phase-marked
run confirmed the stall at that case and was stopped after diagnosis.

The corrected eight-case original dispatch suite passes
(build/i386-public-dispatch-exit-original-final/result.json). Its diagnostic
completion marker uses TRACE rather than DONE so guest-run waits for the
outer suite's PASS/DONE verdict. Native eight-case qualification is running
in build/i386-public-dispatch-exit-native on the existing version-16 image.
The current-source retained guest build is still live and advancing through
module function compilation; its terminal result remains pending.

### Native exit completion and keyboard integration contract

The eight-case direct-dispatch native suite passes
(build/i386-public-dispatch-exit-native/result.json): 46 commands, 8 MiB on
486,-fpu, matching VGA checkpoints, unchanged source disk. The corrected exit
callback explicitly calls Exit; code after JobsHndlr remains unreachable.
Current-source retained guest compilation has advanced into ConsoleRuntime;
its overall terminal result remains pending.

Added tools/test-i386-public-keyboard-messages.py. It waits until a HolyC
function is blocked in GetMsg, injects QEMU make/break for `a`, and checks both
public KEY_DOWN/KEY_UP events, ASCII 97 and scan code 0x1E, then console
recovery with 6*7. The interaction harness can preserve console history for
such commands; existing editor interactions keep their current default. The
baseline attempt is running in build/i386-public-keyboard-messages-red. No
red/green verdict is recorded before its terminal result is inspected.

Next keyboard integration work:

1. Establish a single scheduler-owned input consumer. ConsoleKeys currently
   reads the decoded stream directly, as do six document paths; competing
   consumers would steal events from public GetMsg clients.
2. Route decoded make/break events through PostMsg to the focus task, allowing
   an input worker to run while HolyC code waits or yields. Preserve the IRQ
   break observer and its independent decoder state.
3. Adapt console/document readers to consume public messages without duplicating
   events. Preserve stream-loss/reset behavior, cancellation and popup/filter
   routing; do not flush unrelated commands on a keyboard discontinuity.
4. Qualify public GetMsg key delivery, focus switching, key pairing and lost
   input alongside editor, break and exact VGA regressions. Preserve queued
   non-keyboard messages during input recovery.
5. Complete macro recording and allocation-recovery contracts, then qualify
   guest-built providers through installation, independent boot and successive
   self-hosting generations. Current guest builds are snapshot evidence, not
   a substitute for qualifying subsequent keyboard changes.

### Keyboard delivery baseline and single-consumer implementation

The first keyboard baseline failed during the fixture's unnecessary ports
include, before injection. Removing that include uses the existing OutU8
intrinsic. The corrected baseline is a verified red
(build/i386-public-keyboard-messages-red-v2/result.json): KeyPublic reaches
KEY PUBLIC ready, QEMU injects `a`, and the final VGA verdict times out without
KEY PUBLIC done. The input disk remains unchanged. This proves the missing
public keyboard delivery path rather than a fixture compilation failure.

Added a scheduler-owned keyboard decoder in the retained console provider
(version 33). It posts decoded events through the memory provider's PostMsg
service to sys_focus_task, falling back to the console owner when the focus
signature is invalid. Its default system parent keeps the daemon outside
application child lists. All six document reads and ConsoleKeys now consume
public key messages; only the worker reads the decoded hardware stream.
Required services resolve through symbol tables without new flat imports.
The IRQ break observer retains its independent decoder.

On decoder loss or posting exception, the worker records a reset and removes
only pending keyboard events from the console queue, under its queue lock;
unrelated command jobs remain intact. Console/document readers report the
reset through their existing -1 path. Focus transitions, recovery for other
message clients, allocation failure and the full break/editor regression matrix
still need qualification. No keyboard green result is claimed yet. Rebuild of
the final daemon-parent source is running; fresh cross-build and native tests
are next. The ongoing retained guest build uses the earlier version-16 memory /
version-32 console snapshot captured before these source edits and is now
historical evidence for that snapshot, not the new routing implementation.

### Keyboard routing build qualification started

Console version 33 / memory version 16 cross-build passes
(build/i386-public-keyboard-message-kernel/result.json), including the 386 boot
instruction audit. Flat size remains 483016 bytes. The source used for this
build passes both original rebuild generations. Runtime checks are running:

- public GetMsg hardware make/break: build/i386-public-keyboard-messages-green;
- ordinary console keyboard: build/i386-public-keyboard-console;
- DolDoc edit/save/execute/reopen: build/i386-public-keyboard-doldoc;
- interrupt break recovery: build/i386-public-keyboard-breaks.

These are pending runs, not terminal qualification. They use 486,-fpu; the
public/console checks run at 8 MiB and the DolDoc checker controls its session
profiles. Focus switching, lost-input routing, macro recording and allocation
failure remain additional requirements. The earlier six-provider guest rebuild
is still live for its captured pre-routing snapshot; no current-source full
self-hosting/release claim is made.

### Keyboard routing initial-focus correction

The first console-33 runtime runs fail before accepting their first command:
public keyboard, ordinary keyboard, breaks, and the DolDoc session all time out
at initial typing. The image reaches normal startup; no keyboard green result
is claimed. The DolDoc result records an unchanged source disk and an incomplete
create/edit/save phase. Results/logs are in the four directories above.

ConsoleInit executes in the kernel root task before Kernel spawns ConsoleKeys.
Setting sys_focus_task there directed the new input worker's messages to the
valid kernel root, which does not consume console input. Initial focus now
moves to ConsoleKeys entry, where the actual console task is available, before
startup code or the keyboard worker runs. ConsoleInit only publishes the focus
variable. Rebuild of this correction is running; a fresh cross-build and rerun
of all four runtime checks are required. No syscall/API layout changes are
introduced by this fix.

### Keyboard focus correction did not restore input

The corrected-focus build and 386 boot audit pass, but all four reruns still
fail at initial typing (build/i386-public-keyboard-focus-green,
build/i386-public-keyboard-focus-console, build/i386-public-keyboard-focus-breaks,
build/i386-public-keyboard-focus-doldoc). Moving focus out of ConsoleInit fixes
an incorrect assignment but does not establish that the worker runs or posts
valid events. No keyboard green result is claimed.

Added bounded debug-port markers for worker entry, its first decoded event and
target signature, and the console/worker pointers returned by startup. Both
original rebuild generations pass for this diagnostic source; fresh cross-build
is running in build/i386-public-keyboard-trace-kernel. These markers do not add
startup diagnostic workloads or alter the VGA console.

Added a separate focused-child keyboard checker, keeping the existing public
keyboard checker frozen during its runs. The first attempt failed at initial
typing on the same broken image; its new fixture also contained a 258-byte
line, which is now shortened below the 255-byte limit before qualification.
Focus routing is still unqualified. The older retained guest rebuild remains
live for its captured pre-keyboard-routing snapshot.

### Keyboard bootstrap queue enrollment

The diagnostic cross-build passes its 386 instruction audit, but the public
keyboard run in build/i386-public-keyboard-trace/result.json fails at initial
typing with the source disk unchanged. Its log records a nonzero keyboard task
and normal startup, but no worker entry or decoded-event marker.

Source inspection identifies an ordering defect: the private boot console's
public job rings are initialized by MemoryTaskEnsure on its first managed
yield. NativeReadKey now calls ScanMsg before that yield; JobsHndlr therefore
reads an uninitialized waiting ring before scheduling the keyboard worker.
NativeKeyboardStart now performs the managed yield before spawning the worker
or scanning public messages. This preserves the existing enrollment mechanism
for private boot workers and introduces no public API or module-layout change.

Both original rebuild generations pass for this fix (build/rebuild-test).
A fresh cross-build is running in build/i386-public-keyboard-enrolled-kernel;
runtime verification remains required. This is a source fix, not a keyboard
qualification result. Focus, input loss, macro recording and
current-source self-hosting/release qualification remain open.

The first enrollment cross-build rejected `task->owner`: `task` is a public
CTask, while owner is a private CI386Task field. The yield now accesses owner
through I386TaskSelf, matching existing console scheduler calls. Both original
rebuild generations pass with this correction. Fresh cross-build output is
build/i386-public-keyboard-enrolled-fixed-kernel; runtime verification is still
pending. The failed earlier build is not a runnable qualification image.

### Public hardware keyboard delivery qualified

The corrected enrollment image passes cross-build and the 386 boot instruction
audit (483016 flat kernel bytes). The public keyboard checker now passes in
build/i386-public-keyboard-enrolled-fixed/result.json on 486,-fpu, 8 MiB:
five commands, hardware make/break through GetMsg with ASCII/scan assertions,
all VGA pixels matched, resumed console evaluates 6*7 to 42, input disk unchanged.
Its image SHA-256 is
860802b94d957b743d76643f7c46329a564668c08ffe2c60a0dac3dc765082ce;
checker SHA-256 is
b17bd16b5727284dfba42f6059ffde6e8866f1eb003d91ed0aeed162e64fb6a6.
The debug log now records worker entry and its first decoded event, supporting
the bootstrap ordering diagnosis. Both original rebuild generations pass.

Broader fresh-image checks are running: focused child delivery in
build/i386-public-keyboard-enrolled-focus, ordinary keyboard in
build/i386-public-keyboard-enrolled-console, break recovery in
build/i386-public-keyboard-enrolled-breaks, and DolDoc workflows in
build/i386-public-keyboard-enrolled-doldoc. These are pending, not qualification
claims. Input loss, macro recording, allocation recovery and current-source
full self-hosting/release verification remain open.

### Keyboard focus pass and break-recovery regression

The enrollment image also passes the focused-child checker in
build/i386-public-keyboard-enrolled-focus/result.json (seven commands,
486,-fpu, 8 MiB, all VGA pixels matched, unchanged input disk). The child takes
focus, consumes both hardware key events through GetMsg, and restores console
input. Ordinary keyboard tests pass in
build/i386-public-keyboard-enrolled-console/result.json on the same image.

Break recovery fails at HotkeyWait(0) in
build/i386-public-keyboard-enrolled-breaks: the IRQ request reaches the pending
break bit, allowing the wait to return, but execution reports COMMAND OK rather
than Exception. Spawning the root-parented keyboard worker retains a creator
reference to the console for code lifetime. I386TaskBreakPoll previously
deferred delivery for any lifetime_refs, so that permanent worker suppresses
breaks indefinitely. Lifetime references still prevent task retirement; break
polling now relies on its existing blocked/wait, I/O, compiler/control, cleanup
and message-operation guards instead of rejecting inherited child references.

The break fix is not yet qualified. Both original rebuild generations pass;
fresh cross-build is running in build/i386-public-keyboard-break-fixed-kernel
and must be followed by the break regression. The enrollment-image
passes above do not cover this new source. DolDoc workflows remain running on
the immutable enrollment image. Full self-hosting/release gates remain open.

The older six-provider guest rebuild is now terminal PASS in
build/i386-public-message-scan-retained/result.json. All six generated T32Ms
pass layout/export audits against the captured reference exports. Source image
SHA-256: fc879b518a2f1280ce67097691861db5a2ec003534942881a5bda32bb90a6131.
This is the pre-keyboard memory-16/console-32 snapshot, not current-source
qualification. Installation of these exact guest-built providers and an
independent boot are running in build/i386-public-message-scan-retained-install.

### Distinguish inherited references from borrowed-operation references

The first break change restores HotkeyWait(0), but the standalone break suite
still fails at deferred unlock: the VGA frame contains the assignment answer
2048 followed by Exception, instead of Exception alone. Compiler command-input
checkpoints still require lifetime_refs==active_controls; the permanent
keyboard worker's creator reference suppresses that earlier checkpoint.
Focused-child delivery remains green on this intermediate image. The older
enrollment DolDoc session is terminal incomplete at DocEd(break_doc), with its
source image unchanged; a rerun is live on the intermediate break image.

CI386Task now appends a private inherited_refs counter for the persistent
subset of lifetime_refs: child heap/symbol inheritance and entry-code creator
pins. Attach, rollback and retirement update both counters together. Kernel
break polling requires no remaining borrowed-operation references; compiler
polling permits active controls plus inherited references. Destruction still
checks all lifetime_refs, and borrowed file contexts continue to defer breaks.
The public CTask layout is unchanged. Existing heap/creator-pin regressions
now also assert inherited-reference retention and release.

Both original rebuild generations pass for this source. Fresh cross-build is
running in build/i386-public-keyboard-inherited-refs-kernel; the native task-heap
ownership/rollback corpus is also running. Break and DolDoc workflows remain
unqualified for this new source.

The historical six-provider installation and independent boot now pass in
build/i386-public-message-scan-retained-install/result.json (486,-fpu, KVM,
16 MiB install / 8 MiB boot, arithmetic and document-allocation checks).
Installed candidate SHA-256:
78670886167600f64d2108258e13d40993173b800f8cbc1778ab828d79f043d0.
Native flat-kernel self-hosting is running from that guest-built-provider image
in build/i386-public-message-scan-selfhost. This remains captured pre-keyboard
snapshot evidence; it cannot qualify current inherited-reference changes.

The inherited-reference cross-build and 386 boot audit now pass (483360 flat
bytes). Native task-heap qualification passes in
build/i386-task-heaps-test/result.json: four ownership/lifetime cycles,
14 reclaims, selected-parent inheritance and creator-code pin/release,
including the new inherited_refs assertions. The fresh break suite is running
in build/i386-public-keyboard-inherited-refs-breaks. No break green result yet.

### Break recovery with a permanent keyboard worker qualified

The inherited-reference image now passes the full breaks group in
build/i386-public-keyboard-inherited-refs-breaks/result.json: 16 native commands,
486,-fpu, 8 MiB, all VGA pixels matched. This includes immediate and deferred
unlock delivery, loop/goto/do-loop break checkpoints, caught breaks and resumed
console arithmetic. Image SHA-256:
fa4dbe968f8e48923be3ee804d978c8550319f59b19e97664a278f37d58e601c.
This resolves the creator-reference regression observed after adding the
permanent keyboard worker; it does not qualify focused-child break routing.

The intermediate image's DolDoc rerun is terminal incomplete at the same
DocEd(break_doc) checkpoint, with the source disk unchanged. A fresh full
DolDoc session is running against the inherited-reference image in
build/i386-public-keyboard-inherited-refs-doldoc. Public message and direct job
dispatch regressions are also running against that image in the corresponding
build/i386-public-keyboard-inherited-refs-messages and -jobs directories.
The historical all-guest-provider flat rebuild remains live. Full current-source
self-hosting, macro recording, input-loss recovery and release gates remain open.

### Focused-task break red and historical native self-host pass

Current-image direct job dispatch passes all eight cases and 46 commands in
build/i386-public-keyboard-inherited-refs-jobs/result.json: 486,-fpu, 8 MiB,
exact VGA pixels, unchanged input disk. Full messages and DolDoc remain live.

Added tools/test-i386-public-keyboard-break-focus.py: focus a spawned HolyC
loop, inject Ctrl-Alt-C, require that child to catch Break and restore console
focus, then evaluate 6*7. The inherited-reference image records a genuine red
in build/i386-public-keyboard-focused-break-red/result.json: child ready marker
and successful initial VGA checkpoint, followed by timeout after hotkey
injection; source disk unchanged. Checker SHA-256:
5759682de7c24be29f4af7efd2822bf518af0ddd76d692a095f5ff1ba4ab1a41.

The IRQ break handler previously always requested the console source task,
even when a spawned child held input focus. It now requests the valid focused
task, falling back to the submitting console task if focus is unavailable.
IRQ behavior remains request-only. Both original rebuild generations pass;
fresh cross-build is running in build/i386-public-keyboard-focused-break-kernel.
Focused-child break delivery is not yet qualified.

The captured memory-16/console-32 snapshot now passes native flat-kernel
self-hosting with all six guest-built retained providers in
build/i386-public-message-scan-selfhost/result.json: 487000 flat bytes,
16 MiB build, 8 MiB independent boot, 486,-fpu KVM. Independent instruction,
installed-payload and filesystem audit also passes in
build/i386-public-message-scan-selfhost-audit/result.json. Target image SHA-256:
443ce68122e6fcc06a3ed391c85f23fb174b521bb626d8b15d9c3c8c497ca09d.
This is full guest-built-input evidence for that captured snapshot, not
current-source two-generation reproducibility, workstation budgets or release
qualification. The main coverage table now reflects available task services
and distinguishes remaining terminal/debugging workflows.

Full public messages now also pass on the inherited-reference image in
build/i386-public-keyboard-inherited-refs-messages/result.json: 19 cases,
82 commands, 486,-fpu, 8 MiB, exact VGA pixels and unchanged source disk.
This confirms the prior message/job semantics survive hardware queue routing
and the inherited-reference changes. It predates the focused-break IRQ fix;
that fix still requires its fresh hardware contract result.

### Focused-child break routing qualified

The fresh focused-break cross-build and instruction audit pass (483360 flat
bytes). The same checker that recorded the red now passes on that image in
build/i386-public-keyboard-focused-break-green/result.json: six commands,
486,-fpu, 8 MiB, exact VGA pixels, unchanged source disk. The focused spawned
HolyC task catches Break, restores console focus, and console arithmetic
returns 42. Image SHA-256:
e39f7ea1606d395aeb2f6d0b5c548eea2c9f05b16e40ccb6ad09629599d6814c.
The ordinary console break suite also passes all 16 commands on the same image
in build/i386-public-keyboard-focused-break-console/result.json.

The inherited-reference DolDoc session has completed create/edit/save and is
running its second-boot reopen phase; no full three-boot pass yet. A fresh
six-provider guest rebuild is now running from the focused-break image in
build/i386-public-keyboard-focused-break-retained, with its own frozen export
references. This newer epoch includes public keyboard routing, inherited
reference accounting and focused interrupts. Installation, flat self-hosting,
two-generation reproducibility and complete workstation/release qualification
remain required after that rebuild. Input-loss and macro contracts, multiple
interactive terminals and debugging remain open.

### Three-boot DolDoc and hardware loss recovery pass

The inherited-reference image passes the complete three-boot DolDoc session in
build/i386-public-keyboard-inherited-refs-doldoc/result.json: 107 create/edit/save
commands, 56 reopen commands and 15 revised-program commands, 486,-fpu, 8 MiB,
all VGA pixels matched. Boots take 52.69–53.36 seconds; measured editor
interrupt-to-visible-recovery is 0.3925 seconds. Persistent relative/nested
source, rename/move/delete cycles and independent filesystem reachability/bitmap
checks pass; the source disk remains unchanged. This image predates only the
focused-task IRQ selection change and is not a fully guest-built release.

Added tools/test-i386-public-keyboard-loss.py. It consumes a Shift make through
GetMsg, suspends the named keyboard task, injects enough make/break events to
overflow the 64-byte raw queue, resumes the decoder and requires exactly one
visible INPUT RESET. Lower-case HolyC typing and an answer of 42 afterward
check discarded modifier-release recovery. No private queue-memory writes or
changes to the common input runner are used. The checker passes on the latest
focused-break image in build/i386-public-keyboard-loss/result.json: six commands,
486,-fpu, 8 MiB, exact VGA pixels, unchanged source disk. It qualifies console
overflow recovery, not discontinuity notification to arbitrary focused children.

Full workstation integration is running on that same latest image in
build/i386-public-keyboard-focused-break-workstation; the six-provider native
rebuild remains live in build/i386-public-keyboard-focused-break-retained.
Neither pending run is a qualification result. Macro recording, arbitrary
child loss recovery, multiple terminals, debugging and complete release gates
remain open.

### Loss recovery preserves queued work

The hardware-loss checker now also queues a JOBT_CALL before resuming the
decoder, then yields so overflow recovery runs before ordinary console scanning.
After the single reset, the callback must have run exactly once; lower-case
typing still returns 42. The expanded checker passes on the focused-break image
in build/i386-public-keyboard-loss-queued-job/result.json, with exact VGA and
unchanged source disk. This extends the earlier reset/modifier-only result to
the planned non-keyboard-job preservation invariant. Arbitrary focused-child
discontinuity notification and macro recording remain separate open contracts.
The full workstation suite and six-provider native rebuild remain live.

### Macro recording original contract and native red

Added tools/test-i386-public-macro-recording.py with six original/native cases:
recording disabled, positive key-down eligibility, FIFO copied metadata,
macro-task exclusion, negative down/up pair exclusion and invalid-target rejection.
Original TempleOS passes in build/i386-public-macro-original/result.json. The
focused-break native image records a publication red in
build/i386-public-macro-red/result.json: sys_macro_head lookup returns zero;
source disk unchanged. Checker SHA-256:
2010af53914c71e974e561e2e8f4255628c6460fbce8f66c1c5385b4e0ef3fd1.

Extracted the original CSema layout and semaphore constants to SemaTypes.HH;
KernelA.HH includes that shared definition, preserving its 128-byte records and
21 slots. The native memory provider now publishes sys_semas, sys_macro_head
and sys_macro_task as data exports, initializes the recording ring, and copies
eligible TaskMsg records into it before input-filter routing. Existing function
export indices and flat imports are unchanged; memory service version is 17.
Public headers expose the original names. Both original rebuild generations
pass for this source; the same macro contract is being rerun after the shared
header extraction. Fresh cross-build is running in build/i386-public-macro-kernel.
No native macro green result is claimed yet. Playback/UI, filter-specific
recording combinations and allocation recovery remain outside these six cases.
The earlier workstation and six-provider builds continue on their captured
memory-16 keyboard snapshot; they cannot qualify this new provider.

The shared-header original macro rerun passes in
build/i386-public-macro-shared-original/result.json. The memory-17 cross-build
and 386 boot instruction audit also pass (483360 flat bytes). Native macro
verification is running in build/i386-public-macro-green, and the full public
message regression is running on the same immutable image in
build/i386-public-macro-messages. These runs remain pending.

### Native macro pass and copy-allocation recovery red

Memory-17 passes the six frozen macro-recording cases in
build/i386-public-macro-green/result.json: 20 commands, 486,-fpu, 8 MiB,
exact VGA, unchanged image. All 19 public message cases also pass on the same
image in build/i386-public-macro-messages/result.json (82 commands).
The macro run's 77.76-second startup exceeds the 60-second gate; the message
run records 56.62 seconds on that image. These are functional results, not a
blanket timing qualification; a controlled timing profile remains required.

Added tools/test-i386-public-message-allocation.py. On a snapshot it redirects
MAllocIdent's entry to an OutMem-throwing HolyC helper, with IRQs disabled during
the patch, then restores and verifies the original five code bytes. It requires
exact root-public-heap recovery and empty/unlocked destination/recording rings,
plus subsequent arithmetic. The first fixture attempted an unavailable public
hash-record type and failed before injection; it is not a behavioral red.
The corrected fixture uses the public function address and records a genuine
red in build/i386-public-macro-allocation-red-v2/result.json: fault_injected
is true, the OutMem catch marker is present, cleanup returns false, and the
source disk is unchanged. Frozen checker SHA-256:
55e8ed900a7f994d9b87242ecacafeaf5450522eb0e55220dc8d4be4df3f36a8.

TaskMsg allocates the destination job before copying it for recording. A copy
exception previously leaked that unqueued job. The copy is now guarded by a
cleanup catch that frees it and permits normal exception propagation; neither
ring is touched before a successful copy. Both original rebuild generations pass for this
fix; fresh cross-build is running in build/i386-public-macro-copy-recovery-kernel.
The same frozen fault checker is required afterward. This
single injected allocation site does not qualify all posting failures.
Earlier full workstation and six-provider runs remain live for their captured
memory-16 epoch. Current-source full self-hosting/release gates remain open.

### Macro-copy allocation cleanup green

Both original rebuild generations, the fresh memory-17 cross-build and 386
boot audit pass. The same frozen allocation checker that recorded the actual
copy fault now passes in build/i386-public-macro-allocation-green/result.json:
fault_injected=true, 16 commands, 486,-fpu, 8 MiB, exact VGA, unchanged input
disk. It verifies root-heap recovery, empty/unlocked job rings, restored code
bytes and subsequent arithmetic. Image SHA-256:
80669f3ca6d97b8d39e7ca41e19d38b315c11949c1264254acaa446b05c9a8cb.
All six macro cases also pass again on that image in
build/i386-public-macro-copy-recovery/result.json (20 commands). Their boots
record 57.36 and 56.12 seconds respectively; a full controlled candidate timing
profile remains required rather than treating these narrow passes as release
qualification. Other allocation sites, including exception-handler registration,
still need coverage. The older full workstation and six-provider native runs
remain live for their memory-16 snapshot; current-source self-hosting and the
remaining terminal/debugging/release gates are open.

### Exception-handler registration allocation safety

The frozen registration-fault checker
`tools/test-i386-public-message-registration.py` redirects `SysTry` only after
its own handler is registered. On the preceding image it records a genuine
OutMem fault and fails exact root-heap recovery:
`build/i386-public-macro-registration-red/result.json`.
Checker SHA-256: bcce34de9c14314dcfe47df0be27ca6ae81a7a6c43d186c9ad453342880a4b19.

Recording now registers its cleanup handler before allocating either job.
Message construction is shared with the ordinary posting path; a copy failure
still frees the unqueued original and propagates the exception. Both original
rebuild generations and the fresh cross-build/386 boot audit pass. Image:
`build/i386-public-macro-registration-kernel/kernel.img`, SHA-256
c39fbee87397f74249d627da22697c09f192523c498f39346450888fdf23c0a6.
Registration-fault, copy-fault and six-case recording checks are running in
`build/i386-public-macro-registration-{green,copy,macro}`; runtime qualification
is pending, not inferred from the build.

The earlier memory-16 full workstation run has now passed:
`build/i386-public-keyboard-focused-break-workstation/result.json`, 513 native
commands, 8 MiB, 486,-fpu, 53.56-second startup, exact VGA checkpoints and 20
bounded document cycles with exact heap recovery. Its long-document navigation
latency is 0.491 seconds. This qualifies its captured snapshot, not memory-17.
The six-provider guest rebuild remains live and is compiling frontend routines.
Current-source native generations, multiple terminals, debugging and release
qualification remain open; the complete M7 objective is unchanged.

### Registration and copy-fault runtime qualification

All three frozen checkers pass on image
c39fbee87397f74249d627da22697c09f192523c498f39346450888fdf23c0a6:
`build/i386-public-macro-registration-green/result.json` (registration fault),
`build/i386-public-macro-registration-copy/result.json` (copy allocation fault),
and `build/i386-public-macro-registration-macro/result.json` (six recording cases).
Both fault reports confirm actual injection, exact root-public-heap recovery,
empty/unlocked rings, restored entry bytes, exact VGA and subsequent arithmetic.
All source disks remain unchanged. Startup measurements are respectively
55.77, 58.78 and 55.52 seconds on 8 MiB, 486,-fpu; these focused measurements
are not the complete controlled release timing profile.

The full current-image workstation suite is now running in
`build/i386-public-macro-registration-workstation`. The required-services probe
is running in `build/i386-current-debug-publication-red`; public Dbg remains an
implementation gap pending that current-image observation. A debugger must
provide visible exception/context and source/function inspection plus a tested
return/unwind; publishing the name alone cannot close M7. The earlier native
six-provider build remains live for its distinct memory-16 source snapshot.

### Explicit debugger session contract (implementation pending)

The current-image required-services probe records a valid failure in
`build/i386-current-debug-publication-red/result.json`: memory/file controls
and Spawn/Exit/Yield/Sleep are present; only Dbg is absent. Its console run
passes exact VGA checks on the unchanged memory-17 image. This is publication
evidence, not usable debugging.

Added `tools/test-i386-debug-session.py`, a separate black-box contract for
explicit Dbg entry from a named HolyC function. It requires visible message,
numeric value and function name, evaluates an expression within the debugger,
uses original-style `G;` to continue, checks the caller's subsequent state and
runs arithmetic back at the shell. The checker is running against the existing
image in `build/i386-debug-session-red`; its runtime result is pending. The
fixed rows are an independent expected UI, not copied from guest output.

Implementation should preserve the public Dbg signature and HolyC command
model, retain caller context while inspecting, and restore focus/input state
on continuation. This first contract does not close debugging: subsequent
work must preserve and inspect runtime exception context before unwinding,
resolve source/function locations, cover register/context inspection and the
applicable breakpoint/stepping requirements, and verify nested failure and
resource recovery. Multiple interactive terminals and the complete current
native-generation/release gates remain open. The latest full workstation and
older six-provider native build are still running on separate captured images.

### Explicit HolyC debugger implementation — runtime checks pending

The frozen debugger checker records a genuine publication red on the preceding
image in `build/i386-debug-session-red/result.json`: Dbg is absent, so the
required publication expression returns false. SHA-256:
0e3f90a309dce36b68fbf9116b8f1c0f3dc58ab952c5672abd2c61e1610af22f.

Added native Dbg and G bindings through PublicDebug.HH and console services
version 34. Explicit Dbg preserves the planar display and console state, shows
the message/value and a function whose executable allocation contains the
caller return IP, and evaluates HolyC commands in a nested prompt. G requests
continuation; the display/focus and allocated backup are restored on return or
propagated failure. Nested debugger entry is rejected. The 32-bit G default
uses U32_MAX; non-default IP/task control is explicitly unsupported and throws.
This is initial explicit-session support, not the complete debugger contract.

Both original rebuild generations, the fresh cross-build and 386 boot audit
pass. An early cross-build attempt ran before its bootstrap result was available
and terminated with FileNotFoundError; the sequential retry passes. Image
`build/i386-debug-session-kernel/kernel.img`, SHA-256
78e46172f7d0bca1c75c12bbbd67d75835ffd3924a5525360fb49ade1a081e48.
The frozen session checker and required-services probe are running in
`build/i386-debug-session-green` and `build/i386-debug-publication-green`.
These are pending runtime results, not a debugger usability pass.

The memory-16 focused-keyboard six-provider guest build has now passed all six
module layout/export comparisons in
`build/i386-public-keyboard-focused-break-retained/result.json`. Its source
image SHA-256 is ded01e5c8d76ab2ec1273a23f07753a9ab1ee06464bc8a845bd0e766f2f75c1a.
Installation and independent boot are running in
`build/i386-public-keyboard-focused-break-retained-install`. This older epoch
must remain distinct from current memory-17/console-34 qualification. Current
workstation, native generations, exception/source/register debugging,
multiple terminals, timing and release gates remain open.

### Debugger history oracle correction and native provider installation

The console-34 required-services probe now passes on the debugger image:
`build/i386-debug-publication-green/result.json`, 8 MiB, 486,-fpu, exact VGA,
55.86-second startup, unchanged disk. This only proves publication.

The first session run reached all debugger-screen checkpoints, evaluated the
expression and logged return from G, then failed its final console expectation.
Inspection of the saved screen shows preserved original console history, which
is the intended implementation behavior. The checker had used the runner's
history-clearing default. It now explicitly requires preserved history; no
kernel or common-runner behavior was weakened to meet that expectation.
The revised frozen checker SHA-256 is
64b6c039f8812a7d2697d4df7401301aa8d9fda72b8f46b4a2a7f37023ae5fdd.
Both baseline and implementation runs are pending in
`build/i386-debug-session-history-red` and
`build/i386-debug-session-history-green`. The earlier failure is retained in
`build/i386-debug-session-green/result.json`; do not report it as a full pass.

All six guest-built memory-16/console-33 providers installed and independently
booted successfully in
`build/i386-public-keyboard-focused-break-retained-install/result.json`.
Candidate SHA-256:
3ffed5e14a7c8bc61e247b127a8ac40aad79d4f3edcb66e8d96c9f4889984bdb.
Installation preserves all module bytes and the source/candidate images; the
8 MiB boot executes arithmetic and the document-allocation checker.
The flat-kernel self-hosting build is now live in
`build/i386-public-keyboard-focused-break-selfhost`, using these six native
providers without cross-retained inputs. This remains an earlier source epoch;
it does not qualify the new debugger or current release. Full current-source
native generations, terminal/debugger workflows and release gates remain open.

### Explicit debugger session red/green

The revised frozen history checker now records both terminal results:
`build/i386-debug-session-history-red/result.json` fails on the old image's
absent Dbg publication; `build/i386-debug-session-history-green/result.json`
passes all seven commands on the console-34 debugger image. Checker SHA-256
64b6c039f8812a7d2697d4df7401301aa8d9fda72b8f46b4a2a7f37023ae5fdd is identical.
The green run verifies exact VGA for message/value/function, debugger expression
inspection, G continuation, restored console history, caller state and shell
arithmetic. It uses 8 MiB, 486,-fpu, boots in 56.72 seconds and preserves the
source disk. Exception/register/source inspection, breakpoint/stepping behavior,
nested error/resource recovery and complete M7 remain unqualified.

### Runtime exception inspection before compiler cleanup

Added `tools/test-i386-debug-exception.py`, frozen SHA-256
c649641431bcafa5d3f01d706b4f3b84222a7beb3812f166bc8d9c872003ca90.
The existing explicit-debugger image gives a publication red in
`build/i386-debug-exception-red/result.json`: DbgMode is absent. The new
contract requires original Probe exception text, ExceptionProbe function,
source link FL:Console.HC,1, visible state inspection, G-driven unwind and
shell recovery without executing the statement after throw.

Compiler input now has a typed, optional inspection callback invoked after its
catch returns and before its control is unwound. It saves/restores the original
exception frame pointer and caller trace around nested inspection. Callback
failure still reaches cleanup and reports an inspection diagnostic. The console
uses this hook when DbgMode is enabled, resolving a live executable allocation
and its canonical source link. Compiler/allocation errors and keyboard Break
are excluded from this first inspection path. DbgMode/IsDbgMode use the original
SEMA_DBG_MODE bit and setter returns the previous value. The retained module
updates that bit under the existing single-CPU IRQ guard; an initial cross-build
failed on undeclared LBEqu and is retained as a build failure, not a behavioral
red. Interfaces advance to compiler 59 and console 35.

Both original rebuild generations and the corrected cross-build/386 boot audit
pass. Image `build/i386-debug-exception-kernel-fixed/kernel.img`, SHA-256
e815c2160ae42d17108e2f74aa87c02e48c6e64eecfe7d5b8f823df7a5124fed.
Exception inspection and explicit-session regression checks are now running in
`build/i386-debug-exception-green` and `build/i386-debug-exception-explicit`.
Their runtime results are pending. Saved hardware registers, exact instruction
line mapping, zero-valued exception display, stepping/breakpoints and nested
resource/error paths remain unqualified; this does not close debugging or M7.

The earlier memory-16 focused-keyboard native pipeline now passes retained
build, installation, guest flat-kernel build and independent 8 MiB boot:
`build/i386-public-keyboard-focused-break-selfhost/result.json`. It uses all
six guest-built retained and all six guest-built flat modules, 16 MiB build RAM,
486,-fpu, and preserves its source. Target SHA-256:
a0e6763b903c230514d8b40b035e3a1abfd06c3127ceb6ddb84ce131b0b055ac.
The independent audit in
`build/i386-public-keyboard-focused-break-selfhost-audit/result.json` passes
all twelve executable module ranges, linked image, installed boot payload and
filesystem checks. The 487344-byte linked kernel leaves 80 bytes within the
487424-byte limit; further flat-kernel growth must be measured. This is one
qualified earlier epoch, not two current-source generations or release proof.
Current-source terminal/debugger integration, native generations and release
qualification remain open.

### Canonical exception source-link oracle and current native rebuild

The console-35 explicit-session regression passes in
`build/i386-debug-exception-explicit/result.json`: seven commands, exact VGA,
56.10-second startup, 8 MiB, 486,-fpu, unchanged source image.
The initial exception run reaches its debugger display but fails the expected
source-link row. Its preserved screenshot shows canonical
`FL:C:/Console.HC,1`; the fixture had incorrectly assumed a relative path.
Corrected the independent expected row to that canonical form without changing
kernel behavior. The revised frozen checker SHA-256 is
94bca5f0f13c21a37a2795f8a814cb6d660e56f010ddb3cf7a590f7e9227aade.
Matching baseline and implementation runs are live in
`build/i386-debug-exception-canonical-red` and
`build/i386-debug-exception-canonical-green`; their results remain pending.

Started the six-provider native rebuild for the captured compiler-59,
console-35, memory-17 image in `build/i386-debug-exception-retained`, comparing
against its exact cross-built exports. This is the next current-source native
qualification step; neither the earlier self-hosting pass nor the cross-build
proves these guest outputs before the run completes.

For the next multiple-terminal implementation, the existing source audit finds
that hardware delivery already targets sys_focus_task and queues are public
and task-owned. Console text, planar storage, command input and rendering
ownership are still singleton state. Use original UserCmdLine/UserTaskCont and
WinFocus semantics rather than inventing a separate terminal command model.
Each terminal must own its line buffer, display history and document state,
while HolyC definitions remain in its task symbol scope. Focus changes select
which display is presented, without cancelling another task's work. Required
visible tests must cover two live terminals with separate definitions/history,
background cooperative work, focus switching, document edits and exit/resource
reclamation. Keep display binding correct across compiler/document yields;
switching one global buffer only at command boundaries cannot meet the goal.
The native flat image's measured 80-byte headroom makes any scheduler/private
layout growth a boot-image sizing gate, not an assumption. Runtime exception
inspection, full debugging and the complete release remain open until their
matching behavioral and integration evidence is recorded.

### Runtime exception source inspection red/green

Both revised checker runs are terminal. The baseline fails on absent DbgMode;
`build/i386-debug-exception-canonical-green/result.json` passes all nine
commands with the identical frozen checker. It verifies Probe exception text,
ExceptionProbe function, canonical FL:C:/Console.HC,1 source link, live state
inspection, G-driven unwind, no execution after throw, mode restoration and
subsequent shell arithmetic. Exact VGA checkpoints pass and source remains
unchanged on 8 MiB, 486,-fpu. This qualifies the named exception/source workflow,
not saved registers, stepping/breakpoints, zero exceptions or complete M7.

### Two-terminal visible acceptance contract

Added `tools/test-i386-terminals.py`. It uses original UserCmdLine/WinFocus
interfaces and public Spawn/Exit rather than private queue or scheduler writes.
Two live terminals must display separate named histories, define the same
variable name with different values in independent task scopes, switch focus
and recover the first history/value, exit with visible refocus to the survivor,
then return to the root console. It checks both child-list reclamation and exact
parent public-heap recovery, followed by shell arithmetic. Expected VGA rows are
fixed independently of guest output. This initial contract excludes document
sessions, background compilation, all private resource pools and hotkey routing;
those remain mandatory integration extensions rather than implied passes.

The initial fixture validation rejected a source line over the 255-byte console
limit before boot. It is not a behavioral red. Split the parent wait helper so
all source lines fit (largest 218 bytes), and started the baseline in
`build/i386-terminals-red-v2`. Runtime result is pending. The implementation
must provide task-owned rendering/input state across cooperative yields and
teardown notification before task heaps/symbols are destroyed; keeping a list
of pointers to already freed task buffers cannot satisfy exit/refocus safety.
Existing keyboard delivery already follows the public focus pointer, but this
alone does not prove multiple usable terminals.
The compiler-59/console-35 six-provider native rebuild and memory-17 full
workstation run remain live for their captured images. The complete OS/M7 and
release objective remains open.

### Task-owned terminal implementation — runtime gate pending

The frozen two-terminal checker records a genuine baseline publication failure
in `build/i386-terminals-red-v2/result.json`; UserCmdLine/WinFocus are absent.
Checker SHA-256: 7ae586737c2e44ada32c8497983681988777723fb75d4796a95b2e3cd3980e26.

Console services advance to version 36. Added original public UserCmdLine,
UserTaskCont and WinFocus bindings. Terminal instances own their text surface,
planar storage, document, input-loop stack and keyboard-loss observation.
Renderer accessors select the current task's surface across cooperative yields;
background terminal display/mouse updates cannot overwrite the focused view.
Focus explicitly presents the selected terminal. The existing scheduler cleanup
hook releases/unlinks terminal state before compiler/symbol/heap teardown,
chains an earlier cleanup callback and refocuses a surviving terminal. Child
terminals own a public put_doc; root startup adopts the existing console display.
Keyboard discontinuity now discards pending keyboard messages for registered
terminals and the focused receiver while keeping unrelated jobs, and each
terminal observes the loss independently.

The first cross-build failed on NULL used before its declaration; a subsequent
build rejected structure member selection through the display-return expression.
Corrected the early default to 0 and used pointer member access at affected
renderer sites. Both original rebuild generations and the fresh corrected
cross-build/386 boot audit pass. Image:
`build/i386-terminals-kernel-pointer/kernel.img`, SHA-256
6051ee26f0405f92e4dc2682c9738ce5c30141c68a6a11d4e35156cad0e2f5d0.
The frozen terminal workflow and ordinary keyboard regression are running in
`build/i386-terminals-green` and `build/i386-terminals-keyboard`; runtime
qualification is pending, not inferred from publication or compilation.

This first implementation still needs visible workflow results, document and
background-work integration, hotkey/window-order behavior, failure/kill/resource
coverage and debugger/terminal interactions. Only one debugger session can
currently be active; exiting inside a debugger requires explicit teardown
coverage. UserTaskCont input-layer exception recovery and broader WinFocus
parity need further contracts. The earlier compiler-59/console-35 six-provider
build and memory-17 workstation run remain live on their distinct snapshots.
Current-source native generations and the complete M7/release gates remain open.

### Terminal test pacing and completed regression evidence

The initial terminal run passes separate displays, first-terminal definition
and focus switching, then its unpaced text action overflows the hardware queue.
The retained log records INPUT RESET before the truncated expression; this run
is a failure, not a terminal usability pass. The fixture now acknowledges each
four-character batch against independent expected VGA rows, matching the normal
console runner's input discipline. It retains every isolation, focus, exit and
heap assertion. Frozen checker SHA-256:
0ac80003e40b5a7983b7cfed7872a1745d593ca85f062fd8c4434b4cc6fa6344.
Matching baseline/current runs are live in build/i386-terminals-paced-{red,green}.
The dedicated intentional overflow checker is live in
build/i386-terminals-keyboard-loss; bounded-queue loss behavior remains a
separate required contract.

On the console-36 terminal image, ordinary keyboard behavior passes in
build/i386-terminals-keyboard (57.64-second startup). Explicit debugger and
named-exception regressions pass in build/i386-terminals-debug-session and
build/i386-terminals-debug-exception (59.05 and 59.35 seconds), with exact VGA
and unchanged disks. These focused results do not prove full terminal integration.
The preceding memory-17 registration-fix workstation run is now terminal PASS:
build/i386-public-macro-registration-workstation/result.json, 513 commands,
20 exact-heap-recovery document cycles, 55.56-second startup, 0.315-second
long-document update, 8 MiB and 486,-fpu. Updated the coverage audit's opening
snapshot summary to distinguish these epochs and the completed earlier native
self-hosted image. The full objective remains open.

### Two-terminal workflow green; Ctrl-Alt-N implementation pending runtime gate

The revised frozen terminal checker now records a matching baseline failure and
implementation pass in build/i386-terminals-paced-{red,green}/result.json.
The green run passes 11 parent commands and every child-terminal VGA checkpoint:
independent definitions/history, programmatic focus, exit/refocus, child-list
reclamation, exact parent public-heap recovery and shell arithmetic. It uses
8 MiB, 486,-fpu and an unchanged image, with 58.93-second startup.
The dedicated overflow checker also passes in
build/i386-terminals-keyboard-loss/result.json: exactly one root input reset,
queued CALL survives exactly once, Shift state resets and typing recovers.
Its frozen checker is c3e4e1b5bc9531095a0644d3144b5c68ea2fd339e57d21f7734530765462e201.
These results qualify image 6051ee26f0405f92e4dc2682c9738ce5c30141c68a6a11d4e35156cad0e2f5d0.

Added a separate hardware Ctrl-Alt-N contract in
`tools/test-i386-terminal-hotkeys.py`, SHA-256
f413ce423d6e1c5d237ad6d39f2bb9e4a173cb087a75ba5adce49b5c3591a23a.
The baseline in build/i386-terminal-hotkeys-red/result.json fails at its first
hotkey focus change; the saved screen remains on One with its definition intact.
The fixture requires visible One/Two/root cycling, independent histories and
values, exit/refocus and heap recovery. The runner now supports a focus-next
hardware chord alongside its existing break chord.

The keyboard worker handles Ctrl-Alt-N outside IRQ context, cycles eligible live
terminal records, consumes the N make/release pair and latches until release to
avoid repeated cycling while held. Keyboard discontinuity clears that latch.
Public service layout remains console 36. Both original rebuild generations,
fresh cross-build and 386 boot audit pass. Image
build/i386-terminal-hotkeys-kernel/kernel.img, SHA-256
444bfb1b7ee9de7e0ac6e4b609b2fd066798c649a9baec47a989165e81657229.
Hotkey behavior and ordinary keyboard regression are running in
build/i386-terminal-hotkeys-{green,keyboard}; no runtime pass is claimed yet.
Repeated-key, inhibited-window, creation-hotkey, document/background-work,
private-resource and debugger/terminal combinations need further coverage.
Current-source native generations, complete M7 and release qualification remain
open; the older console-35 six-provider native build remains live.

### Ctrl-Alt-N green; concurrent editor identity regression

The frozen hotkey checker now passes in
`build/i386-terminal-hotkeys-green/result.json`: 11 parent commands, exact VGA
at every child checkpoint, independent definitions/history, One/Two/root
cycling, exit/refocus and parent public-heap recovery. Startup is 57.54 seconds
on 8 MiB with 486,-fpu. Ordinary keyboard regression also passes in
`build/i386-terminal-hotkeys-keyboard` (59.69 seconds). Both use unchanged
image 444bfb1b7ee9de7e0ac6e4b609b2fd066798c649a9baec47a989165e81657229.

Added `tools/test-i386-terminal-documents.py`: two live text DolDoc editors,
hardware focus cycling, distinct edits and saves, editor exit to the named
terminal, task exit/refocus, parent heap recovery and independently checked
persisted file bytes. It writes only a dedicated copy of the source image.
The baseline `build/i386-terminal-documents-red/result.json` fails at
`one-console-title`: the saved VGA screen shows the generic console heading
after Escape, losing `Task: One`. Earlier checkpoints pass, including saving
both documents, restoring One's editor and saving its revised text. This is
partial baseline evidence, not a passing full document workflow.

A shared `NativeTerminalConsoleHeading` now supplies the initial child console
and document-editor restoration headings. Root consoles retain their existing
heading. Original rebuild, fresh cross-build and the frozen document contract
will qualify this change; no runtime pass is claimed yet. Sprite/mouse sessions,
abnormal terminal cleanup, background compilation, complete debugger behavior,
current-source native generations and release qualification remain open.

Both original rebuild generations, the fresh i386 cross-build and 386 boot audit
pass for the heading fix. Candidate `build/i386-terminal-documents-kernel/kernel.img`
has SHA-256 `58ab899923d48879c927e24be06c986436fb1ed4da04a9918ba5219c83dd060e` (483360 flat kernel bytes).
The unchanged document checker and existing root document-editing regression are
running in `build/i386-terminal-documents-green` and
`build/i386-terminal-documents-editing`; runtime qualification remains pending.

### Concurrent text editors pass; idle terminal break contract

The frozen `test-i386-terminal-documents.py` passes in
`build/i386-terminal-documents-green/result.json` against image
58ab899923d48879c927e24be06c986436fb1ed4da04a9918ba5219c83dd060e.
All VGA checkpoints pass on 8 MiB with 486,-fpu, startup 57.34 seconds and
11 parent commands. Both named terminal headings survive editor exit; focus
returns to the surviving editor and then root. Exact parent public-heap recovery
and shell arithmetic pass. Independently read saved files are `/One.DD` =
`6f6e652105` and `/Two.DD` = `74776f3f05` (one! and two? plus cursor byte).
The source disk is unchanged. The original baseline fails at the first restored
terminal heading with the same checker hash. Root document-editing regression
continues in `build/i386-terminal-documents-editing`.

Added `tools/test-i386-terminal-idle-break.py`, frozen SHA-256
2c454f385cbb95b8cfd2de281114e35b5d74ca319598e36e372a075496e5c6b9.
It sends hardware Ctrl-Alt-C while One is idle after defining a variable, then
requires a usable prompt, the retained value, sibling isolation and ordinary
focus/exit/heap recovery. Baseline is running in
`build/i386-terminal-idle-break-red`; no result is claimed yet. The original
`Kernel/KTask.HC` UserTaskCont catches and reports exceptions before continuing
the input loop. The native wrapper currently propagates the idle-loop exception;
this is the next behavioral gap to verify and repair.

This does not close sprite/mouse concurrency, background compilation, abnormal
cleanup, full debugging, current-source native reproducibility or release gates.
The older console-35 provider build remains live in
`build/i386-debug-exception-retained` and cannot qualify the terminal changes.

### Idle terminal Break reaches an unhandled exception; recovery implementation

The initial idle-break baseline is terminal FAIL in
`build/i386-terminal-idle-break-red/result.json`. After One defines its variable,
the hardware chord logs `THROW 0000006B61657242`, `UNHANDLED` and
`FAIL native kernel`. The failure is an actual unhandled Break, not merely a
prompt mismatch. The original UserTaskCont catches/reports and resumes.

NativeUserTaskCont now catches the input-loop exception, marks it handled,
reports it and resumes with the same terminal/task/definitions. The reentry
guard stays set through recovery and clears only on normal loop completion.
Both original rebuild generations pass; a fresh cross-build is running.

The initial checker over-specified the order of IRQ Break and decoded ^C text.
Revised frozen checker SHA-256
6809b4786a85ea9a3f5d27b5e7ad811eb8593e6af1a03c3db28e6cb5d35e6051
requires two breaks and a real editor session after each, then independently
checks the retained variable, sibling isolation, focus/exit and parent public
heap recovery. It does not require a particular incidental cancellation-message
order. The revised baseline runs against the unchanged heading-fix image in
`build/i386-terminal-idle-break-editor-red`; no result is claimed yet.
The same checker will run on the recovery candidate. Full debugging, private
resource failure paths, current native generations and release remain open.

The recovery candidate now passes the fresh cross-build and 386 boot audit
(483360 flat kernel bytes), in addition to the original two-generation rebuild.
`build/i386-terminal-idle-break-kernel/kernel.img` SHA-256:
`a9a664ae3111a362526057187d1d47bde9e82ef0bb42503abf752d870438a5f8`. Revised paired baseline/candidate checks are
live in `build/i386-terminal-idle-break-editor-{red,green}`; no runtime pass
is claimed. The unchanged heading-fix image's document-editing regression and
the older console-35 native-provider build also remain live.

### Idle terminal recovery green; background compiler/editor workflow

The revised frozen checker 6809b4786a85ea9a3f5d27b5e7ad811eb8593e6af1a03c3db28e6cb5d35e6051
now has paired evidence in `build/i386-terminal-idle-break-editor-{red,green}`.
The baseline again hits unhandled Break/kernel failure. The candidate passes
both idle breaks, a visible editor session after each, retained definitions,
sibling isolation, focus/exit and exact parent public-heap recovery. All VGA
checkpoints pass: 11 parent commands, 8 MiB, 486,-fpu, 58.73-second startup.
Its unchanged image SHA-256 is
a9a664ae3111a362526057187d1d47bde9e82ef0bb42503abf752d870438a5f8.
Existing `breaks` regression is running in
`build/i386-terminal-idle-break-regression`.

Added `tools/test-i386-terminal-background.py`, SHA-256 `7395f7f3e3a36667919ff1abd959a636576cb7e95a053ffd28c56c5efc472592`.
One repeatedly compiles/executes a HolyC document while Two opens, edits and
saves another. The oracle requires the compilation count to advance across
that editor session, the compiled assignment to produce 42, independent VGA
checks, exact saved Work.DD bytes, and terminal/parent-heap cleanup. It does not
prove concurrent full-OS builds. The corrected fixture runs in
`build/i386-terminal-background-session`; no result is claimed yet. An initial
setup attempt was deliberately stopped during boot after finding it referenced
unpublished DocPrint; it is not behavioral red evidence. The current setup uses
existing DocPutKey and names the executable document Background.HC.

The heading-fix root document-editing regression and older console-35 native
provider build are still running. Current-source native generations, complete
debugging and release qualification remain open.

### Interrupt regression passes; forced terminal cleanup contract

`build/i386-terminal-idle-break-regression/result.json` passes all 16 existing
interrupt commands on unchanged recovery image
a9a664ae3111a362526057187d1d47bde9e82ef0bb42503abf752d870438a5f8.
All VGA checkpoints match on 8 MiB with 486,-fpu; startup is 57.88 seconds.
This extends the focused idle-break evidence to existing active execution
interrupt cases. It does not prove every wait or debugger cancellation path.

Added `tools/test-i386-terminal-kill.py`, SHA-256
35bb0e3e829e26615cbfca9c139c8a5c62a9d6a7f053cb5ae0a59925810cca8f.
One opens a text DolDoc and leaves unsaved changes; Two calls public Kill on
One, verifies child-list removal, then opens/edits/saves its own document and
exits. The oracle requires exact VGA, parent public-heap recovery, continued
shell use and independently read Survivor.DD bytes (`ok` plus cursor byte 0x05).
The baseline is running in `build/i386-terminal-kill-baseline`; no result is
claimed. This targets forced exit while an editor is active; exhaustive private
resource accounting, sprite/mouse and debugger cancellation remain open.

Background fixture 7395f7f3e3a36667919ff1abd959a636576cb7e95a053ffd28c56c5efc472592
passes in `build/i386-terminal-background-session/result.json`: 14 parent
commands, 58.14-second startup, exact VGA and saved Work.DD bytes 776f726b05.
The original image is unchanged. Its count spans document creation and editor
use, so this result alone does not prove a compilation completed while the
editor was actually open. The strengthened checker `9639f89b195407e6fe8167356455eedda056b0a43299f426b53f566ad047c96d`
marks completed compilations after the editor's visible-open checkpoint and
requires a newer completion before leaving the saved editor. It is running in
`build/i386-terminal-background-live-session`; this stricter gate remains open.

The initial forced-terminal-exit test fails during TermKill helper definition
with `Invalid lval`, before any editor is killed. Current public source does not
publish Kill, so this is not evidence of an editor cleanup failure. Revised
checker `c849ea2bb51c8edb9f2b5de99b1580afb9adf7d46709ba891cf71b70080fa15a` adds an explicit Kill-publication assertion
before that helper. It is running in
`build/i386-terminal-kill-publication-red`. Resolve the public API gap before
claiming the forced-exit workflow is covered.

The root document-editing regression is now terminal PASS in
`build/i386-terminal-documents-editing/result.json`: 169 commands, exact VGA,
8 MiB, 486,-fpu and 57.34-second startup on heading-fix image 58ab8999.

The console-35 native-provider build is also terminal PASS in
`build/i386-debug-exception-retained/result.json`: all six retained modules
were built in the guest. Source disk SHA-256:
62e9f5e2d8069fd30d16525f03f6350d22919e0d7600f5f7fc17964bac09c0d5.
Installation and independent boot are now running in
`build/i386-debug-exception-retained-install`, preserving that source. This
epoch includes compiler-59/memory-17 named exception support, but predates
console-36 terminals. Current-source native reproducibility remains open.

### Publish public Kill through the retained task provider

The explicit publication baseline fails in
`build/i386-terminal-kill-publication-red`: Kill is absent before the forced
editor cleanup workflow can run. The existing original cancellation contract
passes all nine cases in `build/i386-terminal-kill-original/result.json`, checker
0732d2ff19d4a1a795bca70a65c8104982b96504592a292c5e29e4474453cb4b.

Added MemoryKill in Kernel/I386/TaskKill.HC and public _KILL binding. Memory
services advance to version 18 with 43 bindings; the three data bindings retain
their data kind, while Kill is a function. Normal requests set the existing
termination flag; the scheduler/Exit retain responsibility for callback recovery,
children and cleanup. Asynchronous requests preserve wake/suspend flags. The
just_break branch preserves the original caller-Break/Shift-Esc distinction and
requests a deferred focused break for self. Self-break and I/O cancellation
remain explicitly unqualified by the existing nine-case contract.

Both original rebuild generations pass. Fresh i386 build is running in
`build/i386-terminal-kill-kernel`; runtime public cancellation and forced-editor
cleanup must pass before this API is considered qualified.

The console-35 six-provider installation and independent boot now pass in
`build/i386-debug-exception-retained-install/result.json`, installed disk SHA-256
a3c127614021dcbf06f9e1c7818fabafa51b62be4d2e0e13da1f71c98b00ac91.
All installed module bytes match their guest-built inputs and source is unchanged.
The full guest flat build/install is running in `build/i386-debug-exception-selfhost`.
This epoch predates terminals and memory-18 Kill; current-source native release
qualification remains open.

The strengthened background checker now passes in
`build/i386-terminal-background-live-session/result.json`, SHA-256
9639f89b195407e6fe8167356455eedda056b0a43299f426b53f566ad047c96d.
A completion is observed between the visible editor-open checkpoint and editor
exit. All VGA checks, compiled value, persisted Work.DD bytes and parent heap
recovery pass: 14 parent commands, 8 MiB, 486,-fpu, 56.00-second startup and
unchanged recovery image a9a664ae. This is concurrent document compilation, not
a complete background OS rebuild.

Memory-18 Kill candidate builds and passes the 386 boot audit, with unchanged
483360-byte cross-built flat kernel size. Image
`build/i386-terminal-kill-kernel/kernel.img` SHA-256 `201cb474230f705e00e8cef8d84bb42966e0b9710272456811a0c2e652b981e0`.
The nine-case public cancellation corpus and forced-editor cleanup workflow are
running in `build/i386-terminal-kill-public` and `build/i386-terminal-kill-green`.
No native cancellation runtime pass is claimed yet.

### Forced editor exit green; debugger lifetime and character-code fixes

The frozen forced-editor checker c849ea2bb51c8edb9f2b5de99b1580afb9adf7d46709ba891cf71b70080fa15a
passes in `build/i386-terminal-kill-green/result.json`, against unchanged
memory-18 image 201cb474230f705e00e8cef8d84bb42966e0b9710272456811a0c2e652b981e0.
It verifies killed-child removal, surviving editor/save, exact Survivor.DD bytes
6f6b05, task exit and exact parent public-heap recovery. All VGA checkpoints
pass: 13 parent commands, 8 MiB, 486,-fpu, 56.62-second startup.

The broader public cancellation corpus fails during KillShift definition, before
its behavioral cases: CH_SHIFT_ESC is not published. PublicKernel.HH now includes
the original shared CharCodes.HH; MemoryKill uses that same named constant. The
unchanged corpus must be rerun. A build guard correctly rejected the stale
original-rebuild snapshot after this header edit; the rebuild is being refreshed.

Added `tools/test-i386-terminal-debug-kill.py`, frozen SHA-256
cc7aea1e4f2b9a08fc153e3f18ea30029bb5c748e7a51b5b20734607de23d76c.
Its baseline in `build/i386-terminal-debug-kill-red` reaches Kill successfully,
then the survivor's Dbg call throws DbgBusy. Forced exit bypassed stack-local
debugger cleanup, leaving global ownership and the saved display allocation.
Debugger sessions now chain the task cleanup hook, release the saved buffer and
clear ownership on forced exit, then run the prior terminal cleanup. Normal
return restores the prior hook. Fresh builds and matching runtime tests are
pending; full debugger functionality and private-resource accounting stay open.

The debugger-cleanup cross-build rejected an initialized local function-pointer
declaration in ConsoleDebugTaskCleanup. The helper now restores and invokes
the task's existing typed cleanup field instead. This preserves callback chaining
without relying on that unsupported declaration form. The fresh original rebuild
is running again; no successful cleanup-candidate build or runtime pass is
claimed yet. Baseline DbgBusy and the forced-editor workflow pass remain valid
evidence for their unchanged memory-18 image.

The corrected cleanup candidate now passes both original rebuild generations,
fresh cross-build and 386 boot audit (483360 cross-built flat bytes). Image
`build/i386-terminal-debug-cleanup-kernel-fixed/kernel.img` SHA-256:
`9812e5d53b8ca91070c4f1f4f6d8b93e166bb45d57805efabfb59a945765ec85`. Unchanged public cancellation corpus, frozen
debugger-kill contract, explicit Dbg/G regression and named-exception regression
are running in `build/i386-terminal-kill-public-chars`,
`build/i386-terminal-debug-kill-green`, and
`build/i386-terminal-debug-cleanup-{session,exception}`. Runtime qualification
remains pending.

The older console-35/memory-17 full guest kernel build/install/boot passes in
`build/i386-debug-exception-selfhost/result.json`: six native flat modules plus
six guest-built retained modules, 16 MiB build and 8 MiB boot with 486,-fpu.
Flat image is 487344 bytes (80 bytes below the boot-area limit), SHA-256
e2cb9667b8fc89a839cc3965fbb18c2df8201f51c52e4cd1fcd5112259b35d3b.
Installed image SHA-256:
9de62eea59e62c6e3ce14934347e563413da8db5ec7f9983ba7395f4a98b6b9a.
Independent installed/executable audit is running in
`build/i386-debug-exception-selfhost-audit`. These results predate terminals,
Kill and debugger cleanup; current-source two-generation qualification remains
open.

Independent console-35 installed-image audit is now PASS in
`build/i386-debug-exception-selfhost-audit/result.json`: all twelve executable
module ranges satisfy the 386 allowlist, boot payload matches the guest-built
flat image and filesystem allocation matches reachable extents. This completes
that older source epoch's single-generation native build/install/audit pipeline.

### Debugger cleanup green; broader qualification and zero exception handling

On unchanged cleanup image
9812e5d53b8ca91070c4f1f4f6d8b93e166bb45d57805efabfb59a945765ec85,
forced-debugger-exit now passes in `build/i386-terminal-debug-kill-green`: 13
commands, 58.17-second startup, all VGA checkpoints and parent heap recovery.
The survivor enters Dbg after the victim is killed, evaluates 42 and G returns.
The explicit Dbg/G and named-exception regressions also pass in
`build/i386-terminal-debug-cleanup-{session,exception}` (7 and 9 commands,
58.31/58.18-second starts). All use 8 MiB, 486,-fpu and unchanged source disks.
The broader public cancellation corpus is still running.

Started full workstation integration and all six native retained-provider builds
for this captured cleanup snapshot in
`build/i386-terminal-debug-cleanup-workstation` and
`build/i386-terminal-debug-cleanup-retained`. Their image and reference exports
remain fixed. They predate the following zero-exception change.

Added `tools/test-i386-debug-zero-exception.py`, frozen SHA-256
5469a779edf6feab6ddf853e54c0dabea68bb01bd12b05a3462b23e2ad3e4f2f.
It throws zero with DbgMode enabled, requires exception/function/source display,
inspects pre-unwind state and G-unwinds back to a usable shell. Baseline is
running in `build/i386-debug-zero-exception-red`. ConsoleDebugSession now takes
an explicit exception/session discriminator rather than using code zero as
absence, and displays `Exception: 0`. The original rebuild is running; no new
build/runtime pass is claimed. The original broader debugger requirements and
current-source two-generation release qualification remain open.

The zero-exception baseline is terminal FAIL: its VGA screen shows an empty
Message, Value 0 and caller name, with no runtime exception/source heading.
Both original rebuild generations, the fresh cross-build and 386 boot audit
pass for the fix. Image `build/i386-debug-zero-kernel/kernel.img` SHA-256
`0a90d205983f37f08cf8b47cd11a963dfeec026695c7e60f95c46e6372778608`. Frozen zero-case green plus named-exception
and explicit-session regressions are running in
`build/i386-debug-zero-{exception-green,named-regression,explicit-regression}`.
No runtime pass is claimed yet.

The public Kill corpus progressed through callback recovery, then stopped at
`KillState->stage=3;`: the native screen prints 3, while the fixture expected no
output. Corrected that expected result and strengthened the original oracle to
check the assignment's value explicitly. Revised checker SHA-256 `bef6aaf3ca4afbd4c5d8baea9c520921781d2f01da9f25d4cd480b406c9ae564`
is running on original and native systems in
`build/i386-terminal-kill-original-value` and `build/i386-terminal-kill-public-value`.
This is a fixture correction, not an OS behavior change; the full native
cancellation corpus remains unqualified until its revised run completes.

The revised original cancellation oracle now passes all nine cases, including
its explicit assignment-value assertion, in
`build/i386-terminal-kill-original-value/result.json`. Checker SHA-256
bef6aaf3ca4afbd4c5d8baea9c520921781d2f01da9f25d4cd480b406c9ae564.
The matching native run, zero-exception regressions, workstation suite and
captured cleanup-snapshot native provider build remain active.

### Cancellation behavior and zero exceptions green; mode-state and timing gates

The revised native public Kill contract passes all 69 commands/nine cases in
`build/i386-terminal-kill-public-value/result.json`, matching the original
checker bef6aaf3ca4afbd4c5d8baea9c520921781d2f01da9f25d4cd480b406c9ae564.
The unchanged cleanup image 9812e5d5 passes exact VGA and includes pre-entry,
running/sleeping/suspended exit, callback recovery, unchanged async flags, caller
Break and Shift-Esc. Self-break and I/O cancellation remain outside this corpus.
Its 62.19-second start exceeds the separate 60-second timing gate.

Zero-exception, named-exception and explicit Dbg regressions all pass on
unchanged zero-case image
0a90d205983f37f08cf8b47cd11a963dfeec026695c7e60f95c46e6372778608 in
`build/i386-debug-zero-{exception-green,named-regression,explicit-regression}`.
They pass 9/9/7 commands and exact VGA, including Exception: 0 and caller/source
on the zero case. Recorded starts are 64.93/64.92/72.05 seconds.
`build/i386-debug-zero-startup-budget.json` explicitly fails the zero-case
measurement by 4.93 seconds. Functional pass does not qualify startup timing;
the cause of these slower starts has not been established.

Original Fault2 enables DbgMode during a debugger session and restores its
previous state. The native session had not done so. Added normal mode-state
contract `tools/test-i386-debug-mode.py` (e64985d4d1e3a204521cab401301924fb76540255a1011f54877e3142b523104),
checking active mode and restoration of prior false and true values; baseline
runs in `build/i386-debug-mode-red`. Added forced-exit mode regression
`tools/test-i386-debug-mode-kill.py` (5404ba531016e0023dcc3562a5bc69a6cb226c86d80004d50809715f8552fe68),
requiring false mode after killing a debugger task and using a survivor.
Native sessions now save/enable mode and restore it on normal return or chained
forced cleanup. Fresh original rebuild is running; runtime proof remains pending.
Full workstation and native-provider builds remain live on the immutable cleanup
snapshot, predating zero/mode changes. Complete current-source qualification
including timing, full debugger features and two generations remains open.

Mode-state baseline is terminal FAIL: VGA explicitly shows IsDbgMode returning
0 at the debugger prompt. The mode-state implementation passes both original
rebuild generations, fresh cross-build and the 386 boot audit, with 483360 flat
bytes. Candidate `build/i386-debug-mode-kernel/kernel.img` SHA-256:
`3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`. Normal false/true restoration and forced-exit
restoration tests are running in `build/i386-debug-mode-green` and
`build/i386-debug-mode-kill-green`; no runtime pass is claimed yet.

### Debugger mode verified; workstation collision and boot profile

Both mode-state checks pass on unchanged image
`3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`:
`build/i386-debug-mode-green/result.json` (13 commands) and
`build/i386-debug-mode-kill-green/result.json` (14 commands). Exact VGA verifies
active mode, normal restoration of prior false/true mode, and forced-exit
restoration with a surviving debugger task and parent public heap recovery.
No-FPU TCG, 8 MiB starts are 59.439 and 59.375 seconds.
`build/i386-debug-mode-startup-budget.json` passes for the first observation.
This does not supersede the earlier 62–72-second failures or establish
fully guest-built timing/reproducible release qualification.

`build/i386-debug-mode-boot-profile/result.json` records 608 statistical PC
samples on the same unchanged image. Heap allocation/free/size/validation
account for 146/166 public-header samples and 364/389 startup-source samples.
Caller stacks often involve identifier publication. The profiler pauses QEMU;
its duration is not a startup benchmark. Any optimization must preserve full
heap validation, exact string allocation sizes and atomic failure behavior.

The cleanup-snapshot full workstation run is terminal FAIL at compiler
command-105 (`build/i386-terminal-debug-cleanup-workstation/checkpoint.json`).
Its fixture declares `I64 G()` despite the now-public debugger `U0 G(...)`;
VGA shows Compilation failed. This run is not a full-suite pass. A focused
`tools/test-i386-forward-call.py` retains the forward declaration, call and
unresolved-extern recovery assertions with distinct ForwardValue/ForwardCaller
names and checks that public G remains present. Runtime verification is pending.
The shared workstation runner remains unchanged while the earlier native
provider build is live; update the colliding fixture before the next full run.

The focused forward-call check now passes all six commands with exact VGA on
unchanged mode image 3354b498. Evidence: `build/i386-forward-call-green/result.json`;
checker SHA-256 `1f2e0b7b47ef8057a5fb33fd7a0d42e17ee1969eb03456cb69498b180e7889cb`.
This verifies the distinct-name fixture without weakening forward-resolution
or failed-compilation recovery checks; it does not qualify the full suite.

### Both heap validators covered before startup optimization

Added `tools/test-i386.py --heap --heap-source`: it uses the existing heap
corpus with I386_HEAP_SOURCE_BUILD enabled, in a separate output directory.
The default --heap still tests the 386 assembly validator. Results explicitly
identify the selected validator. This cross-compiles the portable implementation;
it does not replace native self-hosted generation qualification.

Strengthened `tests/guest/i386-heap/Validation.HC`: for every invalid mutation
in the existing 160-case header/control matrix, size lookup, allocation,
zero-sized allocation and free must reject it without changing either the
arena or heap control record. Corruption after a valid early allocation is
included. The independent pre-optimization validator remains the oracle.
Both variants pass runtime and instruction audit in
`build/i386-heap-test/result.json` and `build/i386-heap-source-test/result.json`.
Validation fixture SHA-256: `ff2a93a30288f3ce23d23306e45e90a337250ff09f0f5868c5e4bafe2f746c36`.
No allocator optimization is claimed yet.

The full workstation fixture now uses ForwardValue/ForwardCaller instead of
redeclaring debugger G, preserving both forward-call and failed-compilation
recovery assertions. The focused six-command test already passed. The full
suite is running on mode image 3354b498 in `build/i386-debug-mode-workstation`;
no full-suite pass is claimed. The older cleanup-snapshot native provider build
continues with its already-loaded runner and immutable source/reference images;
changing the inactive workstation command list does not change that execution.

### Portable size lookup: one complete scan

The heap profile motivates eliminating the second block-chain traversal from
portable I386HeapSize. I386HeapScan now records an exact used-payload match
while validating the entire physical chain, then checks aggregate counters
before returning the requested byte count. I386HeapValid uses the same scan
without a lookup. No cached metadata, block/control layout changes, or weaker
corruption checks are introduced; the assembly branch is unchanged.

The existing allocator/ownership corpus and strengthened 160-mutation matrix
must pass in both portable and assembly variants. Current-source rebuild and
runtime checks are underway. Native compilation, flat-kernel size (the earlier
native image had only 80 bytes spare), and end-to-end startup measurements are
required before treating this as a verified performance improvement. The extra
lookup comparison in validity-only scans may offset the saved lookup traversal;
measure the complete workload before deciding whether to retain this design.

The scan implementation now passes both original rebuild generations and both
heap variants (`build/i386-heap-{source-test,test}/result.json`), including the
strengthened corruption rejection and public heap lifetime/churn corpus.
Cross-compiling the portable test produces 176416 bytes versus 176680 before
this change; this isolated test size is not the native boot-image size.
Fresh cross-build output is `build/i386-heap-scan-kernel`. Native flat build,
boot-area fit and performance qualification remain pending.

Fresh cross-build and 386 boot audit pass. Image SHA-256: `38fbbde26954101563a481fc2655157d7459dc7c40c06c3bd611318ba1c94bbd`.
A development native flat build is running in `build/i386-heap-scan-flat`,
using verified cross-built retained modules (`--cross-retained`). This run
will test guest compilation, boot-area fit and independent boot; it is not
full native-provider or two-generation self-hosting qualification.

### Portable heap scan: native build and installed-image audit pass

`build/i386-heap-scan-flat/result.json` passes: the guest compiler built all
six flat modules, assembled/installed them and booted the result independently
with 8 MiB and no FPU. The flat image is 487344 bytes (80 bytes spare), SHA-256
`31b085b97abae02e19df4f1506819f6fcb68a716b2ffb26db20e620baa2f4e69`.
Target disk SHA-256:
`ed51468756aac925962e33f885ce3534ae615c1957c8998d78caa682e595d142`.
The six retained providers remain verified cross-built development inputs;
this is not a fully guest-built generation.

`build/i386-heap-scan-flat-cross-retained-audit/result.json` passes all twelve
module executable ranges, boot ranges, installed-payload comparison and RedSea
reachable-extent/bitmap checks. The first audit invocation incorrectly selected
--guest-compiler-template and rejected the cross-built compiler layout; rerunning
with the correct default layout passes without changing the image or auditor.
The KVM boot measurement is not TCG budget evidence. A normal 8 MiB no-FPU TCG
keyboard/startup check is running in `build/i386-heap-scan-flat-keyboard`.

The normal no-FPU TCG keyboard check now passes exact VGA on unchanged target
ed514687, with a 56.21559963794425-second startup.
`build/i386-heap-scan-flat-startup-budget.json` passes the unchanged 60-second
budget. This qualifies this development-image observation, not a fully
guest-built release or a controlled before/after performance improvement.
The earlier over-budget observations remain valid for their recorded images.

### Current-source retained-provider qualification started

The guest-built flat image ed514687 now seeds the current-source six-provider
build in `build/i386-heap-scan-retained`. It uses the matching cross-built
export contracts in `build/i386-heap-scan-kernel/exports`, no-FPU QEMU/KVM and
16 MiB build memory. This is a separate source epoch from the still-running
cleanup-snapshot provider build; neither run is restarted or its inputs edited.

After a provider PASS, install those exact persisted modules with
`test-i386-retained-install.py`, boot the installed candidate, and run
`test-i386-selfhost-install.py` without --cross-retained. Audit the resulting
fully guest-built image using --guest-compiler-template, then measure TCG
startup/workstation behavior. A second native generation with installed-module
comparison is still required; starting this run does not satisfy that gate.

### Next TDD contract: public User terminal creation

Added `tools/test-i386-user-create.py` with a shared original/native contract:
empty terminal creation, formatted startup text executed in the created task,
Adam child-list membership, synchronous Kill removal and continued root use.
The corrected original x64 oracle passes in
`build/i386-user-create-original-fixed/result.json`. Checker SHA-256:
`521478343b9e2c2dcde494d5265c95d5ca48a31e81f38102467c73c85e10d71e`.

The first fixture wrongly assumed caller-owned children and inherited caller
symbols; original User uses Spawn with the default Adam parent. It also needs
a newline in the submitted text to execute it. The frozen contract now checks
Adam membership and uses formatted addresses to observe the child result and
identity. These are oracle corrections, not requested behavior changes.

The initial native baseline fails the publication assertion: User is absent
on unchanged development image ed514687. The corrected checker is running in
`build/i386-user-create-red-fixed`; no native behavior pass is claimed.
Implementation must preserve the full User(fmt, ...) API and default ownership.
Ctrl-Alt-T creation and visible terminal editing/focus remain separate follow-up
checks; passing the publication probe alone will not satisfy terminal creation.

### User dependency: original-backed formatted strings

The corrected User baseline is terminal FAIL at the publication assertion in
`build/i386-user-create-red-fixed/result.json`: User is absent on unchanged
ed514687. The original behavior contract passes. Implementation tracing found
that User requires formatted string generation and XTalk input delivery, neither
currently exposed by the native public API. Do not replace the full variadic
API with a fixture-specific formatter.

Added `tools/test-i386-format-strings.py`: 17 shared cases cover literals,
percent escaping, signed/unsigned/hex/binary, characters/strings, width,
zero-padding, dynamic width, precision, float output and mixed variadic values.
Allocated results are compared and freed. The original x64 oracle passes in
`build/i386-format-original-fixed/result.json`; checker SHA-256
`51a85c43b4b2f71eb5df828fadbda6d19fddcc93f63fc13a8cad117975a55b3f`.
These are selected cases, not complete TempleOS format-language coverage.

Observed original semantics correct three initial printf-based expectations:
%-5d with 42 gives three leading spaces and 42; %.3s leaves HolyC untruncated;
%f with 1.5 yields 2 unless a decimal precision is supplied. Those outputs are
now frozen in the oracle. Native baseline is running in `build/i386-format-red`.
Next implementation work must preserve original formatting and task ownership,
then provide User and hardware creation workflows; no implementation pass is
claimed by adding these tests.

### Shared original formatting core extracted

Moved the original string-building functions into `Kernel/StrPrintCore.HC`
and formatting flags into `Kernel/StrPrintTypes.HH`. `Kernel/StrPrint.HC`
includes the core and retains Print/PrintErr/PrintWarn console wrappers.
The moved function bodies were verified byte-for-byte against the preceding
revision, preserving Latin-1 characters. Both original rebuild generations
and all 17 original formatting cases pass in
`build/i386-format-core-original/result.json`. Fresh cross-build is running
in `build/i386-format-core-kernel`; no native formatting implementation pass
is claimed.

The native formatting baseline is terminal FAIL at missing MStrPrint in
`build/i386-format-red/result.json` (unchanged ed514687). Reusing the core
requires native address/function-segment formatting, IsRaw state and the
existing allocation, software math, date, file and DolDoc services. Preserve
those format families rather than limiting implementation to the current
17-case corpus. User/XTalk and hardware creation remain subsequent work.
The provider/workstation runs keep their captured pre-extraction images.

### Cleanup-snapshot native providers pass

`build/i386-terminal-debug-cleanup-retained/result.json` passes all six
persisted guest-built providers against the matching export contracts.
Source disk SHA-256:
`33fc78cf811e3d147578f06a3d367c7f99c8615b2d249d4dee250285a89567ee`.
Module sizes: Startup 407, MemoryRuntime 300832, FileRuntime 302036,
ConsoleRuntime 960074, CompilerProbe 1231080, CompilerRuntime 1738306 bytes.
This snapshot includes terminals, Kill and debugger task cleanup; it predates
zero-exception/mode restoration, the portable heap scan and formatter extraction.

Installation and independent boot are running in
`build/i386-terminal-debug-cleanup-retained-install` on a copy of the preserved
source. A full flat rebuild and installed-image audit must follow a PASS.
The newer heap-scan provider build and mode-image workstation suite remain
active. Do not combine their source epochs into a current-source release claim.

The cleanup-snapshot installation and independent no-FPU boot now pass in
`build/i386-terminal-debug-cleanup-retained-install/result.json`. All six
installed provider byte sequences match the persisted guest outputs; source
and candidate preservation checks pass. Candidate SHA-256:
`b863d402e0a63b8984575e192272a68c0ed3641648ea6fc58cba4fd1b501c246`.

A full flat-kernel build/install is running from that candidate in
`build/i386-terminal-debug-cleanup-selfhost`, without --cross-retained.
On success, independently audit all twelve module executable ranges and the
installed filesystem, then qualify the fully guest-built image. This still
uses the cleanup snapshot; it cannot certify subsequent mode/heap/formatter
changes or the required second native generation.

### Mode-image complete workstation suite passes

`build/i386-debug-mode-workstation/result.json` passes all 513 native commands
and 576 submitted lines with exact VGA, including 20 document development
cycles with exact task data/code heap recovery. Startup is
58.3255955548957 seconds; long-document input-to-visible-update latency is
0.3174466756172478 seconds. `build/i386-debug-mode-workstation-budget.json`
passes the unchanged 60-second startup gate. The visible-update measurement
also meets the one-second gate; this run does not replace the separate
interrupt-to-recovery latency workflow.

Unchanged image SHA-256:
`3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`.
Runner SHA-256:
`3956a334692d4d9298f49b8cddd515ab0cb1f97a748bc32f78408d6c60101c51`.
The corrected forward-call fixture passes within the complete suite, alongside
compiler/math, window/graphics, keyboard/mouse, document/style/sprite/file
navigation and Help coverage. This image includes terminals, Kill, debugger
cleanup, zero exceptions and mode restoration. It predates portable heap-scan
and formatter extraction and uses cross-built modules. Fully guest-built
current-source two-generation and release qualification remain open.

### Cleanup snapshot: all twelve guest-built modules installed and audited

`build/i386-terminal-debug-cleanup-selfhost/result.json` passes the six-flat
module build, installation and independent 8 MiB no-FPU boot using all six
previously guest-built retained providers. No cross-retained development mode
was used. Flat size is 487344 bytes (80 bytes spare); flat SHA-256
`f4b4b6a5b707f0461c94b1a8abcdb57ec36d81991f04f89640b65636b95b03cc`.
Target disk SHA-256:
`239bacc0433422c21d936d179365f4db95f101f42d7d64087ea01e12bca6611d`.

`build/i386-terminal-debug-cleanup-selfhost-audit/result.json` passes all
twelve executable ranges, installed boot payload, boot instruction audit and
RedSea extent/bitmap checks with the guest-compiler-template layout selected.
Normal no-FPU TCG keyboard/startup verification is running in
`build/i386-terminal-debug-cleanup-selfhost-keyboard`. This is the newest
completed fully guest-built snapshot: compiler 59, memory 18, console 36,
including terminals/Kill/debugger cleanup but predating zero/mode/heap/formatter
changes. Second-generation and current-source release qualification stay open.

### Fully guest-built cleanup snapshot: startup budget fails

The ordinary no-FPU TCG keyboard/exact-VGA check passes on unchanged fully
native target 239bacc0 in
`build/i386-terminal-debug-cleanup-selfhost-keyboard/result.json`.
Its startup is 65.44467783393338 seconds.
`build/i386-terminal-debug-cleanup-selfhost-budget.json` explicitly FAILS the
60-second gate by 5.44467783393338 seconds. Do not promote the functional
pass as startup qualification or infer a proven cause from host concurrency.

The full workstation suite is now running on that fully guest-built target in
`build/i386-terminal-debug-cleanup-selfhost-workstation`. The newer heap-scan
provider build continues independently. Its eventual fully native image needs
its own timing measurement; the prior 56.216-second development result used
cross-built retained modules and cannot settle this gate.

### Heap-scan snapshot: guest-built retained providers pass

`build/i386-heap-scan-retained/result.json` passes compilation of all six
retained modules inside the no-FPU guest, module parsing and reference export
set checks, including the console allocation-wrapper check. Source disk SHA-256:
`d79d32be4350a6e991148d9e2fc87224ed453ad036938df2f79f3d48f78d73bb`.
Guest-built ConsoleRuntime is 960921 bytes, SHA-256
`9d71ebbc01f2e83c6333d7bde8af59b25713f4a9526afdb6f699ec5bdb6899df`.
The checker compares export sets, not binary equality to cross-built modules.

Installation and independent boot verification are running in
`build/i386-heap-scan-retained-install`, using a writable copy of that source.
Next, build/install all six flat modules using these guest-built providers,
audit the installed image, and measure its ordinary no-FPU TCG startup against
the unchanged 60-second gate. The development-image timing does not qualify
this fully native path. This snapshot includes heap-scan and debugger zero/mode
fixes but predates formatter extraction. The older cleanup snapshot's full
workstation suite remains live; neither run proves current-source release
qualification or two native generations.

### Shared formatter extraction: baseline verification complete

The original two-generation rebuild passes after extraction of the unchanged
formatter into `Kernel/StrPrintCore.HC`. All 17 original formatting cases pass
in `build/i386-format-core-original/result.json`. The cross-build and 386 boot
instruction audit pass in `build/i386-format-core-kernel`; its result records
source revision `2470ed94dcea403c6d56e37fd6b08463c9a90406`, a 483360-byte
kernel, and no boot test. These checks establish the refactor baseline only.
Native MStrPrint and User integration, creation hotkeys and their native green
workflow tests remain implementation work.

### Heap-scan snapshot: retained installation and independent boot pass

`build/i386-heap-scan-retained-install/result.json` passes installation of all
six guest-built retained providers, exact installed-byte comparisons and an
independent 8 MiB boot with `486,-fpu` under KVM. The preserved candidate disk
SHA-256 is `b232d79d555c828944558b47b4eaf77b96fef3ab8d66701ee8c185bf09ee16fa`.
Both source and candidate preservation checks pass.

The full native flat build/install is now running in
`build/i386-heap-scan-selfhost` against that candidate, without cross-retained
mode. After it completes, audit the installed executable ranges/filesystem and
measure no-FPU TCG startup. This remains the pre-formatter heap-scan snapshot;
current-source two-generation and release qualification remain open.

### Formatter port: 64-bit boundaries and allocation growth baseline

`tools/test-i386-format-strings.py` now contains 22 cases. The added cases
exercise signed I64 minimum/maximum, unsigned U64 maximum, hexadecimal output
spanning both 32-bit halves, and a 1024-character string that requires output
allocation growth. The growth helper compares every byte and frees both
buffers. All interactive definitions/commands remain below 256 characters.

All 22 cases pass on original TempleOS in
`build/i386-format-boundaries-original/result.json`. Checker SHA-256:
`8a701bcc987f57b91c53b2a4307c11f27b768b7050e5d714cf322e9b06a0be7f`.
The same checker fails on unchanged native development image ed514687 in
`build/i386-format-boundaries-native-red/result.json`: the initial HashFind
returns 0 on the captured VGA screen, so the expected 1 times out. Formatting
cases are not reached. This confirms the missing MStrPrint integration, not a
formatting mismatch; full format-language parity is still outside this corpus.
The native build/install and older cleanup workstation suite remain running.

### Heap-scan snapshot: all twelve guest-built modules and image audit pass

`build/i386-heap-scan-selfhost/result.json` passes the six flat-module guest
build/install with all six guest-built retained providers and independent
8 MiB `486,-fpu` boot (16 MiB build). No cross-retained mode was used. Target
SHA-256: `66819bf5b517d80a937bee1491022eea6988d021c7ad5edbbf64bff61c02e7ba`.
The flat payload is 487344 bytes (80 bytes spare), SHA-256
`f4b4b6a5b707f0461c94b1a8abcdb57ec36d81991f04f89640b65636b95b03cc`.
Its flat bytes match the earlier cleanup snapshot; this is not evidence of a
flat-kernel size or performance improvement from the heap work.

`build/i386-heap-scan-selfhost-audit/result.json` passes the twelve executable
ranges, installed boot payload and boot instruction audit, and filesystem
extent/bitmap checks with the guest compiler template selected. Ordinary
8 MiB no-FPU TCG keyboard/VGA verification is running in
`build/i386-heap-scan-selfhost-keyboard`; evaluate its own startup against the
unchanged 60-second gate. This is now the newest completed fully guest-built
snapshot, including debugger zero/mode fixes and predating formatter extraction.
Current-source two-generation, full workflow and release qualification remain
open. The older cleanup snapshot's workstation suite is still running.

### Fully guest-built heap-scan snapshot: functional boot passes, timing fails

`build/i386-heap-scan-selfhost-keyboard/result.json` passes ordinary keyboard
and exact-VGA checks on target 66819bf5 under 8 MiB `486,-fpu` TCG. Startup is
65.14852777728811 seconds. The unchanged checker explicitly FAILS the 60-second
gate in `build/i386-heap-scan-selfhost-startup-budget.json`, by
5.148527777288109 seconds. Evidence SHA-256:
`22e933ba0b10b538c31c2a2a8c9d260eec5e63de77c182008122accc90c7edfb`.

A QMP instruction-sampling run is now active in
`build/i386-heap-scan-selfhost-profile` on the unchanged fully guest-built image.
Use that image's installed modules for symbol attribution. Its paused elapsed
time is not a benchmark. Earlier cross-built/development timing and profiles
cannot establish the cause of this failure; the portable source heap change
also does not replace the boot kernel's assembly validator. Keep the startup
gate open while identifying the actual native bottleneck. The older cleanup
workstation suite continues through file navigation checks.

### Fully native boot profile identifies the active heap path

`build/i386-heap-scan-selfhost-profile/result.json` completes on unchanged
fully native target 66819bf5, with 656 statistical instruction samples and
installed-module symbol attribution. In the public-header phase, heap
Alloc/Free/Size/Valid account for 140 of 150 samples (52/39/29/20). During
startup source they account for 340 of 367 samples (92/84/79/85). Foundation
has 98 of 139 samples in I386ModuleValid. Profiler SHA-256:
`37f22fb8d7d18978097efc94002c0064fcd096eeb78c83cfc43e4bf43160dc34`.

The next performance change should target the active boot-kernel heap path,
whose assembly validator and subsequent size lookup still traverse separately.
Preserve complete-chain validation, rejection of later corruption, unchanged
arena/control on failure, and exact requested sizes. The portable source scan
alone did not change this path. Any implementation must fit the boot envelope
(current fully native flat image has only 80 spare bytes), pass both heap
variants and the independent corruption oracle, and then be measured on a
new fully native image. Do not interpret paused profile elapsed time as boot
timing or claim a speedup before that measurement. Native formatter/User
integration and the remaining full release requirements remain open.

### Boot-kernel heap size lookup shares the assembly validation scan

`Kernel/I386/Heap.HC` now uses I386HeapScan in both implementations. The
assembly path records a matching used allocation's requested size, continues
through every later block, and returns it only after aggregate validation.
This removes the second physical-chain traversal from I386HeapSize. Invalid,
foreign, freed and interior pointers still return -1; valid zero-size
allocations return 0. NULL remains invalid for size lookup and selects
validation-only behavior inside the shared scan.

The fresh original two-generation rebuild passes
(`build/heap-asm-scan-rebuild.log`). Both `tools/test-i386.py --heap` and
`--heap --heap-source` pass, including the independent corruption oracle and
rejection without arena/control mutation. The cross-build and 386 instruction
audit pass in `build/i386-heap-asm-scan-kernel`: 483088 kernel bytes, 272 fewer
than the preceding 483360-byte cross-build. Cross-build size is not a measured
fully guest-built size or performance improvement.

A guest flat build/install is running in `build/i386-heap-asm-scan-flat`, with
explicit verified cross-retained development inputs. After its audit and boot
checks, rebuild the retained providers in the guest and qualify a fully native
image against the unchanged startup gate. The old 65.149-second timing failure
is not cleared by these component passes. Formatter/User integration and the
remaining full release requirements are still open.

### Fully guest-built cleanup snapshot: complete workstation suite passes

`build/i386-terminal-debug-cleanup-selfhost-workstation/result.json` passes
all 513 native commands, exact VGA at every checkpoint, and 20 document
cycles with exact task data/code heap recovery. This run uses the fully native
cleanup target 239bacc0 and predates debugger zero/mode fixes, portable/assembly
heap-scan changes and formatter extraction. Long-document input-to-visible
latency is 0.2579392488114536 seconds, meeting the one-second gate.

Startup is 64.99476048490033 seconds;
`build/i386-terminal-debug-cleanup-selfhost-workstation-budget.json` FAILS the
60-second gate by 4.9947604849003255 seconds. Evidence SHA-256:
`31b18a438583b12c7b4624a982765717da8c74c276ff8c13a412fe5f4a23173e`.
The full functional pass must not be reported as timing or current-source
release qualification. The optimized assembly-scan guest flat build remains
running; its cross-built image is receiving a separate keyboard/startup check
in `build/i386-heap-asm-scan-cross-keyboard`. That development check cannot
substitute for fully native startup measurement.

### Assembly heap scan: cross-built normal boot meets the startup gate

`build/i386-heap-asm-scan-cross-keyboard/result.json` passes ordinary keyboard
and exact-VGA checks under 8 MiB `486,-fpu` TCG. Startup is
45.82201023912057 seconds; the unchanged 60-second checker passes in
`build/i386-heap-asm-scan-cross-startup-budget.json`. Cross-built disk SHA-256:
`4d57c57f5ee1751997c215f570580af2bb46a905ea40c660c89410c177fab1b0`.
This is evidence for the optimized cross-built snapshot, not a controlled
before/after speed comparison or a fully guest-built timing pass.

The complete workstation regression suite is now running on the same image in
`build/i386-heap-asm-scan-cross-workstation`. The guest flat build in
`build/i386-heap-asm-scan-flat` continues independently. Fully native retained
build/install, installed audit and its own startup measurement still follow;
the preceding native timing failure remains open until qualified replacement
evidence exists. Formatter/User and the broader release requirements remain
unfinished.

### Assembly heap scan: guest flat build, installation and audit pass

`build/i386-heap-asm-scan-flat/result.json` passes all six guest-built flat
modules, installation and independent 8 MiB no-FPU boot. This development run
uses verified cross-built retained providers. Flat size is 487072 bytes,
272 bytes smaller than the preceding native flat payload, leaving 352 bytes
in the boot envelope. Flat SHA-256:
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Target SHA-256:
`d0c5933b92d9a780247202003065216ddda1b10c7943277cbdfcc2837247487a`.

`build/i386-heap-asm-scan-flat-audit/result.json` passes executable ranges,
installed boot payload/boot instructions and filesystem extent/bitmap checks.
The default compiler template is appropriate here because retained providers
are cross-built. Native compilation of all six retained providers is now
running in `build/i386-heap-asm-scan-retained`, using this installed image and
`build/i386-heap-asm-scan-kernel/exports` for export-set checks. After installation,
rebuild the flat modules with those guest-built providers, audit with the guest
compiler template and measure fully native startup. The cross-image workstation
suite continues independently. No fully native timing pass is established yet.

### Assembly heap scan: complete cross-image workstation suite passes

`build/i386-heap-asm-scan-cross-workstation/result.json` passes all 513 native
commands, exact VGA at every checkpoint, and 20 document development cycles
with exact task data/code heap recovery. Startup is 46.07334640296176 seconds;
`build/i386-heap-asm-scan-cross-workstation-budget.json` passes the unchanged
60-second gate. Long-document input-to-visible latency is
0.255388590041548 seconds, meeting the one-second gate. Evidence SHA-256:
`da2f1ccbc3ff012bb202f0f5b7827d96a1f26c2aa6b511d91e962237811e90e8`.

This run qualifies the tested workflows on cross-built image 4d57c57f, with
the combined assembly heap scan. It does not establish fully guest-built
startup or current-source two-generation release qualification. The native
retained-provider build in `build/i386-heap-asm-scan-retained` remains active;
installation, fully native flat rebuild, audit and timing follow its completion.
Native formatter/User integration and the wider release requirements stay open.

### Assembly heap scan: all six retained providers compile natively

`build/i386-heap-asm-scan-retained/result.json` passes guest compilation,
module parsing, export-set checks and the console allocation-wrapper check
for all six retained providers. Source disk SHA-256:
`e809791978764b4258fc0ce0cea1c82041563125b88582ce580411bff6cf9e7d`.
The six output module hashes match the preceding heap-scan provider outputs;
the new optimization resides in the flat boot kernel, not those providers.
This is not yet a second complete native generation or release qualification.

Installation, exact installed-byte checks and independent no-FPU boot are now
running in `build/i386-heap-asm-scan-retained-install` on a writable source
copy. After that passes, rebuild/install the flat modules using these native
providers, audit the complete image with the guest compiler template, and
measure ordinary TCG startup against the unchanged 60-second gate. The source
snapshot includes formatter extraction but still lacks native formatter/User
integration and the other open release requirements.

### Assembly heap scan: native provider installation and boot pass

`build/i386-heap-asm-scan-retained-install/result.json` passes replacement of
all six retained providers, exact installed-byte verification, preserved
source/candidate checks and independent 8 MiB `486,-fpu` boot under KVM.
Candidate SHA-256:
`5bf3336394bb361ed6651b3ecd0f6eae2cbada01bb6f84be218bcd3761e91a18`.

The six flat modules are now rebuilding/installing with these native providers
in `build/i386-heap-asm-scan-selfhost`, without cross-retained development mode.
After completion, audit all twelve executable ranges and installed filesystem
with the guest compiler template, then measure ordinary no-FPU TCG startup.
The cross-image timing pass does not replace that measurement. This snapshot
still lacks native formatter/User integration, and current-source two-generation
and complete release qualification remain open.

### Assembly heap scan: complete native image builds, installs and audits

`build/i386-heap-asm-scan-selfhost/result.json` passes all six guest-built flat
modules using all six guest-built retained providers, installation and independent
8 MiB `486,-fpu` boot (16 MiB build). No cross-retained mode was used.
Flat payload: 487072 bytes, 352 bytes spare, SHA-256
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Target SHA-256:
`9c74ad0a40623d6d383caaf786cdb4f99251080d3b14e0b0b3bc01c59ff0cd5a`.

`build/i386-heap-asm-scan-selfhost-audit/result.json` passes all twelve
executable ranges, installed boot payload and boot instructions, and filesystem
extent/bitmap checks with the guest compiler template selected. Ordinary 8 MiB
no-FPU TCG keyboard/VGA and startup measurement are now running in
`build/i386-heap-asm-scan-selfhost-keyboard`; assess the unchanged 60-second gate
on that result. The 46-second cross-image timing does not substitute for it.
This is the newest completed fully native snapshot. A second complete native
generation, current-image workflows, native formatter/User and full release
qualification remain open.

### Fully native assembly heap scan: normal startup gate passes

`build/i386-heap-asm-scan-selfhost-keyboard/result.json` passes ordinary
keyboard and exact-VGA checks on fully native target 9c74ad0a under 8 MiB
`486,-fpu` TCG. Startup is 53.687440753914416 seconds. The unchanged 60-second
gate passes in `build/i386-heap-asm-scan-selfhost-startup-budget.json`.
Evidence SHA-256:
`0a0d909232de33aa5eeabe57bac7ad377a7d9a29a452bac07441d41edc5fac27`.
This qualifies normal startup on the optimized fully native snapshot; the
older 65-second failures remain historical evidence, not this image's verdict.

The full workstation suite is running in
`build/i386-heap-asm-scan-selfhost-workstation`. A second-generation retained
build is running from the fully native target in
`build/i386-heap-asm-scan-gen2-retained`, with exact comparison against the
installed providers enabled. Continue through native installation, flat-module
rebuild, complete image audit and second-generation workflow checks before
claiming two complete generations. Native formatter/User, broader debugging
and the other full release requirements remain open.

### Fully native assembly heap scan: complete workstation and timing pass

`build/i386-heap-asm-scan-selfhost-workstation/result.json` passes all 513
native commands/576 submitted lines on fully native target 9c74ad0a, with
exact VGA and 20 document cycles with exact task data/code heap recovery.
Startup is 53.786390606779605 seconds; the unchanged 60-second checker passes
in `build/i386-heap-asm-scan-selfhost-workstation-budget.json`. Long-document
input-to-visible latency is 0.2600506618618965 seconds, meeting its one-second
gate. Evidence SHA-256:
`8246e118b853e16070edf2a6248f2b48dd1806c3c276006fcd71c0bacf4f7207`.

The writable three-boot DolDoc save/reboot/reopen/re-execute workflow is now
running in `build/i386-heap-asm-scan-selfhost-doldoc`. The second-generation
retained build continues independently. The workstation pass does not replace
persistence, second-generation, full API/debugger or reproducible-release
qualification; native formatter/User integration remains unfinished.

### Fully native DolDoc persistence and recovery pass across three boots

`build/i386-heap-asm-scan-selfhost-doldoc/result.json` passes on an unchanged
source target 9c74ad0a using a writable candidate: 107 create/edit/save commands,
56 reopen commands and 15 revised-document commands, with exact VGA throughout.
All three 8 MiB no-FPU boot measurements are below 60 seconds:
53.71624059788883, 54.01201851526275 and 53.9515840052627 seconds.
Interrupt-to-recovery VGA latency is 0.2707137567922473 seconds.

Saved programs reopen and execute after reboot; revisions persist across the
third boot. The independent filesystem walker verifies 18 directories,
874 files and 18522 owned sectors, with bitmap matching reachable extents,
including rename/delete, cross-directory move and directory lifecycle checks.
Final writable candidate SHA-256:
`543ecd0856e4c9237fff73e12c5669834b038a254c25c9fb6605dafc154abaf9`.

Actual speaker-output verification is now running on the preserved fully native
source in `build/i386-heap-asm-scan-selfhost-speaker`. The second-generation
retained build continues. These workflow passes do not close native formatter/User,
complete debugger/API support, second-generation or reproducible-release work.

### Fully native speaker waveform and silence verification pass

`build/i386-heap-asm-scan-selfhost-speaker/result.json` passes on target
`9c74ad0a40623d6d383caaf786cdb4f99251080d3b14e0b0b3bc01c59ff0cd5a`
under 8 MiB `486,-fpu` TCG. Independent analysis of 44100 Hz mono PCM
finds stable 440 Hz then 880 Hz tones. Both settled off/reset intervals
emit zero new WAV bytes over at least 1.5 seconds each. All four sound
commands pass exact VGA checks; the source image remains unchanged.
Captured WAV SHA-256:
`5c7dbbbfb54f7fe2b92227e27f90a02227e2c4d7f1fc53e6a6b629002bf51905`.
Checker SHA-256:
`c6a6d41106cac752a742e16871bb0452b10ad15a1189aa58504a6e309532e4f0`.

This verifies emulated speaker output on the current fully native image.
Physical hardware verification remains deferred. The second-generation retained
build is still running with exact installed-provider comparison enabled;
installation, flat rebuild and complete second-generation qualification remain
pending. Native formatter/User, complete debugger/API support and reproducible
release work also remain open.

### Second-generation compiler publication hits contiguous-space exhaustion

The second-generation retained build reaches compiler module publication but
reports `FILE WRITE mutation error` and `BUILD MODULE REJECT` at stage 8,
with compiled size `0x1A8642` (1738306 bytes). No pass is claimed; the harness
is still awaiting its expected success response.

Read-only inspection of `build/i386-heap-asm-scan-gen2-retained/source.img`
finds 6749 free sectors but a largest contiguous run of only 2169 sectors.
The compiler output requires 3396 contiguous sectors. The original native
source target had 12210 free sectors and a largest run of 6451 sectors.
The independent `verify_mutated_volume` walker passes on both images:
source 16 directories/857 files/18501 owned sectors; build candidate
16 directories/862 files/23962 owned sectors, with allocation bitmap matching
reachable extents. The five earlier retained outputs consume the available
large runs before compiler publication. This is a build-space/fragmentation
failure, not evidence of a successful second generation or bitmap corruption.

Next investigate intermediate-file lifetimes and contiguous build workspace
requirements, preserve the failed candidate, and fix the build workflow or
image layout before retrying. Retain exact installed-module comparison and
complete installation/boot/audit checks; do not waive the two-generation gate.

### Retained rebuild schedules larger modules first

The default retained-build workflow now orders independent modules by descending
installed byte size before compiling them. RedSea requires contiguous extents;
writing small outputs first had consumed the runs needed by the final compiler
output. Explicit `--module` order remains unchanged, and successful reports
record `module_order`. Exact module bytes, export checks and installation gates
are unchanged. This mitigates build-output fragmentation; it does not add
filesystem compaction or guarantee success on an arbitrarily fragmented disk.

The failed guest had returned to its prompt after rejecting publication. Its
harness was explicitly interrupted (exit 130) instead of waiting for the
remaining success-response timeout; the failed image is preserved. A fresh run
from the unchanged native target is active in
`build/i386-heap-asm-scan-gen2-largest-first`, with exact installed-module
comparison enabled. Python compilation and diff whitespace checks pass;
guest build success remains unproven until this new run completes.

### Compiler-first retry publishes a byte-identical native compiler

The active `build/i386-heap-asm-scan-gen2-largest-first` run successfully
publishes `RetainedCompilerRuntime.t32m` and advances to `CompilerProbe`.
An independent read of the saved compiler output compares equal, byte for
byte, with the installed first-generation compiler: 1738306 bytes, SHA-256
`c99504863728b790424f1ed6b182f2223cf47fe1a06642113af57b7a3c6abd75`.
The earlier compiler-publication space failure is avoided with this ordering.
The remaining five provider builds, complete comparison, installation and
flat-kernel rebuild are still pending; this is not a complete two-generation pass.

### Second-generation retained providers all match installed native bytes

`build/i386-heap-asm-scan-gen2-largest-first/result.json` passes all six
retained builds, export contracts and console allocation-wrapper checks.
Every generated provider matches its installed first-generation counterpart
byte for byte on native target 9c74ad0a. Build order is CompilerRuntime,
CompilerProbe, ConsoleRuntime, FileRuntime, MemoryRuntime, Startup.
The larger-first schedule avoids the earlier contiguous-space failure on
this source image without changing the outputs or relaxing comparison.

Build candidate SHA-256:
`d7d93fef0589291f7a340ec5f700f939427c3a92deaf49c9a41904a5ce5c02b6`.
The independent filesystem walker passes: 16 directories, 863 files,
27358 owned sectors, allocation bitmap matching reachable extents.
Installation and independent 8 MiB no-FPU boot verification are running in
`build/i386-heap-asm-scan-gen2-largest-first-install`. Native flat rebuild,
complete installed-image audit and second-generation workflows still need
qualification. This provider-level reproducibility pass does not close the
complete two-generation or release requirements.

### Second-generation retained installation and independent boot pass

`build/i386-heap-asm-scan-gen2-largest-first-install/result.json` passes
installation of all six native providers with exact byte preservation and
removal of their build-output paths. An independent writable boot copy runs
`6*7` and `DocAllocationCheck` successfully under 8 MiB `486,-fpu` KVM.
Preserved source and candidate images remain unchanged by that boot test.
Installed candidate SHA-256:
`c516f9595a43f8626b0b4163ad048f483af64b798bb8859bf4998a5d78e8774b`.

The six flat-kernel modules and guest boot image are now rebuilding from this
candidate in `build/i386-heap-asm-scan-gen2-selfhost`, without cross-retained
inputs. Complete installed-image audit, first/second-generation flat-output
comparison and second-generation workflow qualification remain pending.
Native formatter/User, full debugger/API coverage and reproducible release
qualification remain open.

### Second-generation native kernel, exact comparison and image audit pass

`build/i386-heap-asm-scan-gen2-selfhost/result.json` passes all six native
flat-module builds, guest boot-image link/install and independent 8 MiB
`486,-fpu` boot (16 MiB build). All six retained inputs were guest-built.
Target disk SHA-256:
`44ed8c88293ff940fd2c1c73837424c62bd9b4224e4479723a2505aa7c3c5043`.

Direct comparison in `build/i386-heap-asm-scan-gen2-selfhost/comparison.json`
proves all twelve module files and `/Probe/GuestBoot.bin` byte-identical to
the first generation. The flat image is 487072 bytes (352 spare), SHA-256
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Whole disk hashes differ because filesystem allocation/layout differs; this
is executable-output reproducibility, not a reproducible release disk claim.

`build/i386-heap-asm-scan-gen2-selfhost-audit/result.json` passes installed
386 executable/boot-payload/boot-instruction and filesystem checks using the
guest compiler template. The full second-generation workstation suite is
running in `build/i386-heap-asm-scan-gen2-selfhost-workstation`. Startup and
interaction budgets, persistence and audio still need current-generation
qualification. Native formatter/User, full debugger/API support and release
packaging remain open.

### Second-generation complete workstation and timing gates pass

`build/i386-heap-asm-scan-gen2-selfhost-workstation/result.json` passes
513 native commands/576 submitted lines with exact VGA checkpoints on the
second-generation target 44ed8c88 under 8 MiB `486,-fpu` TCG. Twenty bounded
document development cycles recover exact task data/code heap use.
Startup is 54.769869497045875 seconds; the unchanged 60-second gate passes
in `build/i386-heap-asm-scan-gen2-selfhost-workstation-budget.json`.
Long-document input-to-visible latency is 0.3696982068940997 seconds,
meeting the one-second gate. Evidence SHA-256:
`25fe22b771449b43d79f3c44f935b330a4b7684e5791050937749fc2fc1556d8`.

The writable three-boot persistence workflow is running in
`build/i386-heap-asm-scan-gen2-selfhost-doldoc`. Second-generation persistence
and actual speaker-output qualification remain pending. Byte-identical native
executables and these workstation passes do not close native formatter/User,
full debugger/API support or reproducible release packaging.

### Second-generation three-boot DolDoc persistence passes

`build/i386-heap-asm-scan-gen2-selfhost-doldoc/result.json` passes 107
create/edit/save commands, 56 reopen commands and 15 revision checks across
three independent 8 MiB no-FPU boots, with exact VGA throughout. Startup
measurements are 56.57473006192595, 53.96432991186157 and
53.91442803107202 seconds, all below 60 seconds. Interrupt-to-recovery VGA
latency is 0.26818493101745844 seconds.

Saved programs execute after reboot and revisions persist through the third
boot. The independent filesystem walker verifies 18 directories, 874 files,
18522 owned sectors and bitmap equality with reachable extents, including
rename/delete, cross-directory move and directory lifecycle checks. Source
44ed8c88 is unchanged. Final writable candidate SHA-256:
`c9bf56e972295b4eb298ac81c3f8ca477ae9978a9e71fdba32761114eb36549b`.

Actual speaker-output verification is running in
`build/i386-heap-asm-scan-gen2-selfhost-speaker`. Native formatter/User,
complete debugger/API support and reproducible release packaging remain open.

### Second-generation speaker output passes; two native generations qualified for existing workflows

`build/i386-heap-asm-scan-gen2-selfhost-speaker/result.json` passes on
unchanged target 44ed8c88 under 8 MiB `486,-fpu` TCG. Independent 44100 Hz
PCM analysis observes stable 440 Hz then 880 Hz tones. Settled off/reset
intervals each emit zero new WAV bytes over at least 1.5 seconds; all four
sound commands also pass exact VGA. Startup is 53.91643884219229 seconds.
Captured WAV SHA-256:
`53e42268f35d41ef9b3f5fa84f826bef07f800ede20304d30596058f9063fd03`.
Checker SHA-256:
`c6a6d41106cac752a742e16871bb0452b10ad15a1189aa58504a6e309532e4f0`.

Both native generations now pass the existing workstation, startup/latency,
three-boot persistence and actual emulated-audio workflows. All twelve native
modules and the linked boot image are byte-identical between generations;
whole disk layouts differ. This completes the current snapshot's two-generation
workflow verification, not the full OS objective. Native original formatter
and User/task-creation integration, full debugger/API behavior and reproducible
release disk/environment/packaging work remain required. Physical hardware
verification stays deferred. Next resume native formatter integration against
the original-HolyC oracle and existing failing native tests.

### Original formatter oracle adds TempleOS-specific semantics

`tools/test-i386-format-strings.py` now checks 30 cases, adding null strings,
packed multi-character `%c`, packed uppercase `%C`, explicit `%3ts` truncation,
comma-separated decimal/hexadecimal, zero-delimited `%z` list substitution and
dynamic floating precision. These augment integer boundaries, buffer growth
and variadic checks without replacing the original formatter semantics with
C printf assumptions. Maximum submitted line remains 184 bytes.

`build/i386-format-temple-semantics-original/result.json` passes all 30 cases
on original x64 TempleOS. Checker SHA-256:
`63502c1faf82e0f411f90e1c5cf8159c20e70e9d135731eb7711ce239fd97ab5`.
The same native oracle is running against second-generation target 44ed8c88
in `build/i386-format-temple-semantics-native-red`; native MStrPrint remains
unintegrated, so a native pass is not claimed. Continue connecting the shared
original formatter and its symbol/raw-mode dependencies, then implement User
and task creation while preserving the original programming model.

### Current native formatter oracle remains red at API availability

`build/i386-format-temple-semantics-native-red/result.json` fails on preserved
second-generation target 44ed8c88 with checker 63502c1f. The initial
`HashFind("MStrPrint",Fs->hash_table,HTT_FUN)!=0` check does not produce the
expected success value; the harness times out at startup-command-00. The
30 formatting cases are not reached. The same checker passes all 30 cases
on original TempleOS. Native formatter integration therefore remains required.

Source inspection confirms `%p`/`%P` call original `StrPrintFunSeg` and `%P`
uses `IsRaw` to select linked output. Preserve original nearest-symbol lookup,
function/export distinction, offset/truncation formatting and display-mode
behavior when adding the native dependency bridge; do not replace it with
only the existing debugger's function-allocation lookup.

### Shared original symbol lookup and pointer-formatting cores

`Kernel/FunSeg.HC` now includes `FunSegLookupCore.HC` for HasLower and
HashFunSegFind, and `StrPrintFunSegCore.HC` for StrPrintFunSeg. Both extracted
bodies are byte-preserved; expanding the two includes reproduces the previous
file exactly. Architecture-dependent task scanning and cache management remain
in FunSeg.HC. This prepares reuse of original nearest-symbol selection and
pointer formatting by the native formatter without duplicating their behavior.

The original two-generation compiler/kernel rebuild passes in
`build/rebuild-test/result.json` (log `build/formatter-symbol-core-rebuild.log`).
The formatter oracle now has 34 cases, adding function pointer name+offset,
comma-mode name-only output and both null-pointer forms. All 34 pass on original
TempleOS in `build/i386-format-symbol-core-original/result.json`.
Checker SHA-256: `015cd3c5ca7f7569a4a6c53922772c82affd28c7f9f2fff5587142e66ad48285`.
Native integration is still pending; these extraction and original-oracle
passes do not imply native MStrPrint availability.

### Shared original function-symbol cache

`Kernel/FunSegCacheCore.HC` now contains the original FunSegCacheAdd and
FunSegCacheFind bodies. Expanding its include in FunSeg.HC reproduces the
previous source byte for byte, including cache bounds, timestamp handling,
name copying and the SYS_IDLE_PT special case. This completes extraction of
the reusable lookup, cache and pointer-formatting bodies; native task scanning,
code-address validation, clock/display adapters and formatter publication
still need implementation. No native formatting pass is claimed.

Validation: both original compiler/kernel rebuild generations passed in
`build/rebuild-test/result.json`, with the new shared source included in the
source hashes (log `build/formatter-cache-core-rebuild.log`). All 34 original
formatter cases passed in `build/i386-format-cache-core-original/result.json`
(log `build/format-cache-core-original.log`).

### Native original task display-mode query

The original IsRaw body is byte-preserved in `Kernel/IsRawCore.HC`, included
by both KMisc.HC and the retained i386 console. The native console publishes
`_IS_RAW`, and PublicWindow.HH exposes the original IsRaw API. It queries the
current task's DISPLAYf_NOT_RAW flag; this does not implement Raw switching
or establish rendering parity. Console service version stays 36 because its
service-record ABI and existing exports are unchanged; the new export is additive.

The original two-generation compiler/kernel rebuild passes in
`build/rebuild-test/result.json` (log `build/israw-core-rebuild.log`). The new
cross-build/386 instruction audit passes in `build/i386-display-query-kernel`;
boot kernel size remains 483088 bytes, with no new import binding. Its native
display-query test is recorded below after completion.

`tools/test-i386-display-query.py` checks API availability on the native target,
current-task mode queries in both flag states, restoration and continued HolyC
execution. Its helper restores the full display flags before returning. The
original six-case oracle passes in `build/i386-display-query-original`.
The formatter oracle now has 36 cases, adding allocated `%P` output in raw
and windowed modes. All 36 pass on original TempleOS in
`build/i386-format-display-mode-original/result.json`, checker SHA-256
`9ce7ae6d6d5df079308725ce52be7f9320aadf3922e0d0f3746b8af7eea34c9c`.
Native MStrPrint, formatter symbol scanning/cache integration, and full User
creation behavior remain required; these tests do not establish their completion.

The native display-query oracle passes on an 8 MiB `486,-fpu` QEMU boot in
`build/i386-display-query-native/result.json`; its source disk is unchanged.
Checker SHA-256: `f78b2368525c9b3786c3a82331f61ea860eb8a80dd1184e8109af7bb30949bea`.

### Original formatter integrated into the native console

The retained console now includes the original StrPrintCore and shared
FunSeg lookup/cache/pointer-formatting bodies. PublicFormat.HH exposes
StrPrintJoin, StrPrint, CatPrint and MStrPrint through four additive console
exports. The boot loader binds the existing public MSize and software-math
providers plus the hexadecimal bitmap and native idle entry. FunSegFind adapts
original nearest-symbol selection to the single-CPU task ring and mapped
bootstrap/public-pool regions; the cache retains its original timestamp and
name/offset behavior. Its private clock reads native jiffies atomically.
The shared cache class body remains unchanged in FunSegTypes.HH.

The formatter's file-read adapter copies service-owned bootstrap buffers into
task allocations that the original formatter can release with Free. It releases
the borrowed buffer before propagating allocation failure. Native display-mode
queries continue to use the original IsRaw body. The original infinity macro's
Latin-1 byte is present in the native compilation scope.

The two-generation original compiler/kernel rebuild passes (log
`build/native-formatter-infinity-rebuild.log`). Cross-build/386 instruction audit
passes in `build/i386-native-formatter-bound-kernel`, with 484384 flat boot bytes.
The 39-case original oracle passes in `build/i386-native-formatter-original-39`.
The same oracle passes on the cross-built port in
`build/i386-native-formatter-native-39/result.json`: 43 submitted commands,
8 MiB, 486,-fpu, ordinary boot, startup 46.61360586201772 seconds, unchanged
source disk. Checker SHA-256:
`c72bfd6d7a6668ef180012396407efe97b4b12191bcd3c07e00a48e40bfcc0a6`.
Cases cover growth, variadic arguments, integer boundaries, TempleOS-specific
formatting, pointer names/nulls, allocated %P in both display modes and signed
infinity. Original %e infinity uses eleven leading spaces; the oracle records
that behavior. This selected coverage does not establish every format/API case.

The native console source rebuild and full workstation regression are running
in `build/i386-native-formatter-console-selfbuild` and
`build/i386-native-formatter-workstation`. Their terminal verdicts will be
recorded separately. New all-native boot-image size, provider installation,
full formatter coverage, User creation, debugger completion and reproducible
release packaging still require verification/work. Hardware checks stay deferred.

The expanded 41-case formatter oracle also checks fixed-buffer StrPrint plus
CatPrint and direct StrPrintJoin with explicit argument slots. It passes on
original TempleOS (`build/i386-native-formatter-original-41`) and the cross-built
port (`build/i386-native-formatter-native-41`): 47 commands, unchanged source
image, 8 MiB 486,-fpu, startup 48.1894694827497 seconds. Checker SHA-256:
`30b0b9048a1b5f317a6c64909eb198476c24e1233e368093e1e0b75f231aa8de`.

The console now builds inside the port in
`build/i386-native-formatter-console-selfbuild/result.json`: 1077946 bytes,
3357 records and 340 function exports, including all four string APIs and IsRaw.
Installation passes in `build/i386-native-formatter-console-install/result.json`,
with byte-identical replacement and independent 8 MiB boot/DocAllocationCheck.
The installer accepts explicit --module-file MODULE=/PATH mappings so the
standalone console build's /Probe/RetainedConsole.t32m can be installed without
renaming or rebuilding it. Default retained-provider paths remain unchanged.
Native console SHA-256:
`0e6ee740c769fd4d3e779e0edc9420e7afd5c354f6c0960835950d2ec94a571e`.
Candidate disk SHA-256:
`38676a4aa1985dbff2cb8b68fd415e5098bd3e590ec26024fef640479a969271`.

All 41 formatter cases pass again with that installed native-built console in
`build/i386-native-formatter-installed-41/result.json`, on 8 MiB 486,-fpu with
the source disk unchanged. The twelve-module instruction audit passes with
this native console and the remaining cross-built components in
`build/i386-native-formatter-console-audit/result.json`. This mixed-provider
image does not replace the previously fully qualified all-native generation.

The full workstation suite remains active. A native Kernel source build is
also running in `build/i386-native-formatter-kernel-selfbuild`; its result will
measure the updated boot payload against the existing BIOS reservation before
claiming a new all-native installation. Preserve these jobs/evidence and poll
existing handles before starting additional builds.

The full workstation regression now passes on the cross-built formatter image
in `build/i386-native-formatter-workstation/result.json`: 513 native commands,
576 submitted lines, all VGA pixels matched, 20 document-session resource
cycles with exact shared-task data/code heap recovery. This broad check covers
the existing console/compiler, software math, graphics, document editing,
filesystem and navigation workflow; it does not replace verification of an
updated all-native release image. The native Kernel build remains active.

### Native formatter kernel exceeds the current boot reservation

The native Kernel source build finishes successfully in
`build/i386-native-formatter-kernel-selfbuild/result.json`, using the installed
native-built console: module 539549 bytes, SHA-256
`22e6ad401690d7077b9b0751873724c8f6a4af9054d99546b6fc1b672e3377fa`.
Its linked payload with the five cross-built boot helpers is 488256 bytes,
832 above the existing 487424-byte BIOS reservation. This source-build pass
is not a boot-image pass. Do not enlarge the reservation without checking the
boot stack/memory layout.

KernelConsoleLoad now uses a fixed 14-byte global binding-index table, matching
the other service loaders, instead of generating fourteen stack assignments.
The symbol indices and imported providers remain the same. Original two-
generation rebuild passes (log `build/native-formatter-binding-table-rebuild.log`).
Cross-build and native-size verification of this compaction are pending.

The original User creation oracle passes on the current bootstrap in
`build/i386-formatter-user-original`. The same checker fails on the installed
native formatter image in `build/i386-formatter-user-native-red`: User is absent
at the initial availability check, so creation cases are not reached; the source
disk is unchanged. Checker SHA-256:
`521478343b9e2c2dcde494d5265c95d5ca48a31e81f38102467c73c85e10d71e`.
After the boot-size gate, implement User with the original default Adam/CPU-root
parent, terminal-readiness handshake and formatted input delivery to the child.
Startup commands must run in the child; retain newline/partial-input behavior,
copy queued text into child-owned storage, and free it during normal consumption
or forced task cleanup. Do not substitute execution in the caller for XTalk.
Extend automation to creation hotkeys, focus and repeated task/heap recovery
before calling User integration complete. Physical/manual checks remain deferred.

The binding-index table compaction cross-build/386 audit passes in
`build/i386-formatter-binding-table-kernel/result.json`: flat payload 483384
bytes, 1000 fewer than the previous formatter cross-build. The port is now
rebuilding Kernel.HC in `build/i386-formatter-binding-table-selfbuild`; its
native-size result remains pending. Do not infer that the native payload fits
from the smaller cross-built payload alone.

### Compacted native kernel fits and boots; User input oracle expanded

`build/i386-formatter-binding-table-selfbuild/result.json` passes the native
Kernel source build: 538661-byte module, SHA-256
`df996db03c5d16a3e41cee85f530d300adfbfdff3966379d42583eeef92c0d6e`.
The linked payload is 487272 bytes, leaving 152 bytes of the existing BIOS
reservation. The native payload shrank by 984 bytes; do not substitute the
1000-byte cross-build reduction for this measured native result.

The native-built kernel with five cross-built boot helpers passes the twelve-
module executable instruction audit in
`build/i386-formatter-binding-table-native-audit/result.json`. Its boot disk
preserves the source filesystem and BIOS stage (provenance in
`build/i386-formatter-binding-table-boot/image.json`). All 41 formatter cases
pass on that boot image in `build/i386-formatter-binding-table-boot-41/result.json`:
47 commands, 8 MiB 486,-fpu, startup 45.36108453664929 seconds, source disk
unchanged. Flat SHA-256:
`f8be177a6d59d65f3955cb6e6f5694f7bbee0b0abcb1bab248a1b78e0e4b20c8`.
Disk SHA-256:
`c080e1be622ad6a10238f05f1b54542d8b7176cd7f12aadbcc4b9ef8d71dfd90`.
This is a mixed-provider image, not an updated all-native release qualification.

`tools/test-i386-user-create.py` now has 16 cases. Original behavior establishes
that a partial startup string does not execute until XTalk delivers its newline;
User performs two formatting stages, so four percent signs are required to send
one literal modulo operator into the child; and a startup line with over 512
bytes must execute successfully. The test confirms execution in the child,
Adam/CPU-root child membership, cleanup after four creation paths and continued
HolyC execution. The original branch now runs the shared case table and stops
dependent cases on the first failure, avoiding a later Kill on an invalid handle.

All 16 cases pass on original TempleOS in
`build/i386-user-complete-oracle-original/result.json`. The same checker remains
red on the compacted native-kernel image in
`build/i386-user-complete-oracle-native-red/result.json`: the initial User
availability check fails, so the 16 cases are not reached; source disk unchanged.
Checker SHA-256:
`f13e3f4691525e3b14cb613b946c365d8747a3025fa16605d24a38e135d116df`.

Next implement the original User/TaskWait/XTalk behavior with child-owned queued
input and cleanup. Grow terminal input storage beyond the current fixed 256-byte
line rather than truncating the now-tested long command. Preserve the two format
stages and newline/partial-input semantics. The tight boot reservation favors
using existing provider interfaces or validated published provider callbacks in
the console module; any new boot bindings require a measured size check.
Creation hotkeys, focus and repeated heap recovery remain additional gates.


### User/XTalk integration in progress (2026-10-04)

The native console now publishes User, XTalk and TaskWait using the existing
validated Spawn/Kill exports, without adding boot-kernel imports. User preserves
the CPU-root default parent and two formatting stages. XTalk queues a copy owned
by the destination terminal; terminal cleanup frees queued text and its growing
input buffer. Input is no longer limited to 255 bytes. PublicUser.HH loads public
declarations in CPU-root children without repeating singleton console/graphics
initialization. Child-header and terminal-readiness trace points use debug output.

The original two-generation rebuild and cross build pass for this implementation:
`build/i386-user-child-init-trace-kernel/result.json` records 483384 boot-kernel
bytes. This remains a cross-built, mixed-provider test image, not an all-native
release qualification. The preceding child-header image passes all 41 formatter
cases in `build/i386-user-input-child-headers-format/result.json`, 47 commands,
8 MiB 486,-fpu, with the source disk unchanged.

The initial native User test hit the default 30-second command timeout while
loading child declarations. Independent 120-second probes pass on both the
untraced and traced builds (`build/i386-user-child-init-latency/result.json` and
`build/i386-user-child-init-trace-probe/result.json`). Accordingly this fixture
allows 120 seconds per command; assertions and the 16 cases are unchanged. The
revised checker passes on original TempleOS in
`build/i386-user-child-init-original-120/result.json`. Checker SHA-256:
`f3efc65826b2ceb3de4b84a8c66e3a62f254109ee06f942e3cfe8a8a8f0ce52e`.
The two-terminal regression passes in
`build/i386-user-child-init-terminals/result.json`: 11 commands, separate
definitions/history, focus switching, exit refocus, child reclamation and exact
parent public-heap recovery, 8 MiB 486,-fpu, source unchanged. Native full-case
User run FAILS in `build/i386-user-child-init-native-120/result.json`: empty
creation returns 1, but UserProbeStop returns 0 and the expected-1 checkpoint
times out. The source disk is unchanged. Formatted/partial/long-input cases
are not reached. A separate child-lifetime probe is the next diagnostic; empty
creation does not prove the child remains valid or can be reclaimed correctly.

Remaining gates include creation hotkeys, repeated task/heap recovery, full
workstation regression and native console rebuilding/installing before updated
all-native image qualification. Broader TaskWait service-queue and input-filter
semantics still need explicit coverage; current queued text targets terminals.
The complete self-hosting/reproducible-release objective remains open.


### User oracle green and public-symbol retirement fixed (2026-10-04)

The cleanup failure above is resolved on the current cross-built test image.
A diagnostic split records `K1H1`: Kill succeeds but the child remains linked.
The reaper trace in `build/i386-user-stop-values-probe/debug.log` shows file
state already cleared and symbol state still attached. Public DefineLstLoad
metadata belongs to a task's public heap; the bootstrap symbol destructor had
attempted to free it through the bootstrap allocator.

MemoryTaskPublicSymbols now removes public-heap entries from the task's own hash
table before the existing bootstrap symbol destructor runs. It uses the original
shared SymbolHashDel visitor with a release callback that selects the allocation
owner, and checks table/public-heap locks before beginning. Compiler executable
and static storage retain their separate lifetime policy. The fix is in the
retained memory provider; the boot kernel and its import list do not grow.
One-time deferred/pinned reaper diagnostics remain available through debug output.

Original two-generation rebuilding passes. The corrected cross build passes in
`build/i386-user-public-symbol-cleanup-imports-kernel/result.json`, including
386 instruction auditing, with 483384 boot-kernel bytes. All 16 shared User
cases PASS in `build/i386-user-public-symbol-cleanup-native-16/result.json`:
28 commands, 8 MiB 486,-fpu TCG, startup 47.67935970192775 seconds, exact VGA
checkpoints and source disk unchanged. Empty/formatted/partial/percent-escaped/
long startup commands all execute and retire correctly. The revised checker
SHA-256 remains `f3efc65826b2ceb3de4b84a8c66e3a62f254109ee06f942e3cfe8a8a8f0ce52e`.
This supersedes the earlier red cleanup result without deleting its evidence.

The two-terminal regression also passes in
`build/i386-user-public-symbol-cleanup-terminals/result.json`: 11 commands,
8 MiB 486,-fpu, separate definitions/history, focus and exit refocus, child
reclamation and exact parent public-heap recovery; source disk unchanged.

The port's native compiler rebuilds MemoryRuntime successfully in
`build/i386-user-public-symbol-cleanup-memory-selfbuild/result.json`:
306979 bytes, 923 records, 138 exports matching the cross-built contract.
Native module SHA-256:
`aae46daffee9437fd2802d9b61d4601c99730992f7c116679791e64b86292bd9`.
Its installation and independent boot pass in
`build/i386-user-public-symbol-cleanup-memory-install/result.json`, on a copied
image with the other providers and boot kernel cross-built. Candidate disk SHA:
`cd3acb0ce8d85f91bfee27fa78740cf9c38f99bfbc3bd9fb09c2a59ae1ab4ba5`.
The 386 instruction audit passes in
`build/i386-user-public-symbol-cleanup-memory-audit/result.json` with the native
MemoryRuntime and remaining cross-built providers. This is not an all-native
release image, and the 16-case User runtime verdict above uses the cross-built
memory provider.

A native console build is running in
`build/i386-user-public-symbol-cleanup-console-selfbuild` on the image containing
native MemoryRuntime. Its independent export check now also requires NativeUser,
NativeXTalk and NativeTaskWait. Its verdict is pending. Next install/audit the
native console, rerun the User oracle on both native providers, then extend
creation-hotkey, focus and repeated heap-recovery automation and run the full
workstation gate. Fresh CPU-root children currently parse public declarations
again; the 120-second fixture allowance is not a creation-latency acceptance
criterion. Shared standard declarations and faster creation remain usability work.
General service-queue/input-filter TaskWait semantics need broader coverage.
The complete self-hosting, reproducible-release objective stays open.


### Guest-built User providers verified and shortcut oracle established (2026-10-04)

The console build previously marked pending now PASSES in
`build/i386-user-public-symbol-cleanup-console-selfbuild/result.json`:
1093897 bytes, 3434 records, 345 function exports. Its required-export check
includes NativeUser, NativeXTalk and NativeTaskWait, in addition to the existing
formatter, document/editor and build interfaces. Console module SHA-256:
`7d60b7825eb009dfe44bbf4e75fd4d96d09126f8417200694b26f28536c91efb`.
It was built inside the port on the image with guest-built MemoryRuntime.

Installation and independent boot PASS in
`build/i386-user-native-providers-install/result.json`. The installation preserves
the existing native MemoryRuntime; other providers and the boot kernel remain
cross-built. Both native providers pass the complete 386 instruction audit in
`build/i386-user-native-providers-audit/result.json`. Candidate disk SHA-256:
`08477a7cb9e856f3b6920d3a89068afacafad212aff1500fcab7386a08b55b2e`.

All 16 User oracle cases now PASS on this installed native-provider image in
`build/i386-user-native-providers-16/result.json`: 28 commands, 8 MiB 486,-fpu
TCG, startup 51.58985512610525 seconds, source disk unchanged, exact VGA
checkpoints. This proves child creation, empty/formatted/partial/percent-escaped/
long input, execution and cleanup for code emitted by the port's compiler.
All 41 formatter cases PASS in
`build/i386-user-native-providers-format-41/result.json`: 47 commands, startup
51.982766072265804 seconds, same machine and disk-preservation contract.
Hardware Ctrl-Alt-N focus cycling also PASSES in
`build/i386-user-native-providers-focus-hotkeys/result.json`: 11 commands,
startup 51.88247529184446 seconds, independent histories/definitions, exit
refocus and exact parent public-heap recovery. That test does not create terminals.

`tools/test-i386-original-user-hotkeys.py` establishes the next TDD reference.
It resolves the original private KbdBuildSC routine from the CPU-root symbol
table and submits real make/break bytes to its non-IRQ decoder. Six cases PASS
in `build/i386-user-creation-hotkeys-original-position/result.json`: Ctrl-Alt-T
and Ctrl-Alt-Esc each create and reclaim one CPU-root User child; plain T/Esc
and their Ctrl-Alt-Shift variants do not create one. The fixture identifies the
new node before the previous last child, matching original TaskQueInsChild;
it does not assume a head or tail insertion. Decoder scope is explicit: this is
not QEMU hardware delivery, focus or typematic qualification, and does not prove
the port's creation hotkeys. Checker SHA-256:
`c14ffb5770c544b91a1396de6939cd7efcb117cb354d821ed8a519024b484335`.
Earlier fixture attempts and their failures remain in build directories as
historical evidence; only the position-corrected result proves these six cases.

The full workstation gate is running on the native-provider candidate in
`build/i386-user-native-providers-workstation`; its verdict is pending.
Keep Kernel/Compiler sources frozen until it finishes. Next use the shortcut
reference to add QEMU creation/focus/cleanup checks and implement Ctrl-Alt-T,
Ctrl-Alt-Esc and the original Ctrl-Alt-Tab focus alias. Then qualify repeated
User resource recovery and address fresh-child declaration-loading latency.
Broader TaskWait/input-filter and cancellation behavior, debugger/workstation
completion, an updated all-native image and reproducible release packaging
remain part of the full objective. These mixed-provider successes do not close
those gates or establish release readiness.


### Creation shortcuts: original oracle to QEMU red/green (2026-10-04)

The pending workstation run on guest-built MemoryRuntime/ConsoleRuntime now
PASSES in `build/i386-user-native-providers-workstation/result.json`: 513 commands,
576 lines, 8 MiB 486,-fpu TCG, startup 51.42669410491362 seconds, exact VGA
checkpoints, 20 document cycles with exact task data/code heap recovery, and
0.3708586450666189-second long-document update. This image predates the new
shortcut source and has cross-built boot/remaining providers.

The QMP driver now accepts explicit key chords. Its control run reuses the
existing Ctrl-Alt-N focus oracle and PASSES in
`build/i386-keyboard-chord-focus-control/result.json` (11 commands). The new
`tools/test-i386-terminal-create-hotkeys.py` is grounded in the six original
KbdBuildSC oracle cases, adds actual QEMU input delivery, and requires a focused
VGA child, child 6*7, Exit, CPU-root child-list cleanup and resumed root input.
It catches possible Shift-Esc break behavior when testing no creation; it does
not claim that Shift variants have no other input action.

The position-corrected creation fixture first FAILS on the prior image at
Ctrl-Alt-T in `build/i386-terminal-create-hotkeys-native-red-v2/result.json`:
no new child marker appears; later cases are not reached; source unchanged.
The identical checker PASSES on the new cross-built image in
`build/i386-terminal-create-hotkeys-native-green/result.json`: 15 outer commands,
8 MiB 486,-fpu TCG, startup 50.196653900202364 seconds, exact VGA checkpoints,
source unchanged. Both Ctrl-Alt-T and Ctrl-Alt-Esc create, focus, execute 6*7,
Exit and reclaim the child; plain/Shift variants do not create a child.
Checker SHA: `29a6b3529acd7c009a78bf578efa9143b946699f2691ed82dec2c96f9d9ec154`.
Driver SHA: `abd7c8f863fb7233d41f47efec9febd6e73ea56ca4bb7b47d606fba62c0782de`.
New image SHA: `dfec38e37d3faf7371b71ad3bafbc197a6f924600b846e0094e7f90a4e3a80e0`.

Creation runs in the keyboard worker, not IRQ context. It spawns a child that
loads declarations and focuses itself, allowing keyboard decoding to continue
while startup proceeds. Programmatic UserCmdLine still ignores its original
dummy argument and uses the same initialization without forcing focus.
Per-key held state consumes make/break pairs with IRQ-protected updates. The
handler rejects Shift variants, maps Esc to creation and Tab to focus cycling.
No boot imports or provider ABI change is needed. Original two-generation
rebuilding and cross-image 386 audits pass; boot-kernel size stays 483384 bytes.

The focus checker now accepts `--focus-key n|tab` and records the selected key.
Both variants PASS on the new image in
`build/i386-terminal-n-hotkeys-regression/result.json` and
`build/i386-terminal-tab-alias-native-green-labeled/result.json` (11 commands each,
8 MiB 486,-fpu, exact VGA, independent definitions/history, exit refocus, exact
parent public-heap recovery, source unchanged). The initial Tab run's report
had a stale N scope label; use the labeled rerun as authoritative evidence.
The identical labeled Tab checker FAILS on the prior image in
`build/i386-terminal-tab-alias-native-red-labeled/result.json`: the first
focus change does not reach the expected VGA terminal; source unchanged.
Red and green checker SHA:
`d46842561c2a7aeeb594d9aacfc0e8b5bbd433ee655f45efeb1909f483979748`.

The full 16-case programmatic User regression is running in
`build/i386-creation-hotkeys-user-regression-16`. Updated native MemoryRuntime
and ConsoleRuntime building is running in `build/i386-creation-hotkeys-native-build`.
Keep OS sources frozen until these jobs finish. Then install/audit those native
outputs and rerun creation, focus and User gates before updated workstation
integration. Typematic parity, exhaustive repeated-creation resource recovery,
fresh-child latency, broader TaskWait/filter/cancellation behavior, updated
all-native images and reproducible release qualification remain open.

## Next architecture work: boot capacity and complete CPU debugging

The promoted breakpoint bridge consumes nearly all current guest flat
capacity: 487304 of 487424 bytes. The limit comes from the fixed 960-sector
BIOS load area minus its 4096-byte stage, not from available installed RAM.
Do not waive the size guard or remove planned debugger/API functionality.
Keep current qualified images as reproducible baselines.

First establish a capacity contract with automated boundary fixtures:
maximum valid payload boots, one-byte oversized payload is rejected before
publication, a truncated payload never executes, and boot publication leaves
RedSea metadata/file extents unchanged. Both host construction and guest
I386BuildBootImage/installation must enforce the same format. Include
8 MiB no-FPU cold boot and two-generation artifact/boot reproducibility.

Then evaluate moving additional implementation into retained modules versus
extending the staged loader. Prefer retaining a small resident kernel and
using existing module services where that removes the bottleneck cleanly.
If a larger initial payload is necessary, use a bounded BIOS staging buffer
and protected-mode relocation with explicit load ranges, entry validation
and stack/EBDA separation; increasing the low-memory sector count alone is
not sufficient architecture. Choose the implementation from measured boot
module sizes and failing capacity fixtures. Preserve legacy BIOS, 386-only
instructions, VGA, 8 MiB interactive RAM and guest rebuild/install semantics.

Complete CPU debugging with observable contracts for S/single-step vector 1,
register inspection/editing and explicit G target, managed breakpoint
installation/removal/re-arm, and concurrent task ownership. Each must prove
state/continuation and cleanup through real guest execution. Existing
INT3 continuation, six-register markers and forced-child exit cover only
the initial bridge. Full native qualification and all release gates remain
required after these architectural changes.

## Public file API parity discovered by capacity fixtures

The payload-rejection fixture cannot yet create files: public FileWrite
is undefined. Original FileWrite is I64 FileWrite(filename,buffer,size,
CDate cdt=0,attr=0); RedSea success returns the allocated cluster, failure
returns zero, and an empty file uses INVALID_CLUS (-1). It does not return
a Boolean or byte count. Preserve these semantics in tests and bindings.

Use independent persisted RedSea inspection to compare the return value
with the directory entry's cluster, exact binary bytes/length and requested
timestamp/attributes. Cover replacement, relative/current-drive paths,
empty and negative-size original behavior, invalid parent/name and failed
allocation/write without corrupting existing files or leaking task heaps.
Test default date behavior against the original API's Now semantics.
Compression (.Z/RS_ATTR_COMPRESSED) and resident-file behavior need explicit
compatibility inventory/oracles; existing DocWrite or a Boolean service
wrapper does not establish those requirements. Audit FileRead and FileFind
alongside this work rather than assuming document operations expose them.
Then rerun the six malformed/oversized publication cases and require exact
whole-target preservation. Full executable truncation remains a distinct
boot-format integrity requirement.

## CPU-trap generation-two checkpoint and compression experiment

`build/cpu-trap-main-gen2-native-build/result.json` records successful native
construction of all six retained providers and byte identity with the installed
first generation (`build/cpu-trap-main-selfhost/target.img`, SHA-256
`b43b2e027a917f244d2a2fe2e1a97144b6ec05b45fd3e70cb830d4fa2f19a565`).
`build/cpu-trap-main-gen2-native-install/result.json` records exact installation
and independent 8 MiB 486 boot, arithmetic and document allocation checks.
The resulting candidate SHA-256 is
`5ff979ad0f5002cfa5bbaeaefc75731ddc945dca9684a79caf04f2e0f47637d8`.
Full second-generation self-hosted construction is running in
`build/cpu-trap-main-gen2-selfhost`; installed audits and twelve-module/flat/boot
comparison must pass before claiming this epoch reproducible.

The isolated FileWrite prototype now has a candidate native archive encoder
adapted from the original dictionary compression, filename-based .Z attribute
inference, archive allocation/cleanup and replacement attribute publication.
These changes are not promoted or qualified. Its original bootstrap rebuild
passes. The first cross compilation rejected NULL in an early header context;
the candidate now uses numeric zero and restores saved interrupt state on
unsupported-attribute rejection. The source-epoch guard correctly requires
a fresh bootstrap after those edits; bootstrap rebuilding followed by cross
compilation is running before the existing write/include/execute contract. A successful ordinary write does
not prove compressed output works.

After the executable .Z contract passes, qualify seven/eight-bit input, dictionary
growth/recycling, incompressible fallback, empty/replacement writes and original
archive interoperability. Extend independent filesystem audits to legitimate
compressed records while retaining extent, overlap, bitmap and corruption
checks. Resident-file semantics and the remaining public file APIs still need
original-behavior inventory. None of these partial checks closes the release
goal or the debugger and boot-capacity work above.

## CPU-trap epoch: two-generation qualification passes

`build/cpu-trap-main-gen2-selfhost/result.json` and
`build/cpu-trap-main-gen2-selfhost-audit/result.json` pass full guest-built
construction, installation/independent boot and installed executable audits.
`build/cpu-trap-main-generations-audit.json` passes exact comparison of all
twelve modules, the 487304-byte flat payload and installed boot area, plus
independent extent/bitmap verification of both RedSea volumes. Flat SHA-256:
`dd9a2080f5d89010e1827ae9727e456ccc5e0caab81ee762ec73534abe435218`.
Second-generation disk SHA-256:
`2ce117d75adae9313e646461b8fc47103b5ad538241ba13e5f15622e15d9eba1`.
Whole disk hashes differ; the executable artifacts and boot bytes match.
This closes the current CPU-trap epoch's generation comparison, not the
remaining debugger, boot-capacity, public API or release requirements.

The corrected isolated compression prototype passes fresh original bootstrap
rebuilding and cross compilation/instruction audits in
`build/file-write-prototype/build/file-write-compression-zero`. Its native
write/include/execute contract is running. This does not yet qualify archive
interoperability, dictionary-boundary behavior or compressed filesystem audits.

The dated-file corruption test now accepts a selectable filename, for reuse
on a real compressed fixture, and rejects unsupported attributes and compressed
records lacking contiguous storage. All six corruption cases pass on the
ordinary dated fixture (`build/redsea-date-audit-attributes-test.json`), keeping
overlap, out-of-volume, bitmap and invalid-name coverage.

## Initial compressed FileWrite contract passes in isolation

`build/public-file-write-compressed-encoder/result.json` first proved native
write/include/execution, exact VGA and archive header/metadata, then failed the
ordinary-only filesystem auditor. The auditor now permits exactly ordinary
contiguous (0x800) and compressed contiguous (0xC00) file records and reads
either through the independent directory walker. Directory date restrictions,
extent bounds/overlap checks and exact reachable-sector bitmap checks remain.

`build/public-file-write-compressed-audit-green/result.json` passes all four
guest commands on 8 MiB 486 without FPU, archive type CT_7_BIT, requested date,
0xC00 attributes and full independent filesystem verification; the source
disk remains unchanged. This establishes one ASCII HolyC .Z write that the
native compiler can include and execute, not general encoder parity.

Both ordinary and actual compressed fixtures pass all six corruption cases:
`build/redsea-date-audit-attributes-test.json` and
`build/redsea-compressed-date-audit-test.json`. Reproduce the compressed check:

```sh
python3 tools/test-i386-redsea-date-audit.py \
  build/public-file-write-compressed-encoder/candidate.img \
  --name PublicCompressed.HC.Z
```

The encoder/FileWrite implementation remains isolated pending the wider
archive and API requirements above. Next use original compression/expansion
as interoperability oracles and test dictionary growth/recycling, 8-bit data,
fallback, empty/replacement and heap/error cleanup before promotion.

## Original archive parity test finds directory-relocation return bug

New `tools/test-i386-public-file-write-archive-parity.py` generates deterministic
fixtures, boots the original implementation to CompressBuf/ExpandBuf round-trip
and export each archive, then compares native FileWrite output byte for byte
through the independent RedSea walker. Eight cases cover empty/one-byte input,
repetition, seven/eight-bit dictionary growth/recycling and incompressible
fallback. Dictionary fixtures must emit enough bits to require more than 4096
codes even at maximum 12-bit width; fallback fixtures must use CT_NONE.
The native run also checks exact VGA, requested dates/attributes, complete
extent/bitmap consistency and unchanged source disk.

The first test helper exceeded the shell's 255-character input limit; it was
split into ordinary short definitions before retrying. The ordinary-write
baseline fails the empty .Z write contract in
`build/public-file-write-archive-parity-red`; no compression parity is claimed
for that image. The candidate reaches the dictionary7 write in
`build/public-file-write-archive-parity-split`, but reports zero despite
persisting the correct file. Independent inspection proves all five archives
written up to that point match original bytes exactly (empty, single7, single8,
repeat7 and dictionary7), and the volume passes extent/bitmap verification.
The complete eight-case test remains failed, including unexecuted dictionary8
and fallback cases.

Creating dictionary7 grows/relocates its parent directory. The new public
wrapper's post-create cluster lookup still uses the former parent block, so
it reports failure for a successful mutation. The isolated candidate now
resolves the complete file path from the current root after publication,
instead of looking through the potentially stale parent. A fresh original
bootstrap and cross build are running in
`build/file-write-prototype/build/file-write-compression-resolve`; rerun the
whole original-parity contract and lifecycle/metadata tests before promotion.
This is a real return-value/API bug discovered by larger fixtures, not evidence
that all dictionary or error-path requirements are complete.

## Archive parity and ordinary API regression checkpoint

The corrected isolated build passes fresh original bootstrap/cross construction
and 386 instruction audits. Its image SHA-256 is
`abeb0150295a422d6908687e13d920eb17c62fd119571f8fc60374ea95ad652b`.
`build/public-file-write-resolve-metadata`,
`build/public-file-write-resolve-lifecycle` and
`build/public-file-write-resolve-now` pass the existing positive-cluster/binary
metadata, replacement/empty/negative/missing-parent and default-date contracts.

`build/public-file-write-archive-parity-resolve-corrected/result.json` passes
all eight original archive comparisons, twelve guest commands, exact VGA,
dates/attributes and full independent filesystem verification. Seven-bit
dictionary output is 38552 bytes; eight-bit dictionary output is 38832 bytes
for 65536-byte inputs, both byte-identical to original output and large enough
to require dictionary recycling. Both random 32768-byte fixtures exercise
CT_NONE fallback. One eight-bit byte also uses the original capacity fallback:
it cannot fit the initial nine-bit code in its one-byte payload allowance.
The earlier test expectation of CT_8_BIT for that single byte was incorrect
and was corrected from the actual original oracle, without changing the encoder.

`build/public-file-write-archive-replacements/result.json` passes twenty-two
guest commands and swaps all eight filenames to reversed fixture contents,
including large-to-empty and empty-to-large archives. Persisted bytes match
the original counterpart, timestamps change to the requested value, and
reachable extents exactly match the allocation bitmap. A tightened run in
`build/public-file-write-archive-replacements-returns-fixed` also checks the
intermediate replacement write's return and records original bootstrap/script
hashes; that tightened run passes all twenty-two guest commands, original byte
comparisons, dates/attributes and filesystem checks. The original-bootstrap hash collection initially
used incorrect filenames and was corrected to 0000Boot/0000Kernel.BIN.C and
Compiler/Compiler.BIN before this run.

Full 513-command workstation qualification is running in
`build/public-file-write-resolve-workstation`. This remains an isolated source
epoch; no FileWrite/encoder implementation is promoted yet.

Original API inventory confirms FileRead returns a fresh terminated allocation,
expanded size and stored attributes, tries the alternate .Z filename and parent
directories, and consults/updates the shared resident cache. FileWrite refreshes
or removes that cache as attributes change. RS_ATTR_RESIDENT is 0x200; it is a
separate flag, not automatically inferred from .T by FileAttr. FileAttr infers
.Z compression and .C contiguous storage. Public FileRead/FileFind and resident
cache interoperability still require original-behavior tests and implementation.
Do not call plain compressed write parity full file API compatibility.

## Public FileRead: original-oracle red/green checkpoint

`tools/test-i386-public-file-read.py` first validates the original three-argument
API in an original guest, then checks the port independently. It covers exact
binary bytes, size/attributes, trailing NUL, a real CT_8_BIT compressed archive
(64 expanded bytes), alternate .Z lookup, distinct current-task-owned buffers,
mutation of one buffer without affecting another or persisted bytes, empty
files and missing-file output reset. Persisted compressed bytes must match
an archive exported by the original compressor.

The initial functional original oracle passes, then
`build/public-file-read-compressed-red` fails on undefined FileRead after
successful file setup. The final strengthened version has the same qualified
red result in `build/public-file-read-final-red`. Exact original heap-counter
recovery across repeated reads did not pass; it is explicitly excluded from
the original functional oracle rather than reported as original behavior.
The port still must recover its exact current-task heap count over twenty
read/free cycles for both raw and compressed files.

The isolated `build/file-read-prototype` carries the already tested ordinary/
compressed FileWrite epoch and adds public FileRead plus a native export.
It uses the existing file service, copies the terminated result into a current-
task public allocation and releases the service's private buffer, including
allocation exception cleanup. It resets optional size/attribute outputs on
failure. No file-service layout change is needed for this wrapper.
Fresh original bootstrap/cross compilation and instruction audits pass in
`build/file-read-prototype/build/file-read-public`.

`build/public-file-read-green/result.json` passes all twenty-four commands,
original functional oracle, both exact twenty-cycle heap-recovery checks,
exact VGA and independent filesystem/extent/bitmap checks on 8 MiB 486 without
FPU. Startup is 25.148 seconds. Source image SHA-256:
`379160ced32bcb73bc37a54e90dbbff50db6e82defc01144128ae84f5ce6b4a0`.
The source image remains unchanged. The wrapper remains isolated and is not
promoted. Full FileWrite workstation qualification remains live in its prior
source epoch; its result does not qualify this later FileRead epoch.

Next tests must establish parent-directory search, resident-cache coherence,
missing/invalid/malformed archive behavior, public FileFind and allocation/IO
failure cleanup. The current wrapper temporarily uses both private and public
buffers; qualify larger-file peak memory and consider direct public allocation
in the service before claiming complete 8 MiB file API parity. Repeat full
workstation/native builds/generation checks after architectural promotion.

## Public file API: FileWrite promotion and next contracts

Full FileWrite workstation qualification passes in
`build/public-file-write-resolve-workstation/result.json`: 513 commands, exact
VGA and twenty exact shared heap-recovery document cycles. Startup is 24.495
seconds; long-document update is 0.255 seconds. The unchanged formal startup
budget passes in `build/public-file-write-resolve-workstation-budget.json`.

Main now contains the tested ordinary/compressed five-argument I64 FileWrite,
explicit/default timestamp behavior, bounded original dictionary encoder and
post-publication full-path resolution after directory relocation. The public
export is registered and the file-service ABI is 38. Replacement accepts an
optional attribute update while existing callers preserve attributes by default.
Legacy private Boolean writes keep their existing behavior. Resident attributes
and cache parity remain unsupported and explicitly unfinished.

`build/file-write-main-original-cross-build.log` passes the fresh original
bootstrap and cross-build/instruction/keyword audits.
`build/file-write-main-byte-comparison.json` proves all twelve T32Ms and
Kernel32.BIN match the fully tested prototype byte for byte. Main native
retained reconstruction is running in `build/file-write-main-native-build`;
main archive replacement requalification is running in
`build/file-write-main-archive-parity`. Native installation/flat generation
comparison remains required for this newly promoted source epoch.

The FileRead test now optionally exercises parent search with `--parents`.
`build/public-file-read-parent-red/result.json` is actually a PASS: 27 commands,
original oracle, absolute child-path raw lookup and alternate .Z parent lookup,
exact VGA and read/free recovery. No implementation change was necessary;
the interactive task uses the existing worker read service's parent search.
The result directory's intended red name must not be mistaken for a failure.
This qualifies those parent cases, not every root/task/search combination.

New `tools/test-i386-public-file-find.py` validates original Bool FileFind
existence, file/directory filters, explicit alternate .Z and parent-search
flags, missing names and NULL. Its original oracle passes;
`build/public-file-find-red` performs successful directory/file setup, then
fails on the undefined FileFind identifier. Next preserve original CDirEntry
layout/metadata, caller-owned full_name allocation, output zeroing on failure,
wildcard behavior and invalid-flag exceptions before implementing the API.
The existence-only contract is not sufficient for full FileFind parity.

## Main archive requalification and FileFind metadata TDD

`build/file-write-main-archive-parity/result.json` passes the tightened
twenty-two-command replacement contract on the promoted main image. All eight
final archives match original compressed bytes; intermediate/final write
returns, updated dates/attributes, exact VGA and independent filesystem checks
pass. Source image SHA-256 is
`abeb0150295a422d6908687e13d920eb17c62fd119571f8fc60374ea95ad652b`; it remains
unchanged. Main native retained rebuilding is still live in
`build/file-write-main-native-build`; no native-generation result is claimed.

The FileFind test now checks entry attributes, persisted size/cluster/date, an
allocated canonical full_name belonging to the caller's task heap and released
with Free, whole-record zeroing on missing lookup, literal wildcard rejection
and an FUF exception for unsupported flags. It retains existence, file/directory
filters, alternate .Z, parent and NULL cases. The helper uses a record modeled
on the original CDirEntry fields; public CDirEntry declaration/layout exposure
remains a distinct required contract. Do not claim the modeled record proves
the public type is available in the port.

`build/public-file-find-owned-metadata-red/result.json` passes every original
oracle check, then confirms native file setup followed by compilation failure
on undefined FileFind in the metadata helper. Initial quoting in the new
exception helper was corrected before this run. There is no green native
FileFind implementation yet. Next extract/share the actual original directory
entry declaration, expose the full public signature, and implement the tested
metadata/lookup/ownership/exception behavior through task-owned file services.
Add explicit heap/error cleanup and full native qualification before promotion.

The isolated FileRead epoch now has its own full workstation run live in
`build/public-file-read-workstation`. This is separate from the passed earlier
FileWrite epoch; FileRead remains unpromoted until its own broader qualification.

## FileFind implementation: public entry and named-flag contracts pass

The isolated `build/file-find-prototype` carries the tested FileRead wrapper
and adds FileFind through a versioned file-service callback (ABI 39). It
shares the original CDirEntry declaration in Kernel/DirEntryTypes.HH and
original supported flags in Kernel/FileFindFlags.HH with KernelA.HH and
native public headers. Original header bytes outside those extracted sections
are preserved. The service performs exact-name lookup, file/directory filters,
optional .Z and ordered parent search through task-owned volumes; normalized
parent paths strictly shorten and lookup attempts are bounded. The public
wrapper validates flags, zeros missing-entry output and converts the service's
private name into a current-task public allocation released with Free.

Fresh original bootstrap rebuilding and cross/instruction audits pass in
`build/file-find-prototype/build/file-find-public-flags`. Cross boot payload
is 483176 bytes. The earlier candidate passes actual-public-entry checks in
`build/public-file-find-public-entry-green`; the previous FileRead-only image
fails that strengthened contract in `build/public-file-find-public-entry-red`.
Named constants are separately qualified: original oracle passes, the prior
candidate fails at undefined FUF_JUST_FILES in
`build/public-file-find-named-flags-red`, then the updated candidate passes
`build/public-file-find-public-flags-green/result.json`.

The final contract passes twenty-six commands on 8 MiB 486 without FPU,
actual public CDirEntry, named FUF flags, canonical current-task-owned full_name,
metadata/lookup/zeroing/FUF-exception behavior, exact VGA and independent
filesystem verification. Startup is 24.648 seconds. Source image SHA-256:
`c655cc6298bdaa805d39948c1778d59ec93ad48ed4d673c2aa3dd80ea11f51b9`.
The source remains unchanged. Full workstation qualification is running in
`build/public-file-find-workstation`; FileRead regression including parent
lookup is running in `build/public-file-find-read-regression`. Neither FileFind
nor FileRead is promoted. More failure cleanup and broader task/drive/name
cases remain required; this contract is not the entire release gate.

Main FileWrite native retained construction now passes all six providers in
`build/file-write-main-native-build/result.json`. The resulting source image
SHA-256 is
`6d50e30cec0158286c52673987fbf9e799704dbe2958839e49eaf5ed71a76ca2`.
Exact retained installation and independent boot are running in
`build/file-write-main-native-install`; flat reconstruction and two-generation
comparison remain open for this promoted epoch. The separate earlier FileRead
workstation run remains live; no result is claimed prematurely.

## FileFind cleanup proof and source-view oracle correction

Main FileWrite retained installation passes in
`build/file-write-main-native-install/result.json`, followed by full native
construction/installation/independent boot in
`build/file-write-main-selfhost/result.json`. All twelve modules are guest-built.
Flat payload is 487304 bytes (120 spare); SHA-256:
`43594ce3239c33f3d475282b1cd90557622ab49bb4bc3d7e61df78f35657cd82`.
Installed target SHA-256:
`c45551301c49a71a348d7014555f613f4473910c7cb662d05b1c0bc5dff2abf7`.
`build/file-write-main-selfhost-audit` passes installed executable/386/boot/
filesystem audits. Second-generation retained rebuilding/comparison is running
in `build/file-write-main-gen2-native-build`; reproducibility is not yet claimed
for this epoch.

FileRead regression on the combined isolated FileFind epoch passes all 27
commands, including parent lookup and exact read/free recovery, in
`build/public-file-find-read-regression/result.json`. The separate FileRead
and FileFind full workstation runs both terminate at help-man-page-link: the
viewer correctly shows the appended FileRead declaration but the test's exact
source-screen fixture still expects the former PublicFiles.HH contents. These
are failed full runs, not full workstation qualification.

`tools/test-i386-source-aware-workstation.py` now runs the complete original
suite through an in-memory harness adapter with an independent disk-based
source-view oracle. It locates the unique Dir declaration in the packaged
header, wraps its following source lines to 80 columns, and retains exact VGA
comparison and every other suite check. It does not derive expected content
from the guest screen or guest-provided source-link metadata. The replacement
full run is live in `build/public-file-find-source-aware-workstation`. The old
FileFind process was already terminal when cancellation was attempted; no live
job was restarted merely because observation expired. Existing harness files
were not modified while jobs were live.

The initial private-heap cleanup probe stopped at an unsupported internal
TaskFiles.HH include before executing recovery cycles. The new read-only QMP
observer locates kernel_heap from the bounded boot-module data export, validates
its signature/arena bounds and observes used bytes plus allocation count before
and after the cycle command. It records module/harness hashes.
`build/public-file-find-qmp-heap-recovery/result.json` passes thirty commands
and twenty mixed lookup/name-release/missing/filter/parent/FUF-exception cycles:
public task heap usage recovers exactly, and private heap returns to 5346256
used bytes and 7068 allocations. Both physical snapshots match. Exact VGA,
original functional oracle and filesystem checks pass; source disk is unchanged.
These port-only allocation invariants are separate from the original functional
oracle. FileFind/FileRead remain isolated pending full and native qualification.

## FileFind early-rejection compatibility bug: matched red/green

The strengthened FileFind contract has `--edge-cases` for NULL-name and
invalid-drive output preservation, contradictory file/directory filters and
parent-search rejection when the starting directory does not exist. The
original oracle passes all cases. The prior candidate fails
`build/public-file-find-early-rejection-red` at
FindUntouched("Z:/NoFindDrive.BIN"): it clears the caller's record, whereas
original FileFind returns early without touching that record. NULL rejection
already preserves it.

An isolated correction in `build/file-find-rejection-prototype` distinguishes
early drive rejection (-1) from a normal miss (0) and success (1) through an
I64 private callback, with file-service ABI 40. The public API remains Bool
FileFind: it preserves output on early rejection, clears it on a normal miss
and publishes an owned full_name on success. Existing ABI-39 qualification
runs retain their original source epoch. The service-size source assertion
is corrected to 100 bytes for the added callback. Fresh original bootstrap
and cross/instruction audits pass in the corrected checkout.

`build/public-file-find-early-rejection-green/result.json` passes 36 commands
with actual public CDirEntry, named flags, original functional oracle, edge
cases and twenty mixed allocation-recovery cycles including invalid drives.
Startup is 24.898 seconds on 8 MiB 486 without FPU. Public task heap usage
recovers exactly; read-only QMP snapshots show private heap used bytes
5347720 and allocation count 7080 unchanged. Exact VGA and independent
filesystem checks pass. Source image SHA-256:
`d10e8a3cdc4e46e39264f1e5d0e89ae9f279885d8e73344245151556f8e151b2`.
The source image remains unchanged.

The source-aware full workstation run remains live on the earlier ABI-39
candidate; its eventual result will not qualify the ABI-40 correction. Main
FileWrite generation-two retained rebuilding/comparison also remains live.
Before promotion, require the corrected candidate's full workstation and
regressions/native construction, and continue resident/file-error compatibility
work. No narrower test closes the OS release objective.

The earlier ABI-39 source-aware workstation run has now finished successfully:
`build/public-file-find-source-aware-workstation/result.json` reports all 513
native commands, exact VGA pixels at every checkpoint, twenty document resource
cycles with exact task heap recovery, and an unchanged source disk. This covers
the candidate with SHA-256
`c655cc6298bdaa805d39948c1778d59ec93ad48ed4d673c2aa3dd80ea11f51b9`.
Startup was 24.237 seconds on 8 MiB QEMU with `486,-fpu`; the explicit 60-second
timing gate passes in
`build/public-file-find-source-aware-workstation-budget.json`. The long-document
navigation-to-VGA measurement was 0.375 seconds. The result's private heap
observation records module location/provenance only: this full run did not take
private allocator recovery snapshots. Those are covered by the separate mixed
FileFind recovery test, not inferred from this workstation report.

The corrected ABI-40 candidate is undergoing its own full workstation run in
`build/public-file-find-rejection-workstation` and public FileRead/parent-search
regression in `build/public-file-find-rejection-read-regression`. Neither result
is assumed from ABI-39 success. Main's FileWrite generation-two native retained
build remains running; FileRead/FileFind implementations remain isolated pending
their qualification and promotion.

ABI-40 public FileRead regression now passes in
`build/public-file-find-rejection-read-regression/result.json`: 27 commands,
including parent search, binary and expanded `.Z` reads, alternate-name lookup,
independent owned buffers, empty/missing files and twenty read/free recovery
cycles. The original functional oracle, exact VGA and independent filesystem
audit pass; the source disk remains unchanged. Startup is 25.698 seconds on
8 MiB `486,-fpu`. Resident-file compatibility remains outside this result.
The corrected candidate's native retained build has started in
`build/public-file-find-rejection-native-build`; it is not yet qualified.

Main FileWrite generation-two retained rebuilding has completed successfully
in `build/file-write-main-gen2-native-build/result.json`. All six modules are
byte-identical to those installed in generation one, whose disk SHA-256 is
`c45551301c49a71a348d7014555f613f4473910c7cb662d05b1c0bc5dff2abf7`.
The generated source disk SHA-256 is
`9d7eae520e0a1a177500e8d285486b4858fd353bbe304c0452b0b03a51cbbf20`.
Generation-two retained installation and independent boot are running in
`build/file-write-main-gen2-native-install`. Rebuilding the other six modules,
installing the flat kernel and comparing complete generations still remain;
the retained comparison alone does not prove whole-system reproducibility.

Generation-two retained installation and independent boot now pass in
`build/file-write-main-gen2-native-install/result.json`, with installed disk
SHA-256 `83ee4c3c273abb8e073116a7ddf4c3a71dab8ad718aeab3d4401736393627ff2`.
The full native kernel construction has started in
`build/file-write-main-gen2-selfhost`, using those verified retained-build and
installation reports as provenance. Its result is still pending.

The public FileRead checker now has `--resident` for resident writes, fresh
owned cached reads and replacing a resident file with ordinary storage. The
initial oracle attempt (`build/public-file-resident-red`) rejected our assumed
cached attribute of 0x800. Original DskFile.HC initializes cached-read attributes
through FileAttr(name,0), so a cached `.BIN` read reports 0; an ordinary disk
read after removing residence reports 0x800. The corrected original functional
oracle passes in `build/public-file-resident-cached-attr-red/oracle/debug.log`.
The port run is pending; its resident write is expected to expose the existing
attribute-mask limitation, but that failure is not yet qualified evidence.
This test covers write-populated caches and ownership, not cold disk cache
population, compressed resident entries, alias coherence or cache teardown.

The corrected resident test has now reached a qualified port failure in
`build/public-file-resident-cached-attr-red/result.json`: original functional
oracle passes, but the native run times out waiting for the positive result at
the resident FileWrite expression (checkpoint startup-command-21). TaskFileWrite
source rejects attr 0x200 with return 0; the harness did not persist a screenshot
of that failing answer, so the recorded runtime verdict is a checkpoint timeout.
The source image is unchanged. The later
resident ownership/replacement cases have not executed on the port.

Resident implementation must use a shared, explicitly owned cache with the
mounted file-service lifetime, matching the original Adam-owned HTT_FILE model.
Do not attach owned entries to CI386TaskFiles: its Set path frees and replaces
the state on directory changes, and Clone/Destroy serve individual tasks.
Keep cache storage separate from caller-owned returned buffers. Cache compressed
stored bytes, then decode each returned read, as original DskFile.HC does; cached
attributes derive from FileAttr(cache-name,0), while uncached reads expose disk
attributes. Qualify resident replacement with changed bytes, removal of residence,
exact/alternate-name lookup, cold disk population after reboot, task independence,
and bounded cache cleanup before promoting. Allocation and failed-write cache
behavior require original-oracle cases rather than assumptions about atomicity.

Resident replacement coverage is strengthened in the checker: write a different
first byte while retaining residence, require the cached read to return it with
attribute 0, then write another different byte without residence and require
disk attribute 0x800. On success, the independent disk walker must also find
the final replacement bytes. This prevents unchanged-payload fixtures from
hiding stale cache entries. The strengthened original functional oracle passes
in `build/public-file-resident-replacement-red/oracle/debug.log`; its native
run is pending and does not qualify a cache implementation. Reports now record
requested parent/resident scope even on failure and describe excluded features
according to the selected options.

Main FileWrite generation two is now fully guest-built and installed:
`build/file-write-main-gen2-selfhost/result.json` passes with all twelve modules,
16 MiB build RAM and independent 8 MiB boot. Flat size remains 487304 bytes and
SHA-256 `43594ce3239c33f3d475282b1cd90557622ab49bb4bc3d7e61df78f35657cd82`.
The installed image's executable audit passes in
`build/file-write-main-gen2-selfhost-audit`. The independent two-generation
comparison passes in `build/file-write-main-native-generations.json`: all twelve
module bytes, the flat kernel and boot area match exactly; both volume allocation
maps match reachable extents. Generation-two disk SHA-256 is
`babfe40f75ca83eda4c2b7bbeaf53821e112f83b0e43f601c03b84cc2f090fe2`.
Whole disk hashes differ, so reproducibility here is the verified executable and
boot artifacts, not identical whole-volume bytes. BIOS loading still has only
120 bytes of spare flat payload capacity; capacity redesign and remaining public
API compatibility/release gates are still open.

Resident implementation has begun in the isolated main-only checkout
`build/file-resident-prototype`, based on the corrected FileRead/FileFind source.
It adds mounted-service shared entries owning names and stored bytes in the
private heap, exact/alternate cached reads returning fresh owned buffers, and
write-driven replacement/removal. Compressed entries retain stored archive bytes
and expand for ordinary reads. Cross construction has started in that checkout's
`build/file-resident-write-cache`; no passing build or runtime result is claimed.
Cold disk population, explicit service-lifetime cleanup, allocation/failed-write
semantics, cache compatibility across raw/internal consumers and updated ABI
qualification remain required. This prototype is not promoted to main.

Main's fully native generation-two archive replacement qualification passes in
`build/file-write-main-gen2-native-archive-parity/result.json`: 22 commands on
8 MiB `486,-fpu`, exact original archive bytes across all eight fixture classes,
exact VGA and independently valid filesystem allocation. Startup is 35.434
seconds. The full native workstation run remains pending.

The resident prototype's first cross-build stopped before guest compilation
because its fresh checkout lacked `build/rebuild-test/result.json`. Its own
original two-generation bootstrap rebuild is now running. Internal raw reads
are kept on the disk path instead of inheriting public cached-read attributes.
The prototype file-service ABI advances to 41 for the changed shared volume
layout. These changes have no runtime qualification yet.

The corrected ABI-40 FileFind candidate now passes its full workstation suite in
`build/public-file-find-rejection-workstation/result.json`: all 513 native
commands, exact VGA at every checkpoint, twenty document cycles with exact task
heap recovery, and unchanged source disk. Startup is 24.394 seconds on 8 MiB
`486,-fpu`; the explicit 60-second gate passes in
`build/public-file-find-rejection-workstation-budget.json`. Long-document
navigation-to-VGA is 0.258 seconds. This qualifies the corrected source image
`d10e8a3cdc4e46e39264f1e5d0e89ae9f279885d8e73344245151556f8e151b2`,
not the subsequent resident-cache prototype. Native retained rebuilding remains
running before installation/full native qualification and promotion.

Resident ABI-41 original bootstrap and cross construction now pass in the
isolated checkout. The cross kernel is 483184 bytes and the 386 boot instruction
audit passes. The strengthened resident public read/write oracle is running in
`build/public-file-resident-write-cache-green` against that image; the directory
name is prospective and no passing runtime result is claimed. Cold cache
population, lifecycle cleanup and full compatibility remain open.

The first resident-cache runtime reaches the resident write checkpoint but has
not produced the required successful answer. Source inspection identifies an
additional storage-layer gap: RedSea directory record validation rejects
attr 0x200 (`attr & 0x300`), and read/write/repair checks also reject resident
metadata. Thus accepting residence only in TaskFileWrite is insufficient:
publication may precede the failed post-write resolution. The next correction
must consistently admit resident regular-file metadata through directory
validation, reads, writes, repair and independent filesystem auditing, while
retaining rejection of deleted/unsupported bits. Verify the failed candidate's
persisted state before discarding it; do not assume an unsuccessful API return
means disk publication did not occur. Runtime result remains pending.

That first resident-cache run has now failed at the resident write checkpoint
with the recorded console timeout. Its preserved writable candidate contains
`/Probe/ReadResident.BIN` with attr 0xA00, size 4 and bytes `410042ff` (A, NUL,
B, 0xFF): publication happened before the failed post-write resolution.
Raw record inspection is saved in
`build/public-file-resident-write-cache-green/persisted-resident-record.json`.
The corrected isolated independent auditor also verifies the complete volume,
including that resident entry: 873 files, 17506 owned sectors and bitmap matching
reachable extents, saved in `persisted-volume-audit.json` beside that record.
This proves persisted state, not working public resident reads.

The isolated correction admits resident metadata while retaining deleted-bit
rejection in RedSea directory/read/write/repair guards. Its independent auditor
recognizes ordinary/resident and compressed/resident regular-file combinations
(0x800, 0xA00, 0xC00, 0xE00). Fresh original bootstrap passes and cross compilation
is running in `build/file-resident-metadata`; runtime qualification remains open.

The dated-filesystem corruption checker now accepts an explicit `--builder`
auditor and `--resident` fixture qualification. Against the isolated resident
auditor and preserved resident entry it passes all ten rejection cases in
`build/public-file-resident-write-cache-green/resident-corruption-audit.json`:
the existing unsupported-bit, noncontiguous, overlap, extent, bitmap and name
cases plus resident unsupported bits, missing contiguous storage, compressed
resident without contiguous storage and a deleted entry retaining live extents.
This demonstrates that admitting resident metadata preserves these independent
filesystem rejection checks. The corrected runtime has passed its resident
write checkpoint and reached the first cached-read check; no complete runtime
pass is claimed.

Corrected FileFind ABI-40 native retained rebuilding now passes all six modules
in `build/public-file-find-rejection-native-build/result.json`. Generated source
disk SHA-256 is
`3ee4c6be13690baeb2783208f48c1e5dd40777dc9b2bdcbb9d215bb56dbdc0cb`.
Retained installation and independent boot are running in
`build/public-file-find-rejection-native-install`; full native construction and
promotion remain pending.

The resident metadata correction's runtime failed at the first cached-read
checkpoint, after the resident write passed. The original oracle passes and
the source image is unchanged. Cache publication passed the raw mask 0x200 to
a Bool argument; the next isolated correction explicitly normalizes it with
`(attr&0x200)!=0`. Fresh bootstrap/cross rebuilding is running in
`build/file-resident-bool`. This is a source correction awaiting evidence that
it resolves the observed cached-read failure.

ABI-40 FileFind retained installation and independent boot now pass in
`build/public-file-find-rejection-native-install/result.json`, installed disk
SHA-256 `0224870ff3da5abf2019eb3a0fd8e3fcc33ef27af53201e89179f75b6da63bf4`.
Full twelve-module native construction/install is running in
`build/public-file-find-rejection-selfhost` with the verified build and install
reports supplied as provenance. Full native artifact audits and runtime
regressions remain necessary before promotion.

The resident boolean correction's original bootstrap, cross construction and
386 instruction audit pass; cross kernel remains 483184 bytes. The original
functional oracle and native resident contract are running in
`build/public-file-resident-bool-green`. The directory name does not imply a
passing result, and cold cache population/lifecycle compatibility remain open.

The normalized resident-cache flag now passes the complete write-populated
contract in `build/public-file-resident-bool-green/result.json`: 33 commands,
original oracle, exact VGA, independent filesystem audit, owned cached read
buffers, changed-byte resident replacement and changed-byte removal of residence.
The source image is unchanged. This does not establish cold cache population,
compressed residence or service-lifetime cleanup.

New `tools/test-i386-resident-cold-read.py` checks first disk-read attributes
0xA00 followed by cached-read attributes 0 and independently owned buffers. The
original oracle explicitly removes its write-populated Adam cache entry before
reading; it passes in `build/public-file-resident-cold-red/oracle/debug.log`.
The native run boots the preserved resident disk fixture with an empty cache;
its result is pending. Successful read-only qualification must also preserve
the entire candidate disk. This supplies the next contract before implementing
disk-populated caching.

Main's fully native generation-two workstation now passes all 513 commands,
exact VGA and twenty task heap-recovery cycles in
`build/file-write-main-gen2-native-workstation/result.json`. Startup is 35.190
seconds on 8 MiB `486,-fpu`; formal startup budget passes. Long-document update
is 0.258 seconds. Source disk remains unchanged. Combined with the exact two
native generations and native archive parity this qualifies those FileWrite
runtime/build paths, not the remaining API/release requirements.

The cold resident test failed at its first disk read, before its cached-read
expectation: FileRead.HC's ReadAll guard separately rejects resident bit 0x200.
That guard is now corrected in the isolated candidate. Cold population work
retains stored bytes before optional decompression, inserts resident entries in
the shared cache and preserves first-read disk attributes. Cache storage now
uses an explicitly retained mounted-service heap selected at file-service init,
instead of inheriting a potentially transient reader heap. The shared layout
and stored-byte loader contract advance the isolated file-service ABI to 42.
The initial rebuild was deliberately interrupted to include the newly found
ReadAll correction; the complete fresh bootstrap/cross build is now running in
`build/file-resident-cold`. Runtime parity and lifecycle cleanup remain open.

Corrected FileRead/FileFind ABI-40 now passes fully native twelve-module
construction, installation and independent 8 MiB boot in
`build/public-file-find-rejection-selfhost/result.json`. Installed executable
audit passes in `build/public-file-find-rejection-selfhost-audit`. Flat kernel
is 487312 bytes (112 bytes spare), SHA-256
`ba745336478c5ab39f80ed14f51224bcd6f1fb10c0806a5a540a114298422b59`.
Installed disk SHA-256 is
`0fcefcd645ddb173570245e58e0ab8f92a367649ae506fa5180ac68de0f20ecf`.
Native-image public FileFind edge/ownership/twenty mixed heap-cycle contract,
FileRead parent-search contract and full workstation requalification are running
in `build/public-file-find-native-contract`, `build/public-file-read-native-contract`
and `build/public-file-find-native-workstation`. These results are pending;
FileRead/FileFind remain isolated before promotion. Second-generation native
reproducibility for this source epoch and release gates are still required.

ABI-40 fully native public contracts now pass. FileRead parent search and
binary/compressed/owned/empty/missing behavior pass 27 commands in
`build/public-file-read-native-contract/result.json` (startup 34.786 seconds).
FileFind passes 36 commands in `build/public-file-find-native-contract/result.json`
with actual CDirEntry, named flags, edge cases and twenty mixed recovery cycles
(startup 34.888 seconds). Public task heap recovery is exact; private QMP
snapshots preserve used bytes 5368840 and allocation count 7080. Both contracts
pass exact VGA and independent filesystem checks and preserve their source image.
The native full workstation remains running. Second-generation retained rebuild
and exact installed-module comparison has started in
`build/public-file-find-gen2-native-build`; reproducibility is not assumed.

The ABI-42 cold-cache prototype's original bootstrap and cross/386 audits pass.
Its QEMU fixture session successfully writes a resident file and returns 42,
then exits. A fresh boot of that persisted image is undergoing the cold-read
contract in `build/public-file-resident-cold-green`; no cache contents survive
the preparation session. The original cold-read oracle passes. Runtime verdict
is pending, with compressed residency and lifetime cleanup still open.

ABI-42 cold ordinary resident reads now pass in
`build/public-file-resident-cold-green/result.json`: original functional oracle,
first disk attributes 0xA00 then cached attributes 0, independently owned buffers,
exact VGA, unchanged source image and unchanged entire candidate disk. The
fixture was written in a previous QEMU process, so this exercises an initially
empty cache. Compressed residence and shared lifetime cleanup remain open.

The cold resident checker gains `--compressed` for a 64-byte binary `.Z` fixture:
first disk attributes 0xE00, cached attributes 0x400, cached alternate-name reads,
NUL termination and fresh owned buffers. A compressed fixture preparation
session is running in `build/public-file-resident-compressed-fixture`; original
and native compressed qualification are pending. This checks stored archive
ownership plus expansion rather than assuming ordinary residence proves it.

Compressed resident fixture preparation passes, and the isolated independent
auditor rejects all ten metadata/extent/bitmap corruptions against that actual
compressed resident entry in
`build/public-file-resident-compressed-fixture/corruption-audit.json`.
The original compressed cold-read oracle passes; native expanded/cached/alternate
ownership checks are running in `build/public-file-resident-compressed-cold-green`.

The public FileRead checker adds `--resident-recovery` (requires `--resident`)
for twenty port-only create/update/read/remove cache cycles. It checks exact
public task heap recovery and uses the existing read-only QMP observer around
the cycle call to check private used bytes/allocation count. Original functional
oracle remains separate from allocator-accounting assertions. This qualification
is running in `build/public-file-resident-lifecycle-recovery`. It covers removal
of individual entries, not whole mounted-service teardown or allocation failure.

Compressed cold-cache runtime now passes in
`build/public-file-resident-compressed-cold-green/result.json`: original oracle,
first disk attr 0xE00 then cached attr 0x400, exact and alternate-name expansion
of the 64-byte binary fixture, owned buffers, exact VGA and byte-for-byte
unchanged candidate/source disks. This qualifies compressed cold reads for
that fixture, not larger dictionary/cache limits or failed allocations.

Resident entry lifecycle recovery passes in
`build/public-file-resident-lifecycle-recovery/result.json`: 37 commands, original
functional oracle, twenty create/update/read/remove cycles with exact public
task heap recovery, and private QMP used bytes 5365784/allocation count 7159
unchanged before/after. Startup is 25.050 seconds on 8 MiB `486,-fpu`; VGA and
independent filesystem audit pass, source image unchanged. This qualifies entry
removal recovery, not whole-service teardown or allocation-failure paths.
The ABI-42 full workstation suite is running in
`build/public-file-resident-workstation`; native retained rebuilding for this
exact source image is running in `build/public-file-resident-native-build`.
Neither result is assumed from the focused contracts.

The cold resident checker adds `--shared-lifetime`: a spawned child reads the
already populated cache and verifies independently owned buffers; after child
completion the parent changes its current directory and reads the same absolute
cached name again. The original functional oracle passes in
`build/public-file-resident-shared-lifetime/oracle/debug.log`. Native qualification
is running against the ABI-42 persisted fixture. This tests the shared Adam-style
lifetime across task and directory state changes; whole-service teardown and
allocation failure remain separate requirements.

The shared-lifetime native run passes its child-task cache/ownership check but
fails at `Cd("C:/Probe")`: guest frontend reports an undefined identifier.
Public Cd declaration/export compatibility is therefore a prerequisite for
the directory-state part of this test; this failure is not evidence of cache
loss during directory replacement. The complete test remains failing.

The cold checker also gains `--hash-visible`: require the populated resident
file to be discoverable as CHashGeneric through public
HashFind(name,Fs->hash_table,HTT_FILE), with stored pointer and size. The original
oracle passes in `build/public-file-resident-hash-red/oracle/debug.log`; native
qualification is running. The current private mounted-service cache must not
be treated as complete original programming-model compatibility without this
public hash integration. Shared cache semantics and public Adam-style hash
ownership/removal need qualification, not just equivalent FileRead output.

Resident public-hash visibility now has a qualified native failure: original
oracle passes, earlier FileRead/ownership checks pass, then the run times out
at ColdHash("C:/Probe/ReadResident.BIN"). The current private cache does not
publish HTT_FILE entries in the public task hash-table chain. Public cache
integration remains an original programming-model requirement before promotion.

New `tools/test-i386-public-cd.py` provides the Cd implementation contract.
Original oracle passes relative/parent/empty/dot paths, partial path progress
on failure and nested make_dirs. Writes following those changes must be found
in exact expected directories by the independent disk walker. The native run
is pending in `build/public-cd-red`. Default home, drive changes and broader
error compatibility remain separate tests; do not replace original partial
progress with an assumed all-or-nothing directory commit.

The public Cd native contract now fails at the missing Cd call after setup,
matching the earlier shared-cache directory test. Implementation has begun in
the isolated main-only `build/file-cd-prototype`, preserving the ABI-42 resident
source used by live qualification runs. The candidate adds a file-service Cd
callback and public _CD export (file ABI 43), walks and validates components
in order, optionally creates missing directories, and commits the last valid
directory even when a later component fails. Nested filesystem borrowing is
balanced before replacing task directory state. Fresh original bootstrap and
cross construction are running in that checkout. This code is unqualified;
home aliases, whitespace/control handling, public task-field consistency,
drive/error behavior and heap recovery require additional contracts before
promotion. No partial source implementation closes the original Cd requirement.

The Cd checker adds `--task-fields`: public Fs->cur_dir must match each
successful path change and the last valid directory after failure. The original
oracle passes in `build/public-cd-task-fields-red/oracle/debug.log`. Native run
against the pre-Cd image is pending; the existing undefined Cd red already
isolates the missing API. The new assertion prevents a private-only directory
update from being mistaken for original public task-record compatibility.
The Cd candidate's original bootstrap passes and cross module generation is
running; no native behavior is qualified yet.

Public FileRead/FileFind ABI-40 is promoted to main after native public contracts
and full 513-command workstation qualification. Native startup is 35.179 seconds,
long-document update 0.265 seconds and formal startup budget passes. Main's fresh
original bootstrap and cross/386 audits pass in `build/file-read-find-main`;
`build/file-read-find-main-artifact-comparison.json` proves all twelve modules
and Kernel32.BIN exactly match the qualified corrected prototype. This includes
shared original CDirEntry/flags, owned public FileRead buffers, FileFind full_name
ownership and early-rejection output preservation. Resident caching/Cd remain
isolated. Second-generation FileRead/FileFind native qualification is pending;
promotion does not close remaining API or release requirements.

The isolated Cd candidate's original bootstrap/cross/386 audits pass. Ordinary
Cd contract passes sixteen commands; strengthened public task-field contract
passes twenty-four in `build/public-cd-task-fields-candidate/result.json`, startup
27.319 seconds on 8 MiB no-FPU QEMU. Public Fs->cur_dir matches successful and
partially failed path changes, exact VGA and persisted directory/write audit pass.
Home/drive/error compatibility, recovery cycles and broad/native qualification
remain open before Cd promotion.

Promoted FileRead/FileFind second-generation retained rebuilding passes in
`build/public-file-find-gen2-native-build/result.json`: all six retained modules
are byte-identical to the first native installation. Generated source disk
SHA-256 `bbd4a018f21f567ebc6df1c87b99887145cc2351706adfed2e860481fb1efcdc`.
Generation-two installation/boot checks are running in
`build/public-file-find-gen2-native-install`; complete twelve-module/flat/boot
comparison remains pending.

The Cd checker gains `--special-paths`: default/NULL/home paths plus original
whitespace/control trimming. Original oracle passes in
`build/public-cd-special-red/oracle/debug.log`; native behavior is running against
the current candidate. Home may differ between environments, so these checks
require successful API behavior rather than assuming an identical configured
home directory. The task-field contract still checks explicit path targets.

Resident ABI-42 full workstation passes all 513 native commands, exact VGA and
twenty task heap-recovery cycles in `build/public-file-resident-workstation/result.json`.
Startup is 27.311 seconds on 8 MiB `486,-fpu`; formal budget passes and source
image is unchanged. Long-document update is 0.265 seconds. This does not waive
the failing public HTT_FILE cache visibility requirement; resident code remains
isolated pending programming-model integration and native qualification.

Promoted FileRead/FileFind generation-two retained installation and independent
boot pass in `build/public-file-find-gen2-native-install/result.json`, disk SHA-256
`1d39cf80ef11c0a1e78c22d04ea9471c5241a2889f37ae7b63d2a9f85822afe1`.
Full native construction/install is running in `build/public-file-find-gen2-selfhost`.
Complete generation comparison remains pending.

Cd special-path correction is isolated in `build/file-cd-special-prototype`:
expand home components using the configured home directory, trim leading and
trailing whitespace with the existing bitmap and remove non-whitespace control
bytes before walking components. Path capacity includes home expansion; the
temporary cleaned buffer is released. Fresh bootstrap/cross construction is
running there. The prior candidate's Cd("~") checkpoint remains the pending
special-path runtime failure; these source changes are not yet runtime-qualified.

The prior Cd candidate's special-path run now fails at Cd("~"), after default
and NULL-home calls succeed. The corrected home/trimming checkout passes fresh
original bootstrap, cross construction and 386 instruction audit (483184-byte
cross kernel). Combined special-path and public task-field qualification is
running in `build/public-cd-special-green`; no runtime pass is claimed.

Resident ABI-42 native retained rebuilding passes all six modules in
`build/public-file-resident-native-build/result.json`, generated source disk
SHA-256 `3618973caa8bfe32611f033ae04324e1f55392c090277f39f8544808bb2416a1`.
Retained installation/independent boot checks are running in
`build/public-file-resident-native-install`. Native construction and public
hash-model compatibility remain open; private-cache contract success is not
complete resident support.

Corrected Cd special paths and public task fields pass thirty-two commands in
`build/public-cd-special-green/result.json`, startup 25.701 seconds on 8 MiB
no-FPU QEMU. Original oracle, exact VGA and independent persisted writes/paths
audit pass. This includes configured default/NULL/home handling, whitespace and
control trimming plus the earlier partial-failure/mkdir contracts. Drive/error
boundaries, recovery cycles and broad/native construction remain open.

Resident native retained installation and independent boot pass in
`build/public-file-resident-native-install/result.json`, installed disk SHA-256
`3420d94acdcbe04b6806dc9163bc4153e72647cf8890e6729e29197886d50b9d`.
Full native construction/install is running in `build/public-file-resident-selfhost`.

Public resident hash qualification is strengthened: MHeapCtrl must recognize
the CHashGeneric entry, its name and stored-byte buffer. Merely publishing
private heap pointers would violate original allocation/removal ownership.
The strengthened oracle/native test is running in
`build/public-file-resident-hash-ownership-red`. Public cache lookup and removal
must share one authoritative ownership model; the current private cache is
still unpromoted despite its narrower passing read contracts.

Promoted FileRead/FileFind ABI-40 second-generation full native construction,
installation and independent 8 MiB boot now pass. Installed executable audit
passes in `build/public-file-find-gen2-selfhost-audit`; independent generation
comparison passes in `build/public-file-find-native-generations.json`: twelve
modules, 487312-byte flat kernel and boot area are identical, both volumes have
valid reachable-extent bitmaps. Flat SHA-256 remains
`ba745336478c5ab39f80ed14f51224bcd6f1fb10c0806a5a540a114298422b59`.
Second disk SHA-256 is
`f9f20d1723af29b08c92f80e5729f0c6528c0c46bafded44dc1f268365649d2c`;
whole disk bytes differ, so the reproduced artifacts are modules/flat/boot.
The strengthened resident public-hash ownership original oracle also passes;
its native verdict remains pending.

Resident ABI-42 full native construction/install/8 MiB boot passes in
`build/public-file-resident-selfhost/result.json`; installed executable audit
passes in `build/public-file-resident-selfhost-audit`. Flat kernel is 487320
bytes (104 bytes spare), SHA-256
`11c95cab33da1a1ef5acf765e055ae3b0b94d81cf503026fb893d874299fbb40`.
Public hash-model compatibility still blocks resident promotion.

The stronger hash-ownership run reached BAD PUBLIC MEMORY at ColdHash. Its
checker now explicitly returns FALSE for a missing entry/buffer before calling
MHeapCtrl; the guarded original oracle passes and native qualification is
running in `build/public-file-resident-hash-guarded-red`. Do not infer valid
public ownership from that earlier kernel failure.

Public cache restructuring begins in `build/file-resident-public-prototype`:
file-service ABI 44 adds stored-byte reading with original alternate/parent
lookup and archive expansion callbacks. This candidate removes private cache
lookup/publication from the file worker, so a future public hash cache will be
authoritative rather than a mirror with independent stale entries. Public
root-owned cache records/names/buffers, read/write wrappers, removal coherence
and runtime qualification are still to implement. No build/pass is claimed for
this intermediate source. Cd full workstation is running separately against
its qualified focused-contract source.

Resident public-hash ownership follow-up (2026-10-05): the guarded original
oracle passes; the ABI-42 native candidate fails at ColdHash without changing
the source disk (`build/public-file-resident-hash-guarded-red/result.json`).
This confirms the public hash contract remains a promotion blocker.

The isolated ABI-44 candidate now implements root-task public allocations for
CHashGeneric records, names and stored bytes, public hash lookup/publication,
replacement/removal and caller-owned decoded FileRead buffers. Its first
bootstrap passes, but cross compilation rejects an undeclared Gs expression;
that expression now uses Fs->gs and a fresh bootstrap/cross-build is running.
No ABI-44 runtime qualification or promotion is claimed. Parent-resolution
cache keys, failed-write behavior and removal/exception coherence still need
qualification against original TempleOS.

The cold-read test adds --hash-removal (requires --hash-visible): locate the
entry's owning table in the public hash chain, remove it with HashRemDel, then
require disk attributes on the first read, cached attributes on the next, and
new public heap-owned cache objects. The original oracle reports DONE cold
resident in `build/public-file-resident-hash-removal-owner-red/oracle/debug.log`;
the native run remains pending. A preliminary attempt removing from Fs's own
table failed the original oracle because the entry belongs to an ancestor;
the test now explicitly locates the owning table. Python compilation, CLI
parsing and diff whitespace checks pass. Cd's full workstation run remains
live; its focused 32-command result is still the qualified boundary.

Public-cache candidate build and bounded removal test (2026-10-05):
The removal oracle passes, but its initial native helper exceeded the 255-byte
interactive input limit. Split owner-table lookup and removal into separate
functions and add a preflight helper-length check before oracle construction.
The bounded oracle passes; the ABI-42 candidate fails while defining ColdRemove
(`build/public-file-resident-hash-removal-bounded-red`), before exercising
removal. Public HashRemDel is absent from the port's current public hash API,
so this is an additional compatibility obligation, not evidence about removal
behavior. Neither failing run modifies the source disk.

The corrected ABI-44 candidate completes fresh original bootstrap and cross
build in `build/file-resident-public-prototype/build/file-resident-public`.
386 boot audit passes (96 BIOS and 33 protected-mode instructions); kernel is
483192 bytes, SHA-256
`63641eed250557faca96a4ceb8c19cf02c7ac063712d611b8ed3d7d9bd99926f`.
This is build evidence only. Resident read/write plus twenty-cycle public/private
heap recovery is running in `build/public-file-resident-public-hash-recovery`.
A separate no-FPU 8 MiB fixture-population boot passes (25.147 seconds), writing
resident binary data through public FileWrite; fresh cold reads and public
entry/name/data ownership qualification are now running in
`build/public-file-resident-public-hash-cold`. No runtime/hash ownership pass
or OS source promotion is claimed yet. Cd workstation remains live.

Resident cache correction and Cd regression qualification (2026-10-05):
ABI-44 first resident read/write recovery and cold hash runs fail at the first
read. The name service requires a non-NULL extension; wrappers passed NULL
so normalization returned NULL. Both wrappers now pass an empty extension.
The earlier build-only result is not a runtime pass.

The candidate implements public HashRemDel through MemoryRuntime: select the
requested instance in one table, require exact entry identity, unlink with IRQs
saved, then use the existing public hash destructor. It adds the public default
instance declaration and one memory export. First cross-build catches missing
HashBucketFind imports; explicit bucket/single-table imports are now present
and a fresh bootstrap/cross-build is running. No removal-runtime pass is
claimed. Cold removal tests additionally require instances zero and two to
fail without deleting the sole entry; the original oracle passes in
`build/public-file-resident-hash-instance-red/oracle/debug.log`.

The complete unpromoted source is archived as
`docs/patches/i386-public-resident-candidate.patch`, relative to
`1705dbae188ad875aa526daaedc424317cae467a`; git apply --check also passes
against current main. This patch preserves reviewable/recoverable work without
qualifying it as the main OS implementation. Parent cache keys, failure and
allocation rollback, lifecycle, public removal and native builds remain gates.

Cd special-path candidate passes all 513 workstation commands in
`build/public-cd-special-workstation/result.json`: 24.645-second startup,
0.255-second long-document response, exact VGA checkpoints, twenty document
cycles with exact task heap recovery, filesystem audit and unchanged source
disk on no-FPU 8 MiB QEMU. Source disk SHA-256
`d71a5b36522a60960b9fe24f69c85dedbf753bae8732606f408331fc0f13955e`.
No private-heap recovery assertion is inferred from the metadata-only observer.
Retained native construction starts in `build/public-cd-special-native-build`;
drive/error and Cd-specific recovery qualification remains open.

Cold-fixture automation and module binding correction (2026-10-05):
Cold resident tests add --prepare-fixture: populate only the disposable image
through public FileWrite in a separate no-FPU boot, then qualify a fresh boot.
Record preparation and cold-fixture SHA-256; require read-only cold operations
to preserve that prepared baseline and always preserve the supplied source.
The original oracle remains independent. Python compilation and CLI pass.

The imported-helper removal candidate cross-builds and passes the instruction
audit but fails at runtime MemoryRuntime loading: HashBucketFind and
HashSingleTableFind are not published kernel bindings. The new cold fixture
and recovery runs therefore fail before any cache behavior can be qualified.
Do not treat a cross-build/layout pass as module binding or runtime evidence.
The correction uses the already-published HashFind through a stack copy of the
table with next=NULL; its body still references the original buckets, preserving
single-table instance/use-counter behavior without changing the shared chain.
After exact identity selection, unlink from that table and call the existing
destructor with original IRQ restoration order. Removed the extra imports and
auditor allowances. The archived candidate patch reflects this correction;
git apply --check passes. Fresh bootstrap/cross-build is running in
`build/file-resident-public-prototype/build/file-resident-public-removal-scoped`.
Runtime/hash/removal/recovery qualification remains open. Cd native retained
construction is still live at its compiler-module command.

Scoped removal build and empty resident oracle (2026-10-05):
Fresh bootstrap/cross-build completes for the stack-view removal candidate
(`build/file-resident-public-prototype/build/file-resident-public-removal-scoped`).
Instruction audit passes; kernel 483192 bytes; whole source disk SHA-256
`e3dc26aa7e6c58951b54d4df45524e68d1843fd0c204690df33e48e37b24fba1`.
The source disk hash distinguishes the revised retained modules from the
earlier candidate despite the unchanged early flat-kernel hash.

Cold tests now support --empty: zero-length resident write succeeds with the
original -1 return, first disk attributes then cached attributes, independently
owned zero-terminated buffers, public cache visibility and instance/removal
checks. Zero stored size is valid; the public hash checker now rejects negative
sizes rather than zero. --empty rejects compressed/shared-lifetime combinations
that lack corresponding expectations. The empty original oracle passes.
Python compilation/CLI and diff whitespace checks pass.

Scoped candidate boots and passes separate fixture preparation for ordinary,
compressed and empty resident files on no-FPU 8 MiB QEMU. All cold runs fail
at cached attributes after a successful initial disk read; the write-populated
recovery run also fails at its cached read before the twenty-cycle gate.
Results: `build/public-resident-scoped-cold`, `...-packed-cold`, `...-empty-cold`,
`...-recovery`. Source images remain unchanged. These are failures, not cache
ownership/removal passes. A diagnostic in `build/public-resident-scoped-diagnostic`
confirms first read size 4 and attr 2560, but HashFind of the resident filename
in Fs's public table chain returns false. Publication visibility is still open.

Main's original bootstrap has been restored and passes in
`build/main-bootstrap-restored.log`. Cd native construction remains live and
has advanced from CompilerRuntime to CompilerProbe. Neither resident nor Cd
OS source is promoted by this update.

Publication tracing and sharper cold gate (2026-10-05):
When --hash-visible is selected, cold tests now check entry/name/data public
ownership immediately after the first disk read, before checking cached
attributes. Retain the later ownership check as well. The revised original
oracle passes in `build/public-resident-publication-red/oracle/debug.log`;
the old candidate reaches the new ColdHash checkpoint, exposing publication
independently of later cached attribute behavior. Python compilation and
diff checks pass. The top status now separates qualified main, unpromoted Cd
and the failing resident candidate rather than leaving current work buried
only in the chronological record.

Temporary debug-port instrumentation is isolated in the prototype and is not
part of the archived candidate patch or promoted OS. Its fresh bootstrap/cross
build passes. Fixture preparation logs show CACHE LOOKUP for the expected
filename returning NULL, followed by CACHE PUT for the same filename and size
4. This proves the write wrapper invokes publication, not that insertion succeeds.
A second trace adds created/owner pointers and immediate post-insertion lookup;
its fresh build is running in `build/file-resident-public-prototype/build/
file-resident-public-trace2`. Further runtime evidence is required.

A diagnostic expecting Fs->gs->seth_task==Fs returns false. The console task
need not equal the persistent public root, so that result alone does not prove
wrong ownership; do not reinterpret it as a cache contract failure. Cd's native
retained job remains live and has advanced through the compiler/console/file
commands to MemoryRuntime. The full release objective remains incomplete.

Public FileRead binding correction and Cd native installation (2026-10-05):
The cache failure is traced to a macro collision: FormatterRuntime defines
FileRead as NativeFormatterFileRead before ConsoleBind takes &FileRead. Thus
_FILE_READ selects the formatter's disk-only helper instead of the new public
cache implementation. This also explains why read-side trace hooks did not
appear while write-side CACHE PUT did. Do not attribute those failures to
cache insertion itself.

The candidate names its implementation NativePublicFileRead and explicitly
binds _FILE_READ to that function. NativeFormatterFileRead delegates to it,
sharing one public ownership/cache policy. Temporary trace instrumentation is
removed. Fresh bootstrap/cross-build and instruction audit pass in
`build/file-resident-public-prototype/build/file-resident-public-bound`; cold
public ownership/removal and write/read recovery tests are running.

Cold tests add --dotless and exact public cache-key expectations. Original
oracle passes in `build/public-resident-dotless-oracle-red/oracle/debug.log`.
Using an empty extension would append a period to a dotless name, so the next
candidate lets the name service normalize directly when extension=NULL and
public read/write wrappers use that mode. Explicit requested extensions retain
the existing path. Fresh build is running in `build/file-resident-public-exact-name`
under the isolated prototype. The archived patch contains explicit binding,
formatter delegation and exact-name normalization; git apply --check passes.
Runtime parity is still unproven, and no OS source promotion is claimed.

Cd's retained native build passes all six modules in
`build/public-cd-special-native-build/result.json`; retained installation and
independent boot pass in `build/public-cd-special-native-install/result.json`,
installed disk SHA-256
`75a4389c0d137428781f48b65e0d4275902131ae44d996056feeb444be813f2f`.
Full native construction/install starts in `build/public-cd-special-selfhost`,
using both retained provenance results. These native builds use KVM CPU 486
with FPU available; they do not establish the separate full no-FPU build gate.

Resident binding green and expanded heap/no-FPU gates (2026-10-05):
The explicit binding candidate passes `build/public-resident-bound-cold`: 18
commands, startup 25.754 seconds, public entry/name/data ownership, zero/two
instance rejection, public removal and disk repopulation, fresh caller-owned
buffers, exact VGA and unchanged source/prepared disk. Its resident write/read
recovery passes `build/public-resident-bound-recovery`: 37 commands, startup
25.757 seconds, changed-byte replacement/removal and twenty lifecycle rounds.
Caller used bytes and private allocator used 5378688/allocations 7169 recover
exactly. This is not a persistent public root-heap accounting assertion.

Strengthen the lifecycle gate to require unchanged used bytes for both Fs's
public data heap and Fs->gs->seth_task's persistent public data heap after twenty
rounds, retaining independent private allocator snapshots. The new helper is
219 bytes, within the native input limit; Python/diff checks pass. Fresh exact-
name candidate bootstrap/cross/instruction audit passes with source disk SHA-256
`b70758f2843d0b22cfbba6cea9d46633b96e156a3ddc478536c16b8a10cb3c21`.
Binary/compressed/dotless/empty cold ownership/removal contracts, strengthened
recovery and the 513-command workstation are running against that same image.
Do not extend the earlier passing scope to these pending results.

Start qualified main's retained native rebuilding under TCG CPU 486,-fpu in
`build/public-file-find-no-fpu-native-build`, all six providers and a 7200-second
per-command bound. This is a live full no-FPU build attempt, not a pass; previous
KVM builds with FPU available do not cover it. Cd full native construction is
still live and has reached boot-image installation. Release gates remain open.

Exact-name cold gates and persistent-root diagnostics (2026-10-05):
All exact-name cold ownership/removal gates pass on the same ABI-44 candidate:
`build/public-resident-exact-cold` (18 commands, startup 31.883 seconds),
`...-packed-cold` (20, 31.664), `...-dotless-cold` (18, 30.882),
`...-empty-cold` (18, 32.126). Each original oracle passes, public entry/name/data
allocations are recognized, removal rejects wrong instances and repopulates
from disk, VGA matches and source/prepared disk bytes remain unchanged.

Strengthened `build/public-resident-exact-recovery` fails at FindRecovery,
although the earlier caller/private-only recovery passed. Keep the stronger
gate. Diagnostic helpers now emit caller/root before/after counters through
the debug port and persist parsed observations even on failure. Real trace
in `build/public-resident-exact-root-heap-trace/behavior/debug.log` records
caller 1358816 -> 1358816 and root 0 -> 96 after twenty rounds. Regex extraction
of those actual bytes passes. A further run in
`build/public-resident-exact-root-before-trace` emits initial counters before
the loop, to distinguish remaining allocations from a saved-baseline problem.
No explanation or root-heap recovery pass is inferred yet. Each generated
helper fits 255 bytes; the loop helper is 222 bytes. Python/diff checks pass.

Cd full native construction/install/8 MiB boot passes in
`build/public-cd-special-selfhost/result.json`: flat 487320 bytes (104 bytes
spare), SHA-256
`c5b0a6b5ecf48e58cf46e2b506c269262067fa3a0c8119062f81f31e4414210f`,
target disk SHA-256
`d873e42fdc4aff88941dbddad678731d823fe94997b5fbde95ef3ec37d6ad3fa`.
Installed executable/boot/filesystem audit passes in
`build/public-cd-special-selfhost-audit`, using the target's twelve modules
and /Probe/GuestBoot.bin. The initial audit invocation used legacy Gen2 paths
and correctly rejected missing inputs; the successful audit uses the actual
installed artifact paths. Public-Cd broader drive/error/recovery parity,
resident root accounting and release requirements remain open. Main no-FPU
TCG native rebuilding and the exact-name 513-command workstation remain live.

Message-quiescent recovery and Adam public namespace (2026-10-05):
The before-loop trace confirms the zero root baseline is not a saved-variable
artifact. Remaining allocation is a queued job: RESIDENT JOBS reports job code
1 (JOBT_MSG), message code 3 (MSG_KEY_UP), MSize2 96. MemoryMessageNew allocates
these records from memory_root; the delayed Enter release accounts for the
root heap delta. This was input-harness activity, not established cache leakage.

Resident recovery now validates each pending job is root-owned and only a
MSG_KEY_UP message before consuming it. Unexpected jobs fail rather than being
discarded. Quiesce at both snapshot boundaries; retain exact used-byte equality
for caller and persistent root plus independent private snapshots. All helper
lines fit the 255-byte limit after splitting reporting from validation.
`build/public-resident-exact-quiescent-recovery/result.json` passes 45 commands:
caller 1361744 -> 1361744, root 0 -> 0, private allocator recovery pass, VGA
match, independent persisted-byte/volume audit and unchanged source disk.

Exact-name full workstation passes all 513 commands in
`build/public-resident-exact-workstation/result.json`: no-FPU 8 MiB, startup
33.007 seconds, long-document update 0.264 seconds, exact VGA and twenty document
cycles with exact task heap recovery; source disk remains unchanged.

Cold tests add --adam-root, requiring --hash-visible. Original oracle passes
and native ABI-44 image fails while declaring ColdAdamOwn because adam_task is
absent from its public namespace. The candidate now exposes that original
global as a data export initialized to MemoryBind's persistent root task.
Fresh bootstrap/cross/386 audit passes in
`build/file-resident-public-prototype/build/file-resident-public-adam`.
Binary/compressed cold tests require cache entry/name/buffer ownership by
adam_task->data_heap and lookup via adam_task->hash_table; they are running in
`build/public-resident-adam-cold` and `...-packed-cold`. No alias runtime pass
is claimed yet. The archived patch includes the additive public data export
and passes git apply --check. Full no-FPU main retained construction remains
live at CompilerRuntime. Broader original-model/release gates remain open.

Public cache mutation and compiler include contract (2026-10-05):
Adam namespace/ownership cold contracts pass 22 binary and 24 compressed
commands. The new --cache-mutation contract passes the original oracle and
28 native commands in build/public-resident-adam-mutation: edit public
HTT_FILE bytes, read the edit through FileRead, restore bytes, remove/repopulate
cache, exact VGA; source and cold candidate disk bytes remain unchanged.
Startup is 24.502 seconds on the no-FPU 8 MiB configuration.

New tools/test-i386-resident-include.py establishes an original-model red gate.
Use --builder build/file-resident-public-prototype/tools/build-i386-kernel.py
for the ABI-44 resident metadata auditor. The original oracle passes with a
heap-owned FileWrite buffer. Native public cache mutation and FileRead pass,
but #include produces 42 from persisted RootCacheValue=6*7; instead of 49
from the edited resident buffer. Checkpoint startup-command-07 and its VGA
capture establish the value; this is not merely a timeout inference.
Independent RedSea audit passes (16 directories, 871 files, 17544 owned
sectors); persisted source is unchanged and the input image is unchanged.
Evidence: build/public-resident-include-owned-red/result.json. The earlier
literal-buffer oracle was invalid; use StrNew to honor original FileWrite
buffer ownership before drawing compatibility conclusions.

Next architectural gate: compiler includes and document reads must share the
canonical original public resident cache, with proper private/public heap
conversion and no recursion through the public disk fallback. Keep this red
contract until the bridge produces the original result; then requalify cache
ownership/recovery, full workstation, native construction and generations.
The current public-cache candidate remains unpromoted. Both retained builders
are confirmed live: main 486,-fpu TCG is still compiling CompilerRuntime;
Adam candidate KVM is compiling ConsoleRuntime. Neither is a completed gate.

Canonical reader bridge candidate (2026-10-05):
Archived docs/patches/i386-public-resident-include-candidate.patch separately
from the qualified ABI-44 patch. File services advance to ABI 45 with a
public-reader installation callback. Console binding installs a bridge that
uses NativePublicFileRead and copies its owned public buffer into the requested
private heap. Ordinary task reads and task compiler includes consult this
callback; raw/stored reads keep the disk path to prevent recursion. Includes
retain default-extension and absolute-name normalization. Early bootstrap
uses the existing disk implementation until the callback is installed.

The patch applies cleanly to main; it remains unpromoted and unverified at
runtime. Fresh prototype original bootstrap and dependent cross construction
are running. Main original bootstrap has completed again successfully.
Required gates include the existing red include contract, document cache
mutation, allocation/exception cleanup, child-task ownership, recovery, full
workstation and native generations. Callback exception unwinding through
borrowed task file state needs particular qualification before promotion.

Compiler include parity green on ABI-45 candidate (2026-10-05):
Fresh original bootstrap and cross/386 audit pass; kernel remains 483192
bytes. build/public-resident-include-bridge/result.json passes the original
oracle and all nine native commands on 486,-fpu / 8 MiB. The previous disk
result 42 becomes the required cache result 49. Exact VGA passes; independent
RedSea audit passes with 16 directories, 871 files and 17558 owned sectors.
Persisted source remains RootCacheValue=6*7; and input disk is unchanged.
Candidate disk SHA256:
334b339b1006569f58413a497abfa6c9c2f24f0a0928081ae94da2a371439ead.

The include tool now offers --document: original and native DocRead/DocSave
must expose the edited character before compiling the include. Original
oracle passes; native qualification is running in
build/public-resident-include-document-bridge. The full no-FPU workstation
is running in build/public-resident-include-workstation. These are pending,
not promotion evidence yet.

The earlier Adam ABI-44 retained native build has completed all six modules:
build/public-resident-adam-native-build/result.json passes, source disk SHA
 ec523b3327c1c9684c7bf375affaf14ca517e25a28cf06bec0de3521b46468f5.
This is a KVM retained build, not the full no-FPU gate or ABI-45 requalification.
Main's no-FPU TCG retained process remains live and advances through compiler
module output. Cache candidate promotion remains gated on recovery, exceptions,
child ownership, full workstation and native reproducibility/install evidence.

DolDoc cache parity also passes: build/public-resident-include-document-bridge/result.json reports original oracle and 11 native no-FPU / 8 MiB commands, exact VGA, unchanged persisted fixture/input disk and valid RedSea bitmap. DocRead/DocSave sees the same edited cache character as FileRead and compiler include. Full workstation remains running.

ABI-45 recovery/native qualification started (2026-10-05):
The public FileRead contract tool adds --builder, defaulting to main's image
auditor. Use the candidate builder for resident attributes; this selects the
independent metadata walker without changing allocator recovery requirements.
Python compilation and whitespace checks pass. Original FileRead oracle passes
for the fresh ABI-45 recovery run. Native 45-command twenty-cycle caller/root/
private recovery is live in build/public-resident-include-recovery.
The full no-FPU workstation advances through graphics, math and definitions
in build/public-resident-include-workstation. The ABI-45 KVM retained six-module
build is live in build/public-resident-include-native-build. Main's separate
no-FPU TCG retained build also remains live with compiler function progress.
All three candidate runs are pending; no promotion or full release claim.

Compiler cache deletion/repopulation contract (2026-10-05):
The include parity tool adds --removal. After the initial public mutation and
cache-backed include result 49, HashRemDel removes the original public entry;
a second include must yield disk result 42 and publish a new HTT_FILE entry.
Mutating and reading that new entry proves publication and shared ownership
rather than only a disk fallback. --document remains composable.
Original TempleOS passes this extended oracle with --document --removal;
the native 17-command run is live in build/public-resident-include-removal.
Persisted fixture equality, input immutability and the independent RedSea
bitmap audit remain mandatory. No native pass is claimed yet. ABI-45 exact
45-command recovery, full workstation and retained native construction remain
live; their handles/checkpoints were revalidated without restarting them.

ABI-45 exact resident recovery now passes: build/public-resident-include-recovery/result.json reports all 45 commands and twenty resident create/update/remove cycles, exact caller/root public heap recovery and independent private allocator snapshots, VGA parity, persisted raw/compressed/replacement bytes, valid filesystem and unchanged source disk. This qualifies the bridge epoch for this recovery scope; include-specific exception/child lifetime and full native release gates remain open.

Cache removal and default-extension qualification (2026-10-05):
build/public-resident-include-removal/result.json passes all 17 commands on
486,-fpu / 8 MiB: mutation reaches FileRead, DocRead and includes; HashRemDel
forces disk result 42; the include republishes HTT_FILE and fresh public
mutation/read verifies it. Exact VGA, unchanged persisted source/input image
and independent bitmap audit pass. Startup is 28.220 seconds.

The include tool adds --default-extension. Only compiler include names drop
.HC; write, cache lookup, document read and disk audit still use the exact
physical filename. This tests original HC.Z default plus alternate resolution
rather than accidentally changing the fixture. Original oracle passes with
--document --removal --default-extension; native run is live in
build/public-resident-include-default. Runtime pass remains pending.

Source audit of exception cleanup identifies a concrete promotion requirement:
I386LexTaskFileInclude borrows file state (busy and lifetime_refs incremented)
before invoking the installed callback. NativePublicFileRead can throw OutMem
from public allocations, so an exception may bypass release and IRQ restore.
Add a deliberate allocation-failure include test with restored cache metadata,
then require exact private/public recovery and subsequent directory-state
replacement/task exit before accepting a fix. The private read ABI returns
failure pointers/booleans; choose cleanup/propagation behavior to preserve the
original externally visible error while keeping state releasable. Do not
promote the current happy-path bridge on parity/recovery greens alone.
Full workstation and native builders remain live and progressing.

Default-extension native qualification also passes all 17 no-FPU / 8 MiB commands: build/public-resident-include-default/result.json. Exact VGA, original oracle, persisted source/input immutability and independent filesystem audit pass. Both initial cache resolution and removal/disk repopulation work through the bare compiler include name.

Native include allocation-failure regression gate (2026-10-05):
The include tool adds --allocation-failure, explicitly native-only after the
original functional oracle. Set the resident entry byte count to 0x100000000
to force public allocation rejection without copying nonexistent data; require
Out of memory from include, restore count 19, require borrowed file-state busy
zero and successful cached include 49. Before injection the test checks busy
zero, sizeof(CTask)==992 and observer file_state offset 1052. The tool validates
on-image Scheduler/Context/TaskFiles source layouts before using this private
ABI observer and records their SHA256s; unknown layouts require review.
Current ABI-45 layout validation and Python compilation pass. The original
normal include oracle passes; the native 19-command failure run is live in
build/public-resident-include-oom-red, currently declaring its observer helper.
The live run predates the source fingerprint guard; its same disk layout was
independently validated afterwards. This is not a verified red result yet.
Full workstation and both retained builders are revalidated live; the candidate
remains unpromoted until exception cleanup and the other open gates qualify.

First allocation-failure run is terminal at observer declaration: VGA shows Error: Missing ) for unary dereference/cast syntax. Fault injection never executed, so this is a harness defect, not OS exception evidence. Helper now assigns the cast pointer separately and reads b[0]. Python/whitespace checks pass; corrected fingerprint-guarded run is live in build/public-resident-include-oom-observer-fixed.

Exception-preserving reader cleanup candidate (2026-10-05):
Second failure test also terminates before injection with Missing ) in the
observer helper. It does not prove OS leakage. The helper now uses typed local
assignment and U32 pointer arithmetic, avoiding compound casts entirely.
Corrected run is live in build/public-resident-include-oom-typed-observer;
on-image private-layout fingerprint validation passes.

The source-audited callback escape is addressed in a separately archived
candidate: docs/patches/i386-public-resident-cleanup-candidate.patch. Ordinary
private reads catch callback exceptions, free an owned absolute name and
restore interrupt flags before rethrowing. Compiler include catches at the
callback boundary, frees normalized/default-extension names, releases borrowed
file state, restores flags and rethrows the original exception. The externally
visible OutMem remains an exception; it is not translated into missing file.
FileRuntime adds the established retained SysTry/SysUntry/throw imports and
its independent module import contract is updated explicitly. ABI remains 45
because the service layout is unchanged. Patch applies cleanly to main;
Python/whitespace checks pass. Candidate original bootstrap and a dependent
cross build are running; no compiled/runtime pass for this cleanup is claimed.
An inadvertently started main bootstrap is allowed to finish separately; it
cannot qualify candidate edits. Happy-path bridge tests/builds continue from
their immutable source disks and are not invalidated or restarted by this edit.

Allocation failure now reaches a verified OS red gate (2026-10-05):
build/public-resident-include-oom-typed-observer/result.json is terminal fail
at startup-command-15 (include after CodeSize(0x100000000)). Typed observer
compiles, layout/initial busy checks pass, and original normal oracle passes.
Debug log repeatedly reports THROW 0000000000000000, then UNHANDLED and FAIL
native kernel. Metadata restoration and borrow-zero check never execute, so
this proves exception propagation failure, not an observed borrow-count leak.
Persisted source/input immutability and independent volume audit still pass.

ExceptRuntime.throw(0) dispatches a new zero exception. ExceptDispatch invokes
the selected catch and propagates the original exception when catch_except
remains FALSE after that catch returns. Bare throw inside cache cleanup catches
therefore redispatches the current catch and loops. Correct these newly added
cache catches and private-reader cleanup to return with catch_except FALSE,
letting the established dispatcher pop them and preserve OutMem. Do not alter
the global throw API to reinterpret zero or hide errors as missing files.
The first cleanup candidate's bootstrap passes and cross construction is live;
it still contains the invalid bare rethrow and is not a valid fix yet. Keep its
snapshot stable until that build completes, then create the propagation-correct
source epoch and rerun this red gate before broad qualification.

Propagation-correct candidate implemented (2026-10-05):
The first cleanup cross build finishes successfully (386 instruction audit,
483192-byte kernel), but it remains semantically invalid at rethrow boundaries.
New docs/patches/i386-public-resident-propagation-candidate.patch replaces bare
throw in newly added resident allocation/copy/public read/write cleanup catches
with rejected catches (catch_except FALSE). Private normal-read and include
cleanup also reject their catches after freeing names, releasing borrow and
restoring flags. The established dispatcher preserves the original OutMem and
selects outer handlers. FileRuntime requires SysTry/SysUntry, with unused throw
import removed from its explicit contract. No global exception semantics change.
Patch applies cleanly to main; whitespace checks pass. Fresh original candidate
bootstrap is running in build/resident-public-propagation-bootstrap.log.
Required next actions: cross build, rerun the verified allocation-failure gate,
then exact private/public recovery, child/directory replacement and broader
workstation/native generation qualification. No runtime fix claimed yet.

Propagation candidate build qualified; stronger fault gate started (2026-10-05):
Fresh original bootstrap passes, then cross construction and 386 instruction
audit pass in build/file-resident-public-prototype/build/file-resident-public-propagation.
The kernel remains 483192 bytes; this verifies compilation/import binding,
not yet exception behavior. Candidate disk SHA256: dc949c634723f7bef678873fae34bf683bb9a807fcd5f52a0c1b6ad22f166962.
The fault gate additionally records task lifetime_refs before injection and
requires exact equality afterward, alongside file-state busy zero. Its observer
class/layout guard includes file_clone/file_destroy/lifetime_refs, with runtime
offset 1064 required. This checks reaping-blocking references as well as borrowed
state. Python compilation and on-image fingerprint validation pass.
Fresh native fault run is live in build/public-resident-include-oom-propagation;
happy-path original/document/removal/default-name parity is live in
build/public-resident-propagation-parity. Neither runtime gate is complete yet.
Earlier full workstation and both retained builders remain live and progress;
do not treat their earlier source epoch results as propagation-fix evidence.

Propagation module binding correction (2026-10-05):
Both fresh runtime runs terminate during boot with FILES REJECT load reclaimed,
before user headers and before writing the include fixture. This is a kernel
module import-binding rejection, not the allocation-failure verdict. Kernel's
FileRuntime allowlist still held 29 providers and omitted the new SysTry and
SysUntry imports. Add existing published provider indices 40/41 and resize
only the file-loader binding list/stack buffer to 31. The explicit module
import audit already requires those helpers; no broad binding relaxation.
The propagation patch now includes this binding correction and applies cleanly
to main. Fresh bootstrap and dependent cross build run under the
file-resident-public-propagation-bound source epoch. Runtime tests must be
rerun on its resulting image. The test report now identifies an absent include
fixture separately from changed persisted bytes, retaining boot error evidence.
Original parity oracles passed, but neither rejected image reached native
behavior qualification. The candidate remains unpromoted.

Bound propagation build and help-oracle correction (2026-10-05):
Fresh bootstrap/cross/386 audit pass on the bound propagation candidate.
Kernel is 483200 bytes (+8 for its specific helper bindings); disk SHA256:
f5958d48c8eb36962f64c66ec38ce4eb6b91bf01698edc9c1a7f0af355357045.
Allocation failure is rerunning on this image in
build/public-resident-include-oom-propagation-bound; verdict pending.

The earlier full ABI-45 workstation run is terminal at help-man-page-link.
Its source viewer correctly shows the persisted three-argument FileRead
addition in PublicFiles.HH, while the harness's hardcoded expected listing
omits it. This is a source-fixture oracle mismatch, not established UI failure.
The main harness now derives source-view rows from the independent persisted
input disk reader, starting at a unique Dir declaration and retaining exact
80-column wrapping and pixel matching. Expected rows never come from guest
rendered output. Python checks and direct row verification pass (26 rows,
including FileRead). Focused help group runs in
build/public-resident-include-help-dynamic; the new propagation image's full
workstation runs in build/public-resident-propagation-bound-workstation.
These runtime checks are pending. The earlier full run cannot count as a
513-command pass. Both retained builders remain live and unmodified.

Bound candidate still rejects FileRuntime at boot: the provider array grew to 31 but actual KernelFileLoad retained stack/count 29 because the prior edit matched its forward declaration. Source inspection confirms the mismatch. Actual function body now uses 31 consistently for stack, KernelBindings and KernelServiceLoad. No fault or full workstation behavior executed on the rejected image. Archive updated; new loader-corrected original bootstrap is running.

Loader contract guard and fresh qualification (2026-10-05):
The source loader check tools/check-i386-file-bindings.py now runs before cross
construction. It requires the provider-array initializer/declaration, actual
file-loader stack and both call counts to agree, rejects duplicate/out-of-range
provider indices, and requires every explicit FileRuntime import to be allowed.
Main's 29 and candidate's 31 bindings pass; deliberately reproducing the 31/29
mismatch is rejected. Python/whitespace checks pass. Existing archived candidate
still applies to main with this guard. Do not widen the allowlist implicitly.

Corrected loader original bootstrap/cross/386 audit passes; kernel 483200 bytes.
Disk SHA256: 70aa242c2358718cb9440c95c0f2d2a43de97af114357f420eb47b0ef03c9247.
The strengthened failure test and document/removal/default-name parity are
running on this image in build/public-resident-include-oom-propagation-loader
and build/public-resident-propagation-loader-parity. Runtime verdicts pending.
The earlier help group now passes all nine no-FPU 8 MiB checks with exact VGA
in build/public-resident-include-help-dynamic/result.json; startup 25.197 seconds.
The original ABI-45 happy-path bridge retained native build completes all six
modules in build/public-resident-include-native-build/result.json (KVM). Its
source disk SHA is 02203a00cb76df1752b0a086f06f82b92103d1723ee18320ecea48d45c19d433.
These earlier-epoch greens do not qualify the newer propagation fix or prove
full native install/reproducibility. Main no-FPU retained build remains live.

Allocation failure green on loader-corrected propagation candidate (2026-10-05):
build/public-resident-include-oom-propagation-loader/result.json passes all
24 commands on 486,-fpu / 8 MiB. Fault include reports Out of memory, returns
to prompt, restored metadata permits later include result 49, file-state busy
is zero, and task lifetime_refs exactly matches its before value. Exact VGA,
source/input immutability and independent RedSea bitmap audit pass. Startup
26.055 seconds. This closes the fatal rethrow-loop gate for this injection;
it does not establish every exception or all allocator recovery behavior.

Original/document/removal/default-name parity passes all 17 commands in
build/public-resident-propagation-loader-parity/result.json, startup 26.150
seconds, exact VGA and disk audits/immutability. Fresh exact resident recovery,
full workstation and KVM retained native construction are live in
build/public-resident-propagation-loader-recovery, ...-workstation and
...-native-build. These are the propagation epoch, not the earlier bridge.

The include tool adds --failure-recovery (requires --allocation-failure).
The read-only heap observer accepts optional explicit command boundaries,
retaining its existing FileFind default. It samples private heap before the
reference baseline and after restored-metadata successful include plus value
check, requiring exact used bytes, allocations, base/capacity/signature;
peak is allowed to grow. Expected VGA commands remain unchanged. Python and
whitespace checks pass; the stronger 25-command gate is live in
build/public-resident-propagation-failure-recovery. Public allocator recovery
and child-task lifetime remain distinct gates, not implied by this snapshot.

Private allocation-failure recovery green; child cache oracle (2026-10-05):
build/public-resident-propagation-failure-recovery/result.json passes all
25 commands on no-FPU 8 MiB. Independent QMP private snapshots exactly match:
used 5379552 -> 5379552, allocations 7104 -> 7104, identical base/capacity/
signature. Original normal oracle, OutMem prompt recovery, file borrow zero,
exact task lifetime references, restored include 49, exact VGA, persisted-byte/
bitmap audit and unchanged input all pass. Startup 28.018 seconds. This proves
private recovery for the targeted failure, not every exception path/public heap.

The include tool adds --child (requires --document). A child reads the edited
public file cache and DocRead/DocSave, then remains yielding until the parent
synchronously Kill's it. The parent must still read both cached forms and
compile include 49; removal/default-name qualification remains composable.
This explicitly exercises teardown instead of treating a completion flag as
proof of task exit. All helpers fit 255 bytes (largest 229); Python/whitespace
checks pass. Original oracle passes. Native 23-command test is live in
build/public-resident-propagation-child. Full workstation, exact resident
recovery and current retained native construction remain live. No promotion.

Child teardown parity green and complete heap-failure gate (2026-10-05):
build/public-resident-propagation-child/result.json passes original oracle and
23 native no-FPU / 8 MiB commands. Child reads cache-backed FileRead and DolDoc,
parent synchronously terminates the still-live child, both parent reads and
compiler include still see edited value 49. Default-extension/removal/disk
repopulation remain correct. Exact VGA, disk/fixture immutability and volume
audit pass. Startup 27.673 seconds. This proves cache survival across forced
child teardown, not natural exit, every child exception or exact child heap
recovery; those scopes should remain explicit.

The include fault tool adds --failure-public-recovery (requires private failure
recovery). It validates queued jobs are only root-owned MSG_KEY_UP, quiesces
those at both public snapshots, and requires exact caller and persistent root
used bytes around the allocation rejection and recovered include. Independent
private snapshots now span the final public comparison too. No tolerances or
unrelated jobs are accepted. Python/whitespace checks pass; the 29-command
stronger gate is live in build/public-resident-propagation-failure-all-heaps.
The prior private-only 25-command pass remains separate evidence. Exact
resident twenty-cycle recovery, full workstation and native retained builds
remain live; checkpoints show continued command entry/function progress.
Candidate remains unpromoted until the remaining gates finish.

All-heap allocation-failure recovery green (2026-10-05):
build/public-resident-propagation-failure-all-heaps/result.json passes all
29 commands on 486,-fpu / 8 MiB, startup 28.167 seconds. Caller and persistent
root public used-byte comparisons pass after strict key-up-only quiescence;
independent private snapshots exactly match used 5381656 and allocations 7124,
with identical base/capacity/signature. OutMem prompt recovery, zero borrow,
exact lifetime references, later include 49, VGA, persisted bytes/volume and
input immutability pass. This is the targeted failure contract, not all errors.

New --failed-write original-model gate: attempt resident FileWrite with a
filename longer than RedSea's directory-name capacity, require disk result 0
but an owned FileRead from the published resident cache with original bytes.
Original DskFile updates cache after the underlying RedSea write returns,
whereas the candidate currently returns before cache update on disk result 0.
Original oracle passes in build/public-resident-failed-write-red/oracle.
Native 11-command qualification is live; do not infer a native red solely from
source inspection. The independent audit additionally checks that the rejected
long name does not become a persisted file; existing input/fixture equality and
bitmap checks remain mandatory. That audit extension landed after the running
process loaded its tool, so audit its candidate independently at completion.
Exact twenty-cycle recovery, full workstation and retained native builds remain
live and progress; candidate still unpromoted.

Rejected resident write red and ABI-46 attempt-byte candidate (2026-10-05):
build/public-resident-failed-write-red is terminal fail at command 10; exact
VGA capture shows helper result 0 instead of original result 1. Original
oracle passes. Independent audit confirms no rejected long-name file exists;
input and baseline fixture remain unchanged. This establishes the cache
publication mismatch after a disk mutation rejects a filename.

New docs/patches/i386-public-resident-write-attempt-candidate.patch advances
file-service ABI to 46. Optional private write metadata records whether a
valid parent write context was reached, normalized name, effective attributes
and attempted serialized bytes. Resident bytes are copied before freeing the
compression buffer, including after physical mutation failure. Public FileWrite
publishes/removes canonical cache based on this attempted context rather than
rereading only successful disk writes. Invalid parent contexts remain ineligible;
physical result is unchanged. Partial private staging allocations are cleaned
and allocation failure propagates as OutMem through the established dispatcher.
Ordinary writes stage only the key, not a duplicate file payload.

Bindings remain the 31 explicitly verified providers. Patch applies cleanly to
main; whitespace/binding checks pass. Fresh original candidate bootstrap runs
in build/resident-public-attempt-cache-bootstrap.log. Compilation and runtime
behavior are unverified. Required next gates include rejected-write green,
ordinary/compressed/resident publication, invalid-context nonpublication,
allocation failure/recovery, child teardown, full workstation and native builds.
Earlier ABI-45 tests/builds continue from immutable disks; their results do not
qualify the ABI-46 interface or new staging behavior.

ABI-46 build and rejected-write lifecycle oracle correction (2026-10-05):
Fresh original bootstrap and cross/386 audit pass, kernel 483200 bytes.
Disk SHA256: d07634b2d7602819fa785ae3bfee4f27034739a6c01fb5bd87c6436c5bcec634.
Exact twenty-cycle write/read recovery passes on the earlier ABI-45 propagation
image: build/public-resident-propagation-loader-recovery/result.json, 45 commands,
caller 1361744 -> 1361744, root 0 -> 0, private used 5394832 -> 5394832 and
allocations 7243 -> 7243; exact VGA, persisted archive/raw/replacement and volume
checks, unchanged input. This is not ABI-46 staging recovery evidence.

--failed-write-lifecycle adds ordinary-write removal after rejected resident
publication. An additional attempted assertion that a regular-file parent is
an invalid unpublished context fails on original TempleOS before native boot
(FAIL invalid context cache). That assumption is withdrawn; original
FileWrite's DirContextNew uses make_dirs TRUE, so parent-path behavior must be
measured before specifying nonpublication. Do not interpret that failed oracle
as a port defect or assert all failed writes lack a valid context.
The corrected lifecycle gate retains publication and ordinary removal; original
oracle/native qualification run in build/public-resident-write-attempt-removal.
ABI-46 exact resident recovery is live in build/public-resident-write-attempt-recovery.
Required remaining parity work includes attempted compressed bytes and original
parent creation/replacement semantics, alongside failure cleanup, child lifetime,
full workstation and native generations. Earlier broad tests/builds remain live.

Rejected write lifecycle green; compressed attempt gate (2026-10-05):
build/public-resident-write-attempt-removal/result.json passes original oracle
and all 13 native no-FPU / 8 MiB commands. Rejected resident write publishes
readable attempted bytes; rejected ordinary write removes the cache entry.
Disk result remains failure and independent audit confirms no long-name file
was persisted. Exact VGA, baseline fixture/input equality and RedSea audit
pass (16 directories, 871 files, 17568 owned sectors). Startup 29.030 seconds.
This verifies the original-model mismatch fixed by ABI 46 for ordinary bytes.

The tool adds --failed-write-compressed (requires --failed-write), changing
only the rejected target to .Z. FileRead must expand the staged archive back
to the original 19 bytes; then ordinary rejected replacement must remove it.
Original oracle passes; native 13-command gate is live in
build/public-resident-write-attempt-compressed. Candidate exact twenty-cycle
resident recovery is still live. Fresh all-heap allocation-failure recovery
and six-module KVM retained construction now run on the ABI-46 disk in
build/public-resident-write-attempt-failure-recovery and ...-native-build.
Earlier ABI-45 full workstation/native builds and main no-FPU retained build
remain live. These pending gates do not support promotion or release completion.

ABI-46 compressed/recovery greens and parent-creation oracle (2026-10-05):
build/public-resident-write-attempt-compressed/result.json passes original
oracle and 13 no-FPU / 8 MiB commands; cached .Z attempt bytes expand to the
original source and ordinary rejected replacement removes cache. Exact VGA,
no rejected persisted filename, unchanged source/input and valid volume pass;
startup 25.702 seconds. ABI-46 exact twenty-cycle recovery passes 45 commands
in build/public-resident-write-attempt-recovery: caller 1361744 -> same, root
0 -> 0, private used 5397816 -> same and allocations 7243 -> same, exact VGA,
persisted archive/raw/replacement and volume audits; startup 26.317 seconds.

The include tool adds --parent-write: FileWrite to two missing parent levels
must succeed, read back 19 original bytes and independently persist that file
in a valid reachable directory tree. Original oracle passes. Native 11-command
gate is live in build/public-resident-write-parent-red; no native red is claimed
yet. This replaces speculation about parent behavior with a concrete contract.
ABI-46 child/cache parity is requalifying in build/public-resident-write-attempt-child;
all-heap failure recovery and native retained builds remain live. PLAN's current
status is updated to distinguish these epochs from older historical greens.

Automatic parent creation verified red; candidate implemented (2026-10-05):
build/public-resident-write-parent-red is terminal fail at ParentWrite. Debug
reports parent resolve error for /Probe/CacheNewRoot/Deep and helper returns
0; independent audit confirms expected nested bytes absent. Original oracle
passes. This proves missing automatic parent creation on public FileWrite.
ABI-46 all-heap allocation recovery passes 29 commands in
build/public-resident-write-attempt-failure-recovery, and child teardown parity
passes 23 in ...-child; both no-FPU / 8 MiB with exact VGA/disk audits.

New docs/patches/i386-public-resident-write-parent-candidate.patch adds a
public-write parent walker. Resolve each prefix under a balanced volume session;
create missing prefixes via the existing directory mutation, reject non-directory
or failed prefixes, restore temporarily truncated path on every return. The
caller file/directory state stays borrowed and unchanged. Private writes retain
their existing context requirements. Partial directory creation is not rolled
back, matching original make_dirs behavior; regular-file-parent replacement
and all failure-side-effect semantics still need their own measured contract.
Service ABI remains 46. Binding/whitespace checks and patch application pass;
fresh original bootstrap is running. No compiled/runtime pass yet.

Parent oracle now also captures caller directory and drive before writing,
requires both unchanged after write/read, and frees its owned directory copy
on either Boolean outcome. Both helper lines fit 255 bytes (largest 233).
Required next gates: original strengthened oracle, parent-create green, rejected
raw/.Z lifecycle, all-heap/child recovery, full workstation and native generations.

Broad propagation qualification and parent candidate build (2026-10-05):
ABI-45 full workstation completes successfully in
build/public-resident-propagation-loader-workstation/result.json: 513 commands,
no-FPU 8 MiB, exact VGA, twenty exact document task data/code heap cycles;
startup 26.308 seconds, long-document visible update 0.435 seconds. Source
image remains SHA 70aa242c2358718cb9440c95c0f2d2a43de97af114357f420eb47b0ef03c9247.
The same epoch's retained native construction completes all six modules in
build/public-resident-propagation-loader-native-build/result.json (KVM).
These greens are not later ABI-46 parent/staging qualification.

The parent walker candidate's fresh original bootstrap, cross build, explicit
binding guard and 386 audit pass. Kernel remains 483200 bytes. Strengthened
original/parent-context/rejected-compressed lifecycle gate runs in
build/public-resident-write-parent-parity; exact twenty-cycle resident recovery
runs in build/public-resident-write-parent-recovery. Runtime verdicts pending.
Earlier ABI-46 attempted-byte and main no-FPU retained builders remain live.
Still required before promotion: current-source failure/child/full workstation,
native twelve-module/install/boot/audits and generation reproducibility. Physical
hardware/manual gates remain deferred; these are automated QEMU checks.

Parent creation/context parity green (2026-10-05):
build/public-resident-write-parent-parity/result.json passes original oracle
and 16 no-FPU / 8 MiB commands: two missing parent levels created, original
19 bytes persisted/read, caller directory/drive unchanged, rejected .Z cache
publication/expansion and ordinary removal correct. Independent bitmap/tree
and input/baseline equality checks pass; no rejected long filename is persisted.

Exact resident recovery, full 513-command workstation and six-module KVM
retained build are live for this image in build/public-resident-write-parent-recovery,
...-workstation and ...-native-build. Fresh all-heap failure recovery and child
teardown parity run in ...-failure-recovery and ...-child. These are pending,
not inherited passes from previous source epochs. The complete M7 pipeline,
x86-64 regression, fully native twelve-module/install/boot/audits, generation
reproducibility and published/downloaded artifact verification remain required.
No promotion or release completion is claimed.

Current-source full native installation chain queued (2026-10-05):
The parent candidate's 45-command exact twenty-cycle resident recovery passes
in build/public-resident-write-parent-recovery/result.json; caller/root used
bytes exactly recover. Full workstation, failure recovery and child parity
remain live. The exact native retained builder handle was revalidated live.
A dependent pipeline now waits on that handle and requires a six-module pass,
then runs retained installation and full native twelve-module/flat install/boot
with both retained provenance manifests. It fails closed if the required job
vanishes or a prerequisite fails; no build is restarted by this observer.
Outputs: build/public-resident-write-parent-native-install and ...-selfhost;
state: build/public-resident-write-parent-native-pipeline.json. A running state
is not a completed verdict; later turns must revalidate actual processes.
This is first-generation qualification only. Independent installed audit,
second-generation byte equality, installed no-FPU workstation, matching
x86-64 regression and release publication remain required before completion.

Current parent candidate failure/child gates green (2026-10-05):
Authoritative results in
build/public-resident-write-parent-failure-recovery/result.json and
build/public-resident-write-parent-child/result.json both pass, including the
original oracle, exact VGA checkpoints, unchanged input/persisted baseline,
and independent reachable-extent/bitmap audits (16 directories, 871 files,
17575 owned sectors). Both run with 486,-fpu and 8 MiB RAM.
The 29-command allocation rejection/recovery gate restores caller/root public
used bytes and independently observed private heap usage exactly: 5386936
bytes and 7124 allocations before and after, with matching heap identity and
signature. Restored cache metadata permits subsequent successful inclusion;
file-state borrowing and task references recover. The 23-command child gate
checks shared cache reads and DolDoc access, forced child teardown, parent
reuse, removal/repopulation, and default-extension inclusion. It does not
prove natural child exit or arbitrary child lifetime reclamation.

The previous attempted-write epoch's six-module retained build also passes
in build/public-resident-write-attempt-native-build/result.json; it is separate
from current parent qualification and cannot substitute for it.
Current parent native builder PID 3600449 and QEMU PID 3600450, dependent
pipeline PID 3603043, workstation QEMU PID 3600441, and main no-FPU builder
PID 3552346/QEMU PID 3552347 were directly revalidated live. Compiler debug
output shows current parent CompilerProbe construction, main no-FPU console
construction, and ongoing workstation file-editor commands. These jobs remain
pending. No source promotion, generation reproducibility, full no-FPU native
build, or release completion is claimed from this evidence.

Current-source installed audit and second generation queued (2026-10-05):
The live first-generation native pipeline is now followed by
build/public-resident-write-parent-generations-pipeline.py. It waits on the
specific live first-generation pipeline process, requires a successful fully
guest-built retained/flat report, then independently audits the installed
image's twelve executable modules, 386 boot instructions, installed flat
payload and filesystem. Audit source paths are /Modules/I386/Kernel.t32m and
/Probe/GuestBoot.bin; the matching candidate kernel-stage.lst is used.

After that audit succeeds, the installed first generation supplies the second
six-module retained build, with --compare-installed requiring exact retained
payload equality. Retained installation and full second-generation native
flat build follow with both provenance manifests, then a second independent
installed audit and audit-i386-generations.py compare all twelve modules,
flat image and full boot area byte-for-byte. Outputs use
build/public-resident-write-parent-gen2-* and
build/public-resident-write-parent-generation-identity. Pipeline state lives
in build/public-resident-write-parent-generations-pipeline.json; running state
alone proves no qualification. All steps stop on failure. These are queued
checks, not green verdicts. Installed no-FPU workstation, full no-FPU native
construction, remaining M7 behavior/performance and release gates stay open.

Matching candidate x86-64 regression started (2026-10-05):
The public-write-parent candidate now runs tools/test-rebuild.py from its
isolated source checkout, with OUT redirected to
build/public-resident-write-parent-x64-rebuild. This preserves earlier
bootstrap results. The driver hashes its candidate OS source files, rebuilds
Compiler.BIN and Kernel.BIN in original x86-64 TempleOS, boots the resulting
binaries, and rebuilds both again. Its manifest records source hashes and
binary differences; the scope is boot/self-rebuild regression, not x86-64
bit reproducibility or complete behavior coverage. Log:
build/public-resident-write-parent-x64-rebuild.log. This is pending, and the
candidate source must remain fixed while it runs. Both current i386 builders,
workstation QEMU, and queued generation wrapper were directly revalidated
live before launching this independent regression. No gates are waived.

Matching candidate x86-64 self-rebuild green (2026-10-05):
build/public-resident-write-parent-x64-rebuild/result.json is complete, and
both native rebuilds finish with DONE rebuild. The second generation boots
the first generation's generated compiler/kernel. All 1268 recorded source
hashes were independently rechecked against the unchanged candidate checkout;
all exported generation payload hashes also match the manifest. Compiler.BIN
is 256592 bytes in each generation with 176 differing byte offsets;
Kernel.BIN is 193088 bytes in each with 84 differing offsets. This satisfies
the matching x86-64 boot/self-rebuild regression scope, not bit reproducibility
or broad x86-64 behavioral coverage. The manifest's git revision identifies
the prototype base; its source hashes identify the actual dirty candidate.
Current parent i386 native builder and full workstation QEMU remain live;
installed audits and second-generation 386 identity are still pending.

Current candidate cold resident-cache requalification started (2026-10-05):
Two fresh original-oracle/fixture-preparation/separate-cold-boot tests run
against the public-write-parent image, using 486,-fpu:
build/public-resident-write-parent-cold-compressed exercises serialized .Z
reads, first-versus-cached attributes, public hash visibility/removal,
adam_task ownership, child reuse and directory-state replacement;
build/public-resident-write-parent-cold-mutation additionally edits ordinary
cached bytes and requires later reads to observe the edits while disk bytes
remain unchanged. Both use --prepare-fixture --shared-lifetime --hash-visible
--hash-removal --adam-root; the former adds --compressed, the latter
--cache-mutation. The tool explicitly disallows compressed mutation, so these
are separate contracts rather than an unsupported combined invocation.
Results are pending; candidate and input disk equality are required by each
gate. Existing earlier-epoch cold-cache greens are not substituted for these.

Current parent candidate full workstation green (2026-10-05):
build/public-resident-write-parent-workstation/result.json passes all 513
native commands (576 submitted lines) with 486,-fpu and 8 MiB RAM in ordinary
interactive boot. Startup is 28.983919 seconds and long-document update-to-VGA
latency is 0.381036 seconds, within the unchanged 60/1-second budgets.
All VGA pixels match at every checkpoint. The suite covers native compilation,
persistent definitions, error recovery, integer/software F64 answers, public
allocation, window/graphics/document operations, file editor/browser behavior,
and twenty document-development cycles with exact task data/code heap
recovery. This is the current ABI-46 parent/staging candidate's own broad
workstation result, replacing the previously pending verdict for this epoch.
It does not prove installed-generation workstation behavior, complete debugger
interaction, full M7 semantics, no-FPU native construction, or release readiness.

Current compressed and ordinary mutation cold-cache tests have both passed
the original TempleOS oracle and fixture-preparation stages. Their separate
cold native behavior QEMU handles were directly revalidated live; final
verdicts remain pending. The current native retained construction and main
no-FPU native construction also remain live; no restart is inferred from
elapsed time, and the queued install/audit/generation chains remain required.

Current native retained build green; combined cold gate exposes Cd gap (2026-10-05):
build/public-resident-write-parent-native-build/result.json passes all six
native modules. The dependent pipeline has advanced to retained-install.
FileRuntime now has 349015 bytes, 824 records and 122 exports; later full flat
installation and generation comparison remain required.

build/public-resident-write-parent-cold-compressed/result.json fails after
original oracle and native fixture preparation pass. Native debug output
shows ColdChild completing successfully, followed by Cd("C:/Probe") reporting
Undefined identifier; the expected-success console check then times out.
Thus the combined shared-lifetime/directory-state contract remains red for
the actual current candidate. Public Cd exists only in its separate prototype
and must be integrated with the current canonical cache architecture before
this gate can pass. No cache-only pass is substituted for the full contract,
and this result is not explained away as slow observation. The ordinary
mutation companion remains pending and may expose the same integration gap.

The resident include test's help/report wording no longer hardcodes ABI-45
for the allocation-failure scope; source-layout hashes already identify the
actual tested candidate. CLI help and diff checks pass; runtime behavior is
unchanged and existing evidence files remain untouched.

Public Cd/current resident-cache integration candidate prepared (2026-10-05):
Both compressed and ordinary mutation cold-cache gates fail at public Cd;
native cache/child checks complete before Undefined identifier. This drives
integration rather than removing the directory-state requirement.
A separate main-only fork checkout in
build/file-cd-resident-integrated-prototype combines the archived current
parent/write/cache code with TaskCd.HC, public _CD binding, service callback
and declaration. File services advance to ABI 47 (one additional callback);
the matching service-size assertion and auditor version advance together.
The old Cd prototype's private cache and storage changes are not copied.
Running ABI-46 native installation/generation sources remain unchanged.

The complete candidate is archived in
docs/patches/i386-public-cd-resident-integrated-candidate.patch and applies
cleanly to current main. The initial cross-build stopped because this new
checkout lacked its required original-bootstrap manifest, before any native
verdict. Its fresh two-generation original bootstrap is now running, followed
by the cross build only on bootstrap success. Logs:
build/file-cd-resident-integrated-bootstrap.log and
build/file-cd-resident-integrated-build.log. Runtime Cd/cold-cache parity,
full workstation and native generations are required after successful build;
this candidate is not promoted or qualified merely by patch applicability.

Retained installation green; integrated Cd runtime chain queued (2026-10-05):
build/public-resident-write-parent-native-install/result.json passes all six
retained modules, with candidate disk
 ea117714258b39147c52c563707b8418e5d0600fd4052d2500de850a2d2630d1.
The corresponding full native kernel builder/QEMU are directly confirmed
live. This installation is the ABI-46 parent candidate, not ABI-47 Cd proof.

The integrated Cd candidate's original bootstrap handle is confirmed live.
A dependent runtime chain in
build/file-cd-resident-integrated-runtime-pipeline.py waits on that specific
bootstrap/cross-build shell handle and requires ABI 47 in the exported
FileRuntime payload, verified against the build manifest and layout auditor. It then runs public Cd with --task-fields and
--special-paths, followed by the previously red compressed and ordinary
mutation cold-cache contracts, preserving --shared-lifetime and directory
changes. Each step uses a fresh output and requires its own pass report; the
chain stops on first failure. Outputs use
build/file-cd-resident-integrated-{cd,cold-compressed,cold-mutation}; state
is build/file-cd-resident-integrated-runtime-pipeline.json. All remain pending.
The actual bootstrap source and running earlier native sources stay fixed.

Integrated Cd bootstrap/cross-build green (2026-10-05):
The fresh original two-generation bootstrap and cross build finish successfully.
The integrated kernel is 483208 bytes; the 386 boot allowlist passes 96 BIOS
and 33 protected-mode instructions. The runtime wrapper's initial check used
an absent file_runtime report field and stopped before tests; that was a
wrapper error, not an OS failure. It now compares FileRuntime.t32m SHA-256
with the manifest and invokes the candidate file_runtime_layout verifier,
which reads the module's exported version and requires ABI 47. The completed
build is reused; no compiler job is restarted. Public Cd original/native parity
is now running, with both combined cold-cache checks following only on pass.
Runtime and installed-generation gates remain open.

Full native parent installation/audit and integrated Cd green (2026-10-05):
build/public-resident-write-parent-selfhost/result.json passes twelve native
modules, guest-linked flat construction, installation and independent 8 MiB
boot with retained build/install provenance. Flat size is 487328 bytes
(96 bytes below the current BIOS limit); SHA-256:
95b03ab60e754405149915f9120843bece7240e716f7412a2f06ca6745220d6b.
Installed target SHA-256:
2ce19d94fd33275f2ab9402821406b378a4688fce8d3865c89e9412825009785.
build/public-resident-write-parent-selfhost-audit/result.json independently
passes all twelve executable regions, 386 boot instructions, matching installed
flat payload and reachable filesystem bitmap (16 directories, 871 files,
19033 owned sectors). Second-generation retained build is confirmed live.
A fresh full no-FPU 8 MiB workstation suite now runs on this installed target
in build/public-resident-write-parent-installed-workstation, using a writable
copy. First-generation build/audit is not generation identity or release proof.

build/file-cd-resident-integrated-cd/result.json passes the original oracle and
32 native commands on 486,-fpu / 8 MiB, startup 25.449113 seconds and exact
VGA checkpoints. Relative/parent/empty/dot paths, partial failure progress,
nested make_dirs, default/home/whitespace cases and public Fs directory fields
pass. Independent directory writes and volume audit pass (19 directories,
874 files, 17618 owned sectors), with source unchanged. Broader drive/error
parity remains unproved. The dependent combined compressed cold-cache test
is now running; ordinary cache mutation follows on pass. Native six-module
construction also runs for this integrated image in
build/file-cd-resident-integrated-native-build. No earlier ABI-46 native
result is substituted for this new ABI-47 source epoch.

Integrated source broad/resource qualification started (2026-10-05):
The integrated compressed cold-cache QEMU, native retained builder, earlier
installed no-FPU workstation and earlier second-generation retained builder
are directly confirmed live. The integrated image now also runs its own:
- full 513-command no-FPU / 8 MiB workstation suite in
  build/file-cd-resident-integrated-workstation;
- forced public allocation rejection with exact caller/root and independently
  observed private heap recovery in
  build/file-cd-resident-integrated-failure-recovery;
- twenty resident create/update/remove cycles with exact heap recovery in
  build/file-cd-resident-integrated-recovery.
The resource tests use the matching ABI-47 builder for independent disk audits.
Each has its own preserved original oracle and disposable native image.
All final verdicts are pending; previous ABI-46 greens cannot establish
these current-source gates. No OS source changes are made during qualification.

Previously red compressed cold contract now green (2026-10-05):
build/file-cd-resident-integrated-cold-compressed/result.json passes original
oracle, fixture preparation, separate cold boot and all 32 native commands
on 486,-fpu / 8 MiB. Startup is 29.857418 seconds; all VGA checkpoints match.
First-disk/cached .Z reads, alternate suffix lookup, independent owned copies,
adam_task cache ownership, hash removal/repopulation, child reuse and both
public Cd directory-state changes pass. Candidate disk stays identical after
read-only cache tests and input source remains unchanged. An independent
matching-builder volume audit also passes (16 directories, 872 files, 17613
owned sectors). This is an actual red-to-green result for the combined
contract that failed on ABI 46; arbitrary/natural child heap teardown remains
outside this gate's evidence. Ordinary cache mutation now runs next.

Fresh combined compiler/DolDoc/public-write/forced-child qualification runs
in build/file-cd-resident-integrated-include-write-child, with document,
removal/default extension, child, parent-write, rejected compressed write and
ordinary rejected-write lifecycle flags. It requires current-source original
parity, independent persisted bytes/bitmap and unchanged input. Current
allocation recovery, twenty resident recovery cycles, workstation and native
builders were directly revalidated live; their final results remain pending.

Integrated allocation recovery green and native generations queued (2026-10-05):
build/file-cd-resident-integrated-failure-recovery/result.json passes original
oracle and 29 no-FPU / 8 MiB commands, startup 37.257480 seconds, exact VGA
checkpoints and disk/baseline equality. Caller/root public used bytes recover;
private heap independently returns exactly to 5404104 bytes and 7132
allocations, with unchanged heap identity and signature. Borrow/reference
recovery and successful inclusion after the forced OutMem also pass. This
qualifies the integrated source rather than inheriting ABI-46 recovery.

Native retained builder PID 3611305 and QEMU PID 3611308 were confirmed live.
build/file-cd-resident-integrated-generations-pipeline.py now waits on that
exact handle, requires a six-module pass, then runs retained installation,
full twelve-module native construction/install/boot with both provenance
reports, independent installed 386/bitmap audit, second-generation retained
build with --compare-installed, second retained installation/full flat build,
second independent audit and complete generation byte comparison. All steps
stop on failure. Matching stage listing and ABI-47 auditor are used throughout.
Outputs use build/file-cd-resident-integrated-{native-install,selfhost,
selfhost-audit,gen2-native-build,gen2-native-install,gen2-selfhost,
gen2-selfhost-audit,generation-identity}; running state is not a green verdict.
Installed no-FPU workstation and the remaining M7/release gates stay required.

Integrated twenty-cycle resident recovery green (2026-10-05):
build/file-cd-resident-integrated-recovery/result.json passes original oracle
and 45 commands on 486,-fpu / 8 MiB, startup 37.279943 seconds and exact VGA.
Twenty create/update/remove cycles return caller public used bytes exactly
1361744 -> 1361744 and root 0 -> 0. Independent private snapshots return
5417280 -> 5417280 used bytes and 7251 -> 7251 allocations, with matching
heap identity/signature. Binary/expanded/alternate .Z reads, independent
ownership, replacement and residence removal pass. Bitmap/tree audit passes
(16 directories, 875 files, 17615 owned sectors); source remains unchanged.
Both native retained builder/QEMU pairs and the main no-FPU pair were directly
revalidated live. Integrated ordinary cold mutation and combined child/write
contracts remain pending; no jobs are restarted from an observation timeout.

Integrated cold mutation and combined compatibility green (2026-10-05):
build/file-cd-resident-integrated-cold-mutation/result.json passes original
oracle, preparation and separate cold boot with 36 commands on 486,-fpu /
8 MiB (startup 39.180465 seconds, exact VGA). Root-owned public cache-byte
edits affect new reads, disk bytes remain identical, removal/repopulation,
child reuse and both Cd changes pass. The matching-builder bitmap/tree audit
is independently checked after this pass. The entire dependent Cd/compressed/
ordinary mutation runtime chain is now complete; both previously red Cd
integration contracts are green on ABI 47.

build/file-cd-resident-integrated-include-write-child/result.json passes all
30 commands and original oracle (startup 39.006435 seconds, exact VGA).
Compiler/DolDoc edited-cache reads, removal/default-extension inclusion,
forced child teardown and parent reuse, parent directory creation, rejected
compressed-write publication and ordinary rejected-write removal pass.
Independent audit proves expected nested-file persistence, rejected long-name
absence, unchanged baseline source and unchanged input (18 directories,
873 files, 17616 owned sectors). Current cross-manifest source hashes are
independently rechecked before recording these results. Workstation/native
builds, installed-generation requalification and release gates remain open.

Current native installed DolDoc/audio release gates started (2026-10-05):
Three-boot DolDoc persistence/reopen/edit/execute/interrupt recovery runs on
the completed ABI-46 native target in
build/public-resident-write-parent-installed-doldoc-session with 486,-fpu
and QMP stdio. Captured speaker tone/off/reset output runs in
build/public-resident-write-parent-installed-speaker. Both preserve the input
installation and require actual runtime evidence rather than sound-state
assignments or one-boot persistence. Final verdicts remain pending, and these
are earlier-source ABI-46 evidence; equivalent installed checks remain needed
for the final integrated image. The M7 coverage audit opening now identifies
this current installed checkpoint and distinguishes the ABI-47 candidate from
historical evidence. Native build and installed workstation handles were
revalidated live before starting these independent checks.

Installed captured speaker output green; peak resource measurement running
(2026-10-05): build/public-resident-write-parent-installed-speaker/result.json
passes actual captured 440/880 Hz tone sequence on the fully native ABI-46
installation. WAV hash and assess_wav measurements are independently
recomputed and match the recorded result; input disk stays unchanged. This
is runtime waveform evidence, with the console sound contract, rather than
only checking speaker registers. It does not substitute for corresponding
final integrated-image audio qualification.

build/public-resident-write-parent-installed-resource now measures live and
peak heap usage over twenty document-development cycles on the same installed
image with TCG 486,-fpu / 8 MiB. It checks exact recovery, shared data/code
accounting and that the reported arena fits guest RAM. Final resource verdict
is pending. Three-boot DolDoc persistence and broader installed/current
workstation/native generations remain live or pending, not release completion.

Promoted main no-FPU six-module native construction green (2026-10-05):
build/public-file-find-no-fpu-native-build/result.json passes all six retained
modules: CompilerRuntime, CompilerProbe, ConsoleRuntime, FileRuntime,
MemoryRuntime and Startup. The preserved qemu/command.json independently
confirms machine pc, TCG, CPU 486,-fpu and 16 MiB RAM on its disposable source
image. The long-lived builder/QEMU handles are now terminal, with an actual
pass report and successful process log; no timeout-based restart occurred.
This proves retained native construction without an FPU for promoted ABI-40
main, not just interactive boot, and does not prove full flat installation or
current integrated ABI-47 construction.

The exact equivalent current integrated-source build is now running in
build/file-cd-resident-integrated-no-fpu-native-build with --accel tcg
--cpu 486,-fpu --command-timeout 7200, its matching image and cross export
references, and 16 MiB RAM. This remains pending and preserves separate
evidence from the KVM integrated builder. Current KVM generation builders,
workstation QEMU and installed DolDoc driver were directly revalidated live.
Peak resource, installed persistence and final native generations remain open.

Installed resource result and cached-evidence provenance fix (2026-10-05):
The installed ABI-46 resource run passes twenty document-development cycles:
live baseline 1352496 bytes, peak 1356112, reserved peak 1365504 and temporary
live growth 3616. Arena 1114112 + 7143424 fits 8 MiB. This historical result
has preserved runtime/profile evidence but predates the new input pin below.

A negative cached-evidence experiment proved test-i386-resource-profile.py
--parse-only accepted another --disk before the fix. The tool now records
resource-input.json before fresh execution with resolved disk, SHA-256,
CPU/accelerator/RAM, then verifies source equality and the preserved machine,
CPU/accelerator/RAM, drive and snapshot command. Cached parsing requires an
exact input identity; unpinned historical evidence fails closed and must be
remeasured. The same negative fixture now rejects instead of reporting pass.
Final resource-result.json includes disk hash, accelerator and source equality.

Fresh pinned qualification runs in
build/public-resident-write-parent-installed-resource-pinned with TCG
486,-fpu / 8 MiB. Its verdict remains pending; no input manifest is retrofitted
onto older measured evidence. This improves reproducible release validation
without changing the OS or the running candidate sources.

Fresh pinned installed resource profile green (2026-10-05):
build/public-resident-write-parent-installed-resource-pinned/resource-result.json
passes with recorded disk SHA-256
2ce19d94fd33275f2ab9402821406b378a4688fce8d3865c89e9412825009785,
TCG 486,-fpu / 8 MiB, unchanged source and verified preserved QEMU profile.
Twenty development cycles measure 1352496 live baseline, 1356112 live peak,
1365504 reserved peak and 3616 temporary live growth; the arena fits guest
RAM. A completed-evidence parser check accepts the correct pinned input and
rejects both another image and an altered preserved CPU command. Test fixtures
are temporary copies; actual raw evidence is unchanged. This closes the new
resource-provenance check for this installed source epoch. Current integrated
native/FPU-free construction and workstation, second native generation and
installed three-boot DolDoc remain pending, with their actual handles rechecked.

Installed three-boot DolDoc workflow green (2026-10-05):
build/public-resident-write-parent-installed-doldoc-session/result.json passes
107 create/edit/save commands, 56 reopen/execute commands and 15 revised-content
commands over three cold boots on the fully native ABI-46 installation with
486,-fpu / 8 MiB. Startup times are 47.659644, 43.520826 and 43.465267 seconds;
interrupt-to-recovery VGA is 0.297959 seconds. All exact VGA checkpoints pass.
Persisted project and relative-source bytes, rename/delete/move/directory
cycles and reachable extent bitmap pass (18 directories, 888 files, 19054
owned sectors). Source and final session SHA-256 identities are independently
rechecked, and a separate matching-builder full volume audit confirms the
bitmap/tree. These are actual persistence/reboot workflows, not one-boot
console checks. The final integrated image still needs equivalent installed
qualification; current native generations and workstation remain pending.

Integrated cold edge contracts requalified from current source (2026-10-05):
Fresh empty resident-file ownership/removal and dotless-name cache mutation
checks now run in build/file-cd-resident-integrated-cold-empty and
build/file-cd-resident-integrated-cold-dotless. Both preserve original oracles,
prepare fixtures on disposable images, and use a separate no-FPU 8 MiB cold
boot with public hash visibility/removal and adam_task ownership. Dotless
also checks edits through the exact public cache key. Earlier ABI-44 edge
greens are not taken as current ABI-47 verdicts. Final results are pending.
The full integrated workstation is directly confirmed advancing through
original-document compatibility; both KVM native builders and the integrated
TCG no-FPU builder are directly revalidated live. Sources remain fixed and
no incomplete results are promoted.

Installed full workstation and retained generation reproducibility green
(2026-10-05): build/public-resident-write-parent-installed-workstation/result.json
passes all 513 native commands on the fully native ABI-46 target with
486,-fpu / 8 MiB. Startup 37.710675 seconds and long-document update 0.571427
seconds pass budgets; exact VGA and twenty document-development heap-recovery
cycles pass. This is installed-image evidence, complementing the preceding
cross-image workstation result.

build/public-resident-write-parent-gen2-native-build/result.json passes all
six native retained providers and byte_identical_to_installed against target
2ce19d94fd33275f2ab9402821406b378a4688fce8d3865c89e9412825009785.
Independent extraction/hashing of all six installed modules matches the
second-generation report's native payload hashes. Second retained installation
is directly confirmed live; second full flat construction/audits and twelve-
module/flat/boot-area comparison are still required. Integrated ABI-47 retained
and no-FPU builders, workstation, empty/dotless cold checks remain pending.
No earlier-source result establishes final integrated-image qualification.

Integrated full workstation/native retained greens (2026-10-05):
build/file-cd-resident-integrated-workstation/result.json passes all 513
commands on 486,-fpu / 8 MiB: startup 35.971482 seconds, long-document VGA
update 0.268792 seconds, exact checkpoints and twenty document-development
heap-recovery cycles. build/file-cd-resident-integrated-native-build/result.json
passes all six retained modules; native FileRuntime is 365483 bytes with
847 records and 124 exports. Its native pipeline advances to retained-install.
These are this source epoch's own results, not earlier cache/Cd prototype passes.

The native pipeline process is directly revalidated live. A dependent installed
workflow chain in build/file-cd-resident-integrated-installed-workflows.py
requires both full native selfhost and installed 386 audit passes before
running full no-FPU workstation, three-boot DolDoc persistence, captured speaker
and fresh pinned resource tests on disposable images/copies of its target.
Each has an independent verdict/log under build/file-cd-resident-integrated-
installed-{workstation,doldoc-session,speaker,resource-pinned}; all four are
required for the chain pass. State is ...-installed-workflows.json. These are
queued, not completed. Second native generation, fully no-FPU construction,
empty/dotless contracts and remaining M7/release requirements stay open.

Integrated cold edge gates and retained installation green (2026-10-05):
build/file-cd-resident-integrated-cold-empty/result.json passes original oracle,
fixture preparation and 22 separate-cold-boot commands on 486,-fpu / 8 MiB;
startup 27.464066 seconds, exact VGA, correct empty public allocation/cache
ownership/removal and unchanged candidate/input. The dotless companion passes
28 commands, startup 27.514776 seconds, exact key ownership/mutation/removal,
VGA and read-only disk equality. Separate matching-builder tree/bitmap audits
pass: both have 16 directories/872 files, with 17612 empty-case and 17613
dotless-case owned sectors. These close the current-source edge contracts.

build/file-cd-resident-integrated-native-install/result.json passes all six
native retained installations and independent boot; installed candidate hash
06e593e0eabf310f6f28caca7b27fbb8942e28eecb3a5a1a2ac94a960fe14681.
The integrated full-native selfhost process is directly confirmed live. The
earlier ABI-46 generation-two retained installation also passes in
build/public-resident-write-parent-gen2-native-install/result.json; its full
flat builder is directly confirmed live. Installed workflow/audit and complete
generation comparisons remain pending; integrated no-FPU retained construction
continues on its existing handle. No source promotion or release is claimed.

Integrated CPU-trap debugger regression started (2026-10-05):
The existing independent VGA INT3/function/source/state/G-resume checker now
runs five cycles against the integrated ABI-47 image in
build/file-cd-resident-integrated-cpu-trap. It requires preserved EAX result,
restored debugger mode/IF/TF and shell recovery on 486,-fpu, with source/checker
hash equality. This supplies current-source regression evidence for the
already promoted CPU-trap continuation behavior; verdict is pending. It does
not close stepping, user breakpoint installation, complete saved-register
inspection or simultaneous debugger-session requirements. Full native
integrated and previous-source generation-two builders were directly
revalidated live, and installed workflows still wait for a successful audit.

Parent candidate complete native generation identity; integrated CPU trap green
(2026-10-05): build/public-resident-write-parent-generation-identity/result.json
passes all twelve native modules, 487328-byte flat image and complete boot
area equality across two independently built/installed generations. Both
installed audits pass. Flat SHA-256 remains
95b03ab60e754405149915f9120843bece7240e716f7412a2f06ca6745220d6b;
second target is 24eb30c55e77ba107da6108dc56243681e76432a7c9feb824d3575f6263e9083.
Both trees have valid bitmaps (16 directories, 871 files, 19033 owned sectors).
Whole disk images differ; only the stated executable/module/boot identities
are proven. This is fully native ABI-46 reproduction, not ABI-47 proof.

build/file-cd-resident-integrated-cpu-trap/result.json passes five INT3/G
cycles and 44 commands on 486,-fpu / 8 MiB, startup 26.959331 seconds with
exact VGA, preserved EAX result, restored debugger mode/IF/TF and shell
recovery. It does not prove S, managed breakpoints or complete register editing.
The integrated full native driver is directly confirmed live at boot-image
installation; its final audit and installed workflows remain pending. The
existing integrated no-FPU retained builder remains live. Promotion/release
still require the current source's remaining qualification.

Integrated full native installation/386 audit green (2026-10-05):
build/file-cd-resident-integrated-selfhost/result.json passes all twelve native
modules, flat construction, installation and independent 8 MiB boot with
retained build/install provenance. Flat size 487336 bytes leaves 88 bytes
inside the current BIOS payload limit; flat SHA-256:
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f.
Target SHA-256:
5d37e3e92c0cab231aed01f4a8faf2e7b8c9a695a1ce48db1f54749f63ecf99f.
The independent installed audit passes all twelve executable regions, BIOS/
protected-mode 386 instructions, installed flat equality and filesystem bitmap.
This is the integrated canonical cache/Cd ABI-47 source's own native result.

Its second-generation retained build and all four dependent installed workflow
jobs have started. Five-cycle CPU-trap/G continuation also runs directly on
this installed target in build/file-cd-resident-integrated-installed-cpu-trap,
so cross-image debugger evidence is not substituted for native emitted code
and binding addresses. Full installed workstation/persistence/audio/pinned
resources, current native generation identity and no-FPU retained construction
remain pending; broader debugger/API and release requirements remain open.

Integrated native installed audio and pinned resource gates green (2026-10-05):
build/file-cd-resident-integrated-installed-speaker/result.json passes captured
440/880 Hz sequence and console tone/off/reset contract on target
5d37e3e92c0cab231aed01f4a8faf2e7b8c9a695a1ce48db1f54749f63ecf99f.
Input disk and WAV identities are independently rehashed; assess_wav is rerun
and its measurements exactly match the recorded result. Source stays unchanged.

build/file-cd-resident-integrated-installed-resource-pinned/resource-result.json
passes TCG 486,-fpu / 8 MiB with that same pinned target identity and preserved
QEMU configuration. Twenty development cycles measure live baseline 1352496,
live peak 1356112, reserved peak 1365504 and temporary growth 3616 bytes, with
shared code/data accounting and an arena that fits RAM. These are current
ABI-47 native installed results rather than previous-source measurements.
Installed workstation, three-boot DolDoc and CPU-trap checks remain pending;
second native generation and no-FPU retained builders are revalidated live.
Full debugger/API completion, promotion and release requirements remain open.

Integrated native installed CPU-trap debugger green (2026-10-05):
build/file-cd-resident-integrated-installed-cpu-trap/result.json passes five
INT3/G cycles and 44 commands on native target
5d37e3e92c0cab231aed01f4a8faf2e7b8c9a695a1ce48db1f54749f63ecf99f,
using 486,-fpu / 8 MiB. Startup 43.791605 seconds, exact debugger VGA,
function/source/state inspection, EAX preservation, debugger mode/IF/TF
restoration and shell recovery pass. Checker and source image hashes remain
unchanged. This closes current installed continuation regression only;
single-step S, managed breakpoints, complete register inspection/editing and
concurrent debugger sessions remain explicit unimplemented/unproved scope.
Installed workstation/DolDoc workflows and second native generation remain
pending, with generation wrapper and no-FPU native builder directly confirmed
live. Passing these limited debugger checks does not establish complete M7.

Single-step TDD contract added before implementation (2026-10-05):
tools/test-i386-debug-single-step.py runs against the integrated native target
in build/file-cd-resident-integrated-single-step-red. It places INT3 at the last
of three NOPs immediately before a known MOV store, verifies zero local state
at entry, sends S, requires a fresh debugger entry, and checks the store's
0x11223344 value while the function-return marker is still zero. G must then
finish the function with the original result and restored flags/debugger mode.
This rejects a no-op or continue-to-return implementation of S. Exact VGA and
source/checker identity are retained; helper input lengths are checked.

The contract is native TDD based on the original Kernel/KDbg.HC public S
semantics, whose source hash is recorded; it does not claim an original-runtime
oracle, managed breakpoint or full register test. Public S is currently absent
from PublicDebug.HH, so the expected missing-function gate is now running;
actual failure evidence is pending rather than inferred from that declaration.
The current candidate source remains fixed for its installed/generation jobs.
A separate debugger implementation candidate is needed after observing red.

Single-step fixture search corrected before implementation (2026-10-05):
The first single-step TDD run fails at CpuTrapFind before any S command.
The expanded test function outgrows the inherited 128-byte triple-NOP search.
This is fixture failure, not a demonstrated S red. The checker now obtains
MSize of the generated executable allocation and searches only within that
allocation, requiring all three bytes to lie inside it. Public code-allocation
MSize is already covered by the workstation suite. This removes the arbitrary
function-length limit and avoids reading past the executable allocation.
A fresh run in build/file-cd-resident-integrated-single-step-sized-red now
uses this corrected fixture; actual missing-S evidence remains pending. The
first failure evidence is preserved and no OS source is changed to accommodate
it. Existing native-generation/workflow/no-FPU builds remain on fixed sources.

Single-step intended red observed and implementation candidate prepared
(2026-10-05): the corrected fixture passes breakpoint search/patch, actual
INT3 entry and pre-step local-zero check. Its exact VGA failure image shows
`dbg> S;` followed by Undefined identifier. This is the intended missing-public-
function red, distinct from the initial fixture-size failure.

A separate main-only fork checkout in build/debug-single-step-prototype
adds public _DEBUG_STEP/S, requires the active current-task CPU debugger,
sets the saved frame's trap flag, accepts vector 1 through the existing CPU
capture callback, and clears TF on debugger entry/G. The existing kernel
exception-return bridge clears TF while executing debugger code; S enables
it only for the returned debuggee frame. No global exception API is changed.
The full candidate is archived in
 docs/patches/i386-debug-single-step-candidate.patch and applies cleanly to main.
Default/current-task S is targeted first; explicit new-IP/other-task arguments,
managed breakpoints and complete register inspection/editing remain open.

Fresh candidate original bootstrap followed by cross build runs with its
actual checkout cwd; logs are build/debug-single-step-candidate-bootstrap.log
and ...-candidate-build.log. An initial launch used root main's cwd and writes
a separate root build/debug-single-step baseline; it is not candidate evidence.
Correct candidate output is build/debug-single-step-prototype/build/debug-single-step.
Current integrated qualification sources remain fixed. Integrated native
three-boot DolDoc now passes (107/56/15 commands, 38.908934/37.949953/38.808444
second startups and 0.222433-second interrupt recovery), with independent
source/session hashes and matching-builder bitmap audit (18 directories,
889 files, 19094 owned sectors). Installed workstation/generation identity
and no-FPU construction remain pending; no single-step pass is claimed yet.

Single-step candidate dependent runtime qualification queued (2026-10-05):
The actual candidate bootstrap/build shell handle is directly confirmed live.
build/debug-single-step-runtime-pipeline.py waits on that exact handle and
uses only build/debug-single-step-prototype/build/debug-single-step output,
verifying its input disk SHA-256 against the candidate build report. It then
runs the corrected single-instruction store/reentry/G contract followed by
five ordinary CPU-trap continuation cycles, stopping on failure. Outputs are
build/debug-single-step-single-step and build/debug-single-step-continuation;
state is build/debug-single-step-runtime-pipeline.json. Neither is a pass yet.
The unrelated root-cwd baseline remains separate evidence and is not read by
this chain. Current ABI-47 installed workstation, generation reproducibility
and no-FPU native construction remain pending on their existing sources.

Single-step first observable green and broader qualification started
(2026-10-05): the actual candidate original bootstrap, cross build and 386
boot audit pass; kernel remains 483208 bytes. The runtime chain completes:
build/debug-single-step-single-step/result.json passes store-before-return
CPU single-step/reentry/G, and build/debug-single-step-continuation/result.json
passes five ordinary INT3/G cycles. This is a demonstrated missing-S red to
hardware-step green, not only a new public declaration. Existing frame return
and debugger mode/IF/TF restoration remain covered. Default/current-task
scope is unchanged; other-task/new-IP arguments and full breakpoint/register
features remain open.

The single-step checker now accepts --cycles (1..20) and repeats the full
step/resume/result/mode/flag checks with the existing warmed heap equality
probe. Five step cycles run in build/debug-single-step-repeat. Full no-FPU
8 MiB workstation runs in ...-workstation and six native retained modules
build in ...-native-build. These are pending current-step-source gates; the
previous integrated cache/Cd builds cannot substitute for the changed retained
console. The source stays fixed while these jobs run. No promotion or release
completion is claimed from the first functional green.

Integrated native installed workflow chain complete (2026-10-05):
build/file-cd-resident-integrated-installed-workflows.json passes all four
required jobs. The installed full workstation passes 513 commands on
486,-fpu / 8 MiB, startup 39.361013 seconds and long-document VGA update
0.263004 seconds, with exact VGA and twenty exact shared-heap development
cycles. Three-boot DolDoc, captured audio and pinned resource measurements
pass as documented separately. This is current ABI-47 native installed-image
workflow evidence. Second native generation and no-FPU retained construction
are still directly confirmed live; complete release/M7 scope remains open.

The single-step retained builder PID 3631600 is directly confirmed live.
A dependent chain in build/debug-single-step-generations-pipeline.py now
requires that exact six-module build pass, then retained installation, full
native twelve-module construction/install/boot with provenance, installed
386/bitmap audit, second retained build with installed-byte comparison,
second installation/full flat/audit, and final twelve-module/flat/boot equality.
Outputs use build/debug-single-step-{native-install,selfhost,selfhost-audit,
gen2-native-build,gen2-native-install,gen2-selfhost,gen2-selfhost-audit,
generation-identity}. Matching candidate stage listing and auditor are used;
all results remain pending. No earlier-source native generations qualify the
changed step-enabled console. Existing sources remain fixed during these jobs.

Five repeated hardware-step cycles green; forced step-debugger exit gate
started (2026-10-05): build/debug-single-step-repeat/result.json passes five
store-step/reentry/G cycles and 49 commands on 486,-fpu / 8 MiB, startup
26.456843 seconds with exact VGA, result/mode/IF/TF and warmed public heap
checks. Source/checker identity stays unchanged. This broadens the first
single-cycle functional green without asserting full debugger completion.

The existing CPU-debugger forced-kill test now has --single-step. Its victim
executes INT3 followed by NOPs, S must reenter the debugger after one hardware
instruction, then another terminal kills that paused task. The survivor must
enter Dbg, evaluate, G back, exit and restore the parent public heap. This
checks cleanup after vector-1 step entry; all private resources, explicit
new-IP/other-task stepping, registers and managed breakpoints remain open.
The fresh gate runs in build/debug-single-step-forced-kill, verdict pending.
Integrated generation-two retained construction passes all six modules with
installed byte equality and now installs them; full generation comparison
and integrated no-FPU construction remain pending on their existing handles.

Integrated cache/Cd native generation equality and stepped-task teardown
verified (2026-10-05): the integrated generation pipeline completes PASS.
An independent rerun in build/file-cd-resident-integrated-generation-identity-recheck
confirms twelve identical native modules, a 487336-byte identical flat kernel,
and identical installed boot area across both generations. Flat SHA-256:
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f.
Boot-area SHA-256:
39c511c316094a6cf4dcdd01aab0f77b307637e1a6772861ad9764eca09a360f.
Both volumes have 16 directories, 872 files and 19073 owned sectors with
bitmaps matching reachable extents. Whole disk images differ; this gate
claims module/flat/boot equality, not whole-volume byte equality.

build/debug-single-step-forced-kill/result.json passes --single-step:
13 commands on 486,-fpu / 8 MiB, exact VGA, startup 28.422164 seconds,
source image unchanged. A terminal is killed after vector-1 step reentry;
the survivor can enter Dbg, evaluate, resume and exit, with parent public
heap recovery. The checker report now names the selected entry path.
This verifies stepped-task teardown, not complete private-resource or
register/breakpoint coverage. Integrated no-FPU retained builder PID 3614380,
single-step retained builder PID 3631600 and workstation QEMU PID 3631601
remain directly confirmed live. Their pending results are separate gates;
main OS source remains ABI 40 and no release completion is claimed.

Captured-register editing TDD gate started (2026-10-05):
tools/test-i386-debug-register-edit.py derives the actual INT3/store/S/G
fixture and requires the original TaskRegAddr(CTask *,I64) I64-pointer API.
Before stepping, captured EAX must equal 0x11223344; assigning 0x55667788
through that pointer must change the next single-stepped store and final
function result. Existing mode/flags/public-heap checks remain. Dependency
hashes pin both imported debugger checkers; source/checker identities are
checked. This is an EAX semantic gate, not full register/API completion or
an original-runtime oracle. Fixture construction and Python syntax pass.
The unmodified step candidate runs as the expected red in
build/debug-register-edit-red; runtime verdict remains pending. Existing
qualification jobs and candidate sources remain unchanged.

Register fixture and isolated implementation work (2026-10-05):
build/debug-register-edit-red terminates FAIL after the verified pre-store
checkpoint; frontend reports Invalid lval at the debugger pointer declaration.
This does not establish the intended missing-API red. The fixture now declares
its I64 pointer during normal setup and assigns TaskRegAddr(Fs,0) in the
debugger. The corrected run is build/debug-register-edit-assignment-red;
verdict and precise failure interpretation remain pending.

The isolated main-only clone build/debug-register-prototype retains fork-only
origin and implements the original TaskRegAddr switch/pointer shape. Captured
32-bit registers populate canonical public I64 task slots; seven POPAD-restored
register slots copy back before exception return. Scheduler inspection confirms
switching uses private CI386Context, avoiding debugger-shadow clobber by yield.
ESP is displayed from PUSHAD's saved ESP plus the five exception words; edits
to ESP, RIP and flags need a complete return-frame policy and remain open,
as do other-task/register-bank and invalid-index semantics. This candidate is
not qualified or promoted. The full source archive is
 docs/patches/i386-debug-register-candidate.patch (applies cleanly to main).
Its fresh original bootstrap runs under PID 3636946. An earlier accidental
bootstrap launch before register edits was explicitly stopped; its outputs
are not register evidence. Cross build and runtime green remain required.

Captured EAX inspection/editing first runtime green (2026-10-05):
the register candidate passes fresh original two-generation bootstrap;
all 1269 source-manifest hashes are independently rechecked. Cross build,
31 FileRuntime binding guard and 386 boot audit pass (96 BIOS / 33 protected
mode instructions). Native kernel stays 483208 bytes. Candidate image SHA:
e4982d319372819149be514d3c3a4b63bc90c9238ebf6d39055de717a520cc64.

The first candidate runtime run failed only because pointer assignment prints
its dynamic address. A visually inspected screenshot establishes this fixture
mismatch, not an OS failure. The checker now evaluates the assignment's
non-null comparison and expects 1, avoiding address-dependent VGA output.
build/debug-register-edit-nonnull-green/result.json passes 17 commands on
486,-fpu / 8 MiB, startup 25.954454 seconds, all exact VGA checkpoints and
unchanged source. TaskRegAddr reads captured EAX=0x11223344; writing the
original I64 pointer changes the next stepped store and final G result to
0x55667788. Mode/flags and shell recovery pass. Five repeated cycles run in
build/debug-register-edit-repeat; the matching stable-output baseline red
runs in build/debug-register-edit-nonnull-red. Their results remain pending.
This is one register's semantic green, not full debugger or release coverage.

The unchanged single-step candidate now passes six-module native construction
in build/debug-single-step-native-build. Its dependent retained installation
is directly confirmed live as PID 3640181. Full native generations remain
pending. The register candidate has not yet passed its own native generation
or full workstation gates and remains an archived isolated implementation.

Step workstation green and independent register-cycle fixtures (2026-10-05):
build/debug-single-step-workstation/result.json passes all 513 commands on
486,-fpu / 8 MiB, startup 26.706914 seconds and visible long-document update
0.266207 seconds. Exact VGA and twenty exact shared-heap development cycles
pass. This is the unchanged step-enabled candidate, not the newer register
candidate's workstation qualification.

The five-cycle EAX checker fails before completing its first interaction.
Inspection finds a fixture aliasing bug: base repetition shares one interaction
object and the register wrapper inserts its actions once per repeated list
entry. A new two-cycle ECX run also terminates before qualification; preserve
both failures. The wrapper now deep-copies each check independently before
inserting actions. A construction check proves five distinct interaction
objects, each with exactly one TaskRegAddr call. Corrected EAX repetition
runs in build/debug-register-edit-independent-repeat; runtime remains pending.

New tools/test-i386-debug-register-banks.py extends the semantic fixture to
EAX/ECX/EDX/EBX/ESI/EDI using their original register numbers. Each selected
register is loaded before INT3 and supplies the subsequent store; debugger
pointer inspection/editing must change its stepped result. All six fixtures
construct within the console input limit, with dependency hashes pinned.
The corrected two-cycle-per-register chain runs in
build/debug-register-banks-independent-pipeline.py; results are pending.
EBP/ESP, instruction-pointer/flags edits, complete other-task state and release
coverage remain open. Register candidate six-module native construction is
directly confirmed live as PID 3641122; prior step-source native builds cannot
substitute for it. Candidate sources and main OS remain unchanged.

Repeated register editing and wider candidate qualification (2026-10-05):
build/debug-register-edit-independent-repeat/result.json passes five EAX
inspection/edit/store/S/G cycles and 49 commands, exact VGA, startup 26.964408
seconds on 486,-fpu / 8 MiB, unchanged image and pinned dependencies. This
confirms the fixture aliasing correction and repeated EAX semantics including
existing warmed public heap/mode/flag checks. The bank chain's ECX test passes
two cycles and 25 commands, startup 27.217041 seconds; EDX is running, other
bank verdicts remain pending. Complete register coverage is not claimed.

The register candidate full 513-command workstation runs in
build/debug-register-workstation (Python 3641740 / QEMU 3641741), and
stepped-task teardown runs in build/debug-register-forced-kill (3641747 /
3641748), both 486,-fpu / 8 MiB. Six retained native modules are being built
by directly revalidated PID 3641122. A dependent chain, directly live as
3641972, requires that exact build before installation, full native flat
construction and installed audit, then a second retained build with exact
installed comparison, installation/full flat/audit and twelve-module/flat/
boot identity. Outputs are build/debug-register-{native-install,selfhost,
selfhost-audit,gen2-native-build,gen2-native-install,gen2-selfhost,
gen2-selfhost-audit,generation-identity}. Its prototype auditor and matching
stage listing are used. No pending gate is a pass, and earlier step/cache
candidate evidence cannot qualify the updated register console. Main remains
unchanged while candidate sources are pinned. No release completion claimed.

Wider register editing and explicit G address TDD (2026-10-05):
the corrected bank chain passes ECX/EDX/EBX/ESI/EDI, each two semantic
edit/step/resume cycles with 25 commands, exact VGA and unchanged image.
Startup seconds respectively 27.217041, 33.844262, 27.508514, 29.485299,
30.344232. The final EAX bank run remains pending; its separate five-cycle
EAX gate already passes. This does not cover EBP/ESP or other-task contexts.
build/debug-register-forced-kill/result.json passes stepped-task teardown
on the register source, 13 commands, startup 33.758595 seconds, exact VGA,
unchanged image, surviving debugger and parent public heap recovery.

New tools/test-i386-debug-go-address.py specifies original G(ip) behavior:
a real INT3 stops before MOV EAX,0x55667788; explicit G skips that verified
five-byte instruction so a subsequent store preserves 0x11223344. Ordinary
continuation would store 0x55667788, making the chosen-IP effect observable.
Opcode and all immediate bytes are checked before the trap. The first run
build/debug-go-address-red failed at setup because pointer assignment printed
an address; this is fixture failure, not OS evidence. The corrected fixture
assigns inside a U0 helper and runs in build/debug-go-address-quiet-red.
Verdict remains pending. It preserves independent repeated interactions and
pins dependencies; other-task resume and managed breakpoints remain open.
Register full workstation/native generations remain pending on unchanged
sources. Release completion and promotion are not claimed.

Six-register edit chain complete; explicit-address resume red established
(2026-10-05): build/debug-register-banks-independent-pipeline.json passes
all six EAX/ECX/EDX/EBX/ESI/EDI runs, each two cycles, 25 commands, exact VGA,
pinned dependencies and unchanged candidate image. EBP/ESP and complete
other-task state remain open; this is not complete debugger coverage.

build/debug-go-address-quiet-red terminates FAIL at G(CpuResumeIp) after
opcode/immediate-byte and pre-store checks pass and a real INT3 debugger
entry. Debug output records THROW DbgArg; the final VGA checkpoint shows
G(CpuResumeIp) failing to resume. This establishes the intended missing
explicit-address behavior, separate from the earlier setup-output failure.

A main-only fork-origin clone build/debug-go-address-prototype now sets the
saved exception EIP and public task RIP for explicit G/S addresses while
preserving default behavior. Explicit address in a non-CPU debug session
still raises DbgState; other-task arguments remain unimplemented. Its fresh
original two-generation bootstrap passes with all 1269 source hashes
independently verified. Cross build is running; no runtime green is claimed.
Full source archive docs/patches/i386-debug-go-address-candidate.patch applies
cleanly to main. Earlier register and step sources remain unchanged during
live native/workstation/generation qualification. Release remains open.

Explicit G/S address observable greens (2026-10-05): candidate cross build
passes 31 bindings and 386 boot audit, 96 BIOS / 33 protected instructions;
kernel remains 483208 bytes. Image SHA-256:
e166c4767d1b036b50b49520ad653444318b58cc7d50cc91f048acf12118908e.
build/debug-go-address-green/result.json passes explicit G(ip) skip/store/
return semantics with 17 commands, startup 33.702441 seconds, exact VGA,
restored mode/flags and unchanged source on 486,-fpu / 8 MiB.

New tools/test-i386-debug-step-address.py derives the same verified skip
fixture, invokes S(ip), requires fresh vector-1 debugger reentry after the
chosen store but before function completion, and then G back. Baseline
build/debug-step-address-red fails with THROW DbgArg after the trap;
build/debug-step-address-green/result.json passes all 17 commands, startup
34.285580 seconds, exact VGA and unchanged source. This establishes both
address-resume and address-step behavior, not argument acceptance alone.
Repeated interactions stay independent and all imported test sources are
hash-pinned. Explicit addresses in non-CPU sessions and other-task resume,
ESP/RIP direct edits, managed breakpoints and complete debugger coverage
remain open; no release completion or promotion is claimed.

Five G(ip) cycles run in build/debug-go-address-repeat and five S(ip) cycles
in build/debug-step-address-repeat. This changed console's six native modules
build in build/debug-go-address-native-build (KVM); earlier step/register
native outputs cannot qualify it. All three current-source gates are pending.
Register-source full workstation/generation and original step generation
qualification continue on their unchanged sources.

Repeated explicit-address cycles and tracked native-generation runner
(2026-10-05): build/debug-go-address-repeat/result.json and
build/debug-step-address-repeat/result.json each pass five cycles and 49
commands on 486,-fpu / 8 MiB, exact VGA, restored mode/flags, warmed public
heap checks and unchanged image. Startup 31.922704 / 32.074851 seconds.
These qualify repeated current-task G(ip)/S(ip), not other-task resume or
complete debugger/release behavior. Native builds remain pending.

New tools/test-i386-native-generations.py replaces candidate-specific temporary
chain scripts for future qualification. It consumes an already qualified six-
module retained build and matching candidate repository/stage listing, then
runs retained install, native flat construction and installed audit, a second
retained build with exact installed comparison, second install/flat/audit,
and twelve-module/flat/boot equality. It preserves stage logs and results,
pins candidate source files including untracked HC/HH candidates plus tools,
and checks inputs/source identity before and after stages. Each stage must
report PASS; native retained origin must be guest-built supplied inputs.
It requires a fresh output directory, preserving previous evidence.
Python syntax/help pass. Actual CLI negative checks reject an incomplete
provider set before creating output, and refuse an existing evidence directory.
Full runner execution remains pending; existing live chains are not restarted.
No release-ready qualification claim is made from preflight checks.

Explicit-address candidate broad regressions and tracked generation queue
(2026-10-05): build/debug-go-address-forced-kill/result.json passes killing
an actual step-paused task, surviving debugger use and parent public heap
recovery, 13 commands on 486,-fpu / 8 MiB, startup 37.606528 seconds,
exact VGA and unchanged source. This is current address-enabled console
teardown evidence, not substituted from its register predecessor.

Full workstation runs in build/debug-go-address-workstation (Python 3649198,
QEMU 3649199); five default S cycles run in ...-default-step. Six-register
edit regression runs in build/debug-go-address-register-banks-pipeline.py,
outputs ...-register-bank-{ecx,edx,ebx,esi,edi,eax}; all are pending.
An earlier generated launcher accidentally renamed the test tool path and
terminated before testing; its failure is preserved in
build/debug-go-address-banks-independent-pipeline.json. The corrected chain
uses the unchanged tracked register-bank test and proper address-candidate
image. No runtime failure or pass is inferred from the launcher error.

Native retained builder 3648197 remains directly live. The dependent process
3649325 in build/debug-go-address-native-generations-wait.py now waits for
that exact handle and requires six PASS modules, with the tracked runner's
SHA pinned while waiting. It then runs tools/test-i386-native-generations.py
into fresh build/debug-go-address-native-generations. State is
build/debug-go-address-native-generations-wait.json. This is queued first
full execution of the tracked runner; no generation PASS yet. Earlier live
step/register/native and integrated no-FPU gates continue without restart.
Main OS source remains unpromoted and the full release objective stays open.

Managed breakpoint lifecycle TDD started (2026-10-05): new
 tools/test-i386-debug-breakpoint-lifecycle.py derives a bounded executable
NOP fixture and specifies original BptS/BptR/BptFind/B/B2 return values,
duplicate installation, registration without live patching, toggle semantics,
two-breakpoint removal count and exact byte/list restoration. Two rounds
construct as 48 commands within the console input limit. Original contract
source and imported fixture dependencies are pinned. The expected red runs
in build/debug-breakpoint-lifecycle-red on the fixed address-resume candidate;
no verdict yet. This is lifecycle coverage, not managed CPU trap, rewind,
step/rearm, shared-code ownership, task-exit cleanup or original-runtime oracle.
Those remain required debugger work; no narrower completion is claimed.

Current address-source regression results: build/debug-go-address-default-step
passes five default S cycles and 49 commands, while ...-register-bank-ecx
and ...-register-bank-edx each pass two edit/step/resume cycles and 25 commands.
These establish retained default behavior alongside explicit-IP greens;
remaining banks, full workstation and native generation gates continue on
unchanged candidate sources. Release and promotion remain open.

Managed breakpoint lifecycle missing-API red and candidate implementation
(2026-10-05): build/debug-breakpoint-lifecycle-red terminates FAIL at the
first BptS(CpuBptAddr), after normal executable/NOP fixture preparation.
The frontend logs Undefined identifier and COMMAND ERROR. This establishes
the missing lifecycle entry point; no later lifecycle assertion is a pass.

A fork-origin main-only clone build/debug-breakpoint-prototype restores the
canonical CBpt shape from Kernel/KernelA.HH and the original BptFind/BptS/
BptR/B/B2 list/return/opcode semantics from Kernel/KDbg.HC. Native IRQ save/
restore replaces PUSHFD/CLI/POPFD; current task uses I386TaskSelf, with the
public allocation API for task-owned records. Five public bindings raise
console exports from 140 to 145. Fresh original bootstrap is running in
build/debug-breakpoint-candidate-bootstrap.log. Full source is archived in
 docs/patches/i386-debug-breakpoint-candidate.patch and applies cleanly to
main. This is an unqualified candidate; cross/runtime gates are still needed.
Managed trap rewind, stepping/rearming, task/code ownership and exit cleanup
remain required implementation and test work. Existing address/register/step
candidate sources are unchanged while their qualification jobs continue;
main OS remains unpromoted and release completion is unproven.

Breakpoint candidate build qualification and managed-store trap TDD
(2026-10-05): fresh original two-generation bootstrap and cross build PASS,
with 1270 source-manifest hashes independently verified, 31 FileRuntime
bindings, 386 boot audit (96 BIOS / 33 protected instructions) and unchanged
483208-byte native kernel. The lifecycle candidate's runtime gate runs in
build/debug-breakpoint-lifecycle-green; PASS is still pending.

New tools/test-i386-debug-managed-trap.py installs a managed BptS at the
actual store opcode following the bounded NOP fixture. S must restore and
execute that store before reentry; G must complete and rearm the opcode,
then B2 must remove the record and restore code. It preserves existing
result/mode/flags/public-heap checks and pins fixture dependencies.
Independent two-cycle interactions construct within console input limits.
The expected implementation-gap red runs in build/debug-managed-trap-red
on the lifecycle-only candidate; no runtime verdict yet. Original contract
inspection confirms Fault2 decrements RIP for INT3 and task switching restores
old-task breakpoint bytes/reapplies runnable-task breakpoints unless disabled.
Full native implementation must preserve those behaviors, task/code ownership
and cleanup. Current candidate does not implement rewind/step/rearm or task
switch handling; lifecycle compilation is not full debugger completion.
Earlier live qualification stays pinned; main and release readiness remain open.

Breakpoint lifecycle green and register native/workstation qualification
(2026-10-05): build/debug-breakpoint-lifecycle-green/result.json passes
28 commands on 486,-fpu / 8 MiB, startup 34.466079 seconds, exact VGA and
unchanged source. Original lifecycle return values, duplicate/live=False/
toggle/two-record clear and byte/list restoration pass. Five rounds now run
in build/debug-breakpoint-lifecycle-repeat. Managed store-trap runtime is
still pending and is not qualified by this lifecycle green.

build/debug-register-native-build/result.json passes all six native retained
modules; build/debug-register-workstation/result.json passes all 513 commands,
exact VGA and twenty exact shared-heap development cycles on 486,-fpu / 8 MiB.
Startup 33.207068 seconds, long-document update 0.340859 seconds. Retained
installation passes and full native flat construction is directly live as
3651884 / QEMU 3651885. These qualify register-source construction/workstation,
not the later address/breakpoint consoles or complete release readiness.

Managed breakpoint architecture next: the existing scheduler bind callback
runs with IRQs masked after selecting next but before context swap, while
FS still names the outgoing task. A retained wrapper can restore outgoing
record bytes, apply incoming breakpoints unless TASKf_DISABLE_BPTS, then
chain the original platform binder. Preserve its segment/current-task checks
and avoid allocation/scheduling in the hook. Captured managed INT3 needs
record lookup at saved EIP-1, rewind and original-byte restoration; S disables
breakpoint application and requests TF, G clears disable/TF and reapplies.
Direct G at a breakpoint must retain the original step/remove requirement.
Task cleanup must restore/remove records while public heaps/code still live,
including forced kill from another terminal. Shared-code ownership, other-task
registration/resume and original runtime comparisons need dedicated tests.
This design follows original Fault2 and Sched.HC behavior; it is not implemented
or proved by the existing hook alone. Candidate sources stay fixed during
qualification; main OS remains unpromoted and release scope remains intact.

Managed store-trap semantic red and isolated implementation (2026-10-05):
build/debug-managed-trap-red fails after actual managed INT3 and S reentry.
The visually inspected one-store checkpoint returns 0 for the expected
stored marker before function completion. This demonstrates lost original
instruction execution; it is separate from lifecycle API presence.
Five lifecycle rounds pass in build/debug-breakpoint-lifecycle-repeat.

A fork-only main clone build/debug-managed-prototype implements managed
record lookup at saved EIP-1, rewind, restoration and disabled breakpoint
state for S; G re-enables bytes unless still stopped on an installed
breakpoint (prints a step/remove instruction and remains in debugger).
A retained scheduler bind wrapper restores outgoing bytes, applies incoming
records unless disabled, then chains the original platform binder. It does
not allocate or schedule. First record registration installs a task cleanup
wrapper and preserves the previous callback, including registration inside
an active debugger. Cleanup restores bytes/frees records before chaining
previous cleanup while task heaps/code remain live. A private task callback
slot is added; kernel/flat-size effects still need fresh build evidence.
These paths are implemented, not yet verified by task-switch/exit tests.

Full source is docs/patches/i386-debug-managed-candidate.patch (clean apply
to main). Fresh original bootstrap runs in
build/debug-managed-candidate-bootstrap.log. Cross build, managed runtime
green, shared-code ownership, other-task controls, cleanup and broader/native
qualification remain required. Existing live source epochs stay unchanged;
no promotion, complete debugger or release readiness is claimed.

Managed candidate cross parse failure corrected (2026-10-05): original
bootstrap passes on the initial managed source, but cross build terminates
FAIL while compiling ConsoleRuntime. Preserved compiler-log.DD identifies
Debugger.HC line 143: HolyC rejects a function-pointer local declaration with
an initializer. Separate declaration and assignment correct that syntax.
The archived managed patch is updated and applies cleanly; a fresh bootstrap
runs in build/debug-managed-corrected-bootstrap.log to pin the changed source
before another cross build. No cross or managed runtime green is claimed;
size/386/cleanup/native gates remain pending. The failure is compile evidence,
not an observation timeout, and previous successful source epochs remain
untouched.

Independent progress: build/debug-register-selfhost/result.json now passes
full native flat construction/installation/boot on register source; its
second generation is pending. build/debug-single-step-gen2-native-build passes
all six modules with exact installed comparison; complete twelve-module/flat/
boot equality remains pending. Later managed/address source is not qualified
by those results. Main and release completion remain open.

Managed console integration fix and kill fixture prepared (2026-10-05):
corrected bootstrap PASSes, but the separate corrected cross build terminates
FAIL at a new integration issue. compiler-log.DD reports missing Print/PutChars
headers for the breakpoint warning's implicit string-output statement.
The candidate now uses existing I386TextWrite(&console_text,...) and a fresh
bootstrap runs in build/debug-managed-console-bootstrap.log. The source
archive is updated and applies cleanly. Neither failed build is a runtime
PASS; cross, size, 386 and managed runtime evidence remain pending.

New tools/test-i386-debug-managed-kill.py prepares parent-owned executable
code, installs its breakpoint from a child terminal and optionally steps,
then kills that child from the survivor. It requires original entry byte
restoration, successful execution of the parent function by the survivor,
surviving Dbg/G and exact parent public heap recovery. Terminal fixture hash
is pinned; both entry paths construct within console limits and syntax passes.
Runtime is not started before a usable managed candidate exists. This does
not prove all concurrent/shared-code ownership or private resource cleanup.
Existing qualification continues on unchanged earlier epochs; main remains
unpromoted and the complete release objective is still open.

Managed candidate cross green; current runtime gates started (2026-10-05):
console-output corrected original bootstrap and cross build pass. All 1270
source hashes are independently checked; 31 bindings and 386 boot audit pass
(96 BIOS / 33 protected instructions). The private cleanup slot leaves native
kernel at 483208 bytes. Image SHA-256:
86bca6ce6a1196c52a28a71024e0fe0d2792c60fd3b6b6427da4de26d59f0b52.
Managed store-step/rearm runs in build/debug-managed-trap-green, stepped
managed parent-code victim kill in build/debug-managed-kill-step, and lifecycle
regression in build/debug-managed-lifecycle. All verdicts are pending; compile
success does not prove scheduler, cleanup or managed execution semantics.

Single-step-source native generations now pass full twelve-module/flat/boot
identity. Independent rerun build/debug-single-step-generation-identity-recheck
passes: flat 487336 bytes, SHA
 a959ce9581ca34cd23d8e946a4fa6b56771975f5a3ff1d8fd16a8b2a3e0ff5b8;
boot-area SHA
 f87f7191e2a8e4ce632405fa1810aaf1a402814395ce25174de7502bf6eefd11.
Both volumes have 16 directories, 872 files, 19077 owned sectors and bitmaps
matching reachable extents; whole images differ, not claimed byte-identical.

Address-source full workstation passes 513 commands and twenty exact shared-
heap development cycles on 486,-fpu / 8 MiB: startup 37.885299 seconds,
long-document update 0.450070 seconds, exact VGA. Its six native retained
modules also pass; tracked tools/test-i386-native-generations.py is directly
live as PID 3660287 at gen1-install. Full tracked-chain completion remains
pending. Neither earlier-source generation nor workstation results substitute
for managed source qualification; main remains unpromoted and release open.

Managed breakpoint first runtime greens and deferred-registration fixture
(2026-10-05): build/debug-managed-trap-green/result.json passes 21 commands
on 486,-fpu / 8 MiB, startup 29.533144 seconds, exact VGA and unchanged source.
Managed store opcode trap rewinds, S executes the restored store before
reentry, G rearms it, and B2 removes/restores the record. Result, mode/flags
and existing public heap probe pass. This is demonstrated semantic red to
green, not just API binding. Five cycles run in ...-trap-repeat.

build/debug-managed-kill-step passes 15 commands, startup 29.425224 seconds,
exact VGA and unchanged source. Child-installed breakpoint on parent code
is stepped, victim killed, entry byte restored, shared function executes in
the survivor, then surviving Dbg/G and parent public heap recovery pass.
The initial-entry kill path now runs in ...-kill-entry. Complete concurrent
ownership/private-resource coverage and full original API remain open.

Managed-source lifecycle test terminates FAIL at the separate command after
BptS(...,live=FALSE). Its expected unpatched-byte assertion conflicts with
the original scheduler model: deferred registration avoids patching during
the call, but the next task restore applies registered breakpoints. The
checker now performs registration/byte-and-record checks/removal in one
synchronous helper before command input can yield, preserving the immediate
API contract without forbidding scheduler reapplication. Corrected runtime
runs in build/debug-managed-lifecycle-deferred; no pass yet. Preserve the
failure in ...-lifecycle. Full workstation runs in ...-workstation on this
fixed managed image. Existing candidate sources remain frozen during gates;
G2/other-task/debugger and native/release completion remain open.

Repeated managed execution/cleanup greens and G2 TDD (2026-10-05):
build/debug-managed-trap-repeat passes five managed store trap/step/rearm/
remove cycles and 69 commands on 486,-fpu / 8 MiB, startup 27.675738 seconds,
exact VGA, result/mode/flags/public-heap probe and unchanged source.
...-kill-entry passes 15 commands, startup 33.631613 seconds, restoring and
executing shared parent code in the survivor after killing a managed-entry
victim. ...-lifecycle-deferred passes the corrected immediate deferred
registration semantics and all lifecycle assertions, 27 commands, startup
27.518313 seconds. Complete concurrent ownership remains open.

New tools/test-i386-debug-go-clear.py requires original G2 behavior at the
managed store trap: remove records, resume the restored store, verify result,
restored code/list, empty B2 and flags/mode. The expected red
build/debug-go-clear-red terminates with Undefined identifier at G2 after
managed trap preparation; prior managed greens do not supply this API.
A fork-origin main clone build/debug-go-clear-prototype binds G2 to a
clear-then-NativeDebugGo wrapper with preserved current-task/state checks.
Console exports rise 145 to 146. Fresh original bootstrap passes; cross
build is running in build/debug-go-clear-build.log, runtime green pending.
Full archive docs/patches/i386-debug-go-clear-candidate.patch applies cleanly
to main. Other-task G2/focus, direct register control and complete debugger/
release qualification remain open; current managed source stays frozen for
workstation tests and main OS remains unpromoted.

G2 clear/resume and installed-breakpoint G guard green (2026-10-05):
fresh candidate cross/31-binding/386 audit PASS with unchanged 483208-byte
kernel; all 1270 bootstrap source hashes independently verified. Image SHA:
8979dc89c46e81d76e4b6ab874e6b11d2309a1681d5b4c583664c69d60d6a90f.
build/debug-go-clear-green passes 21 commands, startup 31.242170 seconds,
exact VGA, correct restored-store result, empty breakpoint list/B2 and
mode/flags/source recovery on 486,-fpu / 8 MiB. The missing-G2 red is now
an observable clear-and-resume green.

New tools/test-i386-debug-go-blocked.py first issues G at the managed store
breakpoint, requires visible guidance and a still-zero store/function marker,
then G2 clears/resumes. ...-blocked-green passes 21 commands, startup
37.109442 seconds, exact VGA and unchanged source. This verifies stopped
execution, not a warning alone. ...-go-clear-managed-regression passes two
ordinary managed S/G/rearm/remove cycles, 33 commands, startup 31.189027
seconds. Broader other-task/ownership/direct-register/release scope remains
open. Five G2 cycles run in ...-go-clear-repeat, five guarded G/G2 cycles in
...-go-blocked-repeat, and current-source six native modules build in
build/debug-go-clear-native-build. No pending gate is a pass; previous
managed/address native results cannot qualify the changed console. Main
remains unpromoted and complete release readiness remains unproven.

Repeated G2/guard green and stack-register inspection gate (2026-10-05):
build/debug-go-clear-repeat and build/debug-go-blocked-repeat each pass five
cycles and 69 commands on 486,-fpu / 8 MiB, exact VGA, restored store/code/
record state, mode/flags/public heap probe and unchanged image. Startup
33.040126 / 34.479657 seconds. Full workstation now runs in
build/debug-go-clear-workstation. Native retained builder 3668924 is directly
confirmed live; the dependent build/debug-go-clear-native-generations-wait.py
requires that exact six-module PASS and pinned tracked runner before fresh
build/debug-go-clear-native-generations. Both broader gates remain pending.

New tools/test-i386-debug-stack-registers.py compares TaskRegAddr ESP/EBP
slots with GetRSP/GetRBP captured inside the interrupted function before
INT3, then requires ordinary S/G store/result/mode/flag recovery. It pins
fixture dependencies and constructs independent repeated interactions;
source helper is 199 characters, within the console limit. Native exception
entry inspection confirms PUSHAD precedes four segment pushes: saved ESP
points to vector/error/EIP/CS/flags, hence the candidate's +20 conversion to
interrupted ESP. Runtime in build/debug-stack-registers is pending; the
source calculation alone does not prove public stack-register correctness.
Stack editing, instruction-pointer/flags edits, other-task controls,
concurrent ownership, original runtime comparisons and release completion
remain open. Main OS and live candidate sources remain unchanged.

Physical ESP/EBP inspection green and register native generations verified
(2026-10-05): initial build/debug-stack-registers fails its combined comparison
of debugger slots with GetRSP/GetRBP values from separate HolyC assignments.
The expectation compares different evaluation points; backend source shows
GetRSP emits the current ESP inside expression evaluation, which can include
compiler temporaries. This fixture does not establish a debugger conversion
bug. Preserve its failure. The checker now captures physical ESP/EBP in one
assembly block immediately before NOP/INT3, storing snapshots in live locals
reachable through globals, without expression evaluation between capture
and trap. It then compares public I64 slots with those U32 snapshots and G
returns the expected result with mode/flags restored.

build/debug-stack-registers-asm passes 16 commands on 486,-fpu / 8 MiB,
startup 34.467013 seconds, exact VGA and unchanged image; dependency/checker
identities remain pinned. Five independent cycles run in ...-asm-repeat.
This proves inspection, not ESP/EBP editing or complete debugger coverage.

Register-source full native generation equality PASS is independently rerun
in build/debug-register-generation-identity-recheck: twelve identical native
modules, flat 487336 bytes with SHA
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f,
boot area SHA
39c511c316094a6cf4dcdd01aab0f77b307637e1a6772861ad9764eca09a360f.
Both volumes have 16 directories, 872 files, 19089 owned sectors and bitmaps
matching reachable extents. Whole disk images differ; no whole-volume identity
claim. Later managed/G2 generations remain separate pending gates. Main OS
is unpromoted and the full self-hosting/release objective remains open.

Repeated physical stack inspection and task-specific shared-code breakpoint
proof (2026-10-05): build/debug-stack-registers-asm-repeat passes five cycles
and 44 commands on 486,-fpu / 8 MiB, startup 35.405312 seconds, exact VGA,
physical ESP/EBP snapshots, result/mode/flags/public heap probe and unchanged
source. Stack editing remains separate unimplemented scope.

New tools/test-i386-debug-breakpoint-task-switch.py runs two terminals sharing
parent-owned SharedProbe code. One installs a breakpoint, the other executes
that code without trapping and sees no own record but the owner's record;
the owner then traps, G2 clears/resumes, exits, and the survivor verifies and
executes restored code. build/debug-breakpoint-task-switch passes 13 commands,
startup 33.523962 seconds, exact VGA, unchanged source and parent public heap
recovery. This directly exercises scheduler byte application and per-task
lists rather than inferring them from source. Fixture dependency is pinned.

The same checker now accepts --both-own: both terminals register the same
address, first owner traps/clears/exits, second retains its independent record
and traps/clears before code restoration/survivor exit. That fresh gate runs
in build/debug-breakpoint-same-address; verdict pending. Sequential owner
traps do not prove simultaneous debugger sessions, external other-task G/S,
all concurrent ownership or complete release readiness. All candidate sources
remain fixed while native/workstation gates continue; main OS unpromoted.

Same-address ownership and explicit-address native generations verified
(2026-10-05): build/debug-breakpoint-same-address passes --both-own,
13 commands on 486,-fpu / 8 MiB, startup 28.966642 seconds, exact VGA
and unchanged source. Both terminals independently own the same code
address; clearing/exiting the first preserves the second record and its
subsequent trap. This covers sequential ownership, not simultaneous debuggers.

build/debug-managed-workstation passes 513 commands on 486,-fpu / 8 MiB,
startup 34.665548 seconds and long-document update 0.273430 seconds.
The later G2 source separately passes build/debug-go-clear-workstation:
513 commands, startup 36.198762 seconds, long-document update 0.375136
seconds, exact VGA and 20 bounded document cycles with shared heap recovery.
Its six retained modules pass in build/debug-go-clear-native-build;
the exact live native-generation runner is now qualifying gen1-install.
These results do not substitute for installed-image workflow acceptance.

The earlier explicit-address G/S candidate completes the tracked two-generation
runner in build/debug-go-address-native-generations. Independently rerunning
its final audit in build/debug-go-address-generation-identity-recheck passes:
all twelve modules match, flat size 487336 bytes, flat SHA256
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f,
boot-area SHA256
39c511c316094a6cf4dcdd01aab0f77b307637e1a6772861ad9764eca09a360f.
Both volumes have 16 directories, 872 files and 19091 owned sectors;
bitmaps match reachable extents. Whole disk hashes differ, as expected.
This also provides the first complete real execution of the tracked native
qualification runner. Main OS remains unpromoted; G2 native/installed gates,
other-task and simultaneous debugger behavior, full API parity and release
artifacts remain open. The long no-FPU integrated build is confirmed live;
no terminal verdict is claimed.

Reusable installed workstation qualification (2026-10-05):
tools/test-i386-installed-workflows.py replaces the ad hoc four-job wrapper.
It requires a passing guest-built native result whose target hash matches
--disk, plus a passing installed audit with the same flat payload hash.
It runs workstation, three-boot DolDoc session, emulated speaker waveform
and pinned resource profile in parallel on TCG / 486,-fpu / 8 MiB. It pins
the disk, prerequisite results, Python helpers and VGA font before/after
execution; retains per-job logs/results and rejects existing output trees.
Preflight checks reject both existing evidence and a mismatched generation
without creating the rejected output directory. Real execution is pending
in build/debug-go-address-installed-workflows. The later G2 run is queued
behind the confirmed live native runner, waiting for gen1 installed audit;
its destination is build/debug-go-clear-installed-workflows. No four-gate
PASS or release completion is claimed until all actual results pass.

Example (substitute paths from the desired qualified generation):
python3 tools/test-i386-installed-workflows.py \
  --disk build/debug-go-address-native-generations/gen1-selfhost/target.img \
  --native-result build/debug-go-address-native-generations/gen1-selfhost/result.json \
  --installed-audit build/debug-go-address-native-generations/gen1-audit/result.json \
  --out build/new-installed-workflows

Concurrent CPU-debugger TDD gate and no-FPU retry (2026-10-05):
New tools/test-i386-debug-concurrent-traps.py keeps the first terminal paused
at INT3, focuses the second and traps there too. Required behavior is two
live contexts, expression evaluation and independent G, followed by terminal
exit and parent public heap recovery. This is stronger than sequential
same-address ownership. Its first run is build/debug-concurrent-traps-red;
verdict pending. It pins its terminal fixture and source disk. The current
candidate ConsoleCpuCapture explicitly rejects any second trap while global
console_debug_task is occupied; original Kernel/KDbg.HC Dbg2 operates on Fs
and its task continuation, so per-task paused contexts require architectural
work. No candidate source is changed during native qualification.

The previous integrated no-FPU native builder and QEMU handles disappeared
without result.json or a recorded terminal exception. Preserve that run as
incomplete, not PASS. A fresh run uses
build/file-cd-resident-integrated-no-fpu-native-build-retry, TCG / 486,-fpu /
16 MiB and a 10800-second per-command deadline (previously 7200). Its new
process is live; the launch uses a retained execution session rather than
an untracked background child. Installed address workflow speaker and
resource gates already pass; workstation and DolDoc gates are still running.
All later G2 installed-generation gates and the full release goal remain open.

Simultaneous CPU traps reproduce kernel failure; task-local session candidate
(2026-10-05): build/debug-concurrent-traps-red fails after two actual
ConcurrentTrap input calls. Its debug log reaches the first debugger, focus
switch and second INT3, then FAULT vector 3 and FAIL native kernel. This is
behavioral evidence of the global session-owner limitation, not a fixture
compilation failure. Original Kernel/KDbg.HC Dbg2 uses Fs/UserTaskCont;
independent task continuations must remain usable.

New isolated main-only fork clone build/debug-concurrent-prototype applies
all preceding candidate changes and replaces global debugger owner/go/backup/
cleanup state with private CI386Task fields. Current-task G/S/G2 and breakpoint
cleanup consult their own session. CPU capture rejects a trap within the
same active session, but accepts another task's trap. A shared IRQ-protected
session count preserves the initial debug-mode bit until the final session
returns or is killed; terminal surfaces/planes were already task-specific.
The full source patch is docs/patches/i386-debug-concurrent-candidate.patch
and applies cleanly to main. Fresh original bootstrap is running in the new
clone; no compilation or runtime green is yet claimed. G2 sources and their
native/installed gates remain fixed. Other-task controls, nested same-task
traps, direct stack/IP/flags edits, full parity and release completion remain
open. Root main contains evidence/patches only, not promoted candidate code.

Task-local debugger bootstrap qualified; shared-mode lifetime gate added
(2026-10-05): build/debug-concurrent-prototype/build/rebuild-test/result.json
records two completed original x86-64 bootstrap generations. All 1270 source
hashes are independently checked against the fixed candidate. The dependent
pipeline now runs tools/build-i386-kernel.py --test in the same clone; module
exports are underway, so a final 386 build/boot PASS is still pending.

The simultaneous-trap checker now also queries IsDbgMode in the second
terminal after its G while the first session remains paused: required answer
is 1. After both sessions exit, the parent requires IsDbgMode==0 before 42.
This verifies the shared session-count lifetime, not merely two successful
expressions. Preserve the prior red result under its recorded checker hash;
the strengthened checker has a new identity. The pipeline will then run
same-address ownership and managed single-step forced-kill regressions on
the new image. Current stage/evidence is build/debug-concurrent-pipeline.json.
No candidate promotion or complete debugger/release qualification is claimed.

Concurrent candidate diagnostic boot failure retained (2026-10-05):
The cross compiler exports all modules and completes Kernel32.BIN, but
build/debug-concurrent-prototype/build/debug-concurrent/boot/debug.log fails
inside PUBLIC HEADER PROBE: Expecting system sym in PublicDebug.HH,
PUBLIC HEADER PUBLISHED 0 and FAIL native kernel. The --test pipeline
therefore terminates at cross-build and does not run its dependent tests.
This is an unresolved full diagnostic gate; it is not a 386 build/boot PASS
and its cause has not yet been isolated to the new session changes.

Separate interactive-image qualification now runs the strengthened trap
checker in build/debug-concurrent-interactive-traps and new
tools/test-i386-debug-concurrent-kill.py in
build/debug-concurrent-interactive-kill. The latter keeps both INT3 sessions
paused, kills the first from the second debugger, requires the survivor's
mode and expression/G to remain valid, then requires mode restored and
parent heap recovery. Verdicts are pending. Retain the diagnostic failure
regardless of interactive results; it remains required work before promotion.

Concurrent paused-task kill green and diagnostic binding-order correction
(2026-10-05): build/debug-concurrent-interactive-kill passes 14 commands on
486,-fpu / 8 MiB, startup 35.755512 seconds, exact VGA and unchanged disk.
Two real INT3 sessions coexist; killing the first preserves the second's
IsDbgMode==1, expression 42 and G, then mode returns to 0 and the parent
public heap recovers. This is the pre-binding-order-correction image;
independent normal resumption of both tasks remains a separate running gate.

Kernel.HC invoked phase-0 compiler/public-header diagnostics after memory
binding but before KernelConsoleLoad. PublicDebug.HH now requires real
console exports, so that ordering cannot load the full public header set.
The new candidate moves the entire phase-0 compiler probe immediately after
KernelConsoleLoad; phase-1 and all two-phase assertions remain intact.
Updated full candidate patch applies cleanly to main. Fresh candidate
bootstrap runs in .../build/debug-concurrent-bootstrap-bound.log, then a
fresh build/diagnostic run is required before claiming the fix works.
An accidentally launched root bootstrap was stopped immediately; its partial
root build/rebuild-test output is unqualified and must be refreshed if used.
No root source changes or candidate promotion; release completion stays open.

Concurrent normal-resumption fixture focus corrected (2026-10-05):
build/debug-concurrent-interactive-traps times out at first-still-paused,
after both CPU traps, second expression/G and IsDbgMode==1 pass. The retained
PPM at startup-command-10-first-still-paused shows the parent root terminal,
not a kernel failure: focus-next from terminal Two cycles to the third/root
terminal rather than terminal One. The checker now uses TermFocus(TermOne)
and records that command in the second terminal's expected restored history.
The prior failure remains under its original checker identity. A fresh run
on the same pre-binding-order image is build/debug-concurrent-explicit-focus;
no full normal-resumption verdict is yet claimed.

The binding-order-corrected source completes both original bootstrap
generations; all 1270 manifest hashes independently match. Fresh full
build/diagnostic qualification runs in the clone's build/debug-concurrent-bound
with log build/debug-concurrent-bound-build.log. The earlier diagnostic
failure stays retained and remains unresolved until this run passes.
Other-source G2 native/installed workflows and no-FPU retry continue separately;
none substitute for qualification of the current candidate or release scope.

Independent simultaneous CPU-debugger resumption green (2026-10-05):
build/debug-concurrent-explicit-focus passes 13 commands on 486,-fpu /
8 MiB, startup 31.450751 seconds, exact VGA at every checkpoint and unchanged
source. Both terminal INT3 contexts remain alive; second expression/G works,
IsDbgMode stays 1 for the paused first context, explicit TermFocus reaches
that debugger, first expression/G works, both terminals exit and parent heap
and IsDbgMode==0 recover. This qualifies the pre-binding-order-correction
interactive image separately from the still-running corrected diagnostic build.

New tools/test-i386-debug-concurrent-repeat.py compiles shared fixture helpers
once and repeats session spawn/trap/resume/exit five times in one boot,
resetting TermDone before each cycle. Each cycle gets independently copied
VGA events; public heap and mode checks remain in every cycle. Own/base/
terminal checker and source identities are pinned. Fixture preflight verifies
five independent event lists, command length bounds and invalid cycle rejection.
Actual five-cycle execution is build/debug-concurrent-repeat; verdict pending.
The corrected --test boot now reaches console binding/root headers, but full
public-header diagnostics and all later checks still need terminal PASS.
No promotion or full release readiness is claimed.

Repeated concurrent sessions green; diagnostics separate provider load/run
(2026-10-05): build/debug-concurrent-repeat passes five cycles / 31 commands
on 486,-fpu / 8 MiB, startup 30.942262 seconds, exact VGA and unchanged image.
Each cycle verifies two live INT3 contexts, independent expression/G, shared
debug-mode lifetime and parent public heap recovery. This is still the
original task-local interactive image, not the revised diagnostic-order source.

The binding-order attempt in build/debug-concurrent-bound fails earlier at
PROBE REJECT load reclaimed, after ROOT USER HEADERS ok. Full diagnostic
acceptance is not achieved. Late loading adds the large temporary compiler
provider after console residency; allocation pressure/fragmentation is a
working hypothesis, not yet independently proven. The candidate now separates
KernelCompilerProbeLoad from execution: load before console allocations,
execute phase 0 after the real console exports bind, retain phase 1 and its
assertions/release. New fresh bootstrap and dependent --test pipeline are
running; state build/debug-concurrent-preload-pipeline.json, candidate out
build/debug-concurrent-prototype/build/debug-concurrent-preload. The updated
full patch applies cleanly to main. No diagnostic fix PASS, promotion or
complete debugger/release qualification is claimed.

Installed qualification freezes its execution helpers (2026-10-05):
The G2 installed DolDoc subprocess completes PASS, including three boots,
persistence and filesystem integrity, but its wrapper marks the job failed
with Qualification inputs changed during execution. The initial runner pinned
all root tools; unrelated concurrent debugger fixture edits invalidated that
identity. Preserve that wrapper result as unqualified; do not interpret the
wrapper failure as a DolDoc OS failure or reuse it as four-gate PASS.

Updated tools/test-i386-installed-workflows.py copies all Python helpers and
Kernel/FontStd.HC into each fresh output's harness directory. Copy digests
must match source digests, then all four subprocesses execute those copies
with snapshot cwd. Disk/prerequisite and snapshot hashes remain checked
before/after every job, so actual execution inputs stay pinned while root
work continues. Existing-output and exact-native-disk preflight remain intact.
A fresh G2 run is build/debug-go-clear-installed-frozen. Its 151 helper/font
identities independently match; process arguments confirm workstation and
DolDoc execute the frozen paths. Full four-gate verdict remains pending.
The preload diagnostic pipeline separately reaches console loading with the
provider already resident; its terminal result is still pending. Candidate
promotion, full parity and release completion remain open.

Diagnostic preload advances to scalar probe; initialization split required
(2026-10-05): build/debug-concurrent-preload-pipeline terminates at cross-build.
Its boot log passes console binding/root headers, provider loading and
backend/parser/symbol probes, then logs all six SCALAR TYPE records and
FAIL native kernel. This is distinct from the earlier missing debugger export
and late provider load failures. The current moved phase-0 execution runs
after root public/scalar declarations publish; the fixtures expect to create
those declarations themselves. Full diagnostics are still failing, not fixed.

Next architectural correction: split console export binding from root-header
publication. Keep temporary provider loading early; bind real console/debugger
exports while leaving public root headers deferred; execute original phase-0
compiler fixtures; load scalar/public root declarations; retain ordinary
startup and phase-1 fixtures. Express the split as an explicit private config
option plus a root-header service callback, version the changed private
console interface and update its size/version audits. Normal boot should
publish root headers once as before. Do not fake missing exports, weaken
scalar assertions or drop either phase. This needs a new source epoch,
bootstrap, full diagnostic run and interactive/native regression qualification.
The current patch remains an unqualified intermediate implementation.
Frozen G2 installed gates and its original native chain remain separate live
qualification work; no promotion or release completeness is claimed.

Console export/root-header initialization split implemented in candidate
(2026-10-05): private console interface becomes version 38, adding
CI386ConsoleConfig.defer_root_headers and CI386ConsoleServices.root_headers.
ConsoleInit still binds actual services and ownership hooks, then normally
publishes root headers through ConsoleRootHeaders. Diagnostic initialization
sets the deferral flag, leaves scalar/public root publication until phase-0
compiler diagnostics finish, then loads scalar aliases and invokes the same
root-header callback. The provider remains preloaded early; phase 1 and all
existing assertions remain. Builder requires the new callback export and
version 38. Full patch applies cleanly to main.

A fresh original bootstrap runs in the clone's
build/debug-concurrent-bootstrap-split.log; dependent full --test and
concurrent/breakpoint/managed-kill regressions are queued in
build/debug-concurrent-split-pipeline.json, candidate output
build/debug-concurrent-prototype/build/debug-concurrent-split. This is an
implemented source candidate, not a build/runtime PASS. Earlier diagnostic
failures and earlier interactive greens remain tied to their original images.
No root candidate promotion or complete parity/release claim.

Direct public instruction-pointer TDD gate added (2026-10-05):
New tools/test-i386-debug-public-ip.py derives the independently verified
five-byte MOV skip fixture from the G(ip) checker. It changes Fs->rip via a
U0 helper and invokes default G, requiring the original EAX marker to reach
the store/result instead of the skipped MOV immediate. This proves physical
instruction selection rather than merely reading a changed shadow field.
Own/base/G-address/single-step/CPU checker and input image identities are
pinned. Fixture preflight verifies five independent interactions and line
length bounds. First run build/debug-public-ip-red uses the fixed G2 image;
verdict pending. Direct stack/flags edits and other-task control remain open.

The split-initialization candidate completes both bootstrap generations;
its dependent pipeline independently checks all 1270 source hashes and now
cross-builds in build/debug-concurrent-split. Its diagnostics and subsequent
regressions still need terminal PASS. Keep this source fixed throughout that
qualification; any direct-IP implementation belongs to a later source epoch.
Frozen installed G2 speaker/resource gates pass; remaining gates continue.
No root candidate promotion or release-complete claim.

Public RIP edit red; resident bridge publication deferred with root headers
(2026-10-05): build/debug-public-ip-red reaches INT3, accepts direct Fs->rip
editing and G, then times out at the stored-result check. The saved CPU return
frame still controls default G. Candidate NativeDebugGo and NativeDebugStep
now copy the public RIP into saved eip after optional explicit-IP selection;
G2 shares the G path. Stack/flags edits and other-task controls remain separate.

Full split diagnostics still fail after all six BOOTSTRAP SOURCE records.
ConsoleInit installed the resident reader bridge before phase 0, while early
bootstrap fixtures enforce exact compiler allocation reclamation. The cache's
role in that failure is a working hypothesis. Candidate now installs this
bridge in ConsoleRootHeaders, alongside root declaration publication after
early diagnostics. Export binding remains available before phase 0; normal
boot still uses the same root publication function. No assertions are removed.

Updated full patch applies cleanly to main. Fresh source bootstrap and full
--test/public-IP/concurrent/ownership/managed-kill pipeline are running or
queued in build/debug-concurrent-reader-ip-pipeline.json; candidate output
build/debug-concurrent-prototype/build/debug-concurrent-reader-ip. Neither
new correction is yet a qualified build/runtime green. G2 native chain has
advanced to gen2-selfhost; frozen installed DolDoc joins speaker/resource
with PASS, workstation remains pending. Main OS is unpromoted and release
completion remains open.

Installed audit now pins whole input disks (2026-10-05):
tools/audit-i386-guest-image.py records source/installed disk SHA256 plus
stage-listing identity, and checks all unchanged before publishing PASS.
Installed workflow preflight requires installed_disk_sha256 to match the
native target disk. This rejects stale/legacy audits that identify only the
flat payload. The actual main-baseline second-generation audit passes in
build/public-file-find-gen2-identity-audit, flat 487312 bytes, whole disk SHA
f9f20d1723af29b08c92f80e5729f0c6528c0c46bafded44dc1f268365649d2c;
independent hashing confirms both recorded disk identities. Legacy G2 audit
preflight rejects without creating output. Existing frozen runs retain their
original weaker prerequisite schema; future qualification requires re-audit.

Reader/IP candidate diagnostics advance through bootstrap/parser/task layout,
then fail PublicDebug.HH with Invalid lval during actual public-header loading.
The source fixes are not full diagnostic greens. Retain
build/debug-concurrent-reader-ip/boot in the candidate clone. A separate
focused direct-IP run uses that generated interactive image in
build/debug-public-ip-green; verdict pending. This does not bypass the
unresolved diagnostic gate or establish promotion/release completeness.

Direct public RIP editing green; G2 native generations independently verified
(2026-10-05): build/debug-public-ip-green passes 18 commands on 486,-fpu /
8 MiB, startup 26.753895 seconds, exact VGA and unchanged source. Direct
Fs->rip edits followed by default G skip the verified MOV and store/return
the expected marker. This proves the tested current-task G path, not stack/
flags edits, other-task control or the revised header-default source epoch.

build/debug-go-clear-native-generations completes PASS. Independent audit
build/debug-go-clear-generation-identity-recheck passes all 12 modules,
flat 487336 bytes, flat SHA256
677fc890aea419321b03fa299edfc546240122bfa153af43f67c7a93b3547fe9,
boot SHA256
9daa68fd0f77c3ea8b3120c70db0a2af8afe277a7dce37a75c9b548db38ed1e6.
Both volumes: 16 directories, 873 files, 19135 owned sectors with matching
reachable-extent bitmaps. Whole disk hashes differ as expected. These are
G2-source results, separate from the later task-local/diagnostic/IP candidate.

PublicDebug.HH introduced TRUE/FALSE default arguments, while PublicUser.HH
publishes those macros only after PublicKernel.HH. The diagnostic header
probe loads PublicKernel independently. Candidate defaults now use equivalent
0/1 literals, matching the self-contained neighboring public headers.
This removes an actual include-order dependency; whether it resolves the
observed Invalid lval still requires runtime proof. Updated patch applies
cleanly; fresh bootstrap and --test/public-IP/concurrent/ownership/kill gates
run or queue in build/debug-concurrent-header-defaults-pipeline.json.
No diagnostic PASS, root promotion or full release qualification is claimed.

Direct public RIP single-step green; full headers compile with extra warning
(2026-10-05): new tools/test-i386-debug-public-step-ip.py edits Fs->rip,
uses default S and requires chosen-store execution before vector-1 reentry;
G then finishes with the preserved marker. build/debug-public-step-ip-green
passes 18 commands on 486,-fpu / 8 MiB, startup 28.113256 seconds, exact VGA
and unchanged source. Dependencies are pinned and preflight verifies independent
cycles/default S/line bounds. This uses the earlier reader/IP image. Five G
edit/resume cycles separately run in build/debug-public-ip-repeat.

The header-default source now passes actual public-header compilation:
PUBLIC HEADER PUBLISHED 1, warning count 2, CTask size 0x3E0. It no longer
fails Invalid lval. The full diagnostic run then stops at the existing
one-warning assertion. Preserve this new failure; do not relax the assertion
until the additional warning is identified and its cause reviewed. Fresh
source bootstrap/all 1270 hashes and cross export succeed, but full --test
remains unqualified. Main candidate promotion and release completion stay open.

Frozen G2 installed suite and repeated direct-IP editing qualified
(2026-10-05): build/debug-go-clear-installed-frozen completes PASS with all
154 pinned disk/prerequisite/snapshot inputs unchanged. All four gates pass:
workstation 513 commands, 486,-fpu / 8 MiB startup 56.826717 seconds,
long-document update 0.257375 seconds; DolDoc three-boot persistence and
filesystem audit; speaker observed 440/880 Hz, 7.754036-second recording;
resource 20 development cycles, temporary live growth 3616 bytes. Input disk
SHA256 21875e97acc987b736232fb8f0b4d701eb0126193776ce78203c843f7fffa4b5
is unchanged. This frozen run uses the original flat-identity prerequisite
schema; future runs require the newly added whole-disk audit field. These
are G2-source results, not qualification of the later diagnostic/IP candidate.

build/debug-public-ip-repeat passes five cycles / 50 commands, 486,-fpu /
8 MiB startup 28.365170 seconds, exact VGA and unchanged reader/IP image.
Public RIP edits/default G repeatedly select the expected physical store.

Extra header warning source investigation: PublicTaskTypes forwards CBpt;
PublicDebugTypes now completes it. PrsClassCore issues unused-extern warning
when a completed forward has use_cnt<3; the preexisting CCPU warning and new
CBpt completion suggest the extra count, but names need runtime confirmation.
Candidate I386FrontendWarning now logs kind and symbol without changing count
or any assertion. Fresh bootstrap and dependent --test pipeline run/queue in
build/debug-concurrent-warning-trace-pipeline.json. Updated full patch applies
cleanly. Diagnostic acceptance, later-source native/installed qualification,
root promotion, full parity and release completeness remain open.

Candidate-aware exact-volume audit and warning logger correction (2026-10-05):
audit-i386-guest-image.py accepts --repository to use the qualified source's
format/boot helpers; pins those Python helpers and its own implementation
alongside disks/listing. This permits whole-disk re-audit without altering a
fixed candidate. Both G2 generations pass in build/debug-go-clear-gen1-identity-audit
and ...-gen2-identity-audit, flat 487336 bytes. Independent disk hashing matches
21875e97acc987b736232fb8f0b4d701eb0126193776ce78203c843f7fffa4b5 and
6427dd8ed5b19cd6508637f263517cc86fc3795fa610bbea0f62df141ce53e69.
Installed preflight rejects a gen2 audit supplied for gen1 despite identical
flat kernel hashes, without creating output. Prior installed workflows remain
under their recorded schema; new qualification can use these stronger audits.

The diagnostic warning-trace cross compiler fails explicitly at Frontend.HC
KernelHex(kind): that logger symbol is not available to the compiler module.
Retain its compiler-log.DD failure. Candidate warning names now print the
three defined kinds as text through the existing KernelLog service, preserving
count/assertions and naming the actual symbol. Fresh original bootstrap and
full diagnostic/regression pipeline run/queue in
build/debug-concurrent-warning-names-pipeline.json. Updated full patch applies
cleanly; no warning identity or full diagnostic PASS yet claimed. Root OS code
remains unpromoted and full release scope stays open.

Public-header warning identities confirmed; exact contract updated (2026-10-05):
The warning-name source builds and reaches its original assertion. Actual
boot log identifies unused extern CCPU and CBpt for both rollback and
successful header attempts, then PUBLIC HEADER PUBLISHED 1 / 2 / 0x3E0.
Candidate header probe now requires exactly two count-only warnings, preserving
all other compilation, allocation, type identity and later zero-warning checks.
Host full-build audit additionally requires the exact warning-name sequence
CCPU, CBpt, CCPU, CBpt in each header-probe section; a new warning kind/name
still fails. This adjusts the fixture for the completed canonical breakpoint
class rather than accepting arbitrary warning growth. Fresh bootstrap and
full diagnostic/regression pipeline run/queue in
build/debug-concurrent-warning-contract-pipeline.json; verdict pending.

Guest-image auditor also rejects existing output trees before reading inputs.
A real preflight test supplies a missing source and an existing qualified audit
output, requires exit 2 and verifies its result hash remains unchanged.
This prevents failed reruns from leaving stale PASS evidence in a reused tree.
Updated candidate patch applies cleanly to main. Full diagnostics, later-source
native/installed qualification, promotion and release completeness remain open.

Phase-0 full header diagnostics pass; inherited worker contract corrected
(2026-10-05): warning-contract boot passes PUBLIC HEADER CASE 0, 128 task
layout checks, 271 document checks and compiler recovery. Phase 1 reaches
PUBLIC HEADER PUBLISHED 1 / 0 / 0: inherited root include guards skip declarations,
while the fixture wrongly creates a new empty CTask forward. Preserve that
failure; phase-0 success is not a full diagnostic PASS.

Candidate header probe now keeps phase 0's fresh-publication/rollback contract.
Phase 1 locates the inherited published CTask, requires its complete size and
identity before/after failed atomic include and idempotent include, and requires
zero warnings. Existing layout/document/allocation/control checks remain.
Inherited public metadata lookup traverses parent tables; local rollback names
still use local scope checks. Host warning audit distinguishes phase 0's exact
CCPU/CBpt warning sequence from phase 1's empty sequence. Updated patch applies
cleanly. Fresh original bootstrap runs in the clone's
build/debug-concurrent-bootstrap-inherited-headers.log; full build/diagnostic
and later regressions remain required. Main source unpromoted; release open.

Inherited-header helper compiler dependency corrected (2026-10-05):
The first inherited-header candidate finishes both original bootstraps and
all 1270 hashes match, but its i386 module export fails at CompilerHeaderProbe.HC
line 60: return NULL. CompilerProbe includes TRUE/FALSE constants, not NULL;
this is a helper compilation issue, not evidence against inherited-header
semantics. Preserve build/debug-concurrent-inherited-headers/exports/compiler-log.DD.
The helper now returns the equivalent zero pointer literal. Updated full patch
applies cleanly to main. Fresh bootstrap and dependent full diagnostic/IP/
concurrent/ownership/kill pipeline run/queue in
build/debug-concurrent-inherited-zero-pipeline.json. No new header/runtime
PASS yet claimed. Previous phase-0/full installed G2 evidence stays tied to
its source epochs; root promotion and complete release qualification remain open.

Both guest header phases complete; host file-interface audit is stale
(2026-10-05): inherited-zero diagnostic guest reaches DONE native kernel
startup after both PUBLIC HEADER CASE phases and the full guest probes.
The build host then fails at Missing file-runtime ownership evidence: its
FILES row parser expects the older 25-token interface, while the candidate
logs the added ABI-47 services. This is not a complete --test PASS. Preserve
boot/logs; next update must verify every new service address against module
exports, not merely relax the row length. Candidate source remains fixed.

New tools/test-i386-debug-public-flags.py tests physical carry edits: capture
CF clear, set public Fs->rflags CF, G, then ADC must change result from 0x11
to 0x12, with mode/IF/TF/heap checks. Initial build/debug-public-flags-red fails
before any trap because inline CLC/ADC reports unavailable frontend service.
The fixture now compiles supported MOV/NOPs, finds the NOP window and patches
independently NASM-verified bytes f8 cc 83 d0 00 (CLC/INT3/ADC EAX,byte 0),
verifying the bytes before executing. New run
build/debug-public-flags-bytes-red is pending. Five-cycle preflight verifies
independent events and command limits. No flags implementation/runtime green,
root promotion or complete release readiness is claimed.

ABI-47 FileRuntime host qualification updated (2026-10-05):
The concurrent candidate audit now requires all six additional exported services
(write_public, read_stored, expand, public_reader, cd, find_public), derives
addresses from their module exports, parses the complete 31-token FILES row,
and checks every added address. These addresses are also recorded in results.
Independent inspection of inherited-zero's captured boot validates all six;
all 1270 original-bootstrap source hashes still match. The complete updated
candidate patch applies cleanly to main. Fresh full --test qualification runs
in build/debug-concurrent-prototype/build/debug-concurrent-file-audit;
its log is build/debug-concurrent-file-audit-cross-build.log. Captured-row
validation is not a complete diagnostic/build PASS. Root OS remains unpromoted.

The corrected byte-patched flags fixture is terminal FAIL in
build/debug-public-flags-bytes-red/result.json. Its guest reaches
CpuTrapResult==0x12 after captured/public carry checks and G, then the console
check times out. This is runtime evidence beyond the earlier frontend failure;
physical flags restoration still needs implementation and green verification.
The integrated no-FPU retained-build retry remains live (PID 3677763).
Complete self-hosting/release qualification remains open.

Public flags resume candidate (2026-10-05):
Original Kernel/KDbg.HC G clears public task rflags TF on accepted resume;
S sets it. New build/debug-flags-prototype preserves that contract: G/S copy
the public flags shadow into the physical 32-bit exception-return frame, after
clearing/setting TF. Accepted G updates flags after the managed-breakpoint
resume guard, so a blocked G does not commit the pending flags edit. G2 uses
G's path. This does not restrict edits to arithmetic flags. Direct ESP edits,
other-task debugger controls and full debugger parity remain outstanding.
Full cumulative docs/patches/i386-debug-flags-candidate.patch applies to main;
source is isolated from the concurrent candidate's still-running full test.

An initial bootstrap launch followed a failed edit command caused by a wrong
relative working-directory path; it was explicitly stopped, descendants
terminated, and its incomplete output preserved as
build/debug-flags-prototype/build/rebuild-before-flags-edit-incomplete.
The source edit then succeeded and a fresh bootstrap runs in
build/debug-flags-bootstrap.log (PID 3718918). The dependent
build/debug-flags-pipeline.json verifies both bootstrap generations and all
source hashes, runs the full cross-build/diagnostics, then five carry-edit
cycles plus public S/IP, G/IP, simultaneous traps, shared breakpoint ownership
and managed-kill regressions. No flags green or candidate promotion claimed.

Single-step flags contract test added (2026-10-05):
New tools/test-i386-debug-public-step-flags.py derives the verified
CLC/INT3/ADC fixture, preserves captured-CF-clear/public-CF-set checks, then
uses S. At debugger reentry it requires Fs->rax==0x12, TF set and the function
still active; G must then finish with result 0x12 and restored mode/IF/TF/heap.
Dependencies, original debugger contract, checker and source disk are hashed.
Five-cycle preflight confirms independently owned interaction objects and the
255-character command limit. The actual red run against reader-ip is live in
build/debug-public-step-flags-red; no runtime result yet claimed.
A separate dependent build/debug-flags-step-pipeline.json waits for the full
flags pipeline to pass before running five green step/flags cycles, without
mutating any candidate currently under qualification.

The concurrent-file-audit guest again reaches DONE native kernel startup;
its complete host --test still runs additional normal/rejection/workflow
checks, so no overall PASS is claimed. The flags candidate has matched all
1270 bootstrap source hashes and is executing diagnostics. The integrated
no-FPU retained-build retry remains live. Direct ESP support must account for
same-ring IRET: POPAD ignores saved_esp, and ExceptionEntry.HC currently
returns using the frame's original stack, so simply editing the saved_esp
field cannot implement public RSP edits. It needs an explicit return-frame
relocation mechanism plus a real alternate-stack test before qualification.

Public physical-stack TDD fixture (2026-10-05):
New tools/test-i386-debug-public-stack.py allocates an alternate stack before
resource warmup, edits Fs->rsp while paused at actual INT3, and requires the
compiled function's MOV EAX,ESP to observe that exact alternate address after
G. MOV ESP,EBP restores the original function frame before its epilogue;
normal result, mode/IF/TF, arithmetic and repeated heap checks remain.
This distinguishes real stack selection from public-shadow-only edits.
Five-cycle preflight checks independent interactions and command limits.
The red runtime is running against reader-ip in build/debug-public-stack-red;
frontend and actual failure checkpoint must be inspected before attributing a
failure to stack relocation. No alternate-stack implementation/green claimed.

Full concurrent-file-audit and flags host --test processes remain live
(PIDs 3716380 and 3719172); both diagnostic guests reach DONE native kernel
startup. Additional checks remain in progress. Integrated no-FPU retained
build PID 3677763 remains live after about 69 minutes. The single-step flags
red run remains live; neither flags nor stack runtime results are yet claimed.

Physical return-stack candidate implemented (2026-10-05):
The S/flags red run reached its flags-step-reentry screenshot after editing
CF and S, then failed its EAX/TF/result condition. The public-stack red run
compiled/executed, accepted the public RSP edit and G, and timed out at
CpuTrapResult==CpuStackTop. Both preserve unchanged source disks; neither is
a frontend failure or green qualification.

New isolated build/debug-stack-prototype layers on the flags candidate.
KernelDebugCpu returns the desired exception-frame address (public RSP minus
68 bytes). ExceptionEntry's debugger return path disables interrupts after
the C call has returned, copies all 17 frame words in overlap-safe direction,
sets ESP to the relocated frame, restores segments/registers and uses IRET.
This avoids copying onto a live C return address and restores physical ESP to
the selected public RSP. IF remains clear only for relocation/restoration;
IRET restores the edited flags with G/S's TF policy. Default same-stack return
skips the copy. No runtime green or overlap-case coverage yet claimed.
Full docs/patches/i386-debug-stack-candidate.patch applies cleanly to main.

Fresh original bootstrap runs in build/debug-stack-bootstrap.log (PID 3722244).
Dependent build/debug-stack-pipeline.json checks both generations/all source
hashes, full diagnostics, five alternate-stack cycles, five S/flags and five
G/flags cycles, then IP/S, IP/G, simultaneous traps, breakpoint ownership and
managed-kill regressions. Source epochs of other running qualifications stay
fixed. Full native/installed/release gates remain necessary before promotion.

Single-step physical-stack contract added (2026-10-05):
tools/test-i386-debug-public-step-stack.py uses the alternate-stack fixture,
selects public RSP then S, and requires a new exception capture's public RSP
to equal the target with TF set and function still active. Capture derives
RSP from actual saved ESP, so a stale edited shadow cannot satisfy this gate.
G then must read the physical alternate ESP and restore the original function
frame. The stepping fixture reserves 64 KiB with 48 KiB below the selected top
for debugger/compiler work on the alternate stack. Five independent cycle
objects and console command limits pass preflight. Red runs against reader-ip;
build/debug-stack-step-pipeline.json waits for complete stack qualification
before five green cycles. No S/stack runtime PASS yet claimed.

The concurrent/flags/stack full build jobs remain live, not restarted for
observation timeouts. Focused five-cycle G/flags and G/stack checks also run
against their fixed newly built kernel images in
build/debug-public-flags-focused-green and build/debug-public-stack-focused-green.
They provide earlier runtime evidence but cannot replace full --test,
self-hosting/native generations or installed/release gates.

Focused flags green; stack physical result still fails (2026-10-05):
build/debug-public-flags-focused-green/result.json is PASS: five G/CF-edit
cycles, TCG 486,-fpu, 8 MiB, startup 35.78195754438639 seconds, physical ADC
result 0x12 with mode/IF/TF/heap checks and source disk unchanged. This proves
the selected carry-edit path, not all public flags or complete qualification.
The stack candidate's focused five-cycle run is FAIL during the first final
CpuTrapResult==CpuStackTop check, after actual trap/edit/G and shell return.
No stack green is claimed. Isolated build/debug-stack-observe.py logs observed
physical result and requested stack address to E9 for diagnosis on the fixed
image; full candidate sources are not edited while qualification remains live.

New tools/test-i386-debug-public-stack-overlap.py selects public RSP +/-4
relative to the captured stack, then checks physical ESP and original-frame
restoration. The 68-byte frame overlaps itself, exercising forward/backward
copy paths. Both directions pass five-cycle independent-fixture/command-limit
preflight; the -4 runtime red is pending against reader-ip.
build/debug-stack-overlap-pipeline.json runs five cycles in each direction
only after the complete stack prerequisite passes. Current focused stack
failure must be resolved before treating either overlap path as qualified.

Stack failure narrowed by actual address trace (2026-10-05):
The first observation helper cannot index a string literal directly in the
native frontend (Missing ')' diagnostic); preserve build/debug-stack-observe.
The corrected digits-pointer helper compiles and logs from the resumed
function in build/debug-stack-observe-digits/debug.log:
observed return value 0000000000000000, requested stack 0000000000294E20.
The function returns zero, not merely the old stack address. That weakens a
simple 'ESP relocation ignored' explanation; inspect the fixture's emitted
instructions and local-value handling before changing the return mechanism.
The emitted ExceptionEntry module contains the intended CLI, both 17-word
copy loops, MOV ESP,EDX, register restoration and IRET; emitted KernelDebugCpu
loads public RSP offset 228 and returns RSP-68. These inspections establish
code shape, not successful physical stack behavior.

New fixed-image build/debug-stack-observe-code.py logs the guest-compiled
function bytes for diagnosis. It runs separately without candidate edits.
Five focused S/flags cycles also run in
build/debug-public-step-flags-focused-green on the G/flags-qualified image.
Complete host qualification and native/release gates remain open.

Saved-ESP fixture correction; S/flags green (2026-10-05):
The guest function byte trace proves MOV ESP,EBP was followed by return-value
expression pushes at EBP-4, overwriting the local result with zero. This was a
fixture error; the earlier stack result cannot prove relocation failure.
tools/test-i386-debug-public-stack.py now saves exact pre-trap ESP into a local
before INT3 and restores it from that EBP-relative local after reading physical
ESP, preserving local storage and saved registers for the compiler epilogue.
No compiler-frame-size constant is assumed. G/S/overlap fixture preflight
passes command limits. No stack fixture/dependency was live when changed.
Fresh corrected red and five-cycle green run on unchanged old/stack images in
build/debug-public-stack-saved-esp-red and ...-green; earlier failures preserved.
Source implementation remains unchanged pending corrected runtime evidence.

build/debug-public-step-flags-focused-green/result.json is PASS: five S/CF
cycles on 486,-fpu, 8 MiB. Captured CF clear, public CF set, ADC executes with
EAX 0x12 and TF at reentry before G finishes with clean mode/IF/TF/heap; source
disk unchanged. G/flags and S/flags now have focused runtime greens on the
same flags image. This does not prove all flags, other-task control, full
host qualification, native builds or installed/release readiness.

Corrected G/stack green; alternate-stack S fails (2026-10-05):
build/debug-public-stack-saved-esp-green/result.json PASS: five cycles/45
commands, TCG 486,-fpu, 8 MiB, startup 31.750123808160424 seconds, physical
MOV EAX,ESP equals requested stack and exact original ESP is restored; normal
mode/IF/TF/heap checks pass, source disk unchanged. Identical corrected
fixture on reader-ip is FAIL at its final physical stack check, proving the
old return path cannot satisfy the contract. The earlier zero-result fixtures
are preserved and superseded by this saved-ESP fixture evidence.

build/debug-public-step-stack-saved-esp-green/result.json is FAIL during the
first trap/edit/S interaction. Guest logs UNHANDLED 0000000000000001
0000000000000000 then FAIL native kernel; it does not reach the expected
single-step debugger reentry. Alternate-stack stepping remains a real open
case, unlike the corrected G fixture. Investigate capture/debugger execution,
stack ownership and unwinding on the selected stack; no S/stack green claimed.

The fixed stack candidate now starts a six-retained-module guest build in
build/debug-stack-native-build (KVM), with reference exports from its exact
cross-build. This is independent early self-hosting evidence, not completion
of the broader full --test or release gate. All candidate sources stay fixed.
Native generations, alternate-stack S/overlap coverage, current installed
workflows and final release artifact verification remain open.

Alternate-stack S failure linked to exception ownership (2026-10-05):
ExceptRuntime.HC I386ExceptEnter aborts with I386_EXCEPT_INVALID (status 1),
channel zero when capture EBP/ESP are outside task->stk. Except.HC
I386ExceptPush and dispatch impose the same single-stack bounds. After S on
an alternate allocated stack, CPU capture/trampoline execute the debugger on
that selected stack; ConsoleDebugSession's try registration cannot satisfy
the original task-stack bounds. This matches the observed UNHANDLED 1 0.
Do not weaken frame validation or mask the S failure. Architectural follow-up
must separate debugger execution stack from selected CPU resume ESP, or model
valid task stack regions explicitly, preserving nested exception records,
frame walking, yielding, task-local sessions and cleanup. Include initial
trap on an alternate stack, repeated S/G, throwing within debugger input,
simultaneous tasks and forced-kill cleanup in qualification. Original stack
owner/region validation remains an invariant; public RSP edits stay required.

Both +/-4 overlapping G frame paths now run focused five-cycle tests on the
unchanged stack image in build/debug-stack-overlap-{down,up}-focused.
The guest six-module build remains active. A dependent
build/debug-stack-native-chain.json queues the existing two-generation native
install/rebuild/identity verifier after that retained result passes, pinning
this candidate repository and exact kernel-stage listing. This early chain
can provide reproducibility evidence while alternate-stack S remains open;
it cannot qualify the candidate for promotion or release by itself.

Both overlapping return paths qualified; debugger stack design (2026-10-05):
build/debug-stack-overlap-down-focused PASS five cycles, startup
34.46285810414702 seconds. build/debug-stack-overlap-up-focused PASS five
cycles, startup 35.17370137013495 seconds. Both TCG 486,-fpu/8 MiB check physical +/-4 ESP, exact original
stack restoration, mode/IF/TF/heap recovery and unchanged source disk.
These qualify both overlap-copy directions for G, not alternate-stack S.

Implementation design for the next fixed source epoch: allocate a per-task
owned debugger execution stack outside the IF-clear capture path; execute
ConsoleCpuDebug there while keeping selected public RSP in the saved CPU
frame. Exception capture/dispatch must validate frames against the original
owned task stack or the owned debugger stack, preserving prior try records;
never accept arbitrary address ranges by disabling bounds checks. Provide
explicit ownership, lazy allocation, safe reuse and forced-kill/task-finish
cleanup; do not free the currently executing stack. Keep task-local sessions
and original resume flags/registers independent of debugger stack selection.
First-trap-on-alternate-stack support must not depend on a prior original-stack
trap. Verify allocation failure, nested throw/catch, yielding, simultaneous
sessions, repeated S/G and cleanup as well as the existing red S/stack gate.
Account for 8 MiB memory and native boot-image capacity before promotion.

Owned debugger execution stack prototype (2026-10-05):
New build/debug-owned-stack-prototype keeps the stack candidate immutable.
Private task fields track a lazy 64 KiB debugger allocation, its heap/size and
prior cleanup hook. KernelDebugStack allocates outside IF-clear CPU capture;
ExceptionEntry switches onto it before KernelDebugCpu. Resume still relocates
the CPU return frame to selected public RSP, independently of debugger ESP.
I386ExceptCaptureValid accepts the original task region or this task's exact
live debugger allocation (heap size checked), preserving alignment/frame/ESP
bounds. Exception registration and dispatch use this validator, allowing
existing original-stack try records and debugger-stack records together.
Arbitrary ranges are not accepted and public CTask layout is unchanged.
Full docs/patches/i386-debug-owned-stack-candidate.patch applies cleanly.

Fresh bootstrap runs in build/debug-owned-stack-bootstrap.log (PID 3730822).
Dependent build/debug-owned-stack-pipeline.json verifies both generations and
all source hashes, full --test and five S/stack cycles, both overlap directions,
G/stack, S/G flags, IP, simultaneous traps, ownership and kill regressions.
No runtime green claimed. Prototype cleanup chains the prior task hook and
frees the allocation, but self-exit while currently executing on that stack
requires deferred reclamation; do not claim cleanup complete. Allocation
failure currently stops and must gain tested recovery. Multi-region frame
walking, initial trap on alternate stack, nested throw/catch/yield, memory
budgets and native boot capacity remain required. Existing fixed stack native
build and older full suites continue independently.

Owned-stack compiler dependency and deferred reclamation (2026-10-05):
Initial owned-stack cross-build is terminal FAIL before i386 export: original
compiler log reports undefined NULL in Kernel.HC's new cleanup helper. The
original two-generation bootstrap passed; this was a kernel helper parse
error, not runtime stack evidence. Preserve build/debug-owned-stack/exports.
Kernel helper now uses zero pointer literals supported by this kernel's
includes. No runtime owned-stack PASS yet claimed.

Debugger cleanup now only restores/calls the previous cleanup hook. Actual
owned debugger-stack validation/free occurs in I386SchedReap after its guard
proves the task is finished and another task is current. This permits self-exit
from the debugger execution stack without freeing the live stack. Ownership
fields stay live until successful free; reaping failure preserves evidence.
Repeated sessions reuse the bounded task-owned allocation. Updated cumulative
patch applies cleanly. Allocation failure recovery and frame walking remain
open; cleanup implementation still needs forced-kill/self-exit runtime tests.

Fresh bootstrap runs in build/debug-owned-stack-reap-bootstrap.log (PID 3731662),
with dependent build/debug-owned-stack-reap-pipeline.json and a fresh build
output. Previous bootstrap archived as rebuild-owned-stack-before-reap;
failed outputs remain intact. Fixed prior candidates' host/native qualification
continues independently; no source epoch or release completion is conflated.

CPU-debugger self-exit test; next stale console audit identified (2026-10-05):
New tools/test-i386-debug-cpu-self-exit.py repeats five independent terminal
sessions: actual INT3, TermFinish/Exit from the CPU debugger prompt, focus
transfer, mode restored, survivor arithmetic, then both children reaped and
exact parent public heap recovery. Command/independence preflight passes.
This exercises self-exit on the new owned execution stack; it is not a direct
private kernel-allocation count audit. Runtime runs in
build/debug-cpu-self-exit-owned-stack on the fresh reap candidate image.
Five alternate-stack S cycles also run in build/debug-public-step-stack-owned-green.
No result yet claimed; candidate remains fixed while full --test runs.

Concurrent-file-audit, flags and stack full --test runs are now terminal FAIL
at Missing retained console, after earlier diagnostic startup and workflow
activity. Their host parser expects 10 tokens (three layout values plus six
services), but Console ABI38 logs 13 tokens (plus cpu_capture, cpu_debug and
root_headers). Console layout already requires these exports but omits their
three addresses from its expected entries. The next host audit fix must add
all three offsets in interface order and verify every address; simply loosening
row length is insufficient. Preserve all failed outputs; neither full gate
is PASS. Reap candidate still runs; do not mutate its source epoch during that
qualification. Earlier focused flags/G-stack/overlap greens remain scoped to
their exact images and do not close the release gate.

Complete Console ABI38 host audit corrected (2026-10-05):
New isolated build/debug-console-audit-prototype has identical owned-reap OS
sources, with a host-only audit update. Console layout derives all nine service
addresses, including CPU capture/debug and root_headers, from required exports.
The parser requires exactly 4+the version-checked service count tokens (13),
compares every address and records the service-name/address mapping. Independent
captured stack-image audit validates all nine addresses. All 1270 source hashes
match both bootstrap generations; bootstrap artifacts copied independently
from owned-reap without changing that still-running candidate. Fresh full test
runs in build/debug-console-audit-cross-build.log; no overall PASS yet claimed.
Full docs/patches/i386-debug-console-audit-candidate.patch applies cleanly.

Owned-reap focused S/stack and CPU-self-exit runs are terminal FAIL/timeouts.
S/stack reaches its first debugger heading but lacks the subsequent state
checkpoint; self-exit reaches typing TermFinish at the debugger prompt but
fails the expected focus-transfer checkpoint. Logs do not show the previous
UNHANDLED 1 0. Preserve both outputs; inspect debugger input/scheduling and
stack-region frame walking before attributing a new root cause. A displayed
heading alone does not qualify command execution or owned-stack cleanup.
Native and complete release gates remain open; root OS source remains unpromoted.

Owned-stack command failure traced to parser headroom guard (2026-10-05):
Inspection of the final failed PPM frames shows CpuTrapStage and TermFinish
were received, but each returned Compilation failed. This is command
compilation, not unresponsive keyboard input. NativeExpression.HC
I386ParserStackCheck validates GetRBP only against task->stk and requires
4096 bytes of headroom, so it rejects the new debugger execution stack even
though exception registration now recognizes that exact owned allocation.

New isolated build/debug-parser-stack-prototype extends the parser guard:
original bounds remain primary; a frame outside them can select this task's
exact live debugger allocation only if its heap size matches the owned size
and it is at least 4096 bytes. The same end-address/frame bounds and 4 KiB
headroom check then apply. No arbitrary region or guard bypass is introduced;
existing compiler imports already include I386HeapSize. Existing candidates
remain fixed. Full docs/patches/i386-debug-parser-stack-candidate.patch applies.

Fresh bootstrap runs in build/debug-parser-stack-bootstrap.log (PID 3737455).
Dependent build/debug-parser-stack-pipeline.json checks both generations/all
hashes, full --test with the complete console audit, five CPU-self-exit cycles,
S/stack, both overlap paths, G/stack, flags/IP/concurrency/ownership/kill gates.
No new runtime green claimed. Allocation failure recovery, frame walking,
private-resource accounting and native/release gates remain outstanding.

Six-module guest build passes; nested catch/yield test added (2026-10-05):
build/debug-stack-native-build/result.json is PASS for all six retained
modules on the fixed stack candidate. Its dependent native-generations chain
has passed gen1 installation and is running gen1 self-hosting. This source
precedes owned execution/parser stacks; do not transfer its evidence to newer
candidates. Complete two-generation flat-kernel identity remains pending.

New tools/test-i386-debug-cpu-nested-catch.py compiles a helper with nested
try/throw/catch and Sleep(10) inside the catch, then calls it from an actual
INT3 debugger, expects 42, G and clean mode/IF/TF/repeated heap recovery.
Five independent interaction/command-limit preflight passes. A one-cycle
red runs on the owned-reap image without parser guard support; five cycles
run on the fixed parser-stack image. This exercises exception capture/dispatch
and yielding on the owned debugger stack, not just a simple expression.
Focused self-exit and alternate-stack S also run on that parser image in
build/debug-cpu-self-exit-parser-green and build/debug-public-step-stack-parser-green.
No runtime result yet claimed. Full host audits, allocation failure recovery,
frame walking, private accounting and installed/release gates remain open.

Owned/parser stack focused runtime greens (2026-10-05):
All on the same fixed parser-stack image, TCG 486,-fpu, 8 MiB and unchanged
source disk: debug-public-step-stack-parser-green PASS five cycles/45 commands,
startup 43.61391941085458 seconds; debug-cpu-nested-catch-parser-green PASS five
cycles/45 commands, startup 44.03593344427645 seconds; and
debug-cpu-self-exit-parser-green PASS five terminal sessions/31 commands,
startup 43.647741994354874 seconds. They cover actual alternate-stack S and
reentry/G, throwing/catching/sleeping within debugger input, and self-exit
followed by surviving console commands, mode restoration and child reaping.
Public repeated-heap checks pass; no direct private kernel-heap count claim.
Nested-catch fixture on owned-reap without parser support is FAIL (preserved).

New tools/test-i386-debug-initial-alternate-stack.py switches physical ESP in
compiled code before the first INT3, verifies captured public RSP and command
execution, then physical resume result and exact original ESP restoration.
It needs no prior debugger trap/anchor. Five independent fixtures pass command
limits. Initial launches were explicitly stopped to correct an inherited
128-byte NOP finder that needlessly constrained the longer function. Outputs
preserved as unqualified; no runtime failure claim from those interrupted runs.
The finder now stays within MSize's actual code allocation, checking the
complete three-byte NOP window before patching. Fresh bounded red/green runs
are build/debug-initial-alternate-stack-bounded-{red,green}; no result yet.
Complete host/native/install qualification, allocation-failure recovery,
frame walking and private memory budgets remain open; candidate unpromoted.

First trap on alternate stack qualified; caller-identity TDD (2026-10-05):
build/debug-initial-alternate-stack-bounded-green PASS five cycles/45 commands,
TCG 486,-fpu/8 MiB, startup 37.53534290520474 seconds, source disk unchanged.
Physical ESP switches before the first actual INT3; captured RSP, debugger
commands, G physical result and exact original ESP restoration all pass.
The same bounded fixture on the pre-owned stack image fails with
UNHANDLED 1 0 / FAIL native kernel on first trap, preserving the red evidence.
Owned execution no longer depends on a prior original-stack debugger anchor.

New tools/test-i386-debug-cpu-trace.py requires except_callers[0], recorded by
throw on the debugger execution stack, to fall inside the live allocation of
the actual throwing function. Its nested catch sleeps, then G and normal
mode/IF/TF/heap checks remain. This is a bounded identity oracle, not merely
nonzero pointer validation. Five independent fixtures pass command preflight.
Runtime red runs on parser-stack in build/debug-cpu-trace-owned-red. Kernel
Debug.HC Caller and ExceptRuntime.HC throw still walk only original task stack
bounds; debugger-owned region support must preserve header/parent/cycle bounds
and allocation ownership. No frame-walking green or complete trace claimed.
Full host audits and the fixed pre-owned stack's native-generation chain remain
active; newer candidate native/install/release qualification is outstanding.

Checked debugger-region frame walker prototype (2026-10-05):
Caller-identity TDD on parser-stack is terminal FAIL after actual Nested throw
and catch; trace identity cannot be established with original-stack-only walks.
New isolated build/debug-trace-stack-prototype adds task-aware frame bounds,
parent and return helpers. Bounds accept the original stack or this task's
exact live debugger allocation, checking heap size and full header/alignment.
Within-region parents must advance beyond the header. Cross-region parents
are allowed only from debugger region to original region; reverse edges are
rejected, preserving acyclicity. Invalid/unowned frames stop before reads.
throw's bounded caller array and the existing Caller source use these helpers;
this does not establish public Caller export/API parity or every trace frame.

Full docs/patches/i386-debug-trace-stack-candidate.patch applies cleanly.
Fresh bootstrap runs in build/debug-trace-stack-bootstrap.log (PID 3742213),
with dependent build/debug-trace-stack-pipeline.json: all bootstrap hashes,
full --test, five caller-identity, initial alternate trap, nested catch, self-exit,
S/stack and existing flags/IP/concurrency/ownership/kill regressions. No new
runtime PASS yet claimed. Allocation failure, invalid/cycle walker negatives,
private memory budget and current native/install/release gates remain open.

Frame helper forward-declaration ordering corrected (2026-10-05):
Initial trace-stack original bootstrap passes, but cross-build is terminal
FAIL in Kernel.HC at task->debug_stack_cleanup (Invalid member). Frame.HH's
new unconditionally repeated CI386Task forward declaration appears after
Scheduler.HH's complete class and replaces its visible member metadata in
this compiler. This is a header dependency failure, not runtime frame evidence.
Frame.HH now emits that forward declaration only before Scheduler.HH has been
included; complete native task metadata remains available. Preserve the failed
exports/compiler-log.DD and bootstrap as rebuild-trace-before-task-guard.

Updated cumulative trace patch applies cleanly to main. Fresh bootstrap runs
in build/debug-trace-task-guard-bootstrap.log (PID 3742629); dependent
build/debug-trace-task-guard-pipeline.json uses a new output and retains all
caller/alternate-stack/exception/cleanup/flags/IP/concurrency gates. No new
frame-walking runtime green claimed. Fixed earlier stack native chain remains
live in gen1 self-hosting; current source native/release gates remain open.

Frame-walker build reaches native boot-capacity gate (2026-10-05):
Guarded task declaration fixes the kernel member parse failure; both original
bootstrap generations pass and all 1270 hashes match. Cross-build now produces
Kernel32.BIN 490960 bytes, but the current six-module flat boot-image limit is
487424 (960*512-4096). It exceeds the declared reservation by 3536 bytes and
full --test stops before image packaging. Preserve debug-trace-task-guard
exports, stage listing and instruction audit. Parser-stack's flat image is
487400 bytes, only 24 bytes below that limit. No runtime trace image is qualified.

This makes boot capacity architectural work, not a debugger-only checklist.
The BIOS loader reads all 960 sectors contiguously from physical 0x10000;
protected entry uses stack top 0x90000, and legacy memory/EBDA checks reserve
that stack. Raising sector constants alone risks stack/image overlap and
would leave native BuildBootImage/InstallBootArea/selfhost audit contracts
inconsistent. Preserve all frame/ownership checks; do not remove features to
fit the limit. Plan an extended native boot format that streams or stages a
larger kernel into verified high memory, with a versioned handoff and a safe
bootstrap stack. Update linker base/relocations, memory reservation, compiler
cross-build, guest BuildBootImage, install writes, independent boot/image
verifiers and both native generations together. Keep the legacy layout's
acceptance/rejection contracts explicit while adding the extended layout.

Tests first: a payload larger than the current reservation must boot and
produce a source-identical installed boot area; verify first/last loaded bytes,
nonoverlap with stack/EBDA/arena, insufficient-memory rejection, truncated or
oversized image rejection, bounded sector writes and volume preservation.
Then rebuild/install/reboot two generations with identical native payload,
repeat required 8 MiB/no-FPU/workstation/resource gates and rerun debugger
trace regressions on that image. Code-size efficiency can add headroom but
must not replace a scalable boot-image contract. Full release remains open.

Extended boot-load TDD begins (2026-10-05):
New tools/test-i386-extended-boot-load.py places a distinctive 16-byte marker
at the end of a 640 KiB payload range beyond the legacy 487424-byte ceiling,
inside the existing reserved boot area. It requires that tail at an explicitly
selected high-memory payload base, then ordinary console arithmetic; snapshot
source/candidate preservation and unchanged filesystem bytes remain checked.
Fresh output required; payload is bounded before the volume and below 8 MiB.
This is an independent load-reach oracle, not a complete payload-header or
installation test. No declared-length metadata for a future format is guessed.

The legacy parser-stack disk runs this red in build/extended-boot-load-red
with target base 0x100000. No result yet claimed. Implement the extended loader
only alongside explicit length/entry/handoff contracts and validate the actual
oversized kernel, not just this padded marker fixture. Follow with truncated/
oversized/low-memory rejection, installed boot-area preservation, two native
generations and exact source/code/resource checks. Physical hardware remains
deferred; current full release qualification remains incomplete.

Extended high-memory loader prototype verified (2026-10-05):
The legacy load-reach oracle is now terminal FAIL in
build/extended-boot-load-red; its source disk remains unchanged. New standalone
tools/i386-extended-stage.asm retains the legacy BIOS first-stage and handoffs,
reads payload sectors through a low-memory buffer and copies to 0x100000.
Versioned E32B metadata declares exact length/base/FNV checksum; the loader
bounds reads before filesystem LBA 2048, checks extended memory, verifies A20,
checks complete payload integrity and validates its near-jump entry before
publishing a separate image handoff at 0x5030. Legacy OS stage is unchanged.

Run python3 tools/test-i386-extended-loader.py --out <fresh-directory>.
Independent NASM fixture has 655360 payload bytes and checks first/tail markers
at the high-memory destination. build/extended-loader-header-negatives/result.json
passes eight QEMU TCG 486,-fpu cases: valid 8 MiB boot; checksum corruption;
1 MiB insufficient memory; invalid magic/version/base; undersized and oversized
length. Snapshot source disks and all pinned inputs remain unchanged.
Payload SHA256: 57a2dd9d29c0fe923bfdfdfd42a986c4e278a465b00757a55a56420789d9c976.
Earlier build/extended-loader-prototype and extended-loader-trace failures are
preserved: fixture NASM optimized its jump to a short jump, violating the
explicit E9 header. The corrected fixture emits the five-byte jump explicitly.

This is isolated loader evidence, not an integrated TempleOS or installer pass.
A20 currently uses verified port 92 only; BIOS/KBC fallback, early exception
handling, complete executable-range 386 audit, actual high-linked kernel,
high-image arena reservation, guest boot metadata/checksum regeneration,
bounded native install and independent installed-image verification remain.
Add truncated/entry/padding boundary negatives and qualify both native
rebuild/install/reboot generations, then rerun debugger trace and release
resource/workstation/no-FPU gates. Physical hardware verification stays deferred.
Existing debug-stack native-generation and integrated no-FPU native-build
processes were confirmed live during this checkpoint; no new pass claimed.

Extended handoff and entry negatives verified (2026-10-05):
build/extended-loader-handoff-entry/result.json passes 13 isolated cases.
The valid payload checks all four image handoff fields. Four malformed entry
cases carry recomputed checksums, so opcode/reserved-byte/before-body/past-end
rejection is independent of integrity rejection. A removed final sector padded
by the fixed-size disk is rejected by checksum; this is not BIOS read failure.
See docs/i386-extended-boot-contract.md for exact disk/metadata/memory contracts
and coordinated linker, heap reservation, native installer and auditor work.
No integrated TempleOS or release completion claimed. Existing long-running
native-generation and no-FPU build processes remain live; their sources stay
frozen. Physical verification remains deferred.

Extended image reservation candidate begins (2026-10-05):
Separate main checkout build/extended-kernel-prototype applies the cumulative
frame-walking candidate and adds a 16-byte image handoff type plus validated,
sector-rounded high-image reservation. Kernel Main requires the new handoff
when the loader reports its exact 4096-byte stage, then passes both kernel
stack and high image reservations into arena selection. Legacy larger stage
images keep the old reservation path. New memory fixture covers a 655361-byte
payload rounded to 655872, heap starting at 0x1A0200 through 8 MiB, nine invalid
handoffs and unchanged output on rejection. These tests are not yet qualified.

Full cumulative source is archived in
 docs/patches/i386-extended-memory-candidate.patch (git apply --check passes).
The first --memory attempt stopped on missing fresh bootstrap, before compiling
or executing the fixture; preserve build/extended-memory-test.log. Fresh original
bootstrap is confirmed live as PID 3750438/session 86180, output
build/extended-kernel-prototype/build/extended-bootstrap.log, generation 1.
After both bootstrap generations pass, run tools/test-i386.py --memory in that
checkout. High linking, extended packaging and native installation still need
coordinated implementation; no OS runtime or memory-test pass is claimed.

Extended memory candidate qualified; installer candidate advances (2026-10-05):
Fresh original bootstrap passed both generations. Candidate --memory is PASS
in build/extended-kernel-prototype/build/i386-memory-test/result.json, two BIOS
boot variants, 8 MiB/486, compiled guest execution and instruction audit. This
covers sector rounding, high-image/heap nonoverlap and nine malformed handoffs
with output preservation, along with previous legacy arena checks. Preserve
its exact source patch i386-extended-memory-candidate.patch and bootstrap
under build/rebuild-memory-qualified; do not transfer this pass to later edits.

Candidate I386BuildBootImage now selects the high link base and extended
capacity only from a matching extended-stage/image handoff. Native boot-area
publication recognizes E32B source-stage metadata, validates version/base,
regenerates exact length/FNV checksum, and writes/pads only LBA 9–2047 before
publishing sector zero last. Legacy source stages retain their old capacity.
Full cumulative patch docs/patches/i386-extended-install-candidate.patch applies
cleanly to main. Installer changes have no runtime qualification yet; guest
cross-linker/host packager/auditor integration and source-format negatives still
remain. Fresh changed-source bootstrap runs PID 3751065/session 89067 in
build/extended-kernel-prototype/build/extended-installer-bootstrap.log. Follow
with actual oversized high-linked kernel boot and independent native install
sector/hash/volume comparisons; release remains incomplete.

Oversized high-linked kernel build starts (2026-10-05):
Changed installer source original bootstrap passes both generations. Candidate
cross-linker now links all six boot modules at 0x100000; host resident absolute
address checks, packaging, capacity and build-input pins use the extended stage.
Metadata checksum is computed from the exact flat payload before assembly.
Legacy stage remains available. Candidate boot auditor classifies separate
entry32/load32/bios16/copy32 executable ranges, excluding metadata/GDT/padding.
Exact CALL EAX bytes are audited explicitly because installed ndisasm emits
FF D0 as two db records; unfamiliar encodings still reject. Isolated stage audit
passes 96 BIOS and 155 stage instructions in build/extended-audit-fixed.json.
Earlier alignment and mnemonic/disassembler audit failures remain preserved.

Full cumulative docs/patches/i386-extended-kernel-candidate.patch applies cleanly.
Actual --test build is confirmed live PID 3751945/session 11047 in
build/extended-kernel-prototype/build/extended-native-kernel.log; output
build/extended-native-kernel. No kernel boot pass claimed yet. Native independent
installed-image expectations still use the legacy layout and must be updated
before qualification. Early IDT and BIOS/KBC A20 fallback remain open; full
8 MiB/no-FPU/rebuild/install/reboot/release qualification is not complete.

Oversized kernel reaches native entry (2026-10-05):
Extended candidate cross-build produces 493912-byte Kernel32.BIN, SHA256
c772f658ca50b60cdee6b8fd831ee7ff9a44fa31652dbab04f13b89a45a145f3,
above the old 487424-byte limit. Boot instruction audit passes. First full test
image rejects with B: diagnostic_disk changed the kernel data flag after the
loader checksum was generated. Preserve extended-native-kernel/boot/debug.log;
confirmed failed process 3751945 and children were stopped rather than waiting
for its diagnostic timeout. No full --test pass claimed.

Candidate harness now regenerates extended checksum after diagnostic and
file-mutation flag edits. A corrected disposable diagnostic image boots to
START native kernel, ARENA 0x178A00 size 0x667600, REDSEA, runtime and native
resident diagnostics. This proves oversized native entry and observed arena
nonoverlap, not complete diagnostics/release qualification. Exact corrected
image kernel-diagnostics-checksum-fixed.img and logs in
build/extended-kernel-prototype/build/extended-checksum-fixed-boot are retained.
Guest-run PID 3753862/session 63616 is confirmed live; continue that handle.
Updated cumulative i386-extended-kernel-candidate.patch applies cleanly.
Remaining installed-image expectations, full --test rerun, debugger trace,
8 MiB/no-FPU and two native generations still need qualification.

Independent extended boot publication oracle (2026-10-05):
New tools/i386_boot_area.py reconstructs boot-area bytes from source-stage
format and replacement flat payload, validates the entry and capacity, computes
extended length/checksum independently, pads only the permitted payload sectors
and preserves legacy stage/tail behavior. Reconstruction matches the exact
493912-byte extended cross-built disk boot area. This comparison does not prove
guest installer execution. Candidate linked-boot and selfhost-install checks
now use this oracle instead of legacy-size-only expectations; cumulative patch
updated and applies cleanly. Independent filesystem comparison remains required.

Prior debug-stack native chain is terminal FAIL (process gone, result.json fail):
gen1-selfhost actual guest compiler rejects ExceptionEntry.HC (FRONTEND ERROR
CMP, source position 0x67). Preserve build/debug-stack-native-generations and
chain results; do not claim native generation success or restart unchanged.
Extended corrected diagnostic run PID 3753862 remains live and has progressed
through public DolDoc layout diagnostics; no terminal pass yet claimed. Original
integrated no-FPU retained-build retry PID 3677763 remains live. Full release,
extended guest installer execution and native compiler failure diagnosis remain
open.

Native ExceptionEntry assembler failure localized (2026-10-05):
Failed prior gen1 selfhost compiler stops at CMP in top-level asm, not the
inline-asm frontend. Compiler/I386/TopAssembly.HC recognizes only MOV/LEA/TEST/
XOR/ADD and JMP/JNZ there; debugger frame relocation additionally needs CMP,
SUB, DEC, JZ and JC. Preserve original failed native-generation evidence.
Separate build/extended-assembler-prototype applies extended kernel candidate
plus exact register CMP, signed-byte immediate SUB, 32-bit register DEC and
near JZ/JC encodings. Instruction semantics/frame ownership are unchanged.
Small delta docs/patches/i386-top-assembly-debug-frame-candidate.patch applies
cleanly to main (combine with cumulative extended kernel patch). No native
compiler green claimed. Fresh bootstrap confirmed live PID 3756114/session
9433, build/extended-assembler-prototype/build/extended-assembler-bootstrap.log.
Follow by compiling actual ExceptionEntry.HC with the newly built resident
compiler, comparing cross/native module bytes and repeating native generations.

The corrected extended full --test is running independently at PID 3754261/
session 82265, output build/extended-kernel-prototype/build/
extended-native-kernel-checksum-fixed. It has reached runtime diagnostics.
Its source checkout stays unchanged while qualification runs. Prior corrected
standalone diagnostic guest-run ended exit zero with DONE native kernel startup;
this does not substitute for full --test and installation/release gates.

Extended installed audit and trace qualification advance (2026-10-05):
Host audit-i386-guest-image now independently reconstructs installed boot
metadata/checksum/padding via the pinned root tools/i386_boot_area.py oracle.
It retains whole-disk/module/filesystem/386 audits; using a qualified historical
repository for compiler formats does not require that clone to carry the new
oracle. Python compilation and host diff check pass; no installed guest-image
pass claimed for this addition yet.

Actual oversized frame-walking disk is under focused trace test PID 3756360/
session 63069, out build/debug-cpu-trace-extended. Candidate extended full test
PID 3754261 remains live. Assembler-fix fresh original bootstrap passes both
generations, and new full build/test PID 3756326/session 85119 runs in
build/extended-assembler-prototype/build/extended-assembler-kernel.log. Keep
both candidate sources frozen during these runs. This is not yet evidence that
the resident compiler rebuilds ExceptionEntry; verify actual native build and
byte equality after the new image qualifies. Full objective stays open.

Extended debugger trace green and no-FPU retained build green (2026-10-05):
build/debug-cpu-trace-extended/result.json is PASS for one actual CPU trap,
nested throw/catch/yield and except_callers[0] identity in the live throwing
function, followed by G and recovery checks. Exact disk SHA256
6e940d61a7207f99251f21c86adbe224533b9b2576da58ed38bb3994b15cf713;
source disk unchanged. This closes the earlier focused trace red for this image,
not all frame/cycle/freed-memory coverage. Five-cycle qualification is live
PID 3758330/session 76122, out build/debug-cpu-trace-extended-five.

Long-running original integrated cache/Cd TCG 486,-fpu retained-build retry
completed PASS for all six native modules in
build/file-cd-resident-integrated-no-fpu-native-build-retry/result.json.
Source disk SHA256 4dbe237e290d018fd848d7d7bd82cdc6ddc6bbcc192a14e43a84337b7cb5de7e.
This evidence belongs to that historical source, not the extended/assembler
candidate or current full-release qualification.

New tools/test-i386-native-exception-build.py compiles actual ExceptionEntry.HC
with resident compiler on a writable disk copy, validates module layout and
cross-built export contract, pins inputs and retains native bytes/hash. It
explicitly does not prove full generation or byte equivalence. New assembler
candidate is under this check PID 3758460/session 57291, output
build/native-exception-assembler-fixed. Both full kernel --test runs remain
live; installer/release gates and native two-generation rebuild remain open.

Five-cycle trace green; top assembly capacity defect identified (2026-10-05):
build/debug-cpu-trace-extended-five/result.json PASS, five cycles on the same
oversized image, no-FPU CPU, source disk unchanged. Exact scope remains first
caller identity after debugger-stack catch/yield plus G/recovery, not every
frame, corrupted chains or failure injection.

Extended full --test is terminal FAIL at interactive TextFrameDemo(0): guest
logs COMMAND ERROR and the harness times out waiting for completion marker.
Preserve extended-native-kernel-checksum-fixed/input, screenshots and logs.
This is after native diagnostics/startup, not a loader failure. No full green.
Separate native ExceptionEntry check progresses past CMP but rejects near JC
(source line 0x71). No native rebuild success claimed. Inspection reveals
TopAssembly code/temp arrays are 256 bytes but shared I386FrontendAsmByte
permits 1024: expanded near-branch code can exceed actual storage before packing
rejects. This is a source-proven buffer-bound mismatch; exact runtime effects
beyond observed rejection remain unproved.

New separate build/extended-assembler-capacity-prototype carries expanded asm
instructions plus consistent 1024-byte temporary/bundle/pack bounds, retaining
the existing emitter's limit. Updated small cumulative assembler delta patch
applies cleanly to main. Fresh bootstrap live session 17356, log
build/extended-assembler-capacity-prototype/build/
extended-assembler-capacity-bootstrap.log. After bootstrap, rebuild its resident
compiler/image and repeat actual native ExceptionEntry test and byte/ISA audits.
Keep older native failure evidence; resolve TextFrameDemo separately. Installer,
two native generations and full release qualification remain open.

Text-frame failure investigation and assembler capacity build (2026-10-05):
Capacity-fixed assembler original bootstrap passes both generations. Actual
kernel --test is live PID 3759719/session 94776, output
build/extended-assembler-capacity-prototype/build/extended-assembler-capacity-kernel.
Earlier assembler candidate full test independently repeats TextFrameDemo(0)
COMMAND ERROR/timeout; preserve both full-run input artifacts. No full green.

TextRender.HC NativeTextBasePresent allocates 307200+153600 temporary bytes.
Its catch frees both buffers and unconditional epilogue frees them again:
source-proven double cleanup on rendering/allocation exceptions. Archive small
single-cleanup fix docs/patches/i386-text-render-cleanup-candidate.patch; applies
cleanly, not yet runtime-qualified or applied to running candidates. This does
not establish the exception's original cause or fix available memory.
Focused 8 MiB fresh-console renderer probe is live PID 3761606/session 63677,
script build/text-base-extended-probe.py, logs/output build/text-base-extended-probe.
It invokes real NativeTextBasePresent after compiling TextFrameDemo and restores
the display; investigate longer-test memory pressure separately if fresh passes.
Native ExceptionEntry check remains awaiting harness terminal failure after
observed guest rejection; capacity-fixed image needs a fresh test afterward.

Native top assembly immediate gap and renderer probe correction (2026-10-05):
Capacity-fixed native ExceptionEntry still rejects, reported at line 0x71.
Inspection identifies preceding MOV ECX,17: top assembler supports register/
memory MOV and special AX immediate, but no U32 register immediate. Parsing
advances to the next mnemonic before rejecting the operand form, so the reported
JC position alone did not identify the missing operation. Updated assembler
candidate emits B8+register plus little-endian immediate with explicit signed/
unsigned 32-bit bounds. Capacity correction remains necessary independently.
Small cumulative top-assembly patch updated; git apply --check passes.

Fresh separate build/extended-assembler-immediate-prototype combines extended
kernel, assembler instructions/capacity/immediate and renderer single-cleanup
patch. Original bootstrap live session 97542 in build/
extended-assembler-immediate-bootstrap.log. No native compiler green claimed.
Older capacity image/full test and focused native check retain their evidence;
repeat actual exception compilation only on newly built resident compiler.

Fresh renderer probe ended with COMMAND OK but screen expectation timed out:
NativeTextBasePresent changes the displayed surface, so expecting a text answer
before restoring it is an invalid oracle. Preserve first probe as inconclusive,
not a renderer failure. New build/text-base-extended-restored-probe.py restores
the display within a wrapper before returning its Bool and is live session
95025. Original full TextFrameDemo COMMAND ERROR remains independently valid
and unresolved. No completed graphics, installer or release pass claimed.

Fresh renderer probe passes; isolate full-suite failure (2026-10-05):
build/text-base-extended-restored-probe/result.json PASS at 8 MiB/486, four
commands, startup 22.28694190410897 seconds. Wrapper invokes real renderer,
restores console before returning Bool, verifies success and arithmetic42.
This corrects first probe's invalid post-graphics text expectation and proves
fresh-console renderer functionality, not full text-pattern/frame coverage.
Existing four-mode text-frames group now runs separately with hardware pixel
and hotkey checks, session 49616, out build/extended-text-frames-focused. Compare
with full-suite TextFrameDemo failure; do not assume memory pressure is proven.

Immediate-MOV plus consistent-capacity assembler and renderer-cleanup candidate
fresh original bootstrap passes both generations. Full kernel build/test live
session 28543, build/extended-assembler-immediate-prototype/build/
extended-assembler-immediate-kernel.log. Earlier capacity full test and rejected
native tests retain their handles/evidence; no repeated unchanged restart.
Next actual native exception check must use the new resident compiler image.
Full installation, two native generations and release remain incomplete.

Actual native exception rebuild green (2026-10-05):
build/native-exception-immediate-fixed/result.json PASS using the resident
compiler on the immediate/capacity-fixed extended image, 8 MiB/KVM/486.
Actual ExceptionEntry.HC compiles, generated module layout is valid and all
18 exports match the cross-built export contract. Native module SHA256
efd70d4951af804776ddc0f175d5dc1468e974dd26fc50a20edd73bf5dc2649e.
Startup 22.237485487014055 seconds; all pinned inputs unchanged. This closes
the actual compiler rejection, not module byte equivalence or two generations.
Complete six-retained-module native build now runs in a newly launched retained-build process, output build/extended-immediate-native-build.

Existing isolated text-frames group PASS, four exact pixel modes and break/
restore, five commands, 8 MiB/486, startup 28.763167825061828, same trace-qualified
disk SHA256 6e940d61a7207f99251f21c86adbe224533b9b2576da58ed38bb3994b15cf713.
Failure is dependent on prior full-session work; memory pressure is a hypothesis.
Instrumented full-session diagnostic live PID 3764870/session 10237, script
build/text-memory-session.py and generated source, output build/text-memory-session.
It logs task data-heap use before each text mode while preserving original full
sequence. No measurements or full-suite success claimed before completion.
New combined candidate full --test remains live. Physical verification stays
deferred and full objective remains incomplete.

Combined extended native six-module build PASS (2026-10-05):
build/extended-immediate-native-build/result.json PASS, all six retained modules
built by the actual resident compiler, source disk SHA256
5a6de32b1d21c85e35f4b7843a7b818ea30a2caf0195336941782630a141823d.
CompilerRuntime native SHA256 c9c22e68943caad9d01b1dbc50d0528ac804ed6014c64e5caa3a28ffb5d64ff9;
other exact native/reference hashes retained in result. Cross/native binary
identity is not claimed. Two native generations now run session 59834,
build/extended-immediate-native-generations, repository
build/extended-assembler-immediate-prototype, exact extended stage listing.
Freeze candidate sources/tools while native chain qualifies installation,
selfhost flat modules, independent boot audit and next generation.

Instrumented session first failed compiling its diagnostic helper (inline for
variable declaration unsupported). Preserve build/text-memory-session; stopped
that observed failed process tree. Corrected declaration before loop reaches
actual TextFrameDemo failure in build/text-memory-fixed-session, session65099.
E9 nibble logs decode to 1479800 live task-data bytes before include and 1482336
before TextFrameDemo(0). This only measures task live data, not code/private
heap reservations, largest free block or complete memory pressure. Do not claim
exhaustion from these numbers. Combined cleanup/assembler full --test also
fails at the same TextFrameDemo command; source-proven cleanup fix did not
resolve the original trigger. Preserve exact input artifacts and native pass.
Next investigate exception/allocator failure with complete reserved/live/free
measurements while independent native generations run. Full release open.

Renderer reservation diagnostic advances (2026-10-05):
Revalidated current root main/fork and clean worktree. Native generations is
confirmed live PID 3790555, first gen1-install/replace stage (fresh current
handle supersedes earlier launch PID assumptions); preserve same output and
candidate source pins. No installation pass claimed.

New full-session diagnostic build/text-reservation-session.py, generated source
build/text-reservation-instrumented-source.py, is live PID 3791133/session27112.
It records data and code heap used_u8s and alloced_u8s before rendering, then
calls NativeTextBasePresent and restores the display before checking Bool at
the exact full-session phase preceding TextFrameDemo. This distinguishes direct
renderer allocation/display failure from later demo/exception/break handling.
Previous task-only numbers remain valid but insufficient for memory diagnosis.
No reservation measurements or new runtime pass claimed yet. Continue current
handles; full graphics sequence, installed native generations and release remain
open. Root OS changes remain candidate patches until integrated qualification.

Extended loader capacity boundaries qualified (2026-10-05):
Checker now accepts explicit --payload-bytes, bounded above legacy capacity and
before volume LBA2048. build/extended-loader-unaligned/result.json PASS for
655361 bytes, and build/extended-loader-maximum/result.json PASS for 1043968
bytes. Each executes all 13 valid/metadata/checksum/memory/entry/truncation
cases under 486,-fpu/8 MiB (low-memory negative at 1 MiB). Exact destination
first/tail and handoff fields verified, source disks/inputs unchanged. Maximum
payload occupies through LBA2047; partial final sector validates declared-byte
hashing rather than hashing full rounded storage. This remains independent
loader fixture evidence, not full OS/native installation completion.

Native-generation handle3790555 remains live at gen1-install, renderer heap
reservation handle3791133 remains live before its measurement phase. Preserve
same handles and evidence; no new pass for these longer runs. Contract document
updated with capacity boundaries and remaining BIOS read-error/padding-negative,
installation, full-session and release gates. Physical testing stays deferred.

Late-session renderer path narrowed; owned-buffer reuse candidate (2026-10-05):
Reservation diagnostic reaches FramePresentProbe in full original sequence,
then COMMAND ERROR. Direct renderer invocation fails before TextFrameDemo's
own loop/break logic. Recorded data/code live/reserved tuples are both
1479760/1489408 (shared public heap); they do not measure private kernel arena
fragmentation, so exact exception cause remains open. Preserve diagnostic.

Text renderer allocates an additional 307200-byte packed surface and 153600-byte
planes although NativeGraphicsStart already owns a working gr.dc2 surface and
plane buffer. New separate build/extended-render-reuse-prototype uses validated
current-owner buffers when graphics is ready, rejects concurrent presentation,
sets/restores shared presentation guard, and preserves allocation fallback for
callers without an initialized owned graphics context. It does not free borrowed
buffers and preserves complete text-render/plane/VGA semantics. Single cleanup
on fallback exceptions remains included. Full delta
 docs/patches/i386-text-render-reuse-candidate.patch applies to root main;
combine with cumulative extended kernel and assembler deltas, replacing earlier
single-cleanup-only renderer delta. No pixel or full-suite pass claimed yet.
Fresh original bootstrap live session72277, log
build/extended-render-reuse-prototype/build/extended-render-reuse-bootstrap.log.
Then rerun all four exact pixel/hotkey frames and full long sequence at 8 MiB.
Prior native-generation candidate sources remain frozen and current installation
process continues independently. Full release remains incomplete.

Native installation fragmentation failure proved (2026-10-05):
Native-generation process terminal FAIL at gen1-install while replacing
ConsoleRuntime. Candidate deletes the old installed module but cross-directory
FileMove returns false; native source remains under /Probe. Preserve generation
logs, target candidate and bitmap. Independent new
 tools/audit-i386-redsea-space.py verifies reachable filesystem/bitmap first,
then reports aggregate free space and largest contiguous extent. Report
build/extended-native-install-space.json: 3538944 free bytes in seven extents,
largest1146368, native ConsoleRuntime1152984 bytes (needs1153024 sector-rounded).
Disk SHA2564dc6fa9bbd545c56f54357fd58153fa365d872ae4f27e94f85c26f4919c22dc4.
The current copy-publish-delete cross-directory move needs another contiguous
full-file allocation, exceeding that largest gap despite enough total space.
This changes next work from suspected heap allocation to file-move disk-space
architecture. No native installation pass or automatic unchanged retry.

TDD next: move a large regular file between directories on a fragmented valid
volume with no file-sized free extent; require unchanged content/data extent,
source disappearance, target publication, exact ownership bitmap, bounded
metadata writes, rollback/recovery at each publication interruption. Implement
an ownership-preserving directory move with durable intent and recovery instead
of duplicating a live file's entire extent. Keep same-directory rename and
existing negative/IO/recovery contracts. Installer ordering may improve space
headroom but must not replace this general file-move correctness/resource gate.

Renderer reuse bootstrap PASS both generations; full --test live session32659,
output build/extended-render-reuse-prototype/build/extended-render-reuse-kernel.
Native candidate sources remain preserved; full release and native generations
still incomplete.

Fragmented native-module move TDD and renderer compile fix (2026-10-05):
New tools/test-i386-fragmented-module-move.py prepares the exact prior three
retained replacements and ConsoleRuntime deletion on a writable source copy,
then requires cross-directory native module move success, preserved extent/
size/date/attributes/payload and boot area, source disappearance and independent
filesystem ownership integrity. Pins source and checker dependencies; fresh
output required. Run from actual six-module build source. Red run live
session71898, build/fragmented-module-move-red; no test pass claimed. This is
an actual installation-derived reproducer, not interrupted-metadata recovery.

Renderer reuse cross-build is terminal FAIL at forward graphics_presenting
variable: original compiler cannot use that undeclared storage in this module
context. Preserve exports/compiler-log.DD and old bootstrap as
build/rebuild-before-lock-functions. Candidate now calls explicit graphics lock/
unlock functions defined alongside the actual presenting state; all validation
and owned-buffer cleanup remain. Updated renderer patch includes GraphicsFrame
helper definitions and applies cleanly. Fresh changed-source bootstrap live
session18478, log extended-render-lock-bootstrap.log. Only then rebuild/test its
actual ConsoleRuntime. Native generations remain failed pending file-move fix;
no installer/release success claimed.

Fragmented move red and extent-transfer candidate (2026-10-05):
build/fragmented-module-move-red/result.json terminal FAIL at exact final move,
inputs unchanged; prior three replacement commands and deletion succeeded.
New independent build/extended-move-extent-prototype implements prepared target
slot/directory growth before intent, publishes target metadata referencing the
source's existing extent, tombstones source without freeing data, then clears
intent. Distinct version-two transfer magic distinguishes shared-extent recovery
from historical version-one copied-extent recovery. With both names present,
transfer recovery removes destination metadata without freeing shared data;
legacy copy recovery still frees its duplicate. Destination extent must match
recorded source in transfer mode. No whole-file allocation/copy on new move.

Full cumulative docs/patches/i386-redsea-extent-move-candidate.patch applies
cleanly to main (includes extended kernel/assembler/renderer changes; use it
instead of layering overlapping older patches). Fresh original bootstrap live
session72685, extended-move-extent-bootstrap.log. This is unqualified candidate
code: run red fixture green, verify metadata-only writes/content/ownership,
existing failure stages, directory growth and mount/IO interruption recovery,
then rerun retained installation/two native generations. Bitmap reconciliation
and durable journal correctness must be verified together before promotion.
Renderer lock-function bootstrap passed; its runtime validation remains pending.
Full objective remains open.

Transfer journal mount-order audit corrected (2026-10-05):
Extent-move original bootstrap passes both generations; first cross-build/full
--test runs session85443 in build/extended-move-extent-prototype. Do not transfer
runtime evidence from this source to recovery-complete source. Mount source
inspection finds existing bitmap ownership repair precedes move recovery. A
pending shared-extent transfer temporarily exposes two names for one data extent
and would be rejected by repair before journal rollback can unlink the duplicate.

Separate build/extended-transfer-recovery-prototype reads the volume move mode
at mount: version-two transfer intent is validated/replayed before bitmap repair;
legacy copy intent retains repair-before-replay. Journal validation includes
checksum and exact source/destination extent metadata before unlink. Full
cumulative extent-move patch updated with this mount ordering, applies cleanly.
Fresh original bootstrap runs session52904, extended-transfer-recovery-bootstrap.log.
No crash-recovery or complete installation green claimed. Required interruption
fixtures must independently prove both duplicate-name rollback and source-absent
commit, bitmap uniqueness and legacy-journal behavior. Build new kernel, run
actual fragmented move and native generation gates on exact corrected source.
Renderer pixel/full-session and release qualification remain open.

Independent transfer journal reboot fixtures start (2026-10-05):
Recovery-corrected original bootstrap passes both generations. Actual full kernel
build/test is live session80886, extended-transfer-recovery-kernel.log, with new
kernel.img available. New tools/test-i386-transfer-recovery.py constructs intent-
only, duplicate-name shared-extent and committed-source-absent journal states
independently on writable copies of that exact image. It encodes version-two
journal/FNV metadata, reboots each state, requires arithmetic42, expected source/
target namespace, original extent/content, cleared journal, unchanged boot area
and independently valid unique ownership bitmap. Existing source input and tool
pins must stay unchanged. Current runtime run live session67360 in
build/transfer-recovery-boundaries. Python compilation/diff check pass; no runtime
recovery green claimed yet. Scope is three durable publication boundaries, not
every device-write interruption, directory growth, corrupt journals or legacy
copy recovery. Fragmented module move and native generations remain to qualify.
Full objective and renderer long-session qualification remain open.

Transfer boundary recovery and owned-buffer renderer green (2026-10-05):
build/transfer-recovery-boundaries/result.json PASS for independently constructed
intent-only, both-names-shared-extent and committed-source-absent reboot states.
Each returns arithmetic42, clears journal, preserves original extent/content/
boot area, exposes correct source or target and passes unique ownership bitmap
audit. Exact disk SHA2567b4bb4c4f5e1565e16e70da1c0ce391eb69faafff174e18b10d3aadb10ada13b.
All source/checker pins unchanged for that completed run. These three durable
boundaries are not every IO interruption, malformed-journal or directory-growth
qualification. Updated checker independently constructs historical legacy copied
extent duplicate and bitmap allocation; legacy-only compatibility run live
session89204, out build/transfer-recovery-legacy.

Same source owned-buffer renderer passes all four exact text-frame pixel modes
and break/restore at 8 MiB/486, five commands, startup28.616987181827426, output
build/extended-render-reuse-text-frames. Full long-session --test remains running
and is still required. Recovery-corrected source six retained native modules
build live PID3799572/session62892, out build/extended-transfer-native-build.
After it passes, repeat actual fragmented native-module move and two generations.
Keep exact candidate sources frozen; root OS not yet promoted. Full release open.

Legacy journal compatibility and malformed-transfer rejection green (2026-10-05):
build/transfer-recovery-legacy/result.json PASS for independently copied legacy
version-one duplicate extent: reboot rolls back destination, retains source,
clears intent, preserves payload/boot bytes and passes bitmap ownership audit.
New tools/test-i386-transfer-rejection.py tests native mount under TCG486,-fpu
on independently encoded bad checksum, unknown version, source size mismatch,
source block mismatch and destination block mismatch. All five PASS in
build/transfer-journal-rejection/result.json: START native kernel then FAIL
before REDSEA publication, backing disk bytes unchanged after QEMU exits,
inputs unchanged. This validates fail-closed mount behavior for these metadata
classes, not all malformed strings/IO interruption or arbitrary corrupted FS.

Recovery-corrected full interactive test now reaches compiler command19 after
all four text-frame modes in the long sequence (checkpoint.json); former
TextFrameDemo failure point is passed. No terminal full --test pass yet claimed.
Both cross-build full tests and six-module retained native build remain live;
continue existing processes and source pins. Next actual fragmented native
module fixture and two generations depend on that native build. Physical
verification deferred, root OS candidate promotion/release still open.

Low-space extent move test starts while native rebuild runs (2026-10-05):
New tools/test-i386-low-space-move.py constructs a validated disposable volume
with a regular reserve file occupying the largest free extent, leaving every
free extent smaller than loaded ConsoleRuntime. Actual guest FileMove must move
that module between directories and back, preserving extent/size/date/attributes,
payload, allocation bitmap and boot area; source input/checker pins unchanged.
It verifies fixture and final reachable filesystem ownership independently.
Run live session4129, out build/low-space-module-move, exact recovery-corrected
disk. This is resource/metadata ownership coverage, not the native installation-
derived fragmentation fixture or crash interruption coverage. No pass claimed.

Full recovery-corrected interactive suite has reached document nested-lock tests
after all graphics/text and compiler groups. Same retained native six-module
build remains confirmed live PID3799572; full --test PID3797124 continues. Keep
current handles/source pins rather than restart on duration. On native build
success run original fragmented-module fixture and two-generation install chain.
Full release objective stays open.

Actual low-space same-extent move green (2026-10-05):
build/low-space-module-move/result.json PASS on exact recovery-corrected image.
ConsoleRuntime1060985 bytes moves out and back while largest free extent is only
512 bytes. Extent/size/date/attributes, payload, allocation bitmap and boot area
unchanged; both namespace transitions return1, arithmetic42, independently valid
filesystem, input pins unchanged. This proves the new move avoids a full-file
copy on that valid low-space fixture. Actual installation-derived fragmentation
and two native generations still depend on the running six-module rebuild.

Host oracle now compares every backing-image byte outside the two affected
directories and reports changed directory sectors. New stronger run live
session86012, build/low-space-move-bounded-writes. This checks final persistent
changes, not all transient journal writes or power-loss durability. Earlier pass
retains its original checker hash and narrower scope. Full test is still live
in document checks; native retained build PID3799572 is confirmed live. No
terminal full/native generation/release completion claimed.

Bounded KBC loader A20 fallback qualified independently (2026-10-05):
Standalone tools/i386-extended-stage.asm now checks existing A20, attempts the
8042 output-port enable with bounded100000 polls and pending-byte drain, then
verified port92 fallback if needed. Scratch bytes restored and alias/high-byte
checks required before streaming. Checker --kbc-path fixture disables both gates,
proves A20 initially off, and disallows fast fallback: actual controller path
must reenable high-memory access. build/extended-loader-kbc/result.json PASS
all13 cases; automatic path build/extended-loader-a20-automatic also PASS all13.
These are standalone stage sources, not the frozen native-generation candidate;
integrate with its executable-range auditor, rerun 386/no-FPU/image/native gates.
BIOS enable alternative and physical hardware qualification are not claimed.

Stronger low-space module move final byte comparison PASS in
build/low-space-move-bounded-writes/result.json. Only final changed sector19828
is in the affected directory; payload/bitmap/boot/all other backing bytes
unchanged. This is final persistent bytes, not trace of transient journal writes.
Current full-suite/native rebuild processes remain live; do not transfer loader
fallback evidence to their older stage or claim release completion.

Integrated KBC extended stage enters qualification (2026-10-05):
Separate build/extended-a20-integrated-prototype combines full transfer-recovery/
renderer/assembler candidate with root tested KBC loader. Earlier stage patch
context predates fallback; exclude that old stage hunk and retain current root
stage, add explicit placed executable labels/near entry and updated exact ISA
allowlist for RET/CLC/JE. Integrated --kbc-path passes all13 loader cases and
exact boot instruction audit passes96 BIOS/207 stage instructions in
build/extended-a20-integrated-kbc/boot-audit.json. This still precedes actual
full OS/native installation qualification for the new stage.

All1270 original-bootstrap source hashes match recovery-corrected bootstrap and
both overlay generation binaries match its result. Reuse immutable qualified
bootstrap (pure loader/host-tool changes); do not mislabel as fresh OS rebuild.
Actual full --test now live session28025, extended-a20-integrated-kernel.log.
Full cumulative docs/patches/i386-a20-integrated-candidate.patch applies cleanly
to current main and includes all relevant OS/loader/tool candidate changes.
Prior native rebuild/full-suite runs confirmed live with their older stage;
source pins remain frozen. Initial protected exception handling, BIOS fallback
alternative and physical hardware remain unqualified; release stays open.


Early protected-mode loader exception candidate (2026-10-05):
Preserve a 256-entry early IDT in the extended 4096-byte stage. Restore
physical-zero BIOS IDTR before real-mode disk calls and reload the protected
IDTR before copying each sector. Faults emit F and halt; malformed boot inputs
retain their B failure marker. Separate candidate avoids changing running builds.
Evidence: build/extended-early-idt-loader/result.json PASS 13 ordinary cases;
build/extended-early-idt-kbc/result.json PASS 13 forced-controller A20 cases;
build/extended-early-idt-int3/result.json PASS forced INT3 before payload execution.
Both forced fixture boot ISA audits PASS (96 BIOS, 210/225 stage instructions).
Original ordinary run pins pre-fixture source; subsequent KBC/INT3 runs pin the
final stage. These are loader tests, not full TempleOS integration qualification.
Cumulative docs/patches/i386-early-idt-integrated-candidate.patch applies to main.
Full OS suites and retained six-module rebuild remain live; native generation
installation and release acceptance remain open. Physical/manual tests deferred.


Native extent-transfer validation and harness checksum work (2026-10-05):
build/extended-transfer-native-build/result.json PASS all six retained native
modules, source SHA256 7a36c58992e6e6f4aba3875c3d1e61d45a08976037c1c59f2e376bd951965d0e.
Native outputs pass module/export contracts; this does not claim cross-build
byte equality. build/fragmented-module-move-green/result.json PASS using that
retained source: actual ConsoleRuntime 1154987 bytes, original extent 25661
preserved, unique filesystem ownership/bitmap verified, five interactive
commands, 16 MiB QEMU 486, source inputs unchanged. This reproduces the native
installation fragmentation condition, not just the artificial low-space case.
Two-generation validation now running in build/extended-transfer-native-generations
(session65702); requires rebuild/install/reboot evidence before qualification.
Separate early-IDT candidate harness fixes ten remaining payload-flag mutation
sites to refresh E32B checksum before saving, including target format/mount,
source tree copy, write/flush recovery and clearing mutation flags. Python
syntax check PASS; real file-I/O failure matrix running session95631 in
build/extended-checksum-io-matrix. No matrix PASS claimed yet. Preserved full
candidate patch updated; live older full-suite/native-generation sources frozen.


Early-IDT complete-OS boot qualification (2026-10-05):
New tools/test-i386-extended-os-boot.py replaces only the loader of an existing
E32B OS image after independently checking the exact payload checksum. It
checks NASM output size and all bytes from payload through filesystem remain
unchanged, audits boot instructions, then boots 8 MiB QEMU 486,-fpu and checks
HolyC 6*7=42 with VGA checkpoint comparison. Source inputs are SHA256 pinned.
build/extended-early-idt-os-boot/result.json PASS with the integrated A20 OS
payload and final early-IDT candidate. Boot audit PASS 96 BIOS/209 stage
instructions. This proves integrated normal boot and one interactive command;
full suites, two native installation generations, all failure-matrix cases,
and release qualification remain pending. Existing builds continue untouched.
Reproduce with --disk build/extended-a20-integrated-prototype/build/extended-a20-integrated-kernel/kernel.img
--stage build/extended-early-idt-prototype/tools/i386-extended-stage.asm
--audit build/extended-early-idt-prototype/tools/audit-i386-boot.py --out NEW_DIR.


Current full-suite failure retained (2026-10-05):
Both extent-transfer and recovery-corrected candidates reached FILE MOVE PROBE
0000000000000004 and passed phase-1 STRING COPY / PUBLIC HASH TABLES / PUBLIC
DEFINE LIST, then emitted FAIL native kernel during the mutation diagnostic.
The first candidate terminated nonzero; the corrected candidate debug log also
shows the failure. No full-suite PASS or storage-regression closure is claimed.
Failure localizes to the remaining phase-1 MemoryProbe assertions, not the
move-probe return. Exact assertion/cause remains unknown. Do not loosen memory
checks or assume an allocation failure without evidence. Separate main/fork
clone build/extended-memory-probe-diagnostic adds six diagnostic progress and
backing-pool accounting markers while preserving every assertion, archived in
docs/patches/i386-memory-probe-diagnostic.patch (apply after integrated patch).
Fresh original bootstrap rebuild running session42997; must pass and match
source hashes before cross-building this changed OS diagnostic candidate.
Current early-IDT no-FPU debugger trace five-cycle test also running session21008.
Recovery matrix and two native installation generations continue independently.


Native generation and diagnostic follow-up (2026-10-05):
Latest build/debug-cpu-trace-early-idt-five/result.json PASS five cycles,
48 commands, 8 MiB 486,-fpu; live throwing-allocation caller bound and debugger
G/mode/IF/TF/heap checks, source disk unchanged. Not all frame/error cases.
Generation1 retained installation succeeded; native selfhost built and installed
499736-byte payload, but its boot failed #UD at 0x179D57. Target.img disassembly
shows SysTry registration CALL followed by bytes 82 C0 instead of TEST EAX,EAX
85 C0. Source TopAssembly TEST register handler incorrectly used the branch
opcode selector, producing 82; do not claim native generation boot success.
Separate build/extended-top-test-fix restores fixed 85 TEST encoding, preserved
as docs/patches/i386-top-assembly-test-encoding-fix.patch after integrated patch.
Fresh original bootstrap for fix running session56114. Focused regression
 tools/test-i386-native-systry-build.py compiles actual SysTry and independently
requires 85 C0 after its unique registration call; red-source run session2028
pending. Requalify corrected native modules/kernel/install/boot and generation2.
I/O failure matrix passed four write-injection/recovery positions, then old
fifth-write probe failed because no fifth write fired (move succeeded). Existing
copy-based 7-write/6-flush fixture limits are stale for extent transfer; qualify
all four writes/four flushes for the prepared-directory path and directory-growth
path separately rather than infer coverage or weaken OS failure handling.
Memory diagnostic fresh original two-generation bootstrap PASS; cross-build
running session92192. Exact phase1 memory assertion remains open.


TEST encoding regression and follow-up qualification (2026-10-05):
build/native-systry-test-red/result.json fails exactly on required 85 C0
registration TEST bytes after actual guest compilation; compiler command/VGA
passes but emitted instruction oracle rejects. This is a genuine red regression
against the failing generation source, not just source-text inspection.
Corrected build/extended-top-test-fix fresh original bootstrap PASS two
rebuilds and source-qualified cross-build PASS (build/top-test-kernel). Native
SysTry green attempt running session13699; full corrected six-module native
rebuild running session13492 in build/top-test-fixed-native-build. Neither
native result claimed PASS yet; two-generation integration must follow.
Prepared-directory transfer failure matrix updated in preserved integrated
candidate to four writes/four flushes, based on the four journal/publish/unlink/
clear writes and flushes and observed fifth write never firing. Explicit scope
excludes directory growth. New real matrix running session67680 under
build/extended-transfer-io-matrix-four; old failed matrix retained unchanged.
Memory diagnostic cross-build PASS; exact mutation reproduction now running
session16279 in build/memory-probe-failure-detail, with accounting markers.
Release and promotion to main OS source remain pending these integration gates.


Native TEST green and memory-baseline candidate (2026-10-05):
build/native-systry-test-green/result.json PASS actual guest compilation,
registration TEST exactly 85 C0 and sole SysTry export; module SHA256
4a8266a14b06c8ad0a10e4cf5dce7c078e1bf2203ef66f16456ba7df4dccb434.
Red/green regression established. Full fixed native build remains running.
Instrumented mutation diagnostic reached all six memory checkpoints then FAIL.
Phase1 HASH private heap used 0x5F5588 / allocations0x1BA0, FINAL used0x5E5348 /
allocations0x1B9F; difference exactly prior backing span0x10240 and one allocation.
FINAL pool owned_count, retained and used_u8s all zero. The strict equality
baseline was captured before empty allocation cache/backing reclamation.
Separate build/extended-memory-baseline-fix requires zero live task allocations,
trims task pages and backing arenas, asserts an empty pool, then captures baseline.
All original final exact heap/allocation/empty-pool/integrity assertions remain.
No relaxed inequality or omitted leak check. Qualification still pending; fresh
original bootstrap running session81051 before full cross-build/test. Preserved
full docs/patches/i386-memory-baseline-integrated-candidate.patch applies to main
and includes native TEST fix, early IDT, extent transfer and corrected harness.
Do not treat diagnostic localization or candidate as a full-suite PASS.


Destination-directory growth contract (2026-10-05):
Added tools/test-i386-move-directory-growth.py. Guest prepares two eight-entry
(one-sector) directories, source MOVE payload and five destination files; host
oracle checks exact initial directory size512. Guest move must grow destination
to1024 on a fresh directory extent while moved file attr/block/size/date remain
identical to source. Existing filler bytes and moved payload are checked exactly,
source name disappears, filesystem bitmap/unique ownership verified, read-only
writable reboot checks42 and must leave disk SHA256 unchanged. Input/checker/
helper sources pinned throughout. Real run session35952 in
build/move-directory-growth; no PASS claimed until terminal report. Interrupted
directory-growth writes remain a separate open requirement. PLAN opening now
explicitly identifies latest unpromoted candidate and historical evidence scope.


Memory diagnostic advancement and growth fixture correction (2026-10-05):
Corrected memory-baseline candidate normal diagnostic boot has passed both
MEMORY PROBE phases0/1 and parser memory phases0/1. Full suite remains live;
mutation-specific reproduction isolated in build/memory-baseline-mutation-isolated
(session51152) to avoid sharing the full suite's writable mutation image.
An initial focused run was stopped to remove that potential path conflict;
no PASS/FAIL outcome is inferred from the stopped run.
Directory-growth fixture first expected FileWrite byte count4, then mistakenly
used internal helper Bool semantics. Both failed expectation runs are retained.
Public FileWrite returns a positive block number (existing public-file tests
and I386TaskFileWritePublic contract), so corrected test requires >0. Independent
exact-content/extent/directory-size/reboot oracles remain unchanged. New run
build/move-directory-growth-public-write session72733; no growth PASS yet.


Prepared extent-transfer I/O recovery PASS (2026-10-05):
build/extended-transfer-io-matrix-four/result.json PASS all eight independently
armed real guest write/flush failures: writes1/2/3 recover source, write4
recovers destination; flushes1/2 recover source, flushes3/4 recover destination.
Each recovery clears journal, verifies exactly one complete IO payload, and
validates unique filesystem ownership/bitmap (873 files,17782 owned sectors).
Scope is prepared destination slot, not interrupted directory expansion.
Strict trimmed memory probe now also passed the mutation reproduction's former
failure point: FILE MOVE PROBE4 then phase1 MEMORY PROBE and PARSER MEMORY PROBE
in build/memory-baseline-mutation-isolated/boot/debug.log. Full reproduction and
full suite remain running; no complete suite result inferred from these markers.
Directory-growth fixture setup corrected to DirMk(...,5), because entry_cnt is
user capacity and implementation adds three bookkeeping entries before rounding.
Observed prior ...8 request produced1024 rather than512; prior failure retained.
New build/move-directory-growth-full-sector session90911 verifies512 before move,
requires1024 afterward, same file extent/metadata/exact filler bytes and reboot.
No growth PASS claimed yet. Existing public FileWrite >0 contract retained.


Extent-transfer qualification checkpoint (2026-10-05):
build/move-directory-growth-full-sector/result.json PASS all three real boots,
512->1024 destination growth on fresh extent, moved original extent19839,
identical metadata and exact MOVE/five filler payloads, bitmap/unique ownership,
8 MiB writable reboot with unchanged hash, all input hashes unchanged.
Prepared eight-case recovery PASS remains separately scoped. Consolidated
reviewable coverage/commands/limits in docs/i386-extent-transfer-qualification.md.
Latest combined baseline source retained native rebuild started session82294,
build/memory-baseline-native-build. Earlier TEST-fixed native rebuild remains
live; no restart. Isolated baseline mutation guest completed DONE native kernel
startup with no FAIL; full suite remains separate and live. Two generations and
release remain open; interrupted directory-growth matrix still required.


Interrupted destination-growth fixture implementation (2026-10-05):
Separate main/fork clone build/extended-growth-failure-prototype adds private
raw operations6/7 mapping to write/flush failures. Before arming it prepares
one full512-byte destination with five F files; source IO and move execute after
arming. Original normal move/replace probes and normal startup remain separate.
Candidate matrix accepts growth=True and checks both one complete IO namespace
and exact five existing file payloads after recovery. Proposed coverage nine
writes/eight flushes derives from allocation bitmap, old/new directory sectors,
parent publication, old extent release, and four transfer-journal/name writes.
Real runs must prove each injection fires; counts are not qualification yet.
New tools/test-i386-move-growth-failures.py freezes disk, exports, helper sources
and writes terminal pass/fail evidence with source hashes even on exceptions.
Fixture delta docs/patches/i386-move-growth-failure-fixture.patch applies after
i386-memory-baseline-integrated-candidate.patch. Python syntax and patch check
PASS. Fresh original bootstrap PASS; source-qualified cross-build running
session38551, build/growth-failure-kernel.log. No growth
failure matrix PASS claimed. Existing full-suite and native builds untouched.


Final early-IDT loader boundary qualification (2026-10-05):
build/extended-early-idt-maximum/result.json PASS13 at exact payload capacity
1043968 bytes (2039 sectors before filesystem LBA2048). Final stage386 audit
PASS96 BIOS/209 stage instructions. build/extended-early-idt-unaligned/result.json
PASS13 with655361-byte payload, exercising exact-byte checksum over a partial
last sector. Same final early-IDT stage as combined memory-baseline candidate;
source hashes pinned. Covers streamed payload markers/handoff and rejection
cases, not native generation installation or physical-PC qualification.
Interrupted-growth fixture source-qualified cross-build PASS with fresh original
bootstrap and386 boot audit. Full17-case proposed write/flush growth matrix now
running session60661 under build/move-growth-failures. Each failing operation
must fire before its case can pass, then recovery checks one IO name, existing
five F files and filesystem. No matrix result claimed yet; native/build suites
remain live on frozen sources and are not restarted.


Corrected native retained build and latest debugger PASS (2026-10-05):
build/top-test-fixed-native-build/result.json PASS all six retained providers,
source diskSHA256957d5ddd1aee581b395b06d08e466fe2bfbebd1bee14ccda2376878c147c4d2d.
Corrected native CompilerRuntime SHA256
6b933d0ba99d4467848fd3e834fbc6101328e8f7c1ff1c72fefccf3a63b62fba,
1747153 bytes. Other provider payload hashes match the prior retained candidate;
this does not imply cross-build byte equality or latest baseline qualification.
Actual corrected-source two-generation install/build/boot/audit now running
session46610 in build/top-test-fixed-native-generations. Must pass to close the
previous SysTry invalid-opcode generation failure. Its repository remains frozen.
build/debug-cpu-trace-memory-baseline-five/result.json PASS five cycles on latest
combined memory-baseline image, 8 MiB486,-fpu, exact caller-allocation bound,
G/mode/IF/TF/heap/VGA checks, source unchanged. Earlier stage-only result no
longer substitutes for this current combined image. Full suite, latest retained
rebuilding and interrupted-growth matrix remain live; no broad completion claim.


Public Caller compatibility regression (2026-10-05):
Kernel/I386/Debug.HC implements Caller, but current interactive provider does
not bind/publish it. New tools/test-i386-public-caller.py on the latest combined
image reaches INPUT LINE Caller(-1)==0 then FRONTEND ERROR Undefined identifier
and COMMAND ERROR. build/public-caller-red preserves the expected red outcome.
This public API is distinct from private exception caller tracing. Test requires
negative/excessive depth rejection and independently bounds Caller(0)/Caller(1)
within two live compiled function allocations. It does not claim malformed/
freed/cyclic frame coverage or other-task TaskCaller semantics. Implement/publish
Caller with valid private stack bounds in a separate candidate, qualify red/green,
then extend debugger-stack/invalid-frame coverage. Existing live qualification
sources remain frozen; original programming model compatibility stays required.


Latest retained native PASS and public Caller binding candidate (2026-10-05):
build/memory-baseline-native-build/result.json PASS all six native providers,
sourceSHA256e0e66032d1349c7ea22ca52ffe6e33920c5d5e0ed531ee2b1ae832adde1064fb.
Native MemoryRuntime312117 bytes SHA256
ea14a46ed388784e7c57f745c03d6a473fbddd26ab491f658979f162cc5c2e52;
other five provider hashes match TEST-fixed native source qualification. This
qualifies retained rebuilding, not kernel installation/generation2. Actual
latest-source two-generation runner started build/memory-baseline-native-generations.
Separate build/extended-public-caller-bound-prototype adds NativeCaller using
owned original/debug stack bounds, public _CALLER declaration and export, private
kernel loader FrameParent/FrameReturn bindings, exact import allowlist and
console version39. Cumulative i386-public-caller-integrated-candidate.patch
preserves full implementation; patch/syntax checks PASS. Fresh bootstrap session
36257 running before cross-build/green tests. No public Caller PASS claimed.
Earlier intermediate caller prototypes are superseded; live main qualification
sources remain untouched. Accidental root bootstrap invocation was stopped,
its partial output retained separately and original root bootstrap restored.


Public Caller green, growth recovery and generation1 checkpoint (2026-10-05):
build/public-caller-green/result.json PASS eight commands on new console39,
negative/excessive depth return0, Caller0/1 addresses independently bounded by
live Body/Outer allocations. Source/checker unchanged. Fresh original bootstrap
and source-qualified cross/386 boot audit PASS; full caller suite now session18126,
build/public-caller-full-kernel. No full-suite PASS yet.
build/move-growth-failures/result.json PASS17: nine write and eight flush failures,
each armed before full-directory transfer, reboot recovery retains one complete
IO file plus exact five existing F files, clean journal/bitmap/unique ownership,
all pinned inputs unchanged. Interrupted-growth gate covered on fixture source.
TEST-fixed generation1 retained installation/native flat build/install/boot/386
audit PASS; runner now generation2 retained build. Latest baseline generations
also running separately, no result transferred between candidate sources.
Baseline full suite terminated at native allocation verifier after mutation
startup. Actual module54 records,20 exports,34 calls matches current HeapScan
source; old expectation52/19/33 stale. File loader similarly79/24/55 rather than
77/23/54. Root and caller candidate verifiers updated exact contracts, current
retained artifacts PASS. Candidate creator raw module87 records,9 exports,78
calls includes three new extent helpers; exact verifier updated and artifact PASS.
Source-built creator poll/count extension remains provisional until real native
source-build gate reaches it; no claim of qualification from raw-module checks.
Root OS remains unpromoted ABI40; latest caller candidate cumulative patch updated.


Source-built creator exact-contract red/green (2026-10-05):
New tools/test-i386-native-create-build.py invokes real I386BuildModule without
the template flag, retains the emitted module and checks exact creator exports,
imports, relocated break-poll callsites and source identity. Initial native compile
passed but old provisional107/98/20 record/call/poll verifier rejected artifact.
Observed source-built module has109 records,100 calls,22 polls and nine exports.
Corrected exact109/100/22 contract verifies retained artifact and a fresh real
compile: build/native-create-record-contract-green/result.json PASS, all input
hashes unchanged. Raw-module87/78 contract remains distinct and unchanged.
Updated cumulative public Caller patch applies to current main. Separate host
contract candidate build/public-caller-archive-current has identical all1270
bootstrap source hashes; both actual generation binaries and final overlay hashes
also verified before immutable bootstrap reuse. Pure host-verifier change; reuse
is not a new bootstrap rebuild. Full corrected suite now running session24089,
build/public-caller-contract-kernel. Older provisional-count suite remains frozen.
Native generation2 rebuilds remain live; release qualification still open.


Public Caller invalid-frame gate and generation2 identity (2026-10-05):
Extended tools/test-i386-public-caller.py with --invalid-frames, preserving
original eight-command baseline. Uses existing GetRBP intrinsic alias, saves and
restores the current frame parent around each real Caller invocation. Three
cases create self-cycle, misaligned parent and out-of-stack parent; Caller2 must
return0, then valid CallerOuter address bounds must still pass. Latest integrated
image build/public-caller-invalid-frames/result.json PASS14 commands, all pinned
inputs unchanged. Not freed-frame/debugger-stack/other-task introspection proof.
Latest public Caller retained native build running session97501 in
build/public-caller-native-build. Earlier TEST-fixed generation2 retained build
PASS six modules with SHA256 byte identity to generation1; retained installation
also PASS, runner now gen2-selfhost. Latest baseline generation2 remains live;
none of these outcomes qualify newer Caller native installation automatically.
Storage qualification document updated with full17-case interrupted-growth PASS
and explicit source/child-directory limits. Full suites remain live; release open.


Native generation qualification and public Caller debugger stack (2026-10-05):
The TEST-fixed source epoch completes all eight stages in
build/top-test-fixed-native-generations/result.json: first installation,
self-hosted boot and audit, second retained build, installation, self-hosted
boot and audit, and generation identity. All 12 modules match byte for byte.
The 499736-byte native flat kernel SHA256 is
fde141afbd6bf80e658e8678ed642f5293d3798fbff17b0265f275aeef866f7e;
boot-area SHA256 is
c406a23b275f5a953e8026aacd9189cbd14a9271f4523b33bd450ad87eb2074c.
Both volumes have 16 directories, 873 files and 19276 uniquely owned sectors,
with allocation bitmaps matching reachable extents. Complete disk hashes differ:
this proves executable/boot-area reproducibility, not release-disk reproducibility.
Installed generation2 workstation workflows are running separately in
build/top-test-fixed-gen2-workflows; no workstation PASS yet claimed.

Added --public-caller to tools/test-i386-debug-cpu-trace.py. During a real
CPU debugger catch, Caller(0) must return within CpuCallerValid's live compiled
allocation, and default Caller() within its parent CpuTraceValid allocation.
The existing exact throwing-function trace, catch yield, G resume, mode/IF/TF
and heap recovery checks remain. Latest Caller image passes five cycles and
52 VGA-checked commands on 8 MiB, 486,-fpu:
build/debug-cpu-public-caller-five/result.json, source disk unchanged.
This closes the dedicated-debugger-stack gap of the public Caller baseline;
it does not prove arbitrary freed frames or other-task introspection.
The newer memory-baseline native generations and latest public Caller native
build/full suites remain live and retain their own source-specific gates.
Root OS remains unpromoted ABI40. Next release work requires latest-source
qualification and deterministic whole-image packaging; release remains open.


Deterministic whole-disk native packaging (2026-10-05):
Added tools/package-i386-native-image.py and docs/i386-release-packaging.md.
Actual TEST-fixed generation1/2 live trees match all873 file contents, attributes
and dates. Sorted live-tree placement preserves native boot area and every live
file, removes tombstones/slack/unreachable bytes and rebuilds bitmap. Both
packaged disk images now match byte for byte: SHA256
 a25fc4a39eda36441e8000669934def9c850e6a48f9951c43197806de016d7b9.
Independent filesystem ownership/readback PASS;16dirs873files19275owned sectors.
Repackaging is byte-identical; existing-output and pending-journal inputs rejected.
Independent packaged native executable/boot metadata/padding audit PASS in
build/native-release-packaging/native-audit/result.json. Initial invocation used
cross-built compiler marker mode and failed; preserved under packaging/audit,
corrected native-template mode matches existing generation qualification.
Packaged-image QEMU boot PASS on8MiB486,-fpu: normal interactive startup and
6*7=42 VGA-checked, image hash unchanged. Focused compiler/file-navigation/
DolDoc documents/editing workflows now running on a fresh writable copy; no
runtime PASS transferred from unpackaged image. Whole workstation/latest-source qualification and release
promotion remain open. Memory-baseline generation2 now reached selfhost; public
Caller retained native build remains live. Root OS remains unpromoted ABI40.


Packaged workstation provenance and memory-baseline native generations (2026-10-05):
tools/test-i386-installed-workflows.py now accepts optional --native-disk and
--packaging-result together. Native construction evidence must match original
native disk; installed audit must match requested packaged image and same flat
payload. Runner independently recomputes deterministic packaging and compares
whole image bytes before starting frozen workstation/DolDoc/speaker/resource
helpers. It pins original disk, packaging report and packaging helpers too.
New tools/test-i386-packaged-origin.py passes six real-artifact acceptance/
rejection cases in build/native-release-packaging/origin-mutations.json,
including forged matching report/audit hashes over altered boot bytes.
All input hashes unchanged. Full four-gate packaged suite is running in
build/native-release-packaging/installed-workflows. Formal packaged boot timing
passes51.399seconds versus60-second gate; full-suite budgets remain required.

Memory-baseline epoch now completes all eight native-generation stages in
build/memory-baseline-native-generations/result.json. All12modules match between
native generations;499736-byte flat kernel SHA256
fde141afbd6bf80e658e8678ed642f5293d3798fbff17b0265f275aeef866f7e;
boot-areaSHA256c406a23b275f5a953e8026aacd9189cbd14a9271f4523b33bd450ad87eb2074c.
Both volumes16dirs873files19279owned sectors with matching bitmaps.
Both deterministically packaged memory-baseline disks match SHA256
177ffbd736f9ae5010377ccb8dcd9b2b22220ab151e1baeee4c8a5087f3a90d9,
19278owned sectors after directory compaction. Packaged memory-baseline runtime
qualification still required; earlier TEST-fixed runtime passes not transferred.
TEST-fixed generation2 three-boot DolDoc, speaker and resource jobs now PASS;
aggregate remains running on full workstation. Public Caller source remains
newer and unpromoted, with native/full qualification running. Release stays open.


Latest public Caller six-provider native build completes (2026-10-05):
build/public-caller-native-build/result.json now PASS actual native construction
of all six retained providers. Started its own eight-stage native generation
pipeline in build/public-caller-native-generations against the frozen corrected
public Caller repository and stage listing. Older TEST-fixed/memory-baseline
native passes are not substituted. Packaged TEST-fixed speaker/resource jobs
also PASS; full workstation and DolDoc aggregate still running. Release open.


Installed workflow resource verdict enforced (2026-10-05):
Added tools/check-i386-installed-budgets.py. A functional four-job aggregate
PASS is insufficient without normal8MiB486,-fpu startup <=60seconds for the
workstation and all three DolDoc boots, long-document visible update <=1second,
and interrupt-to-recovery VGA <=1second. Nonpositive/nonfinite/missing timing
is rejected. tools/test-i386-installed-workflows.py now records and enforces
per-job budget verdicts before accepting a job. Frozen already-running helpers
remain unchanged; their completed reports need the standalone budget checker.
New tools/test-i386-installed-budgets.py accepts two actual recorded passing
workstation/DolDoc results and rejects18timing mutations, preserving pinned
inputs: build/native-release-packaging/budget-mutations-pinned.json PASS.
This is budget-validator evidence, not new current-source runtime evidence.

Memory-baseline packaged native audit now PASS in
build/memory-baseline-release-packaging/native-audit/result.json. Started its
four installed workflow gates with the new enforced budgets and independently
recomputed native origin in
build/memory-baseline-release-packaging/installed-workflows. Public Caller
native-generation pipeline reaches first selfhost stage; full qualification
and promotion remain required. Release stays open.


One-image debugger regression command (2026-10-05):
Added tools/test-i386-debugger-regression.py, freezing helpers/VGA font/original
KDbg contract source and pinning one image throughout20jobs. Covers6general
register banks, G/S flags, S/IP, G/S stack, initial alternate trap, bidirectional
stack overlap, breakpoint lifecycle/task-switch/shared-address ownership,
concurrent-repeat/kill and public Caller debugger-stack behavior. Repeated
fixtures run5cycles by default; ownership/kill retain fixed scenarios. Every
accepted job must PASS8MiB486,-fpu exactVGA and unchanged disk identity; aggregate
cannot pass missing/failed jobs. All20fixture generators satisfy255-byte input
limit. Latest Caller candidate regression now live in
build/public-caller-debugger-regression (two workers). No runtime aggregate PASS
claimed; existing historical debugger greens not transferred automatically.
Native Caller first-generation selfhost and packaged workstation runs remain
live. Root remains ABI40, newer candidate unpromoted, release remains open.
