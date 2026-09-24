# Focused tests and mutation checks

Build a current image with `python3 tools/build-i386-kernel.py` (run
`python3 tools/test-rebuild.py` first when Kernel/Compiler sources changed).
The input harness tests the supplied image; it does not rebuild it. Keep the
source checkout and image together, especially the font and frame expectations.
Do not replace the image during a run.

```sh
python3 tools/i386-kernel-input.py --list-groups
python3 tools/i386-kernel-input.py --group windows
python3 tools/i386-kernel-input.py --group mouse
python3 tools/i386-kernel-input.py --group sound
python3 tools/i386-kernel-input.py --group document-editing
python3 tools/i386-kernel-input.py --group documents --group text --out build/doc-tests
python3 tools/i386-kernel-input.py  # complete console suite
python3 tools/i386-kernel-input.py --cpu 486,-fpu --group keyboard \
  --out build/i386-486-no-fpu
python3 tools/test-i386-mutations.py
python3 tools/test-i386-mutations.py --mutation control-hit-test
python3 tools/test-i386-test-runner.py  # host verdict checks, no QEMU
python3 tools/test-i386-doldoc-session.py  # writable three-boot acceptance
```

`--cpu` selects the QEMU CPU model and is recorded verbatim in `result.json`.
`i386-kernel-input.py` defaults to `486`; the writable three-boot runner defaults
to `486,-fpu`. The local QEMU has no 386 model, so `486,-fpu`
checks the no-coprocessor runtime contract but does not establish 386 ISA
compatibility. Use the separate instruction audit and a true 386-capable
emulator or physical machine for that promotion gate.

The `mouse` group checks raw PS/2 movement and button packets and the exact XOR
pointer over the idle HolyC prompt, then drives two real `DocEd` sessions. It
verifies the exact VGA caret and serialized canonical
cursor after clicking within an ordinary line and through a vertically scrolled
viewport, and inserts text at the clicked position. Exact pixel checks also
cover the XOR arrow before the click and verify that moving it does not leave the
old cursor pixels behind. Forward and reverse drag cases verify selected-entry
attributes, moving-endpoint caret placement, typed replacement and exact saved
cursor bytes. A long-document case holds the pointer at the clamped bottom edge,
sends another downward packet, and checks a second viewport advance, the exact
selected VGA cells and the canonical endpoint bytes. It then drags back to the
first text row and into the fixed header, checking two upward advances, the
selected VGA frame and the canonical bytes at the start of the document.
Another case holds the button at the bottom edge without further mouse packets,
checks the timer-driven viewport advance and saved cursor, and verifies that
releasing the button stops the repeat.
The group also drags across both horizontal edges of a 100-column unwrapped
line, comparing exact VGA selection frames and saved cursor positions after
repeated edge packets.
The group also creates a two-file RedSea directory, selects the second row with
the mouse, opens it by double-click through public `EdDir`, verifies the selected file in
`DocEd`, and checks pointer restoration when returning to the picker. It then
clicks the first visible link in the packaged compiler overview, verifies the
selected link and XOR pointer, opens the assembler help file by double-click, and
checks pointer and selection restoration after returning to the parent.

The `document-editing` group includes a hardware Ctrl-Alt-C exit from `DocEd`.
It checks restoration of the console surface and task document pointers, lock
and pending-break cleanup, and continued compiler use after the exception.
It also writes and reopens a canonical sprite-linked `CDocBin` payload through
RedSea, checking its exact fixed-width trailer, arbitrary data bytes and restored
entry linkage.

## Manual long-document acceptance

Build the normal image, copy it, and boot the copy without `-snapshot`:

```sh
cp build/i386-kernel/kernel.img build/i386-manual.img
qemu-system-i386 -machine pc -accel tcg -cpu 486 -m 8 -nic none \
  -drive file=build/i386-manual.img,format=raw,if=ide
```

At the HolyC prompt, create a document longer than the 56-row editor body and
open it:

```c
CDoc *d=DocNew("C:/ManualLong.HC",Fs);I64 i;
for(i=0;i<65;i++){DocPutKey(d,'0'+i/10);DocPutKey(d,'0'+i%10);DocPutKey(d,10);}
DocEd(d);
```

Check that the four heading rows remain fixed while Up/Down moves through the
numbered lines, Home/End pans a line wider than 80 columns, and typed text
appears promptly. Press Ctrl-S and require the `Saved` heading. Add a final line
containing `6*7;`, press F5, require `42`, then Escape back to the same document.
Exit the editor, run `DocDel(d);`, close QEMU, boot the same image again, and run
`Ed("C:/ManualLong.HC");`. Require the saved edit and final program line to be
present. Record QEMU version, host, observed boot time, and any display/input
differences. This is the human usability check; the `document-latency` and
writable-session tests provide repeatable hardware-input and exact-pixel gates.

