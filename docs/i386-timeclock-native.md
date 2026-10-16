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
