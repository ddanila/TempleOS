# Focused tests and mutation checks

Build a current image with `python3 tools/build-i386-kernel.py` (run
`python3 tools/test-rebuild.py` first when Kernel/Compiler sources changed).
The input harness tests the supplied image; it does not rebuild it. Keep the
source checkout and image together, especially the font and frame expectations.
Do not replace the image during a run.

```sh
python3 tools/i386-kernel-input.py --list-groups
python3 tools/i386-kernel-input.py --group windows
python3 tools/i386-kernel-input.py --group documents --group text --out build/doc-tests
python3 tools/i386-kernel-input.py  # complete console suite
python3 tools/test-i386-mutations.py
python3 tools/test-i386-mutations.py --mutation control-hit-test
python3 tools/test-i386-test-runner.py  # host verdict checks, no QEMU
python3 tools/test-i386-doldoc-session.py  # writable two-boot acceptance
```

The default disk is `build/i386-kernel/kernel.img`. An optional positional disk
path overrides it. Groups run in suite order, sharing one normal boot; omitted
groups do not run their setup commands. Available groups are keyboard, windows,
graphics, date, math, definitions, text-frames, compiler, breaks, documents, and
text. These select existing assertions, including hardware input and exact VGA
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

`test-i386-doldoc-session.py` is that separate writable-disk test. It copies the
built image, creates a canonical document, enters `DocEd`, and sends QEMU keyboard
events for typing, cursor-left and backspace. It checks VGA text/cursor pixels,
returns to HolyC with Escape, writes to RedSea, then boots the same candidate
again and verifies the reopened editor and serialized bytes. It fails if the
source image changes. This acceptance now passes for the ordinary-text subset;
full original editor integration remains open.

Results, logs, the last submitted checkpoint, and VGA screenshots are retained in
`build/i386-focused` or `build/i386-mutations` (override with `--out`). Mutation
reports include detected/survived/inconclusive verdicts and baseline evidence.
Use a new output directory when preserving earlier screenshots; result.json is
removed before each run so an interrupted run cannot leave an old passing verdict.
For TDD, add an acceptance assertion, observe the intended failure, implement the
port behavior, and run the selected group followed by complete build validation.

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
