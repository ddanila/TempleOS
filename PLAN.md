# TempleOS architecture plan: 32-bit 386+ and VGA

## Objective and status

Build a native, standalone 32-bit TempleOS variant for 386-class and later
PC-compatible machines with VGA. Preserve the interactive HolyC programming
system, ring-0 execution, one shared flat address space, DolDoc, and simple
software graphics and sound. Keep the working x86-64 system as a regression target.

This replaces the 16-bit feasibility track and makes native i386 the next
architectural target. Cross-platform QEMU launchers remain useful supporting
work; they are not a substitute for native 386 compatibility. ARM, RISC-V, UEFI,
and broad modern-device support are deferred.

Implementation is underway; see [port progress](docs/port-progress.md) for current
evidence and limitations. The full 32-bit OS is not yet implemented.
Current evidence covers the x86-64 image on QEMU 10.2.1/TCG: graphical startup,
two terminals, keyboard input, and HolyC `6*7;` returning `42`. The image verifier
checks 725 packaged files and embedded DolDoc record lengths. Two native x86-64 rebuild/reboot generations also pass; persistence, audio, and
multicore behavior still need baseline verification. The native i386 foundation
now boots a disk image on the 8 MiB QEMU/486 development profile, initializes
cooperative tasks and timer interrupts, reads its source from RedSea, and loads a
separate startup module that initializes VGA through resident imports. A retained
HolyC console now executes disk-backed startup source, compiles keyboard
submissions, retains definitions, recovers
from syntax errors and renders integer/pointer/software-F64 answers with the
original 8×8 font. These results do not establish strict 386 support, the complete
HolyC/DolDoc environment or native self-hosting. Component evidence and remaining limitations
are tracked in the progress document.

All work stays in our fork on `main`. Preserve `archive` at `c26482b`.

## Final goal: a fully working TempleOS on a PC-compatible machine

Deliver a standalone, self-hosting 32-bit TempleOS that a person can boot and use
as their complete offline HolyC development environment on a named physical
386-class PC with VGA. This is the final product milestone, M7; the current native
console and individual subsystem tests are intermediate evidence toward it.
"PC-compatible" means the reference hardware contract below, not the original
8088 IBM PC or every later PC configuration. Preserve the HolyC language, shared
ring-0 address space, cooperative tasks, executable DolDoc documents, graphics,
sound and on-machine development described in this plan.

M7 requires an integrated acceptance run with the following outcomes:

1. **Boot and operate independently.** Cold-boot a published hard-disk image through
   the machine's legacy BIOS into the normal interactive environment without a
   host compiler, attached test harness or mandatory diagnostic suite. Publish
   reproducible image preparation and boot instructions for the selected hardware.
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
   retained-memory growth. Establish measured responsiveness limits on the named
   hardware before final acceptance. Pass strict 386SX/DX, no-387 emulator checks
   and an integrated run on a named physical 386/VGA configuration; record exact
   BIOS, CPU, RAM, storage and peripheral details for each result.
6. **Publish a reviewable result.** Ship the boot image, matching source revision,
   build/boot instructions, support matrix, acceptance results and known limitations.
   Preserve the working x86-64 regression target. Remaining optional hardware and
   application work must be distinguished from failures of the required workflow.

M7 remains open until all required outcomes are demonstrated. Physical hardware
availability may delay that evidence; emulator success must remain labelled as
such. The existing deferrals for networking, modern devices and additional
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
Shared document records, locking services and native #help_file metadata remain
source-driven DolDoc dependencies.
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
public-contract work. Registered backing regions and a demand-growth provider now have native coverage, including return of wholly
unused regions to the bootstrap allocator. Task teardown now invokes the retained
provider after releasing heap controls; public free also notifies the provider
after finishing its page-header reads. See
[public memory](docs/i386-public-memory.md).
See [shared task records](docs/i386-task-records.md) and
[native public headers](docs/i386-public-headers.md).

Hardware acceptance runs alongside all four priorities: establish named 386SX/DX
profiles without a coprocessor, verify the legacy BIOS/ATA path and planar VGA,
audit generated and handwritten executable code, and measure input responsiveness
under compilation and disk/display activity. Current QEMU/486 evidence remains
development evidence. Physical-machine acceptance, full public APIs, DolDoc and
self-hosting remain explicit gates; a working native prompt does not close them.

### Next implementation slices

Use the following bounded changes to turn the roadmap into reviewable work.
Each slice must preserve the working x86-64 build and report native memory use.
The public-contract slices precede document integration; hardware validation can
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
| Native rebuild | Build compiler and kernel from source inside the resulting environment, install the generated boot artifacts and repeat the cycle. | Two native rebuild/reboot generations at the 16 MiB design target, followed by the named strict 386/no-387 acceptance profiles. |

Treat the RAM figures as acceptance targets pending full-workload measurements.
If the complete environment exceeds them, first identify retained versus temporary
allocations and unnecessary duplication. Any proposed change to the hardware
contract or HolyC/DolDoc behavior requires an explicit plan revision supported by
those measurements.

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
Keep strict 386/no-387 execution and physical VGA acceptance alongside this work;
the existing QEMU/486 results remain development evidence.

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
| CPU | 80386 instruction set, 32-bit protected mode, one CPU; validate SX and DX profiles |
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

### Vintage hardware verification alongside implementation

