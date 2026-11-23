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


## Budget popup transaction entry and native data-field dispatch (2026-11-06)

Budget now passes entry through its actual `n` command and PopUpForm. The fixture
starts with the installed account template and no seeded transactions. A
read-only observer waits for Budget's document and a five-field popup; the host
then types date 09/04/1998, amount 125.50, BANK, RENT and description `popup entry`,
using Tab between fields. Escape accepts the popup and a second Escape saves
Budget. It neither writes the form object nor injects guest messages.

The original control build/i386-budget-entry-reference-v2 and native comparison
build/i386-budget-entry-native-v2 both pass mask 63. Independent checks require
an empty initial document, exact resulting BANK report, one nonzero transaction
identity, the complete 48-byte data record, 105-byte twelve-entry string table
and unchanged 97-byte installed account list. Only document pointer addresses
are normalized. The mask checks observer completion, caller documents,
menu/settings, window bounds, autocomplete activity and same-session readback.
Native arithmetic renders 42 afterward, the filesystem audit passes, 1738
existing files are preserved, and all pinned inputs remain unchanged.

The native-v1 run against the prior image failed after popup acceptance. Its
screens show typed text inserted before data fields, leaving credit/debit empty
and opening the account picker. A separate parser probe in
build/i386-budget-entry-prefix-probe-v3 confirms StrMatch finds the colon and
PrsDollarCmd retains min_col=5 for `Date:%s`. The fault was dispatch: native
DocPutKey sent printable data-field keys to DocBasicEditCore, which handles
ordinary text and inserts a new text record for non-text entries. The original
EdCharIns was already compiled into Console but was not selected here.

The four-line DocumentRuntime change declares that existing function and routes
printable data/hex-field keys to it. Original field overstrike, insertion,
allocation, terminators and update-data behavior are retained. The native-v2
comparison uses build/i386-budget-entry-char-cross-v2/kernel.img. Both original
bootstrap generations pass; the cross-build passes its 96 BIOS/332 protected-mode
386 instruction audit. The candidate source audit matches 1368 files. The
16 MiB diagnostic boot in build/i386-budget-entry-minimal-v1 passes all 307200
welcome pixels; this does not qualify the complete minimal suite or timing gate.

The existing seven-case class-form fixture also passes unchanged through the KVM
keyboard harness in build/i386-budget-entry-class-form-kvm-v1, including numeric
accept/cancel and caller heap recovery. The older TCG runner in
build/i386-budget-entry-class-form-v1 timed out before its first test command;
that failed attempt is retained, not counted as a class-form pass.

Original reference-v1 exposed two oracle assumptions: an empty document saves
zero bytes, and the two-digit year 98 parses as 2098. Reference-v2 explicitly
types 1998 and checks the empty byte string. An initial unnecessary extraction of
EdCharIns failed cross-compilation; it was removed after finding the existing
original implementation. No extraction or replacement function remains.

Reproduce with fresh output directories:

```
python3 tools/test-i386-budget-entry.py --archive build/i386-budget-entry-char-cross-v2/exports/BudgetAccts.DD.Z --out OUT_REFERENCE
python3 tools/test-i386-budget-entry.py build/i386-budget-entry-char-cross-v2/kernel.img --reference OUT_REFERENCE --out OUT_NATIVE
```

This covers accepted popup entry and saving, not popup cancellation, editing or
copying existing entries, account-picker choices, templates, cold reopening of
this newly entered record, mouse input, complete hex editing or whole Budget
qualification. The separate cold-save workflow remains independent evidence.
C1-C5 remain open.


## Budget popup cancellation and cold reopening of UI-entered data (2026-11-06)

The popup-entry runner now first fills all five fields with a deliberately
unwanted transaction: 01/01/2001, 999.99, GHOST, VOID and `discard me`. Shift-Escape
cancels it. The read-only observer checks that the same empty Budget document and
empty transaction list remain, and neither data nor string-table file exists.
A second `n` interaction enters and saves the previously specified 125.50
BANK-to-RENT record. The exact twelve-entry string table and installed account
file exclude the cancelled account names and description.

The original control in build/i386-budget-entry-cancel-reference-v1 passes
mask 127 for cancellation plus the existing full-session checks, then mask 63
for same-boot reopening/restoration. The native comparison in
build/i386-budget-entry-cancel-native-v1 passes both masks, with a full QEMU
shutdown and restart before reopening. It loads Budget and the observer without
installation or data seeding, checks the actual reopened report and single
nonzero transaction identity, then exits with Shift-Escape. The reopened data,
strings and accounts match both the initial saved exports and the original
control. Every native file's bytes, attributes and timestamps remain unchanged
across cold reopening/abort. Both console returns render fresh 42, the filesystem
audit passes, 1738 original files are preserved and inputs remain unchanged.

The existing popup-entry reproduction commands now perform this whole sequence;
use fresh output directories and the matching current reference. No application
or runtime code changed for this extension. This joins UI entry, cancellation,
save and native cold reopening in one workflow, rather than inferring persistence
from the independent preseeded-transaction test. The original reopen is same-boot,
not original cold-boot evidence. Editing/copying entries, account-picker choices,
templates, mouse and complete Budget/C1-C5 qualification remain open.

## Budget existing-entry edit/copy and cold reopening (2026-11-09)

A new real-keyboard workflow cancels an unwanted new transaction, enters the
accepted BANK-to-RENT transaction, edits its description through the populated
form, accepts a populated copy, saves and reopens both records. The read-only
observer requires independent entry/string allocations and waits for committed
Budget document publication, including on the original two-CPU system.

Original controls build/budget-edit-copy-original-v5/v6/v7 pass mask 511 and
same-boot reopen mask 63 with identical normalized outputs. Native
build/budget-edit-copy-native-v3 passes both masks through an actual QEMU
shutdown/restart, restores caller state, returns fresh arithmetic after both
exits and preserves all file bytes/attributes/timestamps during read-only abort.
The session changes only its probe and three Budget files; 1,877 existing files
are preserved.

The original populated date reparses 09/04/98 as 2098, and its amount acquires
two ULPs from the original numerical approximation. Native retains its existing
exact-power/binary64 policy. The oracle checks exact target-specific bits and
requires only bytes 32 and 64 to differ in the 80-byte saved data; reports,
dates, counts, strings, accounts and every other data byte match. This records
an existing numerical architecture difference rather than using a tolerance.

See [the workflow and remaining Budget paths](i386-budget-edit-copy.md), its
reproduction commands and build/budget-edit-copy-audit-v1/result.json. The audit
checks eleven inventoried files plus the compressed template and unchanged
runtime source. Edit/copy cancellation and other field changes, account-picker
and editor interactions, templates, mouse and full Budget qualification remain
open. No inventory item or C1–C5 milestone closes.

## Budget cancellation of modified existing-entry/copy forms (2026-11-09)

The edit/copy runner's `--cancel-existing` mode now opens each populated form,
changes its description and waits for the read-only observer to see that changed
live data tag before sending Shift-Escape. Both cancellations must preserve the
same document, transaction and three string pointers, exact original values and
absence of unsaved data/string files. Raw cancelled documents retain the same
entry IDs; the selected-entry cursor marker is checked explicitly.

Original controls build/budget-existing-cancel-original-v2/v3 pass mask 2047,
then same-boot reopen mask 63. Native build/budget-existing-cancel-native-v1
passes both masks through actual shutdown/restart and read-only abort, with exact
file bytes/attributes/timestamps preserved and fresh arithmetic after both exits.
Accepted edit/copy/save data still matches the earlier workflow within each
target's established exact numerical policy; cancelled text never enters the
saved string table. The session preserves 1,877 existing files.

See [the workflow, commands and remaining paths](i386-budget-edit-copy.md) and
build/budget-existing-cancel-audit-v1/result.json. Keyboard logs verify the order
of observed draft changes and cancellation; exact fixtures/raw records, source
provenance and prior accepted outputs are audited. No application/runtime code
changed. Other field changes, account-picker/editor, templates, mouse and full
Budget qualification remain open; no C1–C5 milestone or inventory item closes.

## Budget view-account picker and cancellation repair (2026-11-09)

The actual `v` menu accepts RENT from BANK and then cancels a changed BANK choice.
Three seeded transactions retain their identities and middle-row selection;
reports, thirteen literal account links/defaults, all record fields and saved
bytes match the original exactly. A post-return account check prevents an early
observer sample from concealing the native cancellation defect.

The unchanged caller fails at mask 1535: cancellation changes the RENT balance
to zero. Both popup boundaries return -1 correctly. Budget's pointer comparison
loses the sentinel through zero extension on i386; BgtMain and the two analogous
BgtEntry comparisons now use DOCM_CANCEL(U8 *). No runtime/compiler ABI changes
are required. The current-source original control verifies the reviewed casts
on the original x64 runtime; nested entry-picker UI is still separate work.

Pinned-original v7, reviewed-source original v1 and repaired native v1/v2 pass
masks 2047/63. Native reopening is a real shutdown/restart; read-only abort leaves
all file bytes/attributes/timestamps unchanged. All 112 transaction bytes,
sixteen strings and thirteen accounts equal seed/original exports; 1,877 existing
files are preserved and both exits render fresh arithmetic. The prior modified
entry/copy cancellation and cold-reopen regression also passes.

See [the exact workflow and reproduction commands](i386-budget-account-picker.md)
and build/budget-account-picker-audit-v1/result.json. Both bootstrap generations,
source/image delivery, unchanged kernel/sixteen runtime modules, twelve-field
pointer probes and seventeen negative oracle checks are audited. Inventory only
appends component receipts. Nested pickers, account-file editing, other field
changes, templates, mouse, resource profiles and full Budget/C1–C5 qualification
remain open; bundled qualification remains 2/686.

## Budget nested entry-form account menus (2026-11-09)

The new `test-i386-budget-entry-picker.py` enters a transaction with blank credit
and debit accounts. Submitting opens the real credit menu: choose RENT and cancel,
then choose BANK and accept. The debit menu similarly cancels a changed CASH
selection and accepts RENT. Read-only observation confirms each selection before
the keyboard action and every returned form's date, amount, description and
blank/populated accounts. No transaction or unsaved data/string file exists
before final form acceptance. Raw data-tag/amount exports cover values omitted
by ordinary document serialization.

Original build/budget-entry-picker-original-v3 and normal native
build/budget-entry-picker-capture-native-v1 pass masks 1023/63. Exact original menu
headers/colors/order/literal identities, final reports and 48-byte saved data,
twelve strings and 97-byte accounts are checked. Existing numerical policies
are checked exactly: only saved amount byte 32 differs after formatted original
round trips. Native actually shuts down/restarts; read-only abort preserves all
file bytes/attributes/timestamps and fresh arithmetic follows both exits. The
session preserves 1,877 existing files. Original reopening is same-boot.

See [the workflow and commands](i386-budget-entry-picker.md) and
build/budget-entry-picker-audit-v1/result.json. The previous pointer-width fixes
are exercised directly; no additional application/runtime code change is needed.
Account-file editing, other field changes, templates/periodic entries, mouse,
resources and full Budget/C1–C5 acceptance remain open. Inventory adds component
receipts; bundled qualification remains 2/686.

One unchanged-fixture native run (build/budget-entry-picker-native-v2) saves
all three files but times out before the caller contract completes; its final
screenshot shows the console. Two capture-wrapper runs return successfully,
but the cleanup/observer-join boundary remains unresolved. Preserve that failed
receipt as a C2/C3 issue; passing picker evidence does not close it.

