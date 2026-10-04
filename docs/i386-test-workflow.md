# Focused tests and mutation checks

Functional acceptance uses automated QEMU tests. The manual workflows below
are optional exploratory sessions, not required repetitions of passing tests.
Use them to identify usability problems and convert reproducible failures into
automated regressions. Host audio playback and subjective comfort may still
benefit from human feedback without blocking automated functional acceptance.

See the [current qualification queue](../PLAN.md#next-goal-an-automatically-qualified-m7-release)
for required next work and the focused/integration/release test tiers. The
single-command qualification entry point described there is planned, not yet
implemented. The current packager validates existing evidence; it does not run
the entire qualification pipeline or enforce every performance budget.

For typing pasted text into an interactive QEMU guest, launch QEMU with
`-qmp unix:/tmp/templeos-qmp.sock,server=on,wait=off`, then run:

```sh
python3 tools/qemu-paste.py --socket /tmp/templeos-qmp.sock
```

Paste into the helper window with Ctrl+V and click **Type into QEMU**. This
emulates a US-layout keyboard; it needs no guest clipboard service. Newlines
press Enter (and execute commands at the console); no final Enter is added.
ASCII text, tabs and newlines are supported. `--text '6*7;'` or `--file FILE`
can be used instead of the window. Use the guest's actual QMP socket path.

Build a current image with `python3 tools/build-i386-kernel.py` (run
`python3 tools/test-rebuild.py` first when Kernel/Compiler sources changed).
The input harness tests the supplied image; it does not rebuild it. Keep the
source checkout and image together, especially the font and frame expectations.
Do not replace the image during a run.

The current fully guest-built candidate is
`build/i386-kernel/selfhost-install-capacity-lexfix-kvm/target.img`. Its two
guest-built generations, current-source QEMU profiles and local package are
tracked in [M7 acceptance](i386-m7-acceptance.md). The `*-fixed` paths in the
historical reproduction recipe below refer to an earlier source generation.
To package the current candidate after its required evidence is present, run
`python3 tools/package-i386-current.py`, then
`python3 build/i386-release-current/verify.py`. Human manual observation is
deferred at the user's request.

For an automated persistent-session repeat on the second generation in a
host that blocks QMP Unix sockets, use:

```sh
python3 tools/test-i386-doldoc-session.py \
  build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --cpu 486,-fpu --qmp-stdio \
  --out build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doldoc-repeat-stdio
```

This creates its own writable copy and verifies three boots; it does not run
the deferred human observation session.

To repeat the second-generation interrupted-install cuts under no-FPU TCG
on a host that blocks QMP Unix sockets and QEMU snapshots, use:

```sh
python3 tools/test-i386-guest-install-recovery.py \
  --source build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --reference build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --boot-file /Probe/GuestBoot.bin --accel tcg --cpu 486,-fpu \
  --qmp-stdio --include-committed-cut \
  --out build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/install-recovery-tcg-nofpu-stdio-retry
```

The independent boot uses a writable disk copy so it cannot modify the
reference target and does not need QEMU's host snapshot directory.

To produce the fully guest-built installed image used by the M7 checks, start
from the current cross-built bootstrap disk and run the native build and
installation stages. The retained build runs in a 16 MiB QEMU/KVM guest; the
installation tests cold-boot their results at 8 MiB:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py
python3 tools/test-i386-retained-build.py --out build/i386-kernel/retained-build-fixed
python3 tools/test-i386-retained-install.py \
  --source build/i386-kernel/retained-build-fixed/source.img \
  --out build/i386-kernel/retained-install-fixed
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-kernel/retained-install-fixed/candidate.img \
  --out build/i386-kernel/selfhost-install-fixed
python3 tools/audit-i386-guest-image.py \
  --source build/i386-kernel/selfhost-install-fixed/target.img \
  --installed build/i386-kernel/selfhost-install-fixed/target.img \
  --kernel-module-path /Modules/I386/Kernel.t32m \
  --flat-path /Probe/GuestBoot.bin --guest-compiler-template \
  --out build/i386-kernel/selfhost-install-fixed/instruction-audit
```

`build/i386-kernel/selfhost-install-fixed/target.img` is the independently
booted, fully guest-built image. The QEMU work here is substantial; preserve
each stage's `result.json` and use a fresh output directory for a new run.

Rebuild from that installed image to make Generation 2, then compare both
installed generations. The retained build also requires each new T32M to match
the copy installed on the Generation 1 disk:

```sh
python3 tools/test-i386-retained-build.py \
  --disk build/i386-kernel/selfhost-install-fixed/target.img \
  --compare-installed build/i386-kernel/selfhost-install-fixed/target.img \
  --out build/i386-kernel/retained-build-gen2-fixed
python3 tools/test-i386-retained-install.py \
  --source build/i386-kernel/retained-build-gen2-fixed/source.img \
  --out build/i386-kernel/retained-install-gen2-fixed
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-kernel/retained-install-gen2-fixed/candidate.img \
  --out build/i386-kernel/selfhost-install-gen2-fixed
python3 tools/audit-i386-generations.py \
  --first build/i386-kernel/selfhost-install-fixed/target.img \
  --second build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --out build/i386-kernel/generation-identity-fixed
python3 tools/audit-i386-guest-image.py \
  --source build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --installed build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --kernel-module-path /Modules/I386/Kernel.t32m \
  --flat-path /Probe/GuestBoot.bin --guest-compiler-template \
  --out build/i386-kernel/selfhost-install-gen2-fixed/instruction-audit
```

The complete 8 MiB Generation 2 workstation run uses KVM for development
feedback and records 506 native commands, 569 submitted lines, exact VGA
checkpoints and 20 document resource cycles:

```sh
python3 - <<'PY'
import runpy
from pathlib import Path
runpy.run_path('tools/i386-kernel-input.py')['run_input'](
    Path('build/i386-kernel/selfhost-install-gen2-fixed/target.img'),
    Path('build/i386-kernel/selfhost-install-gen2-fixed/full'),
    accel='kvm', ram_mib=8, startup_timeout=180)
PY
```

After the corresponding `486,-fpu` TCG full suite and three-boot writable
DolDoc run pass on that same disk, prepare a local release candidate with:

```sh
python3 tools/package-i386-release.py --out build/i386-release-candidate
```

The package also requires an original-TempleOS DolDoc reader check on the exact
Generation 2 image. Reproduce it with:

```sh
python3 tools/test-i386-doc-compat.py \
  build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --out build/i386-kernel/selfhost-install-gen2-fixed/doc-compat-provenance-retry
```

The packager verifies the recorded 1,233 source-file hashes in the committed
checkout and all 814 delivered source files on the RedSea disk, the installed
Generation 2 disk and flat-image hashes, the executable-region audit, three
complete workstation verdicts (`486` KVM, `486,-fpu` TCG and `pentium3,-fpu`
TCG), the three writable boot verdicts and both KVM and no-FPU TCG final-image
installation recovery suites, each with two pre-commit cuts and a post-LBA-0
hard stop. It produces a compressed raw IDE
disk, manifest, command records and acceptance evidence. It hashes the source,
both retried targets and the post-LBA-0 target for each profile against the
release image, and checks all 16 recovery QEMU command records for the CPU,
accelerator, RAM size and disk paths. It
also verifies and includes the original-reader document round trip, both QEMU
command records and the identical native/original document bytes. It
requires the no-FPU-built Generation 3 disk to pass its independent 8 MiB
boot, Generation 2 byte-identity comparison, 386 executable audit, complete
workstation suite and three-boot writable DolDoc session. The latter records
a hash-checked post-creation snapshot so the reopen phase can be retried from
the exact persistent state with `--resume-reopen`. It
requires the focused 8 MiB
resource profile from that exact disk. The bundle includes `verify.py`; running
`python3 verify.py` inside it checks every bundled file and the decompressed
disk. A README mutation must fail verification. Human manual observation is optional exploratory feedback; this command does
not publish a release.

The native build/install harnesses accept `--cpu` as well as `--accel`, so the
complete guest build can be exercised without an FPU. For example, to rebuild
all retained modules from the installed Generation 2 disk under 16 MiB TCG and
require each output to match its installed copy:

```sh
python3 tools/test-i386-retained-build.py \
  --disk build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --compare-installed build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --accel tcg --cpu 486,-fpu \
  --out build/i386-kernel/retained-build-gen3-tcg-nofpu
```

On a host that blocks QMP Unix sockets, add `--qmp-stdio` to both
`test-i386-retained-build.py` and `test-i386-selfhost-install.py`. The latter
boots a separate writable copy for its independent post-install check because
QEMU snapshot files may also be blocked. A focused current-source smoke check
for the transport is:

```sh
python3 tools/test-i386-retained-build.py \
  --disk build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --compare-installed build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --accel tcg --cpu 486,-fpu --qmp-stdio --module Startup \
  --out build/i386-kernel/retained-startup-capacity-lexfix-gen2-tcg-nofpu-stdio
```

That focused result matches the installed 407-byte `Startup` module. The
all-six current-source no-FPU guest rebuild also passes after resumed
per-module runs. Its post-write audit is at
`build/i386-kernel/retained-build-capacity-lexfix-gen2-tcg-nofpu-stdio/result.json`;
all six module hashes match the installed Generation 2 disk.

If a long run reaches the host command timeout after earlier modules have
already been written to `source.img`, wait for its QEMU process to exit. Then
use `--resume` with `--module NAME` for the unfinished modules and a measured
`--command-timeout`; this reuses the persisted disk instead of copying the
original input again. Once all six are present, run `--audit-only` on the same
output directory with `--compare-installed` to require byte identity. Never
resume or audit a disk while another QEMU process is writing it.

If the runner itself is terminated, first check whether QEMU still holds the
source image's write lock. A locked image must not be used for a retry, even
when the runner has exited; its guest may still be compiling. The Linux QEMU
helper now asks the kernel to terminate QEMU when its runner dies, so future
interrupted runs release that lock. A prior detached QEMU may still need to
finish or be stopped before the same image can be reused.
The writable runner checks the lock before replacing its prior QEMU log or
result, so a blocked retry preserves the active run's evidence.

`tools/test-i386-selfhost-install.py` also accepts `--command-timeout` in
seconds for the long 16 MiB TCG kernel build; its default remains 2,400
seconds. Set a measured longer limit when the guest is still emitting
functions near that boundary. A timeout is not a guest build failure.

To reproduce the no-FPU Generation 3 gates on the exact Generation 2 disk:

```sh
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --accel tcg --cpu 486,-fpu --command-timeout 7200 \
  --out build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long
python3 tools/audit-i386-generations.py \
  --first build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --second build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/target.img \
  --out build/i386-kernel/generation-identity-gen2-gen3-tcg-nofpu
python3 tools/audit-i386-guest-image.py \
  --source build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/source.img \
  --installed build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/target.img \
  --kernel-module-path /Modules/I386/Kernel.t32m \
  --flat-path /Probe/GuestBoot.bin --guest-compiler-template \
  --out build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/instruction-audit
python3 tools/test-i386-doldoc-session.py \
  build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/target.img \
  --cpu 486,-fpu \
  --out build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/doldoc-tcg-nofpu-final
```

If only the reopen or revised phase fails, add `--resume-reopen` to the last
command. The runner verifies the first-boot result, CPU, source disk and saved
snapshot hash, then restores that snapshot before retrying the reopen boot.

Run the complete workstation suite on that target with:

```sh
python3 - <<'PY'
import runpy
from pathlib import Path
runpy.run_path('tools/i386-kernel-input.py')['run_input'](
    Path('build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/target.img'),
    Path('build/i386-kernel/selfhost-install-gen3-tcg-nofpu-long/full-tcg-nofpu'),
    accel='tcg', cpu='486,-fpu', ram_mib=8, startup_timeout=180)
PY
```

The final installed image also supplies the guest-built boot file needed to
repeat the installation interruption/retry gate on that exact disk:

```sh
python3 tools/test-i386-guest-install-recovery.py \
  --source build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --reference build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --boot-file /Probe/GuestBoot.bin \
  --include-committed-cut \
  --out build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-committed
```

Repeat the same three cuts under no-FPU TCG with `--accel tcg --cpu 486,-fpu`
and a separate output directory, for example
`build/i386-kernel/selfhost-install-gen2-fixed/install-recovery-tcg-nofpu`.

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
python3 tools/test-i386-boot-audit.py  # boot ISA rejection cases, no QEMU
python3 tools/test-i386-doldoc-session.py  # writable three-boot acceptance
```

`--cpu` selects the QEMU CPU model and is recorded verbatim in `result.json`.
`i386-kernel-input.py` defaults to `486`; the writable three-boot runner defaults
to `486,-fpu`. The local QEMU has no 386 model, so `486,-fpu`
checks the no-coprocessor runtime contract but does not establish 386 ISA
compatibility. Use the separate instruction audit and a true 386-capable
emulator or physical machine for that promotion gate.
`build-i386-kernel.py` audits its BIOS and protected-mode boot executable
ranges during every build; `build/i386-kernel/boot-instruction-audit.json`
records byte counts, instruction counts and hashes. The build also audits its
linked module code. Live JIT output remains a separate coverage requirement.

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

Copy the fully guest-built installed image and boot the copy without `-snapshot`:

```sh
cp build/i386-kernel/selfhost-install-gen2-fixed/target.img build/i386-manual.img
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

## Manual self-hosted workstation session

Use the independently installed fully guest-built disk. Keep a writable copy so the
automated reference remains unchanged. Record observations in the
[manual observation template](i386-manual-observation-template.md):

```sh
cp build/i386-kernel/selfhost-install-capacity-lexfix-kvm/target.img build/i386-manual-source.img
qemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu -m 8 -nic none \
  -drive file=build/i386-manual-source.img,format=raw,if=ide
```

At the HolyC prompt, open `Help("C:/Doc/CmdLineOverview.DD");`, follow its
directory link with Enter or the mouse, then return. Create `C:/Project` and
`C:/Project/Sub` with `DirMk`, browse them with `EdDir`, and open
`Ed("C:/Project/Sub/Main.HC");`. Type a multiline program defining
`I64 ManualAnswer(){return 6*7;}` and calling `ManualAnswer;`. Press F5 and
observe `42`. Introduce a syntax error, press F5, follow the source-linked
diagnostic, repair the line, and run it again. In a separate file, run a loop
and interrupt it with Ctrl+Alt+C; confirm the editor and console remain usable.
Save with Ctrl-S, close QEMU, boot the same writable copy again, reopen the
project and run it. Try `Snd(60);` followed by `Snd;` for the PC speaker, and
repeat the long-document screen/scroll check above. Record observed boot,
editing and interruption latency, plus any input or display discrepancy.

For the full native rebuild, close QEMU and make a blank-boot target from that
same source disk so the project files are present on both volumes:

```sh
python3 - <<'PY'
from pathlib import Path
source=Path('build/i386-manual-source.img').read_bytes()
Path('build/i386-manual-target.img').write_bytes(bytes(2048*512)+source[2048*512:])
PY
qemu-system-i386 -machine pc -accel tcg -cpu 486,-fpu -m 16 -nic none \
  -drive file=build/i386-manual-source.img,format=raw,if=ide \
  -drive file=build/i386-manual-target.img,format=raw,if=ide,index=2
```

Run these HolyC commands. The kernel build may take several minutes under TCG;
each module command should return `1`:

```c
I386BuildModule("C:/Kernel/I386/Kernel.HC","C:/Probe/ManualKernel.t32m",TRUE)>0;
I386BuildModule("C:/Kernel/I386/SysTry.HC","C:/Modules/I386/SysTry.t32m",TRUE)>0;
I386BuildModule("C:/Kernel/I386/TaskContext.HC","C:/Modules/I386/TaskContext.t32m",TRUE)>0;
I386BuildModule("C:/Kernel/I386/ExceptContext.HC","C:/Modules/I386/ExceptContext.t32m",TRUE)>0;
I386BuildModule("C:/Kernel/I386/IrqEntry.HC","C:/Modules/I386/IrqEntry.t32m",TRUE)>0;
I386BuildModule("C:/Kernel/I386/ExceptionEntry.HC","C:/Modules/I386/ExceptionEntry.t32m",TRUE)>0;
I386BuildBootImage("C:/Probe/ManualKernel.t32m","C:/Modules/I386/","C:/Probe/Manual.bin")>0;
I386InstallBootImage("C:/","D:/","C:/Probe/Manual.bin");
```

The final command should return `1`. Close QEMU, boot
`build/i386-manual-target.img` alone with the same 16 MiB profile, reopen the
project, run it, and compile `C:/Compiler/I386/LexNumber.HC` to a new T32M.
Keep the source and target images and a short observation log. Automated
rebuild, project, compatibility and interruption checks cover the
byte-level and recovery contracts; this session checks the human workflow.

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

For long compiler-source investigations, the Python `run_input` helper accepts
`accel='kvm'` when the host provides accessible `/dev/kvm`. Its default remains
`accel='tcg'`; this option is currently a Python API argument, not a CLI flag.
The exact QEMU invocation, including accelerator, is saved in `command.json`.
Use copied disks for writable probes. KVM runs provide development feedback;
TCG remains the required promotion profile and 386 instruction audits still
apply. A console expression such as `I386BuildModule(...)||1` only checks that
the console recovers: it masks the builder's failure return. Inspect build
rejection logs and independently audit the resulting artifact before claiming
a successful source build.

To audit two full guest-built compiler artifacts against the host assembly:

```sh
python3 tools/audit-i386-compiler-runtime.py \
  build/i386-kernel/exports/CompilerRuntime.t32m \
  build/i386-kernel/full-runtime-kvm-division/GuestCompilerRuntime.t32m \
  build/i386-kernel/full-runtime-kvm-generation1/CompilerRuntime.t32m
```

The Python QEMU helper also accepts `startup_timeout=<seconds>` for an
explicitly measured exploratory boot; the normal default is 60 seconds. The
Generation 1 compiler disk needed 72.917 seconds at 16 MiB on TCG. Passing
with a larger limit does not satisfy the normal startup budget.

To repeat the original TempleOS styled-document compatibility check on the
current second generation, use its completed three-boot session image:

```sh
python3 tools/test-i386-doc-style-compat.py \
  build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doldoc-tcg-nofpu-stdio/session.img \
  --out build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/doc-style-compat-stdio \
  --qmp-stdio
```

The check extracts the persisted native color/style document, boots original
x64 TempleOS under QEMU to read and save it, and compares the returned bytes.
The original guest also edits the document; a copied i386 session disk receives
those bytes in the existing one-sector file, then boots under `486,-fpu` TCG
and reads/saves them unchanged. The i386 guest checks the original guest's
added `!` marker in the parsed document before writing it. The source session
disk is not changed. Run
the same command with the first generation's `doldoc-tcg-nofpu/session.img`
to reproduce both packaged results.

To enforce the normal-boot timing budget against an existing full workstation
result, run:

```sh
python3 tools/check-i386-startup-budget.py \
  build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/full-tcg-nofpu-stdio-cli/result.json \
  --out build/i386-startup-budget-gen2.json
```

The checker requires a passing interactive `486,-fpu`, 8 MiB result with a
finite positive startup measurement. It exits 0 within 60 seconds, 1 over
budget, or 2 for invalid evidence, and records the input hash. This timing
check alone does not establish candidate provenance or full qualification.
The current second-generation result is an expected failure at 73.265 seconds.

To locate costs in that installed candidate without changing it:

```sh
python3 tools/profile-i386-boot.py \
  --disk build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --cpu 486,-fpu --out build/i386-boot-profile-gen2-nofpu \
  --interval 0.2 --timeout 240
```

The profiler extracts symbols from the disk's retained modules, boots a QEMU
snapshot, and verifies the original disk hash afterward. It records module
hashes, sampled instruction addresses and frame chains. Its pauses distort
elapsed time: use the unprofiled workstation result for the startup gate.

To verify emitted speaker output independently of PIT register checks:

```sh
python3 tools/test-i386-speaker-output.py \
  build/i386-kernel/selfhost-install-capacity-lexfix-gen2-kvm/target.img \
  --out build/i386-speaker-output-gen2-emission
```

Repeat with `selfhost-install-capacity-lexfix-kvm/target.img` and output
`build/i386-speaker-output-gen1-emission` for the first generation. The test
uses 8 MiB `486,-fpu` TCG, QMP stdio, and an unchanged-source QEMU snapshot.
It needs no host audio service: the speaker connects directly to the WAV backend.
Four commands retain the existing PIT/IRQ/VGA assertions while holding 440 Hz
and 880 Hz tones, speaker-off and reset states. The checker requires at least
one second of each stable tone and rejects other sustained output.

This QEMU backend omits inactive-voice intervals from its WAV. After a 0.3-second
drain interval, each 1.5-second off/reset observation must emit zero new file
bytes; each tone observation must emit at least one second of PCM. The WAV and
these independent observations together verify tone and silence. The result
records disk, WAV, checker and runner hashes, raw windows and emission sizes.
The source disk must remain unchanged. Malformed or incomplete observations
fail instead of being treated as silence.

`tools/package-i386-current.py` requires both results (override their paths
with `--first-audio` and `--second-audio`), validates their exact disk/profile
and test hashes, and reanalyses both recordings. Its standalone verifier
repeats that analysis using the bundled checker. `python3
tools/test-i386-test-runner.py` exercises muted/wrong/reversed/stuck tones,
missing silence, invalid emission observations and source-disk protection.

The public task/debug publication probe is an intentionally open requirement:

```sh
python3 tools/test-i386-required-services.py build/i386-kernel/kernel.img \
  --out build/i386-required-services-startup-u32
```

It boots an unchanged snapshot under 8 MiB `486,-fpu` TCG, verifies known
public `MAlloc` and `Dir` controls, then checks `Spawn`, `Exit`, `Yield`,
`Sleep` and `Dbg` in the native public function table. Missing functions
produce exit 1 and a named failing JSON result; absent/repeated observations
or failed controls produce an invalid verdict. A publication pass alone
does not establish task/terminal or debugging behavior.

For a development flat-kernel rebuild on fresh cross-built retained inputs:

```sh
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-kernel/kernel.img \
  --out build/i386-kernel/selfhost-startup-u32-development \
  --accel kvm --cpu 486,-fpu --qmp-stdio --cross-retained
```

`--cross-retained` checks the disk, retained exports and delivered source
against the cross-build manifest and explicitly reports zero guest-built
retained modules. This is development feedback and cannot satisfy M7's
all-module, two-generation gate. Normal runs retain the existing guest-built
input workflow. Interrupted/rejected runs clear any old final verdict.
The x64 ISO/rebuild tools use the immutable original snapshot commit instead
of an `archive` branch; ordinary clones must include that history. An isolated
ISO can be audited with `python3 tools/verify-iso.py --image <path>`.

The optimized-source integration commands are:

```sh
python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img \
  --cpu 486,-fpu --qmp-stdio --out build/i386-startup-u32-workstation-tcg
python3 tools/check-i386-startup-budget.py \
  build/i386-startup-u32-workstation-tcg/result.json \
  --out build/i386-startup-u32-workstation-budget.json
python3 tools/test-i386-doldoc-session.py \
  build/i386-kernel/selfhost-startup-u32-development/target.img \
  --cpu 486,-fpu --qmp-stdio --out build/i386-startup-u32-doldoc-tcg
```

These completed development runs pass their startup and visible-update/interrupt
budgets. Their retained modules are cross-built; repeat the promotion profiles
after all guest-built retained outputs are installed. A result from an older
image is not a pass for a changed disk, and an active build checkpoint is not
a final module audit.

### Public cooperative delays

Run the focused public contract on the actual candidate disk:

```sh
python3 tools/test-i386-public-delay.py build/i386-public-delay-kernel/kernel.img \
  --out build/i386-public-delay-after
```

The test first requires exactly one public lookup observation for each delay
and working `MAlloc`/`Dir` controls. It then executes `Yield`, zero/negative
`Sleep`, and future/past `SleepUntil` deadlines, checks task identity, idle-bit
restoration and IF preservation (including calls with interrupts masked), and
requires exact VGA output plus a usable prompt afterwards. It uses 8 MiB
`486,-fpu` TCG and preserves the input image. Missing functions fail; invalid
lookup controls cannot become a pass. This does not establish multiple terminals
or public task creation/exit.

Keep a newer image isolated while older-source native builds continue:

```sh
python3 tools/test-rebuild.py
python3 tools/build-i386-kernel.py --out build/i386-public-delay-kernel
python3 tools/test-i386-retained-build.py \
  --disk build/i386-public-delay-kernel/kernel.img \
  --out build/i386-public-delay-native-memory \
  --reference-exports build/i386-public-delay-kernel/exports \
  --module MemoryRuntime --accel kvm --cpu 486,-fpu --qmp-stdio
```

The reference directory supplies the matching export contract, not proof of
byte equality or a complete native installation. A selected module rebuild
cannot satisfy the all-module/two-generation qualification gate.

### Isolated full integration outputs

`tools/build-i386-kernel.py --test --out BUILD` passes that exact build directory
to its final install-copy check and that build's kernel image to document
compatibility. Their results are written to `BUILD/install-copy/result.json`
and `BUILD/doc-compat/result.json`.

To repeat those gates independently:

```sh
python3 tools/test-i386-install-copy.py --build build/i386-asm-char-kernel
python3 tools/test-i386-doc-compat.py build/i386-asm-char-kernel/kernel.img \
  --out build/i386-asm-char-kernel/doc-compat --qmp-stdio
```

Install-copy records the original input image hash and checks that it remains
unchanged across publication, target boot and interrupted-copy recovery. It
removes an old result before starting so a failed repeat cannot leave a stale
pass. Neither isolated gate alone is a full integration pass.

### Public task lifecycle contract

```sh
python3 tools/test-i386-public-tasks.py build/i386-public-delay-kernel/kernel.img \
  --out build/i386-public-tasks-before
```

The current baseline exits 1 for missing public `Spawn`, `Exit` and `TaskQueIns`, with working
`MAlloc`/`Dir` controls. After publication, the behavior branch exercises the
ordinary public interfaces under 8 MiB `486,-fpu` TCG: parent/heap/symbol/directory
ownership, child links, task records, explicit exit and ordinary entry return,
default parent/name/stack, nested selection of a different parent, and repeated
public-pool reclamation. Deferred creation with `flags=0` must remain dormant
through 20 yields, then activate through `TaskQueIns` and reclaim its allocations
without public child-ring insertion. That sequence repeats 20 times, checking
both pool usage and reserved capacity after each cycle. All 43 commands fit
the interactive line limit. Checks of a
new task's record and child links run inside the spawning command before any
yield; later commands never dereference a possibly reclaimed task. Pool usage
is measured inside the repeat function so transient command compilation does
not invalidate the comparison. Bootstrap stack/control reclamation, allocation
failure and disposal of never-activated tasks need additional oracles.
The behavior branch is currently unexecuted; missing service observations are
not an end-to-end lifecycle pass. Checker hashes are fixed before the run and
changes during testing reject the verdict.

### Installing the optimized native retained outputs

```sh
python3 tools/test-i386-retained-install.py \
  --source build/i386-kernel/retained-startup-u32-kvm/source.img \
  --out build/i386-kernel/retained-startup-u32-installed \
  --accel kvm --cpu 486,-fpu --qmp-stdio
python3 tools/i386-kernel-input.py \
  build/i386-kernel/retained-startup-u32-installed/candidate.img \
  --out build/i386-retained-startup-u32-keyboard-tcg \
  --group keyboard --cpu 486,-fpu --qmp-stdio --writable-copy
python3 tools/check-i386-startup-budget.py \
  build/i386-retained-startup-u32-keyboard-tcg/result.json \
  --out build/i386-retained-startup-u32-keyboard-budget.json
```

The installer verifies persisted module bytes, uses a separate writable copy
for independent boot, preserves the source/candidate hashes and rejects output
paths that would overwrite its source. To qualify a single rebuilt provider,
add `--module CompilerRuntime` (repeat `--module` for multiple providers).
The report lists only the selected providers; this does not establish that
the other installed modules were built natively. Omitting the option still
requires and installs all six retained providers. These outputs predate the public-delay
change. The installed image's observed 71.383183-second startup fails the
60-second budget; a component installation pass does not promote it to M7.

### Native inline assembly contract

Cross-compiling a loader fixture does not prove that the guest compiler accepts
the same assembly. Compile and execute the loader-required operand forms,
explicit local branches, and a block exceeding 256 bytes through the normal
guest prompt:

```sh
python3 tools/test-i386-native-inline-asm.py IMAGE --out build/native-inline-asm
```

The test stages a bounded source file through DolDoc, checks its saved source,
then verifies assembly returning 41 and ordinary HolyC returning 42. It uses
8 MiB `486,-fpu` TCG, compares VGA pixels, and preserves the supplied image via
a snapshot. Its report covers those assembly forms; it is not full assembler
feature parity or full self-hosting qualification. For isolated development
flat-kernel builds, `test-i386-selfhost-install.py --cross-retained --cross-build
DIRECTORY` verifies retained inputs against that explicit cross-build manifest.
These runs remain development evidence even if the native flat kernel boots.

### Native expression conditionals

The expression `#if` frontend contract has a recorded failing baseline and
passes on the updated compiler. Run its native JIT fixture with:

```sh
python3 tools/test-i386-native-conditionals.py IMAGE --out build/native-conditionals
```

The test checks macro arithmetic, true/false/nested branches, 32-bit pointer
`sizeof`, floating-point truth, skipped invalid code and code after directives.
After a failed condition it requires the shared original expression diagnostic
(`Invalid lval at` for a missing name), prior definitions and ordinary execution
to survive, with no failed definition published. Its report preserves source
and checker hashes. The older image fails while including the positive fixture; the updated
compiler passes its behavior assertions. For executed JIT/AOT distinction:

```sh
python3 tools/test-i386-native-conditionals-aot.py IMAGE --out build/native-conditionals-aot
```

This stages a source file, checks JIT result 98, builds its module in the guest,
and feeds those exact bytes to the native loader corpus with expected result 99.
It preserves the source disk and checker hashes, uses a writable working copy,
and saves the matching module/loader report. The module must fit the corpus's
existing 2,048-byte packet. These tests do not establish allocation-failure or
exact conditional-owned heap cleanup.

The retained task runtime shares the installed scheduler's switch and binding
callbacks. Run its focused interoperability fixture after the source bootstrap:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --tasks --task-runtime-core
python3 tools/test-i386.py --tasks
```

The focused fixture writes `build/i386-task-runtime-core-test/result.json` and
checks 20 dormant creation/activation/normal-return/destruction cycles, private
allocation reclamation, exact bootstrap heap accounting, both task rings and
FS/GS binding. It also checks 20 never-activated disposal cycles, retention
of a creator's code while its dormant child exists, and a failed file cleanup
followed by successful retry without premature creator destruction. It uses a separate image to stay below the existing task fixture
memory limit. This verifies private retained helpers; public Spawn/Exit/TaskQueIns
and automatic reaping still require the public task contract tests.

Before changing the public lifecycle contract, check that its definition source
also compiles in original TempleOS:

```sh
python3 tools/test-i386-public-task-definitions.py
```

This oracle compiles the classes and function bodies from the public contract
and initializes its state pointer to zero. It never runs the workers. The
separate public lifecycle test still proves runtime behavior and resource
recovery on the selected i386 disk; a definition-compile pass cannot replace it.

For the public directory view used by Spawn, run:

```sh
python3 tools/test-i386.py --task-symbols
```

This checks that `CTask.cur_dir` points to the owned directory, that children
receive distinct inherited storage, and that directory replacement updates the
public pointer. It also exercises explicit-parent symbol/file inheritance and
parent retention through task exit. The public lifecycle gate still needs to
pass on both the cross-built and installed guest-built runtime.

The public lifecycle contract also checks six creation rejections, unchanged
public pool/child state, caller IF and a successful spawn afterward. Run the
separate descendant oracle to compare parent return/Exit with original TempleOS:

```sh
python3 tools/test-i386-public-task-descendants.py --original --out build/descendants-original
python3 tools/test-i386-public-task-descendants.py build/i386-kernel/kernel.img --out build/descendants-i386
```

It covers a child canceled before entry, a running child, a sleeping child and
a sleeping grandchild. The original reference executes these cases, rather than
only compiling their definitions. Each native command checks exact VGA; the
input disk and checker remain unchanged. This does not establish public Kill,
I/O cancellation or disposal of never-activated tasks.

The public pool counters do not include raw stack/control/registry allocations.
Check those separately with the bootstrap accounting gate:

```sh
python3 tools/test-i386-public-task-accounting.py build/i386-kernel/kernel.img --out build/task-bootstrap-accounting
```

The checker derives private layout declarations from source headers in the
tested disk, rather than importing internal implementation headers into the
app. It binds the installed heap validator and checks both signatures before
reading counters. It requires exact bootstrap used-byte and allocation-count
recovery after 20 normal-return/Exit cycles, 20 deferred-activation cycles and
six creation rejections. Header hashes, disk hash and both checker hashes are
recorded. Run it again on the installed guest-built provider; public pool
recovery and bootstrap recovery prove different resource invariants.

The accounting gate also executes 20 descendant-tree cycles, repeating the five
original cases four times, and hashes the descendant checker it uses. This
includes destruction of sleeping grandchildren; functional child-list removal
alone does not establish raw allocation recovery.

Check structured exceptions inside spawned workers independently:

```sh
python3 tools/test-i386-public-task-exceptions.py --original --out build/task-exceptions-original
python3 tools/test-i386-public-task-exceptions.py build/i386-kernel/kernel.img --out build/task-exceptions-i386
```

The original reference executes catches across a yield, nested catches/rethrow,
Exit inside try, and descendant cancellation with an active exception record.
The native run requires the same results and exact VGA on an unchanged disk.
This does not establish uncaught-exception recovery or public Kill/break.

The bootstrap accounting gate repeats all four worker-exception variants five
times. It checks raw allocation recovery after every worker retires, including
Exit inside a try block and cancellation with a live exception record. Its
report includes the exception checker hash and the 20-cycle verdict alongside
ordinary, deferred and descendant-tree task accounting.

Check public task exit callbacks against executable original behavior:

```sh
python3 tools/test-i386-public-task-end-callbacks.py --original --out build/task-end-original
python3 tools/test-i386-public-task-end-callbacks.py build/i386-kernel/kernel.img --out build/task-end-i386
```

The five cases cover normal return, explicit Exit, a callback that throws to
an active catch and resumes task execution, and queued descendant cancellation
inside try, with either callback-driven Exit or recovery. A parent must renew
termination requests if its child recovers. Callbacks must run once with their public pointer cleared and kill,
suspension, message-wait and wake state reset. The resumed task must still be
able to spawn a child. This does not establish public Kill or I/O cancellation.
The bootstrap accounting gate repeats each variant four times, checks exact
allocation recovery after each cycle, and records the callback checker hash.


The public Kill contract is a tests-first prerequisite; the port does not yet
publish this API:

```sh
python3 tools/test-i386-public-task-kill.py --original --out build/task-kill-original
python3 tools/test-i386-public-task-kill.py build/i386-kernel/kernel.img --out build/task-kill-i386
```

The original reference executes nine variants: cancellation before entry,
running, sleeping and suspended tasks, callback recovery, caller-side Break,
asynchronous cancellation of sleeping/suspended tasks, and caller-side
Shift-Esc delivery. The latter sets BREAK_TO_SHIFT_ESC on the caller and checks
MSG_KEY_DOWN, CH_SHIFT_ESC and scan code 0x20100000201. Original Kill returns
FALSE on this path despite posting the message; the target stays alive and can
subsequently be cancelled normally. Async cancellation
must initially preserve wake deadlines and all flags except KILL. It also
rejects null, protected-root and retired task pointers. The native check first
requires a working MAlloc lookup and public Kill lookup, then the same behavior
with exact VGA. It is expected to fail until Kill is published. Self-directed
break, I/O-wait cancellation and full public message/break behavior need separate
contracts; this test does not qualify those paths.


Verify native assembly operand encoding and compiler recovery:

```sh
python3 tools/test-i386-asm-recovery.py build/i386-kernel/kernel.img --out build/asm-recovery
```

Use a fresh image containing the current AsmOperandFixture.HC and compiler
provider. At 16 MiB with no FPU, the test writes an invalid source through
DolDoc, requires zero-divisor rejection without an output module, then compiles
a valid fixture and checks exact bytes for OR register/memory, TEST masks and
constant expressions, class-member displacement and signed branches. It verifies
that the prompt remains usable and freezes input-disk/checker/validator hashes.
Use `--accel tcg` for software emulation. This tests selected assembly/error
paths; it does not establish all compiler error recovery or public FileWrite.

Public message compatibility has a separate tests-first reference:

```sh
python3 tools/test-i386-public-messages.py --original --out build/public-messages-original
python3 tools/test-i386-public-messages.py build/i386-kernel/kernel.img --out build/public-messages-i386
```

The fourteen checks cover empty root/child job queues, 40 queued messages in FIFO order, destructive mask
filtering, negative message codes producing down/up events, FlushMsgs counts
and zeroed outputs on an empty queue, and PostMsg/GetMsg delivery to a child.
The native runner first checks MAlloc and Msg publication and then requires the
same console results, preserving the input image and freezing checker hashes.
The routing checks temporarily link two live worker tasks: normal posts follow
the filter chain, DONT_FILTER bypasses it, and a post to an input-filter task
returns to its preceding task. Popup checks cover parent-queue fallback,
rejection of a parent post without FILTER_INPUT, direct popup delivery and
clearing AWAITING_MSG on both parent and popup. Links are restored before
workers retire. These check routing against public task fields; they do not run
the original InputFilterTask job loop or establish full window-manager behavior.
These public APIs are not yet published in the port; the native command is a
future acceptance gate, not a currently passing test. A queued JOBT_CALL must execute before a following message is returned and
move to the completed queue with result 42 and DISPATCHED/DONE flags. The test
then removes and frees that completed node. EXE_STR/SPAWN jobs, macro
recording and allocation recovery are outside this contract.

Check public task job-queue initialization independently of message delivery:

```sh
python3 tools/test-i386-public-task-queues.py --original --out build/task-queues-original
python3 tools/test-i386-public-task-queues.py build/i386-kernel/kernel.img --out build/task-queues-native
```

The focused contract checks empty waiting/done circular rings and unlocked
control flags for the root and ten spawned children. It exercises the same
public records in original and native guests and does not call the internal
JobCtrlInit helper. The contract also inserts three jobs with auxiliary strings into a child's
waiting/done rings using caller-owned allocations, then requires exact caller
heap usage recovery after exit. Both original and native references pass this addition, including a verified
native red result before the cleanup implementation. Message delivery and general allocation
recovery require separate checks.

Check input-filter link lifetime before qualifying message routing:

```sh
python3 tools/test-i386-public-task-filter-links.py --original --out build/filter-links-original
python3 tools/test-i386-public-task-filter-links.py build/i386-kernel/kernel.img --out build/filter-links-native
```

The caller and ten spawned children must begin with input-filter self-links.
Each child joins the caller's ring and exits; the caller's ring must return to
self-links. The original reference passes, and the preceding native image has
a verified red result. The new implementation passes green qualification and the queued-job cleanup
and callback regressions on the same 8 MiB no-FPU image. This does not run the
input-filter job loop.

Verify public task validity before deferred storage reclamation:

```sh
python3 tools/test-i386-public-task-validity.py --original --out build/task-validity-original
python3 tools/test-i386-public-task-validity.py build/i386-kernel/kernel.img --out build/task-validity-native
```

The current/root task and live child must validate. The child then retires with
its heap locked; it must stop validating before the lock is released and storage
is reaped. Original reference and preceding-image native red are verified;
green qualification of the scheduler fix passes at 8 MiB without an FPU.
Native and retained scheduler regressions, queued-job cleanup and callback
recovery checks also pass. This does not establish
safety for arbitrary unmapped pointers.

Verify message posting separately from scanning/job dispatch:

```sh
python3 tools/test-i386-public-message-posting.py --original --out build/message-posting-original
python3 tools/test-i386-public-message-posting.py build/i386-kernel/kernel.img --out build/message-posting-native
```

Five contracts inspect actual CJob nodes for 40-event FIFO, paired messages,
invalid task/master rejection, full-width metadata, system-heap ownership and
idle/await wake flags.
They remove and free nodes directly; they do not supply a replacement ScanMsg.
Original and native version-13 provider qualification pass, including all VGA
checkpoints at 8 MiB on 486,-fpu. Queued-job cleanup (12 cases) and callback
recovery (5 cases) also pass on that image. Scanning, routing, macro recording and allocation recovery
need their own checks.

The posting checker additionally tests forward and backward filter routing,
DONT_FILTER bypass, popup rejection/direct delivery, and popup-chain wakeup,
for eleven cases total. Original qualification passes; expanded native
qualification passes in build/i386-posting-routing-native at 8 MiB on
486,-fpu with all VGA checkpoints matching. Fixtures restore
task links before retirement and inspect actual CJob nodes without ScanMsg.

The full message reference has fifteen original cases, including callback
argument delivery and master-owned completion before message scanning.
Native job dispatch/scanning is still open; a passing posting test does not
qualify those services.

Verify public suspension and scheduler eligibility:

```sh
python3 tools/test-i386-public-task-suspend.py --original --out build/suspend-original
python3 tools/test-i386-public-task-suspend.py build/i386-kernel/kernel.img --out build/suspend-native
```

Five contracts cover the previous-state return, NULL caller, signature rejection,
preservation of flags/deadline, suspended-child exclusion and resume. Original
and corrected version-14 native qualification pass (five cases, 16 commands,
8 MiB on 486,-fpu, matching VGA checkpoints). The earlier version-14 image
failed during header publication; the literal-default correction resolves it.

The full message reference now has sixteen original contracts. The added queued
callback throws JobTest; completion flags/queue and subsequent message delivery
must still succeed. This exercises the job handler's exception recovery, not
general uncaught child-exception isolation. Native dispatch remains open.

The full message reference now has eighteen original cases, adding queued
spawn parent/argument/lifecycle and queued source execution result 42. Fixtures
release the spawned child and free completed jobs plus auxiliary source/name
strings. Native dispatch/scanning remains unimplemented. The corrected
version-14 posting regression separately passes all eleven posting cases.

Qualify job dispatch independently of message scanning:

```sh
python3 tools/test-i386-public-job-dispatch.py --original --out build/dispatch-original
python3 tools/test-i386-public-job-dispatch.py build/i386-kernel/kernel.img --out build/dispatch-native
```

Five contracts cover all three dispatch kinds, callback recovery, master
wake/focus and spawned-child lifecycle. Original qualification passes; native
version-15 qualification is pending. Source execution prints 42 before the
fixture's boolean result. These checks do not supply a scanner or qualify
free/exit completion flags, inhibited focus, cancellation or allocation errors.

Version-15 direct-dispatch native qualification passes all five cases at 8 MiB
on 486,-fpu with matching VGA checkpoints. Version-16 adds public scanning,
waiting and flushing; its full eighteen-case native message qualification is
pending. Queued source execution prints 42 before the boolean fixture result,
which the checker now expects explicitly.

The full message reference now has nineteen original cases, adding inhibited
key-description filtering followed by ordinary key delivery and queue emptiness.
The fixture restores caller inhibit flags. Native version-16 qualification is
pending on the corrected scanning image; no keyboard hardware integration is
implied by posting these events directly.

The direct-dispatch checker now has seven original contracts, adding exact heap
recovery for FREE_ON_COMPLETE (job and auxiliary string) and inhibited focus.
Expanded native qualification is running on the version-16 image. Its queue
cleanup and callback regressions pass at 8 MiB without an FPU; the full message
run remains pending.

Version-16 full native message qualification passes nineteen contracts (82
commands), and the seven-case direct-dispatch qualification passes, both at
8 MiB on 486,-fpu with matching VGA checkpoints and unchanged source disk.
The checker now includes a pending eighth EXIT_ON_COMPLETE fixture; its first
original run timed out, so do not treat that added case as a validated oracle
until the phase-marked rerun is diagnosed.

The eighth EXIT_ON_COMPLETE oracle is now corrected and passes on original
TempleOS: the end callback explicitly calls Exit, and servant code after
JobsHndlr must remain unreachable. The initial returning callback was an
invalid fixture assumption. Native eight-case qualification is pending in
build/i386-public-dispatch-exit-native. Inner diagnostic phase markers avoid
DONE so the harness waits for the complete suite verdict.

The corrected eight-case dispatch native suite passes at 8 MiB on 486,-fpu
with matching VGA checkpoints. Start keyboard/public-message integration with:

```sh
python3 tools/test-i386-public-keyboard-messages.py build/i386-kernel/kernel.img --out build/keyboard-messages
```

The checker injects `a` while HolyC waits in GetMsg, checks make/break ASCII and
scan code, then checks console recovery. Its first baseline run is pending;
this does not yet qualify focus switching, popup/filter keyboard routing or
lost-input recovery. The harness preserve_history interaction flag retains
console command rows; existing editor interactions retain their default.

The corrected keyboard baseline is red in
build/i386-public-keyboard-messages-red-v2: the fixture compiles, reaches GetMsg,
injects `a`, and times out before completion. The first attempt's ports include
failed to compile and did not constitute a keyboard red result. The checker now
uses the preexisting OutU8 intrinsic without that include.

Console version 33 implements a single input worker plus public-message readers.
Green keyboard delivery, focus/reset recovery, document editing and break
regressions remain pending. Historical version-16/console-32 retained builds
must not be presented as qualification for the new input routing source.

For the keyboard routing change, pair the public GetMsg contract with the
ordinary keyboard, breaks and DolDoc session checks:

```sh
python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img --group keyboard --cpu 486,-fpu --qmp-stdio --out build/keyboard-console
python3 tools/i386-kernel-input.py build/i386-kernel/kernel.img --group breaks --cpu 486,-fpu --qmp-stdio --out build/keyboard-breaks
python3 tools/test-i386-doldoc-session.py build/i386-kernel/kernel.img --qmp-stdio --out build/keyboard-doldoc
```

The console-33 build and 386 boot audit pass; these runtime runs remain pending.
A public key-pair pass alone does not qualify focus changes, stream loss or
editor/compiler break recovery.

The first console-33 runtime runs time out during initial command typing.
ConsoleInit had assigned focus to the kernel root before the console task was
spawned. Initial focus is now assigned in ConsoleKeys entry. Fresh build and
public-keyboard/ordinary-keyboard/break/DolDoc reruns are pending; the earlier
build pass did not qualify interactive input.

The initial-focus correction alone does not restore input: all four reruns
still fail at initial typing. A fresh diagnostic image records worker entry,
first decoded event/target signature and startup task pointers on the debug
port. No keyboard green result is claimed.

Focused-child delivery has a separate checker:

```sh
python3 tools/test-i386-public-keyboard-focus.py build/i386-kernel/kernel.img --out build/keyboard-focus
```

It gives a spawned child focus, injects `a` while that child waits in GetMsg,
then restores console focus. Its source lines fit the 255-byte input limit;
behavior remains unqualified until input routing itself works.

The worker-trace image reaches startup and logs a nonzero spawned worker, but
never logs worker entry before the initial-typing timeout. The boot console
must enroll its public job rings through a managed yield before its first
ScanMsg. NativeKeyboardStart now performs that yield. Both original rebuild
generations pass; fresh-image runtime verification is pending. The failure is
recorded in build/i386-public-keyboard-trace/result.json (unchanged input disk).

The enrollment fix passes the public keyboard checker on
build/i386-public-keyboard-enrolled-fixed-kernel/kernel.img, 486,-fpu, 8 MiB.
build/i386-public-keyboard-enrolled-fixed/result.json records all VGA pixels
matched, both GetMsg key events validated, console arithmetic recovery, and
unchanged source disk. Worker entry is present in its debug log. Focused-child,
ordinary keyboard, breaks and DolDoc reruns are running in the corresponding
build/i386-public-keyboard-enrolled-* directories; this narrow pass does not
qualify those additional workflows.

Focused-child delivery and ordinary keyboard checks now pass on the enrollment
image (build/i386-public-keyboard-enrolled-focus and
build/i386-public-keyboard-enrolled-console). Break recovery fails at the first
HotkeyWait(0) checkpoint: the permanent keyboard worker's creator reference
causes the lifetime_refs guard in I386TaskBreakPoll to defer delivery. The guard
is removed while operation-specific safety checks remain. A fresh build and
break test are required for that new source; DolDoc remains running on the
previous enrollment image.

The intermediate break fix passes HotkeyWait(0), but fails deferred unlock
because compiler polling still defers for the keyboard worker's creator pin.
CI386Task now tracks inherited_refs separately from borrowed-operation refs;
both kernel and compiler break checkpoints permit persistent child references
while retaining borrowed-resource guards. Public CTask is unchanged. Both
original rebuild generations pass; fresh cross-build and native task-heap
counter/lifetime checks are running. Require a fresh break-suite pass before
claiming recovery. The enrollment DolDoc run is terminal incomplete at
DocEd(break_doc); its source disk is unchanged.

The inherited-reference image passes the full breaks group (16 commands,
486,-fpu, 8 MiB, exact VGA pixels) in
build/i386-public-keyboard-inherited-refs-breaks/result.json. Immediate/deferred
delivery and generated loop checkpoints recover with the permanent keyboard
worker present. Focused-child break routing is still outside this result.
Fresh full DolDoc, public message and job-dispatch regressions are running on
that image; the intermediate-image DolDoc run is terminal incomplete at the
editor break checkpoint and cannot qualify the new source.

Focused-child interrupt routing has its own hardware-driven contract:

```sh
python3 tools/test-i386-public-keyboard-break-focus.py IMAGE --out build/focused-break
```

It requires a focused spawned HolyC loop to catch Ctrl-Alt-C as Break, restores
console focus and checks arithmetic afterward. The inherited-reference image
has a recorded red after child readiness and hotkey injection, with input disk
unchanged. The IRQ handler now selects valid focus before the console fallback;
both original rebuild generations pass and fresh native verification is pending.

The captured pre-keyboard snapshot passes all-guest-provider flat self-hosting
and independent executable/filesystem audit in
build/i386-public-message-scan-selfhost and -selfhost-audit. These historical
results do not cover current focus-routing changes.

Focused-task break now has a red/green pair from the same frozen checker:
build/i386-public-keyboard-focused-break-{red,green}/result.json. Green uses
the focused-break image on 486,-fpu at 8 MiB, matches all VGA pixels, preserves
the input disk and recovers console arithmetic. The unchanged console breaks
group also passes all 16 commands on that image. The new six-provider retained
build uses build/i386-public-keyboard-focused-break-kernel/exports as frozen
references; older guest-built images cannot qualify this epoch.

The hardware overflow contract is:

```sh
python3 tools/test-i386-public-keyboard-loss.py IMAGE --out build/keyboard-loss
```

It primes Shift through GetMsg, suspends the public Keyboard task, overflows the
raw queue using QMP keys, then resumes it. Exact VGA checks require one reset
and recovered lower-case HolyC input; the debug log must contain exactly one
INPUT RESET, and the source image must remain unchanged. It passes on the
focused-break image in build/i386-public-keyboard-loss/result.json. It does not
establish arbitrary focused-child loss notification.

The full inherited-reference DolDoc three-boot session now passes: 178 commands,
52.69–53.36-second startup, 0.3925-second editor interrupt recovery, persisted
programs and independent filesystem/bitmap checks. Its image predates focused
IRQ selection; the full latest-image workstation suite and newer guest-provider
rebuild are running separately.

The loss checker also enqueues a normal CALL job before decoder recovery,
yields to let overflow handling run, and requires that callback to execute
exactly once afterward. This expanded contract passes in
build/i386-public-keyboard-loss-queued-job/result.json on the focused-break image.
The earlier reset-only result does not establish queued-job preservation.

The TaskMsg macro-recording contract has original and native modes:

```sh
python3 tools/test-i386-public-macro-recording.py --original --out build/macro-original
python3 tools/test-i386-public-macro-recording.py IMAGE --out build/macro-native
```

It checks copied FIFO metadata, recording eligibility, macro-task exclusion,
negative-pair exclusion and invalid targets. The original six cases pass; the
memory-16 image records missing sys_macro_head publication. Memory version 17
adds the recording state and pre-filter copy path. Both original rebuild
generations pass; native verification is pending. This is not macro playback/UI
or allocation-failure qualification. Keep the checker and image frozen per run.

All six native macro cases and all 19 message cases pass on memory version 17.
The macro run records a 77.76-second startup (over budget); the same-image
message run records 56.62 seconds. Functional verdicts do not waive the timing
profile gate.

Allocation recovery has a separate native-only fault contract:

```sh
python3 tools/test-i386-public-message-allocation.py IMAGE --out build/message-allocation
```

It temporarily patches the public MAllocIdent entry on a snapshot to throw
OutMem, with IRQs disabled, then restores and checks its bytes. Root-public-heap
usage and both job rings must recover exactly. The corrected fixture records
fault_injected=true and a cleanup failure before the source fix; its first
hash-type compilation failure was not a valid behavioral red. The copy path
now frees its unqueued destination job before propagating the exception.
Fresh-image verification is pending; this covers one allocation site only.

The frozen copy-allocation checker now has a genuine red/green pair:
-macro-allocation-red-v2 and -macro-allocation-green both record the injected
fault and unchanged input image. Green verifies exact heap/ring cleanup and
code restoration, then console arithmetic, on 486,-fpu at 8 MiB. The same image
also passes all six macro-recording cases again. This covers copy allocation,
not every allocation/exception-registration failure path or release timing.

### Exception-handler registration allocation safety

The frozen registration-fault checker
`tools/test-i386-public-message-registration.py` redirects `SysTry` only after
its own handler is registered. On the preceding image it records a genuine
OutMem fault and fails exact root-heap recovery:
`build/i386-public-macro-registration-red/result.json`.
Checker SHA-256: bcce34de9c14314dcfe47df0be27ca6ae81a7a6c43d186c9ad453342880a4b19.

Recording now registers its cleanup handler before allocating either job.
Message construction is shared with the ordinary posting path; a copy failure
still frees the unqueued original and propagates the exception. Both original
rebuild generations and the fresh cross-build/386 boot audit pass. Image:
`build/i386-public-macro-registration-kernel/kernel.img`, SHA-256
c39fbee87397f74249d627da22697c09f192523c498f39346450888fdf23c0a6.
Registration-fault, copy-fault and six-case recording checks are running in
`build/i386-public-macro-registration-{green,copy,macro}`; runtime qualification
is pending, not inferred from the build.

The earlier memory-16 full workstation run has now passed:
`build/i386-public-keyboard-focused-break-workstation/result.json`, 513 native
commands, 8 MiB, 486,-fpu, 53.56-second startup, exact VGA checkpoints and 20
bounded document cycles with exact heap recovery. Its long-document navigation
latency is 0.491 seconds. This qualifies its captured snapshot, not memory-17.
The six-provider guest rebuild remains live and is compiling frontend routines.
Current-source native generations, multiple terminals, debugging and release
qualification remain open; the complete M7 objective is unchanged.

### Registration and copy-fault runtime qualification

All three frozen checkers pass on image
c39fbee87397f74249d627da22697c09f192523c498f39346450888fdf23c0a6:
`build/i386-public-macro-registration-green/result.json` (registration fault),
`build/i386-public-macro-registration-copy/result.json` (copy allocation fault),
and `build/i386-public-macro-registration-macro/result.json` (six recording cases).
Both fault reports confirm actual injection, exact root-public-heap recovery,
empty/unlocked rings, restored entry bytes, exact VGA and subsequent arithmetic.
All source disks remain unchanged. Startup measurements are respectively
55.77, 58.78 and 55.52 seconds on 8 MiB, 486,-fpu; these focused measurements
are not the complete controlled release timing profile.

The full current-image workstation suite is now running in
`build/i386-public-macro-registration-workstation`. The required-services probe
is running in `build/i386-current-debug-publication-red`; public Dbg remains an
implementation gap pending that current-image observation. A debugger must
provide visible exception/context and source/function inspection plus a tested
return/unwind; publishing the name alone cannot close M7. The earlier native
six-provider build remains live for its distinct memory-16 source snapshot.

### Explicit debugger session contract (implementation pending)

The current-image required-services probe records a valid failure in
`build/i386-current-debug-publication-red/result.json`: memory/file controls
and Spawn/Exit/Yield/Sleep are present; only Dbg is absent. Its console run
passes exact VGA checks on the unchanged memory-17 image. This is publication
evidence, not usable debugging.

Added `tools/test-i386-debug-session.py`, a separate black-box contract for
explicit Dbg entry from a named HolyC function. It requires visible message,
numeric value and function name, evaluates an expression within the debugger,
uses original-style `G;` to continue, checks the caller's subsequent state and
runs arithmetic back at the shell. The checker is running against the existing
image in `build/i386-debug-session-red`; its runtime result is pending. The
fixed rows are an independent expected UI, not copied from guest output.

Implementation should preserve the public Dbg signature and HolyC command
model, retain caller context while inspecting, and restore focus/input state
on continuation. This first contract does not close debugging: subsequent
work must preserve and inspect runtime exception context before unwinding,
resolve source/function locations, cover register/context inspection and the
applicable breakpoint/stepping requirements, and verify nested failure and
resource recovery. Multiple interactive terminals and the complete current
native-generation/release gates remain open. The latest full workstation and
older six-provider native build are still running on separate captured images.

### Explicit HolyC debugger implementation — runtime checks pending

The frozen debugger checker records a genuine publication red on the preceding
image in `build/i386-debug-session-red/result.json`: Dbg is absent, so the
required publication expression returns false. SHA-256:
0e3f90a309dce36b68fbf9116b8f1c0f3dc58ab952c5672abd2c61e1610af22f.

Added native Dbg and G bindings through PublicDebug.HH and console services
version 34. Explicit Dbg preserves the planar display and console state, shows
the message/value and a function whose executable allocation contains the
caller return IP, and evaluates HolyC commands in a nested prompt. G requests
continuation; the display/focus and allocated backup are restored on return or
propagated failure. Nested debugger entry is rejected. The 32-bit G default
uses U32_MAX; non-default IP/task control is explicitly unsupported and throws.
This is initial explicit-session support, not the complete debugger contract.

Both original rebuild generations, the fresh cross-build and 386 boot audit
pass. An early cross-build attempt ran before its bootstrap result was available
and terminated with FileNotFoundError; the sequential retry passes. Image
`build/i386-debug-session-kernel/kernel.img`, SHA-256
78e46172f7d0bca1c75c12bbbd67d75835ffd3924a5525360fb49ade1a081e48.
The frozen session checker and required-services probe are running in
`build/i386-debug-session-green` and `build/i386-debug-publication-green`.
These are pending runtime results, not a debugger usability pass.

The memory-16 focused-keyboard six-provider guest build has now passed all six
module layout/export comparisons in
`build/i386-public-keyboard-focused-break-retained/result.json`. Its source
image SHA-256 is ded01e5c8d76ab2ec1273a23f07753a9ab1ee06464bc8a845bd0e766f2f75c1a.
Installation and independent boot are running in
`build/i386-public-keyboard-focused-break-retained-install`. This older epoch
must remain distinct from current memory-17/console-34 qualification. Current
workstation, native generations, exception/source/register debugging,
multiple terminals, timing and release gates remain open.

### Debugger history oracle correction and native provider installation

The console-34 required-services probe now passes on the debugger image:
`build/i386-debug-publication-green/result.json`, 8 MiB, 486,-fpu, exact VGA,
55.86-second startup, unchanged disk. This only proves publication.

The first session run reached all debugger-screen checkpoints, evaluated the
expression and logged return from G, then failed its final console expectation.
Inspection of the saved screen shows preserved original console history, which
is the intended implementation behavior. The checker had used the runner's
history-clearing default. It now explicitly requires preserved history; no
kernel or common-runner behavior was weakened to meet that expectation.
The revised frozen checker SHA-256 is
64b6c039f8812a7d2697d4df7401301aa8d9fda72b8f46b4a2a7f37023ae5fdd.
Both baseline and implementation runs are pending in
`build/i386-debug-session-history-red` and
`build/i386-debug-session-history-green`. The earlier failure is retained in
`build/i386-debug-session-green/result.json`; do not report it as a full pass.

All six guest-built memory-16/console-33 providers installed and independently
booted successfully in
`build/i386-public-keyboard-focused-break-retained-install/result.json`.
Candidate SHA-256:
3ffed5e14a7c8bc61e247b127a8ac40aad79d4f3edcb66e8d96c9f4889984bdb.
Installation preserves all module bytes and the source/candidate images; the
8 MiB boot executes arithmetic and the document-allocation checker.
The flat-kernel self-hosting build is now live in
`build/i386-public-keyboard-focused-break-selfhost`, using these six native
providers without cross-retained inputs. This remains an earlier source epoch;
it does not qualify the new debugger or current release. Full current-source
native generations, terminal/debugger workflows and release gates remain open.
