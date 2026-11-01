# Bundled application launch review

Reference: archive `c26482bb6ad3f80106d28504ec5db3c6a360732c` with recovered
map/asset bytes from `ce055f205fc38536443289fb1cfc73632f6624f4` (see
[binary repair provenance](binary-repairs.md)).
This source review covers all twelve `Apps/` directories (73 reference files),
linked to the exhaustive [file inventory](i386-compatibility-inventory.json).
Entry points and direct includes below come from the pinned Run/Load scripts.
They are launch recipes for future reference capture; none is runtime-qualified.
Relative includes depend on the directory change performed by those scripts.

| Application | Launch script | Entry after loading | Direct Load includes |
| --- | --- | --- | --- |
| Budget | Apps/Budget/Run.HC | Budget | BgtStrs, Budget, BgtAccts, BgtEntry, BgtTemplate, BgtFile, BgtMain |
| GrModels | Apps/GrModels/Run.HC | Models | ManGen, BallGen, Models |
| KeepAway | Apps/KeepAway/Run.HC | KeepAway | KeepAway |
| Logic | Apps/Logic/Run.HC | DigitalLogic | Logic |
| Psalmody | Apps/Psalmody/Run.HC | Psalmody | JukeBox, JukePuppet, Psalmody, PsalmodyCtrls, PsalmodyDraw, PsalmodyFile, PsalmodyMain |
| Span | Apps/Span/Run.HC | Span | Span.HH, SpanDerive, SpanBridge, SpanNew, SpanMain |
| Strut | Apps/Strut/Run.HC | Strut | Strut |
| TimeClock | Apps/TimeClock/Load.HC | PunchIn, PunchOut, TimeRep, invoked separately | TimeClk, Install |
| Titanium | Apps/Titanium/Run.HC | Titanium | Titanium |
| ToTheFront | Apps/ToTheFront/Run.HC | ToTheFront | TTFGlbls, TTFLib, TTFInit, TTFVis, TTFFire, TTFMove, TTFDraw, ToTheFront |
| Vocabulary | Apps/Vocabulary/Run.HC | VocabQuiz | VocabQuiz |
| X-Caliber | Apps/X-Caliber/Run.HC | XCaliber | XCCtrls, X-Caliber |

Budget's Run script also includes Install, creating `~/Budget` and copying
`Accts.DD.Z` if the directory is absent. TimeClock's Load script includes
Install, creating `~/TimeClock` and printing the three public entry commands.
Other Install scripts present in the inventory must be reviewed independently;
the presence of an Install file does not mean Run executes it. Resolve includes
transitively, including compressed-name lookup and shared public services,
before treating these dependency lists as complete.

## First reference-capture workflows

Start with persistent applications whose results have independent file oracles:

* **TimeClock:** load through its original script, punch in and out with entered
  descriptions under a controlled guest clock, inspect the report, reboot and
  inspect it again. Decode `~/TimeClock/TimeFile.DATA.Z` independently: typed
  entries, dates, descriptions and EOF must match the actions. The original
  TimeClk source writes these fields explicitly. Test cancellation as well as
  accepted descriptions. Clock control and observations are still to implement.
* **Budget:** start from its installed account template, enter a transaction,
  save, quit and reopen; compare the transaction/account report with persisted
  data. Source establishes the Strs.DD.Z, Accts.DD.Z and Bgt.DATA.Z files and
  calls to the corresponding read/write functions. Capture exact interaction
  and serialization behavior on the original system before writing the oracle.
* **Psalmody:** capture a short note-edit/play/save/reopen workflow, comparing
  stored music, visible state and audio. Direct includes identify the drawing,
  controls and file components; exact UI actions and output oracles remain open.

For every graphics/game program, capture its documented controls and a meaningful
state transition sequence, including termination and resource cleanup. Set or
record random seeds and clock inputs where needed; a launch screenshot is not
sufficient evidence. Remaining per-program workflows, original observations,
executable tests and all 224 demo-file classifications are C1 gaps. API service
review and desktop-feature workflows also remain open.

TimeClock's first storage/report reference capture passes, with reviewed data
in `tests/i386/timeclock-reference.json` and an executable checker in
`tools/test-i386-timeclock-reference.py`. It covers Load/Install and the first
controlled two-entry storage/reopen/report component workflow above. Interactive
punch commands and reboot are still open; the complete application and native
port remain unqualified.