## Budget return repetition and failure captures (2026-11-09)

Two further nested-picker commands pass entry/cold-reopen masks 1023/63, while
the earlier first-close timeout remains unresolved. The return profiler adds
sixteen real read-only Budget reopen/abort sessions with exact saved records,
caller restoration, fresh arithmetic and unchanged contents/attributes/timestamps
for all 1,881 files. No installation or data reseeding occurs. Retained observer
exports prevent interpreting this as heap-recovery qualification.

A failure stops QEMU and retains registers plus 64 MiB memory. An explicitly
induced host exception at the active view verifies capture delivery; it does not
reproduce the runtime stall. The snapshot analyzer verifies public task metadata,
bounded Budget callers and four malformed-capture rejections. See
[return diagnostics and commands](i386-budget-return-diagnostics.md) and
build/budget-return-diagnostics-audit-v1/result.json. Runtime sources/modules are
unchanged. The original timeout, other Budget workflows and complete C1–C5
acceptance remain open; inventory qualification remains 2/686.

## Budget late-save deadline and ATA scheduling (2026-11-09)

A full nested-picker repetition captures the late caller in BgtAcctsWrite's
allocation-bitmap I/O, before its first device-status poll, while WinMgr renders.
Continued observation completes a save at 44.6 seconds including snapshot cost.
This establishes a deadline overrun for the reproduced case rather than an
unbounded observer/settings wait. The original uncaptured failed receipt stays
preserved.

A private per-channel poll-yield token now allows ready I/O work between
scheduled yields while admitting IRQs at every callback and preserving FIFO,
I/O guards, port/status/poll/error and poisoning behavior. Three full nested-
picker cycles pass unchanged 30-second markers and mask 1023; saves measure
7.0–7.6 seconds. The canonical command passes masks 1023/63 with real cold
reopening, unchanged saved files and fresh arithmetic after both returns.
The raw-write microbenchmark shows no comparable gain, so this is bounded
workload evidence rather than general storage throughput qualification.

See [the change and exact checks](i386-ata-poll-scheduling.md),
build/ata-poll-budget-audit-v1/result.json, the expanded two-drive ATA contract and
public retained transfer receipt. Both bootstraps and the 386 audit pass; only
FileRuntime changes among sixteen binaries, with public ABIs unchanged.
Other Budget workflows, resource recovery and complete C1–C5 qualification remain
open; bundled qualification remains 2/686.

Budget account-file editing now has original/native real-keyboard evidence:
GREEN/BANK + GHOST cancellation, then RED/BANK + GIFTS save, exact draft and
intermediate/final files, stable seeded transaction, report color and caller
restoration. Masks 1023/63 include actual native cold restart/read-only abort,
unchanged file bytes/attributes/timestamps and fresh arithmetic after both exits.
The initial native failure exposed standalone Ed routing; the next exposed
missing Ctrl-T and non-form window navigation. Generic popup file editing now
uses shared DocFileEd and original visible-document key behavior. Only
ConsoleRuntime changes; Budget source, kernel, fifteen other modules and public
ABI remain unchanged. Both bootstraps and a standalone parent-search editor
regression pass. See [account editor evidence](i386-budget-accounts-editor.md).
Templates/periodic entries, mouse, resources and complete Budget/C1–C5 acceptance
remain open; component receipts leave qualification at 2/686.

Budget interval templates and periodic copies now have original/native real-form
keyboard evidence, without seeded entries. Typed schedule cancellation, accepted
three-row template, nested periodic entry cancellation and retained schedule,
outer cancellation, and final two-entry periodic copy pass masks 262143/63.
Host checks cover all form tags/deferred backing bytes, row/string ownership,
unchanged original identities, exact template/ordinary storage and reconstructed
equal-date ordering. Native cold restart/read-only abort preserves all file
bytes/attributes/timestamps; fresh arithmetic follows both exits. Both exact
floating-point policies are recorded (four saved-byte differences), while date
fraction four agrees on both targets. No runtime/application code changes.
See [template and periodic evidence](i386-budget-templates.md). Other recurrence
types, template editing/deletion, mouse/resources and full Budget/C1–C5 remain
open; component evidence leaves qualification at 2/686.

Calendar recurrence now has four original/native real-keyboard controls:
monthly/bimonthly/semiannual/annual creation, both nested cancellation paths,
identity-preserving cancelled edit, accepted recurrence/base-entry replacement,
whole-family deletion, recreation and cold persistence. Masks 16777215/63 and
exact menu/form/backing/live/storage oracles pass; only saved byte 84 differs
under the established exact binary64 policies. All expanded dates retain the
same four-tick quantization. See [recurrence evidence](i386-budget-recurrence.md).

The first native controls exposed finished picker children retained by linked
scroll controls. Generic committed task retirement now detaches associations
after descendant/render draining. The focused unchanged return/Exit/recovering-
Kill fixture fails 51/0/0 before and passes 255/255/255 afterward, including
borrowed storage survival and actual heap/child-list reclamation. See
[retirement evidence](i386-control-retirement.md). Both existing bootstraps and
the 386 audit pass; only ConsoleRuntime changes, with unchanged kernel/ABIs.
The DocEd-exit regression passes; derived-control regression remains pending.
The combined audit revalidates eight captures and rejects 660 corruptions.
Boundary validation, mouse/resources, complete Budget and C1–C5 remain open;
component receipts leave qualification at 2/686.

Budget validation now has original/native real-keyboard rejection controls for
zero/negative intervals, Null type, and cancellation of a typed base transaction
followed by invalidating the retained schedule. Mask 1023, exact seven-phase
forms/backing/menu and four empty reports pass. No data/string file is created;
native abort preserves all file bytes/metadata after installation and renders 42.
See [validation evidence](i386-budget-validation.md).

The separate direct expansion API control matches all 2872 bytes for eighteen
boundary/mode cases: day/month overflow, leap year, reversed/equal ranges, Null,
half-day intervals and the existing >2050 year mapping. It checks template shared
ownership versus independently owned periodic copies, first-row omission,
contents/links and an empty queue after cleanup. See
[boundary evidence](i386-budget-boundaries.md). Audits reject
323 validation and 361 boundary corruptions; runtime modules/bootstrap
inputs remain unchanged. Earlier setup/synchronization failures are retained,
not passing controls. The derived-control regression is still pending. Mouse,
resources and complete Budget/C1–C5 remain open; qualification remains 2/686.

The Budget mouse workflow now has a passing original reference (1023/63) and an
explicit unchanged native failure. Real PS/2 events select rows/accounts, and
original double-left/right clicks save/abort. Exact report/live identities,
column-two cursors, edit prefill/cancellation, menus, storage and caller recovery
are checked. Native reaches the first pointer target but leaves the retained
document cursor at the end; stopped RAM/registers and 276 completed manager
updates are retained. The managed worker lacks original retained-document mouse
click dispatch; packet/button consumption and default timing also need checks.
See [the strict mouse gate](i386-budget-mouse.md). The audit rejects 188 corrupted
records and does not label the native failure as a pass.

Explicit derived-control cleanup now passes all six masks 63 via the unchanged
function definitions compiled from a file, with the identical WinMgr pause
before callbacks, raw results, exact caller heap/frame recovery and unchanged
files/metadata. The legacy interactive attempt stopped on an eight-pixel console
viewport shift before cleanup; that wrapping issue remains open. See
[cleanup provenance and commands](i386-control-retirement.md). This does not
qualify automatic prepass or console input. No runtime/modules/bootstrap inputs
changed. Native mouse, console input, resources and full C1–C5 remain open;
qualification remains 2/686.

The later managed document dispatch checkpoint passes the strict unchanged
Budget mouse workflow natively (1023/63), including cold reopen without Install,
exact saved state, caller recovery and 1884 preserved prior files. Queued PS/2
edges use the shared original recognizer/action rules; boot-position and
callback-Exit cleanup have retained red/green controls. The existing cursor,
mouse-state and control cleanup regressions pass. The unflagged DocEd comparison
retains its exact prior 113/95 and 524/609 pixel failure; the 8 MiB functional
mouse run takes 65.97 seconds and is not a 60-second startup-gate pass.
See [architecture, receipts and remaining gaps](i386-window-mouse-dispatch.md).
Control capture, wheel, borders/dragging, top menus, rendering/resources and
native rebuild generations remain open. Qualification remains 2/686.

Managed control mouse dispatch now passes the same eight-phase original oracle:
left/right ordinary and border coordinates, repeated held capture, outside
release and self/focus inhibition. The unchanged old image records no callbacks;
its strict failure is retained. Five native throw/recovering/committed Exit and
owner-retirement cases pass 255, including actual worker identity, child drain,
borrowed-control detachment and exact controller heap recovery. Budget retains
its full mouse/cold pass (1023/63, 1885 prior files). See
[the control component evidence](i386-control-mouse.md). This does not qualify
raw-focus controls, default motion gain, wheel/border/menu/raster/resources or
complete C1–C5. Qualification stays 2/686.

Raw-focus control input now passes the same original eight-phase callback oracle,
including left/right, border coordinates, held capture/outside release and both
inhibition flags. The old native image completes inputs with no callbacks; the
new control-only route leaves managed-render admission unchanged. Managed input,
five callback-lifetime modes and Budget mouse/cold reopening (1023/63) still pass.
The strict unflagged editor retains exactly its prior 113/95 and 524/609 client
failure. See [raw control input](i386-raw-control-input.md). Raw document input,
raw control drawing/legacy scopes, default hardware motion gain and full C1–C5
remain open; qualification stays 2/686.

Original default mouse gain and edge history now match 62 physical-input steps
and 744 independent state values, including x=0/639, y=0/479 and reversal. The
shared integer prescale/offset helper also matches on the rebuilt classic system.
Native UI consumers use logical coordinates while raw MouseGet retains its
additional device contract. Help/picker pixels and mouse-state behavior pass at
8 MiB; queue, raw controls, five callback-lifetime cases and Budget mouse/cold
reopening pass. See [motion evidence](i386-mouse-gain.md). The complete device
group still fails console typing after held click, byte-identically before/after;
unflagged DocEd remains 113/95 with 524/609 client differences. Wheel, full
ms_hard/MsSet, timing/bursts, remaining desktop/app/resources and native/minimal
startup acceptance remain open. Qualification remains 2/686.

The current native Psalmody keyboard oracle reaches the unchanged
PsalmodyMain source and rejects the undefined SwapI64 identifier at line 226,
before the keyboard workflow runs. The retained failure is in
`build/ac-dictionary-direct-copy/psalmody-keyboard64/result.json`.
A candidate publishes the existing native Console swap routine through
PublicMemory and preserves the source of the application. It cross-builds.
The native loading and keyboard checks are pending.

The Console-only SwapI64 candidate fails during early PublicMemory loading
because Console has not yet registered its symbols. The second candidate
registers the existing MemoryRuntime swap routine alongside the other
early memory bindings. It passes the native 8 MiB signed 64-bit swap and
same-address operand checks, followed by fresh arithmetic. The original
Psalmody load advances from line 226 to RegOneTimePopUp at line 584.
The patch and receipts are in `build/psalmody-public-swap-v2`. This remains
an overlay while the two-generation harness pins the production sources.

With the early SwapI64 binding and the shared registry popup core, the
unchanged Psalmody application loads and runs its keyboard workflow. The
first popup overlay failed boot because its serialized export names contained
an empty slot. The corrected overlay verifies all 700 names and passes
native startup. The keyboard test records the expected three pitches,
deletes the last note and restores caller state (mask 63). It fails
the original exact duration check, recording 0, 7 and 8 instead of
three 8s. The timed keyboard regression remains open. The candidate,
failing receipt and decoded vectors are in `build/psalmody-registry-popup-v2`.

