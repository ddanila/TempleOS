# Standalone native kernel foundation

`Kernel/I386/Kernel.HC` now supplies a native kernel entry independent of the
arithmetic/task test runner. `tools/build-i386-kernel.py` cross-compiles it inside
the rebuilt x86-64 TempleOS guest, links six native modules, audits generated
executable regions and packages a bootable hard-disk image. `CompilerRuntime` and
`Startup` are packaged separately and loaded from RedSea. The former remains in
extended memory; the latter is reclaimed after display initialization.

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
qemu-system-i386 -machine pc -accel tcg -cpu 486 -m 8 -nic none \
  -drive file=build/i386-kernel/kernel.img,format=raw,if=ide
```

The build requires the existing QEMU/NASM/Python tooling; the screenshot check
also uses Pillow. Outputs are under `build/i386-kernel`: `kernel.img`, the linked
`exports/Kernel32.BIN`, exported modules, an instruction listing, build/boot logs,
`boot/screen.png` and `result.json`. The manifest records source/bootstrap hashes,
build input hashes, tool versions, image/module hashes and boot evidence. A dirty
worktree is identified explicitly, so the recorded revision alone is not claimed
to describe such a build.

## Interactive and diagnostic boot

`kernel.img` is the default interactive image. It mounts RedSea, initializes the
retained services and public headers, executes startup source, and opens the
HolyC console. It does not load `CompilerProbe`, execute memory/source self-checks,
or create the temporary diagnostic worker and its private compiler arena.

The build also writes `kernel-diagnostics.img`. It differs from the normal disk
in one byte of the exported `kernel_diagnostics` data word in the flat boot
kernel. The builder validates that symbol against the module's data ranges and
requires the normal image's value to be zero before creating the diagnostic copy.
Both modes use the same executable code, modules and filesystem contents.

`--test` runs the full existing root/worker diagnostic checks on the diagnostic
image. Keyboard/VGA input, startup-source recovery and normal service rejection
checks run on the default image; probe rejection tests use the diagnostic image.
Normal startup rejects any diagnostic execution markers and is also tested with
a deliberately invalid probe module. Both disk hashes and startup timings are
recorded separately. The diagnostic disk is selected by filename; no rebuild or
guest-side prompt is needed to switch modes.

## Entry and memory ownership

`tools/i386-bios.inc` is the shared BIOS CHS loader and fixed-width memory handoff,
also used by the existing test fixtures. It reads a reserved 384 KiB stage at
0x10000, gathers conventional/legacy extended-memory information, sets VGA mode
0x12 and enters flat 32-bit protected mode. The new kernel stage establishes its
stack at 0x90000, installs an emergency IDT, sets CR0.EM and calls the linked entry
with the memory handoff pointer at 0x5000. A separate version-1 disk handoff at
0x5020 records the BIOS drive and RedSea volume start. It supplies no runtime
function pointers. The kernel stage ends at 0x70000, below the root stack. Test
stages retain their own bounds; the numeric-oracle fixture explicitly permits a
256 KiB stage below its heap.

Native startup validates the handoff, verifies/enables A20 using the legacy
controller path, and selects an arena while reserving the boot/stage/stack and
firmware areas. The observed 8 MiB QEMU profile selects base 0x110000 and size
0x6D0000. The kernel initializes its own heap, root stack/task/CPU state, GDT,
exception services, IDT, timer and sleep queue. This retains the current legacy
contiguous-memory and scratch-address assumptions; strict vintage BIOS/386
validation remains required.

## Current runtime behavior

The disk-loaded startup module calls the resident display service, which allocates
a 153600-byte logical planar framebuffer and presents an 80×60 text console at
640×480 using the existing TempleOS 8×8 font. In diagnostic mode, a temporary
heap-owned task sleeps for 25 serviced ticks at a time while root idles and timer
IRQs make it runnable. Diagnostic output reports the memory arena and first two
wakeups on port 0xE9; the task is reaped after its compiler probes. Normal mode
starts the console without that worker. After reporting startup done,
the kernel continues running; the optional boot test stops its own QEMU process
after collecting evidence. Exception/fault diagnostics currently halt on fatal
conditions and are not the final debugger interface.

The boot test verifies the extended arena bounds, RedSea mount, source checksum,
lexical character/line counts and temporary input reclamation, disk-module execution and reclamation, unchanged disk contents,
readiness, two correctly delayed wakeups and every VGA pixel. A separate interactive
boot checks emulated keyboard input, editing and scrolling against rendered pixels.
The builder records
the linked image size in its manifest. The combined
task/exception/sleep regression passes through the shared BIOS path, and both
x86-64 compiler/kernel rebuild/reboot generations pass. Tests use QEMU's 486 model
with 8 MiB; generated-code auditing and CR0.EM are not proof of strict 386 support.

This is the first standalone native kernel foundation, not a complete TempleOS
port. It now has an initial native HolyC console and disk-backed source startup,
but still lacks DolDoc startup, full public CTask/CPU integration, mouse UI,
speaker integration or native
self-hosted compiler. The image now includes a formatted RedSea source/module volume, but it is not
a complete installed TempleOS distribution. The complete 8 MiB interactive environment and
16 MiB self-hosting goals remain unproven. The full scope in PLAN.md is unchanged.


## RedSea startup volume

The builder places a volume at sector 2048 of the 16 MiB image, after the reserved
boot area. It packages Kernel/Compiler HC, HH, DD and PRJ files without modifying
their bytes, and the twelve native modules under `Modules/I386`. The manifest
records the verified file count. It initializes directory self/parent records, termination,
fixed-width extents/dates, and allocation bits including reserved/out-of-volume
bits. An independent serialized-volume walk checks every file hash, directory
extent and ownership bit before boot. Deliberate header, directory-size, file-byte
and bitmap corruption were all rejected by this verifier.

`BootDisk.HH` defines the separate 16-byte disk handoff (magic, version, BIOS drive,
volume start). Startup currently requires BIOS drive 0x80 to map to primary IDE
master; it rejects other BIOS drive numbers and does not discover arbitrary BIOS
to-controller mappings. Native ATA PIO identifies the disk and mounts RedSea in
both modes. Diagnostic boot additionally walks `Kernel/I386/Kernel.HC`. It reads
that source into a checked, terminated heap
buffer and verifies its FNV-32 checksum. A native compiler control and lexical
file then consume the buffer through the raw character reader. The boot test
compares character count, newline count and normalized checksum with the packaged
source, and verifies reclamation of the buffer/control/file allocations. This
loads one source file on demand; the distribution remains on disk.
Mounting and service loading happen with IF clear. The console subsequently
executes startup source with interrupts enabled through the retained file
services. The complete public CDrv/CFile interface remains unfinished.

The memory-handoff regression checks the disk sidecar too, including the absence
of a volume in ordinary test images. The existing RedSea reader suite and both
x86-64 rebuild/reboot generations pass. The legacy memory/A20 and strict-386
limitations above continue to apply.

## Fixed boot-image placement

The BIOS stage starts at `0x10000` and reserves 4096 bytes before the linked kernel
at `0x11000`. The host linker receives that explicit destination. The builder
checks the stage prefix and independently verifies stored-pointer values in the
flat kernel against module records. The kernel's ready-message pointer exercises
this path; the retained console's title pointer exercises relocation into a
runtime-allocated image. Both use version-3 module records while existing
position-independent modules remain version 2. The overall boot reservation
is now 450560 bytes (880 sectors), ending at `0x7E000`, 40 KiB below the
fixed task-stack reservation at `0x88000`.

## Disk-loaded startup and resident bindings

After installing task/exception/interrupt/timer services and loading the retained
compiler runtime, the kernel loads `Modules/I386/Startup.t32m` through `I386RedSeaLoadBound`. Its explicit binding
table exposes `KernelLog`, `KernelDisplay` and `kernel_startup_count`. The module
initializes the display through the resident service, increments that resident
counter, logs its execution and returns the count. It is absent from the six-module
bootstrap link; source and module hashes are recorded separately by the builder.

Startup runs synchronously with IF clear and exclusive heap/disk access. The
kernel checks that loading retains exactly one allocation, invokes the entry,
then frees that image and verifies its allocation/byte accounting. The display
buffer remains owned by resident kernel code. No callback, task entry or pointer
into the startup image may outlive its return; unloading arbitrary modules with
retained references is not supported by this startup contract.

The `MODULE` diagnostic is emitted only after execution and reclamation succeed.
The boot check requires it, the module's own diagnostic and the complete VGA
pixel result. Both resident code and the separate startup payload undergo
instruction audits. Two additional boots use copies of the image with the startup
CPU tag changed or one resident-data import renamed; both must halt before module
execution, with their disks unchanged. These checks run as part of `--test`.
The manifest records the linked kernel size; the startup image reclaims 232 bytes
on the current build. This startup path executes cross-compiled native code from disk. The retained
console separately compiles and executes `/Kernel/I386/StartOS.HC` before its first
prompt, then accepts keyboard source. Source startup runs in the console task,
after worker diagnostics. Failed or missing source returns to the prompt through
the input cleanup path. See [i386-console-runtime.md](i386-console-runtime.md).

## Native keyboard console

The kernel initializes the existing keyboard controller/scan-set path while IRQ1
is masked, then unmasks IRQ0/1. IRQ1 reads and publishes raw bytes to the existing
bounded input queue and wakes the reader without switching inside the interrupt.
A dedicated heap-owned task blocks in `I386KeyboardRead`, decodes key-down events,
and owns the console buffer and VGA presentation. Queue discontinuity resets the
partial line and decoder rather than submitting ambiguous input. The auxiliary
port is now enabled after keyboard setup. IRQ12 feeds a bounded standard
three-byte PS/2 decoder, and normal HolyC can snapshot coordinates and buttons
through `MouseGet`; window-manager/editor cursor routing remains pending.

`Text.HH/HC` provides an allocation-free 80×60 renderer over the existing four
planar buffers. It uses the original `Kernel/FontStd.HC` bytes, supports all 256
glyphs at cell-rendering level, and implements newline, carriage return, tabs,
backspace, wrapping and scrolling. A caller must exclusively own the initialized
record, live font and framebuffer; presentation remains a separate operation.
The console tracks changed text rows and uploads only their scanlines. An ordinary
edit transfers 2560 bytes; initialization and scrolling still transfer the full
153600-byte framebuffer. Clean events do no VGA work. See
[i386-console-runtime.md](i386-console-runtime.md) for ownership and invalidation
contracts. Vintage-CPU latency and full-scroll cost remain to be measured.

The input task collects at most 255 bytes plus a terminator. Backspace cannot
erase the prompt; Ctrl-C cancels the partial line. Tabs add spaces at eight-column
stops relative to the input line. Extra characters at the limit are ignored until
space is freed or the line is submitted. Enter reports the line on debug port E9
and submits it to the retained compiler input service. Results and diagnostics
are rendered before the next prompt; successful definitions survive subsequent
inputs. The console/font/rendering implementation now lives in a retained module.
See [console runtime](i386-console-runtime.md) for task/heap ownership, scalar
formatting, limits and remaining public-API/DolDoc work.

`tools/i386-kernel-input.py` boots the real disk image and sends QMP keyboard
events. It checks Shift, release handling, cancellation, tab expansion and
backspace across a wrap boundary, then submits sixty empty lines to exercise
scrolling, then compiles commands covering persistent state, recovery, target
widths and numerical boundary values. An independent renderer reads the original font and compares every
VGA pixel at each checkpoint. The test runs under the builder's `--test` option,
records its commands/logs/screens under `build/i386-kernel/input`, and confirms
that the original disk remains unchanged. The existing blocking-input component
regression and both x86-64 rebuild/reboot generations also pass.

## Resident export index

The kernel now stores its loader exports in a private table using the shared
`CHashExport` prefix. The owner record and buckets are allocated from the kernel heap
through `I386HashTableNew`; the resident entry records have separate lifetime.
Startup resolves the required names through native `HashFind`, reads their values
with shared `HashVal`, checks U32 address bounds and converts the selected records
to the existing checked loader's binding format.
`HashStr`, insertion and lookup operate without allocation, with 64-bit hash
values and target-width bucket pointers. These records describe loader addresses
and kinds; they are not compiler function/class metadata. See `i386-hash.md` for
the public primitives and ownership rules, and `i386-symbols.md` for shared
compiler record layouts and value compatibility tests.

The export index now chains to an owned built-in type registry. Startup creates
the original 17 internal type names as real five-record class arrays, with native
pointer variants, and preserves the raw-type map's alias ordering. It checks every
name through the parent-table lookup path and checks the Bool/F64 map entries.
The registry remains resident for the kernel's lifetime. Loader export binding
still filters for export symbols and passes the wrong-target/missing-import tests.

The builder requires a `TYPES` marker reporting 17 names and 7,672 bytes of registry
heap use, and records those values in the manifest. The kernel image is now
314504 bytes and passes the full 8 MiB QEMU/486 boot, keyboard/VGA and timer checks.
This is compiler startup groundwork: opcode tables, compiler control records,
native parsing, source execution and the complete public type environment remain.

The kernel image is now 331352 bytes. The lexical-source check consumes 14027
source bytes and 360 newlines and reclaims 14488 heap bytes at this revision.
The builder derives those source-dependent expectations and the allocation
footprint from the packaged source and records them under `lexical_source`.
This validates character consumption, not tokenization or execution of the source.

## Retained compiler runtime

String/number parsing and the software numerical runtime now reside in a disk-loaded
module above 1 MiB. Its versioned interface borrows the loaded image's function
addresses, and the image remains allocated for the kernel lifetime. Its raw-reader
functions and decimal/hex bitmaps are explicit kernel imports. Boot and task-time
calls verify execution after relocation and retention across startup allocations.
Wrong CPU, missing import and wrong interface versions are rejected with heap
reclamation before publication. See [i386-compiler-runtime.md](i386-compiler-runtime.md)
for the interface, measured footprint, tests and remaining compiler integration.

The compiler and file service loaders share `KernelServiceLoad`. It resolves the
module, binds the declared imports, initializes a zeroed stack candidate (at most
128 bytes), checks the service version/size and every function pointer against
the loaded allocation, and only then copies the candidate into the resident
record. Failure reclaims the image and checks the original heap baseline. The
existing wrong-target/import/version boot tests still exercise both services.
The native kernel is now 387,432 bytes; including the 2,160-byte stage overhead
leaves 3,624 bytes in the fixed 384 KiB reservation. Symbol registration uses one
loop with a packed name list and a pointer table. The bootstrap links
`ModuleFileSingle.HC`; the module-set loader remains in the shared
`ModuleFile.HC` and its independent regression tests. This removes unused code
from the bootstrap without changing the loader APIs. Startup binding setup also
no longer writes entries 13/14 beyond its three-entry array.

After boot-time module loading and Startup, FileRuntime version 2 binds the
mounted volume to its retained channel/session implementation. The pulse task
then repeats the nested plain/compressed include and archive-error checks through
that path. The API still requires IF clear on entry, but ATA polling opens IRQ
windows and yields while retaining the complete file-operation lease. See
[i386-redsea-tasks.md](i386-redsea-tasks.md) for ownership and verification limits.