The default disk is `build/i386-kernel/kernel.img`. An optional positional disk
path overrides it. Groups run in suite order, sharing one normal boot; omitted
groups do not run their setup commands. Available groups are keyboard, mouse, windows,
graphics, sound, date, math, definitions, text-frames, compiler, breaks, documents,
document-editing, document-resources, document-latency, and text. These select
existing assertions, including hardware input and exact VGA
pixels, rather than a separate abbreviated implementation of the checks.
Normal startup validation still runs for every selection. Focused results report
only selected groups and actual submitted command counts. The complete build
validation remains `python3 tools/build-i386-kernel.py --test`, including diagnostic
boot, original-target comparisons, and module rejection checks.

Mutation checks first require a passing unmodified windows group. Each mutation
then boots a fresh QEMU process and overwrites one real public function's entry
in guest RAM: `CtrlInside` always returns false, or `WinHorz` returns false without
resizing. The replacement preserves the native three-argument calling convention.
The unchanged WindowServiceCheck assertion expects 14; these faults produce -4
and -14 respectively. Only the exact faulty VGA answer at that checkpoint counts
as detection. A passing assertion is a survivor; a crash, timeout, installation
failure, or different failure is inconclusive. Both cause a nonzero runner exit.
These are representative faults, not a coverage percentage or proof that all
possible regressions are detectable. They do not validate strict 386 hardware.

All input-harness runs use QEMU disk snapshots. Mutations change neither source
files nor stored images and disappear when QEMU exits. The mutation report also
checks the original disk hash after testing. Do not use this harness to establish
persistence across reboot; that requires a separate writable-disk test.

`test-i386-doldoc-session.py` is that separate writable-disk test. It defaults
to QEMU `486,-fpu` for all three boots and accepts `--cpu` to override the
profile. It copies the built image, creates a canonical document, enters
`DocEd`, and sends QEMU keyboard events for typing, Enter, Backspace, all four
arrows, Home/End, Delete and Tab. It checks VGA text/cursor pixels,
opens packaged help with F1, returns to the same editor frame, executes the
program with F5, and writes to RedSea. A second boot verifies the
reopened editor and serialized bytes, changes the saved HolyC program with real
keys, and uses F5 to replace it. A third boot verifies the revised source and
executes its new result. It fails if the
source image changes. This acceptance now passes for the ordinary-text subset;
full original editor integration remains open. The acceptance also creates a
second root file, forcing a full one-sector root directory to grow, plus a third
tab-bearing file, a three-line vertical-navigation file, and an empty-line
Delete/Backspace fixture, and checks all five after reboot.

Results, logs, the last submitted checkpoint, and VGA screenshots are retained in
`build/i386-focused` or `build/i386-mutations` (override with `--out`). Mutation
reports include detected/survived/inconclusive verdicts and baseline evidence.
Use a new output directory when preserving earlier screenshots; result.json is
removed before each run so an interrupted run cannot leave an old passing verdict.
For TDD, add an acceptance assertion, observe the intended failure, implement the
port behavior, and run the selected group followed by complete build validation.

The focused `document-compatibility` group opens `C:/Probe/OriginalCompat.DD`,
which is generated by the original x86-64 `DocSave` during the cross-build rather
than synthesized by the host. Native `DocRead` loads its text, sprite reference
and binary trailer, and native `DocSave` must reproduce the exact 48-byte layout.
Run it with:

```sh
python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img \
  --out build/i386-cross-doc --group document-compatibility
```

Run the reverse native-to-original proof with:

```sh
python3 tools/test-i386-doc-compat.py
```

It copies the native disk, persists `BinaryRecord.DD` through native `DocWrite`,
extracts it with an independent RedSea walk, boots original x86-64 TempleOS with
the exact file, and requires original `DocRead`/`DocSave` to reproduce all 37
bytes. The complete `build-i386-kernel.py --test` promotion gate invokes this
test automatically.

The complete gate also uses fresh writable images to interrupt all seven raw
sector writes and six flushes in the journaled cross-directory move fixture. Each image
then boots through mount-time bitmap reconstruction and is independently walked
for directory validity, exact reachable allocation bits and complete `IO` file
contents. Every case requires exactly one surviving name: failures before a
durable source tombstone recover the source, while later failures recover the
destination.

The complete gate also interrupts all four writes and three flushes in regular
file replacement. Independent post-reboot parsing requires one live fixture
containing exactly `OLD` or `NEW`, an all-zero move-intent area and allocation
bits matching every reachable extent.