The registry-popup overlay passes a separate native 64 MiB modal check with
physical mouse and keyboard input. Shift-Escape and unchecked OK preserve
the flag. Checking the box and clicking OK commits the Psalmody JukeBox
suppression bit. The next call returns immediately, and a fresh boot reloads
the bit and suppresses the popup again. Only the test fixture and
`/Home/Registry.HC.Z` change. The cold session preserves every file and
renders fresh arithmetic. The fixture and receipt are in
`build/psalmody-registry-modal-v4`. Psalmody's timed keyboard acceptance and
production integration remain open.

The combined SwapI64 and registry-popup overlay also passes the standalone
8 MiB production User check at 50.95 seconds with the managed pointer
and five command/raster checkpoints. The existing 60-second budget checker
passes on that receipt. See `build/psalmody-registry-popup-v2/user8`.

The integrated native image passes the unchanged TimeClock report workflow at
64 MiB on a 486 with the FPU disabled. The report matches the original bytes,
totals 5,400 seconds, and reproduces after a cold reboot. All raster checkpoints
pass in both sessions. This workflow uses typed fixture records. The receipt is
in `build/i386-graphics-registry-integration/timeclock-report64/result.json`.

An experimental ConsoleRuntime overlay passes the physical PS/2 application
menu gesture from the original oracle. After the observer publishes its first
sample, the pointer reaches (20, 4), drags with the left button held to (20, 12),
and releases. The focused task receives the exact command tuple (1, 2676, 83).
The earlier candidate attempt timed out waiting for the initial pointer target.
The observer receipt records both logical and raw device coordinates and is
saved with its fixture in `build/application-menu-mouse-observer-v1`. Production
integration and broader menu behavior remain open.

The same menu patch was rebased onto the integrated changed-row VGA image.
The ConsoleRuntime instruction audit passes and the physical gesture again
delivers (1, 2676, 83) at 64 MiB. Build commands, packaging and runtime
receipts are in `build/application-menu-integrated-v1`.
The unmodified image reaches both pointer targets but times out waiting for the
menu command after release. Its receipt is in the same directory.

On the original system and the rebased overlay, releasing outside the menu
dispatches no command. The two subsequent selections each dispatch
(1, 2676, 83) exactly once. The full heading row and the selected dropdown
region match the original across 6,272 pixels. The overlay also passes
the 8 MiB User smoke test in 50.55 seconds with five raster checkpoints.
See `build/application-menu-repeat-v1` for the repeat, raster and startup
receipts. The menu overlay still awaits production integration.

The integrated image passes the unchanged Budget physical mouse workflow and
read-only cold reopen. It also reproduces the unchanged KeepAway load boundary
at `SettingsPush` on line 645. Loading TaskSettings directly reaches an undefined
`AutoComplete` at line 82 of TaskSettingsCore. These receipts are under
`build/i386-graphics-registry-integration`.

The integrated image passes the Noise and Sweep task, speaker and mute cleanup
checks with four exact raster checkpoints on the managed-pointer profile.
The earlier TCG attempt timed out at the initial raster comparison before
sending any test command. The passing receipt and profile wrapper are in
`build/i386-graphics-registry-integration/sound-effects-managed64` and
`build/i386-graphics-registry-integration/sound-with-managed-pointer.py`.

KeepAway's unchanged Load.HC succeeds after explicitly loading the bundled
autocomplete library and TaskSettings in that order. All three application
files match the original and fresh arithmetic executes afterward. The
`keepaway-libraries64` receipt records this 64 MiB KVM session. Normal startup
still requires library integration for this launch path, and gameplay remains
open.

The integrated image passes the unchanged TimeClock physical keyboard run.
Four punch records encode the original multiline, accepted, and cancelled
descriptions. The cold boot reads them back byte for byte. The receipt is
in `build/i386-graphics-registry-integration/timeclock-keyboard64/result.json`.

KeepAway now has an original launch, jump, restart and exit oracle. With
the explicit libraries, the 64 MiB integrated image reproduces the state
transitions and restores the caller. Its render fails. The native frame has
zero arena-yellow pixels, compared with 291,658 on the original. The Window
Manager reports OutMem after a 536,461,778-byte allocation request.
See `build/keepaway-play-v1` for the fixture, captures and separate gameplay
render check. Gameplay qualification remains open.

The compiled KeepAway frame table matches the original on all 30 entries.
Each selected sprite reports a length of 4,042 bytes, and every 32-byte
prefix hash matches. This comparison is in `build/keepaway-sprites-v1`.
The live draw path still needs diagnosis, including which frame data reaches
interpolation when the allocation fails.

KeepAway now stores its temporary object pointers in explicit I64 slots for
QSortI64, following the port's existing fixed-width sort convention. The
original used a pointer array, whose entries are four bytes on i386.
The comparator, draw order rules, and embedded sprite bytes are preserved.
The original-width control and both repaired native checks pass. The native
check through the bundled Load.HC path captures 295,061 arena-yellow pixels
and 4,280 red border pixels, with no Window Manager exception. Jump, restart,
exit, caller restoration and fresh arithmetic also pass. Live-game frames
are timing dependent. See `build/keepaway-sort-production-v1/native64/result.json`.
Scoring, additional input, and automatic startup library loading remain open.

A fresh full-content cross-build also passes the boot instruction audit and
ships the repaired KeepAway source. All 686 inventory files match the current
tree. The full image passes the 64 MiB launch, jump, restart, exit, caller
restoration and arena raster checks. See `build/keepaway-sort-production-v1`
for the image identity and runtime receipts.

KeepAway's bundled loader now resolves autocomplete and TaskSettings on demand
when their public functions are absent. Autocomplete loads first so task
settings can bind it. The patched loader passes on the original system and
on a cold 64 MiB native boot with no preparatory library commands. The native
run passes arena rendering, jump, restart, exit and caller restoration.
See `build/keepaway-libraries-lazy-v1` for the original and native receipts.

The fresh full image runs the bundled Run.HC twice directly from a cold boot.
Both launches render the instructions and arena and return to the prompt.
The second launch reuses the exact autocomplete and task-settings symbols from
the first. No library commands are needed before either launch. The same image
passes the 8 MiB User smoke test in 50.43 seconds. The full image audit, launch
and startup receipts are in `build/keepaway-libraries-lazy-v1`.

The original ten-case Logic synthesis oracle now passes on the current native
64 MiB image. All three application files match the reference. After loading
autocomplete and TaskSettings, the unchanged Logic code produces mask 1023
and the prompt accepts fresh arithmetic. The interactive Logic workflow and
automatic library loading remain open. See
`build/logic-synthesis-current-v1/native64/result.json`.

With controlled ball placement, original and native KeepAway both award
2 points for a handoff and 6 for a recent pass, reaching a total of 8.
The original accepts Space to shoot. The native run times out waiting for
the same shot transition after Space. These results are in
`build/keepaway-score-v1`. The scoring check uses controlled game state.

Using a left-button press in place of Space gives the same split. The original
starts the shot, while the native run records both scores and times out
waiting for the shot transition. See `build/keepaway-score-mouse-v1`.

The Space-key trace reaches the native Shoot function with possession set
and no shot active. The function sets active, stopped, and shooting to 1,
and clears possession. The observer still times out waiting to see the
active flag. Splitting the chained assignment produces the same timeout,
so the production assignment is unchanged. See
`build/keepaway-shot-state-v1` and `build/keepaway-shot-split-v1`.

A trajectory check confirms that the original Space-key shot updates the
ball's flight deadline after its animation. Native Space and left-button
input both time out waiting for this persistent update. The original
animation sample progresses through the shooting frames and updates the
deadline. The native sampler records only its first sample before timing out.
See `build/keepaway-shot-trajectory-v1` and `build/keepaway-shot-animation-v1`.

Physical keyboard entry now reproduces an AND synthesis on the original
and native Logic application. Typing gate AND, inputs F0 and CC, and output
C0 produces the expected gate and input links. The circuit region matches
the original across 3,795 pixels. Both sessions return to their caller, and
the native session renders fresh arithmetic. The native test explicitly
loads autocomplete and TaskSettings before launching Logic. See
`build/logic-interaction-return-v1` for the input and raster receipts.

Logic's bundled loader now uses the same guarded autocomplete and task-settings
order as KeepAway. The original and cold native runs pass the physical AND
workflow through Load.HC without preparatory library commands. All 3,795
circuit pixels match the original region, and fresh arithmetic renders.
See `build/logic-lazy-load-v1` for the receipts.

Host-side memory sampling confirms that the native shot flags remain set
while the frame deadline stays fixed across 16 samples. The original advances
its frame deadline and completes the flight update. The native game still
accepts Escape and returns to the prompt. This localizes the remaining gap to
post-input animation for the tested state. See
`build/keepaway-shot-host-observer-v1`.

The host sample repeats the native frame stall with both test-side animation
task suspension calls removed. The native shot flags stay set, and all 16
samples report the same frame deadline and original flight deadline. See
`build/keepaway-shot-no-suspend-v1/native64/result.json`.

The fresh full image repeats the Logic keyboard-driven AND workflow through
its bundled loader. The 3,795-pixel circuit region matches the original
again, and fresh arithmetic renders. See
`build/logic-lazy-load-v1/full-play64/result.json` and
`build/logic-lazy-load-v1/full-raster.json`.

The unmuted KVM KeepAway trace holds the guest jiffy counter and Window Manager
update count fixed after the shot becomes active. At the sampled point, the
CPU has interrupts enabled and the PIC timer interrupt is unmasked. With
`Mute(ON)`, both counters advance and the shot animation progresses through
frames 4 to 8. The shorter sample ends before the flight deadline updates.
See `build/keepaway-shot-muted-timer-v1/comparison.json`. Longer muted and
unmuted TCG controls are underway.

The bundled Vocabulary sources load on the current native image after
explicitly loading autocomplete. All three files match the original, and
fresh arithmetic executes. Dictionary initialization and the interactive quiz
remain open. See `build/vocabulary-libraries-v1/native64/result.json`.

The longer muted KVM control and the unmuted TCG run both finish the Space-key
shot, clear the active flag, and update the flight deadline. The unmuted
KVM stall remains open. A smaller test with two overlapping Noise tasks
keeps the clock advancing under both KVM interrupt-controller configurations.
These results narrow the failure to a condition in the full KeepAway
scenario. See `build/keepaway-shot-timer-controls-v1` and
`build/native-speaker-clock-v1`.

The controlled unmuted KVM comparison uses the same image, fixture and
physical Space-key sequence for both runs. With the in-kernel interrupt
controller enabled, the flight deadline remains unchanged. With
`-machine pc,kernel_irqchip=off`, the guest clock advances and the shot
updates the flight deadline. Both runs return to the prompt. The result
establishes an alternate verified KVM profile for this workflow. The default
KVM stall still needs a root-cause fix. See
`build/keepaway-shot-irq-controls-v2`.

The Vocabulary quiz reference opens a definition after a numbered answer,
dismisses the popup, and exits at the next question. Native initialization
uses the original compressed word archive and the bundled definitions.
The native run renders a question, accepts a numbered answer, opens the
definition popup, and renders the next question after dismissal. It times
out waiting for quiz exit after the next Escape. The native final capture
shows that fresh question and its unanswered prompt. See
`build/vocabulary-quiz-dismiss-v1`. The next test waits for the fresh
unanswered prompt before sending Escape.

