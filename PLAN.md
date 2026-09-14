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
multicore behavior still need baseline verification. Experimental i386 expression
and function backends are tracked in the progress document.

All work stays in our fork on `main`. Preserve `archive` at `c26482b`.

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

## Architectural work packages

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

| Milestone | Work and required evidence |
| --- | --- |
| M0: Verified starting point | A: source rebuild and regression baseline; select exact 386SX/DX emulator, BIOS, VGA, storage, and memory profiles |
| M1: Architecture contract | B and G: ABI/data-layout specification, module identification, format fixtures, memory accounting plan, instruction policy |
| M2: Compiled 32-bit code | C and initial D: cross-generated integer/I64 code executed by a minimal protected-mode runner; numerical and ABI tests underway |
| M3: Bootable 386 kernel | E and minimum F: CHS disk boot, VGA, keyboard, PIC/PIT, memory allocation, task switching; strict instruction checks |
| M4: Interactive HolyC | Complete essential C/D: native JIT/compiler, F64 without a coprocessor, shell, storage, exceptions; no integer-only completion claim |
| M5: TempleOS environment | F/G/H: DolDoc, editing/help, mouse, graphics, audio, persistence, portable data, measured low-memory workflow |
| M6: Self-hosting and portability proof | Native i386 compiler/kernel rebuild and reboot; 386SX/DX and later-CPU checks; x86-64 regressions and published support matrix |

M2's target runner and early M3 boot/interrupt work can be developed alongside
the backend after M1. Do not require the full compiler before running backend
tests, or the complete desktop before resolving compile-time execution.

The protected-mode runner now executes HolyC-generated integer functions with
32-bit pointers, 64-bit arithmetic, and basic control flow. Next, complete the
integer/call backend and native module loading path needed to compile and run
more kernel units, while closing the remaining M0/M1 gates. The architecture-tagged
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
conversion checks and x64 signed-conversion evidence. Implicit mixed conversions
and the remaining arithmetic/formatting/math surface still need integration. See `docs/i386-f64-backend.md`. Signed
and unsigned integer-to-F64 helpers now pass 2,048 conversion checks, including
64-bit extrema and nearest-even halfway cases. Signed F64-to-I64 truncation now
passes 1,024 inputs against actual x64 HolyC and an independent host oracle,
including invalid-result bits. Implicit language-node mapping, explicit unsigned output
semantics and floating-point exception state remain pending. Numerical
comparison now passes 2,048 checks, including unordered NaNs, signed zeros and
reversed operands; same-type relational operators now use this runtime path. See
`docs/i386-soft-f64.md`.
Next, complete the software F64 runtime and compiler lowering, migrate full public
task/CPU records and task semantics, bring up
the production entry path, input and full
exception handling, then task/page-pool integration and resident kernel
symbol binding, variadic calls, address-bearing initializers, and exception-safe
runtime interfaces before attempting a full kernel link. Runner success remains an
intermediate milestone, not the final OS.

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
