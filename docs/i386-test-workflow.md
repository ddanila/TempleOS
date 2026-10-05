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
  --retained-build-result build/i386-kernel/retained-build-gen2-fixed/result.json \
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
python3 tools/test-i386-retained-build.py \
  --disk build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --compare-installed build/i386-kernel/selfhost-install-gen2-fixed/target.img \
  --out build/i386-kernel/retained-build-gen3-tcg-nofpu \
  --accel tcg --cpu 486,-fpu --command-timeout 7200
python3 tools/test-i386-retained-install.py \
  --source build/i386-kernel/retained-build-gen3-tcg-nofpu/source.img \
  --out build/i386-kernel/retained-install-gen3-tcg-nofpu \
  --accel tcg --cpu 486,-fpu
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-kernel/retained-install-gen3-tcg-nofpu/candidate.img \
  --retained-build-result build/i386-kernel/retained-build-gen3-tcg-nofpu/result.json \
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

### Explicit debugger session red/green

The revised frozen history checker now records both terminal results:
`build/i386-debug-session-history-red/result.json` fails on the old image's
absent Dbg publication; `build/i386-debug-session-history-green/result.json`
passes all seven commands on the console-34 debugger image. Checker SHA-256
64b6c039f8812a7d2697d4df7401301aa8d9fda72b8f46b4a2a7f37023ae5fdd is identical.
The green run verifies exact VGA for message/value/function, debugger expression
inspection, G continuation, restored console history, caller state and shell
arithmetic. It uses 8 MiB, 486,-fpu, boots in 56.72 seconds and preserves the
source disk. Exception/register/source inspection, breakpoint/stepping behavior,
nested error/resource recovery and complete M7 remain unqualified.

### Runtime exception inspection before compiler cleanup

Added `tools/test-i386-debug-exception.py`, frozen SHA-256
c649641431bcafa5d3f01d706b4f3b84222a7beb3812f166bc8d9c872003ca90.
The existing explicit-debugger image gives a publication red in
`build/i386-debug-exception-red/result.json`: DbgMode is absent. The new
contract requires original Probe exception text, ExceptionProbe function,
source link FL:Console.HC,1, visible state inspection, G-driven unwind and
shell recovery without executing the statement after throw.

Compiler input now has a typed, optional inspection callback invoked after its
catch returns and before its control is unwound. It saves/restores the original
exception frame pointer and caller trace around nested inspection. Callback
failure still reaches cleanup and reports an inspection diagnostic. The console
uses this hook when DbgMode is enabled, resolving a live executable allocation
and its canonical source link. Compiler/allocation errors and keyboard Break
are excluded from this first inspection path. DbgMode/IsDbgMode use the original
SEMA_DBG_MODE bit and setter returns the previous value. The retained module
updates that bit under the existing single-CPU IRQ guard; an initial cross-build
failed on undeclared LBEqu and is retained as a build failure, not a behavioral
red. Interfaces advance to compiler 59 and console 35.

Both original rebuild generations and the corrected cross-build/386 boot audit
pass. Image `build/i386-debug-exception-kernel-fixed/kernel.img`, SHA-256
e815c2160ae42d17108e2f74aa87c02e48c6e64eecfe7d5b8f823df7a5124fed.
Exception inspection and explicit-session regression checks are now running in
`build/i386-debug-exception-green` and `build/i386-debug-exception-explicit`.
Their runtime results are pending. Saved hardware registers, exact instruction
line mapping, zero-valued exception display, stepping/breakpoints and nested
resource/error paths remain unqualified; this does not close debugging or M7.

The earlier memory-16 focused-keyboard native pipeline now passes retained
build, installation, guest flat-kernel build and independent 8 MiB boot:
`build/i386-public-keyboard-focused-break-selfhost/result.json`. It uses all
six guest-built retained and all six guest-built flat modules, 16 MiB build RAM,
486,-fpu, and preserves its source. Target SHA-256:
a0e6763b903c230514d8b40b035e3a1abfd06c3127ceb6ddb84ce131b0b055ac.
The independent audit in
`build/i386-public-keyboard-focused-break-selfhost-audit/result.json` passes
all twelve executable module ranges, linked image, installed boot payload and
filesystem checks. The 487344-byte linked kernel leaves 80 bytes within the
487424-byte limit; further flat-kernel growth must be measured. This is one
qualified earlier epoch, not two current-source generations or release proof.
Current-source terminal/debugger integration, native generations and release
qualification remain open.

### Canonical exception source-link oracle and current native rebuild

The console-35 explicit-session regression passes in
`build/i386-debug-exception-explicit/result.json`: seven commands, exact VGA,
56.10-second startup, 8 MiB, 486,-fpu, unchanged source image.
The initial exception run reaches its debugger display but fails the expected
source-link row. Its preserved screenshot shows canonical
`FL:C:/Console.HC,1`; the fixture had incorrectly assumed a relative path.
Corrected the independent expected row to that canonical form without changing
kernel behavior. The revised frozen checker SHA-256 is
94bca5f0f13c21a37a2795f8a814cb6d660e56f010ddb3cf7a590f7e9227aade.
Matching baseline and implementation runs are live in
`build/i386-debug-exception-canonical-red` and
`build/i386-debug-exception-canonical-green`; their results remain pending.

Started the six-provider native rebuild for the captured compiler-59,
console-35, memory-17 image in `build/i386-debug-exception-retained`, comparing
against its exact cross-built exports. This is the next current-source native
qualification step; neither the earlier self-hosting pass nor the cross-build
proves these guest outputs before the run completes.

For the next multiple-terminal implementation, the existing source audit finds
that hardware delivery already targets sys_focus_task and queues are public
and task-owned. Console text, planar storage, command input and rendering
ownership are still singleton state. Use original UserCmdLine/UserTaskCont and
WinFocus semantics rather than inventing a separate terminal command model.
Each terminal must own its line buffer, display history and document state,
while HolyC definitions remain in its task symbol scope. Focus changes select
which display is presented, without cancelling another task's work. Required
visible tests must cover two live terminals with separate definitions/history,
background cooperative work, focus switching, document edits and exit/resource
reclamation. Keep display binding correct across compiler/document yields;
switching one global buffer only at command boundaries cannot meet the goal.
The native flat image's measured 80-byte headroom makes any scheduler/private
layout growth a boot-image sizing gate, not an assumption. Runtime exception
inspection, full debugging and the complete release remain open until their
matching behavioral and integration evidence is recorded.

### Runtime exception source inspection red/green

Both revised checker runs are terminal. The baseline fails on absent DbgMode;
`build/i386-debug-exception-canonical-green/result.json` passes all nine
commands with the identical frozen checker. It verifies Probe exception text,
ExceptionProbe function, canonical FL:C:/Console.HC,1 source link, live state
inspection, G-driven unwind, no execution after throw, mode restoration and
subsequent shell arithmetic. Exact VGA checkpoints pass and source remains
unchanged on 8 MiB, 486,-fpu. This qualifies the named exception/source workflow,
not saved registers, stepping/breakpoints, zero exceptions or complete M7.

### Two-terminal visible acceptance contract

Added `tools/test-i386-terminals.py`. It uses original UserCmdLine/WinFocus
interfaces and public Spawn/Exit rather than private queue or scheduler writes.
Two live terminals must display separate named histories, define the same
variable name with different values in independent task scopes, switch focus
and recover the first history/value, exit with visible refocus to the survivor,
then return to the root console. It checks both child-list reclamation and exact
parent public-heap recovery, followed by shell arithmetic. Expected VGA rows are
fixed independently of guest output. This initial contract excludes document
sessions, background compilation, all private resource pools and hotkey routing;
those remain mandatory integration extensions rather than implied passes.

The initial fixture validation rejected a source line over the 255-byte console
limit before boot. It is not a behavioral red. Split the parent wait helper so
all source lines fit (largest 218 bytes), and started the baseline in
`build/i386-terminals-red-v2`. Runtime result is pending. The implementation
must provide task-owned rendering/input state across cooperative yields and
teardown notification before task heaps/symbols are destroyed; keeping a list
of pointers to already freed task buffers cannot satisfy exit/refocus safety.
Existing keyboard delivery already follows the public focus pointer, but this
alone does not prove multiple usable terminals.
The compiler-59/console-35 six-provider native rebuild and memory-17 full
workstation run remain live for their captured images. The complete OS/M7 and
release objective remains open.

### Task-owned terminal implementation — runtime gate pending

The frozen two-terminal checker records a genuine baseline publication failure
in `build/i386-terminals-red-v2/result.json`; UserCmdLine/WinFocus are absent.
Checker SHA-256: 7ae586737c2e44ada32c8497983681988777723fb75d4796a95b2e3cd3980e26.

Console services advance to version 36. Added original public UserCmdLine,
UserTaskCont and WinFocus bindings. Terminal instances own their text surface,
planar storage, document, input-loop stack and keyboard-loss observation.
Renderer accessors select the current task's surface across cooperative yields;
background terminal display/mouse updates cannot overwrite the focused view.
Focus explicitly presents the selected terminal. The existing scheduler cleanup
hook releases/unlinks terminal state before compiler/symbol/heap teardown,
chains an earlier cleanup callback and refocuses a surviving terminal. Child
terminals own a public put_doc; root startup adopts the existing console display.
Keyboard discontinuity now discards pending keyboard messages for registered
terminals and the focused receiver while keeping unrelated jobs, and each
terminal observes the loss independently.

The first cross-build failed on NULL used before its declaration; a subsequent
build rejected structure member selection through the display-return expression.
Corrected the early default to 0 and used pointer member access at affected
renderer sites. Both original rebuild generations and the fresh corrected
cross-build/386 boot audit pass. Image:
`build/i386-terminals-kernel-pointer/kernel.img`, SHA-256
6051ee26f0405f92e4dc2682c9738ce5c30141c68a6a11d4e35156cad0e2f5d0.
The frozen terminal workflow and ordinary keyboard regression are running in
`build/i386-terminals-green` and `build/i386-terminals-keyboard`; runtime
qualification is pending, not inferred from publication or compilation.

This first implementation still needs visible workflow results, document and
background-work integration, hotkey/window-order behavior, failure/kill/resource
coverage and debugger/terminal interactions. Only one debugger session can
currently be active; exiting inside a debugger requires explicit teardown
coverage. UserTaskCont input-layer exception recovery and broader WinFocus
parity need further contracts. The earlier compiler-59/console-35 six-provider
build and memory-17 workstation run remain live on their distinct snapshots.
Current-source native generations and the complete M7/release gates remain open.

### Terminal test pacing and completed regression evidence

The initial terminal run passes separate displays, first-terminal definition
and focus switching, then its unpaced text action overflows the hardware queue.
The retained log records INPUT RESET before the truncated expression; this run
is a failure, not a terminal usability pass. The fixture now acknowledges each
four-character batch against independent expected VGA rows, matching the normal
console runner's input discipline. It retains every isolation, focus, exit and
heap assertion. Frozen checker SHA-256:
0ac80003e40b5a7983b7cfed7872a1745d593ca85f062fd8c4434b4cc6fa6344.
Matching baseline/current runs are live in build/i386-terminals-paced-{red,green}.
The dedicated intentional overflow checker is live in
build/i386-terminals-keyboard-loss; bounded-queue loss behavior remains a
separate required contract.

On the console-36 terminal image, ordinary keyboard behavior passes in
build/i386-terminals-keyboard (57.64-second startup). Explicit debugger and
named-exception regressions pass in build/i386-terminals-debug-session and
build/i386-terminals-debug-exception (59.05 and 59.35 seconds), with exact VGA
and unchanged disks. These focused results do not prove full terminal integration.
The preceding memory-17 registration-fix workstation run is now terminal PASS:
build/i386-public-macro-registration-workstation/result.json, 513 commands,
20 exact-heap-recovery document cycles, 55.56-second startup, 0.315-second
long-document update, 8 MiB and 486,-fpu. Updated the coverage audit's opening
snapshot summary to distinguish these epochs and the completed earlier native
self-hosted image. The full objective remains open.

### Two-terminal workflow green; Ctrl-Alt-N implementation pending runtime gate

The revised frozen terminal checker now records a matching baseline failure and
implementation pass in build/i386-terminals-paced-{red,green}/result.json.
The green run passes 11 parent commands and every child-terminal VGA checkpoint:
independent definitions/history, programmatic focus, exit/refocus, child-list
reclamation, exact parent public-heap recovery and shell arithmetic. It uses
8 MiB, 486,-fpu and an unchanged image, with 58.93-second startup.
The dedicated overflow checker also passes in
build/i386-terminals-keyboard-loss/result.json: exactly one root input reset,
queued CALL survives exactly once, Shift state resets and typing recovers.
Its frozen checker is c3e4e1b5bc9531095a0644d3144b5c68ea2fd339e57d21f7734530765462e201.
These results qualify image 6051ee26f0405f92e4dc2682c9738ce5c30141c68a6a11d4e35156cad0e2f5d0.

Added a separate hardware Ctrl-Alt-N contract in
`tools/test-i386-terminal-hotkeys.py`, SHA-256
f413ce423d6e1c5d237ad6d39f2bb9e4a173cb087a75ba5adce49b5c3591a23a.
The baseline in build/i386-terminal-hotkeys-red/result.json fails at its first
hotkey focus change; the saved screen remains on One with its definition intact.
The fixture requires visible One/Two/root cycling, independent histories and
values, exit/refocus and heap recovery. The runner now supports a focus-next
hardware chord alongside its existing break chord.

The keyboard worker handles Ctrl-Alt-N outside IRQ context, cycles eligible live
terminal records, consumes the N make/release pair and latches until release to
avoid repeated cycling while held. Keyboard discontinuity clears that latch.
Public service layout remains console 36. Both original rebuild generations,
fresh cross-build and 386 boot audit pass. Image
build/i386-terminal-hotkeys-kernel/kernel.img, SHA-256
444bfb1b7ee9de7e0ac6e4b609b2fd066798c649a9baec47a989165e81657229.
Hotkey behavior and ordinary keyboard regression are running in
build/i386-terminal-hotkeys-{green,keyboard}; no runtime pass is claimed yet.
Repeated-key, inhibited-window, creation-hotkey, document/background-work,
private-resource and debugger/terminal combinations need further coverage.
Current-source native generations, complete M7 and release qualification remain
open; the older console-35 six-provider native build remains live.

### Concurrent terminal document contract

Run the automated two-editor session on a disposable writable copy:

```sh
python3 tools/test-i386-terminal-documents.py build/i386-terminal-documents-kernel/kernel.img --out build/i386-terminal-documents-green
```

The checker copies the input to `OUT/session.img`, opens independent One/Two
DolDoc documents, types and saves different contents, cycles focus through root,
returns to each editor, revises and saves, and exits both editors and tasks.
VGA comparisons require named console headings after editor exit. The host then
reads the saved RedSea files and requires exactly `one!` and `two?`, each followed
by DolDoc's cursor byte 0x05. Parent public-heap recovery and a final shell answer
are required too. The original input image must remain unchanged.

Frozen checker SHA-256:
`e14a082848c68820bb5d47bd0951d1aadbfb782ec4df00d4a1823cfe0a9a90a8`.
The baseline in `build/i386-terminal-documents-red` fails at the first restored
console title; it displays the generic root heading. A task-aware heading fix
is under verification. This contract excludes sprites, mouse interaction,
restart persistence, abnormal cleanup and general background compilation.

The preceding Ctrl-Alt-N and ordinary keyboard checks are now PASS in
`build/i386-terminal-hotkeys-{green,keyboard}`, on the unchanged 444bfb1b image.

Heading-fix candidate: `build/i386-terminal-documents-kernel/kernel.img`, SHA-256
`58ab899923d48879c927e24be06c986436fb1ed4da04a9918ba5219c83dd060e`. Original two-generation rebuild, cross-build and
386 boot audit pass. Concurrent-editor green and root `document-editing`
regression runs are active; inspect their result files before claiming a pass.

### Concurrent text editors pass; idle terminal break contract

The frozen `test-i386-terminal-documents.py` passes in
`build/i386-terminal-documents-green/result.json` against image
58ab899923d48879c927e24be06c986436fb1ed4da04a9918ba5219c83dd060e.
All VGA checkpoints pass on 8 MiB with 486,-fpu, startup 57.34 seconds and
11 parent commands. Both named terminal headings survive editor exit; focus
returns to the surviving editor and then root. Exact parent public-heap recovery
and shell arithmetic pass. Independently read saved files are `/One.DD` =
`6f6e652105` and `/Two.DD` = `74776f3f05` (one! and two? plus cursor byte).
The source disk is unchanged. The original baseline fails at the first restored
terminal heading with the same checker hash. Root document-editing regression
continues in `build/i386-terminal-documents-editing`.

Added `tools/test-i386-terminal-idle-break.py`, frozen SHA-256
2c454f385cbb95b8cfd2de281114e35b5d74ca319598e36e372a075496e5c6b9.
It sends hardware Ctrl-Alt-C while One is idle after defining a variable, then
requires a usable prompt, the retained value, sibling isolation and ordinary
focus/exit/heap recovery. Baseline is running in
`build/i386-terminal-idle-break-red`; no result is claimed yet. The original
`Kernel/KTask.HC` UserTaskCont catches and reports exceptions before continuing
the input loop. The native wrapper currently propagates the idle-loop exception;
this is the next behavioral gap to verify and repair.

This does not close sprite/mouse concurrency, background compilation, abnormal
cleanup, full debugging, current-source native reproducibility or release gates.
The older console-35 provider build remains live in
`build/i386-debug-exception-retained` and cannot qualify the terminal changes.

### Idle terminal cancellation recovery

```sh
python3 tools/test-i386-terminal-idle-break.py build/i386-terminal-idle-break-kernel/kernel.img --out build/i386-terminal-idle-break-editor-green
```

The current checker (SHA-256
`6809b4786a85ea9a3f5d27b5e7ad811eb8593e6af1a03c3db28e6cb5d35e6051`)
sends two idle Ctrl-Alt-C chords. After each, it opens/closes a text editor and
checks the named terminal display; it then verifies retained state, sibling
isolation and task cleanup. Cancellation-message ordering is intentionally not
the oracle: IRQ exception delivery and decoded ^C can be observed in either
order. The initial checker found an unhandled Break/kernel failure. A revised
matching baseline is running in `build/i386-terminal-idle-break-editor-red`;
recovery runtime qualification is pending.

Idle-break paired red/green results now pass the recovery gate described above.
The candidate starts in 58.73 seconds on 8 MiB and 486,-fpu, with exact VGA and
unchanged source image. Existing interrupt regression is running in
`build/i386-terminal-idle-break-regression`.

### Background compilation with a foreground editor

```sh
python3 tools/test-i386-terminal-background.py build/i386-terminal-idle-break-kernel/kernel.img --out build/i386-terminal-background-session
```

Checker SHA-256: `7395f7f3e3a36667919ff1abd959a636576cb7e95a053ffd28c56c5efc472592`.
One repeatedly executes a HolyC document; Two edits/saves Work.DD. The check
requires compilation progress during the editor session, value 42 from compiled
code, exact foreground VGA, exact persisted `work` plus cursor byte 0x05, and
normal task/parent-heap cleanup. It uses a writable copy and verifies that the
source disk stays unchanged. Runtime result is pending. This is not a full-OS
background rebuild or exhaustive concurrency test.

The existing `breaks` group now passes 16 commands on the recovery candidate in
`build/i386-terminal-idle-break-regression` (57.88-second startup, 8 MiB, 486,-fpu).

### Forced terminal cleanup during editing

```sh
python3 tools/test-i386-terminal-kill.py build/i386-terminal-idle-break-kernel/kernel.img --out build/i386-terminal-kill-baseline
```

The checker kills One with a live unsaved editor from Two. It requires removal
from the parent's child list, continued editing/save in Two, exact saved bytes,
normal surviving-task exit and parent public-heap recovery. Checker SHA-256:
`35bb0e3e829e26615cbfca9c139c8a5c62a9d6a7f053cb5ae0a59925810cca8f`.
Baseline is running; no pass or failure is claimed yet.

The first background run passes all visible/file/cleanup checks, but its counter
interval also includes setup before editor entry. Use the strengthened checker
`9639f89b195407e6fe8167356455eedda056b0a43299f426b53f566ad047c96d` and output `build/i386-terminal-background-live-session`
for the stricter concurrency gate: a completed compilation must be observed
after the editor visibly opens and before it closes. This run is pending.

Forced-exit setup currently fails compiling the TermKill helper, before killing
a terminal. The revised checker `c849ea2bb51c8edb9f2b5de99b1580afb9adf7d46709ba891cf71b70080fa15a` explicitly checks
Kill publication first; its baseline is running in
`build/i386-terminal-kill-publication-red`. The initial setup failure does not
qualify actual forced cleanup behavior.

Root `document-editing` regression is now PASS: 169 commands with exact VGA,
57.34-second startup on the heading-fix image. The older console-35 native
provider build also passes all six modules. Installation/independent boot are
running in `build/i386-debug-exception-retained-install`; this source epoch
predates terminal changes and does not qualify current-source reproducibility.

The Kill publication baseline now fails explicitly. Original nine-case public
cancellation oracle passes in `build/i386-terminal-kill-original`. The new
memory-18 candidate will be checked with both the public cancellation corpus
and the frozen forced-editor-exit workflow. Self-break/I/O cancellation are not
covered by that corpus. The original two-generation rebuild passes; candidate
cross-build/runtime qualification is pending.

Console-35 retained installation/independent boot passed with all six guest-built
modules unchanged. The next native flat build/install is running in
`build/i386-debug-exception-selfhost`; it predates current terminal/Kill work.

The stricter background oracle now passes in
`build/i386-terminal-background-live-session`: 14 commands, exact VGA, a
completed compilation while the editor is open, compiled value 42, exact saved
bytes and parent heap recovery. Startup is 56.00 seconds on 8 MiB, 486,-fpu.

Kill candidate cross-build and 386 boot audit pass. Native qualification runs:

```sh
python3 tools/test-i386-public-task-kill.py build/i386-terminal-kill-kernel/kernel.img --out build/i386-terminal-kill-public
python3 tools/test-i386-terminal-kill.py build/i386-terminal-kill-kernel/kernel.img --out build/i386-terminal-kill-green
```

Both runs are active; runtime results remain pending.

The forced-editor workflow now passes on memory-18 image 201cb474: 13 commands,
56.62-second startup, exact VGA/Survivor.DD bytes and parent heap recovery.
The public cancellation corpus stopped earlier in setup because CH_SHIFT_ESC
was unpublished; the shared public character-code header now supplies it.

### Debugger ownership after forced terminal exit

```sh
python3 tools/test-i386-terminal-debug-kill.py build/i386-terminal-debug-cleanup-kernel/kernel.img --out build/i386-terminal-debug-kill-green
```

Frozen checker cc7aea1e4f2b9a08fc153e3f18ea30029bb5c748e7a51b5b20734607de23d76c
kills One inside Dbg and requires Two to enter Dbg, evaluate 42, G back and exit
with parent heap recovery. Baseline fails with DbgBusy in
`build/i386-terminal-debug-kill-red`. A chained task cleanup hook now owns the
debugger backup and releases it on forced exit; build/runtime qualification is
pending. This is not a register/stepping or exhaustive private-allocation test.

Corrected cleanup candidate build/audit passes:
`build/i386-terminal-debug-cleanup-kernel-fixed/kernel.img`, SHA-256
`9812e5d53b8ca91070c4f1f4f6d8b93e166bb45d57805efabfb59a945765ec85`. Four runtime checks are active: public Kill,
forced debugger exit, explicit Dbg/G and named exception inspection.

The older console-35 full guest build/install/boot passes in
`build/i386-debug-exception-selfhost` (487344 bytes, 16 MiB build/8 MiB boot,
486,-fpu, all twelve modules guest-built). Independent installed-image audit is
running; this source predates terminal/Kill changes.

Independent console-35 installed-image audit is now PASS in
`build/i386-debug-exception-selfhost-audit/result.json`: all twelve executable
module ranges satisfy the 386 allowlist, boot payload matches the guest-built
flat image and filesystem allocation matches reachable extents. This completes
that older source epoch's single-generation native build/install/audit pipeline.