Waiting for the second unanswered Vocabulary prompt still leaves Escape unable
to exit. The native focus sample identifies the quiz task at the first prompt
and the definition task during the popup and at the next prompt. A physical
click puts keyboard focus back on the quiz. Escape then exits and fresh
arithmetic renders. See `build/vocabulary-quiz-focus-v1/native64/result.json`.
A separate clean boot reaches the same quiz with the bundled dictionary bytes
alone, after explicit autocomplete load and ACInit. That test adds only the
probe to the image. See `build/vocabulary-bundled-dictionary-v1`.

Vocabulary now loads autocomplete on demand and initializes the dictionary
when the quiz starts with an empty word list. A cold 64 MiB run with the
bundled dictionary and no preparatory library commands reaches the question,
accepts a choice, and opens the definition. The run uses a click to restore
quiz focus before exiting. Fresh arithmetic renders. See
`build/vocabulary-lazy-init-v1/native64/result.json`. Automatic focus
restoration after the definition still needs a fix.

The rebuilt full Vocabulary image passes the boot instruction and 686-file
inventory audits. Its cold quiz starts with the bundled dictionary. After
Escape dismisses the definition, the popup task signature is cleared while
keyboard focus still holds its old task address. Clicking the quiz restores
focus and permits Escape to exit. See `build/vocabulary-lazy-init-v1/full-inventory.json`
and `build/vocabulary-popup-lifetime-v1/native64/result.json`.

A minimal asynchronous PopUp and View reproduces the same native stale focus.
The original retires the popup and routes the next key to its caller. The
native baseline retires the popup and leaves focus at its former address.
The retirement overlay selects the next eligible task in window order.
It returns focus to the caller in the minimal test and in the complete
Vocabulary answer, definition, and Escape workflow without a mouse click.
The overlay passes its instruction audit and the 8 MiB User smoke test in
50.74 seconds. See `build/async-popup-focus-inline-v1` and
`build/async-popup-focus-retire-v1`. The production source remains pinned by
the ongoing native rebuild.

The retirement-focus and application-menu patches also pass together on the
full Vocabulary image. The overlay passes the instruction audit, the original
popup focus handoff, and the complete Vocabulary answer and Escape workflow.
Outside menu release dispatches no command, each of two subsequent selections
dispatches (1, 2676, 83) once, and all 6,272 checked menu pixels match the
original. The 8 MiB User smoke test passes in 50.90 seconds. See
`build/native-focus-menu-overlay-v1`. Broader popup regressions are still
running under the managed-pointer profile. The two patches remain overlays
while the two-generation harness uses its pinned production sources.

The popup lifetime and window-order assertions both pass on the focus-only
overlay and the combined focus/menu overlay. The observed lifetime values
are 1, 1, 63, 63 and 255. Window order returns mask 255. The two standard
screen-driven wrappers stopped at screenshot comparisons earlier in their
runs. The passing runs package the same assertions and check their direct
output markers, followed by exact fresh arithmetic glyphs. See
`build/native-popup-contracts-v1`.

On the combined focus/menu overlay, Psalmody also records all three expected
notes at the exact original durations when input starts after redraw. The
recorded and post-backspace files and caller mask match the original bytes.
See `build/native-focus-menu-overlay-v1/psalmody64/result.json`. The
immediate-input timing case remains open.

The original COrder2D3, CMass, CSpring and CMathODE declarations compile on
the full native image. The original AMathODE then rejects mp_cnt in ODEDel.
A scratch single-CPU derivative path advances to the missing D3Norm
dependency. Adding the needed scalar F64 vector operations advances beyond
their definitions, but compiling the serial ODE source still throws a
Compiler exception without a diagnostic location. Strut has yet to load in
this sequence. See `build/strut-ode-types-v1` and `build/strut-ode-d3-v1`.

Popup focus recovery, the application menu, and timestamped Psalmody note
durations are integrated in the production sources. Both original bootstrap
rebuilds and the native full cross-build pass. The full image matches all
1,533 delivered source and documentation files and all 686 inventory files.
The production image passes repeated menu selection and cancellation,
Vocabulary definition dismissal and keyboard-only exit, and the immediate
Psalmody note-vector comparison. The 8 MiB User smoke test passes in
50.72 seconds. See `build/native-focus-menu-psalmody-production-v1`.

WordSearch now uses I64 slots for the original QSortI64 comparator, preserving
pointer values across i386 and x64. A controlled 20-by-20 grid collects words
in all eight directions. The original and ported native run match all 3,200
logical strings and the complete zero-padded export. The unchanged native
pointer-width variant corrupts the sort output. Fresh arithmetic follows the
ported run. See `build/wordsearch-sort-v1` and
`build/wordsearch-sort-zeroed-v1`. The dictionary-backed full demo workflow
remains open.

The Strut ODE failure isolates to ODERK5OneStep after compiling the previous
23 units. Replacing four positive-base backtick powers with Exp and Ln in a
scratch single-CPU ODE variant lets the whole library compile. Strut then
reaches its missing CCtrlBttnState dependency. The original button library
is under test. See `build/strut-ode-compile-units-v1` and
`build/strut-ode-power-v1`.

WordSearch now loads autocomplete and initializes the bundled dictionary on
demand. Its normal include path passes from a cold 64 MiB boot with no setup
library commands. With the same seed, the 20-row display and both dictionary
searches match the original's complete 1,944-byte DolDoc output, including
all 366 displayed matches. The capture removes only the exact native command
echo after the output. Fresh arithmetic renders. See
`build/wordsearch-dictionary-exact-v1/native64/result.json`.

The original CtrlsBttn.HC loads on native i386, moving Strut to the
Mat4x4Scale binding at line 93. A Console overlay publishes the existing
Mat4x4Scale, DCSymmetry3Set, GrPlot3, and GrLine3 implementations. Its
instruction audit passes. With the explicit ODE, scalar vector, settings and
button dependencies, the unchanged Strut Load.HC compiles and fresh
arithmetic renders. See `build/strut-native-raster-bindings-v1`.
Physical input places two masses on both the pinned original and the native
overlay. Neither run observes spring creation after the fixture's drag, so
the paired check ends before play mode. See `build/strut-edit-play-v1`.

The native single-CPU ODE probe emits mask 5 of the expected 7 for
`x' = x`. It passes scalar vector checks and the five-step adaptive RK5
check. The fixed-step RK4 assertion fails and the probe does not isolate
which part of that assertion failed. See `build/strut-ode-numeric-v1`.

The 128 MiB retained rebuild of the latest production image is still in
progress at this checkpoint. The completed C5 generation results above
apply to the earlier graphics and registry image.

The RK4 routine writes the initial derivative to `ode->DstateDt` and
reads it through a local pointer initialized to `ode->tmp3`. The original
Adam source contains the same mismatch. A scratch variant points the
local at `ode->DstateDt`. The same native analytic probe now emits mask 7
and the console renders fresh arithmetic. See
`build/strut-rk4-derivative-v1/native64/result.json`. Reconstruct the
tested ODE source before running the probe with:

```sh
patch -o build/strut-rk4-derivative-v1/SerialODE.HC \
  build/strut-ode-power-v1/SerialODE.HC \
  < build/strut-rk4-derivative-v1/derivative.patch
```

The original Strut draw callback recenters its viewport after the first
mass. The earlier fixed-screen drag selected the second mass at both
ends. The projected-endpoint fixture reads the current viewport transform
and drags from the first mass at (320, 244) to the second at (245, 180).
The pinned original creates the spring, enters play, advances past
0.01 seconds of simulation time, and returns on Escape. This workflow
is recorded in the inventory. See `build/strut-projected-drag-v1`.

The native raster overlay reaches the same projected endpoints and
creates a spring through physical input. Space enters play. The probe
times out waiting for the simulation clock to pass 0.01 seconds.
The native window worker pumps input and presents frames, with no ODE
update phase corresponding to the original window manager. See
`build/strut-projected-drag-v1/native64/result.json`.

An exploratory native observer calls the serial ODE updater at play
entry. The run creates the spring and sends Space, but the observer
does not reach its play marker after that call becomes eligible. Its
receipt does not establish whether the updater threw, stalled, or was
never invoked. See `build/strut-simulation-tick-v1/native64/result.json`.

With the play marker emitted before the diagnostic tick, native Strut
reaches `ODEsUpdate` with a positive refresh rate and time zero. The
updater does not return within the observation window. A separate test
against the production image observes zero next and last ODE links on
both the fresh console and a newly spawned task. The original task
constructor initializes these links to the address of the queue head.
The candidate scheduler patch restores that initialization for root
and prepared tasks. It applies cleanly and still needs a native build
and runtime verification. See `build/strut-simulation-update-trace-v1`
and `build/native-ode-task-birth-v1`.

The same native Strut trace passes when the fixture initializes the two
zero links before launch. Physical input creates the spring, the explicit
ODE update returns, simulation time advances, Escape exits, and fresh
arithmetic renders. This verifies the queue initialization dependency.
The normal window worker still needs the update phase. The scheduler
candidate is building in a compiler overlay while the separate production
retained rebuild continues. See `build/strut-ode-task-ring-v1/native64/result.json`.

The scheduler overlay cross-build and protected-mode boot audit pass.
A fresh console and its spawned child both have self-linked ODE queues,
and fresh arithmetic renders. This candidate changes the scheduler
binary through the compiler overlay. The runtime test covers task
initialization. The console's automatic ODE update remains separate
work. See `build/native-ode-task-birth-v1/candidate64/result.json`.

The scheduler candidate also passes a serial ODE check with a stretched
spring. A fixed anchor at zero and a unit mass at two start at rest.
With rest length one and spring constant four, the integrator reaches
0.1 seconds with position 1.98006658 and velocity -0.39733866. Both
match the analytic oscillator within the probe tolerance of 0.02,
and the fixed anchor remains at rest. The test drives the solver
explicitly through the task's initialized queue. See
`build/native-stretched-spring-v1/native64`.

The 128 MiB retained rebuild of the production focus, menu, and Psalmody
image completed all nine module builds. A two-generation qualification run
has started from that passing retained image. See
`build/native-focus-menu-psalmody-production-v1/retained128/result.json`.

The combined scheduler and Console candidate passes the 386 instruction
audit and the paired Strut physical-input workflow. The native window
worker calls the serial updater without a diagnostic tick. Two masses and
a spring are placed, play advances beyond 0.01 seconds, and Escape returns
to the console, where fresh arithmetic renders. These runs still load
Strut's dependencies explicitly. The candidate's vector export bitmap
also needs expansion before those exports are exercised by a cold loader.
See `build/native-window-ode-v1/combined/result.json` and
`build/native-window-ode-v1/strut64/result.json`.

The pinned original Span serializer passes a RAM-disk save and reopen
of a simple steel bridge. The version 1.0 file is 312 bytes, with a
16-byte header, two 100-byte masses, and one 96-byte spring. Reopening
restores the fixed anchor and both endpoint links. The in-memory export,
disk readback, and re-encoding match byte for byte. The original file
is retained as a native differential oracle. See
`build/span-reference-persistence-v1/ram-reference`.

The cold Strut loader candidate cross-compiles after moving ODE type
definitions before their prototypes and giving the enlarged export bitmap
its full initializer. The combined image passes the instruction audit.
This candidate loads settings, controls, and autocomplete on demand and
binds ODE through the resident module. The cold interactive test is
running. See `build/native-strut-entry-v1`.

