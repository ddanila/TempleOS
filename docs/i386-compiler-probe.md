# Compiler diagnostics outside the bootstrap stage

`CompilerProbe.t32m` contains the compiler token, identifier/string and definition
probes previously compiled directly into Kernel32.BIN. The six bootstrap modules
remain linked into the BIOS-loaded image. The disk now packages nine modules in
all: those six, the retained CompilerRuntime, synchronous Startup and temporary
CompilerProbe. Executable-region instruction audits cover all nine.

The kernel loads CompilerProbe from RedSea before startup while it exclusively
owns boot disk access. The checked loader binds twelve functions and one writable
data array: KernelLog/Hex/Stop, heap Size/Free/Valid, interrupt Save/Restore, raw
lexer input, owned include attachment, HashAdd, StrCmp and char_bmp_alpha_numeric.
The module uses the actual retained compiler interface for token services and
borrows the kernel's symbol table and I64 type descriptor. It contains the small
shared control/file seed routines; it does not contain a second compiler runtime.

Main receives a version-1, 44-byte CI386CompilerProbe record plus its size. Every
pointer is borrowed only during that synchronous call. The module rejects an
incompatible record before running tests. It registers no callbacks or tasks and
retains no caller pointers. Its phase-zero call executes before Startup. Its image
then remains live until the phase-one call from the pulse task after timer/IRQ
activity; that call performs no disk I/O.

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
current probe image is 43328 bytes with a 43344-byte temporary heap span. Both
phases, reclamation and rejection checks pass with this namespace; see
`docs/i386-keywords.md` for the separate resident registry lifetime.
