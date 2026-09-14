# Standalone native kernel foundation

`Kernel/I386/Kernel.HC` now supplies a native kernel entry independent of the
arithmetic/task test runner. `tools/build-i386-kernel.py` cross-compiles it inside
the rebuilt x86-64 TempleOS guest, links six native modules, audits generated
executable regions and packages a bootable hard-disk image. A seventh module,
`Startup`, is packaged separately and loaded from RedSea during native startup.

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

## Entry and memory ownership

`tools/i386-bios.inc` is the shared BIOS CHS loader and fixed-width memory handoff,
also used by the existing test fixtures. It reads a reserved 384 KiB stage at
0x10000, gathers conventional/legacy extended-memory information, sets VGA mode
0x12 and enters flat 32-bit protected mode. The new kernel stage establishes its
stack at 0x90000, installs an emergency IDT, sets CR0.EM and calls the linked entry
with the memory handoff pointer at 0x5000. A separate version-1 disk handoff at
0x5020 records the BIOS drive and RedSea volume start. It supplies no runtime
function pointers. The kernel stage ends at 0x70000, below the root stack. Test
stages retain their separate 160 KiB limit.

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
640×480 using the existing TempleOS 8×8 font. A heap-owned task sleeps for 25 serviced ticks at
a time while root idles and timer IRQs make it runnable. Startup diagnostics report
the memory arena and first two wakeups on port 0xE9. After reporting startup done,
the kernel continues running; the optional boot test stops its own QEMU process
after collecting evidence. Exception/fault diagnostics currently halt on fatal
conditions and are not the final debugger interface.

The boot test verifies the extended arena bounds, RedSea mount and streamed source
checksum, disk-module execution and reclamation, unchanged disk contents,
readiness, two correctly delayed wakeups and every VGA pixel. A separate interactive
boot checks emulated keyboard input, editing and scrolling against rendered pixels.
The builder records
the linked image size in its manifest. The combined
task/exception/sleep regression passes through the shared BIOS path, and both
x86-64 compiler/kernel rebuild/reboot generations pass. Tests use QEMU's 486 model
with 8 MiB; generated-code auditing and CR0.EM are not proof of strict 386 support.

This is the first standalone native kernel foundation, not a complete TempleOS
port. It has no HolyC shell/JIT, DolDoc startup, startup-source execution, full
public CTask/CPU integration, mouse UI, speaker integration or native
self-hosted compiler. The image now includes a formatted RedSea source/module volume, but it is not
a complete installed TempleOS distribution. The 8 MiB interactive and
16 MiB self-hosting goals remain unproven. The full scope in PLAN.md is unchanged.


## RedSea startup volume

The builder places a volume at sector 2048 of the 16 MiB image, after the reserved
boot area. It packages Kernel/Compiler HC, HH, DD and PRJ files without modifying
their bytes, and the seven native modules under `Modules/I386`. The manifest
records the verified file count. It initializes directory self/parent records, termination,
fixed-width extents/dates, and allocation bits including reserved/out-of-volume
bits. An independent serialized-volume walk checks every file hash, directory
extent and ownership bit before boot. Deliberate header, directory-size, file-byte
and bitmap corruption were all rejected by this verifier.

`BootDisk.HH` defines the separate 16-byte disk handoff (magic, version, BIOS drive,
volume start). Startup currently requires BIOS drive 0x80 to map to primary IDE
master; it rejects other BIOS drive numbers and does not discover arbitrary BIOS
to-controller mappings. Native ATA PIO identifies that disk, mounts RedSea and
walks `Kernel/I386/Kernel.HC`. A 256-byte buffer streams the complete source while
computing an FNV-32 checksum, compared with the packaged source by the boot test.
All disk access occurs during controlled startup with IF clear. There is no full
public CDrv/CFile interface, runtime filesystem concurrency or source execution yet.

The memory-handoff regression checks the disk sidecar too, including the absence
of a volume in ordinary test images. The existing RedSea reader suite and both
x86-64 rebuild/reboot generations pass. The legacy memory/A20 and strict-386
limitations above continue to apply.

## Disk-loaded startup and resident bindings

After installing task/exception/interrupt/timer services, the kernel loads
`Modules/I386/Startup.t32m` through `I386RedSeaLoadBound`. Its explicit binding
table exposes `KernelLog`, `KernelDisplay` and `kernel_startup_count`. The module
initializes the display through the resident service, increments that resident
counter, logs its execution and returns the count. It is absent from the six-module
resident link; source and module hashes are recorded separately by the builder.

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
on the current build. This executes cross-compiled native code from disk; it does
not yet compile source on the target or provide the native shell/JIT.

## Native keyboard console

The kernel initializes the existing keyboard controller/scan-set path while IRQ1
is masked, then unmasks IRQ0/1. IRQ1 reads and publishes raw bytes to the existing
bounded input queue and wakes the reader without switching inside the interrupt.
A dedicated heap-owned task blocks in `I386KeyboardRead`, decodes key-down events,
and owns the console buffer and VGA presentation. Queue discontinuity resets the
partial line and decoder rather than submitting ambiguous input. The auxiliary
port remains disabled by the current keyboard setup; mouse support is pending.

`Text.HH/HC` provides an allocation-free 80×60 renderer over the existing four
planar buffers. It uses the original `Kernel/FontStd.HC` bytes, supports all 256
glyphs at cell-rendering level, and implements newline, carriage return, tabs,
backspace, wrapping and scrolling. A caller must exclusively own the initialized
record, live font and framebuffer; presentation remains a separate operation.
The console currently uploads the full framebuffer after key-down events, so
vintage-CPU presentation cost remains to be measured and reduced.

The input task collects at most 255 bytes plus a terminator. Backspace cannot
erase the prompt; Ctrl-C cancels the partial line. Tabs add spaces at eight-column
stops relative to the input line. Extra characters at the limit are ignored until
space is freed or the line is submitted. Enter reports the line on debug port E9
and starts another line. This is keyboard line collection, not command execution;
the compiler/JIT and DolDoc remain required integration work.

`tools/i386-kernel-input.py` boots the real disk image and sends QMP keyboard
events. It checks Shift, release handling, cancellation, tab expansion and
backspace across a wrap boundary, then submits sixty empty lines to exercise
scrolling. An independent renderer reads the original font and compares every
VGA pixel at each checkpoint. The test runs under the builder's `--test` option,
records its commands/logs/screens under `build/i386-kernel/input`, and confirms
that the original disk remains unchanged. The existing blocking-input component
regression and both x86-64 rebuild/reboot generations also pass.

## Resident export index

The kernel now stores its loader exports in a private table using the shared
`CHash` prefix. The owner record and buckets are allocated from the kernel heap
through `I386HashTableNew`; the resident entry records have separate lifetime.
Startup resolves the required names through native `HashFind` and
converts the selected records to the existing checked loader's binding format.
`HashStr`, insertion and lookup operate without allocation, with 64-bit hash
values and target-width bucket pointers. These records describe loader addresses
and kinds; they are not compiler function/class metadata. See `i386-hash.md` for
the public primitives, record layouts, ownership rules and compatibility tests.
