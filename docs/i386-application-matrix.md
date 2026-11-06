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

The 64 MiB full-content image repeats the exact original typed-record and
DolDoc report check with a 5,400-second duration, strict welcome/report VGA
screens, and a cold-reboot rerender. It passes with unchanged source and input
bytes (`build/i386-native-indexed-cross64-full-timeclock-report-welcome`). The
three TimeClock inventory entries record this current-image result; physical
input and complete application qualification remain open.

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

With sprite interpolation and transformed drawing, unchanged KeepAway advances
past `SpriteInterpolate` and `Sprite3YB` and fails at `D3I32Norm` on line 292
(`build/i386-app-keepaway-interpolation-v1`, inputs unchanged). Gameplay remains
open.

With the public D3I32 norm and distance functions, unchanged KeepAway advances
past `D3I32Norm` and stops at `GrBorder` on line 299
(`build/i386-app-keepaway-d3norm-v1`, inputs unchanged). Gameplay remains open.

With the original border and two-point rectangle bindings, unchanged KeepAway
advances past `GrBorder` and stops at `sqrt2` on line 346
(`build/i386-app-keepaway-border2-v1`, inputs unchanged). Gameplay remains open.

With the original mathematical constants, unchanged KeepAway advances past
`sqrt2` and stops at `Blink` on line 381
(`build/i386-app-keepaway-constants-v1`, inputs unchanged). Gameplay remains open.

With public `Blink`, unchanged KeepAway advances past the blinking text branch
and stops at `Beep` on line 428 (`build/i386-app-keepaway-blink-v1`, inputs
unchanged). Gameplay remains open.

With public `Beep`, unchanged KeepAway advances past the game-over beep and
stops at `Noise` on line 487 (`build/i386-app-keepaway-beep-v1`, inputs
unchanged). Gameplay remains open.

With the original asynchronous sound-effect routines, unchanged KeepAway
advances past `Noise` and stops at mouse state `ms` on line 504
(`build/i386-app-keepaway-effects-v1`, inputs unchanged). Gameplay remains open.

With native logical mouse state, unchanged KeepAway advances past `ms` and
stops at the missing `Exp` dependency on line 598
(`build/i386-app-keepaway-mouse-v1`, inputs unchanged). Gameplay remains open.

With the native exponential provider, unchanged KeepAway advances past `Exp`
and stops at `SettingsPush` on line 645 (`build/i386-app-keepaway-exp-v1`,
inputs unchanged). Gameplay remains open.

The 64 MiB full-content native image independently confirms that current
boundary (`build/i386-native-indexed-cross64-full-keepaway-load/result.json`).
All three packaged KeepAway files match the pinned reference bytes. Loading
the unchanged `Load.HC` reaches `KeepAway.HC.Z` line 645 and rejects its
unbound `SettingsPush`; no game interaction executes. The complete shared
settings bodies exist, but their native dependencies and lifecycle are still
unfinished (see [task settings](i386-task-settings.md)).

The patched full-content image repeats the unchanged TimeClock report and
cold-reboot workflow (`build/i386-cmp-byte-full-timeclock-report-kvm/result.json`).
It passes exact typed-record and DolDoc report checks for 5,400 seconds,
welcome/report VGA checkpoints, and the reopened report, with unchanged
inputs. This regression covers the report workflow; physical input and the
complete application remain unqualified.

The same patched image passes the unchanged TimeClock QEMU keyboard punch
workflow with multiline text and Shift+Escape cancellation; independently
decoded records survive cold reboot byte-for-byte
(`build/i386-cmp-byte-full-timeclock-keyboard-kvm/result.json`). Physical
input, full visual behavior and the complete application remain unqualified.

## Budget installed-template storage and cold reopening (2026-11-06)

Budget now passes a constructed transaction write, same-session reopen and
native cold-boot reopen with the actual installed account template. The new
oracle checks the complete 48-byte transaction and 106-byte twelve-entry string
table, account colors, and unchanged saved-file bytes/metadata across reboot.
This exposed and fixed an application pointer-width assumption: StrFileWrite
now allocates I64 sort slots for QSortI64. The source gate permits exactly that
reviewed change; the other ten Budget source/asset files remain reference-exact.
See [the sort-width diagnosis and evidence](i386-qsort-i64.md).

This is progress toward the Budget workflow above, not a substitute for its
interactive transaction entry, account-view and cancellation tests. C1-C5 and
whole-application qualification remain open.

## Budget account views and deletion callback (2026-11-06)

The installed-template reference in
build/i386-budget-views-installed-reference-v2 and native comparison in
build/i386-budget-views-installed-native-v1 both pass mask 31 and three exact
DolDoc comparisons. Three deliberately unsorted transactions are inserted
through BgtIns, then BgtRegen produces chronological BANK and RENT views.
Independent expected documents check dates, amounts, running balances, the
installed BANK foreground color and cursor markers. Only transaction addresses
are normalized; the checker separately requires three distinct nonzero IDs,
identical IDs across account changes, and the exact two surviving IDs after
removing the grocery transaction.

The fixture selects the middle transaction before changing accounts and checks
that the regenerated document keeps that selection. It invokes the real
BgtPutKey Ctrl-Y branch, verifies the two-entry list and resulting BANK balance
70, then checks that an unhandled key returns FALSE without replacing the doc.
The caller's documents are restored and subsequent console arithmetic succeeds.
The source gate accepts only the already reviewed BgtStrs I64 sort-slot port;
all other Budget files are reference-exact. Both runs preserve their inputs.
The native filesystem audit passes and 1738 existing files are preserved.

The initial original v1 run exposed an uninitialized fixture mask; its driver,
fixture and documents remain frozen beside that failed result. The corrected
fixture explicitly starts the mask at zero and checks the selected-row cursor
markers instead of assuming an end-of-document cursor. No runtime behavior was
changed for this comparison.