Maintain separate development and acceptance profiles. The current QEMU/486
profile provides fast integration feedback; it cannot certify the 386 baseline.
Record the emulator version/configuration or physical machine configuration with
each result, including CPU, coprocessor presence, usable RAM, BIOS, VGA and disk
geometry. Select and validate a strict 386 emulator profile before treating its
results as hardware acceptance; real-machine testing remains a separate gate.

| Profile | Purpose and required evidence |
| --- | --- |
| Development: QEMU/486, 8 MiB | Repeatable boot and integration checks, allocation accounting, disk persistence and VGA output. Keep this evidence distinct from strict CPU compatibility. |
| 386SX and 386DX, no 387, 8 MiB | Execute the generated-code corpus and interactive workflow; exercise legacy boot/memory discovery and software F64. Reject later instructions in executable code and verify that optional firmware services are unnecessary. |
| 386-class, no 387, 16 MiB | Rebuild the compiler and kernel natively, boot the outputs and report peak usable-memory demand and elapsed time. |
| Named physical 386/VGA machine | Verify boot, planar display, keyboard, selected mouse, ATA persistence and speaker/timer coexistence; record differences from emulator behavior. |

Run CPU and absent-coprocessor checks as compiler/runtime changes land. Exercise
fallback boot paths with modern BIOS services unavailable, and measure input
latency during disk access, VGA presentation and compilation. Use those results
to choose bounded work units and scheduling points; short protected register
operations must not become long interrupt-disabled display or disk loops.
Instruction audits, emulator execution and physical testing provide different
evidence and should all remain visible in release criteria.

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
  workflow and native rebuild. Keep strict 386 compatibility and x86-64 regression
  evidence alongside these gates.

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
| Development hardware conceals a later CPU or firmware dependency | Establish the strict 386/no-387 execution profile while public services are integrated. Audit executable regions and exercise legacy firmware fallbacks on every affected change. | Boot and generated-code tests pass on that profile before full document integration is declared complete; physical-machine acceptance remains a separate gate. |

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
self-hosting. Establish strict 386 test profiles and memory measurements alongside
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
   strict 386SX/DX and no-coprocessor verification gates. Establish that emulator
   profile early enough to test each preceding stage, not only the final image.

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
accounting. Establish named 386SX/DX emulator profiles now and apply them as work
lands; strict CPU, absent-FPU and legacy BIOS/device checks must not wait for
self-hosting. The current QEMU/486 result is development evidence only.

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
the strict 386SX/DX or full native programming-environment acceptance gates.

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
instruction baseline. Select and exercise a strict 386 emulator profile alongside
this work; the current 486 development result leaves that acceptance gate open.

| Milestone | Work and required evidence |
| --- | --- |
| M0: Verified starting point | A: source rebuild and regression baseline; select exact 386SX/DX emulator, BIOS, VGA, storage, and memory profiles |
| M1: Architecture contract | B and G: ABI/data-layout specification, module identification, format fixtures, memory accounting plan, instruction policy |
| M2: Compiled 32-bit code | C and initial D: cross-generated integer/I64 code executed by a minimal protected-mode runner; numerical and ABI tests underway |
| M3: Bootable 386 kernel | E and minimum F: CHS disk boot, VGA, keyboard, PIC/PIT, memory allocation, task switching; strict instruction checks |
| M4: Interactive HolyC | Complete essential C/D: native JIT/compiler, F64 without a coprocessor, shell, storage, exceptions; no integer-only completion claim |
| M5: TempleOS environment | F/G/H: DolDoc, editing/help, mouse, graphics, audio, persistence, portable data, measured low-memory workflow |
| M6: Self-hosting and portability proof | Native i386 compiler/kernel rebuild and reboot; 386SX/DX and later-CPU checks; x86-64 regressions and published support matrix |
| M7: Fully working PC system | Complete the integrated physical-PC acceptance workflow in the final-goal section: independent boot, HolyC/DolDoc development and debugging, graphics/input/sound, persistent documents, two native rebuild generations, measured RAM/latency and published artifacts. Pending; M0–M6 component evidence alone does not close this gate. |

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
Public CDrv/CFile integration, decompression and directory growth remain pending.
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

- Retain QEMU/TCG for fast development and x86-64 regression checks. On this machine,
  `qemu-system-i386 -cpu help` lists 486 and newer models but no 386 model.
  `qemu32` is not a 386 compatibility specification. A 486 QEMU boot is only a
  development result, even with feature flags disabled.
- Validate in a selected 386-capable emulator such as 86Box using explicit SX/DX,
  coprocessor-absent, VGA, RAM, BIOS, and IDE settings. Check its CPU enforcement
  and combine this with executable instruction audits; emulator success alone
  cannot establish compatibility with every real 386.
- Test missing optional BIOS calls, absent mouse/FPU, failed disk reads, constrained
  RAM, timer wrap, arithmetic boundary cases, and repeated task/exception transitions.
- Exercise both cross-generated and natively generated code, including JIT and
  compiler-generated assembly blocks; inspect runtime helpers and boot code too.
- Validate on an actual named 386 machine when available. Until then, label support
  as emulator-verified, not physical-hardware-verified. No claim of universal PC
  compatibility follows from either result.
- Record bootable artifacts, source/tool versions, commands, results, memory peaks,
  and timing. Every milestone must preserve the existing x86-64 working target.

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