Forced debugger exit, ordinary Dbg/G and named-exception regressions now pass
on cleanup image 9812e5d5. Full workstation integration and six native provider
builds are running on that immutable snapshot in
`build/i386-terminal-debug-cleanup-{workstation,retained}`.

### Zero-valued exceptions

`tools/test-i386-debug-zero-exception.py` throws zero and requires a runtime
exception heading, caller/source, pre-unwind state and G-driven shell recovery.
Frozen checker SHA-256:
`5469a779edf6feab6ddf853e54c0dabea68bb01bd12b05a3462b23e2ad3e4f2f`.
Baseline `build/i386-debug-zero-exception-red` is running. The implementation
now distinguishes a runtime exception from explicit Dbg independently of its
code; build/runtime qualification remains pending.

Zero-case baseline failed with Message/Value rather than exception/source UI.
The candidate in `build/i386-debug-zero-kernel` passes original rebuilds,
cross-build and 386 audit; image SHA-256 `0a90d205983f37f08cf8b47cd11a963dfeec026695c7e60f95c46e6372778608`.
Zero, named and explicit-session runtime checks are running.

The cancellation corpus needed an expected-output correction for the standalone
field assignment `KillState->stage=3;` (result 3). The original oracle now checks
that assignment value as well. Revised checker `bef6aaf3ca4afbd4c5d8baea9c520921781d2f01da9f25d4cd480b406c9ae564` is running in
`build/i386-terminal-kill-{original-value,public-value}`. Do not count the
previous mismatch as a cancellation implementation failure or as a full pass.

Zero-case baseline failed with Message/Value rather than exception/source UI.
The candidate in `build/i386-debug-zero-kernel` passes original rebuilds,
cross-build and 386 audit; image SHA-256 `0a90d205983f37f08cf8b47cd11a963dfeec026695c7e60f95c46e6372778608`.
Zero, named and explicit-session runtime checks are running.

The cancellation corpus needed an expected-output correction for the standalone
field assignment `KillState->stage=3;` (result 3). The original oracle now checks
that assignment value as well. Revised checker `bef6aaf3ca4afbd4c5d8baea9c520921781d2f01da9f25d4cd480b406c9ae564` is running in
`build/i386-terminal-kill-{original-value,public-value}`. Do not count the
previous mismatch as a cancellation implementation failure or as a full pass.

Revised native public Kill corpus passes 69 commands/nine cases. Zero, named and
explicit debugger regressions also pass. Their measured starts exceed the
60-second gate (62.19 seconds for Kill, 64.93/64.92/72.05 for debugger runs).
`build/i386-debug-zero-startup-budget.json` is a formal timing FAIL; do not
promote these functional passes as complete timing qualification.

New `test-i386-debug-mode.py` checks IsDbgMode inside Dbg and restoration of
prior false/true state; baseline is running in `build/i386-debug-mode-red`.
`test-i386-debug-mode-kill.py` additionally requires mode restoration after
forced debugger exit. Implementation and build verification are in progress.

Mode-state baseline fails with IsDbgMode == 0 inside Dbg. Candidate build and
386 audit pass, image SHA-256 `3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`. Run qualification:

```sh
python3 tools/test-i386-debug-mode.py build/i386-debug-mode-kernel/kernel.img --out build/i386-debug-mode-green
python3 tools/test-i386-debug-mode-kill.py build/i386-debug-mode-kernel/kernel.img --out build/i386-debug-mode-kill-green
```

Both are active; startup timing is still a separate open gate.

### Debugger mode verified; workstation collision and boot profile

Both mode-state checks pass on unchanged image
`3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`:
`build/i386-debug-mode-green/result.json` (13 commands) and
`build/i386-debug-mode-kill-green/result.json` (14 commands). Exact VGA verifies
active mode, normal restoration of prior false/true mode, and forced-exit
restoration with a surviving debugger task and parent public heap recovery.
No-FPU TCG, 8 MiB starts are 59.439 and 59.375 seconds.
`build/i386-debug-mode-startup-budget.json` passes for the first observation.
This does not supersede the earlier 62–72-second failures or establish
fully guest-built timing/reproducible release qualification.

`build/i386-debug-mode-boot-profile/result.json` records 608 statistical PC
samples on the same unchanged image. Heap allocation/free/size/validation
account for 146/166 public-header samples and 364/389 startup-source samples.
Caller stacks often involve identifier publication. The profiler pauses QEMU;
its duration is not a startup benchmark. Any optimization must preserve full
heap validation, exact string allocation sizes and atomic failure behavior.

The cleanup-snapshot full workstation run is terminal FAIL at compiler
command-105 (`build/i386-terminal-debug-cleanup-workstation/checkpoint.json`).
Its fixture declares `I64 G()` despite the now-public debugger `U0 G(...)`;
VGA shows Compilation failed. This run is not a full-suite pass. A focused
`tools/test-i386-forward-call.py` retains the forward declaration, call and
unresolved-extern recovery assertions with distinct ForwardValue/ForwardCaller
names and checks that public G remains present. Runtime verification is pending.
The shared workstation runner remains unchanged while the earlier native
provider build is live; update the colliding fixture before the next full run.

The focused forward-call check now passes all six commands with exact VGA on
unchanged mode image 3354b498. Evidence: `build/i386-forward-call-green/result.json`;
checker SHA-256 `1f2e0b7b47ef8057a5fb33fd7a0d42e17ee1969eb03456cb69498b180e7889cb`.
This verifies the distinct-name fixture without weakening forward-resolution
or failed-compilation recovery checks; it does not qualify the full suite.

### Both heap validators covered before startup optimization

Added `tools/test-i386.py --heap --heap-source`: it uses the existing heap
corpus with I386_HEAP_SOURCE_BUILD enabled, in a separate output directory.
The default --heap still tests the 386 assembly validator. Results explicitly
identify the selected validator. This cross-compiles the portable implementation;
it does not replace native self-hosted generation qualification.

Strengthened `tests/guest/i386-heap/Validation.HC`: for every invalid mutation
in the existing 160-case header/control matrix, size lookup, allocation,
zero-sized allocation and free must reject it without changing either the
arena or heap control record. Corruption after a valid early allocation is
included. The independent pre-optimization validator remains the oracle.
Both variants pass runtime and instruction audit in
`build/i386-heap-test/result.json` and `build/i386-heap-source-test/result.json`.
Validation fixture SHA-256: `ff2a93a30288f3ce23d23306e45e90a337250ff09f0f5868c5e4bafe2f746c36`.
No allocator optimization is claimed yet.

The full workstation fixture now uses ForwardValue/ForwardCaller instead of
redeclaring debugger G, preserving both forward-call and failed-compilation
recovery assertions. The focused six-command test already passed. The full
suite is running on mode image 3354b498 in `build/i386-debug-mode-workstation`;
no full-suite pass is claimed. The older cleanup-snapshot native provider build
continues with its already-loaded runner and immutable source/reference images;
changing the inactive workstation command list does not change that execution.

The scan implementation now passes both original rebuild generations and both
heap variants (`build/i386-heap-{source-test,test}/result.json`), including the
strengthened corruption rejection and public heap lifetime/churn corpus.
Cross-compiling the portable test produces 176416 bytes versus 176680 before
this change; this isolated test size is not the native boot-image size.
Fresh cross-build output is `build/i386-heap-scan-kernel`. Native flat build,
boot-area fit and performance qualification remain pending.

Fresh cross-build and 386 boot audit pass. Image SHA-256: `38fbbde26954101563a481fc2655157d7459dc7c40c06c3bd611318ba1c94bbd`.
A development native flat build is running in `build/i386-heap-scan-flat`,
using verified cross-built retained modules (`--cross-retained`). This run
will test guest compilation, boot-area fit and independent boot; it is not
full native-provider or two-generation self-hosting qualification.

### Portable heap scan: native build and installed-image audit pass

`build/i386-heap-scan-flat/result.json` passes: the guest compiler built all
six flat modules, assembled/installed them and booted the result independently
with 8 MiB and no FPU. The flat image is 487344 bytes (80 bytes spare), SHA-256
`31b085b97abae02e19df4f1506819f6fcb68a716b2ffb26db20e620baa2f4e69`.
Target disk SHA-256:
`ed51468756aac925962e33f885ce3534ae615c1957c8998d78caa682e595d142`.
The six retained providers remain verified cross-built development inputs;
this is not a fully guest-built generation.

`build/i386-heap-scan-flat-cross-retained-audit/result.json` passes all twelve
module executable ranges, boot ranges, installed-payload comparison and RedSea
reachable-extent/bitmap checks. The first audit invocation incorrectly selected
--guest-compiler-template and rejected the cross-built compiler layout; rerunning
with the correct default layout passes without changing the image or auditor.
The KVM boot measurement is not TCG budget evidence. A normal 8 MiB no-FPU TCG
keyboard/startup check is running in `build/i386-heap-scan-flat-keyboard`.

The normal no-FPU TCG keyboard check now passes exact VGA on unchanged target
ed514687, with a 56.21559963794425-second startup.
`build/i386-heap-scan-flat-startup-budget.json` passes the unchanged 60-second
budget. This qualifies this development-image observation, not a fully
guest-built release or a controlled before/after performance improvement.
The earlier over-budget observations remain valid for their recorded images.

### Current-source retained-provider qualification started

The guest-built flat image ed514687 now seeds the current-source six-provider
build in `build/i386-heap-scan-retained`. It uses the matching cross-built
export contracts in `build/i386-heap-scan-kernel/exports`, no-FPU QEMU/KVM and
16 MiB build memory. This is a separate source epoch from the still-running
cleanup-snapshot provider build; neither run is restarted or its inputs edited.

After a provider PASS, install those exact persisted modules with
`test-i386-retained-install.py`, boot the installed candidate, and run
`test-i386-selfhost-install.py` without --cross-retained. Audit the resulting
fully guest-built image using --guest-compiler-template, then measure TCG
startup/workstation behavior. A second native generation with installed-module
comparison is still required; starting this run does not satisfy that gate.

### Next TDD contract: public User terminal creation

Added `tools/test-i386-user-create.py` with a shared original/native contract:
empty terminal creation, formatted startup text executed in the created task,
Adam child-list membership, synchronous Kill removal and continued root use.
The corrected original x64 oracle passes in
`build/i386-user-create-original-fixed/result.json`. Checker SHA-256:
`521478343b9e2c2dcde494d5265c95d5ca48a31e81f38102467c73c85e10d71e`.

The first fixture wrongly assumed caller-owned children and inherited caller
symbols; original User uses Spawn with the default Adam parent. It also needs
a newline in the submitted text to execute it. The frozen contract now checks
Adam membership and uses formatted addresses to observe the child result and
identity. These are oracle corrections, not requested behavior changes.

The initial native baseline fails the publication assertion: User is absent
on unchanged development image ed514687. The corrected checker is running in
`build/i386-user-create-red-fixed`; no native behavior pass is claimed.
Implementation must preserve the full User(fmt, ...) API and default ownership.
Ctrl-Alt-T creation and visible terminal editing/focus remain separate follow-up
checks; passing the publication probe alone will not satisfy terminal creation.

### User dependency: original-backed formatted strings

The corrected User baseline is terminal FAIL at the publication assertion in
`build/i386-user-create-red-fixed/result.json`: User is absent on unchanged
ed514687. The original behavior contract passes. Implementation tracing found
that User requires formatted string generation and XTalk input delivery, neither
currently exposed by the native public API. Do not replace the full variadic
API with a fixture-specific formatter.

Added `tools/test-i386-format-strings.py`: 17 shared cases cover literals,
percent escaping, signed/unsigned/hex/binary, characters/strings, width,
zero-padding, dynamic width, precision, float output and mixed variadic values.
Allocated results are compared and freed. The original x64 oracle passes in
`build/i386-format-original-fixed/result.json`; checker SHA-256
`51a85c43b4b2f71eb5df828fadbda6d19fddcc93f63fc13a8cad117975a55b3f`.
These are selected cases, not complete TempleOS format-language coverage.

Observed original semantics correct three initial printf-based expectations:
%-5d with 42 gives three leading spaces and 42; %.3s leaves HolyC untruncated;
%f with 1.5 yields 2 unless a decimal precision is supplied. Those outputs are
now frozen in the oracle. Native baseline is running in `build/i386-format-red`.
Next implementation work must preserve original formatting and task ownership,
then provide User and hardware creation workflows; no implementation pass is
claimed by adding these tests.

### Shared original formatting core extracted

Moved the original string-building functions into `Kernel/StrPrintCore.HC`
and formatting flags into `Kernel/StrPrintTypes.HH`. `Kernel/StrPrint.HC`
includes the core and retains Print/PrintErr/PrintWarn console wrappers.
The moved function bodies were verified byte-for-byte against the preceding
revision, preserving Latin-1 characters. Both original rebuild generations
and all 17 original formatting cases pass in
`build/i386-format-core-original/result.json`. Fresh cross-build is running
in `build/i386-format-core-kernel`; no native formatting implementation pass
is claimed.

The native formatting baseline is terminal FAIL at missing MStrPrint in
`build/i386-format-red/result.json` (unchanged ed514687). Reusing the core
requires native address/function-segment formatting, IsRaw state and the
existing allocation, software math, date, file and DolDoc services. Preserve
those format families rather than limiting implementation to the current
17-case corpus. User/XTalk and hardware creation remain subsequent work.
The provider/workstation runs keep their captured pre-extraction images.

### Cleanup-snapshot native providers pass

`build/i386-terminal-debug-cleanup-retained/result.json` passes all six
persisted guest-built providers against the matching export contracts.
Source disk SHA-256:
`33fc78cf811e3d147578f06a3d367c7f99c8615b2d249d4dee250285a89567ee`.
Module sizes: Startup 407, MemoryRuntime 300832, FileRuntime 302036,
ConsoleRuntime 960074, CompilerProbe 1231080, CompilerRuntime 1738306 bytes.
This snapshot includes terminals, Kill and debugger task cleanup; it predates
zero-exception/mode restoration, the portable heap scan and formatter extraction.

Installation and independent boot are running in
`build/i386-terminal-debug-cleanup-retained-install` on a copy of the preserved
source. A full flat rebuild and installed-image audit must follow a PASS.
The newer heap-scan provider build and mode-image workstation suite remain
active. Do not combine their source epochs into a current-source release claim.

The cleanup-snapshot installation and independent no-FPU boot now pass in
`build/i386-terminal-debug-cleanup-retained-install/result.json`. All six
installed provider byte sequences match the persisted guest outputs; source
and candidate preservation checks pass. Candidate SHA-256:
`b863d402e0a63b8984575e192272a68c0ed3641648ea6fc58cba4fd1b501c246`.

A full flat-kernel build/install is running from that candidate in
`build/i386-terminal-debug-cleanup-selfhost`, without --cross-retained.
On success, independently audit all twelve module executable ranges and the
installed filesystem, then qualify the fully guest-built image. This still
uses the cleanup snapshot; it cannot certify subsequent mode/heap/formatter
changes or the required second native generation.

### Mode-image complete workstation suite passes

`build/i386-debug-mode-workstation/result.json` passes all 513 native commands
and 576 submitted lines with exact VGA, including 20 document development
cycles with exact task data/code heap recovery. Startup is
58.3255955548957 seconds; long-document input-to-visible-update latency is
0.3174466756172478 seconds. `build/i386-debug-mode-workstation-budget.json`
passes the unchanged 60-second startup gate. The visible-update measurement
also meets the one-second gate; this run does not replace the separate
interrupt-to-recovery latency workflow.

Unchanged image SHA-256:
`3354b49895533bb2267d8c840877fc609b780319911436463a9c28bd5f7e54a1`.
Runner SHA-256:
`3956a334692d4d9298f49b8cddd515ab0cb1f97a748bc32f78408d6c60101c51`.
The corrected forward-call fixture passes within the complete suite, alongside
compiler/math, window/graphics, keyboard/mouse, document/style/sprite/file
navigation and Help coverage. This image includes terminals, Kill, debugger
cleanup, zero exceptions and mode restoration. It predates portable heap-scan
and formatter extraction and uses cross-built modules. Fully guest-built
current-source two-generation and release qualification remain open.

### Cleanup snapshot: all twelve guest-built modules installed and audited

`build/i386-terminal-debug-cleanup-selfhost/result.json` passes the six-flat
module build, installation and independent 8 MiB no-FPU boot using all six
previously guest-built retained providers. No cross-retained development mode
was used. Flat size is 487344 bytes (80 bytes spare); flat SHA-256
`f4b4b6a5b707f0461c94b1a8abcdb57ec36d81991f04f89640b65636b95b03cc`.
Target disk SHA-256:
`239bacc0433422c21d936d179365f4db95f101f42d7d64087ea01e12bca6611d`.

`build/i386-terminal-debug-cleanup-selfhost-audit/result.json` passes all
twelve executable ranges, installed boot payload, boot instruction audit and
RedSea extent/bitmap checks with the guest-compiler-template layout selected.
Normal no-FPU TCG keyboard/startup verification is running in
`build/i386-terminal-debug-cleanup-selfhost-keyboard`. This is the newest
completed fully guest-built snapshot: compiler 59, memory 18, console 36,
including terminals/Kill/debugger cleanup but predating zero/mode/heap/formatter
changes. Second-generation and current-source release qualification stay open.

### Fully guest-built cleanup snapshot: startup budget fails

The ordinary no-FPU TCG keyboard/exact-VGA check passes on unchanged fully
native target 239bacc0 in
`build/i386-terminal-debug-cleanup-selfhost-keyboard/result.json`.
Its startup is 65.44467783393338 seconds.
`build/i386-terminal-debug-cleanup-selfhost-budget.json` explicitly FAILS the
60-second gate by 5.44467783393338 seconds. Do not promote the functional
pass as startup qualification or infer a proven cause from host concurrency.

The full workstation suite is now running on that fully guest-built target in
`build/i386-terminal-debug-cleanup-selfhost-workstation`. The newer heap-scan
provider build continues independently. Its eventual fully native image needs
its own timing measurement; the prior 56.216-second development result used
cross-built retained modules and cannot settle this gate.

### Heap-scan snapshot: guest-built retained providers pass

`build/i386-heap-scan-retained/result.json` passes compilation of all six
retained modules inside the no-FPU guest, module parsing and reference export
set checks, including the console allocation-wrapper check. Source disk SHA-256:
`d79d32be4350a6e991148d9e2fc87224ed453ad036938df2f79f3d48f78d73bb`.
Guest-built ConsoleRuntime is 960921 bytes, SHA-256
`9d71ebbc01f2e83c6333d7bde8af59b25713f4a9526afdb6f699ec5bdb6899df`.
The checker compares export sets, not binary equality to cross-built modules.

Installation and independent boot verification are running in
`build/i386-heap-scan-retained-install`, using a writable copy of that source.
Next, build/install all six flat modules using these guest-built providers,
audit the installed image, and measure its ordinary no-FPU TCG startup against
the unchanged 60-second gate. The development-image timing does not qualify
this fully native path. This snapshot includes heap-scan and debugger zero/mode
fixes but predates formatter extraction. The older cleanup snapshot's full
workstation suite remains live; neither run proves current-source release
qualification or two native generations.

### Shared formatter extraction: baseline verification complete

The original two-generation rebuild passes after extraction of the unchanged
formatter into `Kernel/StrPrintCore.HC`. All 17 original formatting cases pass
in `build/i386-format-core-original/result.json`. The cross-build and 386 boot
instruction audit pass in `build/i386-format-core-kernel`; its result records
source revision `2470ed94dcea403c6d56e37fd6b08463c9a90406`, a 483360-byte
kernel, and no boot test. These checks establish the refactor baseline only.
Native MStrPrint and User integration, creation hotkeys and their native green
workflow tests remain implementation work.

### Heap-scan snapshot: retained installation and independent boot pass

`build/i386-heap-scan-retained-install/result.json` passes installation of all
six guest-built retained providers, exact installed-byte comparisons and an
independent 8 MiB boot with `486,-fpu` under KVM. The preserved candidate disk
SHA-256 is `b232d79d555c828944558b47b4eaf77b96fef3ab8d66701ee8c185bf09ee16fa`.
Both source and candidate preservation checks pass.

The full native flat build/install is now running in
`build/i386-heap-scan-selfhost` against that candidate, without cross-retained
mode. After it completes, audit the installed executable ranges/filesystem and
measure no-FPU TCG startup. This remains the pre-formatter heap-scan snapshot;
current-source two-generation and release qualification remain open.

### Formatter port: 64-bit boundaries and allocation growth baseline

`tools/test-i386-format-strings.py` now contains 22 cases. The added cases
exercise signed I64 minimum/maximum, unsigned U64 maximum, hexadecimal output
spanning both 32-bit halves, and a 1024-character string that requires output
allocation growth. The growth helper compares every byte and frees both
buffers. All interactive definitions/commands remain below 256 characters.

All 22 cases pass on original TempleOS in
`build/i386-format-boundaries-original/result.json`. Checker SHA-256:
`8a701bcc987f57b91c53b2a4307c11f27b768b7050e5d714cf322e9b06a0be7f`.
The same checker fails on unchanged native development image ed514687 in
`build/i386-format-boundaries-native-red/result.json`: the initial HashFind
returns 0 on the captured VGA screen, so the expected 1 times out. Formatting
cases are not reached. This confirms the missing MStrPrint integration, not a
formatting mismatch; full format-language parity is still outside this corpus.
The native build/install and older cleanup workstation suite remain running.

### Heap-scan snapshot: all twelve guest-built modules and image audit pass

`build/i386-heap-scan-selfhost/result.json` passes the six flat-module guest
build/install with all six guest-built retained providers and independent
8 MiB `486,-fpu` boot (16 MiB build). No cross-retained mode was used. Target
SHA-256: `66819bf5b517d80a937bee1491022eea6988d021c7ad5edbbf64bff61c02e7ba`.
The flat payload is 487344 bytes (80 bytes spare), SHA-256
`f4b4b6a5b707f0461c94b1a8abcdb57ec36d81991f04f89640b65636b95b03cc`.
Its flat bytes match the earlier cleanup snapshot; this is not evidence of a
flat-kernel size or performance improvement from the heap work.

`build/i386-heap-scan-selfhost-audit/result.json` passes the twelve executable
ranges, installed boot payload and boot instruction audit, and filesystem
extent/bitmap checks with the guest compiler template selected. Ordinary
8 MiB no-FPU TCG keyboard/VGA verification is running in
`build/i386-heap-scan-selfhost-keyboard`; evaluate its own startup against the
unchanged 60-second gate. This is now the newest completed fully guest-built
snapshot, including debugger zero/mode fixes and predating formatter extraction.
Current-source two-generation, full workflow and release qualification remain
open. The older cleanup snapshot's workstation suite is still running.

### Fully guest-built heap-scan snapshot: functional boot passes, timing fails

`build/i386-heap-scan-selfhost-keyboard/result.json` passes ordinary keyboard
and exact-VGA checks on target 66819bf5 under 8 MiB `486,-fpu` TCG. Startup is
65.14852777728811 seconds. The unchanged checker explicitly FAILS the 60-second
gate in `build/i386-heap-scan-selfhost-startup-budget.json`, by
5.148527777288109 seconds. Evidence SHA-256:
`22e933ba0b10b538c31c2a2a8c9d260eec5e63de77c182008122accc90c7edfb`.

A QMP instruction-sampling run is now active in
`build/i386-heap-scan-selfhost-profile` on the unchanged fully guest-built image.
Use that image's installed modules for symbol attribution. Its paused elapsed
time is not a benchmark. Earlier cross-built/development timing and profiles
cannot establish the cause of this failure; the portable source heap change
also does not replace the boot kernel's assembly validator. Keep the startup
gate open while identifying the actual native bottleneck. The older cleanup
workstation suite continues through file navigation checks.

### Fully native boot profile identifies the active heap path

`build/i386-heap-scan-selfhost-profile/result.json` completes on unchanged
fully native target 66819bf5, with 656 statistical instruction samples and
installed-module symbol attribution. In the public-header phase, heap
Alloc/Free/Size/Valid account for 140 of 150 samples (52/39/29/20). During
startup source they account for 340 of 367 samples (92/84/79/85). Foundation
has 98 of 139 samples in I386ModuleValid. Profiler SHA-256:
`37f22fb8d7d18978097efc94002c0064fcd096eeb78c83cfc43e4bf43160dc34`.