The cold Strut loader candidate passes the interactive workflow. The
first guest command includes the app's Load.HC. The fixture then starts
Strut, places two masses and a spring, enters play, observes the native
window worker advance simulation time, and exits with Escape. Fresh
arithmetic renders. The app acquires its dependencies on demand and
uses resident ODE bindings. See
`build/native-strut-entry-v1/strut64/result.json`.

The native Span persistence comparison reaches the original loader and
stops at the missing `PopUpFileName` service in SpanNew.HC. The trial
compiles the serial ODE variant and the original button library before encountering
this gap. The file comparison remains open. See
`build/span-reference-persistence-v1/native64/result.json`.

The original filename-form and popup functions compile as a scratch
dependency on native i386. Adding them moves Span beyond the previous
`PopUpFileName` diagnostic, but the bundled loader still reports a
compiler exception without a source line. The next probe loads its
five includes separately to identify the failing source unit. See
`build/span-native-chooser-v1/native64/result.json`.

Original Span now has a physical-input reference for dismissing the
instructions, placing a mass on the 15-mass default bridge, starting and
stopping simulation with Space, and exiting with Shift+Escape. The
simulation clock stays fixed while paused, and exit restores the caller's
draw callback and empty ODE queue. The split native loader reaches
SpanMain.HC before throwing an unlocated compiler exception. The earlier
four includes compile after supplying the filename chooser. See
`build/span-reference-mouse-v1/original/result.json` and
`build/span-native-compile-stages-v1/native64/result.json`.

The cold Strut candidate with the solver linked into ConsoleRuntime
boots at 8 MiB under KVM, but the original User fixture fails with
`OutMem` in `USCheck`. The previous production image passes that
fixture. A smaller Console candidate keeps the update phase and
loads the solver into Adam only when an ODE app opens. It cross-compiles
and passes the instruction audit. Its 8 MiB and cold Strut tests are
running. See `build/native-strut-entry-v1/user8-kvm/result.json` and
`build/native-ode-on-demand-v1/combined/result.json`.

The on-demand ODE candidate passes the cold 64 MiB Strut workflow with
automatic simulation, Escape cleanup, and fresh console arithmetic.
At 8 MiB, the same candidate still fails the original User fixture at
`USCheck`, with the same fallback-heap exhaustion values as the
resident-solver candidate. This keeps the startup regression open.
A scheduler-only image and the previous production image are under
test with the same KVM startup harness. See
`build/native-ode-on-demand-v1/strut64/result.json` and
`build/native-ode-on-demand-v1/user8-kvm/result.json`.

The original filename chooser accepts the default path with Escape and
cancels with Shift+Escape. The paired probe checks the returned string or
null and restoration of the caller's popup task. The original passes.
See `build/filename-popup-differential-v1/original-escape/result.json`.

The same filename chooser probe passes on native i386 with the original
chooser source and the native document and popup services. It returns
the default path on Escape, returns null on Shift+Escape, restores
the popup owner state, and renders fresh arithmetic. See
`build/filename-popup-differential-v1/native64-escape/result.json`.

Both the production image recheck and the scheduler-only candidate
pass the 8 MiB KVM User fixture. The ODE update phase remains the
focus of the startup investigation. A smaller candidate reuses the
window manager's existing guarded task traversal for the update pass.
See `build/native-focus-menu-psalmody-production-v1/user8-recheck/result.json`
and `build/native-ode-task-birth-v1/user8-kvm/result.json`.

A Console-only swap on the previous production kernel reproduces the
8 MiB failure. The next candidate shares the existing guarded task
traversal between geometry and ODE updates. Its Console module occupies
2,472 bytes more resident memory than production, down from 4,360 bytes
for the separate traversal. The 8 MiB KVM User fixture passes, including
the full startup mask and fresh arithmetic. The matching cold Strut
test is running. See
`build/native-ode-on-demand-v1/console-only-user8/result.json` and
`build/native-ode-shared-traversal-v1/user8-kvm/result.json`.

Eight functions from the original SpanMain.HC compile in source order.
The ninth, DrawSpring, throws the compiler exception. It switches
between the three spring materials before rendering a line. A follow-up
probe checks whether a default branch changes the diagnostic. See
`build/span-main-units-v1/native64/result.json`.

The shared-traversal image also passes cold Strut at 64 MiB. The same
image passed the 8 MiB User fixture and reached its startup screen in
50.85 seconds. A follow-up image selects the serial solver from the
original Adam ODE file. Selecting either branch reproduces the
corresponding original or tested serial source bytes. The shared-file
candidate also passes cold Strut, automatic play, Escape, and fresh
arithmetic. See
`build/native-ode-shared-traversal-v1/strut64/result.json` and
`build/native-ode-shared-solver-v1/strut64/result.json`.

A default branch does not change Span's DrawSpring failure. A reduced
probe compiles the original switch and property assignments by
themselves. The isolated GrLine3 call fails, including when the switch
labels are numeric. The next probe varies argument types and the call
target. See `build/span-draw-spring-default-v1/native64/result.json`
and `build/span-draw-spring-minimal-v1/native64/result.json`.

The Span raster-call probe compiles when the two coordinates first
go through typed I64 locals, or when integer literals replace the
floating-point members. Replacing the already-integer endpoint
arguments does not help. An otherwise equivalent local call target
also fails with the floating-point members passed directly, so the
failure does not depend on GrLine3's binding. The full Span loader is
under test with the typed locals, and a compiler trace is building.
See `build/span-line-call-v1/native64/result.json`.

The Span call failure comes from floating-point helper discovery. The
frontend checks whether values have an F64 class, but the implicit
F64-to-I64 flag makes the classifier return I64. The helper scan already
checks the reverse conversion flag. Adding the I64-result flag makes
all five reduced call forms compile on a native CompilerRuntime
overlay, including the unmodified member arguments. The runtime-value
and 8 MiB checks are running. See
`build/native-implicit-f64-helper-v1/native64/result.json`.

With explicit I64 locals, the full Span loader passes DrawSpring and
reaches the missing SndTaskEndCB binding in SongTask. An original music
player source slice with a native clock adapter is under test together
with the compiler candidate and the unchanged Span source. See
`build/span-native-coordinate-locals-v1/native64-typed/result.json`.

The compiler overlay also executes the direct member conversions.
The probe passes 7.75 and -3.5 to integer parameters and observes
the combined result 697. The combined compiler and shared ODE image
passes the 8 MiB KVM User fixture, reaching startup in 51.47 seconds.
A cold include of Strut's Run.HC on that same image matches the
instruction pixels, enters the editor, exits with Escape, and
renders fresh arithmetic. See
`build/native-implicit-f64-value-v1/native64/result.json`,
`build/native-implicit-f64-helper-v1/user8-kvm/result.json`, and
`build/native-strut-run-entry-v1/native64/result.json`.

With the compiler and music adapters, the unchanged Span loader
compiles. The native serializer writes and reopens a 312-byte file
with the original record sizes and reconstructed topology. Its
newly computed bridge differs from the original fixture in six
floating-point spring fields. The mass records and all other bytes
match. The original and native tests that reopen and re-encode each
other's files are running. See
`build/span-native-music-v1/native64/result.json`.

The pinned original opens the native-generated bridge and reproduces
all 312 input bytes after a RAM-disk save and readback, restoring the
anchor and both endpoint links. See
`build/span-file-interchange-v1/original/result.json`.

Native Span also opens the original bridge, restores its endpoints,
and saves the same 312 bytes. The host reads the returned file from
the native disk and verifies the original SHA-256. Both directions of
file interchange pass. A new native bridge has the same layout and
matches every other byte, with rounding differences bounded in six
newly computed spring fields. An earlier fixture incorrectly compared
FileWrite's return value with the byte count. The final fixture checks
its success and verifies the actual disk bytes. See
`build/span-file-interchange-v1/native64-roundtrip/result.json`.

The production focus, menu, and Psalmody two-generation run passed
generation one's install, self-host build, instruction audit, and
delivered-source audit. The orchestrator and generation-two guest
stopped during the retained rebuild without a terminal report. The
interruption receipt preserves the completed stage hashes. See
`build/native-focus-menu-psalmody-production-v1/generations128/terminal-observation.json`.

The on-demand shared ODE solver, native task queue initialization,
guarded window update, raster exports, and implicit F64 conversion
fix are integrated in the production sources. Both original
bootstrap rebuilds and the native cross-build and 386 instruction
audit pass. The full image verifies 1,537 delivered source and
documentation files and 686 inventory files. The 8 MiB KVM User
fixture passes in 50.62 seconds. Cold Strut passes physical editing,
automatic simulation, and Escape cleanup at 64 MiB. The independent
Run.HC check matches the instruction pixels and returns to fresh
console arithmetic. The 128 MiB retained rebuild is in progress.
See `build/native-ode-production-v1/qualification.json`.

The production Strut entry now has its own inventory workflow and
the paired Load.HC workflow is qualified. The scope is the observed
edit, play, exit, and continuation sequence.

Native Span passes that application's independent physical workflow
on the production ODE image with a cold loader overlay. The first
guest command includes Span's Load.HC. Mouse input dismisses the
instructions and adds a mass to the 15-mass bridge. Space starts and
stops simulation, the ODE clock stays fixed while stopped, and
Shift+Escape restores the caller and returns to fresh arithmetic.
The soundtrack adapter is present in the image. A paired recording
test is running to measure its output. See
`build/span-native-cold-v1/native64/result.json`.

The pinned original and the native Span overlay capture the same
first six soundtrack notes through the guest sound recorder. The
ONA sequence is 67, 65, 67, 65, 58, 65, and both speakers are off
after Shift+Escape. Native playback uses the Play source from
Adam/ASnd.HC with a native jiffy adapter. The first fixture used
C-based offsets and was corrected for TempleOS's A-based note map.
These checks cover pitch order and exit cleanup. A follow-up build
selects the chooser and player from files shared with original Adam.
See `build/span-soundtrack-asnd-v1/original/result.json` and
`build/span-soundtrack-asnd-v1/native64/result.json`.

Span's filename chooser and music player are now shared with original
Adam and load independently on demand on native i386. The full
production image passes both original bootstrap rebuilds, the native
cross-build and instruction audit, and the source audit for 1,542
delivered files and all 686 inventory files. At 64 MiB, cold Span
passes mass placement, simulation and pause, the original six-note
soundtrack prefix, speaker shutdown on exit, and the original bridge
file round trip. Strut passes its physical workflow on the same
image. The 8 MiB User fixture passes in 51.57 seconds. The retained
rebuild is running on the new image. See
`build/span-production-v1/qualification.json`.

Cold loader checks on the production Span image locate the next
application dependencies. GrModels first needs CMeshTri, Titanium
needs mp_cnt, ToTheFront needs Line, and X-Caliber needs CMass. All
four receipts verify the original application files in the image.
The GrModels record-only probe uses the original serializer, record
declarations, and size table. It matches the pinned original's
62-byte sprite exactly and returns to fresh arithmetic. Full
interactive model generation remains open. See
`build/production-span-followup-load-v1` and
`build/grmodels-ball-reference-v1`.

Original sprite declarations, matrix rotations, and the original
lighting chooser let GrModels complete its native Load.HC and return
to fresh arithmetic. Supplying only the sprite records stops at
Mat4x4RotZ, which isolates the earlier types gap. ToTheFront with
the original Line helper reaches the missing GrPlot binding.
X-Caliber with native ODE initialized reaches D3Equ after resolving
CMass. See `build/grmodels-native-matrix-v1/native64/result.json`,
`build/tothefront-line-load-v1/native64/result.json`, and
`build/xcaliber-ode-load-v1/native64/result.json`.

