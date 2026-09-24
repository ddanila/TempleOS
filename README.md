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

## 32-bit port development

The native 386+/VGA port is underway; the normal launcher still runs x86-64.
See [the architecture plan](PLAN.md), [working i386 ABI](docs/i386-abi.md),
[QEMU support matrix](docs/i386-support-matrix.md),
[implementation progress](docs/port-progress.md) and
[bootstrap module format](docs/i386-modules.md).

Build and boot-check the standalone native kernel foundation with:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --test
qemu-system-i386 -machine pc -accel tcg -cpu 486 -m 8 -nic none \
  -drive file=build/i386-kernel/kernel.img,format=raw,if=ide
```

For an already built image, make a separate preview copy so another build does
not replace the file used by your VM:

```sh
cp build/i386-kernel/kernel.img build/TempleOS-i386-preview.img
qemu-system-i386 -machine pc -accel tcg -cpu 486 -m 8 -nic none -snapshot \
  -drive file=build/TempleOS-i386-preview.img,format=raw,if=ide
```

The current image boots to the interactive environment in about 45 seconds on
the development machine (QEMU/486, 8 MiB); diagnostic boot takes several minutes.
Its native file workflow includes `Dir`, `EdDir`, `FileRename`, `FileMove`,
`FileDel` and empty-directory `DirDel`; cross-directory moves currently support
regular files on one volume.
The separate
`build/i386-kernel/kernel-diagnostics.img` runs the full boot/worker probe suite;
use that filename in the QEMU command when you want diagnostics. `--test` verifies
both paths automatically. `-snapshot` discards disk changes when QEMU exits;
console definitions also last only for that running session. This is the 32-bit preview; `run-qemu.sh`
continues to launch the existing full x86-64 environment.

This image boots a native VGA HolyC console. At the prompt,
try `6*7;`, `sizeof(U8 *);`, or `1.5+2.25;`. Definitions persist between lines:

```c
I64 n=40;
I64 Next(){return ++n;}
Next;
```

The last command prints `41`. Syntax errors return to the prompt and preserve
previous definitions. Shared public task and CPU headers load before user startup;
`sizeof(CTask);` returns `992`, and `Fs->gs==Gs;` returns `1`. See
[native public headers](docs/i386-public-headers.md) for the implemented scope.
Browse the packaged original help documents with `Help();`, or open a specific
document with `Help("C:/Doc/CompilerOverview.DD");`. Page Up/Page Down and the
Up/Down arrows page through the read-only text projection; Home returns to the
first page. Left/Right selects direct file links, Enter follows the highlighted
link, and Escape returns to the parent document or prompt. Links to published
native symbols, such as the `Dir` link in the command-line overview, open their
packaged source file at the recorded source line. Help-category links open a
live listing of matching help documents and public native symbols registered by
the compiler's `#help_index`/`#help_file` metadata; entries can be selected and
opened like ordinary links. `FF:` links open at
the requested text occurrence, and `FA:` links open at their invisible DolDoc
anchor.
This is an initial console: multiline editing, the complete
language/runtime, DolDoc and native self-hosting remain
unfinished. See [console details](docs/i386-console-runtime.md) and
[kernel image details](docs/i386-kernel.md).

The first native ordinary-text DolDoc session is also available from that
HolyC prompt. The simplest file workflow is:

```c
Dir("C:/Project");
EdDir("C:/Project");
Ed("C:/Project/Main.HC");
```

`Dir` lists entries in their on-disk order and marks directories with `/`; it
accepts absolute or task-relative paths. `EdDir` opens a VGA file picker:
Up/Down changes the selection, Enter descends into a directory or opens a file in
`Ed`, Backspace returns to the parent directory, `N` prompts for a new filename,
`R` renames a file or directory in place, Delete removes a regular file or empty
directory after a visible `Y/N` confirmation, and Escape
returns to the prompt. Entering a new name opens it directly in `Ed`; Escape
there saves it and returns to the refreshed picker. `Ed` also loads or
creates a path supplied directly, while Shift-Escape discards that editing
session. The lower-level document
services remain available:

```c
CDoc *d=DocNew("C:/MyDoc.DD",Fs);
DocEd(d);
DocWrite(d);
DocExe(d);
DocDel(d);
d=DocRead("C:/MyDoc.DD");
DocEd(d);
DocExe(d);
DirMk("C:/Project");
DirMk("C:/Project/Sub");
d=DocNew("C:/Project/Sub/Main.HC",Fs);
DocEd(d); // F5 saves and executes it.
```