The next performance change should target the active boot-kernel heap path,
whose assembly validator and subsequent size lookup still traverse separately.
Preserve complete-chain validation, rejection of later corruption, unchanged
arena/control on failure, and exact requested sizes. The portable source scan
alone did not change this path. Any implementation must fit the boot envelope
(current fully native flat image has only 80 spare bytes), pass both heap
variants and the independent corruption oracle, and then be measured on a
new fully native image. Do not interpret paused profile elapsed time as boot
timing or claim a speedup before that measurement. Native formatter/User
integration and the remaining full release requirements remain open.

### Boot-kernel heap size lookup shares the assembly validation scan

`Kernel/I386/Heap.HC` now uses I386HeapScan in both implementations. The
assembly path records a matching used allocation's requested size, continues
through every later block, and returns it only after aggregate validation.
This removes the second physical-chain traversal from I386HeapSize. Invalid,
foreign, freed and interior pointers still return -1; valid zero-size
allocations return 0. NULL remains invalid for size lookup and selects
validation-only behavior inside the shared scan.

The fresh original two-generation rebuild passes
(`build/heap-asm-scan-rebuild.log`). Both `tools/test-i386.py --heap` and
`--heap --heap-source` pass, including the independent corruption oracle and
rejection without arena/control mutation. The cross-build and 386 instruction
audit pass in `build/i386-heap-asm-scan-kernel`: 483088 kernel bytes, 272 fewer
than the preceding 483360-byte cross-build. Cross-build size is not a measured
fully guest-built size or performance improvement.

A guest flat build/install is running in `build/i386-heap-asm-scan-flat`, with
explicit verified cross-retained development inputs. After its audit and boot
checks, rebuild the retained providers in the guest and qualify a fully native
image against the unchanged startup gate. The old 65.149-second timing failure
is not cleared by these component passes. Formatter/User integration and the
remaining full release requirements are still open.

### Fully guest-built cleanup snapshot: complete workstation suite passes

`build/i386-terminal-debug-cleanup-selfhost-workstation/result.json` passes
all 513 native commands, exact VGA at every checkpoint, and 20 document
cycles with exact task data/code heap recovery. This run uses the fully native
cleanup target 239bacc0 and predates debugger zero/mode fixes, portable/assembly
heap-scan changes and formatter extraction. Long-document input-to-visible
latency is 0.2579392488114536 seconds, meeting the one-second gate.

Startup is 64.99476048490033 seconds;
`build/i386-terminal-debug-cleanup-selfhost-workstation-budget.json` FAILS the
60-second gate by 4.9947604849003255 seconds. Evidence SHA-256:
`31b18a438583b12c7b4624a982765717da8c74c276ff8c13a412fe5f4a23173e`.
The full functional pass must not be reported as timing or current-source
release qualification. The optimized assembly-scan guest flat build remains
running; its cross-built image is receiving a separate keyboard/startup check
in `build/i386-heap-asm-scan-cross-keyboard`. That development check cannot
substitute for fully native startup measurement.

### Assembly heap scan: cross-built normal boot meets the startup gate

`build/i386-heap-asm-scan-cross-keyboard/result.json` passes ordinary keyboard
and exact-VGA checks under 8 MiB `486,-fpu` TCG. Startup is
45.82201023912057 seconds; the unchanged 60-second checker passes in
`build/i386-heap-asm-scan-cross-startup-budget.json`. Cross-built disk SHA-256:
`4d57c57f5ee1751997c215f570580af2bb46a905ea40c660c89410c177fab1b0`.
This is evidence for the optimized cross-built snapshot, not a controlled
before/after speed comparison or a fully guest-built timing pass.

The complete workstation regression suite is now running on the same image in
`build/i386-heap-asm-scan-cross-workstation`. The guest flat build in
`build/i386-heap-asm-scan-flat` continues independently. Fully native retained
build/install, installed audit and its own startup measurement still follow;
the preceding native timing failure remains open until qualified replacement
evidence exists. Formatter/User and the broader release requirements remain
unfinished.

### Assembly heap scan: guest flat build, installation and audit pass

`build/i386-heap-asm-scan-flat/result.json` passes all six guest-built flat
modules, installation and independent 8 MiB no-FPU boot. This development run
uses verified cross-built retained providers. Flat size is 487072 bytes,
272 bytes smaller than the preceding native flat payload, leaving 352 bytes
in the boot envelope. Flat SHA-256:
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Target SHA-256:
`d0c5933b92d9a780247202003065216ddda1b10c7943277cbdfcc2837247487a`.

`build/i386-heap-asm-scan-flat-audit/result.json` passes executable ranges,
installed boot payload/boot instructions and filesystem extent/bitmap checks.
The default compiler template is appropriate here because retained providers
are cross-built. Native compilation of all six retained providers is now
running in `build/i386-heap-asm-scan-retained`, using this installed image and
`build/i386-heap-asm-scan-kernel/exports` for export-set checks. After installation,
rebuild the flat modules with those guest-built providers, audit with the guest
compiler template and measure fully native startup. The cross-image workstation
suite continues independently. No fully native timing pass is established yet.

### Assembly heap scan: complete cross-image workstation suite passes

`build/i386-heap-asm-scan-cross-workstation/result.json` passes all 513 native
commands, exact VGA at every checkpoint, and 20 document development cycles
with exact task data/code heap recovery. Startup is 46.07334640296176 seconds;
`build/i386-heap-asm-scan-cross-workstation-budget.json` passes the unchanged
60-second gate. Long-document input-to-visible latency is
0.255388590041548 seconds, meeting the one-second gate. Evidence SHA-256:
`da2f1ccbc3ff012bb202f0f5b7827d96a1f26c2aa6b511d91e962237811e90e8`.

This run qualifies the tested workflows on cross-built image 4d57c57f, with
the combined assembly heap scan. It does not establish fully guest-built
startup or current-source two-generation release qualification. The native
retained-provider build in `build/i386-heap-asm-scan-retained` remains active;
installation, fully native flat rebuild, audit and timing follow its completion.
Native formatter/User integration and the wider release requirements stay open.

### Assembly heap scan: all six retained providers compile natively

`build/i386-heap-asm-scan-retained/result.json` passes guest compilation,
module parsing, export-set checks and the console allocation-wrapper check
for all six retained providers. Source disk SHA-256:
`e809791978764b4258fc0ce0cea1c82041563125b88582ce580411bff6cf9e7d`.
The six output module hashes match the preceding heap-scan provider outputs;
the new optimization resides in the flat boot kernel, not those providers.
This is not yet a second complete native generation or release qualification.

Installation, exact installed-byte checks and independent no-FPU boot are now
running in `build/i386-heap-asm-scan-retained-install` on a writable source
copy. After that passes, rebuild/install the flat modules using these native
providers, audit the complete image with the guest compiler template, and
measure ordinary TCG startup against the unchanged 60-second gate. The source
snapshot includes formatter extraction but still lacks native formatter/User
integration and the other open release requirements.

### Assembly heap scan: native provider installation and boot pass

`build/i386-heap-asm-scan-retained-install/result.json` passes replacement of
all six retained providers, exact installed-byte verification, preserved
source/candidate checks and independent 8 MiB `486,-fpu` boot under KVM.
Candidate SHA-256:
`5bf3336394bb361ed6651b3ecd0f6eae2cbada01bb6f84be218bcd3761e91a18`.

The six flat modules are now rebuilding/installing with these native providers
in `build/i386-heap-asm-scan-selfhost`, without cross-retained development mode.
After completion, audit all twelve executable ranges and installed filesystem
with the guest compiler template, then measure ordinary no-FPU TCG startup.
The cross-image timing pass does not replace that measurement. This snapshot
still lacks native formatter/User integration, and current-source two-generation
and complete release qualification remain open.

### Assembly heap scan: complete native image builds, installs and audits

`build/i386-heap-asm-scan-selfhost/result.json` passes all six guest-built flat
modules using all six guest-built retained providers, installation and independent
8 MiB `486,-fpu` boot (16 MiB build). No cross-retained mode was used.
Flat payload: 487072 bytes, 352 bytes spare, SHA-256
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Target SHA-256:
`9c74ad0a40623d6d383caaf786cdb4f99251080d3b14e0b0b3bc01c59ff0cd5a`.

`build/i386-heap-asm-scan-selfhost-audit/result.json` passes all twelve
executable ranges, installed boot payload and boot instructions, and filesystem
extent/bitmap checks with the guest compiler template selected. Ordinary 8 MiB
no-FPU TCG keyboard/VGA and startup measurement are now running in
`build/i386-heap-asm-scan-selfhost-keyboard`; assess the unchanged 60-second gate
on that result. The 46-second cross-image timing does not substitute for it.
This is the newest completed fully native snapshot. A second complete native
generation, current-image workflows, native formatter/User and full release
qualification remain open.

### Fully native assembly heap scan: normal startup gate passes

`build/i386-heap-asm-scan-selfhost-keyboard/result.json` passes ordinary
keyboard and exact-VGA checks on fully native target 9c74ad0a under 8 MiB
`486,-fpu` TCG. Startup is 53.687440753914416 seconds. The unchanged 60-second
gate passes in `build/i386-heap-asm-scan-selfhost-startup-budget.json`.
Evidence SHA-256:
`0a0d909232de33aa5eeabe57bac7ad377a7d9a29a452bac07441d41edc5fac27`.
This qualifies normal startup on the optimized fully native snapshot; the
older 65-second failures remain historical evidence, not this image's verdict.

The full workstation suite is running in
`build/i386-heap-asm-scan-selfhost-workstation`. A second-generation retained
build is running from the fully native target in
`build/i386-heap-asm-scan-gen2-retained`, with exact comparison against the
installed providers enabled. Continue through native installation, flat-module
rebuild, complete image audit and second-generation workflow checks before
claiming two complete generations. Native formatter/User, broader debugging
and the other full release requirements remain open.

### Fully native assembly heap scan: complete workstation and timing pass

`build/i386-heap-asm-scan-selfhost-workstation/result.json` passes all 513
native commands/576 submitted lines on fully native target 9c74ad0a, with
exact VGA and 20 document cycles with exact task data/code heap recovery.
Startup is 53.786390606779605 seconds; the unchanged 60-second checker passes
in `build/i386-heap-asm-scan-selfhost-workstation-budget.json`. Long-document
input-to-visible latency is 0.2600506618618965 seconds, meeting its one-second
gate. Evidence SHA-256:
`8246e118b853e16070edf2a6248f2b48dd1806c3c276006fcd71c0bacf4f7207`.

The writable three-boot DolDoc save/reboot/reopen/re-execute workflow is now
running in `build/i386-heap-asm-scan-selfhost-doldoc`. The second-generation
retained build continues independently. The workstation pass does not replace
persistence, second-generation, full API/debugger or reproducible-release
qualification; native formatter/User integration remains unfinished.

### Fully native DolDoc persistence and recovery pass across three boots

`build/i386-heap-asm-scan-selfhost-doldoc/result.json` passes on an unchanged
source target 9c74ad0a using a writable candidate: 107 create/edit/save commands,
56 reopen commands and 15 revised-document commands, with exact VGA throughout.
All three 8 MiB no-FPU boot measurements are below 60 seconds:
53.71624059788883, 54.01201851526275 and 53.9515840052627 seconds.
Interrupt-to-recovery VGA latency is 0.2707137567922473 seconds.

Saved programs reopen and execute after reboot; revisions persist across the
third boot. The independent filesystem walker verifies 18 directories,
874 files and 18522 owned sectors, with bitmap matching reachable extents,
including rename/delete, cross-directory move and directory lifecycle checks.
Final writable candidate SHA-256:
`543ecd0856e4c9237fff73e12c5669834b038a254c25c9fb6605dafc154abaf9`.

Actual speaker-output verification is now running on the preserved fully native
source in `build/i386-heap-asm-scan-selfhost-speaker`. The second-generation
retained build continues. These workflow passes do not close native formatter/User,
complete debugger/API support, second-generation or reproducible-release work.

### Fully native speaker waveform and silence verification pass

`build/i386-heap-asm-scan-selfhost-speaker/result.json` passes on target
`9c74ad0a40623d6d383caaf786cdb4f99251080d3b14e0b0b3bc01c59ff0cd5a`
under 8 MiB `486,-fpu` TCG. Independent analysis of 44100 Hz mono PCM
finds stable 440 Hz then 880 Hz tones. Both settled off/reset intervals
emit zero new WAV bytes over at least 1.5 seconds each. All four sound
commands pass exact VGA checks; the source image remains unchanged.
Captured WAV SHA-256:
`5c7dbbbfb54f7fe2b92227e27f90a02227e2c4d7f1fc53e6a6b629002bf51905`.
Checker SHA-256:
`c6a6d41106cac752a742e16871bb0452b10ad15a1189aa58504a6e309532e4f0`.

This verifies emulated speaker output on the current fully native image.
Physical hardware verification remains deferred. The second-generation retained
build is still running with exact installed-provider comparison enabled;
installation, flat rebuild and complete second-generation qualification remain
pending. Native formatter/User, complete debugger/API support and reproducible
release work also remain open.

### Second-generation compiler publication hits contiguous-space exhaustion

The second-generation retained build reaches compiler module publication but
reports `FILE WRITE mutation error` and `BUILD MODULE REJECT` at stage 8,
with compiled size `0x1A8642` (1738306 bytes). No pass is claimed; the harness
is still awaiting its expected success response.

Read-only inspection of `build/i386-heap-asm-scan-gen2-retained/source.img`
finds 6749 free sectors but a largest contiguous run of only 2169 sectors.
The compiler output requires 3396 contiguous sectors. The original native
source target had 12210 free sectors and a largest run of 6451 sectors.
The independent `verify_mutated_volume` walker passes on both images:
source 16 directories/857 files/18501 owned sectors; build candidate
16 directories/862 files/23962 owned sectors, with allocation bitmap matching
reachable extents. The five earlier retained outputs consume the available
large runs before compiler publication. This is a build-space/fragmentation
failure, not evidence of a successful second generation or bitmap corruption.

Next investigate intermediate-file lifetimes and contiguous build workspace
requirements, preserve the failed candidate, and fix the build workflow or
image layout before retrying. Retain exact installed-module comparison and
complete installation/boot/audit checks; do not waive the two-generation gate.

### Retained rebuild schedules larger modules first

The default retained-build workflow now orders independent modules by descending
installed byte size before compiling them. RedSea requires contiguous extents;
writing small outputs first had consumed the runs needed by the final compiler
output. Explicit `--module` order remains unchanged, and successful reports
record `module_order`. Exact module bytes, export checks and installation gates
are unchanged. This mitigates build-output fragmentation; it does not add
filesystem compaction or guarantee success on an arbitrarily fragmented disk.

The failed guest had returned to its prompt after rejecting publication. Its
harness was explicitly interrupted (exit 130) instead of waiting for the
remaining success-response timeout; the failed image is preserved. A fresh run
from the unchanged native target is active in
`build/i386-heap-asm-scan-gen2-largest-first`, with exact installed-module
comparison enabled. Python compilation and diff whitespace checks pass;
guest build success remains unproven until this new run completes.

### Compiler-first retry publishes a byte-identical native compiler

The active `build/i386-heap-asm-scan-gen2-largest-first` run successfully
publishes `RetainedCompilerRuntime.t32m` and advances to `CompilerProbe`.
An independent read of the saved compiler output compares equal, byte for
byte, with the installed first-generation compiler: 1738306 bytes, SHA-256
`c99504863728b790424f1ed6b182f2223cf47fe1a06642113af57b7a3c6abd75`.
The earlier compiler-publication space failure is avoided with this ordering.
The remaining five provider builds, complete comparison, installation and
flat-kernel rebuild are still pending; this is not a complete two-generation pass.

### Second-generation retained providers all match installed native bytes

`build/i386-heap-asm-scan-gen2-largest-first/result.json` passes all six
retained builds, export contracts and console allocation-wrapper checks.
Every generated provider matches its installed first-generation counterpart
byte for byte on native target 9c74ad0a. Build order is CompilerRuntime,
CompilerProbe, ConsoleRuntime, FileRuntime, MemoryRuntime, Startup.
The larger-first schedule avoids the earlier contiguous-space failure on
this source image without changing the outputs or relaxing comparison.

Build candidate SHA-256:
`d7d93fef0589291f7a340ec5f700f939427c3a92deaf49c9a41904a5ce5c02b6`.
The independent filesystem walker passes: 16 directories, 863 files,
27358 owned sectors, allocation bitmap matching reachable extents.
Installation and independent 8 MiB no-FPU boot verification are running in
`build/i386-heap-asm-scan-gen2-largest-first-install`. Native flat rebuild,
complete installed-image audit and second-generation workflows still need
qualification. This provider-level reproducibility pass does not close the
complete two-generation or release requirements.

### Second-generation retained installation and independent boot pass

`build/i386-heap-asm-scan-gen2-largest-first-install/result.json` passes
installation of all six native providers with exact byte preservation and
removal of their build-output paths. An independent writable boot copy runs
`6*7` and `DocAllocationCheck` successfully under 8 MiB `486,-fpu` KVM.
Preserved source and candidate images remain unchanged by that boot test.
Installed candidate SHA-256:
`c516f9595a43f8626b0b4163ad048f483af64b798bb8859bf4998a5d78e8774b`.

The six flat-kernel modules and guest boot image are now rebuilding from this
candidate in `build/i386-heap-asm-scan-gen2-selfhost`, without cross-retained
inputs. Complete installed-image audit, first/second-generation flat-output
comparison and second-generation workflow qualification remain pending.
Native formatter/User, full debugger/API coverage and reproducible release
qualification remain open.

### Second-generation native kernel, exact comparison and image audit pass

`build/i386-heap-asm-scan-gen2-selfhost/result.json` passes all six native
flat-module builds, guest boot-image link/install and independent 8 MiB
`486,-fpu` boot (16 MiB build). All six retained inputs were guest-built.
Target disk SHA-256:
`44ed8c88293ff940fd2c1c73837424c62bd9b4224e4479723a2505aa7c3c5043`.

Direct comparison in `build/i386-heap-asm-scan-gen2-selfhost/comparison.json`
proves all twelve module files and `/Probe/GuestBoot.bin` byte-identical to
the first generation. The flat image is 487072 bytes (352 spare), SHA-256
`f7afe15704d130b47025deed2b46fd50b67c9d5acd377ce5984520e7e83e16cb`.
Whole disk hashes differ because filesystem allocation/layout differs; this
is executable-output reproducibility, not a reproducible release disk claim.

`build/i386-heap-asm-scan-gen2-selfhost-audit/result.json` passes installed
386 executable/boot-payload/boot-instruction and filesystem checks using the
guest compiler template. The full second-generation workstation suite is
running in `build/i386-heap-asm-scan-gen2-selfhost-workstation`. Startup and
interaction budgets, persistence and audio still need current-generation
qualification. Native formatter/User, full debugger/API support and release
packaging remain open.

### Second-generation complete workstation and timing gates pass

`build/i386-heap-asm-scan-gen2-selfhost-workstation/result.json` passes
513 native commands/576 submitted lines with exact VGA checkpoints on the
second-generation target 44ed8c88 under 8 MiB `486,-fpu` TCG. Twenty bounded
document development cycles recover exact task data/code heap use.
Startup is 54.769869497045875 seconds; the unchanged 60-second gate passes
in `build/i386-heap-asm-scan-gen2-selfhost-workstation-budget.json`.
Long-document input-to-visible latency is 0.3696982068940997 seconds,
meeting the one-second gate. Evidence SHA-256:
`25fe22b771449b43d79f3c44f935b330a4b7684e5791050937749fc2fc1556d8`.

The writable three-boot persistence workflow is running in
`build/i386-heap-asm-scan-gen2-selfhost-doldoc`. Second-generation persistence
and actual speaker-output qualification remain pending. Byte-identical native
executables and these workstation passes do not close native formatter/User,
full debugger/API support or reproducible release packaging.

### Second-generation three-boot DolDoc persistence passes

`build/i386-heap-asm-scan-gen2-selfhost-doldoc/result.json` passes 107
create/edit/save commands, 56 reopen commands and 15 revision checks across
three independent 8 MiB no-FPU boots, with exact VGA throughout. Startup
measurements are 56.57473006192595, 53.96432991186157 and
53.91442803107202 seconds, all below 60 seconds. Interrupt-to-recovery VGA
latency is 0.26818493101745844 seconds.

Saved programs execute after reboot and revisions persist through the third
boot. The independent filesystem walker verifies 18 directories, 874 files,
18522 owned sectors and bitmap equality with reachable extents, including
rename/delete, cross-directory move and directory lifecycle checks. Source
44ed8c88 is unchanged. Final writable candidate SHA-256:
`c9bf56e972295b4eb298ac81c3f8ca477ae9978a9e71fdba32761114eb36549b`.

Actual speaker-output verification is running in
`build/i386-heap-asm-scan-gen2-selfhost-speaker`. Native formatter/User,
complete debugger/API support and reproducible release packaging remain open.

### Second-generation speaker output passes; two native generations qualified for existing workflows

`build/i386-heap-asm-scan-gen2-selfhost-speaker/result.json` passes on
unchanged target 44ed8c88 under 8 MiB `486,-fpu` TCG. Independent 44100 Hz
PCM analysis observes stable 440 Hz then 880 Hz tones. Settled off/reset
intervals each emit zero new WAV bytes over at least 1.5 seconds; all four
sound commands also pass exact VGA. Startup is 53.91643884219229 seconds.
Captured WAV SHA-256:
`53e42268f35d41ef9b3f5fa84f826bef07f800ede20304d30596058f9063fd03`.
Checker SHA-256:
`c6a6d41106cac752a742e16871bb0452b10ad15a1189aa58504a6e309532e4f0`.

Both native generations now pass the existing workstation, startup/latency,
three-boot persistence and actual emulated-audio workflows. All twelve native
modules and the linked boot image are byte-identical between generations;
whole disk layouts differ. This completes the current snapshot's two-generation
workflow verification, not the full OS objective. Native original formatter
and User/task-creation integration, full debugger/API behavior and reproducible
release disk/environment/packaging work remain required. Physical hardware
verification stays deferred. Next resume native formatter integration against
the original-HolyC oracle and existing failing native tests.

### Original formatter oracle adds TempleOS-specific semantics

`tools/test-i386-format-strings.py` now checks 30 cases, adding null strings,
packed multi-character `%c`, packed uppercase `%C`, explicit `%3ts` truncation,
comma-separated decimal/hexadecimal, zero-delimited `%z` list substitution and
dynamic floating precision. These augment integer boundaries, buffer growth
and variadic checks without replacing the original formatter semantics with
C printf assumptions. Maximum submitted line remains 184 bytes.

`build/i386-format-temple-semantics-original/result.json` passes all 30 cases
on original x64 TempleOS. Checker SHA-256:
`63502c1faf82e0f411f90e1c5cf8159c20e70e9d135731eb7711ce239fd97ab5`.
The same native oracle is running against second-generation target 44ed8c88
in `build/i386-format-temple-semantics-native-red`; native MStrPrint remains
unintegrated, so a native pass is not claimed. Continue connecting the shared
original formatter and its symbol/raw-mode dependencies, then implement User
and task creation while preserving the original programming model.

### Current native formatter oracle remains red at API availability

`build/i386-format-temple-semantics-native-red/result.json` fails on preserved
second-generation target 44ed8c88 with checker 63502c1f. The initial
`HashFind("MStrPrint",Fs->hash_table,HTT_FUN)!=0` check does not produce the
expected success value; the harness times out at startup-command-00. The
30 formatting cases are not reached. The same checker passes all 30 cases
on original TempleOS. Native formatter integration therefore remains required.

Source inspection confirms `%p`/`%P` call original `StrPrintFunSeg` and `%P`
uses `IsRaw` to select linked output. Preserve original nearest-symbol lookup,
function/export distinction, offset/truncation formatting and display-mode
behavior when adding the native dependency bridge; do not replace it with
only the existing debugger's function-allocation lookup.

### Shared original symbol lookup and pointer-formatting cores

`Kernel/FunSeg.HC` now includes `FunSegLookupCore.HC` for HasLower and
HashFunSegFind, and `StrPrintFunSegCore.HC` for StrPrintFunSeg. Both extracted
bodies are byte-preserved; expanding the two includes reproduces the previous
file exactly. Architecture-dependent task scanning and cache management remain
in FunSeg.HC. This prepares reuse of original nearest-symbol selection and
pointer formatting by the native formatter without duplicating their behavior.