The focused `help` group opens the packaged original
`C:/Doc/CompilerOverview.DD` through public `Help`, verifies the projected titles
and link labels against exact VGA pixels, selects and follows the assembler file
link, resolves the `Dir` man-page link through the live native symbol table into
its packaged public header at the exact recorded declaration line, resolves the
circular-queue `HI:` category through live help-file metadata, verifies its
generated listing, selects the registered queue document, returns through both
parent levels, and follows an `FF:` link to the requested second text
occurrence plus an `FA:` link to an invisible DolDoc anchor. It exits with Escape
and requires the task heap to return to its pre-viewer usage. Run it with:

```sh
python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img \
  --out build/i386-help --group help
```

The `document-editing` group also invokes retained `DocAllocationCheck`. It
injects exact `OutMem` failures into document construction, first-entry creation,
text replacement, newline creation, serialization and disk-backed loading, then
checks heap balance, lock release, unchanged document state and successful edit,
save and reopen recovery. This diagnostic
is a prompt command in the focused/full harness; normal boot does not run it.
The focused evidence for this slice is
`build/i386-doc-read-allocation-3/result.json` (66 commands, QEMU/486, 8 MiB,
43.320-second startup, disk SHA-256
`726d5f35f8b1c68addfae36c62a8e47ca451460e7d90d760883eab7277ebbd51`).
The corresponding full gate is in `build/i386-kernel/result.json`; the normal
disk SHA-256 is
`99a2de8deefafc3bb8d4092cd1a2bd93bc6d9d6c9592624f98f4af6c14f0c765`.
Successful `DocRead` persistence after the cleanup change is independently
covered by `build/i386-doldoc-read-recovery-final/result.json`, whose two boots
measured 42.968 and 43.472 seconds and left the source disk unchanged.

The group now also constructs a canonical multiline HolyC document, invokes
retained `DocExe`, checks its visible `42` result and calls the published
definition again. Evidence is in `build/i386-doc-execute-green-5/result.json`:
75 commands passed on QEMU/486 with 8 MiB, exact VGA checkpoints and a
43.521-second startup. The writable acceptance in
`build/i386-doldoc-execute-session-1/result.json` executes `NativeProgram.HC`,
saves it to RedSea, boots the modified copy and executes it again. Its two boots
measured 43.673 and 43.828 seconds; the source image remained unchanged.

The editor acceptance now uses real F5, Escape and Ctrl+Alt+C input. It checks
the exact VGA result/diagnostic view while correcting a syntax error, recovering
from a thrown runtime exception and interrupting a running marked loop. Evidence
is in `build/i386-doldoc-editor-complete-green-1/result.json`: 46 create/edit/save
commands and 31 reopen commands passed on QEMU/486 with 8 MiB, including an exact
software-F64 `3.75` result; startup measured 44.075 and 46.179 seconds, and the
source image stayed unchanged.

The same acceptance now includes multiline diagnostic navigation. Its cursor
starts on line 3; the compiler rejects line 2, Escape returns to the first byte
of line 2, and hardware Delete/text input repairs the expression before F5
produces `1`, `42` and `3`. The exact diagnostic, cursor and corrected-result VGA
frames are required.

The editor workflow also presses F1 after modifying an unsaved document. It
requires a fresh `HELP VIEW begin`, exits with Escape, requires the matching view
end, and then compares the complete restored editor frame. This covers nested
viewer lifetime plus preservation of the document cursor and pending edits.

The focused `file-navigation` group also opens the project picker with F4 from
`C:/Browse/Main.HC`. It requires the picker to start at `C:/Browse` with the
existing directory and files, exits it, and compares the restored editor frame
and cursor. All earlier picker create, descend, rename, delete and regular-file
move checks run in the same group.

The `document-editing` group types `one two one` through hardware input, opens
Ctrl-F, verifies the prompt while entering `one`, and checks exact editor frames
for the wrapped first hit, F3 next hit and Shift-F3 previous hit. The typed text
occupies adjacent canonical records, so this also guards logical search across
record boundaries.
The sequence then searches for an absent term and requires the unchanged cursor
plus the exact `DolDoc editor - Not found` frame.
It also types a three-line document, verifies the Ctrl-G prompt, moves from line
3 to the first byte of line 2, then requests line 9 and requires the same cursor
with an exact `Line not found` frame.

The latest replacement and save-failure acceptance passes in
`build/i386-doldoc-save-failure-green-1/result.json`. It creates and executes `42`,
reopens the program and changes it to `48`, then reboots and executes the saved
revision as `48`. It also attempts F5 from a missing-parent path, checks the
visible `Save failed` report and `42` execution, and verifies that the document
remains editable. The three QEMU/486 8 MiB startups measured 43.626, 43.672 and
43.621 seconds; all hardware-keyboard and exact VGA checkpoints passed. The
source image stayed unchanged and the writable candidate SHA-256 was
`089c414f0d276239d3de649cd5360f1af6b7ef022d082f41a92eb60780646a94`.

