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
The shared keyboard helper also passes the 8 MiB initial welcome-pixel
regression with unchanged inputs (`build/i386-keyboard-helper-welcome-8m`);
this concurrent run does not qualify startup timing.

The emulated-keyboard runner has been extended to check empty descriptions.
The expanded run passes across a cold reboot with unchanged inputs
(`build/i386-timeclock-keyboard-cancel-native`). Despite the run directory
name and its stated scope, it uses Escape to accept empty input. A corrected
run enters text and uses Shift+Escape to cancel it; this passes with an empty
description and byte-identical cold-reboot recovery, with unchanged inputs
(`build/i386-timeclock-keyboard-shift-escape-native`).

On the patched 64 MiB full-content image, the unchanged report workflow again
passes exact typed records, the original DolDoc report and 5,400-second total,
welcome/report VGA checkpoints, and cold-reboot rerender
(`build/i386-cmp-byte-full-timeclock-report-kvm/result.json`). Its logical
record SHA-256 is `f5ecc13cd3d99a3efe3fc9208e158d5fa0b94a6ec47884de48d176e23ca4e04b`;
the report SHA-256 is
`faa5155d46e6a394493031341f60052c38e7cabab285b0ce2f73e84d4bf731c9`.
All pinned inputs are unchanged. Physical input and whole-application behavior
remain open.

The patched full-content image also passes the unchanged QEMU keyboard
`PunchIn`/`PunchOut` workflow
(`build/i386-cmp-byte-full-timeclock-keyboard-kvm/result.json`). It records
multiline descriptions, an accepted description and Shift+Escape cancellations.
The independently decoded typed records remain byte-identical after cold reboot
(logical SHA-256
`6a5ec9a51635f81452f3e8c052b43bd494deb3f11e9d4b8aefb6e73e56036161`).
All inputs are unchanged. This covers emulated keyboard entry, not physical
input, full VGA or the entire application.

## Fresh report failure on the newer desktop image

The unchanged TimeClock report fixture wrote a 50-byte compressed archive
under the configured Home. An independent host decoder recovered the exact
34-byte original golden record. The guest resolved both the home-relative
and absolute filename. Public FileRead returned no data through either
path, while public ExpandBuf accepted a raw copy of the captured archive.
The compressed file read path needs further isolation.
See the [read trace](../build/i386-timeclock-read-paths-v1/read-evidence.json).

A follow-up on the 64 MiB desktop image added the captured archive bytes
as `/Packed.DATA.Z` before boot. Public `FileRead` returned a buffer for
that path. The `.Z` suffix selects compressed decoding. The probe checked
buffer presence, and the packaged copy also had a different directory
and storage history from the TimeClock file. The new Home archive still
failed through the absolute path. A cold-boot attempt on a copy of the
written disk stopped during kernel startup before it could retry the read.
See the [guest report markers](../build/i386-timeclock-read-paths-v2/report-markers.txt).

A separate 64 MiB guest probe expanded that captured record and passed it
directly to public `FileWrite`. All five immediate reads returned the exact
34 bytes. This covered plain and compressed writes at the root and under
`Home/TimeClock`, plus a compressed write through TimeClock's exact
home-relative filename. The probe leaves the application's failing call
sequence open and gives a controlled passing case on the same base image.
See the [round-trip results](../build/i386-timeclock-write-read-matrix-v1/guest-results.txt).

The failing application run and passing direct-write run both left the
same 50-byte archive and RedSea attributes `0xC00` at
`/Home/TimeClock/TimeFile.DATA.Z`. The on-disk comparison isolates the
difference to guest state or to the call sequence surrounding the read.
See the [disk comparison](../build/i386-timeclock-write-sequence-v1/disk-comparison.json).

Within one guest, TimeClock's own write was unreadable before and after
`TimeEntriesDel`, including through the absolute path. A direct overwrite of
the same filename with the captured record made the next read return all 34
bytes. This reproduces the original failure without the report runner and
rules out record cleanup as the trigger. See the
[guest trace](../build/i386-timeclock-write-sequence-v1/guest-results.txt).

A first-write probe isolated a case outside TimeClock. A direct write
to the app's exact filename succeeded when `FileWrite` created its
missing parent directory. Plain and compressed writes with freshly
created parents also read back exactly. After an explicit `DirMk`,
the first compressed file under that directory was present in the
image with the expected archive but the immediate guest read failed.
TimeClock's installer also creates its directory with an explicit
`DirMk`. See the
[first-write trace](../build/i386-timeclock-first-write-v1/guest-results.txt).

On a fresh guest, explicitly creating `~/TimeClock` reproduced the
failure with a direct first write to the exact application filename.
A second write to that path made it readable. In a separate run,
`FileFind` returned the expected RedSea metadata and guest `BlkRead`
returned the exact packed bytes while public `FileRead` still failed
on the same file. The difference remains inside the whole-file read
path or its decompression step. See the
[explicit directory trace](../build/i386-timeclock-explicit-directory-v1/guest-results.txt)
and [guest sector trace](../build/i386-timeclock-read-layer-v1/guest-results.txt).

A debugger trace on the same 64 MiB image places the failure before
decompression. The stored-file service returned null for all four
failed reads, including the absolute read and the retry after the guest
read the raw sector. The overwrite allowed the same bytes to reach the
compact decompressor and the public read passed. See the
[file service trace](../build/i386-timeclock-file-service-trace-v1/file-service-results.txt).