The original two-generation compiler/kernel rebuild passes in
`build/rebuild-test/result.json` (log `build/formatter-symbol-core-rebuild.log`).
The formatter oracle now has 34 cases, adding function pointer name+offset,
comma-mode name-only output and both null-pointer forms. All 34 pass on original
TempleOS in `build/i386-format-symbol-core-original/result.json`.
Checker SHA-256: `015cd3c5ca7f7569a4a6c53922772c82affd28c7f9f2fff5587142e66ad48285`.
Native integration is still pending; these extraction and original-oracle
passes do not imply native MStrPrint availability.

### Shared original function-symbol cache

`Kernel/FunSegCacheCore.HC` now contains the original FunSegCacheAdd and
FunSegCacheFind bodies. Expanding its include in FunSeg.HC reproduces the
previous source byte for byte, including cache bounds, timestamp handling,
name copying and the SYS_IDLE_PT special case. This completes extraction of
the reusable lookup, cache and pointer-formatting bodies; native task scanning,
code-address validation, clock/display adapters and formatter publication
still need implementation. No native formatting pass is claimed.

Validation: both original compiler/kernel rebuild generations passed in
`build/rebuild-test/result.json`, with the new shared source included in the
source hashes (log `build/formatter-cache-core-rebuild.log`). All 34 original
formatter cases passed in `build/i386-format-cache-core-original/result.json`
(log `build/format-cache-core-original.log`).

### Native original task display-mode query

The original IsRaw body is byte-preserved in `Kernel/IsRawCore.HC`, included
by both KMisc.HC and the retained i386 console. The native console publishes
`_IS_RAW`, and PublicWindow.HH exposes the original IsRaw API. It queries the
current task's DISPLAYf_NOT_RAW flag; this does not implement Raw switching
or establish rendering parity. Console service version stays 36 because its
service-record ABI and existing exports are unchanged; the new export is additive.

The original two-generation compiler/kernel rebuild passes in
`build/rebuild-test/result.json` (log `build/israw-core-rebuild.log`). The new
cross-build/386 instruction audit passes in `build/i386-display-query-kernel`;
boot kernel size remains 483088 bytes, with no new import binding. Its native
display-query test is recorded below after completion.

`tools/test-i386-display-query.py` checks API availability on the native target,
current-task mode queries in both flag states, restoration and continued HolyC
execution. Its helper restores the full display flags before returning. The
original six-case oracle passes in `build/i386-display-query-original`.
The formatter oracle now has 36 cases, adding allocated `%P` output in raw
and windowed modes. All 36 pass on original TempleOS in
`build/i386-format-display-mode-original/result.json`, checker SHA-256
`9ce7ae6d6d5df079308725ce52be7f9320aadf3922e0d0f3746b8af7eea34c9c`.
Native MStrPrint, formatter symbol scanning/cache integration, and full User
creation behavior remain required; these tests do not establish their completion.

The native display-query oracle passes on an 8 MiB `486,-fpu` QEMU boot in
`build/i386-display-query-native/result.json`; its source disk is unchanged.
Checker SHA-256: `f78b2368525c9b3786c3a82331f61ea860eb8a80dd1184e8109af7bb30949bea`.

### Original formatter integrated into the native console

The retained console now includes the original StrPrintCore and shared
FunSeg lookup/cache/pointer-formatting bodies. PublicFormat.HH exposes
StrPrintJoin, StrPrint, CatPrint and MStrPrint through four additive console
exports. The boot loader binds the existing public MSize and software-math
providers plus the hexadecimal bitmap and native idle entry. FunSegFind adapts
original nearest-symbol selection to the single-CPU task ring and mapped
bootstrap/public-pool regions; the cache retains its original timestamp and
name/offset behavior. Its private clock reads native jiffies atomically.
The shared cache class body remains unchanged in FunSegTypes.HH.

The formatter's file-read adapter copies service-owned bootstrap buffers into
task allocations that the original formatter can release with Free. It releases
the borrowed buffer before propagating allocation failure. Native display-mode
queries continue to use the original IsRaw body. The original infinity macro's
Latin-1 byte is present in the native compilation scope.

The two-generation original compiler/kernel rebuild passes (log
`build/native-formatter-infinity-rebuild.log`). Cross-build/386 instruction audit
passes in `build/i386-native-formatter-bound-kernel`, with 484384 flat boot bytes.
The 39-case original oracle passes in `build/i386-native-formatter-original-39`.
The same oracle passes on the cross-built port in
`build/i386-native-formatter-native-39/result.json`: 43 submitted commands,
8 MiB, 486,-fpu, ordinary boot, startup 46.61360586201772 seconds, unchanged
source disk. Checker SHA-256:
`c72bfd6d7a6668ef180012396407efe97b4b12191bcd3c07e00a48e40bfcc0a6`.
Cases cover growth, variadic arguments, integer boundaries, TempleOS-specific
formatting, pointer names/nulls, allocated %P in both display modes and signed
infinity. Original %e infinity uses eleven leading spaces; the oracle records
that behavior. This selected coverage does not establish every format/API case.

The native console source rebuild and full workstation regression are running
in `build/i386-native-formatter-console-selfbuild` and
`build/i386-native-formatter-workstation`. Their terminal verdicts will be
recorded separately. New all-native boot-image size, provider installation,
full formatter coverage, User creation, debugger completion and reproducible
release packaging still require verification/work. Hardware checks stay deferred.

The expanded 41-case formatter oracle also checks fixed-buffer StrPrint plus
CatPrint and direct StrPrintJoin with explicit argument slots. It passes on
original TempleOS (`build/i386-native-formatter-original-41`) and the cross-built
port (`build/i386-native-formatter-native-41`): 47 commands, unchanged source
image, 8 MiB 486,-fpu, startup 48.1894694827497 seconds. Checker SHA-256:
`30b0b9048a1b5f317a6c64909eb198476c24e1233e368093e1e0b75f231aa8de`.

The console now builds inside the port in
`build/i386-native-formatter-console-selfbuild/result.json`: 1077946 bytes,
3357 records and 340 function exports, including all four string APIs and IsRaw.
Installation passes in `build/i386-native-formatter-console-install/result.json`,
with byte-identical replacement and independent 8 MiB boot/DocAllocationCheck.
The installer accepts explicit --module-file MODULE=/PATH mappings so the
standalone console build's /Probe/RetainedConsole.t32m can be installed without
renaming or rebuilding it. Default retained-provider paths remain unchanged.
Native console SHA-256:
`0e6ee740c769fd4d3e779e0edc9420e7afd5c354f6c0960835950d2ec94a571e`.
Candidate disk SHA-256:
`38676a4aa1985dbff2cb8b68fd415e5098bd3e590ec26024fef640479a969271`.

All 41 formatter cases pass again with that installed native-built console in
`build/i386-native-formatter-installed-41/result.json`, on 8 MiB 486,-fpu with
the source disk unchanged. The twelve-module instruction audit passes with
this native console and the remaining cross-built components in
`build/i386-native-formatter-console-audit/result.json`. This mixed-provider
image does not replace the previously fully qualified all-native generation.

The full workstation suite remains active. A native Kernel source build is
also running in `build/i386-native-formatter-kernel-selfbuild`; its result will
measure the updated boot payload against the existing BIOS reservation before
claiming a new all-native installation. Preserve these jobs/evidence and poll
existing handles before starting additional builds.

The full workstation regression now passes on the cross-built formatter image
in `build/i386-native-formatter-workstation/result.json`: 513 native commands,
576 submitted lines, all VGA pixels matched, 20 document-session resource
cycles with exact shared-task data/code heap recovery. This broad check covers
the existing console/compiler, software math, graphics, document editing,
filesystem and navigation workflow; it does not replace verification of an
updated all-native release image. The native Kernel build remains active.

### Native formatter kernel exceeds the current boot reservation

The native Kernel source build finishes successfully in
`build/i386-native-formatter-kernel-selfbuild/result.json`, using the installed
native-built console: module 539549 bytes, SHA-256
`22e6ad401690d7077b9b0751873724c8f6a4af9054d99546b6fc1b672e3377fa`.
Its linked payload with the five cross-built boot helpers is 488256 bytes,
832 above the existing 487424-byte BIOS reservation. This source-build pass
is not a boot-image pass. Do not enlarge the reservation without checking the
boot stack/memory layout.

KernelConsoleLoad now uses a fixed 14-byte global binding-index table, matching
the other service loaders, instead of generating fourteen stack assignments.
The symbol indices and imported providers remain the same. Original two-
generation rebuild passes (log `build/native-formatter-binding-table-rebuild.log`).
Cross-build and native-size verification of this compaction are pending.

The original User creation oracle passes on the current bootstrap in
`build/i386-formatter-user-original`. The same checker fails on the installed
native formatter image in `build/i386-formatter-user-native-red`: User is absent
at the initial availability check, so creation cases are not reached; the source
disk is unchanged. Checker SHA-256:
`521478343b9e2c2dcde494d5265c95d5ca48a31e81f38102467c73c85e10d71e`.
After the boot-size gate, implement User with the original default Adam/CPU-root
parent, terminal-readiness handshake and formatted input delivery to the child.
Startup commands must run in the child; retain newline/partial-input behavior,
copy queued text into child-owned storage, and free it during normal consumption
or forced task cleanup. Do not substitute execution in the caller for XTalk.
Extend automation to creation hotkeys, focus and repeated task/heap recovery
before calling User integration complete. Physical/manual checks remain deferred.

The binding-index table compaction cross-build/386 audit passes in
`build/i386-formatter-binding-table-kernel/result.json`: flat payload 483384
bytes, 1000 fewer than the previous formatter cross-build. The port is now
rebuilding Kernel.HC in `build/i386-formatter-binding-table-selfbuild`; its
native-size result remains pending. Do not infer that the native payload fits
from the smaller cross-built payload alone.

### Compacted native kernel fits and boots; User input oracle expanded

`build/i386-formatter-binding-table-selfbuild/result.json` passes the native
Kernel source build: 538661-byte module, SHA-256
`df996db03c5d16a3e41cee85f530d300adfbfdff3966379d42583eeef92c0d6e`.
The linked payload is 487272 bytes, leaving 152 bytes of the existing BIOS
reservation. The native payload shrank by 984 bytes; do not substitute the
1000-byte cross-build reduction for this measured native result.

The native-built kernel with five cross-built boot helpers passes the twelve-
module executable instruction audit in
`build/i386-formatter-binding-table-native-audit/result.json`. Its boot disk
preserves the source filesystem and BIOS stage (provenance in
`build/i386-formatter-binding-table-boot/image.json`). All 41 formatter cases
pass on that boot image in `build/i386-formatter-binding-table-boot-41/result.json`:
47 commands, 8 MiB 486,-fpu, startup 45.36108453664929 seconds, source disk
unchanged. Flat SHA-256:
`f8be177a6d59d65f3955cb6e6f5694f7bbee0b0abcb1bab248a1b78e0e4b20c8`.
Disk SHA-256:
`c080e1be622ad6a10238f05f1b54542d8b7176cd7f12aadbcc4b9ef8d71dfd90`.
This is a mixed-provider image, not an updated all-native release qualification.

`tools/test-i386-user-create.py` now has 16 cases. Original behavior establishes
that a partial startup string does not execute until XTalk delivers its newline;
User performs two formatting stages, so four percent signs are required to send
one literal modulo operator into the child; and a startup line with over 512
bytes must execute successfully. The test confirms execution in the child,
Adam/CPU-root child membership, cleanup after four creation paths and continued
HolyC execution. The original branch now runs the shared case table and stops
dependent cases on the first failure, avoiding a later Kill on an invalid handle.

All 16 cases pass on original TempleOS in
`build/i386-user-complete-oracle-original/result.json`. The same checker remains
red on the compacted native-kernel image in
`build/i386-user-complete-oracle-native-red/result.json`: the initial User
availability check fails, so the 16 cases are not reached; source disk unchanged.
Checker SHA-256:
`f13e3f4691525e3b14cb613b946c365d8747a3025fa16605d24a38e135d116df`.

Next implement the original User/TaskWait/XTalk behavior with child-owned queued
input and cleanup. Grow terminal input storage beyond the current fixed 256-byte
line rather than truncating the now-tested long command. Preserve the two format
stages and newline/partial-input semantics. The tight boot reservation favors
using existing provider interfaces or validated published provider callbacks in
the console module; any new boot bindings require a measured size check.
Creation hotkeys, focus and repeated heap recovery remain additional gates.


### User/XTalk cleanup verification (2026-10-04)

The current cross-built image passes all 16 shared User cases, including
partial input completed by XTalk, two formatting stages, commands longer than
512 bytes, execution in the child and cleanup after each creation path:

```sh
python3 tools/test-i386-user-create.py \
  build/i386-user-public-symbol-cleanup-imports-kernel/kernel.img \
  --out build/i386-user-public-symbol-cleanup-native-16
```

The fixture now allows 120 seconds per command because new CPU-root children
load public declarations under no-FPU TCG. This allowance does not establish
acceptable interactive creation latency. The original checker branch also
passes all 16 cases with the same assertions. Native runtime evidence is in
`build/i386-user-public-symbol-cleanup-native-16/result.json`: 28 commands,
8 MiB 486,-fpu, exact VGA checkpoints, source disk unchanged.

The preceding failure was a real cleanup defect, not only a timing problem:
`build/i386-user-stop-values-probe/debug.log` reports Kill success and retained
child-list membership. Public-heap hash entries now retire through the shared
symbol visitor before bootstrap symbol teardown. Existing terminal isolation,
focus, exit and exact parent public-heap recovery pass in
`build/i386-user-public-symbol-cleanup-terminals/result.json`.

Native MemoryRuntime compilation, installation/boot and 386 instruction audits
pass in `build/i386-user-public-symbol-cleanup-memory-selfbuild/result.json`,
`build/i386-user-public-symbol-cleanup-memory-install/result.json` and
`build/i386-user-public-symbol-cleanup-memory-audit/result.json`. These prove a
native memory provider with cross-built remaining providers. The full User
runtime result above is on the cross-built image. Native console building is
still running in `build/i386-user-public-symbol-cleanup-console-selfbuild`;
installation and User tests on both native providers remain outstanding.
Creation hotkeys, exhaustive recovery and updated full-workstation/all-native
release gates are not established by these narrower checks.


### Runtime verification with guest-built User providers (2026-10-04)

Native ConsoleRuntime and MemoryRuntime now build, install and pass 386 auditing.
The candidate is `build/i386-user-native-providers-install/candidate.img`;
its SHA-256 is
`08477a7cb9e856f3b6920d3a89068afacafad212aff1500fcab7386a08b55b2e`.
The boot kernel and remaining providers are cross-built. Reproduce the three
passed runtime gates with fresh output directories:

```sh
python3 tools/test-i386-user-create.py \
  build/i386-user-native-providers-install/candidate.img --out build/user-native-check
python3 tools/test-i386-format-strings.py \
  build/i386-user-native-providers-install/candidate.img --out build/format-native-check
python3 tools/test-i386-terminal-hotkeys.py \
  build/i386-user-native-providers-install/candidate.img --out build/focus-native-check
```

Their current results are respectively
`build/i386-user-native-providers-16/result.json`,
`build/i386-user-native-providers-format-41/result.json` and
`build/i386-user-native-providers-focus-hotkeys/result.json`. All pass on
8 MiB 486,-fpu TCG with exact VGA checkpoints and source disk preservation:
16 User cases/28 commands, 41 formatter cases/47 commands, and 11 commands
covering hardware Ctrl-Alt-N focus, history/definition isolation, exit refocus
and parent public-heap recovery.

The next shortcut reference is automated:

```sh
python3 tools/test-i386-original-user-hotkeys.py --out build/original-user-hotkey-check
```

Six original decoder cases pass in
`build/i386-user-creation-hotkeys-original-position/result.json`. The fixture
resolves private KbdBuildSC metadata and calls the original routine with
make/break bytes, checks CPU-root child counts, and kills each created child.
It proves Ctrl-Alt-T/Esc creation plus plain/shift rejection in the original
non-IRQ decoder, not QEMU hardware delivery or native-port shortcut behavior.
Full native-provider workstation testing is running in
`build/i386-user-native-providers-workstation`; that verdict and an updated
all-native release qualification remain outstanding.


### Creation and focus shortcuts (2026-10-04)

On `build/i386-user-creation-hotkeys-kernel/kernel.img`, Ctrl-Alt-T and
Ctrl-Alt-Esc create a terminal and focus it after declaration loading.
Ctrl-Alt-N and Ctrl-Alt-Tab cycle focus. The current implementation is
cross-built; updated native-provider rebuilding is still running.

```sh
python3 tools/test-i386-terminal-create-hotkeys.py \
  build/i386-user-creation-hotkeys-kernel/kernel.img --out build/create-check
python3 tools/test-i386-terminal-hotkeys.py \
  build/i386-user-creation-hotkeys-kernel/kernel.img --focus-key tab --out build/tab-check
```

`build/i386-terminal-create-hotkeys-native-red-v2/result.json` proves the creation
fixture fails on the prior image at Ctrl-Alt-T. The identical checker passes on
the updated cross-built image in
`build/i386-terminal-create-hotkeys-native-green/result.json`: 15 outer commands,
actual QMP key delivery, both creation aliases, focused VGA child, child 6*7,
Exit, child-list retirement, plain/Shift no-creation and resumed root. A possible
Shift-Esc break is caught; no-creation does not mean the chord has no other action.
The generic chord driver separately passes the existing focus control in
`build/i386-keyboard-chord-focus-control/result.json`.

Both N and Tab focus checks pass in
`build/i386-terminal-n-hotkeys-regression/result.json` and
`build/i386-terminal-tab-alias-native-green-labeled/result.json`, including
history/definition isolation, exit refocus and exact parent public-heap recovery.
All three gates use 8 MiB 486,-fpu TCG, exact VGA checkpoints and preserved sources.
They do not qualify typematic behavior, exhaustive creation heap recovery or
acceptable creation latency. Fresh children still load declarations again.

The earlier image with guest-built MemoryRuntime/ConsoleRuntime also completes
its full workstation suite in `build/i386-user-native-providers-workstation/result.json`:
513 commands, 576 lines, 20 document cycles with exact task data/code heap
recovery, 51.426694-second startup and 0.370859-second visible update. That image
predates these shortcut changes. New User regression and native-provider build
results remain pending in `build/i386-creation-hotkeys-user-regression-16` and
`build/i386-creation-hotkeys-native-build`; installation, runtime requalification
and updated all-native release gates remain outstanding.

### Updated shortcut provider qualification (2026-10-04)

The current cross-image User regression passes all 16 cases/28 commands on
8 MiB `486,-fpu` TCG, with exact VGA checkpoints and an unchanged source disk:
`build/i386-creation-hotkeys-user-regression-16/result.json`. Startup is
48.720395 seconds. This checks programmatic User behavior, not shortcut delivery
or exhaustive resource recovery.

`build/i386-creation-hotkeys-native-build/result.json` records successful
guest builds of MemoryRuntime (306979 bytes, 138 exports) and ConsoleRuntime
(1096790 bytes, 347 exports). Their SHA-256 values are respectively
`aae46daffee9437fd2802d9b61d4601c99730992f7c116679791e64b86292bd9` and
`711bc2afd77ccb0c916417e4f3d07fa3e3fcdc427f8efd62c05b62f870690c51`.
The independent twelve-module instruction/ABI audit passes in
`build/i386-creation-hotkeys-native-audit/result.json`. Boot and the other
providers remain cross-built. Installation passes in
`build/i386-creation-hotkeys-native-install/result.json`; candidate disk SHA-256
is `88c42c7ded6cba4f5c9029e4ca41c5ab1d2f4da3e8c2736bcd8aa37f0ac389d6`.
Native shortcut/User regressions are running in
`build/i386-creation-hotkeys-native-runtime` and
`build/i386-creation-hotkeys-native-user-16`; these build/audit results do not establish runtime acceptance
or current-source all-native release qualification.

### Experimental User recovery oracle

`tools/test-i386-user-recovery.py` reuses the established User creation fixture
and proposes eight alternating empty/executed create/kill cycles after one
warmup. It checks CPU-root child count and shared public-pool used/reserved
bytes, not bootstrap allocator accounting. It is **not an acceptance gate**:
`build/i386-user-recovery-original/result.json` fails at case 4, the first measured
cycle, on original TempleOS. Individual counter observations are required to
separate deferred cleanup or pool retention from leaks and establish the actual
original contract. The native comparison is running in
`build/i386-user-recovery-native`; a native pass alone cannot validate this oracle.
Do not use this experiment to claim exhaustive resource recovery or to impose
unsupported behavior on the port.

`tools/observe-i386-user-recovery.py` records ten numbered snapshots (before
creation, then after each of nine alternating empty/executed create/kill cycles)
without assuming exact recovery. The structured report names the columns and
rejects missing or unordered snapshots. A pass proves functional cycles and
observation delivery, **not** resource recovery.

Original-system observation passes in
`build/i386-user-recovery-original-observations-v2/result.json`, checker SHA-256
`5b3893c023b73541e6b5b028bc680d920c6485b2d3c2698f31a19d9c25fa2ae0`.
Root child count is three in all ten snapshots; shared-pool reserved bytes stay
at 2142068736. Used bytes grow from 286798336 to 291338240 (4539904 bytes),
caller heap from 332136 to 333720, and CPU-root heap from 279698960 to 280377536.
These are observations of this fixture, not proof of which allocations persist
or an allowance to grow without bound on the 8 MiB port.

The same observation fixture is running against the installed native providers
in `build/i386-user-recovery-native-observations`. Inspect those measurements
and allocation ownership before turning this into an acceptance gate.

### Native shortcut result and bootstrap observations

The installed guest-built MemoryRuntime/ConsoleRuntime image passes creation
shortcuts in `build/i386-creation-hotkeys-native-runtime/result.json`: 15 commands
on 8 MiB `486,-fpu` TCG, 52.185862-second startup, exact VGA checkpoints and
unchanged source disk. This covers Ctrl-Alt-T/Esc creation, focused child HolyC
input/Exit and plain/shift rejection, not typematic or exhaustive recovery.

The experimental native exact-recovery run is terminal and fails by console
timeout at `UserCycle(FALSE);`, after `USER headers ok` and `USER input begin`.
Evidence is `build/i386-user-recovery-native/result.json`. This does not prove
which recovery counter differs or even that the recovery expression completed.

`tools/observe-i386-user-bootstrap.py` adds separate bootstrap used-byte and
allocation-count snapshots to the public-pool observations. It extracts only
layout declarations from the tested disk, verifies the backing signature and
heap validity, and records header and dependency hashes. Results remain
observations, not a recovery acceptance verdict. The run is pending in
`build/i386-user-bootstrap-observations`. The shared layout extractor was
refactored from the existing task-accounting tool; its generated 107 commands
and header provenance were compared before/after and are exactly unchanged.

The guest-built-provider Tab-focus test passes in
`build/i386-creation-hotkeys-native-tab/result.json`: 11 commands, exact VGA
checkpoints, separate histories/definitions, exit refocus and exact parent
public-heap recovery, on 8 MiB `486,-fpu` TCG. Startup is 56.120742 seconds
and the source disk is unchanged. This is focus behavior, not exhaustive
creation resource accounting.

The first empty create/kill cycle in the native observation run has unchanged
public-pool used/reserved and caller/root heap counters (1368064, 1379328,
1354760, 0), with root child count one before and after. The run is still live;
these two snapshots do not qualify repeated recovery. The failed strict
fixture's final PPM shows `UserCycle(FALSE);` with no returned result, rather
than a visible false verdict.

`tools/test-i386-user-cycle.py` isolates an empty create/kill cycle inside one
HolyC call and records start/created/stop/retired phase markers, including on
failure. It checks completion and resumed arithmetic, not counters. The native
run is pending in `build/i386-user-cycle-native`; use it to distinguish a
create/kill wait from the strict fixture's later recovery expression.

### Updated native User regression

