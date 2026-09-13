# TempleOS in QEMU

From this directory, run:

```sh
./run-qemu.sh
```

Requirements: `python3`, `nasm`, `qemu-system-x86_64`, and `qemu-img`
(Ubuntu packages: `python3 nasm qemu-system-x86 qemu-utils qemu-system-gui`).
These are installed on the development machine.

The launcher builds `build/TempleOS.iso` from this checkout and opens QEMU with
1 GiB RAM, two CPUs, legacy IDE devices, and software emulation (TCG).
The existing TempleOS kernel and compiler binaries bootstrap the OS; this is
packaging, not a Linux cross-compilation of HolyC. Source edits are included on
the disc; kernel/compiler edits require rebuilding those binaries inside TempleOS.

At **Install onto hard drive**, press **n** to try the live CD. At **Take Tour**,
press **y** for the tour or **n** for the HolyC prompt. Try `6*7;` followed by
Enter; it prints `42`. Press **F1** for help. **Ctrl+Alt+G** releases QEMU's input
grab; close the QEMU window to stop the VM.

The launcher creates a persistent, initially blank 2 GiB virtual disk at
`build/TempleOS.qcow2`. You can choose installation in the guest if you want to
save work. Live-CD changes do not persist. The default launcher always boots the
CD; after installation, use `./run-qemu.sh -boot order=c` to boot the disk.
Only the image files are attached to the VM.

For a remote display, use `./run-qemu.sh -display vnc=127.0.0.1:1` and connect a
VNC viewer to localhost port 5901 (or forward that port over SSH).

## Fork changes

`archive` preserves the original snapshot at `c26482b`. Development is on `main`,
and the only Git remote is the personal fork, `ddanila/TempleOS`.

- `tools/build-iso.py` writes the TempleOS RedSea filesystem and El Torito metadata
  described in `Doc/RedSea.DD` and `Adam/Opt/Boot/DskISORedSea.HC`.
- `tools/boot-dvd.asm` loads the archived kernel and uses the register handoff in
  `Adam/Opt/Boot/BootDVD.HC`. No external ISO is needed to build or run.
- Binary data damaged by the archive's ASCII conversion has been restored;
  see [repair provenance](docs/binary-repairs.md).

Verified on this machine with QEMU 10.2.1/TCG: graphical startup, both terminals,
keyboard input, and HolyC evaluation of `6*7;` returning `42`.

To check image structure and all packaged file contents:

```sh
python3 tools/build-iso.py
python3 tools/verify-iso.py
```