The native source-availability gate now passes on an additive TimeClock image.
Executing the unchanged Load script fails at `__DIR__`; the underlying
compile-time stream gap is tracked in [the compiler stream work](i386-compile-stream.md).
Storage/report and full interactive native qualification remain open.

The first stream implementation passes its focused commands; TimeClock loading
now progresses past __DIR__ and fails at the missing public Now binding. The
original TimeClk source is unchanged. This advances a dependency gate, while
native storage/report and full application qualification remain open.

The public Now binding now passes its focused native test. Unchanged TimeClock
source compilation advances to GetStr in PunchOut (TimeClk.HC line 127).
GetStr and its original input/flag behavior are the next dependency to test and
port; no full application pass is claimed.


A fresh Console-88 check (2026-10-15) packages all three original TimeClock files
unchanged and confirms native source availability. Loading is still rejected at
`GetStr(,,GSF_WITH_NEW_LINE)` in PunchOut, TimeClk.HC line 127; the current
compiler diagnostic is `Invalid lval`, and GetStr remains absent from the native
public declarations. Evidence: `build/i386-c3-timeclock-console88-load/result.json`
and its guest log, with unchanged checker/image inputs; additive packaging is in
`build/i386-c3-timeclock-console88-package/result.json`. The rejection precedes
the continuation arithmetic command and does not qualify Load/Install or any
native application workflow. Preserve the unchanged source and implement the
original GetStr contract rather than editing the app around this dependency.


The original punch-command oracle now passes (2026-10-15) in
`build/i386-c3-timeclock-punch-reference`: real GetStr through scripted input,
accepted/multiline/empty/cancel descriptions, duplicate commands, independently
decoded typed records and a final closed report. Cancellation commits a punch
with an empty description. See [punch-command contracts](i386-timeclock-punch.md).
Reboot, physical keyboard, elapsed-time and full native workflows remain open.
A fresh unchanged-source Console-113 load check still rejects GetStr at line
127, after source availability passes, in
`build/i386-c3-timeclock-console113-load` with unchanged inputs. Its additive
package is `build/i386-c3-timeclock-console113-package`; the three application
files match the pinned reference digests. This is an explicit native red gate,
not a qualified application.

Console-128 clears the GetStr and DocClear binding dependencies. The unchanged
three-file TimeClock package passes native source availability, fresh-install
precondition, Load/Install and continuation arithmetic in
build/i386-c3-timeclock-docclear-load-result, with unchanged inputs. The native
punch/storage/reboot oracle is now running. This is a loading milestone, not
whole-application qualification; elapsed-time report formatting and physical
keyboard workflows remain open.

The native punch/storage/cold-reboot run now passes ten first-boot and four
reopen checks with unchanged inputs (build/i386-c3-timeclock-punch-reopen-result).
A strict deterministic report comparison finds exact record/content/date/total
agreement but a missing held word-wrap entry from the original welcome document.
This C2 startup gap remains a failing report gate; see
[i386-timeclock-native.md](i386-timeclock-native.md). Full application qualification
remains open.

The three TimeClock inventory entries link the later report/reboot, VGA and
emulated-keyboard evidence alongside the historical failure; they remain
unqualified until the complete application workflow is covered. The status
paragraphs above describe earlier source epochs, not the latest report result.

The native TimeClock evidence has advanced beyond those earlier checkpoints:
unchanged application source now passes a 64 MiB emulated-keyboard punch-in and
punch-out with multiline descriptions and byte-identical record recovery after a
cold reboot (`build/i386-timeclock-keyboard-native`). A separate strict VGA run
checks the original installation and report screens and exact report bytes
across reboot (`build/i386-suspended-rich-report-vga`). These are distinct
scoped workflows; the latter suspends WinMgr and the keyboard run does not
check the full VGA image. They do not establish full application or desktop
compatibility. See [the current native evidence](i386-timeclock-native.md).

A first Budget component reference now runs the original Load and Install
scripts, constructs a single BANK-to-RENT transaction for 125 whole units,
writes the application data and string files, and reopens them in the same
session. The independently packed record and exact string table match, and
inputs remain unchanged (`build/i386-budget-storage-reference-v3`; runner
`tools/test-i386-budget-reference.py`). This does not exercise Budget's form,
menu, report, reboot, or native application behavior. An earlier probe using a
decimal literal produced a slightly different F64 value from host IEEE 125.50;
the whole-unit fixture avoids depending on that literal conversion behavior.