`build/i386-creation-hotkeys-native-user-16/result.json` passes all 16 cases
and 28 commands on the installed guest-built MemoryRuntime/ConsoleRuntime
image: 8 MiB `486,-fpu` TCG, 52.391379-second startup, exact VGA checkpoints
and unchanged source disk. Together with creation and Tab tests, this qualifies
the affected focused behavior; it does not close exhaustive recovery or
all-native/two-generation qualification. Full workstation regression is running
in `build/i386-creation-hotkeys-native-workstation`.

The bootstrap observer's first empty create/kill cycle returns to 5348304 used
bytes and 7104 allocations, exactly its initial snapshot, while public-pool
counters also recover. Later cycles are still running. This is narrower than
the final repeated-recovery requirement.

For fresh-child declaration latency, the next architectural candidate is to
load declaration-only `PublicUser.HH` once in the CPU-root scope, after console
exports are installed and with a valid root-owned compiler control. Child
scopes can inherit the stable declarations; singleton `StartOS.HC` remains an
initial-console operation. `I386FrontendPublish` requires the actual control's
owner and destination scope to match: redirecting a child hash pointer is not
a valid shortcut. Check root initialization order, peak memory, inheritance
guards and definition isolation before implementing this. Both startup and
child readiness must be measured; moving cost into boot alone is insufficient.

### Same-call User/Kill compatibility failure

The isolated synchronous native run is terminal:
`build/i386-user-cycle-native/result.json` fails by console timeout with
`start`, `created`, `stop` markers and no `retired` marker. Its checker is
`5d8052d9aacffc4f89ccffb38d7a252cf64966f75a6ef352b3c4cc9b0a52b967`.
Thus the wait occurs after User creation and during the stop path, before any
recovery comparison. This must not be described as a pool-counter failure.

The cycle tool now supports `--original` and `--async-stop`. The default
synchronous HolyC definitions are unchanged. Original TempleOS passes the
default same-call cycle in `build/i386-user-cycle-original/result.json`, with
all four phase markers; updated checker SHA-256 is
`d8e06a94e8256377a1865b3294379db369525900317e717916051063d76ebdfd`.
The native `--async-stop` diagnostic is running in
`build/i386-user-cycle-native-async`. It requests Kill without waiting, then
yields for a bounded interval and checks child-list retirement. This diagnoses
the failure; it is not a replacement for synchronous Kill compatibility.

Separate-command bootstrap observations have recovered both public-pool
counters and bootstrap used bytes/allocation count exactly through three
cycles. That run is still live and does not excuse the same-call wait bug.

The first asynchronous diagnostic is terminal:
`build/i386-user-cycle-native-async/result.json` fails by console timeout, with
start/created/stop markers and no retired marker. Because that version logs
nothing between the Kill request and the wait, it does not localize the stop
path further. Its checker SHA-256 matches the passing original synchronous
comparison (`d8e06a94e8256377a1865b3294379db369525900317e717916051063d76ebdfd`).

The updated `--async-stop` diagnostic emits interrupt flags, jiffies and child
membership immediately after Kill returns and after at most 20 yields. This
uses an iteration bound rather than relying on timer progress to stop the
diagnostic, and retains the synchronous fixture as the compatibility contract.
The new run is pending in `build/i386-user-cycle-native-async-state`.

### Bootstrap observation timeout: scope correction

`build/i386-user-bootstrap-observations/result.json` is terminal and fails by
console timeout at the fifth `UserProbeStart(FALSE);`, with `USER headers begin`
but no header-completion marker. The five paired snapshots (initial plus four
completed cycles) in its debug log all show public-pool used/reserved bytes
1368064/1379328, root child count one, and bootstrap 5348304 used bytes/7104
allocations. This proves recovery through those four measured cycles, not the
planned nine. No allocation leak is established by this timeout.

The same-call cycle fixture's 120-second limit covers both header compilation
and stop. Its stop marker narrows the last observed phase but does not prove an
indefinite wait. The implementation queue now calls for distinguishing latency
from cancellation failure before modifying the port. The original-system
cycle pass establishes required behavior, not a comparable host-time budget.

The bootstrap observer now preserves parsed partial snapshots and the last
checkpoint in future failure reports. Its extraction was checked against the
terminal run's five paired snapshots and exact bootstrap counters. Historical
result JSON remains unchanged; that run used the earlier checker.

### Nine-cycle native public-pool result

`build/i386-user-recovery-native-observations/result.json` passes 52 commands
on 8 MiB `486,-fpu` TCG, with exact VGA checkpoints, unchanged source disk and
54.306944-second startup. All ten snapshots (initial plus nine alternating
empty/executed create/kill cycles) exactly match: root child count one,
public-pool used/reserved bytes 1368064/1379328, caller heap 1354760 and
CPU-root public heap zero. This uses the same observation checker as the
original-system comparison (`5b3893c023b73541e6b5b028bc680d920c6485b2d3c2698f31a19d9c25fa2ae0`).
It establishes recovery for these measured public counters. Bootstrap coverage
is still only four completed cycles, and same-call completion remains open.

The bounded asynchronous state diagnostic is terminal:
`build/i386-user-cycle-native-async-state/result.json` observes
`USER CYCLE state 202 188552 1` after Kill returns, then times out before the
post-yield measurement. Thus the request returns with IF enabled and the child
still linked; this rules out a stall within that asynchronous Kill call, not
latency or failure during the following yields.

The cycle checker now records phase observation times and accepts an explicit
`--command-timeout`. The unchanged synchronous behavior is being observed with
600 seconds in `build/i386-user-cycle-native-long-observation`. This extended
diagnostic is intended to distinguish expensive creation/cleanup from a
permanent wait; it does not waive normal acceptance latency requirements.

### Isolated root-declaration prototype

An isolated checkout at `build/root-declaration-prototype` (only `main`, fork
remote) loads declaration-only `PublicUser.HH` in ConsoleInit after installing
console exports, using the actual CPU-root compiler scope. The main source
tree and the images under regression are unchanged. The prototype passes its
matching original x64 two-generation rebuild; its i386 build is running in
`build/root-declaration-prototype/build/i386-root-declarations`. No prototype
runtime result is claimed yet. Startup memory, child readiness, inherited
include guards and task-local definition isolation still need qualification
before applying the change to main.

### Same-call timeout resolved as latency

`build/i386-user-cycle-native-long-observation/result.json` passes the unchanged
synchronous create/kill behavior on 8 MiB `486,-fpu` TCG, with exact VGA and
unchanged source disk. Phase times show creation starts at 98.385991 seconds,
headers begin at 98.436331, headers finish at 209.111057 and retirement completes
at 227.997553. The measured cycle is about 129.61 seconds: roughly 110.67 seconds
for headers and 18.89 seconds for retirement. This exceeds the old 120-second
combined-command timeout. The 600-second diagnostic establishes functional
completion; it does not meet a faster interactive latency requirement. The
evidence does not justify changing cancellation semantics to fix a permanent
stall.

The root-declaration prototype's i386 build and all-module instruction audit
complete successfully; boot kernel remains 483384 bytes. Its focused same-call
cycle, creation shortcuts and 16-case User tests are running in
`build/i386-root-declarations-cycle`, `build/i386-root-declarations-hotkeys` and
`build/i386-root-declarations-user-16`. Prototype artifacts remain distinct from
main's mixed native-provider image. No runtime acceptance is claimed yet.

### Root-declaration focused results

The isolated cross-built prototype (disk SHA-256
`d4a8229bcacad8120420c2614c6374d0ebe63cdd42736450effb1caf14215cbe`) passes
the same-call cycle, 16-case User oracle and creation shortcuts in
`build/i386-root-declarations-cycle`, `build/i386-root-declarations-user-16`
and `build/i386-root-declarations-hotkeys`. All use 8 MiB `486,-fpu` TCG, exact
VGA checks and unchanged source disks.

The same cycle checker records start at 110.817482 seconds and retirement at
111.170215 (about 0.35 seconds). Header loading spans about 0.10 seconds,
retirement about 0.20. The prior mixed-native image measured about 129.61
seconds; provider provenance differs, so native rebuild qualification is still
required before claiming this speed for the native release candidate.
Startup is 59.827704 seconds for the cycle, 59.934938 for shortcuts and
63.546689 for User. The startup target is not reliably satisfied.

The bootstrap observer now offers `--require-recovery`, requiring all ten
snapshots in order and exact child/public-pool/task-heap/bootstrap counters
after every cycle. Its mismatch detector rejects independent injected public
and bootstrap drift. Observation-only remains the default. Prototype recovery
qualification with that flag is running in
`build/i386-root-declarations-recovery`; Tab-focus isolation is running in
`build/i386-root-declarations-tab`. Main's runtime source is unchanged.

### Root-declaration change promoted to main

The prototype passes strict nine-cycle public/bootstrap recovery in
`build/i386-root-declarations-recovery/result.json`: all ten bootstrap snapshots
are 5326856 used bytes/7161 allocations, with public counters and CPU-root child
count also exactly stable. Startup is 58.508295 seconds. Tab isolation passes in
`build/i386-root-declarations-tab/result.json`, with 58.573605-second startup,
independent histories/definitions, refocus and parent-heap recovery. Both use
8 MiB no-FPU TCG and unchanged source disks.

The ConsoleInit root-declaration change is now applied to main. Its matching
original x64 two-generation rebuild passes in `build/rebuild-test/result.json`;
the main i386 build is running in `build/i386-root-declarations-main`. Prototype
functional results do not substitute for updated guest-built providers or
all-native/two-generation release qualification. Startup remains close to its
budget and must be qualified again.

The previous native-provider integration image completes the full workstation
regression in `build/i386-creation-hotkeys-native-workstation/result.json`:
513 commands/576 lines, 53.657661-second startup and 0.257098-second long-document
update on 8 MiB `486,-fpu` TCG. This source epoch predates shared root declarations.

### Main build and six-provider qualification

`build/i386-root-declarations-main/result.json` completes the main i386 build
and instruction audit, with 483384 boot bytes and disk SHA-256
`277fc38d3469be170fff6616246b2434bac2c8190b9c814eec293e120dd69a1d`.
All six retained providers are now rebuilding under 16 MiB KVM in
`build/i386-root-declarations-native-build`, using this build's export contracts.
Main-image strict recovery is running in `build/i386-root-declarations-main-recovery`.
No native rebuild/installation/runtime result is claimed yet.

Comparison with the tested prototype finds all eleven retained/helper modules
byte-identical. Kernel.t32m and the linked flat image differ; all 135 module
differences are after the terminating NUL inside the 12-byte keyword-name
arrays. All 73 runtime names, types and values match. KeywordsInit copies only
through NUL, but these unspecified string-tail bytes are still a cross-build
reproducibility concern. Keep the actual main-image runtime check and record
this for deterministic source initialization; do not claim byte-identical boot
artifacts or silently normalize bytes in evidence.

### Main recovery and deterministic keyword gate

`build/i386-root-declarations-main-recovery/result.json` passes strict nine-cycle
recovery, with all ten bootstrap snapshots at 5326856 used bytes/7161 allocations
and exact public-pool/task-heap/child-count recovery. Startup is 58.411265 seconds
on 8 MiB `486,-fpu` TCG; the source disk is unchanged.

`tools/audit-i386-keyword-table.py` independently checks the exported 73-entry
keyword descriptor table against OpCodes.DD and hash-type constants, including
all twelve bytes of each name array. It is a keyword-data gate, not a substitute
for ABI/ISA audit. The existing main cross-built Kernel fails this new gate in
`build/i386-keyword-tail-main-red.json`: nonzero bytes follow the NUL in `include`.

In the isolated checkout, the keyword generator emits twelve explicit byte
initializers per name, including zero fill. Inventory and type/value constants
remain unchanged. Generator checks and the matching original two-generation
rebuild pass; the updated i386 build is running in
`build/root-declaration-prototype/build/i386-keyword-initialization`. Gate and
runtime acceptance are pending. Main Kernel/Compiler sources stay frozen for
the ongoing six-provider native build.

### Keyword determinism passes; inherited module completion is open

The explicit twelve-byte initializer prototype passes
`build/i386-keyword-tail-prototype-green.json`; independent injected tail-byte,
type and value errors are all rejected by the audit. The same-call runtime
cycle also passes in `build/i386-keyword-initialization-cycle/result.json`.
Two separate cross-build executions produce all twelve modules and the linked
flat image byte for byte: `build/i386-keyword-repeat-comparison.json`, 13
artifacts and no differences. Main has not yet adopted this source change.

The root-sharing six-provider build is terminal and fails while building its
first CompilerRuntime source unit. The debug log reports frontend rejection at
`C:/Kernel/SymbolTypes.HH:130`, the CHashFun definition; the build command returns
zero and the harness subsequently times out awaiting success. Evidence is
`build/i386-root-declarations-native-build/qemu/debug.log` and its checkpoint.
The tool does not write a result JSON on this failure. No selected provider
pass is claimed.

Completion currently requires a forward descriptor directly in the parent's
first table. Shared root declarations can be inherited through an intervening
child table. The isolated fix permits module-source private completion to
resolve that inherited descriptor while preserving interactive direct-scope
publication checks and existing allocation/schema validation. Its matching
original rebuild is running in the isolated checkout; module/runtime acceptance
is still pending. Fix this regression before native root-sharing promotion.

### Inherited forward completion: isolated build and focused regression

The isolated module-only inherited lookup fix passes its matching original
two-generation rebuild and i386 build/audit in
`build/root-declaration-prototype/build/i386-module-inheritance`. The resumed
six-provider qualification in `build/i386-module-inheritance-native-build` has
progressed past the previous CHashFun rejection and is compiling functions;
provider completion/installation is not yet claimed.

`tools/test-i386-module-inherited-forward.py` creates a small source document
including SymbolTypes.HH, builds it into a persisted T32M, checks its Main export
and verifies the inherited CPU-root CHashFun retains its identity and opaque
shape. The test uses a writable disk copy and verifies the original disk hash.
It does not execute the output module or replace full provider self-builds.

The first test revision reproduces main's frontend rejection; the repaired
image passes its guest checks but fails the host source comparison because
DocWrite saves a trailing CH_CURSOR byte. The fixture now expects that exact
byte rather than stripping saved content. Matching revised red/green runs are
pending in `build/i386-module-inherited-forward-red-v2` and
`build/i386-module-inherited-forward-green-v2`. Treat earlier incomplete verdicts
as diagnostic evidence only. Main has not yet adopted the completion fix.

### Matching forward-module red/green; fixes applied to main

The corrected focused checker
`d0f9f11e3be26f7924f70914acf82bb780720c0c877b5b01d980faff5cb51494` fails
on the pre-fix main image at module compilation, with the original CHashFun
frontend rejection (`build/i386-module-inherited-forward-red-v2/result.json`).
It passes the repaired image in
`build/i386-module-inherited-forward-green-v2/result.json`: ten commands,
58.281468-second startup, exact VGA checkpoints, unchanged source disk,
persisted source including its cursor marker, and only the Main export. Module
SHA-256 is `30d9f862147498a29d35f82c5b684d8eaaa9ee0b9e813efc21b87b0394156264`.
The root forward descriptor remains identical and opaque.

Main now includes the module-source inherited-forward lookup and explicit
twelve-byte keyword initialization. Interactive direct-scope completion checks
remain in place. Main's matching original rebuild passes; i386 build/audit is
running in `build/i386-module-inheritance-main`. The full isolated retained
provider build is still live in `build/i386-module-inheritance-native-build`.
Native build completion, installation and current-source release qualification
remain required.

### Current main audit and automatic keyword gate

`build/i386-module-inheritance-main/result.json` completes the current main
i386 build/audit with 483384 boot bytes. Its keyword table passes the standalone
auditor in `build/i386-module-inheritance-main/keyword-data-standalone.json`.
The updated combined module instruction/data audit also passes in
`build/i386-module-inheritance-main-integrated-audit`.

The regular `build-i386-kernel.py` audit now validates the keyword table and
writes `keyword-data-audit.json`; fresh build reports include that result and
the keyword-checker hash in build-input provenance. This rejects future
nonzero name tails automatically rather than relying on a separate manual
audit command. The build that produced the current image predates integration
of the gate; a fresh gated build is running in
`build/i386-module-inheritance-main-gated`.

Main-image inherited-module regression is running in
`build/i386-module-inherited-forward-main`; the complete workstation suite is
running in `build/i386-module-inheritance-main-workstation`. The isolated
six-provider build remains active, progressing through CompilerRuntime
functions. Completion and native installation/runtime qualification remain open.

### Gated main build and current module regression pass

`build/i386-module-inheritance-main-gated/result.json` passes the integrated
instruction and 73-descriptor keyword-data audits. All twelve modules and the
linked flat image match the preceding main build byte for byte, recorded in
`build/i386-module-inheritance-main-repeat.json` (13 artifacts, no differences).

The focused main-image regression passes in
`build/i386-module-inherited-forward-main/result.json`: ten commands,
58.624633-second startup, exact VGA checkpoints, unchanged source disk and the
same persisted Main module hash as the isolated green test. Root forward-class
identity/opaque shape is preserved.

The isolated six-provider build is terminal after its 900-second command
timeout during CompilerRuntime generation, last observed at
I386FrontendAssembly. Its logs show function-generation progress and no new
frontend rejection at that point; they do not prove CompilerRuntime completion.
The tool has no success result JSON for this attempt. A fresh build from the
gated main image is running in `build/i386-module-inheritance-native-build-long`
with 3600 seconds per build command. This is an explicit build observation
budget, not a waiver of startup/interactive latency or no-FPU qualification.
The current full workstation regression remains live.

### Retained provenance before full self-hosting

Full `test-i386-selfhost-install.py` runs now require
`--retained-build-result` and a retained installation verdict. The latter defaults
to `result.json` beside `--disk`; use `--retained-install-result` to override it.
Both verdicts must pass, the build disk must match the installation source,
the installed disk must match the supplied image, and all six providers must
match the build size/hash and installation hash. These checks run before QEMU.
The output records both evidence-file hashes. Cross-retained development runs
retain their separate cross-build checks and cannot use guest evidence options.

The harness suite passes all 17 tests, including rejection of eight mutated
guest provenance chains. This links existing build/install evidence; it does
not establish current-source two-generation qualification by itself.

### Shared-root Help category integration failure

The full current-source workstation run in
`build/i386-module-inheritance-main-workstation` terminated with a VGA timeout
at `help-index-link`, after entering `HI:Data Types/Circular Queue`. The saved
`help-index-link-hi-category.ppm` shows the expected help file and eight symbols,
but their order differs from the fixture. The previous hash-order fixture is
not an alphabetical oracle. Original `Adam/AHash.HC` sorts category entries by
name, with help-file entries first.

The isolated checkout `build/root-declaration-prototype` now gathers at most
128 registrations into a bounded stack array and sorts each group by name. It
retains the existing page/link limits and uses no additional heap allocation.
The matching original two-generation rebuild passes. Its i386 build is pending
in `build/root-declaration-prototype/build/i386-help-sort`; a focused Help run
against the unchanged main image is running in `build/i386-help-sort-red`, using
the alphabetical category oracle. Neither the prototype nor that focused run
is a completed integration pass. Main Kernel/Compiler inputs remain unchanged
while `build/i386-module-inheritance-native-build-long` runs.

The alphabetical Help oracle now has a matched red/green observation. The main
image terminates at the category VGA assertion in `build/i386-help-sort-red`.
The isolated image passes all nine Help commands in
`build/i386-help-sort-green/result.json`, including category selection, file
opening and returning to the selected category, plus search/anchor links and
heap recovery. CPU is `486,-fpu`, RAM 8 MiB, startup 58.119722 seconds, with every
VGA pixel matched. Image SHA-256 is
`1afc4a3e150556fce6219b5ed63c2e4375609c3cb86b403d3964c5a2a5848b8a`.
The checker SHA-256 is
`f095e48393fa1d64cd9af0d1d9fa10b93af7cb85fd7998df54bcb93575f5f4ad`;
prototype DocumentRuntime SHA-256 is
`1305e5a46baf35e7148b4ff612ba16aa5bb8545cfcba77621840d7ce01eb2148`.
The matching original rebuild and i386 executable audit pass; boot kernel size
is unchanged at 483384 bytes. Full workstation qualification is running in
`build/i386-help-sort-workstation`. The sorted implementation and fixture remain
isolated until that run and the main-source native build finish.

### CPU breakpoint debugger failing contract

Run `python3 tools/test-i386-debug-cpu-trap.py IMAGE --out OUTPUT`.
The checker compiles three NOP bytes, locates that sequence in a bounded scan,
patches and verifies the first byte as 0xCC, then calls the helper. It requires
a visible debugger identifying the function/source, state inspection, `G`
continuation after the actual trap, stage 2, restored debugger mode and IF,
cleared TF and ordinary HolyC recovery. It does not prove installed software
breakpoint policy, stepping or complete register inspection.

Current main is red in `build/i386-debug-cpu-trap-byte-red-v2/result.json`: all
preparation commands pass; `CpuTrapProbe` logs `CPU TRAP enter`, followed by
`FAULT 0000000000000003 00000000002817FD` and `FAIL native kernel`.
The source image remains unchanged. The visible debugger assertion times out;
no continuation assertions execute. This is actual CPU dispatch failure, not
a rejected assembler statement.

The first attempt in `build/i386-debug-cpu-trap-red` rejects the unsupported
INT3 mnemonic before execution. The first patched-byte fixture in
`build/i386-debug-cpu-trap-byte-red` fails because a top-level scan also prints
a value. Neither establishes CPU dispatch behavior. The final checker isolates
those preparation details in functions and verifies them before invoking the
trap. Keep the runtime failure and assembler support gap separately open.

The isolated sorting image now passes the complete workstation suite in
`build/i386-help-sort-workstation/result.json`: 513 commands, 576 lines, exact
VGA at every checkpoint and 20 bounded document cycles with exact shared-heap
recovery. No-FPU TCG startup is 58.169028506 seconds on 8 MiB; the unchanged
60-second checker passes in `build/i386-help-sort-workstation-budget.json`.
Long-document update is 0.432723586 seconds, below the one-second budget.
This establishes integration on the isolated cross-built image identified
above; it does not establish native provider qualification or release readiness.
Promotion remains pending while the main-source native build completes.

### Main Help promotion and retained native installation

The isolated Help implementation and alphabetical category fixture are now
applied to main. The matching original two-generation rebuild passes in
`build/rebuild-test/result.json` (log `build/help-sort-main-rebuild.log`).
The i386 build, instruction audit and deterministic keyword gate pass in
`build/i386-help-sort-main/result.json`; boot kernel remains 483384 bytes.
`build/i386-help-sort-main-promotion-comparison.json` verifies all twelve T32M
modules and Kernel32.BIN equal the fully qualified isolated prototype exactly.
A focused current-main Help check is running in `build/i386-help-sort-main-help`.

The earlier root-declaration source epoch now completes all six native retained
providers in `build/i386-module-inheritance-native-build-long/result.json`.
This closes its inherited-forward build rejection and replaces the earlier
900-second incomplete attempt with completed payload/export audits. Installation
passes in `build/i386-module-inheritance-native-install/result.json`, preserving
each native payload exactly and independently booting an 8 MiB copy. Candidate
SHA-256 is `63429476aaad0e398d7ca4862de02b5fe441d9e399849dc775047458747d8dfa`.

The provenance-enforced flat self-hosting run uses that candidate and its
retained-build result in `build/i386-module-inheritance-selfhost`. It is still
running. Those native modules predate alphabetical Help, so neither installation
nor the ongoing flat build establishes full self-hosting of the newer main
source. Two native generations, CPU-trap debugger behavior and release
qualification remain open.

### Breakpoint assembly encoding and full native flat build

`tools/test-i386-breakpoint-asm.py` compiles `NOP INT3 NOP` and `NOP BPT NOP`,
checks the emitted 0x90/0xCC/0x90 byte sequence and ordinary HolyC recovery,
without executing either trap. Current pre-fix main is red in
`build/i386-breakpoint-asm-red/result.json`, with the INT3 definition rejected.
The isolated compiler change passes all six commands in
`build/i386-breakpoint-asm-green/result.json`, on 8 MiB no-FPU TCG, with exact VGA
and 58.585581-second startup. Checker SHA-256 is
`e6641d2e97a73e6fa4c47f65e6019fa9594895086bb115808a8f368a99a88a18`;
image SHA-256 is
`2c02421f0388878a0e544ee0f79b9bd49ee45741fe13a2c3e1c5d7199565d0aa`.
Both tests preserve their source images.

