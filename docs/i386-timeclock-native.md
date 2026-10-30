# Native TimeClock integration

ConsoleRuntime 128 supplies original GetStr/DocGetStr2 and the previously
unbound DocClear. The application package contains all three original TimeClock
files byte-for-byte. Native source availability, fresh-install precondition,
Load/Install and continuation arithmetic pass in four commands at 64 MiB
(build/i386-c3-timeclock-docclear-load-result), with unchanged inputs.

The punch runner uses real In/GetStr and unchanged PunchIn/PunchOut. It captures
seven stages: already-out, multiline punch-in, duplicate in, described out,
duplicate out, cancelled-description in, and empty-description out. The host
independently decodes typed records, checks every intermediate prefix and exact
duplicate-file identity, and bounds each stored date by Now readings around
its command. A second cold boot reads the same compressed application file,
checks the closed report and compares its decompressed data byte-for-byte.

The first command phase and all host record checks pass in
build/i386-c3-timeclock-punch-cluster-result; its reopen phase stops on an
incorrect empty-output expectation. The corrected complete run passes all ten first-boot commands and four
reopen commands with unchanged inputs in
build/i386-c3-timeclock-punch-reopen-result. All four decoded records, every
stage prefix and duplicate-file identity match; the rebooted logical file is
byte-identical to the saved final file. Earlier fixture
failures are retained: -punch-native expected no Load answer; -punch-installed-result
incorrectly treated FileWrite as returning a byte count. FileWrite returns the
allocated filesystem location. Both first and subsequent Load scripts emit Cd's
successful return in the native console; that projection is not a claim of
original desktop visual parity. No application source was changed for these tests.

The separate deterministic report runner writes the original two-entry fixture,
checks native reopen fields, and compares the entire saved DolDoc document to
[the original golden](../tests/i386/timeclock-reference.json). In
build/i386-c3-timeclock-report-native the logical records match exactly and all
four guest commands pass, but the exact document comparison fails. The native
report is missing the leading held `$WW+H,1$` command; every subsequent byte,
including the dates and 5,400-second total, matches. comparison.json records both
complete reports. The original HomeSys.HC UserStartUp types Doc/Start.DD, whose
held word-wrap command survives DocClear. NativeTerminalTranscriptStart currently
writes a minimal console heading instead. This is a visible C2 startup-document
gap, not a reason to discard the original report prefix or qualify the application.
The strict report/reboot test remains a failing gate until that startup behavior
is implemented.

Commands:

```sh
python3 tools/package-i386-application.py IMAGE --app TimeClock --out PACKAGE
python3 tools/test-i386-timeclock-native.py PACKAGE/candidate.img --out LOAD
python3 tools/test-i386-timeclock-punch-native.py PACKAGE/candidate.img --out PUNCH
python3 tools/test-i386-timeclock-report-native.py PACKAGE/candidate.img --out REPORT
```

Physical keyboard input, full original desktop startup, complete report parity,
resource qualification and native-generation acceptance remain open. No inventory
entry or C1–C5 milestone is marked complete by these component tests.

The independent [terminal startup reference](i386-terminal-startup.md) now
passes exact fresh/welcome/cleared document comparisons on the pinned original
system, confirming the retained setting without executing TimeClock.

The root terminal now inserts the complete original `Doc/Start.DD` through
`DocType`, after the existing native heading. This retains the welcome's held
word-wrap command through `DocClear`. A keyboard/log-driven 64 MiB run checks
the exact original TimeClock typed records and full report bytes, then repeats
the report after a cold reboot; it passes with unchanged inputs
(`build/i386-welcome-report-reboot-paced`). The application package comes from
`build/i386-welcome-timeclock-package`, which preserves the three original
source files. Both original rebuild generations and the native cross-build/386
audit pass (`build/i386-welcome-insertion-cross`).

This is not a full terminal-startup or desktop qualification: the existing
native heading is still present, the original terminal menu, callback and task
orchestration remain open, and the new runner does not check VGA pixels. The
existing strict report and 8 MiB drive-map runners time out on their initial
old-heading pixel expectation (`build/i386-welcome-timeclock-report` and
`build/i386-welcome-boot-8m`); both guests reached startup. Their VGA and
minimal-profile gates remain unqualified until an independent oracle covers the
new screen. Two earlier keyboard-driven reboot attempts also timed out after
input queue resets; the successful paced run is retained separately.

The strict VGA runner now specifies the actual document states created by the
unchanged application: `Install.HC` clears the terminal and displays its
instructions, and `TimeRep` clears it again and displays the report. It checks
those text and color cells against the original font rather than expecting the
obsolete plain transcript. With WinMgr suspended and the synchronous rich
redraw, the 64 MiB first boot and cold reboot pass all seven requested
commands, exact VGA checks, original record/report bytes, and the 5,400-second
total, with unchanged inputs (`build/i386-suspended-rich-report-vga`). This
is scoped to those states; desktop startup, general callbacks, physical input,
performance and full application qualification remain open.

A separate keyboard test exercises the unchanged TimeClock
`PunchIn` and `PunchOut` commands using QEMU PS/2 key events, including
multiline descriptions. It reads the resulting typed records and checks them
again after a cold reboot. At 64 MiB, both records match the entered
descriptions and the saved bytes survive a cold reboot; all pinned inputs
remain unchanged. The test is retained in
`tools/test-i386-timeclock-keyboard.py`; its run is recorded in
`build/i386-timeclock-keyboard-native`. This is an emulated-keyboard test,
not a physical-hardware or full application qualification. The longer retained
native build remains in progress at
`build/i386-c5-shared-bitfield-native-build`.