The first native Budget load probe packages all eleven pinned original files
without source edits. Its Load command is rejected at the missing public
`LinkedLstCnt` in `BgtStrs.HC` line 87, before Install or any application
workflow (`build/i386-budget-native-load-v1`). The guest log and unchanged
input hashes preserve this dependency failure. The runner's installation check
now distinguishes the home directory from the packaged source directory; that
check has not yet been reached.

MemoryRuntime 32 now exports the shared original `LinkedLstCnt` body; original
and native list contracts pass, and the unchanged Budget loader advances to
`QSortI64` at `BgtStrs.HC` line 97 (`build/i386-budget-native-load-v2`).
The load is still rejected and Install has not run. See
[linked-list count evidence](i386-linked-list-count.md).

MemoryRuntime 33 exports the original `QSortI64` body. The original and native
ascending, descending, duplicate and pointer-callback checks pass; see
[sort evidence](i386-qsort-i64.md). Unchanged Budget loading now reaches
`BgtMain.HC` line 50 and rejects at `PopUpOk`
(`build/i386-budget-native-load-v3`), before installation or a workflow.

ConsoleRuntime 140 exports the original button-popup builders; the original and
native seven-case comparisons pass with exact documents and results.
ConsoleRuntime 141 adds the original `PopUpEd` wrapper. The Budget loader now
reaches `SettingsPush` in `BgtMain.HC` line 182 and rejects there
(`build/i386-budget-native-load-v5`). The popup-editor reference and native
input-path check remain scoped as described in [popup editor evidence](i386-popup-ed.md).

The pinned original now has an executable account-view reference for Budget.
Three deliberately out-of-order constructed transactions are inserted and
`BgtRegen` renders both BANK and RENT views. The checked documents preserve
chronological order, descriptions, amounts and running balances (BANK: 100, 80,
50; RENT: 0, 0, 30), and the three row identities are distinct and remain the
same between views. Exact document bytes are compared after normalizing only
those runtime addresses. The original reference passes with unchanged inputs
(`build/i386-budget-report-reference-v1`; runner
`tools/test-i386-budget-report-reference.py`). The initial capture reused freed
buffers and is retained in `build/i386-budget-report-reference-probe`; the
corrected capture keeps both buffers live. This is a constructed-data
component oracle, not interactive entry, save/reboot, native report parity or
full Budget qualification. On the current raw-block image the unchanged
Budget loader still stops at SettingsPush in `BgtMain.HC` line 182, with
unchanged inputs (`build/i386-budget-current-native-load`); no native account
view ran.

Logic now has a pinned-original synthesis oracle covering all ten gate modes,
with a known truth table and checked input wiring per mode. The unchanged native
loader is blocked at its embedded DolDoc binary initializer before synthesis.
See [Logic compatibility](i386-logic-compatibility.md) for the evidence and
the document-backed include work; the interactive and graphics workflows remain
unqualified.

## Current full-image loader checks (2026-11-01)

The native load runner now accepts application files already present in a full
image only after verifying each byte against the repaired pinned reference; it
adds only absent files and verifies the delivered set. On the current
pre-random-family image, unchanged Load scripts still reject at the following
points, with source-image and runner inputs unchanged:

| Application | First observed rejection | Evidence |
| --- | --- | --- |
| Logic | Line 569, `SettingsPush` | `build/i386-app-logic-current-v1` |
| KeepAway | Line 221, registry initialization | `build/i386-app-keepaway-current-v1` |
| Strut | Line 16, missing `CMass` class | `build/i386-app-strut-current-v1` |
| Vocabulary | Line 7, missing `RandU32` | `build/i386-app-vocabulary-current-v1` |

These are compiler/load checks, not gameplay or application qualification.
With the shared random family, Vocabulary advances to the missing `ACDDefGet`
at line 35 (`build/i386-app-vocabulary-rand-v1`). Original application launch,
interaction, persistence and visual/audio workflows remain required.

With the shared registry integration, unchanged KeepAway advances past registry
initialization and fails at `Max` on line 257 (`build/i386-app-keepaway-registry-v1`,
inputs unchanged). This is a load check; the game has not been qualified.

With public `Min`, `Max` and `Clamp`, unchanged KeepAway advances past `Max`
and stops at the `GrEllipse` call on line 263
(`build/i386-app-keepaway-minmax-v1`, inputs unchanged). Gameplay remains open.

With the original 2D curves and flood-fill bindings, unchanged KeepAway advances
past `GrEllipse` and `GrFloodFill` and fails at `SpriteInterpolate` on line 269
(`build/i386-app-keepaway-curves2-v1`, inputs unchanged). Gameplay remains open.