The one-line opcode selection is promoted to main. Its matching original
rebuild and i386 build/audits pass in `build/rebuild-test/result.json` and
`build/i386-breakpoint-asm-main/result.json`. The promotion comparison proves
all twelve modules and flat kernel byte-identical to the green prototype in
`build/i386-breakpoint-asm-main-promotion-comparison.json`. The existing inline
assembly regression is running in `build/i386-breakpoint-asm-main-inline`.
CPU trap inspection, resumption and stepping remain unimplemented.

The pre-Help root-declaration source epoch now passes the complete guest flat
build/install/independent boot in `build/i386-module-inheritance-selfhost`.
All twelve modules are guest-built. Target SHA-256 is
`22a5c9e20b2c698ec2deda5b8a9bff7f4f251802e4701e1343182d6d6b59bb78`;
flat bytes are 487384 (40 bytes spare), SHA-256
`ff4c21d753a4ab3ce37d4f3b2575eff868064ba12db36a4c83aae10f6039d87c`.
Retained build/install verdict hashes are recorded in the result. The installed
386 executable ranges, boot payload, filesystem and exact keyword data audit
pass in `build/i386-module-inheritance-selfhost-audit`. A no-FPU native User
creation/retirement check is running in `build/i386-root-declarations-native-cycle`.
This native epoch predates the Help sorting and new assembly mnemonic changes.
It does not replace current-source two-generation or release qualification.

The promoted main Help check also passes all nine commands with exact VGA in
`build/i386-help-sort-main-help/result.json`, with 58.631367-second startup.

The fully guest-built pre-Help image now passes the same-call User cycle in
`build/i386-root-declarations-native-cycle/result.json`: 17 commands, exact VGA,
source preserved, matching checker 1c6f9171. Start-to-retirement is
0.352312204 seconds (headers about 0.100618 seconds, retirement about
0.201351 seconds). This confirms functional completion and shared-header speed
on native-built providers, not exhaustive resource recovery. Startup is
66.404226066 seconds on 8 MiB no-FPU TCG; the unchanged timing gate fails in
`build/i386-root-declarations-native-cycle-budget.json`. Keep that failure
visible separately from the functional pass.

### Native root-header boot profile and heap-search prototype

The updated profiler distinguishes `ROOT USER HEADERS begin/ok` from ordinary
console headers and startup source; its six ordered phase transitions pass.
`build/i386-root-declarations-native-profile/result.json` completes on preserved
native target 22a5c9e2, using the installed modules' own symbol maps. Root headers
have 506 samples: 181 allocation, 165 free and 96 heap scan (442 combined).
Foundation has 148 samples, 110 in module validation. The dominant allocation
and free stacks run through lexer identifier publication and frontend
publication under ConsoleInit. Pausing for samples invalidates elapsed-time
benchmarking; the independently measured 66.404-second boot failure remains
the timing evidence.

The isolated `build/cpu-debug-prototype` heap change preserves full-arena
validation before mutation, first-fit allocation, exact pointer matching,
coalescing and the portable path. The later block search uses bounded U32
assembly. Matching original two-generation rebuild passes. Both existing
heap corpora pass in `build/i386-heap-test` and `build/i386-heap-source-test`
inside that checkout, with 49 public heap layout checks, 1024 churn rounds and
three lifetime/pool/backing cycles each. Its i386 integration build is running
in `build/cpu-debug-prototype/build/i386-heap-seek`. No speed or native boot-size
claim is made yet; the optimization remains isolated.

The current-main inline-assembly regression also passes in
`build/i386-breakpoint-asm-main-inline/result.json`, including loader-required
operand forms, character immediates and a block over 256 bytes, with the source
preserved. Startup for that cross-built image is 58.431377 seconds.

The heap-search prototype integrated build and executable/keyword audits now
pass in `build/cpu-debug-prototype/build/i386-heap-seek/result.json`.
The cross-built boot kernel is 482440 bytes, 944 bytes smaller than main's
483384-byte baseline. Image SHA-256 is
`6db997ffe5c0c75c76a1a7edff8d7587450b02a68151f8930721d9e7ace8c38e`.
Normal no-FPU 8 MiB TCG keyboard/exact-VGA boot passes in
`build/i386-heap-seek-keyboard/result.json` at 23.484112070 seconds; the unchanged
60-second checker passes in `build/i386-heap-seek-keyboard-budget.json`. This is
a recorded cross-image timing, not a controlled fully native speed comparison.

Full workstation regression is running in `build/i386-heap-seek-workstation`.
The isolated cross-retained development flat build is running in
`build/cpu-debug-prototype/build/i386-heap-seek-native-development`. It checks
native source assembly acceptance and boot-image fit using verified cross-built
retained providers; it cannot establish full self-hosting or native-provider
startup timing. Main heap sources remain unchanged pending these checks.

The isolated heap-search guest flat-development build now passes in
`build/cpu-debug-prototype/build/i386-heap-seek-native-development/result.json`.
All six flat modules build in the guest, install and boot independently; retained
providers are explicitly cross-built. Flat size is 486472 bytes (952 spare),
SHA-256 `1f8ec5aedbba424a78b436b0e26da1b85e156e172372fe99c29a8c51743a9a26`.
Target SHA-256 is
`355d62b9d625659a1bfcafdd545467302c22e05a4dec27dddd757be59770ccee`.
Instruction ranges, boot payload, filesystem and exact keyword data pass in
`build/i386-heap-seek-native-development-audit`. Use the cross compiler template
mode for this mixed development image (omit `--guest-compiler-template`);
the first audit invocation with the guest-template flag rejected the cross-built
compiler's template representation. The corrected audit passes.

No-FPU 8 MiB keyboard/exact-VGA boot passes on that guest flat image in
`build/i386-heap-seek-native-development-keyboard/result.json` at
23.939021246 seconds. The unchanged startup-budget checker passes in its
`-budget.json` report. Fully guest-built retained-provider startup and full
workstation integration remain pending. The optimization remains isolated.

### Heap-search promotion and register-preserving CPU-trap contract

The isolated heap optimization passes the full workstation suite in
`build/i386-heap-seek-workstation/result.json`: 513 commands, 576 lines, exact
VGA and 20 document cycles with exact shared-heap recovery. Startup is
23.638717247 seconds, and the unchanged startup gate passes. Long-document
update is 0.254742163 seconds. This complements both heap corpora and the
guest flat-development build/audit/boot, without proving fully native retained
provider timing.

The implementation is promoted to main. Its original two-generation rebuild
passes in `build/rebuild-test/result.json` (log `build/heap-seek-main-rebuild.log`).
The i386 build and instruction/keyword audits pass in `build/i386-heap-seek-main`.
`build/i386-heap-seek-main-promotion-comparison.json` confirms all twelve T32M
modules and Kernel32.BIN match the fully qualified prototype exactly. The boot
kernel is 482440 bytes. All six retained providers are rebuilding natively in
`build/i386-heap-seek-native-build`, using that byte-identical prototype image
and its export contracts; the run has advanced past CompilerRuntime and is
building CompilerProbe. Final payload audits remain pending.

The CPU-trap checker now returns a known EAX value from the interrupted helper
after `G` and compares it with 0x11223344. This rejects an implementation that
continues execution but loses EAX. The updated checker SHA-256 is
`50e93b3703532900221720901765fe33cddda0f37e841912b20023aaf1e1df38`.
Its pre-heap main-image red result is in
`build/i386-debug-cpu-trap-register-red/result.json`: preparation succeeds, then
`CPU TRAP enter` is followed by vector 3 and `FAIL native kernel`. Source disk
remains unchanged. Register return, mode/IF/TF restoration and shell recovery
remain unexecuted assertions, not established behavior.

The heap-search source epoch now passes all six native retained providers in
`build/i386-heap-seek-native-build/result.json`, including exact export contracts
and the console allocation-wrapper check. Module sizes are CompilerRuntime
1739257, CompilerProbe 1231080, ConsoleRuntime 1096428, FileRuntime 302036,
MemoryRuntime 306979 and Startup 407 bytes. The result records each payload
hash and the resulting source-disk hash. Installation is running in
`build/i386-heap-seek-native-install`; native-provider boot timing, the matching
flat rebuild, integrated native workflows and second-generation reproducibility
remain pending. This is completed construction evidence, not a release pass.

The optimized epoch's native retained installation passes in
`build/i386-heap-seek-native-install/result.json`: all six payloads match their
build hashes, preserved source/candidate disks remain unchanged by the boot
check, and an independent 8 MiB KVM boot evaluates 6*7 and DocAllocationCheck.
Candidate SHA-256 is
`ed8e5e33b1f2f1c1643133df27883a6dd821210dfcce6793c398c4c09b340d4d`.
The provenance-enforced six-flat-module rebuild is now running in
`build/i386-heap-seek-selfhost`, with the matching retained-build result.
No-FPU timing and integrated fully guest-built workflows remain pending.

The current optimized epoch now completes full self-hosted construction in
`build/i386-heap-seek-selfhost/result.json`: six native retained providers plus
six guest-built flat modules, exact installation and independent 8 MiB boot.
The result records the matching retained build/install evidence hashes. Flat
size is 486472 bytes (952 spare), SHA-256
`8d2f831e07580b1c240defadbfe37140821ae979db743fa50bbe6285b791626b`.
Target SHA-256 is
`6fc8eb0b3ebc632e58f6b1d4fcf1dfc5f0350233648fbf62fb7b3d215cfcb63b`.
The installed image audit is in `build/i386-heap-seek-selfhost-audit`; no-FPU
8 MiB keyboard/exact-VGA startup testing is running in
`build/i386-heap-seek-selfhost-keyboard`. A completed self-hosted build is not
a full workflow, second-generation reproducibility or release verdict.

The fully guest-built optimized target 6fc8eb0b now passes its installed
386 executable/boot/filesystem and keyword audits in
`build/i386-heap-seek-selfhost-audit/result.json`. Ordinary no-FPU 8 MiB TCG
keyboard/exact-VGA boot passes in `build/i386-heap-seek-selfhost-keyboard` at
32.920473797 seconds. The unchanged 60-second checker passes in its
`-budget.json` report, closing the previous 66.404-second native-image failure
for this source epoch.

Full native workstation qualification is running in
`build/i386-heap-seek-selfhost-workstation`. Second-generation retained rebuilding
is running in `build/i386-heap-seek-gen2-native-build`, with current export
contracts and `--compare-installed` against first-generation target 6fc8eb0b.
That exact-byte comparison remains pending, as do the second flat build and
release qualification. Kernel/Compiler sources remain unchanged during these
runs. CPU-trap debugger continuation remains an independent failing contract.

### Optimized fully native workstation qualification

`build/i386-heap-seek-selfhost-workstation/result.json` now PASSes on the
fully guest-built first-generation target
`6fc8eb0b3ebc632e58f6b1d4fcf1dfc5f0350233648fbf62fb7b3d215cfcb63b`.
The 8 MiB `486,-fpu` TCG run completes 513 native commands / 576 submitted
lines, all exact VGA checkpoints and 20 document development cycles with
exact shared task data/code heap recovery. Startup is 33.014209438 seconds;
long-document visible update is 0.372473826 seconds, below the planned
one-second limit. The unchanged 60-second startup checker PASSes in
`build/i386-heap-seek-selfhost-workstation-budget.json`; its input evidence
SHA-256 is `7d67d64824c47633660545f8957888137c629062eafd7a07c19e0b774ee2e917`.

This closes the current first-generation workstation gate. The live
second-generation retained build is still compiling ConsoleRuntime; final
installed-byte comparison, second-generation flat construction/audits and
release qualification remain pending. CPU-trap continuation remains failing.
Kernel/Compiler and the live build driver remain unchanged.

### Optimized second-generation retained reproducibility

`build/i386-heap-seek-gen2-native-build/result.json` PASSes all six guest-built
providers and exact comparison with installed first-generation target
`6fc8eb0b3ebc632e58f6b1d4fcf1dfc5f0350233648fbf62fb7b3d215cfcb63b`.
CompilerRuntime, CompilerProbe, ConsoleRuntime, MemoryRuntime, FileRuntime
and Startup each reproduce their first-generation payload bytes exactly.
The resulting writable construction disk SHA-256 is
`60adc1af0035d086d7bd3fb24ee14ba626e46ce1a5f52fcf37ee052d33457d92`.
Export checks and ConsoleRuntime allocation-wrapper checks also pass.

Installation and independent boot are running in
`build/i386-heap-seek-gen2-native-install`. This retained-provider result
does not establish second-generation flat-kernel construction, complete
image reproducibility, debugger completion or release readiness.

Second-generation exact retained installation and independent 8 MiB KVM
`486` boot now PASS in `build/i386-heap-seek-gen2-native-install/result.json`.
All six installed payload bytes match their guest-built inputs; the source
and installed candidate are preserved during the boot test. Independent
`6*7` and `DocAllocationCheck` checks pass. Candidate SHA-256:
`93c5539e0bcdb28dc8826cf5355ed752374191f1e210cc6769b5d7b48b254a98`.
This boot is not a no-FPU TCG timing measurement.

Second-generation flat construction is running in
`build/i386-heap-seek-gen2-selfhost`, using both verified retained build and
installation reports. Its command is:

```sh
python3 tools/test-i386-selfhost-install.py \
  --disk build/i386-heap-seek-gen2-native-install/candidate.img \
  --retained-build-result build/i386-heap-seek-gen2-native-build/result.json \
  --retained-install-result build/i386-heap-seek-gen2-native-install/result.json \
  --out build/i386-heap-seek-gen2-selfhost \
  --accel kvm --cpu 486 --qmp-stdio --command-timeout 3600
```

After it passes, audit the installed image with `--guest-compiler-template`
and compare generation module/flat bytes and installed boot areas with
`tools/audit-i386-generations.py`. These verdicts remain pending.

Current fully guest-built three-boot DolDoc qualification is running in
`build/i386-heap-seek-selfhost-doldoc-session` with `486,-fpu` and QMP stdio,
using first-generation target 6fc8eb0b as the preserved source. It exercises
creation/replacement, persisted-byte and RedSea checks, reboot/reopen and
execution, plus interrupt recovery. No final verdict or current-image
interrupt-latency pass is available yet.

Second-generation flat construction, installation and independent boot PASS
in `build/i386-heap-seek-gen2-selfhost/result.json`. All twelve modules are
guest-built with verified retained-provider provenance. Target SHA-256:
`f4ac63ed0c0f5cf645d1c8f6ff02931d728ac56dbf87f9b10628e1630209282e`.
Installed instruction/boot/RedSea/keyword audits PASS in
`build/i386-heap-seek-gen2-selfhost-audit/result.json`.

`build/i386-heap-seek-generation-identity/result.json` PASSes exact comparison
of all twelve modules, the 486472-byte flat kernel and installed boot areas
against first generation 6fc8eb0b. Flat SHA-256:
`8d2f831e07580b1c240defadbfe37140821ae979db743fa50bbe6285b791626b`.
Boot-area SHA-256:
`7a03603c6e65292c9bfb08c86007e97e42cd60329af1fc1db7e97f0c44c2b3c3`.
Both RedSea volumes have 16 directories, 865 files and 18819 owned sectors,
with allocation bitmap matching reachable extents. Whole disk SHA values
differ; this verdict establishes artifact and boot reproducibility.
The live three-boot DolDoc workflow, full debugger functionality/API parity
and release qualification remain separate requirements.

### Current fully native resource bounds

`build/i386-heap-seek-selfhost-resource-profile/resource-result.json` PASSes
on first-generation target 6fc8eb0b with 8 MiB `486,-fpu` TCG. All 20 document
development cycles recover the exact shared task heap. Live baseline is
1352496 bytes, live peak 1356112 bytes and reserved peak 1356800 bytes;
temporary live growth is 3616 bytes. Public data/code counters both report
the same shared arena, so these values must not be added together. Arena
base 1114112 plus size 7143424 fits within installed 8 MiB RAM.
This measures the exercised document corpus, not every possible workload.
The three-boot persistence/interrupt workflow remains running separately.

### Current fully native persistence and speaker qualification

`build/i386-heap-seek-selfhost-doldoc-session/result.json` PASSes all three
8 MiB `486,-fpu` boots on preserved first-generation target 6fc8eb0b.
Creation/edit/save, reboot/reopen, revised re-execution, nested/relative
paths and rename/move/delete cycles pass with exact VGA and persisted-byte
checks. The final RedSea bitmap matches reachable extents (18 directories,
882 files, 18840 owned sectors). Source image remains unchanged.
Interrupt-to-recovery VGA is 0.216029367 seconds, below one second. Startup
is 33.326298730 / 33.073723438 / 33.236156186 seconds; all three formal
startup checks pass in the stage-specific `-budget.json` reports.

`build/i386-heap-seek-selfhost-speaker/result.json` also PASSes: captured
440/880 Hz waveform and off/reset no-emission intervals, with no emission
errors and unchanged source. WAV SHA-256:
`ccbdd47558db00e97d401cf3095738d8ed7c76dfbc9c398a1dc5ebb8f61f82e7`.
These are emulator verdicts. Full CPU debugger/API parity and current release
packaging/publication remain open.

### Current native CPU breakpoint baseline

`build/i386-heap-seek-selfhost-cpu-trap-red/result.json` FAILs on the qualified
first-generation target 6fc8eb0b, with source image preserved. Checker SHA:
`50e93b3703532900221720901765fe33cddda0f37e841912b20023aaf1e1df38`.
Preparation succeeds; actual vector 3 at EIP 0x281BDA reaches KernelFault
and halts. Continuation/EAX/IF/TF/debugger-mode assertions do not execute.

The implementation experiment uses `build/cpu-trap-resume-prototype`, a
main-only isolated checkout with the user's fork remote. Required design:
copy the normalized CPU frame into task-owned state without allocation,
yielding or enabling IF in exception dispatch; redirect exception return
to a normal-task trampoline; enter the existing debugger only after IRET
restores the interrupted execution flags; resume the saved EIP with exact
register restoration and explicitly controlled TF. Reject unsupported or
nested traps safely. Forced task exit must reclaim debugger state without
resuming a dead task. The console service ABI must carry capture and normal
context entry separately. This design is not yet implemented or verified.

The initial continuation contract remains only the first CPU-debugger step.
Register inspection/editing, explicit G target, single-step/debug exceptions,
managed breakpoints and concurrent-task ownership need their own observable
contracts before the full debugger requirement is complete. Retain the
qualified baseline image and repeat instruction/size/workstation/native
construction checks after any promoted implementation change.

The isolated CPU-trap prototype now contains task-owned normalized-frame
storage, separate capture/debug console callbacks (experimental console ABI
37), normal-context debugger entry and a complete POP-segments/POPAD/IRET
return trampoline in the existing ExceptionEntry module. It accepts only
vector 3 with CS=8 and saved IF set, rejecting nested/unsupported cases.
The qualified main OS sources remain unchanged. Prototype construction
requires its own original rebuild evidence; that prerequisite is running
in `build/cpu-trap-resume-prototype/build/rebuild-test`. The initial cross
build stopped for missing prerequisite evidence, before compiling this code.
No prototype build, continuation, cleanup or size verdict is claimed yet.

### CPU breakpoint continuation: isolated first green

The prototype's original two-generation rebuild PASSes. Its cross build
PASSes instruction/keyword audits in
`build/cpu-trap-resume-prototype/build/cpu-trap-initial`, with a 483168-byte
boot kernel (728 bytes larger than qualified main). Experimental console ABI
37 required updating the isolated harness version contract.

The unchanged checker
`50e93b3703532900221720901765fe33cddda0f37e841912b20023aaf1e1df38`
now PASSes all 15 commands in
`build/cpu-trap-resume-prototype/build/cpu-trap-initial-continuation/result.json`.
Image SHA-256:
`ca66901a4340d43a4351fc66284ee11f2cb1156b47d6e4af217e29fbaa2b3623`.
Actual INT3 enters the debugger with expected function/source and task state;
G resumes with EAX 0x11223344 preserved. Debugger mode, IF/TF and shell
recovery assertions pass with exact VGA on 8 MiB `486,-fpu`; source unchanged.
Startup is 23.595790695 seconds. This contrasts with the same checker's
qualified-native vector-3 halt baseline.

The implementation remains isolated and unpromoted. Repeated traps, forced
exit/cleanup, broader register inspection/editing, stepping, managed
breakpoints and concurrent debugger ownership remain required. Full
workstation and guest-native flat size/construction qualification must pass
before promotion; the qualified native flat has only 952 bytes spare.

The CPU-trap checker now accepts `--cycles 1..20` and compares the live
shared task heap after each resumed probe against its warmed baseline.
Five cycles PASS on the isolated prototype in
`build/cpu-trap-repeat-green/result.json` (44 commands, exact VGA, EAX/IF/TF
and debugger-mode recovery, source unchanged, startup 23.691972967 seconds).
The identical checker FAILs at actual vector 3 on qualified native main
in `build/cpu-trap-repeat-red/result.json`, source unchanged. Checker SHA:
`2eb225904dfccce77d92241dfd6f5091ec65e8a26321b16b910a5410f338283d`.
This verifies repeatability and warmed live-heap recovery in the exercised
root-task path, not forced exit, backing-pool reclamation or simultaneous
debuggers. Prototype full workstation testing is running in
`build/cpu-trap-resume-prototype/build/cpu-trap-workstation`; implementation
remains unpromoted pending broader regression and guest flat-size checks.

### Forced exit from a CPU breakpoint

`tools/test-i386-cpu-debug-kill.py` compiles and executes actual INT3 in a
child terminal, verifies the breakpoint debugger via exact VGA, switches
focus, kills that child and enters the explicit debugger in its survivor.
The survivor evaluates 6*7, returns through G, exits and recovers the parent
public heap exactly. All 13 commands PASS on prototype ca66901a in
`build/cpu-trap-kill-green/result.json` (8 MiB `486,-fpu`, source unchanged).
The identical checker FAILs at actual vector 3 on qualified native main
in `build/cpu-trap-kill-red/result.json`, source unchanged. Checker SHA:
`e4fc058ffdfd45bf705112daaa414785fe86106de19cca1dcdc1bc985bb441ae`.
This establishes the exercised forced-exit/cleanup path, not simultaneous
debugger sessions or exhaustive private-resource accounting.

Full prototype workstation testing remains live in `cpu-trap-workstation`;
its guest six-module flat-development build is live in
`build/cpu-trap-resume-prototype/build/cpu-trap-flat-development`. The latter
uses verified cross-built retained inputs and is a size/construction check,
not a fully native retained-provider or release verdict. OS sources remain
frozen during these jobs and are not promoted to main.

The initial prototype guest flat-development build fails at ExceptionEntry:
its second top-level `asm` block is rejected (`Invalid top-level assembly
entry`). The cross build accepted it, so cross-only proof was insufficient.
Evidence is retained in its `build/debug.log` and
`construction-failure.json`. The driver was intentionally stopped with
SIGINT after the observed rejection (terminal exit 130), not restarted for
a polling timeout. No flat installation/boot verdict is claimed.

The guest compiler explicitly permits one top-level assembly bundle per
module. Move the trampoline into ExceptionEntry's existing block and place
its import with the other import before emitted code. Verify the combined
bundle stays within the existing 256-byte and relocation bounds, rebuild
and repeat the guest construction. The live workstation run still uses
the initial immutable image; prototype sources remain frozen until it
finishes. Main OS sources remain unchanged.

`tools/test-i386-cpu-register-resume.py` checks distinct markers in two
register banks (`--bank 0`: EAX/EBX/ECX; `--bank 1`: EDX/ESI/EDI), keeping
each source line within the 255-byte console limit. Both banks PASS three
real trap/resume cycles on prototype ca66901a, in
`build/cpu-trap-registers-bank0-v2/result.json` and
`build/cpu-trap-registers-bank1-v2/result.json` (30 commands each, exact VGA,
source unchanged, warmed heap and IF/TF/debugger-mode assertions).
The preliminary oversized-line run and 128-byte marker-search runs did not
execute traps and are not CPU register failures. The tested revised search
window is 256 bytes. This covers six general-register markers, not complete
register inspection/editing or stack/segment/flags preservation under every
condition. The full prototype workstation remains live in mouse tests;
assembly-layout correction and guest flat construction remain pending.

