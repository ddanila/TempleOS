# Standalone native kernel foundation

`Kernel/I386/Kernel.HC` now supplies a native kernel entry independent of the
arithmetic/task test runner. `tools/build-i386-kernel.py` cross-compiles it inside
the rebuilt x86-64 TempleOS guest, links six native modules, audits generated
executable regions and packages a bootable hard-disk image.

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
also used by the existing test fixtures. It reads a reserved 160 KiB stage at
0x10000, gathers conventional/legacy extended-memory information, sets VGA mode
0x12 and enters flat 32-bit protected mode. The new kernel stage establishes its
stack at 0x90000, installs an emergency IDT, sets CR0.EM and calls the linked entry
with the handoff pointer at 0x5000. It supplies no runtime function pointers.

Native startup validates the handoff, verifies/enables A20 using the legacy
controller path, and selects an arena while reserving the boot/stage/stack and
firmware areas. The observed 8 MiB QEMU profile selects base 0x110000 and size
0x6D0000. The kernel initializes its own heap, root stack/task/CPU state, GDT,
exception services, IDT, timer and sleep queue. This retains the current legacy
contiguous-memory and scratch-address assumptions; strict vintage BIOS/386
validation remains required.

## Current runtime behavior

The kernel allocates a 153600-byte logical planar framebuffer and presents sixteen
vertical color bars at 640×480. A heap-owned task sleeps for 25 serviced ticks at
a time while root idles and timer IRQs make it runnable. Startup diagnostics report
the memory arena and first two wakeups on port 0xE9. After reporting startup done,
the kernel continues running; the optional boot test stops its own QEMU process
after collecting evidence. Exception/fault diagnostics currently halt on fatal
conditions and are not the final debugger interface.

The boot test verifies the extended arena bounds, readiness, two correctly delayed
wakeups and every VGA pixel. The current linked image is 125672 bytes. The combined
task/exception/sleep regression passes through the shared BIOS path, and both
x86-64 compiler/kernel rebuild/reboot generations pass. Tests use QEMU's 486 model
with 8 MiB; generated-code auditing and CR0.EM are not proof of strict 386 support.

This is the first standalone native kernel foundation, not a complete TempleOS
port. It has no HolyC shell/JIT, DolDoc startup, disk-backed RedSea startup, full
public CTask/CPU integration, keyboard/mouse UI, speaker integration or native
self-hosted compiler. The image currently contains only boot stages and the kernel;
it is not a formatted or installed RedSea distribution. The 8 MiB interactive and
16 MiB self-hosting goals remain unproven. The full scope in PLAN.md is unchanged.
