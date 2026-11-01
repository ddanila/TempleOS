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

When WinMgr is suspended and a rich view is needed, the native terminal now
composes the window list synchronously instead of blitting the stale plain
surface. Two frames are needed because the frame pipeline reads text cells
before window drawing recalculates them. Exact 8 and 64 MiB VGA checks pass
for the welcome, suspended input, `DocClear` and a subsequent command with
unchanged inputs (`build/i386-suspended-clear-final-8m` and
`build/i386-suspended-clear-final-64m`); focused long-command VGA checks also
pass (`build/i386-suspended-rich-double-8m` and
`build/i386-suspended-rich-double-64m`). Both original rebuilds and the native
cross-build/386 audit pass (`build/i386-suspended-rich-double-cross`).

A separate 64 MiB keyboard/log-driven TimeClock run with WinMgr suspended
matches the original record and report bytes across a cold reboot
(`build/i386-suspended-rich-report-paced`), with unchanged inputs. The fixture
paces input at one second per key: an earlier faster cold-reboot attempt lost
input after a queue reset (`build/i386-suspended-rich-report-log`). The strict
TimeClock VGA runner instead timed out when application `Load.HC` cleared the
screen and displayed its actual instructions; its old expected transcript is
not valid for that state (`build/i386-suspended-rich-double-report`). These
checks do not establish general callback/reentrancy behavior or responsiveness;
the two full frames per update are a performance cost. Isolated startup timing
and complete desktop qualification remain open.

## User child startup and task defaults (2026-11-01)

A new `User` child startup fixture passes all eight checks on both the pinned
original and the current original rebuild (`build/i386-user-startup-reference-final`
and `build/i386-user-startup-rebuilt-final`). It checks the shared input/display
document, 4096-entry limit, border and menu, visible non-raw state, right-click
callback, original welcome bytes, queued child execution and a successful `Kill`.
The latter does not establish complete task or heap reclamation.

The same fixture fails on the current 64 MiB native image with mask 161 of 255
(`build/i386-user-startup-native-red-v1`): the shared document, queued execution
and `Kill` checks pass, while the entry limit, border and menu, visible state,
right-click callback and welcome checks fail. At the prompt the original child
reported display flags 3 and inhibit flags 0; native reported 2 and 0. The
original `HomeSys.HC` starts two `User` tasks and tiles them; recreating this
requires the actual terminal initialization and its dependencies, including
`TermRightClickLink`, before desktop behavior can be qualified.

A separate original `Spawn` fixture records initial task-window defaults
(`build/i386-task-window-default-reference-final`): coordinates 1–78 and
13–58, inhibit flags `0x52F3FF`, text attribute `0xF1`, and a task-name title.
Its checks also cover the drive-derived border attribute and successful `Kill`.
These are initial task defaults, not the later tiled user-window geometry. The
native comparison and implementation remain open, as do the full desktop and
C1–C5.
