# TempleOS architecture plan: 32-bit 386+ and VGA

## Objective and status

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
with the latest source remains open. The loader-index development image now
passes the full no-FPU workstation suite with 50.241406-second startup and a
0.261061-second long-document update; its retained inputs are cross-built. Older
fully guest-built startup results exceed the 60-second target. Functional passes and package
hash verification do not by themselves close these gaps. The historical
“next” sections below record the implementation sequence; the following work
queue supersedes their stale status and priority statements.

All work stays in our fork, `ddanila/TempleOS`, directly on `main`, without
feature branches or PRs. The former `archive` branch was removed after verifying
that its history is contained in `main`.

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