This initial editor accepts printable bytes, Enter/newline, Backspace,
all four arrows, Home/End, Delete and Tab. Shift-Left and Shift-Right select
canonical text, and typing or deletion replaces the selected span. Ctrl-C,
Ctrl-X and Ctrl-V copy, cut and paste that canonical selection. Reversing
Shift-Left/Shift-Right contracts the horizontal selection. Paste constructs a
complete temporary canonical document before publishing any records, so an
allocation failure leaves the destination unchanged. F5 saves and executes
the current document; if saving fails, the result view reports it while still
executing the in-memory source.
Ctrl-Shift-Up and Ctrl-Shift-Down select from the cursor to the start or end of
the document for whole-file clipboard operations.
Shift-Up and Shift-Down select multiline canonical ranges at the current column.
Shift-Page-Up and Shift-Page-Down extend that selection by the 55-line viewport.
Reversing either vertical movement contracts the same canonical range.
Escape returns from the result view, and Ctrl+Alt+C interrupts a running program.
After a compiler error in the current file, Escape returns with the cursor at the
first byte of the reported source line so it can be corrected and rerun directly.
F1 opens the packaged Help Index from inside the editor; Shift-F1 opens About
TempleOS. Escape returns to the same unsaved document and cursor.
F4 opens the file picker in the current document's directory and inserts the
selected absolute filename at the cursor. Shift-F4 inserts a selected directory
name. Either insertion is one undo operation.
Ctrl-F opens the native search prompt. Press Tab after the search text to enter
a replacement and replace the next match; Enter from the search field only
finds it. F3 moves to the next match with wrapping;
Shift-F3 moves to the previous match. Search operates across adjacent canonical
text records without changing the saved document; a miss is reported in the
editor heading.
The normal i386 HolyC scope also exports the original `Snd(ona)` PC-speaker
primitive. `Snd(60)` starts concert A through PIT channel 2; `Snd` or `SndRst`
stops it.
It also exports `MouseGet(&x,&y,&buttons,&packets)` for the installed PS/2
mouse. Coordinates are clamped to the 640×480 VGA surface and the low three
button bits report left, right and middle state. Moving the mouse at the HolyC
prompt displays the XOR pointer; keyboard input hides it until the mouse moves
again, keeping the console backing text clean. A left click in `DocEd` moves
the canonical insertion point to the clicked visible text cell, including in a
scrolled document. Mouse movement displays an XOR arrow without modifying the
canonical text or graphics backing surface, and the editor's block caret shows
the clicked insertion point. Holding the left button while moving selects text;
copy, cut, deletion and typed replacement use the same canonical selection as
Shift+cursor commands. Continuing to drag against the bottom screen edge extends
the selection into the next row, including while the button is held still.
Dragging into the fixed header likewise scrolls upward from the first text row.
Dragging against either
horizontal screen edge pans a long unwrapped line while extending the selection.
The file picker also displays the pointer and selects a visible file or directory
row on left click; Enter or a double-click opens the selected item through its
existing path.
The help viewer displays the pointer as well. Clicking a visible link selects it;
Enter or a double-click follows it, and Escape returns to the parent help document
with the pointer restored.
Ctrl-G prompts for a one-based line number and moves to that line's first
editable byte; an out-of-range request leaves the cursor in place and reports it.
Alt-Backspace walks back through sixteen native editor undo points, including
their canonical cursors and embedded document records. Consecutive typing,
Backspace or Delete keystrokes within one second form one undo point; changing
operation, moving the cursor or pausing starts another.
Ctrl-S saves without exiting or executing and reports `Saved` or `Save failed` in the editor
heading; another edit clears that status.
The document body has a 56-row viewport below the fixed heading. It follows the
cursor through files longer than one VGA screen without scrolling the heading
off screen. With word wrap disabled, lines wider than 80 columns pan horizontally
to keep the cursor visible.
The original Ctrl-K, Ctrl-U and Ctrl-Z shortcuts start blinking, underlined and
inverted text; their Shift-Ctrl forms end those styles. Blinking text follows
the native 500 ms clock phase and swaps foreground/background like original
TempleOS. Foreground/background records loaded from a file also render in their
VGA colors.
It uses
the canonical `CDoc` model and persistent RedSea files; full DolDoc commands,
layout, broader mouse activation and the original `ExeDoc` integration remain in progress.
To keep saved files across QEMU exits, omit `-snapshot` when running your separate
preview copy. `DocExe` executes the current document through the retained live
compiler, suppresses its cursor marker, and retains successful definitions. The
original editor action graph is still open; F5 is the retained native binding for
the current integration stage.

For selectable console test groups and checks that deliberate faults are detected,
see the [TDD test workflow](docs/i386-test-workflow.md).

Run isolated bootstrap/backend checks with:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py
python3 tools/test-i386.py --functions
python3 tools/test-i386.py --data
python3 tools/test-i386.py --vga
python3 tools/test-i386.py --heap
python3 tools/test-i386.py --memory
python3 tools/test-i386.py --a20
python3 tools/test-i386.py --irq
python3 tools/test-i386.py --tasks
python3 tools/test-i386-module-check.py
python3 tools/test-i386-loader.py
```

These tests compile HolyC inside a temporary TempleOS VM. The i386 test executes
generated integer code in a protected-mode runner using QEMU's 486 model; it
does not yet boot a complete 32-bit TempleOS system or prove real-386 support.

The VGA test additionally requires Pillow and checks every pixel of a 640×480
screenshot after native palette programming and planar framebuffer uploads.