A Console overlay publishes the resident Line, GrPlot, GrRect3, and
matrix rotations and the original sprite record size table. The
combined image passes the instruction audit. See
`build/native-geometry-bindings-v1/combined/result.json`.

The per-symbol graphics candidate loads GrModels with its original
lighting chooser. ToTheFront reaches the missing PopUpGetI64 helper,
then moves to the multicore visibility code after loading that
original popup helper. X-Caliber's added scalar vector routines move
its loader to GrPeek. These are compile probes. See
`build/native-geometry-bindings-v1/GrModels/result.json`,
`build/tothefront-integer-prompt-v1/native64/result.json`, and
`build/xcaliber-vector-load-v1/native64/result.json`.

Both resident graphics export candidates fail the 8 MiB User fixture
with fallback-heap exhaustion. The table candidate also exposes a
native parser failure on the local indirect function declarations.
The next candidate loads the original portable geometry routines on
demand from the unchanged production Console image. See
`build/native-geometry-bindings-v1/user8/result.json` and
`build/native-geometry-table-v1/user8/result.json`.

The on-demand geometry probe compiled the original graphics routines
and integer prompt at 64 MiB using the production Span image. The
package audit confirmed that all existing files and the boot area were
preserved. ToTheFront advanced to `TTFVis.HC:146`, where the compiler
rejected `mp_cnt` in its multicore visibility code. This confirms the
loader reached the same dependency without the resident graphics
exports. The full game workflow still needs verification. See
`build/native-geometry-source-v1/ToTheFront/result.json`.

At this checkpoint, the retained 128 MiB native rebuilds for the ODE
and Span production images were both still running. Their current
receipts are under `build/native-ode-production-v1/retained128` and
`build/span-production-v1/retained128`.

A ToTheFront serial visibility probe submits the existing worker
callbacks directly over the full unit and map ranges. The probe
keeps the original visibility merge and the single-enemy range
calculation. The geometry and integer prompt still load, but the
alternate application loader is rejected before any visibility
workflow can be verified. The probe leaves the production app
sources intact. See
`build/native-geometry-source-v1/ToTheFront-serial-inline/result.json`.

Loading ToTheFront units individually advances the single-CPU probe
past the visibility unit. The original `TTFFire.HC` is the next
rejection, with a compiler exception and zero frontend errors. This
run verifies compilation of the serial unit, with no runtime
visibility comparison yet. In a separate guest, the on-demand
geometry and original lighting chooser let the unmodified GrModels
loader complete on the production Span image, and the console
displayed the result of fresh arithmetic. Full model generation
remains open. See `build/native-geometry-source-v1/ToTheFront-serial-exact`
and `build/native-geometry-source-v1/GrModels/result.json`.

The ODE production image completed the retained rebuild for all nine
modules at 128 MiB on the pinned 486 CPU. The retained source disk
SHA-256 matches the receipt. This is the retained-provider rebuild
gate. Two-generation installation and qualification remain open on
the newer Span image. See
`build/native-ode-production-v1/retained128/result.json`.

Splitting the original ToTheFront fire unit by function isolates the
compiler exception to `IndirectResolveAll`. Comparing the pending
order with `&indirect_head`, as the draw routine does, lets that
function compile. The next missing symbol is `Wrap` at
`TTFMove.HC:71`. The probe retains the original application files in
the disk image. The original `Wrap` has been added as an optional
probe input for the next run. See
`build/native-geometry-source-v1/ToTheFront-split-fire/result.json`
and `build/native-geometry-source-v1/ToTheFront-indirect-head/result.json`.

The original `Wrap` lets the ToTheFront probe compile `TTFMove.HC`.
The probe now stops at `TTFDraw.HC:18`, the first call site that
combines `GrCircle3` and `Saw`. The compiler reported an undefined
identifier without identifying the symbol. X-Caliber with on-demand
graphics, ODE and the scalar vector helpers advances past its previous
`GrPeek` failure and throws a compiler exception after an unused
`Ship` declaration warning. See
`build/native-geometry-source-v1/ToTheFront-wrap/result.json` and
`build/native-geometry-source-v1/X-Caliber/result.json`.

The GrModels probe invokes the original `BallGen` after loading the
app. The class form displayed radius 20.000, 16 longitude faces and
8 latitude rings. Escape returned to the console. This check covers
opening and leaving the form. Choosing a lighting color and comparing
the generated mesh with the original remain open. See the screenshots
and receipt in `build/native-geometry-source-v1/GrModels-ball-form`.

The Span production image also completed all nine retained module
rebuilds at 128 MiB on the pinned 486 CPU. The retained source disk
SHA-256 matches the receipt. The two-generation runner passed its
input source audit and began generation-one installation. See
`build/span-production-v1/retained128/result.json` and
`build/span-production-v1/generations128`.

The pinned original and the Span production image both show the
BallGen defaults and open the original lighting chooser after Escape.
The first native check captured the console before the chooser was
drawn. The later capture shows the matching chooser rows, columns and
swatches. Color selection and the generated mesh comparison remain
open. See `build/grmodels-ball-reference-v1/form-original` and
`build/native-geometry-source-v1/GrModels-ball-chooser`.

The BallGen workflow now exercises Escape on the default form, a
physical click on the red full-range swatch and No at the repeat
prompt. Both guests returned a red sprite with 128 triangles. The
pinned original returned 59 vertices and native returned 60. Twelve
triangles differ when compared by their vertex coordinates. The
native console still executes arithmetic after the workflow. Exact
mesh equivalence remains open. See
`build/native-geometry-source-v1/GrModels-ball-mesh/comparison.json`.

The first Span two-generation runner exited with status 143 during
generation-one installation. Its input source audit passed and its
files remain available. A fresh runner using the same retained input
and configuration is active in
`build/span-production-v1/generations128-retry`.

A 128-sample BallGen math probe records the binary64 ring and longitude
angles, the cosine results, and the coordinates before and after
integer conversion. Both guests use identical angle bits. Eighteen
cosine samples differ. The existing high-precision oracle agrees
with the original on all 128 and with native on 110. At the sampled
longitude of pi/4 the one-bit cosine difference moves a product from
above 10 to below it, so truncation produces 9 instead of 10. Seven
sampled coordinate triples differ. See
`build/grmodels-ball-reference-v1/vertex-math-comparison.json`.

The restarted Span generation run passed generation-one retained
installation and advanced to its native self-host build.

At pi/4, the public cosine in the cross-built bootstrap image is one
bit below the oracle. JIT compilation of the same source in that
guest matches the oracle. Installing the guest-rebuilt CompilerRuntime
also gives the expected public cosine and reproduces every byte of
the 128-sample vertex-math probe. The complete BallGen workflow still
returns 60 vertices against the original's 59. On the retained
installation, 36 of the 128 triangles differ by resolved vertex
coordinates. The standalone probe stores floating-point intermediates
before integer conversion. The full app passes its coordinate
expressions directly to AddVertex, so the next comparison needs to
observe that call path. See the cosine receipts under
`build/grmodels-ball-reference-v1` and
`build/native-geometry-source-v1/GrModels-ball-mesh-retained/comparison.json`.

The interactive AddVertex trace captures all 256 coordinate triples
on the pinned original and retained native image. Each traced guest
produced the same mesh as its uninstrumented run. Twenty-four calls
received different coordinates before deduplication. The first
difference is zero-based call 34, with original coordinates
(10, -9, -14) and native coordinates (10, -10, -14). See
`build/native-geometry-source-v1/GrModels-ball-trace-retained-fixed/comparison.json`.

An initial trace export requested an invalid size and filled the host
disk, which interrupted Span's generation-one acceptance screenshot.
The partial export was discarded and the trace now exports exactly
6 KiB. The new Span runner verified provenance and reused the passed
retained installation. Generation-one self-hosting is running again
under `build/span-production-v1/generations128-resume-install`.

A focused call reproduces the BallGen mismatch with the same two
binary64 operands. The original passes -9 or 9 when the product is
converted directly to an integer argument and -10 or 10 when it is
stored as binary64 first. Native passes -10 or 10 in both cases.
An independent rational model reproduces all 256 original vertex
calls with a 64-bit product significand and all 256 retained native
calls with a 53-bit significand. This isolates the remaining mesh
difference to product precision at the integer conversion boundary.
See `build/grmodels-ball-reference-v1/product-precision-comparison.json`.

A software wide multiply prototype rounds the exact binary64 operand
product to the original 64-bit significand before truncating to I64.
The guest differential passed 16 cases, including subnormal operands,
overflow, invalid inputs and both signs of the BallGen boundary.
Using the prototype at the eight coordinate expressions in the
instrumented BallGen run on the retained image reproduced all 256
original AddVertex arguments and the exact 59-vertex, 128-triangle
sprite. The compiler still needs to select this behavior for
unchanged source, and the original public entry point still needs
qualification. See `build/grmodels-ball-reference-v1/WideProduct.HC`
and `build/native-geometry-source-v1/GrModels-ball-wide-product/result.json`.

A compiler candidate recognizes a floating multiply whose parser
result already carries the integer conversion flag. It emits the
wide multiply helper directly and skips the later binary64-to-I64
conversion for that instruction. The original bootstrap compiler and
instruction audit pass. At 64 MiB the unchanged product fixture
matches the original byte for byte, including the distinct results
for direct and stored products. The candidate exhausts the fallback
heap during the original 8 MiB User fixture, so it remains an
overlay. See `build/i386-wide-product-lowering-v1`.

Span generation one passed retained installation, self-hosting,
the image audit and the delivered-source audit. Generation two has
started its retained rebuild.

The wide-product candidate now shares operand normalization and the
53-by-53-bit product with ordinary software multiplication. This
saves 1,649 bytes in CompilerRuntime and preserves the byte-exact
64 MiB conversion result. At 8 MiB, the unchanged User workload still
fails. A read-only heap census immediately before USCheck measures a
268,120-byte largest primary payload on the baseline and 264,024 on
the candidate, exactly one page smaller. User needs 267,528 bytes
after alignment. Both fallback heaps have a 2,840-byte largest
payload. The candidate remains an overlay. See the `heap-base`,
`heap-shared`, `shared-conversion64` and `shared-user8` receipts
under `build/i386-wide-product-lowering-v1`.

A second memory overlay tries the minimum requested backing batch
when low memory cannot serve it and the public pool spills to the
primary arena. It keeps the smaller late batches at the high end.
The cross-build and instruction audit pass. At the unchanged 8 MiB
USCheck boundary, primary free payload rises from 452,296 to 457,848
bytes, but the largest contiguous block stays at 264,024 bytes.
User creation still fails on the same 267,527-byte request. The
extra free space does not solve the placement constraint. See
`build/i386-wide-product-lowering-v1/heap-primary-minimum/result.json`.

Reusing small primary-heap holes for late backing batches still
fails the 8 MiB User workload. The largest contiguous payload fell
to 236,368 bytes from 264,024 with minimum batches alone. This
placement policy stays in the overlay. See
`build/i386-wide-product-lowering-v1/heap-small-holes/result.json`.

