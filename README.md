# TempleOS for older PCs

This fork brings TempleOS to older PC-compatible machines: **32-bit 386-class
and later CPUs, VGA, and legacy PC devices**. The aim is a standalone HolyC
workstation that can edit, compile and rebuild itself on a small machine while
preserving what makes TempleOS distinctive.

HolyC remains the system language and interactive shell. DolDoc remains the
executable document and development interface. The port keeps one privileged
address space, cooperative tasks, direct hardware access, RedSea storage,
software graphics and PC-speaker sound.

**The port is under development and verified in QEMU. Physical vintage-PC
compatibility is a target, not a verified claim.** See the [architecture
plan](PLAN.md) and [QEMU support matrix](docs/i386-support-matrix.md).

## Hardware target

| Component | Target |
| --- | --- |
| CPU | 32-bit 80386 instruction baseline and later compatible CPUs |
| Floating point | Software F64; no 387 or other FPU required |
| Memory | 8 MiB for interactive use; 16 MiB for native system rebuilds |
| Boot and storage | Legacy BIOS, IDE/ATA disk, RedSea filesystem |
| Display | VGA, 640×480 with 16 colors |
| Input and sound | AT keyboard, PS/2 mouse, PC speaker |

Current acceptance uses QEMU's `486,-fpu` and later 32-bit CPU profiles,
plus instruction audits for the 386 baseline. These checks do not certify a
physical 386 motherboard or its timing. This is a 32-bit project; 8086/286,
UEFI, networking, and broad modern-device support are outside the current scope.

## Current progress

The native i386 system boots into a VGA HolyC environment with editing, help,
source-linked diagnostics, software floating point, mouse input, graphics,
sound primitives and persistent DolDoc files.

- Two guest-built generations reproduce all twelve kernel/compiler/runtime
  modules, the flat image and installed boot area byte for byte.
- Automated QEMU tests cover editing and execution, error and interruption
  recovery, save/reboot/reopen, memory reclamation, and interrupted installation.
- Both generations pass the complete workstation tests at 8 MiB under no-FPU
  486 and later 32-bit CPU profiles. The six retained modules also rebuild in
  the guest under no-FPU emulation at 16 MiB.
- Original x86-64 TempleOS and the port exchange tested DolDoc files, including
  a styled document edited by the original system and reopened by the port.

This does not establish complete original application or API compatibility.
M7 release qualification remains open: required coverage needs a consolidated
review, no-FPU startup currently takes about 73–74 seconds on the recorded host
against a 60-second target, and audio-output verification and release publication
remain planned work. Functional acceptance is automated; human exploration is
optional feedback, not a requirement to repeat passing tests.

The [M7 evidence map](docs/i386-m7-acceptance.md) records the exact candidates,
results and limitations. The [progress log](docs/port-progress.md) contains the
implementation history.

## Build and try the 32-bit port

The development workflow uses Linux, Python 3, NASM and QEMU. On Ubuntu/Debian,
the relevant packages are `python3`, `python3-pil`, `nasm`, `qemu-system-x86`,
`qemu-utils` and `qemu-system-gui`.

From the repository root:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
```

The bootstrap compiles HolyC inside a TempleOS VM; this is not a conventional
GCC or Clang build. The full build and tests can take considerable time under
software emulation. For the guest-native rebuild and installation workflow,
see [the test and development guide](docs/i386-test-workflow.md).

After building, make a writable working copy and boot it:

```sh
cp build/i386-kernel/kernel.img build/TempleOS-i386-work.img
qemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu -m 8 -nic none \
  -drive file=build/TempleOS-i386-work.img,format=raw,if=ide
```

Keep that working copy to preserve saved files; do not overwrite it when
rebuilding. The normal image boots to the interactive environment without the
diagnostic suite. `build/i386-kernel/kernel-diagnostics.img` is the separate
diagnostic image. Generated images and test results live in the ignored
`build/` directory and are not included in a fresh checkout.

At the HolyC prompt, try:

```c
6*7;
1.5+2.25;
Help();
```

To create a source file:

```c
DirMk("C:/Project");
Ed("C:/Project/Main.HC");
```

In the editor, **F5** saves and executes the document, **Ctrl+S** saves,
**F1** opens help, and **Escape** returns. **Ctrl+Alt+C** interrupts a running
program. **Ctrl+Alt+G** releases QEMU's input grab. Saved files persist on the
working disk; live console definitions last for the current session.

For host-to-guest pasting, the [development guide](docs/i386-test-workflow.md)
describes `tools/qemu-paste.py`, which types text through QEMU's emulated
keyboard without requiring a guest clipboard service.

## Original x86-64 environment

The original x86-64 system remains available for bootstrapping and regression
comparisons. **`run-qemu.sh` launches that environment, not the 32-bit port:**

```sh
./run-qemu.sh
```

It packages this checkout into a live CD and boots QEMU with 1 GiB RAM and two
CPUs. Choose **n** at “Install onto hard drive” to try the live CD. A persistent,
initially blank disk is created at `build/TempleOS.qcow2`; after installing in
the guest, use `./run-qemu.sh -boot order=c` to boot it. Live-CD edits do not persist.

## Development and provenance

Development stays on `main` in [ddanila/TempleOS](https://github.com/ddanila/TempleOS).
The original snapshot remains in Git history. TempleOS was created by Terry A.
Davis; this fork builds on the snapshot preserved by
[cia-foundation/TempleOS](https://github.com/cia-foundation/TempleOS).
Restored archive data is documented in [binary repair provenance](docs/binary-repairs.md).

Useful references:

- [Architecture plan and next release goal](PLAN.md)
- [Automated tests and development workflow](docs/i386-test-workflow.md)
- [i386 ABI](docs/i386-abi.md) and [module format](docs/i386-modules.md)
- [Native console](docs/i386-console-runtime.md) and [kernel image](docs/i386-kernel.md)
- [QEMU support matrix](docs/i386-support-matrix.md) and [M7 acceptance](docs/i386-m7-acceptance.md)
