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