The Span generation-one self-hosted image passed the physical
64 MiB Span check, including mass placement, simulation, pause,
six soundtrack notes, speaker shutdown and return to the console.
Its unchanged 8 MiB User fixture failed the same contiguous task
allocation as the separate wide-product candidates. This independently
records a resource regression on the rebuilt generation. See
`build/span-production-v1/gen1-span64/result.json` and
`build/span-production-v1/gen1-user8/result.json`.

At the User8 allocation boundary, generation one's largest primary
payload measures 231,256 bytes against the passing bootstrap's
268,120. The generation-one ConsoleRuntime adds 25,688 bytes of
resident payload. Exchanging only that module for its bootstrap
counterpart on a diagnostic copy recovers 24,576 contiguous bytes.
The resulting 255,832-byte block still falls short of 267,528.
The boot area and every other file remain intact in the diagnostic
copy. See `build/span-production-v1/gen1-user8-growth.json`.

Original circle and ellipse walkers, 3D drawing primitives, polar
conversion and Saw compile on demand in the ToTheFront probe. The
unchanged TTFDraw unit then compiles. The final application unit
stops at the missing PopUpRangeF64 at line 3. A follow-up probe
with the original range chooser is running. See
`build/native-geometry-source-v1/ToTheFront-curves/result.json`.

The original range chooser moves the final ToTheFront compile to
`ScanChar` at line 99. A follow-up uses the original key poll over
the published message APIs. The pinned original launcher reaches the
GameSeed prompt. In a separate deterministic workload, the original
multicore and native serial visibility workers return twelve identical
values. They agree on the visible neighbor, the unit behind a mountain,
763 visible cells, visibility after clearing the obstruction, and the
death update. Native still executes arithmetic after the probe.
The complete interactive match remains open. See
`build/tothefront-original-v1/visibility-zeroed/result.json` and
`build/native-geometry-source-v1/ToTheFront-visibility-zeroed/result.json`.

The original key poll advances ToTheFront to its task settings
dependency. Loading the shared settings and autocomplete services
used by Span lets the final game unit compile, and fresh console
arithmetic succeeds. This loader still uses the serial visibility
and queue-head probe changes.

The pinned original starts a fixed-seed match with two Human players,
draws the map, advances to the other artillery phase on Space and
returns on Escape. The same physical keyboard workflow is running
against the native loader. See
`build/tothefront-original-v1/human-match` and
`build/native-geometry-source-v1/ToTheFront-task-settings/result.json`.

The native Human match probe accepts the fixed seed, selects both
Human players, draws the start map, advances on Space and returns
on Escape. The console then executes fresh arithmetic. Both captured
phase headers read Artillery because the first advance changes
players within the artillery phase. Framebuffer captures differ
in unit and overlay pixels. The workflow remains a probe of the
patched loader, with full gameplay and exact rendering still open.
A second probe compiles the same dependencies through a single app
directory include and returns to a working prompt. See
`build/native-geometry-source-v1/ToTheFront-human-match` and
`build/native-geometry-source-v1/ToTheFront-combined/result.json`.

Span's generation-two retained rebuild and installation passed.
The generation-two native self-host check is running.

A source-only ToTheFront candidate preserves the original Run.HC
launcher and the original multicore visibility path. Native selects
the serial workers and loads its graphics, popup, key polling and
task settings dependencies when the app starts. The queue sentinel
uses its address on both paths. At 64 MiB, the normal Run.HC entry
opens the fixed-seed Human match, draws the map and exits back to
fresh arithmetic. The same image passes the unchanged 8 MiB User
check in 50.73 seconds. The image kept the original boot area and all
unrelated files. The shared-source refactor, full game workflows
and exact rendering remain open. See
`build/tothefront-normal-entry-v1/match64/result.json` and
`build/tothefront-normal-entry-v1/user8/result.json`.

The ToTheFront source overlay now extracts the original geometry,
sound, popup and key-poll bodies into shared includes. The native
launcher uses those includes on demand, and the original paths use
the same bodies at their existing call sites. The fixed-seed Human
workflow returns on both the original-kernel overlay and the native
Run.HC path. Native also passes the unchanged 8 MiB User check in
51.00 seconds. The refactor remains in a source overlay while the
in-flight Span generation check verifies its pinned sources. See
`build/tothefront-shared-entry-v1/original/result.json`,
`build/tothefront-shared-entry-v1/native64/result.json` and
`build/tothefront-shared-entry-v1/user8/result.json`.

The shared ToTheFront loader and helpers are integrated in the
production source tree. Both original bootstrap rebuilds and the
native cross-build and instruction audit pass. The delivered source
audit covers 1,554 files and the build checks all 686 pinned
inventory entries. The new production image passes the normal
64 MiB fixed-seed Human launcher and the unchanged 8 MiB User
fixture in 50.69 seconds. Full game workflows and exact rendering
remain open. See `build/tothefront-production-v1/qualification.json`.

On the preceding Span production image, both native generations
rebuilt, installed and booted. Sixteen modules and their artifacts
match within the declared eight-byte Kernel date exception. Both
generations pass the physical Span workflow and fail User8 at the
contiguous task allocation. This closes the two-generation
artifact check for that image. The resource gate and full
compatibility suite remain open. See
`build/span-production-v1/generations128-resume-install/checkpoint.json`.

The pinned original and the current ToTheFront production image
match through all six phases of a fixed-seed Human turn and the
start of turn two. Physical Space advances each phase. The observer
records the turn, phase, active player and both live unit counts
after the corresponding phase label is published. Both preserve
32 units per side and exit on Escape. Native returns to fresh
arithmetic. Unit movement, firing orders, and exact framebuffer
equivalence remain open. See
`build/tothefront-original-v1/phases-original-labeled/result.json`
and `build/tothefront-production-v1/phases64-labeled/result.json`.

The fixed-seed ToTheFront comparison now selects an infantry unit
and physically drags it to a legal adjacent hex during the first
movement phase. Both guests report unit 16 at row 30, column 1,
with two movement points remaining. Both finish the same phase
sequence and exit. Native returns to fresh arithmetic. Firing,
overrun and exact rendering remain open. See
`build/tothefront-original-v1/move-original-positive/result.json`
and `build/tothefront-production-v1/move64-positive/result.json`.

The direct-fire differential stages one defender in an empty,
visible hex adjacent to attacker 0 during the first firing phase.
The original seed alone has no legal direct-fire pair. Physical
dragging on the pinned original marks attacker 0 fired, reduces
defender 0 from 100 life to zero, and updates the opposing live
count to 31. Native selects the same coordinates and displays the
range circle but times out waiting for the shot to finish. This
localizes the remaining gap to native direct-fire interaction.
See `build/tothefront-original-v1/fire-original-adjacent/result.json`
and `build/tothefront-production-v1/fire64-adjacent/result.json`.

The native direct-fire trace confirms that selecting the attacker
completes visibility calculation, delivers the mouse release, and
enters UnitDirectFire. The hit branch returns from Noise and remains
inside the following Sleep. A separate native console fixture returns
from a plain Sleep(250), then stalls in Sleep(250) after starting
Noise(250,34,41). This shows the same failure without app input,
rendering or shot calculations. The noise-task interaction remains
open. See `build/tothefront-production-v1/fire64-shot-trace/result.json`
and `build/tothefront-production-v1/noise-sleep64/result.json`.

The native noise-stall capture samples the timer at 17,130 jiffies
three times over one second. The running FS base identifies the
spawned noise task. The sampled instruction addresses map to Snd's
speaker-port I/O, and the timer does not advance. In a separate
run of the same disk and fixture with KVM and QEMU's userspace IRQ
chip, Sleep returns after exactly 250 jiffies while Noise is active.
The complete ToTheFront direct-fire comparison is now running in
that configuration. The default in-kernel IRQ-chip case remains
open. See `build/tothefront-production-v1/noise-stall-samples/result.json`
and `build/tothefront-production-v1/noise-userspace-irqchip/result.json`.

The native ToTheFront shot completes with QEMU's userspace IRQ chip.
The staged adjacent shot matches the pinned original on the hit,
defender life falling from 100 to zero, opposing live count falling
to 31, and the phase trace through turn two. The default IRQ-chip
failure remains open. A single speaker note and a 250-jiffy sleep
pass under the default KVM configuration. The repeated Noise
workload also passes with the split IRQ-chip configuration.
See `build/tothefront-production-v1/fire64-userspace-irqchip/result.json`,
`build/tothefront-production-v1/noise-single-note/result.json` and
`build/tothefront-production-v1/noise-split-irqchip/result.json`.

The current production image passes the established Noise/Sweep
lifecycle and cleanup contract under default KVM. It also passes
sixteen alternating speaker writes from the caller and fixed-note
Noise at note 34. The varying-note Noise worker at notes 34 through
40 still freezes the timer when the caller polls in 5 ms sleeps.
In three frozen samples, the primary PIC had IRQ0 unmasked with no
pending or in-service request. This confines the reproduction to
the varying-note worker in the default IRQ configuration. See the
`sound-effects-managed64`, `noise-note-burst`, `noise-fixed-low`
and `noise-poll-parent` receipts under `build/tothefront-production-v1`.

A spawned control worker completes sixteen alternating speaker
writes with a 15 ms sleep between writes under default KVM. Its
parent resumes after 400 jiffies and executes fresh arithmetic.
The varying-note Noise fixture still freezes the timer under
default KVM with `kvm-pit.lost_tick_policy=discard`. These results
rule out task spawning, alternating writes at that cadence and
the default lost-tick policy as sufficient causes on this host.
The exact trigger remains open. See
`build/tothefront-production-v1/noise-worker-burst400/result.json`
and `build/tothefront-production-v1/noise-discard-lost-ticks/result.json`.

Tracing the real Noise worker found an existing time-unit mismatch.
Each nominal millisecond pause was compared with a seconds deadline
and replaced with at most 0.25 seconds, which was then passed as
zero milliseconds. The default IRQ-chip trace freezes at one
jiffy value during this loop. The shared Noise and Sweep paths now
convert the remaining duration to milliseconds and round a positive
pause up before Sleep. The first build attempt used the wrong
integer rounding helper. The verified source uses Ceil on F64.

The rebuilt ConsoleRuntime overlay with those exact source bytes
passes the standalone Noise timer check and the full staged
ToTheFront direct-fire comparison under default KVM. The shot and
phase trace match the original oracle. The same image passes User8
in 50.85 seconds. Full-image and retained-generation qualification
for the timing change remain open. See
`build/native-noise-worker-trace-v1/delay-fire64/result.json`
and `build/native-noise-worker-trace-v1/delay-user8/result.json`.

A fresh production image with the sound-effect timing correction
passes both original bootstrap rebuilds and the native cross-build
and instruction audit. Its source audit covers 1,554 files and the
build checks all 686 inventory entries. Under default KVM, the
Noise/Sweep lifecycle, ToTheFront direct-fire differential, Span
physical workflow and unchanged User8 all pass. The new image's
128 MiB retained rebuild is running. See
`build/sound-delay-production-v1/qualification.json`.

A physical artillery drag in the fixed-seed Human match queues unit 30
to row 0, column 3 on both the pinned original and the current native
production image under default KVM. The order resolves at the same
hex and the queue empties. The seven affected hexes contain no units,
and the phase traces match through the start of turn two. The native
guest exits to fresh arithmetic. Artillery damage, overrun, exact
rendering and a complete match remain open. See
`build/tothefront-original-v1/indirect-original/result.json` and
`build/sound-delay-production-v1/indirect64/result.json`.