The nested-project extension passes in
`build/i386-doldoc-relative-green-2/result.json`. Public `DirMk` creates
`C:/Project` and `C:/Project/Sub`; F5 saves and executes `Sub/Main.HC` as `49`;
the third boot reopens the same file and executes `49` again. A second program
uses `Project/Sub/Relative.HC`, executes `64`, and reopens and executes `64` after
reboot. The three startups measured 43.824, 43.925 and 43.777 seconds, with 61,
31 and 13 commands and exact VGA checks. An independent disk walk found 17
directories, 717 files and 12442
owned sectors, with no overlap, exact parent links and a bitmap matching all
reachable extents. The source image stayed unchanged and the candidate SHA-256
was `e772adc675204815c7d27d72b4596fc2cb9dc895580e738582190a19dcee7ded`.

## Initial tooling validation

Validated on 2026-09-22 against the existing f723db4 native image (QEMU/486,
8 MiB; disk SHA-256
`b65ec8cf6d916f449fdbcfa2cc12751fb5c8146d36057b151c9a6003bcdbc477`):

- Complete console suite: 221 commands / 284 input lines passed
  (`build/test-groups-full/result.json`).
- Windows alone: seven commands passed; documents plus text: 33 commands passed
  (`build/test-groups-docs/result.json`).
- Both mutations detected at `window-service-check`, with exact -4 and -14
  answers; disk unchanged (`build/i386-mutations-final/result.json`).
- Four host verdict tests passed, covering detection, survival, timeout, and
  baseline failure.

This tooling change reused the built image; it did not rerun the cross-build,
diagnostic boot, or module rejection suite. Those remain separate integration
checks, and the earlier image manifest describes its original build inputs.

## Native implementation wrap-up

The subsequent full native build passed 227 commands / 290 input lines and both
normal and diagnostic boot checks; both original x64 rebuild generations also
passed. Six host tests now cover mutation verdicts and rejection of source-disk
changes during persistence acceptance. See [current progress](port-progress.md)
for measurements and remaining editor/hardware gates.

The five-point round-trip corpus in the cross-build log exercises the shared
loader under original x64 using original `DocSave`. Native persistence is the
separate writable two-boot test, not a claimed native execution of that corpus.

For the focused persisted-graphics loop, run:

```sh
python3 tools/i386-kernel-input.py --group document-sprites \
  build/i386-kernel/kernel.img --out build/i386-kernel/document-sprites
```

This boots the normal image, creates and reopens a sprite document on RedSea,
and compares the complete VGA frame including exact sprite pixels. Keep the
broader `document-editing` and full gates for integration coverage.

For the focused directory-browsing workflow, run:

```sh
python3 tools/i386-kernel-input.py --group file-navigation \
  build/i386-kernel/kernel.img --out build/i386-kernel/file-navigation
```

This creates a nested directory and two source files in snapshot mode, checks
absolute, relative and missing-path `Dir` results against exact VGA output, then
drives `EdDir` with Up, Down, Enter, Backspace and Escape. It verifies descent
into a nested directory, return to the parent, the selected file in `Ed`, and both
return paths with exact VGA frames. It then uses `N` to name a new file, edits and
saves it, checks the refreshed picker selection, and verifies its persisted bytes.
It then selects that file, verifies the Delete `Y/N` confirmation and refreshed
picker frame, and proves the file is absent through both `DocRead` and `FileDel`.
Before deletion it uses `R` to rename the file, checks exact rename-entry and
refreshed VGA frames, verifies the old name is absent and the new name retains
the exact bytes, and rejects a missing source, collision, directory and
cross-directory move.
The same group then renames `Sub/` to `Code/`, enters the renamed directory,
returns to its parent, verifies the old path is absent and lists the intact
`Nested.HC` through the new path.
It finally proves `DirDel` rejects that nonempty directory, creates `Empty/`,
checks the exact `Delete empty Empty/? Y/N` frame, deletes it, checks the refreshed
selection, and verifies repeated absence.

The group then creates `Archive/`, moves `Other.HC` to
`Archive/Moved.HC`, verifies the exact two source bytes at the destination and
absence at the old path, and rejects a missing source, destination collision and
directory source. It moves the file back, verifies `Archive/` contains only its
canonical `.` and `..` entries, and removes the empty directory. This gives the
public `FileMove` contract a bounded feedback loop before the exhaustive gate.

The complete build gate additionally creates a disposable writable image with a
private file-mutation boot flag. Its native worker injects four `FileMove`
transaction failures, verifies source preservation and destination rollback,
then succeeds and cleans up. The host clears the flags, independently audits all
reachable RedSea extents and bitmap bits, and performs a normal read-only reboot
that proves both probe directories and files are absent. The ordinary diagnostic
image remains read-only and must contain no mutation-probe marker.
