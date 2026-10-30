# Original terminal startup contract

The original-system control in
`build/i386-c2-terminal-startup-exact-reference` passes with unchanged fixture
and tool hashes. It runs the pinned original system used by the TimeClock
reference, calls the original `DocTermNew`, types the complete original
`::/Doc/Start.DD`, and clears the resulting document.

The fixture checks that the terminal put/display document is shared, its entry
limit is 4096, its border and menu exist, and raw output is off. Three exported
buffers establish the document sequence:

| Stage | Exact saved bytes |
| --- | --- |
| Fresh terminal | Empty (zero bytes) |
| After original `Type` | Entire original `Doc/Start.DD`, then newline and byte 0x05 |
| After `DocClear` | `$WW+H,1$`, then byte 0x05 |

The host compares the entire welcome buffer to the pinned source, including all
links and formatting. It does not normalize DolDoc commands. The initial run
in `build/i386-c2-terminal-startup-reference` failed a fixture expectation that
an empty terminal saves a 0x05 terminator; the actual empty document saves zero
bytes. Its observations are retained, and the corrected fresh run passes.

```sh
python3 tools/test-i386-terminal-startup-reference.py --out OUTPUT
```

This independently confirms the startup cause of the strict native TimeClock
report mismatch described in [the native application evidence](i386-timeclock-native.md).
It is an original reference contract, not native startup qualification.

Native integration still needs the complete `DocTermNew` path, including its
right-click callback, border, menu and scroll initialization, followed by the
original welcome insertion. `NativeTerminalTranscriptStart` currently writes a
minimal heading. The complete original `DocType`/`Type`, `DocDump` and graphics dependencies
are now integrated and pass their scoped original/native comparisons; see
[document output evidence](i386-doc-type.md). This supplies the welcome insertion
service but does not run the original terminal startup sequence. Desktop task orchestration in `HomeSys.HC`
remains separate outstanding work. Preserve the minimal 8 MiB boot contract
while implementing the full desktop profile. No inventory entry or milestone
is qualified by this reference test.

The native root terminal now calls the original `DocType` on `Doc/Start.DD`
after its existing native heading. The welcome is visible and its held
word-wrap entry survives clearing, as confirmed by the exact TimeClock report
and cold-reboot comparison in `build/i386-welcome-report-reboot-paced`. This
is still a partial startup sequence: the native heading precedes the original
welcome and `DocTermNew`, its right-click callback, border/menu setup and the
original desktop tasks are not integrated. Existing startup VGA expectations
must be revised against independent evidence; the 8 MiB and strict VGA gates
currently time out at the old heading expectation. See
[i386-timeclock-native.md](i386-timeclock-native.md) for the tested scope.

The native console now exposes the original `sys_os_version` value and creates
`DD_OS_NAME_VERSION` using the original `DefinePrint` format before inserting
the welcome. This restores the centered version title. The focused initial
screen fixture compares all 640×480 pixels against a frame assembled from the
original font and welcome text, allowing either cursor blink state. It passes at
8 and 64 MiB with unchanged inputs (`build/i386-welcome-screen-8m` and
`build/i386-welcome-screen-64m`). Both original rebuild generations and the
native cross-build/386 audit pass (`build/i386-welcome-version-cross`). The
keyboard/log-driven exact TimeClock report and cold-reboot comparison also pass
with unchanged inputs (`build/i386-welcome-version-report-log`).

The pixel fixture covers the initial screen only; it does not qualify command
input, the full original desktop or isolated startup timing. The existing
plain-text VGA harness still fails after input because the welcome document
switches the console to syntax-highlighted document rendering. An attempted
welcome-screen adaptation matched the initial frame but timed out while typing
(`build/i386-welcome-version-text-8m-cursor` and
`build/i386-welcome-version-report-cursor`); it was not retained as a passing
oracle. The full VGA and minimal-profile gates remain open.

The input harness now has an explicit `welcome` mode for the initial document
view. It checks the 79-column wrap, green transcript and cursor as well as the
welcome frame. When the harness suspends WinMgr, the current runtime exposes its
retained plain VGA surface; the harness verifies that actual transition rather
than claiming the welcome is still displayed. With that scope, an 8 MiB run
passes the long setup command and a subsequent arithmetic command with exact
VGA checks and unchanged source (`build/i386-welcome-input-8m-transition`). Its
62.813557-second startup was concurrent and is not an isolated timing gate.

The strict 64 MiB TimeClock report runner now accepts `--welcome`. Its exact
VGA checks, original typed records and full report bytes pass on first boot and
again after cold reboot (`build/i386-welcome-version-report-transition`), with
unchanged inputs and the original 5,400-second total. This does not qualify
continuous rich-document rendering while WinMgr is suspended: losing the
welcome from the displayed surface in that state remains an implementation gap.
Nor does it qualify the full desktop or C1–C5.