Initial CPU-trap prototype workstation integration now PASSes in
`build/cpu-trap-resume-prototype/build/cpu-trap-workstation/result.json`: all
513 commands/576 lines, exact VGA and 20 exact shared-heap recovery cycles.
8 MiB `486,-fpu` startup is 23.802352321 seconds; the formal budget PASSes
in `build/cpu-trap-initial-workstation-budget.json`. Long-document update
is 0.375444596 seconds, below one second. This does not erase the same
prototype's guest ExceptionEntry compilation failure.

The trampoline is now merged into ExceptionEntry's single existing assembly
block, with KernelDebugCpu imported before code, in main-only isolated
`build/cpu-trap-layout-prototype` (fork remote). The provenance guard correctly
rejects reuse of the older original rebuild after this source edit. A fresh
original two-generation rebuild is running there; corrected cross/guest
construction and runtime verdicts remain pending. The initial checkout and
qualified main images remain preserved.

### Merged CPU trampoline layout

The corrected layout checkout passes a fresh original rebuild and cross
construction/instruction/keyword audits in
`build/cpu-trap-layout-prototype/build/cpu-trap-layout`. All twelve T32Ms
and Kernel32.BIN are byte-identical to the initial prototype; comparison
PASSes in `build/cpu-trap-layout-byte-comparison.json`. Thus its emitted
workstation code matches the initial 513-command qualified prototype.

Five-cycle continuation also PASSes on the corrected image in
`build/cpu-trap-layout-repeat/result.json`, using the current main checker.
The six-module guest flat-development rebuild is live in
`build/cpu-trap-layout-prototype/build/cpu-trap-layout-flat-development`.
A direct guest ExceptionEntry compilation check is live in
`build/cpu-trap-layout-top-asm` to verify the specific prior rejection.
Neither guest verdict is available yet; flat size and promotion remain
pending. These builds keep cross-built retained providers explicit.

The merged layout's direct guest compilation rejected `SUB`. Its full flat
run was stopped intentionally after that independent rejection (exit 130).
Replacing `SUB ESP,68` with supported signed-immediate `ADD ESP,-68`
now passes a fresh original rebuild, cross instruction/keyword audits
(483168-byte kernel), direct guest ExceptionEntry construction in
`build/cpu-trap-add-top-asm/result.json` and five-cycle continuation in
`build/cpu-trap-add-repeat/result.json`. The direct native assembly bundle
therefore passes the existing compiler bounds without broadening its
assembler. The prior SUB rejection remains historical evidence.

Full six-module guest flat-development construction is now running in
`build/cpu-trap-layout-prototype/build/cpu-trap-add-flat-development`, with
verified cross-retained inputs. Flat size/install/boot remain pending;
prototype OS code is not yet promoted.

### Corrected CPU trampoline guest flat construction

`build/cpu-trap-layout-prototype/build/cpu-trap-add-flat-development/result.json`
PASSes six guest-built flat modules, installation and independent 8 MiB boot.
Flat size is 487304 bytes, leaving 120 bytes before the current loader limit.
Flat SHA-256:
`dd9a2080f5d89010e1827ae9727e456ccc5e0caab81ee762ec73534abe435218`.
Target SHA-256:
`d0eaadccedb1b3708620ac5bc6efe9bda3d780c7fe15b1837c058aa631337cc3`.
Retained inputs are verified cross-built development providers: this is not
a fully native twelve-module result. Installed instruction/boot/RedSea and
keyword audits PASS in `build/cpu-trap-add-flat-audit/result.json`.

Both three-cycle register banks and forced CPU-debugger child exit PASS on
the corrected cross image in `build/cpu-trap-add-bank0`, `-bank1` and `-kill`.
Five-cycle continuation on the installed guest flat image is live in
`build/cpu-trap-add-flat-repeat`. Promotion is pending that verdict.
Full native providers, updated generations and release qualification must
be repeated after promotion. Further debugger features will require
addressing the near-full boot payload rather than waiving its size limit.

### Initial CPU continuation promoted to main

Main now includes the corrected task-owned CPU frame and normal-context
debugger bridge/trampoline, with console ABI 37. Capture handles same-ring
vector 3 with saved IF enabled; unsupported/nested faults retain the fatal
path. Existing debugger cleanup supports the tested forced-child-exit path.
G restores the captured registers/EIP/flags with TF cleared.

Fresh main original rebuild and `build/cpu-trap-main` construction/audits
PASS. All twelve modules plus Kernel32.BIN match the corrected prototype
exactly (`build/cpu-trap-main-byte-comparison.json`). Installed guest flat
five-cycle continuation PASSes in `build/cpu-trap-add-flat-repeat`.
This promotion establishes initial breakpoint continuation only. Main's
updated fully native provider/generation qualification and remaining CPU
debugger functionality still need implementation/testing; 120-byte guest
flat headroom is not sufficient justification to drop any planned feature.

Promoted main now independently PASSes five-cycle continuation in
`build/cpu-trap-main-repeat/result.json`. All six retained providers are
rebuilding natively in `build/cpu-trap-main-native-build`, using current
`build/cpu-trap-main/exports` contracts and 3600-second command budgets.
CompilerRuntime remains live; no fully native result for this epoch exists
yet. Kernel/Compiler sources and the loaded build harness stay frozen.

### BIOS fixed-load boundary baseline

`tools/test-i386-boot-load-boundary.py` puts a nonzero marker at the final
permitted payload byte in a preserved standard disk copy, boots it with
8 MiB `486,-fpu` QEMU, and checks the byte in guest RAM plus 6*7 through
exact VGA. It PASSes in `build/cpu-trap-main-boot-boundary/result.json`: the
487424-byte load window reaches address 0x87FFF, with unchanged filesystem
bytes and source image. Startup is 23.897774333 seconds. This exercises
the BIOS boundary of the present payload format, not an independently
linked maximum-size kernel or oversized/truncated-publication rejection.
Those contracts and boot-capacity implementation remain open.

`tools/test-i386-boot-payload-rejection.py` defines six guest publication
rejection cases and requires the complete target disk to remain unchanged.
Its current run `build/cpu-trap-main-payload-rejection-v3` FAILs during
fixture creation: public FileWrite is an undefined identifier. No installer
rejection assertion executes. The preliminary first run stopped on output
from top-level fixture assignments; helpers now avoid that output.

The file-service write callback exists and DocWrite uses it, but public
FileWrite binding/parity is missing. Implement and independently qualify
that original public API, then rerun these publication cases. Do not label
this fixture failure as oversized-payload rejection evidence. Truncated
executable integrity and maximum-size linking remain separate open gates.

Original source audit corrects FileWrite fixture expectations: successful
nonempty RedSea FileWrite returns the cluster, not TRUE. The publication
fixture now tests `FileWrite(...)>0`. Original signature includes cdt and
attr defaults; original RedSea empty-file success returns INVALID_CLUS (-1).
Public FileWrite remains unimplemented; this fixture correction is not a
green publication verdict. PLAN.md records independent metadata/return,
error, empty-file, timestamp/attribute and compressed/resident parity work.
The current retained rebuild is live in ConsoleRuntime after compiler
providers; main OS sources remain frozen for that qualification epoch.

### Original public FileWrite contract baseline

`tools/test-i386-public-file-write.py` creates an embedded-NUL/binary payload
through the original five-argument API and compares the positive returned
cluster with an independent persisted directory record. It also requires
exact four bytes, explicit timestamp 0x1122334455667788, contiguous attribute
0x800, valid RedSea ownership and preserved source image.

`build/public-file-write-red/result.json` currently FAILs at the FileWrite
call/declaration (frontend Invalid lval). Payload and report-helper preparation
pass, but no file or metadata assertion executes. The earlier rejection
fixture independently reports FileWrite undefined. This is failing API
coverage, not a successful filesystem test. Existing Boolean internal writes
are not sufficient to satisfy this public cluster-return contract. Empty,
error, replacement, default-date, compression and resident parity remain
additional planned contracts. Native CPU-trap provider qualification remains
live on main; its Kernel/Compiler source epoch stays frozen.

All six promoted CPU-trap providers now PASS native construction, export
contracts and console allocation-wrapper checks in
`build/cpu-trap-main-native-build/result.json`. Exact installation and
independent boot are running in `build/cpu-trap-main-native-install`.
Updated native flat/generation/workstation/release verdicts remain pending.

The main-only isolated `build/file-write-prototype` now contains an initial
FileWrite cluster-return service path, explicit timestamp propagation and
public five-argument binding. Its fresh original rebuild PASSes; cross
construction is running in its `build/file-write`. The public metadata
contract has not passed. This experiment currently handles contiguous
ordinary writes only; default Now, compression/resident semantics and
compatibility of existing internal write callers still require work before
promotion. Main Kernel/Compiler sources are unchanged for native qualification.

Promoted CPU-trap exact native-provider installation and independent 8 MiB
boot PASS in `build/cpu-trap-main-native-install/result.json`. Fully native
six-module flat reconstruction is running in `build/cpu-trap-main-selfhost`,
with both required retained provenance reports. Final flat/native debugger
workflow and generation qualification remain pending.

The first FileWrite prototype cross build passes, but both public metadata
and boot rejection runs stop during ROOT USER HEADERS: PublicFiles uses
CDate before DateTypes is included. These are startup failures, not file
contract passes. The isolated header now includes DateTypes explicitly,
and the legacy Boolean wrapper retains its previous negative-size rejection
and attribute behavior while the new public core is developed separately.
A fresh original rebuild is running before corrected cross construction.
Default Now, compression/resident behavior and complete API parity remain
open; no FileWrite implementation is promoted to main.

Corrected FileWrite header cross construction/audits PASS in the isolated
`build/file-write-headers`. All six oversized/header/entry publication
rejection cases PASS in `build/boot-payload-rejection-headers-green`, with
the entire target disk unchanged and preserved original source.

The public FileWrite guest commands pass, and independent raw metadata
comparison PASSes in `build/public-file-write-headers-green/metadata-observation.json`:
returned cluster matches the persisted entry, bytes are A/NUL/B/0xFF,
length is four, date is 0x1122334455667788 and attributes are 0x800.
The full contract result remains FAIL: verify_mutated_volume rejects any
nonzero file date, a historical zero-date fixture assumption incompatible
with the explicitly requested timestamp. Correct that general audit policy
without dropping extent/bitmap checks and rerun the unchanged contract.
Default Now/compression/resident behavior and broader FileWrite tests remain
open; the partial prototype is unpromoted.

### Dated regular-file auditing and first public write green

verify_mutated_volume now accepts nonzero timestamps on regular 0x800 files;
all extent/ownership/bitmap/name and existing directory fixture checks remain
enforced. `tools/test-i386-redsea-date-audit.py` PASSes the dated file image
and rejects independently mutated overlapping/out-of-volume extents, flipped
allocation bitmap and invalid name (`build/redsea-date-audit-test.json`).

The unchanged public FileWrite contract now PASSes end to end in
`build/public-file-write-date-audit-green/result.json` on the isolated
prototype: actual cluster return, exact binary bytes, explicit timestamp,
contiguous attributes and full filesystem integrity/source preservation.
This first ordinary-write green does not establish default Now, replacement,
error/empty/compressed/resident behavior or full FileWrite parity. The OS
implementation remains isolated.

The promoted CPU-trap fully native twelve-module image PASSes construction,
installation and independent boot in `build/cpu-trap-main-selfhost`, with
487304-byte flat SHA dd9a2080 and target SHA
`b43b2e027a917f244d2a2fe2e1a97144b6ec05b45fd3e70cb830d4fa2f19a565`.
Installed 386/boot/RedSea/keyword audits PASS in its `-audit` directory.
Five-cycle continuation remains running in `build/cpu-trap-main-selfhost-repeat`.
Current workstation, second-generation and release qualification remain open.

The fully native promoted debugger image now PASSes five-cycle continuation
in `build/cpu-trap-main-selfhost-repeat`, with exact VGA and preserved source.
Startup is 33.224857890 seconds; its formal `-budget.json` verdict PASSes.
Full workstation is running in `build/cpu-trap-main-selfhost-workstation`.
Second-generation retained construction/exact installed comparison is running
in `build/cpu-trap-main-gen2-native-build`, using current cross export contracts.

`tools/test-i386-public-file-write-lifecycle.py` PASSes all nine commands
and independent filesystem/metadata checks on the isolated prototype in
`build/public-file-write-lifecycle-green`: replacement binary bytes and
cluster return, explicit replacement timestamp, empty/negative-size success
return -1 with no data extent, invalid-parent zero return/no file, valid
bitmap and source preservation. The same checker FAILs at undefined FileWrite
on current main in `build/public-file-write-lifecycle-red`. These ordinary
write cases do not establish default Now, compressed/resident semantics,
exhaustive failure recovery or complete public file API parity. Implementation
remains isolated while native qualification runs.

### FileWrite default-date failing contract and RTC prototype

`tools/test-i386-public-file-write-now.py` independently compares the
persisted default-date binary file against the host UTC execution interval
(with explicit 120-second tolerance), cluster return and attributes.
`build/public-file-write-now-red/result.json` FAILs on the explicit-date-only
prototype: the file date is zero, outside that interval. Guest writes and
filesystem checks execute; this is a real default-date semantic failure.

The isolated FileWrite prototype now uses a bounded consistent RTC snapshot
for zero cdt, with interrupt-protected CMOS access, BCD/12-hour decoding and
Struct2Date minus local_time_offset. It retains the original 2000-based
two-digit year convention and the boot RTC's disabled-NMI selector policy.
Its fresh original rebuild is running before cross/runtime qualification.
No default-date green is claimed; clock modes/offset/boundary/error cases
need broader tests. Main OS sources remain unchanged while native workstation
and second-generation provider checks run.

RTC-backed FileWrite prototype original rebuild and cross audits PASS in
`build/file-write-prototype/build/file-write-now`. The default-date contract
now PASSes in `build/public-file-write-now-green`, including independent UTC
interval, raw binary/cluster/attribute metadata and complete filesystem audit.
The nine-command ordinary lifecycle regression PASSes on that image in
`build/public-file-write-now-lifecycle`.

The clock checker also accepts `--offset-days -1|0|1`. Both +1 and -1 cases
PASS in `build/public-file-write-offset-plus` and `-minus`, proving persisted
date follows RTC-derived UTC minus local_time_offset. These runs use the
explicit 120-second clock tolerance. They do not exercise all RTC encodings,
update-boundary/failure conditions or centuries; those remain required
coverage, alongside compression/resident semantics and full native/size
qualification before any FileWrite promotion. Main native workstation and
second-generation provider checks remain live on their unchanged OS epoch.

Fully native CPU-trap workstation qualification PASSes all 513 commands,
exact VGA and 20 exact heap-recovery cycles in
`build/cpu-trap-main-selfhost-workstation/result.json`: startup 33.068386981
seconds, visible long-document update 0.204777493 seconds. The formal
`-budget.json` startup verdict PASSes. Gen2 retained construction/comparison
remains live; full release qualification is still open.

`tools/test-i386-public-file-write-compressed.py` specifies original filename
inference: write ASCII HolyC source as .HC.Z, include it and execute its
function, then independently check date/0xC00 attributes and a CT_7_BIT
archive header with correct persisted and expanded lengths.
`build/public-file-write-compressed-red` FAILs on the ordinary-write prototype
after FileWrite succeeds: include reports COMMAND ERROR. No execution or
archive metadata assertions pass. The prototype writes raw bytes for .Z.
Implement the original 7/8-bit compression algorithm and filename/attribute
semantics, with fallback only where the original requires it, plus resident
cache compatibility. Do not substitute an always-uncompressed archive for
full compression behavior. FileWrite remains unpromoted.

Integrated cache/Cd native generation equality and stepped-task teardown
verified (2026-10-05): the integrated generation pipeline completes PASS.
An independent rerun in build/file-cd-resident-integrated-generation-identity-recheck
confirms twelve identical native modules, a 487336-byte identical flat kernel,
and identical installed boot area across both generations. Flat SHA-256:
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f.
Boot-area SHA-256:
39c511c316094a6cf4dcdd01aab0f77b307637e1a6772861ad9764eca09a360f.
Both volumes have 16 directories, 872 files and 19073 owned sectors with
bitmaps matching reachable extents. Whole disk images differ; this gate
claims module/flat/boot equality, not whole-volume byte equality.

build/debug-single-step-forced-kill/result.json passes --single-step:
13 commands on 486,-fpu / 8 MiB, exact VGA, startup 28.422164 seconds,
source image unchanged. A terminal is killed after vector-1 step reentry;
the survivor can enter Dbg, evaluate, resume and exit, with parent public
heap recovery. The checker report now names the selected entry path.
This verifies stepped-task teardown, not complete private-resource or
register/breakpoint coverage. Integrated no-FPU retained builder PID 3614380,
single-step retained builder PID 3631600 and workstation QEMU PID 3631601
remain directly confirmed live. Their pending results are separate gates;
main OS source remains ABI 40 and no release completion is claimed.

Captured EAX inspection/editing first runtime green (2026-10-05):
the register candidate passes fresh original two-generation bootstrap;
all 1269 source-manifest hashes are independently rechecked. Cross build,
31 FileRuntime binding guard and 386 boot audit pass (96 BIOS / 33 protected
mode instructions). Native kernel stays 483208 bytes. Candidate image SHA:
e4982d319372819149be514d3c3a4b63bc90c9238ebf6d39055de717a520cc64.

The first candidate runtime run failed only because pointer assignment prints
its dynamic address. A visually inspected screenshot establishes this fixture
mismatch, not an OS failure. The checker now evaluates the assignment's
non-null comparison and expects 1, avoiding address-dependent VGA output.
build/debug-register-edit-nonnull-green/result.json passes 17 commands on
486,-fpu / 8 MiB, startup 25.954454 seconds, all exact VGA checkpoints and
unchanged source. TaskRegAddr reads captured EAX=0x11223344; writing the
original I64 pointer changes the next stepped store and final G result to
0x55667788. Mode/flags and shell recovery pass. Five repeated cycles run in
build/debug-register-edit-repeat; the matching stable-output baseline red
runs in build/debug-register-edit-nonnull-red. Their results remain pending.
This is one register's semantic green, not full debugger or release coverage.

The unchanged single-step candidate now passes six-module native construction
in build/debug-single-step-native-build. Its dependent retained installation
is directly confirmed live as PID 3640181. Full native generations remain
pending. The register candidate has not yet passed its own native generation
or full workstation gates and remains an archived isolated implementation.

Step workstation green and independent register-cycle fixtures (2026-10-05):
build/debug-single-step-workstation/result.json passes all 513 commands on
486,-fpu / 8 MiB, startup 26.706914 seconds and visible long-document update
0.266207 seconds. Exact VGA and twenty exact shared-heap development cycles
pass. This is the unchanged step-enabled candidate, not the newer register
candidate's workstation qualification.

The five-cycle EAX checker fails before completing its first interaction.
Inspection finds a fixture aliasing bug: base repetition shares one interaction
object and the register wrapper inserts its actions once per repeated list
entry. A new two-cycle ECX run also terminates before qualification; preserve
both failures. The wrapper now deep-copies each check independently before
inserting actions. A construction check proves five distinct interaction
objects, each with exactly one TaskRegAddr call. Corrected EAX repetition
runs in build/debug-register-edit-independent-repeat; runtime remains pending.

New tools/test-i386-debug-register-banks.py extends the semantic fixture to
EAX/ECX/EDX/EBX/ESI/EDI using their original register numbers. Each selected
register is loaded before INT3 and supplies the subsequent store; debugger
pointer inspection/editing must change its stepped result. All six fixtures
construct within the console input limit, with dependency hashes pinned.
The corrected two-cycle-per-register chain runs in
build/debug-register-banks-independent-pipeline.py; results are pending.
EBP/ESP, instruction-pointer/flags edits, complete other-task state and release
coverage remain open. Register candidate six-module native construction is
directly confirmed live as PID 3641122; prior step-source native builds cannot
substitute for it. Candidate sources and main OS remain unchanged.

Repeated register editing and wider candidate qualification (2026-10-05):
build/debug-register-edit-independent-repeat/result.json passes five EAX
inspection/edit/store/S/G cycles and 49 commands, exact VGA, startup 26.964408
seconds on 486,-fpu / 8 MiB, unchanged image and pinned dependencies. This
confirms the fixture aliasing correction and repeated EAX semantics including
existing warmed public heap/mode/flag checks. The bank chain's ECX test passes
two cycles and 25 commands, startup 27.217041 seconds; EDX is running, other
bank verdicts remain pending. Complete register coverage is not claimed.

The register candidate full 513-command workstation runs in
build/debug-register-workstation (Python 3641740 / QEMU 3641741), and
stepped-task teardown runs in build/debug-register-forced-kill (3641747 /
3641748), both 486,-fpu / 8 MiB. Six retained native modules are being built
by directly revalidated PID 3641122. A dependent chain, directly live as
3641972, requires that exact build before installation, full native flat
construction and installed audit, then a second retained build with exact
installed comparison, installation/full flat/audit and twelve-module/flat/
boot identity. Outputs are build/debug-register-{native-install,selfhost,
selfhost-audit,gen2-native-build,gen2-native-install,gen2-selfhost,
gen2-selfhost-audit,generation-identity}. Its prototype auditor and matching
stage listing are used. No pending gate is a pass, and earlier step/cache
candidate evidence cannot qualify the updated register console. Main remains
unchanged while candidate sources are pinned. No release completion claimed.

Wider register editing and explicit G address TDD (2026-10-05):
the corrected bank chain passes ECX/EDX/EBX/ESI/EDI, each two semantic
edit/step/resume cycles with 25 commands, exact VGA and unchanged image.
Startup seconds respectively 27.217041, 33.844262, 27.508514, 29.485299,
30.344232. The final EAX bank run remains pending; its separate five-cycle
EAX gate already passes. This does not cover EBP/ESP or other-task contexts.
build/debug-register-forced-kill/result.json passes stepped-task teardown
on the register source, 13 commands, startup 33.758595 seconds, exact VGA,
unchanged image, surviving debugger and parent public heap recovery.

New tools/test-i386-debug-go-address.py specifies original G(ip) behavior:
a real INT3 stops before MOV EAX,0x55667788; explicit G skips that verified
five-byte instruction so a subsequent store preserves 0x11223344. Ordinary
continuation would store 0x55667788, making the chosen-IP effect observable.
Opcode and all immediate bytes are checked before the trap. The first run
build/debug-go-address-red failed at setup because pointer assignment printed
an address; this is fixture failure, not OS evidence. The corrected fixture
assigns inside a U0 helper and runs in build/debug-go-address-quiet-red.
Verdict remains pending. It preserves independent repeated interactions and
pins dependencies; other-task resume and managed breakpoints remain open.
Register full workstation/native generations remain pending on unchanged
sources. Release completion and promotion are not claimed.

Six-register edit chain complete; explicit-address resume red established
(2026-10-05): build/debug-register-banks-independent-pipeline.json passes
all six EAX/ECX/EDX/EBX/ESI/EDI runs, each two cycles, 25 commands, exact VGA,
pinned dependencies and unchanged candidate image. EBP/ESP and complete
other-task state remain open; this is not complete debugger coverage.

build/debug-go-address-quiet-red terminates FAIL at G(CpuResumeIp) after
opcode/immediate-byte and pre-store checks pass and a real INT3 debugger
entry. Debug output records THROW DbgArg; the final VGA checkpoint shows
G(CpuResumeIp) failing to resume. This establishes the intended missing
explicit-address behavior, separate from the earlier setup-output failure.

A main-only fork-origin clone build/debug-go-address-prototype now sets the
saved exception EIP and public task RIP for explicit G/S addresses while
preserving default behavior. Explicit address in a non-CPU debug session
still raises DbgState; other-task arguments remain unimplemented. Its fresh
original two-generation bootstrap passes with all 1269 source hashes
independently verified. Cross build is running; no runtime green is claimed.
Full source archive docs/patches/i386-debug-go-address-candidate.patch applies
cleanly to main. Earlier register and step sources remain unchanged during
live native/workstation/generation qualification. Release remains open.