The occupied-hex artillery comparison places one unarmored defender
in the previously empty impact hex before the physical drag. The
pinned original and the current native production image under default
KVM both reduce defender 16 from 100 life to zero and report 31 live
opponents at the start of turn two. The impact, queue and phase traces
match, and the native guest exits to fresh arithmetic. The fixture
covers one direct artillery impact against an unarmored unit.
See `build/tothefront-original-v1/indirect-damage-original/result.json`
and `build/sound-delay-production-v1/indirect-damage64/result.json`.

The overrun comparison stages enemy infantry on an adjacent plains hex
and physically drags an armored unit onto it during the first movement
phase. The pinned original and native production image under default KVM
both kill defender 16, leave attacker 0 at 100 life, and place it at
row 26, column 1 with zero movement remaining. The phase traces match
through the start of turn two and native exits to fresh arithmetic.
This fixture covers a successful overrun on plains. Failed overruns,
close assault, exact rendering and a complete match remain open.
See `build/tothefront-original-v1/overrun-original/result.json`
and `build/sound-delay-production-v1/overrun64/result.json`.

The close-assault comparison stages an armored defender on adjacent
plains and physically drags infantry onto it during the first movement
phase. Both guests kill defender 0 and place attacker 16 at row 32,
column 1 at full life and zero remaining movement. The phase trace
matches through the start of turn two, and the native production
guest exits to fresh arithmetic under default KVM. The shared
fixture also reproduces the earlier original overrun result.
See `build/tothefront-original-v1/close-assault-original/result.json`
and `build/sound-delay-production-v1/close-assault64/result.json`.

The fixed-seed map comparison exports the offscreen terrain raster
when the first Human artillery phase is published. All 296,960 bytes
match the pinned original on the native production image. The terrain,
river and road arrays also match across all 874 hexes. The composed
screenshots still differ, including pixels below the original system
status line. Time-dependent overlays and full framebuffer parity remain
open. See `build/sound-delay-production-v1/map64/comparison.json` and
`build/tothefront-original-v1/compare_map.py`.

The match-ending test stages a single adjacent enemy during the
first firing phase. The ordinary mouse drag kills that defender,
and the game publishes its Game Over message with live counts
32 and zero on both the pinned original and native production image.
Pressing Enter and reusing the seed restarts turn one with both
32-unit forces restored. The native guest exits with Escape and
executes fresh arithmetic. The fixture covers the match-ending
transition and restart from a staged state. See
`build/tothefront-original-v1/game-over-original/result.json`
and `build/sound-delay-production-v1/game-over64/result.json`.

The SimpleAI differential selects the bundled computer player through
the normal player menu. With seed 12345678, both guests move all 32
units during the first computer movement phase and return control to
the human player. The initial positions, life and movement points
match for every unit. After movement, units 0 and 9 differ in position
and remaining movement. The other 30 unit states match. The native
guest exits and executes fresh arithmetic. See
`build/sound-delay-production-v1/simple-ai64/comparison.json`.

The SimpleAI trace reproduces the first-movement discrepancy and
localizes it to nearest-target selection. Both guests make the same
two signed random draws in the same order, both for unit 3. Units
0 and 9 start on row 28 and choose between defenders in column 12,
six rows above and below. The pinned original chooses defender 10
on row 22. Native chooses defender 11 on row 34. The other 30 target
choices match. The two candidate positions are symmetric in the hex
grid. The exact floating-point step that changes the comparison
remains open. See
`build/sound-delay-production-v1/simple-ai-target64/target-comparison.json`.

The distance trace measures the stored coordinates and squared
distances for both symmetric target pairs. The original rounds the
two squared distances to identical binary64 values. Native rounds
the lower target one binary64 step closer in both cases. The original
vertical coordinate spacing reproduces all three captured original row
centers in a host calculation. Using that spacing in the native center
initializer on an experimental disk makes all 32 first-movement states
match the original. The map raster regression is running against the
experimental disk. Broader seed coverage remains open. See
`build/sound-delay-production-v1/simple-ai-distance64/distance-comparison.json`
and `build/sound-delay-production-v1/simple-ai-center-candidate64/comparison.json`.

The shared ToTheFront source now uses the original binary64
vertical spacing for the default native hex size. On a disk
repacked with those exact source bytes, all 32 SimpleAI movement
states and the complete map raster and map arrays match the pinned
original at seed 12345678. The one-line experimental disk also
matches all 32 movement states at seed 27182818. A fresh full
production build, additional seeds and full-match parity remain open.
See `build/sound-delay-production-v1/simple-ai-center-shared64/comparison.json`,
`build/sound-delay-production-v1/map-center-shared64/comparison.json`
and `build/sound-delay-production-v1/simple-ai-center-second-seed64/comparison.json`.

The sound-timing production image completes all nine retained
module rebuilds and their persisted export checks at 128 MiB. The
two-generation qualification is running with that image as input.
See `build/sound-delay-production-v1/retained128/result.json`.

A fresh full image containing the shared vertical spacing change
passes the 386 instruction audit and the unchanged 8 MiB User startup
in 51.09 seconds. The first SimpleAI movement phase and complete
offscreen map raster match the pinned original on this image.
The build reuses the two verified original bootstrap generations.
The build receipt records concurrent changes to local cleanup records.
The core source audit verifies 1,554 files and the separate inventory
audit verifies all 686 bundled files against revision 35db7c90.
See `build/tothefront-center-production-v1/qualification.json`.

The bundled-file audit also verifies the preceding sound-timing image,
its retained build image and its generation-one installed candidate
against their source revision. Checking the preceding image against
the new revision detects the single changed ToTheFront initializer.
Generation one's native self-build is running.
See `build/i386-bundled-source-audit-v1/gen1-install.json`
and `build/i386-bundled-source-audit-v1/pre-fix.json`.

The sound-timing generation-one installation reproduces the 8 MiB
User allocation failure with the cross-built flat kernel and native
retained providers. The paired heap probe measures a largest primary
payload of 268,120 bytes on the cross-built image and 239,448 on the
native-retained image. The same User creation needs 267,528 aligned
bytes. Both images have 242 free primary blocks and identical
fallback space. The probe therefore localizes the failure to the
retained-provider installation before the native flat-kernel rebuild.

The installed retained modules add 29,256 payload bytes in total.
ConsoleRuntime accounts for 25,688 bytes of that growth. Its declared
data ranges grow by six bytes, and the module also carries a larger
disk relocation table. The compiler retains its existing division
template export difference. See
`build/i386-resident-growth-v1/modules.json` and
`build/i386-resident-growth-v1/user8.json`.

Generation one of the sound-timing image rebuilt, installed and
booted all sixteen modules. The core and bundled audits verify
1,554 and 686 files respectively. The physical Span workflow
passes at 64 MiB. The unchanged User check at 8 MiB fails during
task creation with OutMem. Generation two's retained rebuild is
running. See `build/sound-delay-production-v1/gen1-span64/result.json`,
`build/sound-delay-production-v1/gen1-user8/result.json` and
`build/i386-bundled-source-audit-v1/gen1-selfhost.json`.

Two live 8 KiB backing regions separate the two largest free blocks
in the paired retained-install heap snapshots. An overlay that doubles
late primary backing batches to 16 KiB when space permits raises total
free payload by 1,232 bytes on the fully native generation-one image,
while reducing the largest block from 231,256 to 229,072 bytes.
Both runs reject the same User task allocation. The batching experiment
remains outside production. See
`build/i386-resident-growth-v1/separators.json` and
`build/i386-primary-backing-batch-v1/double-user8/result.json`.

The generation-one heap trace finds both separating 8 KiB backing
regions fully occupied in the root task before any User fixture
command. Their ownership, page counts and the 231,256-byte largest
free block stay identical through all three setup commands. This
rules out the test's header and fixture loads as the cause of this
fragmentation. See
`build/i386-resident-growth-v1/gen1-user-trace/result.json`.

A separate overlay reduces cached small allocations from sixteen
pages per public-heap batch to eight, while retaining the existing
backing policy. It increases total free primary payload by 8,584 bytes
and the largest block by 248 bytes. The unchanged 8 MiB User test
still rejects the same allocation. The overlay stays experimental.
See `build/i386-primary-backing-batch-v1/small-public-user8/result.json`
and `build/i386-primary-backing-batch-v1/small-public-stock-user8/result.json`.

The pinned original X-Caliber reference dismisses the solar-storm
prompt with the mouse, starts level one with four enemies and zero
score, fires the gun with Space, and returns on Escape. The ordinary
native loader on the current full image reproduces the compiler
exception. Compiling source sections with the original DolDoc binary
records attached allows the draw routine to compile and isolates
the next exception to the standalone Explosion routine. A diagnostic
using Sqr in its denominator is running. See
`build/xcaliber-reference-v1/original-click/result.json` and
`build/native-geometry-source-v1/X-Caliber-split-draw/result.json`.

The isolated HolyC power test executes a square, cube, fractional
exponent and negative exponent on the pinned original. The native
compiler rejects the fixture before execution. In particular, a
dynamic base of 3 with literal exponent 2 returns one binary64 step
below 9 on the original. The Sqr substitution bypasses the compiler
exception in X-Caliber's Explosion routine and exposes a later
diagnostic at Freq2Ona. The substitution is a compile diagnostic.
Exact power behavior remains open. See
`build/i386-power-operator-v1/original/result.json`,
`build/i386-power-operator-v1/native64/result.json` and
`build/native-geometry-source-v1/X-Caliber-explosion-square/result.json`.

With the original Freq2Ona body loaded on demand, the diagnostic
X-Caliber build compiles its firing and initialization section. It
then reaches the main routine and rejects the SettingsPush call.
A probe that loads the original desktop helpers before that routine
is running. See
`build/native-geometry-source-v1/X-Caliber-frequency/result.json`.

Loading the original task settings, autocomplete and key-poll helpers
lets the diagnostic X-Caliber build compile its main routine. The
shared physical workflow then reaches the same level-one state as
the pinned original and observes the gun reload transition after Space.
The native run times out waiting for return after Escape. A trace of
the real key loop and ODE teardown is running. This diagnostic still
uses the Sqr substitution. See
`build/native-geometry-source-v1/X-Caliber-desktop/result.json`,
`build/native-geometry-source-v1/X-Caliber-play/result.json` and
`build/xcaliber-reference-v1/original-shared-workflow/result.json`.

The original input trace receives Escape and completes teardown
after firing. The two native control runs use identical packaged
sources. With no shot, native receives both Escape events, completes
teardown, and executes fresh arithmetic. After firing, native still
receives both Escape events but never reaches the teardown marker.
A finer trace of the simulation and refresh calls is running.
See `build/xcaliber-reference-v1/original-input-trace/result.json`,
`build/native-geometry-source-v1/X-Caliber-input-trace/result.json`
and `build/native-geometry-source-v1/X-Caliber-no-fire/result.json`.

After firing and receiving Escape, native X-Caliber completes its
AI, solar flare, expiry and damage calls. It enters Refresh and
does not reach the following marker. The pinned original returns
from Refresh, exits the loop and completes teardown. QMP timer and
window-manager counter sampling, plus a userspace IRQ-chip control,
are running. See `build/native-geometry-source-v1/X-Caliber-loop-trace/result.json`
and `build/xcaliber-reference-v1/original-loop-trace/result.json`.

Generation two of the sound-timing image completes the nine
retained rebuilds and installs them. Both stage images preserve all
686 bundled files against the sound-timing revision. The native
flat-kernel self-build is running. See
`build/i386-bundled-source-audit-v1/gen2-retained.json`
and `build/i386-bundled-source-audit-v1/gen2-install.json`.
