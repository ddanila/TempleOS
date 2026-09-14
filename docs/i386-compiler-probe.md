# Compiler diagnostics outside the bootstrap stage

`CompilerProbe.t32m` contains the compiler token, identifier/string and definition
probes previously compiled directly into Kernel32.BIN. The six bootstrap modules
remain linked into the BIOS-loaded image. The disk now packages ten modules in
all: those six, retained CompilerRuntime and FileRuntime, synchronous Startup and temporary
CompilerProbe. Executable-region instruction audits cover all ten.

The kernel loads CompilerProbe from RedSea before startup while it exclusively
owns boot disk access. The checked loader binds fifteen functions and one writable
data array: KernelLog/Hex/Stop, heap Size/Free/Valid, interrupt Save/Restore, raw
lexer input, owned include attachment, HashAdd, StrCmp, SysTry/SysUntry/throw
and char_bmp_alpha_numeric.
The module uses the actual retained compiler interface for token services and
borrows the kernel's symbol table and I64 type descriptor. It contains the small
shared control/file seed routines; it does not contain a second compiler runtime.

Main receives a version-4, 52-byte CI386CompilerProbe record plus its size. Every
pointer is borrowed only during that synchronous call. The module rejects an
incompatible record before running tests. It registers no persistent callbacks or tasks and
retains no caller pointers. Include callbacks are borrowed only for synchronous
calls into the retained compiler service. Its phase-zero call executes before Startup. Its image
then remains live until the phase-one call from the pulse task after timer/IRQ
activity; both phases now exercise disk reads and nested includes.

After each call, the kernel verifies temporary heap allocations were reclaimed.
After phase one returns, it frees the module image, clears its pointer, checks the
exact byte/allocation decrement and verifies that CompilerRuntime remains a live
allocation. Heap release occurs inside a short interrupt-masked section. The
compiler services and their image remain resident. This is a specific synchronous
module-lifetime contract, not support for unloading arbitrary modules with active
callbacks, tasks or borrowed code pointers.

The host verifier requires all previous token/value/metadata/reclamation records
in both phases. It additionally checks one PROBE MODULE record and one PROBE
RELEASE record, extended-memory placement, exact image/span sizes and ordering
around startup/task activity. CPU-tag, missing-import and interface-version
mutations must reject and reclaim the probe image before diagnostics or startup
execute. Startup rejection matches its exact MODULE record rather than a substring
inside the diagnostic module log.

Run `python3 tools/test-rebuild.py` followed by
`python3 tools/build-i386-kernel.py --test`. The build records the diagnostic
module's hash and temporary lifetime separately from the modules that remain
resident after both probes. The conventional-memory reservation stays 384 KiB.
Moving diagnostics creates code headroom there, at the cost of a temporary
extended-memory allocation through phase one; it is not a claim that peak memory
fell or that the full native compiler fits the eventual memory target.

Verification passes both x64 rebuild/reboot generations and the full native boot
suite. The bootstrap is 364504 bytes, down from 390760, leaving 28712 bytes in the
unchanged reservation. CompilerProbe loads at 0x11D600 with 44208 image bytes and
a 44224-byte heap span, all reclaimed after phase one. CompilerRuntime stays at
126464 image bytes with its 126480-byte retained span. Source checks, all previous
probes, VGA/keyboard/timers and all three probe rejection cases pass. These are
8 MiB QEMU/486 development observations; strict 386 and full workflow memory
validation remain required.

With native keyword initialization, ProbeDefine inherits the real 73-entry registry
through resident symbols instead of constructing a synthetic define keyword. The
probe image at that stage was 43328 bytes with a 43344-byte temporary heap span. Both
phases, reclamation and rejection checks pass with this namespace; see
`docs/i386-keywords.md` for the separate resident registry lifetime.

Conditional preprocessing adds ProbeConditional, which exercises a skipped outer
branch and a selected nested symbol condition through the actual namespace. Both
phases require CONDITIONAL PROBE records and token-text reclamation. At that stage the
diagnostics image was 48232 bytes with a 48248-byte temporary span; its context ABI
remains version 1. See `docs/i386-lex-conditional.md` for the runtime version-9
conditional services and the still-unimplemented expression path.

With compiler service version 10, ProbeIncludes passes a local callback/context
through the retained include-capable entry. Nested children, skipped branches,
missing-provider errors, parent recovery, interrupt state and reclamation are
checked in both phases. The old entry also rejects includes without reusing that
callback. The host requires INCLUDE PROBE records before startup and after ticks;
all callback use ends before probe-module reclamation. At that stage the probe's own version-1
record stayed unchanged; the disk-provider addition below uses version 2.

At compiler service version-10 introduction, the probe image was 59760 bytes with a 59776-byte temporary heap span, all
reclaimed. The compiler runtime retains 138680 heap bytes for its 138664-byte image.
The bootstrap is 384208 bytes with 9008 bytes of headroom. Both x64 generations,
all native boot/value/reclamation/pixel checks, executable instruction audits and
runtime/probe rejection boots pass. Disk-provider packaging/binding and the full
native compiler remain open.

The version-2 probe record adds the kernel's stable disk include service. Boot
now executes plain/compressed nested disk includes through the retained lexer and
file provider, then tests malformed-archive recovery. The task phase explicitly
sets IF for a rejected load and restores the prior flags. The current diagnostic
image is 68256 bytes and reclaims its complete 68272-byte span. The kernel checks
both retained service images after that release. See `i386-file-runtime.md` for
packaging, complete validation and updated boot-stage headroom.

The current version-4 probe also recovers from a malformed include through the
resident exception runtime. It preserves an enclosing active control, explicitly
unwinds the failed child in a native catch, then tokenizes fresh input in the same
task. Boot and worker phases check IF, exception-record removal and exact temporary
heap reclamation; the host requires both `COMPILER RECOVERY` records. See
[i386-compiler-unwind.md](i386-compiler-unwind.md) for scope and remaining parser/JIT
work. The probe currently uses 85608 image bytes and a reclaimed 85624-byte heap
span; current image measurements are in [i386-file-runtime.md](i386-file-runtime.md).

The recovery probe now attaches temporary intermediate-code nodes and a label to
the failed child, then verifies their reclamation along with the input/control.
Retry allocates and explicitly discards a new instruction through retained
services. See [i386-code-context.md](i386-code-context.md).