Explicit G/S address observable greens (2026-10-05): candidate cross build
passes 31 bindings and 386 boot audit, 96 BIOS / 33 protected instructions;
kernel remains 483208 bytes. Image SHA-256:
e166c4767d1b036b50b49520ad653444318b58cc7d50cc91f048acf12118908e.
build/debug-go-address-green/result.json passes explicit G(ip) skip/store/
return semantics with 17 commands, startup 33.702441 seconds, exact VGA,
restored mode/flags and unchanged source on 486,-fpu / 8 MiB.

New tools/test-i386-debug-step-address.py derives the same verified skip
fixture, invokes S(ip), requires fresh vector-1 debugger reentry after the
chosen store but before function completion, and then G back. Baseline
build/debug-step-address-red fails with THROW DbgArg after the trap;
build/debug-step-address-green/result.json passes all 17 commands, startup
34.285580 seconds, exact VGA and unchanged source. This establishes both
address-resume and address-step behavior, not argument acceptance alone.
Repeated interactions stay independent and all imported test sources are
hash-pinned. Explicit addresses in non-CPU sessions and other-task resume,
ESP/RIP direct edits, managed breakpoints and complete debugger coverage
remain open; no release completion or promotion is claimed.

Five G(ip) cycles run in build/debug-go-address-repeat and five S(ip) cycles
in build/debug-step-address-repeat. This changed console's six native modules
build in build/debug-go-address-native-build (KVM); earlier step/register
native outputs cannot qualify it. All three current-source gates are pending.
Register-source full workstation/generation and original step generation
qualification continue on their unchanged sources.

Repeated explicit-address cycles and tracked native-generation runner
(2026-10-05): build/debug-go-address-repeat/result.json and
build/debug-step-address-repeat/result.json each pass five cycles and 49
commands on 486,-fpu / 8 MiB, exact VGA, restored mode/flags, warmed public
heap checks and unchanged image. Startup 31.922704 / 32.074851 seconds.
These qualify repeated current-task G(ip)/S(ip), not other-task resume or
complete debugger/release behavior. Native builds remain pending.

New tools/test-i386-native-generations.py replaces candidate-specific temporary
chain scripts for future qualification. It consumes an already qualified six-
module retained build and matching candidate repository/stage listing, then
runs retained install, native flat construction and installed audit, a second
retained build with exact installed comparison, second install/flat/audit,
and twelve-module/flat/boot equality. It preserves stage logs and results,
pins candidate source files including untracked HC/HH candidates plus tools,
and checks inputs/source identity before and after stages. Each stage must
report PASS; native retained origin must be guest-built supplied inputs.
It requires a fresh output directory, preserving previous evidence.
Python syntax/help pass. Actual CLI negative checks reject an incomplete
provider set before creating output, and refuse an existing evidence directory.
Full runner execution remains pending; existing live chains are not restarted.
No release-ready qualification claim is made from preflight checks.

Reusable native generation qualification (after retained construction passes):

```sh
python3 tools/test-i386-native-generations.py \
  --repository build/debug-go-address-prototype \
  --retained-build build/debug-go-address-native-build \
  --stage-listing build/debug-go-address-prototype/build/debug-go-address/kernel-stage.lst \
  --out build/debug-go-address-native-generations --accel kvm
```

Run with a fresh output directory. This command is documented for the pending
provider build; it has not yet completed the tracked runner's full sequence.

Explicit-address candidate broad regressions and tracked generation queue
(2026-10-05): build/debug-go-address-forced-kill/result.json passes killing
an actual step-paused task, surviving debugger use and parent public heap
recovery, 13 commands on 486,-fpu / 8 MiB, startup 37.606528 seconds,
exact VGA and unchanged source. This is current address-enabled console
teardown evidence, not substituted from its register predecessor.

Full workstation runs in build/debug-go-address-workstation (Python 3649198,
QEMU 3649199); five default S cycles run in ...-default-step. Six-register
edit regression runs in build/debug-go-address-register-banks-pipeline.py,
outputs ...-register-bank-{ecx,edx,ebx,esi,edi,eax}; all are pending.
An earlier generated launcher accidentally renamed the test tool path and
terminated before testing; its failure is preserved in
build/debug-go-address-banks-independent-pipeline.json. The corrected chain
uses the unchanged tracked register-bank test and proper address-candidate
image. No runtime failure or pass is inferred from the launcher error.

Native retained builder 3648197 remains directly live. The dependent process
3649325 in build/debug-go-address-native-generations-wait.py now waits for
that exact handle and requires six PASS modules, with the tracked runner's
SHA pinned while waiting. It then runs tools/test-i386-native-generations.py
into fresh build/debug-go-address-native-generations. State is
build/debug-go-address-native-generations-wait.json. This is queued first
full execution of the tracked runner; no generation PASS yet. Earlier live
step/register/native and integrated no-FPU gates continue without restart.
Main OS source remains unpromoted and the full release objective stays open.

Managed breakpoint lifecycle TDD started (2026-10-05): new
 tools/test-i386-debug-breakpoint-lifecycle.py derives a bounded executable
NOP fixture and specifies original BptS/BptR/BptFind/B/B2 return values,
duplicate installation, registration without live patching, toggle semantics,
two-breakpoint removal count and exact byte/list restoration. Two rounds
construct as 48 commands within the console input limit. Original contract
source and imported fixture dependencies are pinned. The expected red runs
in build/debug-breakpoint-lifecycle-red on the fixed address-resume candidate;
no verdict yet. This is lifecycle coverage, not managed CPU trap, rewind,
step/rearm, shared-code ownership, task-exit cleanup or original-runtime oracle.
Those remain required debugger work; no narrower completion is claimed.

Current address-source regression results: build/debug-go-address-default-step
passes five default S cycles and 49 commands, while ...-register-bank-ecx
and ...-register-bank-edx each pass two edit/step/resume cycles and 25 commands.
These establish retained default behavior alongside explicit-IP greens;
remaining banks, full workstation and native generation gates continue on
unchanged candidate sources. Release and promotion remain open.

Managed breakpoint lifecycle missing-API red and candidate implementation
(2026-10-05): build/debug-breakpoint-lifecycle-red terminates FAIL at the
first BptS(CpuBptAddr), after normal executable/NOP fixture preparation.
The frontend logs Undefined identifier and COMMAND ERROR. This establishes
the missing lifecycle entry point; no later lifecycle assertion is a pass.

A fork-origin main-only clone build/debug-breakpoint-prototype restores the
canonical CBpt shape from Kernel/KernelA.HH and the original BptFind/BptS/
BptR/B/B2 list/return/opcode semantics from Kernel/KDbg.HC. Native IRQ save/
restore replaces PUSHFD/CLI/POPFD; current task uses I386TaskSelf, with the
public allocation API for task-owned records. Five public bindings raise
console exports from 140 to 145. Fresh original bootstrap is running in
build/debug-breakpoint-candidate-bootstrap.log. Full source is archived in
 docs/patches/i386-debug-breakpoint-candidate.patch and applies cleanly to
main. This is an unqualified candidate; cross/runtime gates are still needed.
Managed trap rewind, stepping/rearming, task/code ownership and exit cleanup
remain required implementation and test work. Existing address/register/step
candidate sources are unchanged while their qualification jobs continue;
main OS remains unpromoted and release completion is unproven.

Breakpoint candidate build qualification and managed-store trap TDD
(2026-10-05): fresh original two-generation bootstrap and cross build PASS,
with 1270 source-manifest hashes independently verified, 31 FileRuntime
bindings, 386 boot audit (96 BIOS / 33 protected instructions) and unchanged
483208-byte native kernel. The lifecycle candidate's runtime gate runs in
build/debug-breakpoint-lifecycle-green; PASS is still pending.

New tools/test-i386-debug-managed-trap.py installs a managed BptS at the
actual store opcode following the bounded NOP fixture. S must restore and
execute that store before reentry; G must complete and rearm the opcode,
then B2 must remove the record and restore code. It preserves existing
result/mode/flags/public-heap checks and pins fixture dependencies.
Independent two-cycle interactions construct within console input limits.
The expected implementation-gap red runs in build/debug-managed-trap-red
on the lifecycle-only candidate; no runtime verdict yet. Original contract
inspection confirms Fault2 decrements RIP for INT3 and task switching restores
old-task breakpoint bytes/reapplies runnable-task breakpoints unless disabled.
Full native implementation must preserve those behaviors, task/code ownership
and cleanup. Current candidate does not implement rewind/step/rearm or task
switch handling; lifecycle compilation is not full debugger completion.
Earlier live qualification stays pinned; main and release readiness remain open.

Breakpoint lifecycle green and register native/workstation qualification
(2026-10-05): build/debug-breakpoint-lifecycle-green/result.json passes
28 commands on 486,-fpu / 8 MiB, startup 34.466079 seconds, exact VGA and
unchanged source. Original lifecycle return values, duplicate/live=False/
toggle/two-record clear and byte/list restoration pass. Five rounds now run
in build/debug-breakpoint-lifecycle-repeat. Managed store-trap runtime is
still pending and is not qualified by this lifecycle green.

build/debug-register-native-build/result.json passes all six native retained
modules; build/debug-register-workstation/result.json passes all 513 commands,
exact VGA and twenty exact shared-heap development cycles on 486,-fpu / 8 MiB.
Startup 33.207068 seconds, long-document update 0.340859 seconds. Retained
installation passes and full native flat construction is directly live as
3651884 / QEMU 3651885. These qualify register-source construction/workstation,
not the later address/breakpoint consoles or complete release readiness.

Managed breakpoint architecture next: the existing scheduler bind callback
runs with IRQs masked after selecting next but before context swap, while
FS still names the outgoing task. A retained wrapper can restore outgoing
record bytes, apply incoming breakpoints unless TASKf_DISABLE_BPTS, then
chain the original platform binder. Preserve its segment/current-task checks
and avoid allocation/scheduling in the hook. Captured managed INT3 needs
record lookup at saved EIP-1, rewind and original-byte restoration; S disables
breakpoint application and requests TF, G clears disable/TF and reapplies.
Direct G at a breakpoint must retain the original step/remove requirement.
Task cleanup must restore/remove records while public heaps/code still live,
including forced kill from another terminal. Shared-code ownership, other-task
registration/resume and original runtime comparisons need dedicated tests.
This design follows original Fault2 and Sched.HC behavior; it is not implemented
or proved by the existing hook alone. Candidate sources stay fixed during
qualification; main OS remains unpromoted and release scope remains intact.

Managed store-trap semantic red and isolated implementation (2026-10-05):
build/debug-managed-trap-red fails after actual managed INT3 and S reentry.
The visually inspected one-store checkpoint returns 0 for the expected
stored marker before function completion. This demonstrates lost original
instruction execution; it is separate from lifecycle API presence.
Five lifecycle rounds pass in build/debug-breakpoint-lifecycle-repeat.

A fork-only main clone build/debug-managed-prototype implements managed
record lookup at saved EIP-1, rewind, restoration and disabled breakpoint
state for S; G re-enables bytes unless still stopped on an installed
breakpoint (prints a step/remove instruction and remains in debugger).
A retained scheduler bind wrapper restores outgoing bytes, applies incoming
records unless disabled, then chains the original platform binder. It does
not allocate or schedule. First record registration installs a task cleanup
wrapper and preserves the previous callback, including registration inside
an active debugger. Cleanup restores bytes/frees records before chaining
previous cleanup while task heaps/code remain live. A private task callback
slot is added; kernel/flat-size effects still need fresh build evidence.
These paths are implemented, not yet verified by task-switch/exit tests.

Full source is docs/patches/i386-debug-managed-candidate.patch (clean apply
to main). Fresh original bootstrap runs in
build/debug-managed-candidate-bootstrap.log. Cross build, managed runtime
green, shared-code ownership, other-task controls, cleanup and broader/native
qualification remain required. Existing live source epochs stay unchanged;
no promotion, complete debugger or release readiness is claimed.

Managed candidate cross parse failure corrected (2026-10-05): original
bootstrap passes on the initial managed source, but cross build terminates
FAIL while compiling ConsoleRuntime. Preserved compiler-log.DD identifies
Debugger.HC line 143: HolyC rejects a function-pointer local declaration with
an initializer. Separate declaration and assignment correct that syntax.
The archived managed patch is updated and applies cleanly; a fresh bootstrap
runs in build/debug-managed-corrected-bootstrap.log to pin the changed source
before another cross build. No cross or managed runtime green is claimed;
size/386/cleanup/native gates remain pending. The failure is compile evidence,
not an observation timeout, and previous successful source epochs remain
untouched.

Independent progress: build/debug-register-selfhost/result.json now passes
full native flat construction/installation/boot on register source; its
second generation is pending. build/debug-single-step-gen2-native-build passes
all six modules with exact installed comparison; complete twelve-module/flat/
boot equality remains pending. Later managed/address source is not qualified
by those results. Main and release completion remain open.

Managed console integration fix and kill fixture prepared (2026-10-05):
corrected bootstrap PASSes, but the separate corrected cross build terminates
FAIL at a new integration issue. compiler-log.DD reports missing Print/PutChars
headers for the breakpoint warning's implicit string-output statement.
The candidate now uses existing I386TextWrite(&console_text,...) and a fresh
bootstrap runs in build/debug-managed-console-bootstrap.log. The source
archive is updated and applies cleanly. Neither failed build is a runtime
PASS; cross, size, 386 and managed runtime evidence remain pending.

New tools/test-i386-debug-managed-kill.py prepares parent-owned executable
code, installs its breakpoint from a child terminal and optionally steps,
then kills that child from the survivor. It requires original entry byte
restoration, successful execution of the parent function by the survivor,
surviving Dbg/G and exact parent public heap recovery. Terminal fixture hash
is pinned; both entry paths construct within console limits and syntax passes.
Runtime is not started before a usable managed candidate exists. This does
not prove all concurrent/shared-code ownership or private resource cleanup.
Existing qualification continues on unchanged earlier epochs; main remains
unpromoted and the complete release objective is still open.

Managed candidate cross green; current runtime gates started (2026-10-05):
console-output corrected original bootstrap and cross build pass. All 1270
source hashes are independently checked; 31 bindings and 386 boot audit pass
(96 BIOS / 33 protected instructions). The private cleanup slot leaves native
kernel at 483208 bytes. Image SHA-256:
86bca6ce6a1196c52a28a71024e0fe0d2792c60fd3b6b6427da4de26d59f0b52.
Managed store-step/rearm runs in build/debug-managed-trap-green, stepped
managed parent-code victim kill in build/debug-managed-kill-step, and lifecycle
regression in build/debug-managed-lifecycle. All verdicts are pending; compile
success does not prove scheduler, cleanup or managed execution semantics.

Single-step-source native generations now pass full twelve-module/flat/boot
identity. Independent rerun build/debug-single-step-generation-identity-recheck
passes: flat 487336 bytes, SHA
 a959ce9581ca34cd23d8e946a4fa6b56771975f5a3ff1d8fd16a8b2a3e0ff5b8;
boot-area SHA
 f87f7191e2a8e4ce632405fa1810aaf1a402814395ce25174de7502bf6eefd11.
Both volumes have 16 directories, 872 files, 19077 owned sectors and bitmaps
matching reachable extents; whole images differ, not claimed byte-identical.

Address-source full workstation passes 513 commands and twenty exact shared-
heap development cycles on 486,-fpu / 8 MiB: startup 37.885299 seconds,
long-document update 0.450070 seconds, exact VGA. Its six native retained
modules also pass; tracked tools/test-i386-native-generations.py is directly
live as PID 3660287 at gen1-install. Full tracked-chain completion remains
pending. Neither earlier-source generation nor workstation results substitute
for managed source qualification; main remains unpromoted and release open.

Managed breakpoint first runtime greens and deferred-registration fixture
(2026-10-05): build/debug-managed-trap-green/result.json passes 21 commands
on 486,-fpu / 8 MiB, startup 29.533144 seconds, exact VGA and unchanged source.
Managed store opcode trap rewinds, S executes the restored store before
reentry, G rearms it, and B2 removes/restores the record. Result, mode/flags
and existing public heap probe pass. This is demonstrated semantic red to
green, not just API binding. Five cycles run in ...-trap-repeat.

build/debug-managed-kill-step passes 15 commands, startup 29.425224 seconds,
exact VGA and unchanged source. Child-installed breakpoint on parent code
is stepped, victim killed, entry byte restored, shared function executes in
the survivor, then surviving Dbg/G and parent public heap recovery pass.
The initial-entry kill path now runs in ...-kill-entry. Complete concurrent
ownership/private-resource coverage and full original API remain open.

Managed-source lifecycle test terminates FAIL at the separate command after
BptS(...,live=FALSE). Its expected unpatched-byte assertion conflicts with
the original scheduler model: deferred registration avoids patching during
the call, but the next task restore applies registered breakpoints. The
checker now performs registration/byte-and-record checks/removal in one
synchronous helper before command input can yield, preserving the immediate
API contract without forbidding scheduler reapplication. Corrected runtime
runs in build/debug-managed-lifecycle-deferred; no pass yet. Preserve the
failure in ...-lifecycle. Full workstation runs in ...-workstation on this
fixed managed image. Existing candidate sources remain frozen during gates;
G2/other-task/debugger and native/release completion remain open.

Repeated managed execution/cleanup greens and G2 TDD (2026-10-05):
build/debug-managed-trap-repeat passes five managed store trap/step/rearm/
remove cycles and 69 commands on 486,-fpu / 8 MiB, startup 27.675738 seconds,
exact VGA, result/mode/flags/public-heap probe and unchanged source.
...-kill-entry passes 15 commands, startup 33.631613 seconds, restoring and
executing shared parent code in the survivor after killing a managed-entry
victim. ...-lifecycle-deferred passes the corrected immediate deferred
registration semantics and all lifecycle assertions, 27 commands, startup
27.518313 seconds. Complete concurrent ownership remains open.

New tools/test-i386-debug-go-clear.py requires original G2 behavior at the
managed store trap: remove records, resume the restored store, verify result,
restored code/list, empty B2 and flags/mode. The expected red
build/debug-go-clear-red terminates with Undefined identifier at G2 after
managed trap preparation; prior managed greens do not supply this API.
A fork-origin main clone build/debug-go-clear-prototype binds G2 to a
clear-then-NativeDebugGo wrapper with preserved current-task/state checks.
Console exports rise 145 to 146. Fresh original bootstrap passes; cross
build is running in build/debug-go-clear-build.log, runtime green pending.
Full archive docs/patches/i386-debug-go-clear-candidate.patch applies cleanly
to main. Other-task G2/focus, direct register control and complete debugger/
release qualification remain open; current managed source stays frozen for
workstation tests and main OS remains unpromoted.

G2 clear/resume and installed-breakpoint G guard green (2026-10-05):
fresh candidate cross/31-binding/386 audit PASS with unchanged 483208-byte
kernel; all 1270 bootstrap source hashes independently verified. Image SHA:
8979dc89c46e81d76e4b6ab874e6b11d2309a1681d5b4c583664c69d60d6a90f.
build/debug-go-clear-green passes 21 commands, startup 31.242170 seconds,
exact VGA, correct restored-store result, empty breakpoint list/B2 and
mode/flags/source recovery on 486,-fpu / 8 MiB. The missing-G2 red is now
an observable clear-and-resume green.

New tools/test-i386-debug-go-blocked.py first issues G at the managed store
breakpoint, requires visible guidance and a still-zero store/function marker,
then G2 clears/resumes. ...-blocked-green passes 21 commands, startup
37.109442 seconds, exact VGA and unchanged source. This verifies stopped
execution, not a warning alone. ...-go-clear-managed-regression passes two
ordinary managed S/G/rearm/remove cycles, 33 commands, startup 31.189027
seconds. Broader other-task/ownership/direct-register/release scope remains
open. Five G2 cycles run in ...-go-clear-repeat, five guarded G/G2 cycles in
...-go-blocked-repeat, and current-source six native modules build in
build/debug-go-clear-native-build. No pending gate is a pass; previous
managed/address native results cannot qualify the changed console. Main
remains unpromoted and complete release readiness remains unproven.

Repeated G2/guard green and stack-register inspection gate (2026-10-05):
build/debug-go-clear-repeat and build/debug-go-blocked-repeat each pass five
cycles and 69 commands on 486,-fpu / 8 MiB, exact VGA, restored store/code/
record state, mode/flags/public heap probe and unchanged image. Startup
33.040126 / 34.479657 seconds. Full workstation now runs in
build/debug-go-clear-workstation. Native retained builder 3668924 is directly
confirmed live; the dependent build/debug-go-clear-native-generations-wait.py
requires that exact six-module PASS and pinned tracked runner before fresh
build/debug-go-clear-native-generations. Both broader gates remain pending.

New tools/test-i386-debug-stack-registers.py compares TaskRegAddr ESP/EBP
slots with GetRSP/GetRBP captured inside the interrupted function before
INT3, then requires ordinary S/G store/result/mode/flag recovery. It pins
fixture dependencies and constructs independent repeated interactions;
source helper is 199 characters, within the console limit. Native exception
entry inspection confirms PUSHAD precedes four segment pushes: saved ESP
points to vector/error/EIP/CS/flags, hence the candidate's +20 conversion to
interrupted ESP. Runtime in build/debug-stack-registers is pending; the
source calculation alone does not prove public stack-register correctness.
Stack editing, instruction-pointer/flags edits, other-task controls,
concurrent ownership, original runtime comparisons and release completion
remain open. Main OS and live candidate sources remain unchanged.

Physical ESP/EBP inspection green and register native generations verified
(2026-10-05): initial build/debug-stack-registers fails its combined comparison
of debugger slots with GetRSP/GetRBP values from separate HolyC assignments.
The expectation compares different evaluation points; backend source shows
GetRSP emits the current ESP inside expression evaluation, which can include
compiler temporaries. This fixture does not establish a debugger conversion
bug. Preserve its failure. The checker now captures physical ESP/EBP in one
assembly block immediately before NOP/INT3, storing snapshots in live locals
reachable through globals, without expression evaluation between capture
and trap. It then compares public I64 slots with those U32 snapshots and G
returns the expected result with mode/flags restored.

build/debug-stack-registers-asm passes 16 commands on 486,-fpu / 8 MiB,
startup 34.467013 seconds, exact VGA and unchanged image; dependency/checker
identities remain pinned. Five independent cycles run in ...-asm-repeat.
This proves inspection, not ESP/EBP editing or complete debugger coverage.

Register-source full native generation equality PASS is independently rerun
in build/debug-register-generation-identity-recheck: twelve identical native
modules, flat 487336 bytes with SHA
8eebe3e5df7f4928b438628dd1b49464a12f55291fb18e5706811258d271345f,
boot area SHA
39c511c316094a6cf4dcdd01aab0f77b307637e1a6772861ad9764eca09a360f.
Both volumes have 16 directories, 872 files, 19089 owned sectors and bitmaps
matching reachable extents. Whole disk images differ; no whole-volume identity
claim. Later managed/G2 generations remain separate pending gates. Main OS
is unpromoted and the full self-hosting/release objective remains open.

Repeated physical stack inspection and task-specific shared-code breakpoint
proof (2026-10-05): build/debug-stack-registers-asm-repeat passes five cycles
and 44 commands on 486,-fpu / 8 MiB, startup 35.405312 seconds, exact VGA,
physical ESP/EBP snapshots, result/mode/flags/public heap probe and unchanged
source. Stack editing remains separate unimplemented scope.

New tools/test-i386-debug-breakpoint-task-switch.py runs two terminals sharing
parent-owned SharedProbe code. One installs a breakpoint, the other executes
that code without trapping and sees no own record but the owner's record;
the owner then traps, G2 clears/resumes, exits, and the survivor verifies and
executes restored code. build/debug-breakpoint-task-switch passes 13 commands,
startup 33.523962 seconds, exact VGA, unchanged source and parent public heap
recovery. This directly exercises scheduler byte application and per-task
lists rather than inferring them from source. Fixture dependency is pinned.

The same checker now accepts --both-own: both terminals register the same
address, first owner traps/clears/exits, second retains its independent record
and traps/clears before code restoration/survivor exit. That fresh gate runs
in build/debug-breakpoint-same-address; verdict pending. Sequential owner
traps do not prove simultaneous debugger sessions, external other-task G/S,
all concurrent ownership or complete release readiness. All candidate sources
remain fixed while native/workstation gates continue; main OS unpromoted.