These are actual account-document and callback operations, not physical input
through View, popup transaction entry, rendered-pixel equivalence, scheduled
templates or complete Budget qualification. Those acceptance checks and C1-C5
remain open. The next interaction test must drive View/key dispatch rather
than treating direct BgtPutKey invocation as physical keyboard evidence.

## Budget View with emulated keyboard input (2026-11-06)

The new keyboard comparison advances the prior direct callback case through
actual View/DocGetKey and QEMU keyboard input. The pinned-original run in
build/i386-budget-keyboard-reference-v2 and native run in
build/i386-budget-keyboard-native-v1 both pass mask 31 and exact before/after
DolDoc checks. The host sends Ctrl down, Y down/up, Ctrl up, then Escape; the
key events and their log offsets are retained in each guest/keys.jsonl.

The fixture constructs the same three transactions and selects the grocery row
before entering View. An observer installed as user_put_key delegates every
received key to the unchanged BgtPutKey and records the Ctrl-Y result/modifier;
it does not inject a message or invoke the callback outside keyboard dispatch.
After deletion BgtRegen installs its normal callback on the replacement document.
Escape then exits View successfully. The checker requires exactly one Ctrl-Y
callback, two remaining transactions, the surviving rent row selected, bank
balance 70, original colors and exact cursor markers. Transaction addresses alone
are normalized, with distinct/stable/surviving identities checked separately.

The native run returns to the console and independently finds the rendered 42
from a fresh arithmetic command. Its filesystem audit passes, 1738 existing
files are preserved and inputs remain unchanged. Captured before/deleted/final
screens provide inspection evidence; full pixel equality is not asserted because
the original and native window geometries differ. The original v1 control stopped
on an invalid-opcode exception at the fixture's repeated-port logging call before
readiness. Its source and final screen are preserved; v2 uses the established
byte-at-a-time OutU8 logger on both architectures.

This covers emulated keyboard deletion and Escape through View. It does not
cover choosing the initial row by navigation, popup transaction entry, mouse,
saving the deletion, the complete Budget() startup/settings lifetime, physical
hardware or whole application qualification. Those workflows and C1-C5 remain
open; the separate storage/cold-reboot result must not be treated as proof of an
interactive save/delete/reopen workflow.


## Budget full keyboard session and save (2026-11-06)

The unchanged Budget() entry point now has a full session comparison:
build/i386-budget-session-reference-v2 and
build/i386-budget-session-native-v1 both pass mask 63. The fixture seeds three
transactions through the real storage functions, then opens Budget. A read-only
child observer captures the documents and waits for keyboard-selected state;
it neither moves the cursor nor replaces the application's key handler. QEMU
Home/Down selects the middle grocery row, Ctrl-Y deletes it, and Escape saves
and closes the application. The observer's captures use the parent task heap
so they survive its exit.

Independent checks require exact chronological documents, colors, cursor markers,
running balance 70 and surviving transaction identities, normalizing only
addresses. The saved 80-byte transaction data, 125-byte string table and 108-byte
account file match the original. Six mask bits check observer completion,
restored put/display documents, menu/settings pointers, window bounds,
autocomplete activity and two-record same-session readback. The native run also
renders 42 after returning to the console. Its filesystem audit passes, all
1738 existing files are preserved and both runs retain unchanged inputs.

The initial original reference-v1 reached the restored console but timed out
waiting for fixture completion after TaskWait on the retired observer. The
corrected fixture waits for that task identity using TaskValidate and task_num,
so reuse of its address cannot make it wait for a different task. The failed
run and frozen inputs remain available; this does not establish a runtime fix.

Reproduce the reference with:

```
python3 tools/test-i386-budget-session.py --archive build/i386-budget-sort-slot-cross-v1/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-session.py build/i386-budget-sort-slot-cross-v1/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

This advances navigation, saving and the actual application's settings lifetime.
It does not cover popup transaction entry, cold reopening of this interactive
save, Shift-Escape cancellation, mouse input or pixel equality. The independent
constructed-transaction cold-storage test above does not fill that gap. Complete
Budget acceptance and C1-C5 remain open.


## Budget cold reopening and keyboard abort (2026-11-06)

The full-session runner now covers reopening and cancellation. The original
control in build/i386-budget-session-abort-reference-v2 reopens in the same boot.
The native comparison in build/i386-budget-session-abort-native-v1 terminates
QEMU after saving and starts a fresh guest from that actual working image,
without installation or reseeding. Both phases pass mask 63 with unchanged inputs.

The reopened BANK view contains salary and rent with balance 70. Home selects
salary, Ctrl-Y temporarily removes it, and the captured view contains only rent
with balance -30. Shift-Escape aborts through the unchanged application's View
branch. Exact data, string-table and account exports remain identical to the
saved phase, and readback still finds both transactions. Independent documents
check colors, cursor positions and surviving IDs; only addresses are normalized.
Every file's bytes, attributes and timestamps remain unchanged across native cold
reopening and abort. The filesystem audit passes, 1738 original files are
preserved, and fresh arithmetic renders 42 after both native phases. Inspected
original/native screens agree on the remaining rent row; full pixel equality
is not asserted.

Reference-v1 stopped before application execution because the fixture used
conditional expressions rejected by the original HolyC parser. Its frozen
fixture, driver and failure screen remain preserved. Reference-v2 uses ordinary
if statements; no application or runtime behavior changed for this test.

The preceding reproduction commands now run both phases; use fresh output
directories. This covers cold reopening and Shift-Escape for the preseeded
interactive-save workflow. Popup transaction entry, scheduled templates, mouse,
complete Budget behavior and C1-C5 remain open. The original control does not
establish original cold-boot behavior.
