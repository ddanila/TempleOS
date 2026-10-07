# Original macro playback contract for the i386 port

The earlier integrated ABI 47 candidate recorded key messages and copied their
payloads but lacked original serialization and playback services. The current
console-v44 prototype restores them through shared original cores and native
executable input filters. The selected evidence below qualifies individual
behaviors; complete playback and release qualification remain open. Recording
and manual public `PostMsg` replay alone do not establish macro playback.

The original `SysMacro2Str` converts eligible character key-downs into quoted
HolyC text statements. Other events become `Msg(code,arg1,arg2);` statements.
It uses `char_bmp_macro` from `Kernel/CharBitmaps.HC`; quotation, dollar signs,
control characters and grouping must match the original output byte for byte.
Conversion clears the recording semaphore and preserves the recorded ring.

`PlaySysMacro(n=1)` captures the focused task and validates it. Playback disables
recording, serializes the ring, and executes the generated InFile code. A self
recipient uses `InStr`; another recipient uses `XTalkStrWait`, waiting between
iterations. The temporary serialization is freed. Missing/retired recipients,
repeat counts, cancellation, task focus and allocator failures need explicit
coverage. Recorded arrival times must not survive into replayed keys.

The port's `NativeXTalk` queues raw characters. It cannot replace the
original executable InFile path without changing behavior. The native executable input-filter path now provides
`InStr` and `XTalkStrWait`; their qualification must preserve the
original public signatures, task ownership, priority and wait behavior. Retain
shared original macro serialization code where practical. Keep private timing
metadata outside public `CJob` layout.

Automated acceptance requires:

- Installed guest availability of `SysMacro2Str`, `PlaySysMacro`, `InStr` and
  `XTalkStrWait`, including ordinary function symbols rather than export-only
  lookups.
- Independent original-x64 and native serialization oracles for empty, character,
  quoted/backslash/dollar/control and mixed-message rings; exact bytes and ring
  preservation.
- Actual self and child playback through executable InFile code, including
  positive repetition, nonpositive counts, focus selection, and recipient exit.
- Editor insertion and undo grouping from actual replay, with no reuse of
  recorded arrival timestamps, and a working subsequent interactive command.
- Error/interruption/allocation cleanup with exact task/root heap recovery and
  no leftover recording semaphore, queued job, wait or task ownership reference.
- Fresh integrated build, native generations and packaged workflow qualification
  after changing OS source. Existing ABI 47 evidence remains tied to its source.

`tools/test-i386-macro-playback.py` checks API prerequisites only. Behavioral
qualification is provided by the separate self, child, allocation, focus,
retired-recipient and editor fixtures; API availability alone proves no playback.

## Executable text path identified (2026-10-06)

`Compiler/PrsExpressionCore.HC::PrsFunCallCore` resolves quoted statement
syntax through the ordinary `Print` function symbol. Original
`Kernel/StrPrint.HC::Print` formats with `StrPrintJoin`, calls `PutS`, and frees
the buffer. `Kernel/KeyDev.HC::KDInputFilterPutS` turns those bytes into
`Msg(MSG_KEY_DOWN,ch,0)` when the executing task has
`TASKf_INPUT_FILTER_TASK`; the existing native `MemoryPostMsgCore` already
routes messages from a filter task to its preceding recipient with
`JOBf_DONT_FILTER`.

Consequently the missing path needs native Print output dispatch, executable
text jobs on a correctly linked input-filter task, and the original public
InStr/XTalkStrWait services. Executing serialized source on an ordinary console
task would print its characters rather than feed the recipient. Sending the
serialized source through NativeXTalk would type HolyC syntax rather than
execute it. Neither satisfies the original contract.

`tools/test-i386-input-filter-prerequisites.py` checks ordinary symbols together
as a bitmask: Print=1, InStr=2, XTalkStrWait=4, expected 7. It checks availability
only; a passing mask must be followed by actual source execution, routing,
wait, lifetime and cleanup tests. Its first run uses the cleanup-v1 image and
preserves evidence in `build/input-filter-prerequisites-red-v1`.

The console-version-42 output prototype now passes the unchanged quoted/public
output regression and a separate synthetic self-linked filter routing check
at 486,-fpu / 8 MiB. Evidence is `build/console-print-green-v1/result.json`
(5 commands) and `build/console-output-routing-v1/result.json` (10 commands).
Both require exact VGA checkpoints; the routing check also requires two consumed
key messages and exact task heap recovery. This proves an output branch only;
real filter-task linking, executable text jobs, waiting and retirement remain
unimplemented and must be qualified before claiming playback.

## Current native playback evidence (2026-10-06)

Console version 44 on `build/macro-playback-native-v1/kernel.img` implements
the shared original playback loop. Selected terminal passing reports are:

- `build/macro-playback-self-v1/result.json`: 17 commands, counts 0/1/3,
  ten extra cycles, exact caller heap, preserved ring and recording disabled.
- `build/macro-playback-child-v1/result.json`: 23 commands, independent child
  receipt, repeats, filter links and caller heap recovery.
- `build/macro-playback-focus-v1/result.json`: 25 commands; a change in global
  focus during receipt does not redirect the captured playback recipient.
- `build/macro-playback-retired-v1/result.json`: 18 commands; null and retired
  focus return before disabling recording, matching original behavior.
- `build/macro-playback-recipient-exit-v1/result.json`: 21 commands; recipient
  exit bounds positive and negative repeat loops. This is not external cancellation.
- `build/macro-playback-allocation-job-v1/result.json` and
  `build/macro-playback-allocation-context-v1/result.json`: 18 commands each;
  selected CAlloc failures recover caller heap, ring and filter state.

Editor v1 passed its VGA insertion and two undo checkpoints, then failed an
incorrect fixture assumption that DocSize measures text length. Editor v2
replaced that with entry traversal but compared the full color-bearing type
field, causing its worker to wait indefinitely. Both failed fixture snapshots
are retained alongside their reports. Editor v3 uses type_u8, as original
DolDoc does, and passes all 17 commands on the unchanged v44 image. Exact VGA proves xAB,
one undo to x, and a second undo to empty. Worker retirement, empty text,
unchanged stored timestamps and continued console use also pass.

Queued cancellation passes 13 commands in
`build/macro-playback-cancel-queued-v1/result.json`: actual playback filter is
killed before entry, with exact caller heap, restored links/flags, preserved
ring, recording disabled and continued console use.

Active cancellation at the Msg checkpoint passes 21 commands in
`build/macro-playback-cancel-active-v4/result.json`. Caller keyboard messages
are drained before/after measurement; exact caller and root heaps recover,
filter links/flags and patched service bytes restore, ring survives and the
console continues. The v5 report passes 23 commands, including ten additional
cycles with every invariant checked each time. This covers one checkpoint.

Interruption between repeats passes 23 commands in
`build/macro-playback-interrupt-v1/result.json`: Break propagates at the second
repeat wait, exactly one first AB repeat subsequently completes, no second
repeat is queued, IRQ/Yield entry restore and caller/root heaps recover exactly
after keyboard queue drainage. Already queued work is explicitly drained; this
is not atomic cancellation of all jobs.

Other active cancellation sites, complete resource recovery, original-system playback
oracle coverage, and fresh integrated native generations/package qualification
remain open. Earlier broad release reports do not qualify this source epoch.

## Repeatable qualification command

`tools/qualify-i386-macro-playback.py` runs 16 selected cases on independent
writable copies of one pinned disk: public/input prerequisites, basic and
original-byte serialization, self/child/repeat/focus/retirement behavior, editor
undo, queued/active cancellation, repeat-wait interruption, and two selected
allocation failures. It pins the disk, original serialization export, driver,
fixtures, shared helpers and expected font source, checks them before/after each stage, and records
each passing child report with its hash. It requires each child to report a
passing 486,-fpu / 8 MiB runtime against the pinned disk.

Run it against the eventual audited installed or packaged image, for example:

```sh
python3 tools/qualify-i386-macro-playback.py IMAGE.img \
  --repository . \
  --original build/macro-core-original-v7/MacroExtended.HC \
  --out build/macro-playback-installed-qualification-v1
```

This does not establish native image origin, complete OS qualification or
release readiness. Those need their separate generation, image audit and
package evidence. The original export must remain independently obtained;
never regenerate it from the native implementation.

Host driver validation in `build/macro-qualification-driver-gates-v1/result.json`
uses synthetic child reports to check successful orchestration, wrong-CPU
rejection and changed-image rejection. It is not guest macro qualification.
The real combined run remains pending while native image qualification runs.

Mixed-event playback passes 23 commands in
`build/macro-playback-mixed-v1/result.json`: the child independently consumes
all message types and requires ordered character A (key-down/scan zero),
non-character arrow (key-down/character zero/scan 0xC8), then A key-up/scan
0x1E. Counts 0/1/3 plus ten cycles pass, with original ring payloads preserved,
recording disabled, restored child filter state, exact caller heap and retired
child at cleanup. This verifies executable serialized Msg statements as well
as quoted text, not only serialization bytes. The aggregate now includes this
case and pins the font source used by expected VGA rendering. Use the current
fixture repository for the aggregate; the older frozen source snapshot predates
this newly added fixture and remains unchanged for native qualification.

## Original interactive macro utility remains required

Callable playback does not restore the original editor macro workflow. Original
`Adam/DolDoc/DocPutKey.HC` handles F2 via EdMacroUtil and Shift-F2 by closing
an active macro popup, stripping the shortcut from the recording, and invoking
PlaySysMacro. Native DocPutKey currently delegates to DocBasicEditCore, while
its editor session has F1/F5 handlers but no F2 macro path.

`tools/test-i386-macro-ui-prerequisites.py` requires ordinary EdMacroUtil,
PopUpMacroMenu and EdInsCapturedMacro symbols (mask 1/2/4). This is an API
prerequisite only; its eventual pass cannot establish a usable macro utility.
The existing sixteen-case callable-playback aggregate remains selected coverage
and does not substitute for this missing interactive path.

The next implementation must preserve these original concepts and test them:

- F2 opens the macro utility with name and repeat-count fields plus RECORD,
  INSERT, PLAY, REPEAT N, STOP and CANCEL actions. Obtain original-x64 behavior
  evidence before defining exact field/action acceptance. Preserve the original
  APIs and document/form semantics rather than replacing this with a command menu.
- RECORD clears the previous ring and enables recording; STOP disables it.
  Utility task input must be excluded from recording as in the original.
- PLAY and REPEAT N use the restored executable playback services and captured
  focus. Shift-F2 excludes its shortcut from the recorded macro and handles an
  active utility popup as original DocPutKey does.
- INSERT creates the original DolDoc macro entry with the captured name/source.
  Save/reopen and original TempleOS exchange must preserve its semantics.
- Exact VGA/key/mouse scripts cover these flows without requiring a human for
  routine acceptance. Cancel/exception/allocation tests require popup and focus
  restoration, no residual task/job ownership, and exact heap recovery.
- Repeat the new flows on the final installed/package image with fresh native
  generation and release evidence after OS source changes.

The current frozen native rebuild remains useful for console-v44 qualification,
but cannot qualify a later macro utility implementation or the whole final OS.

### Original form-construction oracle

`tools/test-i386-original-macro-menu.py` executes original PopUpMacroMenu
in x64 TempleOS and interposes DocMenu only to capture the constructed form
without waiting for a chooser. The v4 report in `build/original-macro-menu-v4`
passes original form flags, popup task handoff, one menu call returning PLAY,
restored function entry and cleared popup/macro task ownership. It exports
`original/OriginalMacroMenu.DD` (254 bytes) and records both bound fields in
observation.json. Original saved documents omit data widgets; their field
tags/formats/raw types/flags/lengths are captured separately rather than inferred
from the saved action document. The default tags are Name:Test_ and Repeat N:1_.

Versions v1/v2 failed because the fixture did not initialize its call counter;
v2 diagnostics showed correct ownership/form flags and an uninitialized count.
The corrected fixture explicitly initializes counters/state before patching.
Their source snapshots/reports remain preserved. This oracle does not qualify
chooser interaction, F2 hardware delivery, macro field editing or the native UI.
Native form support must include DocPrint, DocDataFmt and DocMenu; those are
currently absent and are dependencies of the original utility implementation.

### Functional form-construction test before the port

`tools/test-i386-doc-form-construction.py` requires DocPrint/DocDataFmt/DocMenu,
then constructs original DA name/repeat fields and a BT PLAY action, binds
actual storage, checks formatted tags and field/action metadata, refreshes
changed values, deletes the document and verifies continued console use.
`build/doc-form-construction-red-v1` fails at API mask 0 rather than expected 7;
the original saved frame confirms this. It does not yet execute the behavioral
assertions in the native guest.

The behavioral fixture is independently validated by
`build/original-doc-form-construction-v5/result.json` in original x64 TempleOS.
Earlier original fixture versions are preserved: v1 incorrectly wrapped a
multi-statement console command inside one condition; v2/v3 exposed a name
buffer initialization assumption. The corrected fixture uses explicit StrCpy
and separately executes setup statements before asserting their final value.
An intermediate v4 launch followed a failed fixture generator and is invalid
as test evidence. These are fixture corrections, not native implementation fixes.

Original DocPutS calls PrsDollarCmd, which uses CmpCtrlNew, Lex and expression
evaluation. The native saved-document loader only parses its existing subset;
it cannot replace this general command parser for bound forms. Restore/share
the original parsing and formatting path, then implement chooser behavior and
its resource tests before closing the interactive macro utility gate.

The original flag and dollar-command parser bodies are now shared in
DocDollarFlagsCore.HC and DocDollarParseCore.HC, included by DocPlain.HC at
the original positions. Exact extraction, original form behavior and original
macro construction/ownership pass after extraction, with byte-identical saved
action document (`build/doc-dollar-core-extraction-v1/runtime-result.json`).
These shared cores are not yet bound into the native runtime.

### DolDoc parser adapter work (2026-10-06)

The original macro-menu oracle now pins DocPlain, both extracted dollar parser
cores, LexLib and PrsExp as well as the form/macro sources and runner.
`build/original-macro-menu-parser-pins-v1/result.json` passes: the two bound
fields retain their original flags, lengths and formats; PLAY returns 2; popup
and macro task ownership clear after return. The chooser remains interposed,
so this evidence does not qualify input interaction or native form support.

The native compiler already exposes the needed expression callbacks through
`CPrsSymbolServices.declarations`: `evaluate` returns the raw expression value;
`types.integer_expression` performs integer conversion, including F64. Use
these distinct callbacks for LexExpression and LexExpressionI64 rather than
introducing an integer-only DolDoc grammar. No service ABI expansion is needed
merely to reach these existing callbacks.

Before wiring the shared parser, add native tests for nested document parsing
from an executing HolyC command, task symbol lookup (including STR_LEN),
floating-point-to-integer conversion, adjacent string literals, and cleanup
following malformed expressions or allocation failure. Compiler control creation
and entry reject a task marked compiler_busy; confirm the actual executing
command state and preserve the control stack, cleanup callback and task lifetime
references. Do not bypass ownership by creating an untracked control.

Implement adapters for control creation/deletion, token advancement, extended
strings and both expression modes, then bind the shared dollar parser. Follow
with original DocPutS/DocPrint and bound field formatting before the existing
form-construction test can become green. DocMenu interaction and macro utility
entry/exit remain subsequent required work. The frozen v44 retained build does
not contain these parser changes and cannot qualify them.

### DolDoc expression contract before native adapters (2026-10-06)

`tests/guest/i386-doc-dollar/Contract.HC` is one shared behavioral fixture for
original TempleOS and the native port. `tools/test-i386-doc-dollar-parser.py`
runs it inside an executing HolyC function, checking six independent bits:
operator precedence; DA length using STR_LEN; FG integer conversion from 3.75;
adjacent string literals with a task global; raw F64 bits for LE=1.5; and a
HolyC function call in the action expression. Unlinked parser entries get their
own initialized queues before deletion; the temporary document is deleted.

`build/doc-dollar-parser-original-v1/result.json` passes all six (mask 63).
This validates the original semantics independently rather than guessing what
the native implementation ought to return. The native runner first requires
PrsDollarCmd, then submits the same fixture and requires mask 63 plus continued
console arithmetic. This is the next parser gate, followed by malformed-input,
allocation failure and control-stack/heap restoration tests. The six-bit test
alone does not prove cleanup on exceptions, form interaction or full DolDoc.

The native baseline `build/doc-dollar-parser-native-red-v1/result.json` fails
at the PrsDollarCmd prerequisite. Its saved VGA frame was inspected: symbol
lookup returns 0 instead of expected 1 and the console prompt is present.
Behavioral parser assertions have not run in the native guest; they remain
required, not inherited from the original x64 pass.

### Native DolDoc compiler adapter candidate (2026-10-06)

`Kernel/I386/DocParserCompiler.HC` now provides an explicit caller-owned context
for nested control creation/entry, task-scoped frontend lookup, lexing, raw and
integer expression callbacks, adjacent-string joining and control-stack cleanup.
It is included by DocumentRuntime for compilation, but is not yet wired to
PrsDollarCmd; the native parser contract remains red. Parser strings remain
control-owned until copied to public task storage, preserving embedded bytes
and the terminator length. No global map of borrowed parser controls is used.

The initial cross-build attempt rejected a stale x64 bootstrap as expected.
Bootstrap refresh is in progress; compiler acceptance, runtime adapter behavior
and failure/cancellation cleanup are still unproven. A cleanup edit landed
during the first bootstrap run, making its manifest unsuitable for this
candidate; a fresh rebuild was started after the edit. The rebuild runner now
checks source hashes again before accepting its result, and the cross-build
rejects an explicitly failed bootstrap report.

The refreshed bootstrap now passes with unchanged source hashes:
`build/rebuild-test/result.json` has result pass and two completed original
compiler/kernel rebuild generations. Independent comparison of its recorded
Kernel/Compiler hashes against the current tree passes. Cross-build
`build/doc-parser-adapter-cross-v2` is running against that bootstrap; no
adapter runtime pass is claimed yet. The older frozen v44 native rebuild is
separate and remains on the CompilerProbe command.

The adapter cross-build completed successfully at
`build/doc-parser-adapter-cross-v2/result.json`, including the 386 instruction
and module audit. Its recorded adapter hash matches the current file. Image
SHA256 is `dc3d2de914268d49a6a59bec63f91824a4c81c1756ccf85fad81f8874b74e2d9`.
This proves compilation and static audits, not execution of the new callbacks.
A normal boot/arithmetic smoke test is running separately; PrsDollarCmd remains
unimplemented until the shared grammar accepts an explicit service context.

`build/doc-parser-adapter-smoke-v1/result.json` passes normal boot and HolyC
6*7=42 using TCG/486,-fpu and a writable image copy. This confirms startup and
console use after inclusion of the adapter; none of the adapter functions are
exercised yet, and it does not close the red DolDoc parser contract.

### Shared dollar grammar with explicit compiler services (2026-10-06)

`DocDollarServices.HH` defines lex, raw expression, integer expression and
extended-string callbacks with an explicit context. The shared flag and command
cores now call these services. Original DocPlain keeps its existing public
PrsDollarCmd/PrsDocFlags/PrsDocFlagSingle entry points through original compiler
adapters. Compiler-control lifetime belongs to the wrapper, including when the
core catches an expression error and returns DOCT_ERROR; it no longer depends
on the success-only close previously inside the core.

`build/doc-dollar-services-original-v1/result.json` passes the shared six-bit
parser contract after this change. `build/original-macro-menu-dollar-services-v1`
also passes actual original macro form construction and ownership, retaining
both field formats/flags/lengths and PLAY result 2. These are original x64
checks; no native PrsDollarCmd or form support is claimed.

The native adapter now provides matching context callbacks, still without
wiring the core. The preceding adapter cross-build/smoke covers the earlier
adapter version, not these additional callbacks. Fresh bootstrap validation is
running before recompiling this source epoch. Native form formatting/scanning,
malformed-input cleanup, allocation/cancellation coverage and parser integration
remain required.

### Bound form scanning dependency (2026-10-06)

`tests/guest/i386-str-scan/Contract.HC` and
`tools/test-i386-str-scan.py` establish the original string scanner behavior
needed by bound forms: decimal and string prefixes, hexadecimal, binary, F64,
and dynamic width with the returned remainder. Original
`build/str-scan-original-v1/result.json` passes all six checks. Native
`build/str-scan-native-red-v1/result.json` fails its prerequisite; the inspected
VGA frame shows StrScan absent (0 rather than 1). Native behavior has not run.

The whole original scanner is now shared via Kernel/StrScanCore.HC, included
by StrScan.HC. DocDataFmt and DocDataScan are shared via DocFormDataCore.HC,
included at their original DocForm position. Exact byte extraction passes at
`build/form-scan-core-extraction-v1/result.json`. These include changes are
under original rebuild/runtime verification; no native scanner/form support is
claimed. Port dependencies for every retained scan format, including dates and
numeric/string conversion, before exposing StrScan and binding the form core.
The six-bit fixture is selected coverage; failure cleanup still needs tests.

The preceding explicit dollar-service adapter cross-build completed at
`build/doc-dollar-services-cross-v1/result.json` with a passing 386 boot audit.
It predates the scanner/form extraction and does not qualify their integration.

`build/original-macro-menu-form-data-core-v1/result.json` passes actual original
macro form construction/ownership after extraction of DocDataFmt/DocDataScan.
Name/repeat formats, flags and lengths remain unchanged; PLAY returns 2 and
popup/task ownership clears. Chooser interaction remains interposed.

The updated original bootstrap passes two rebuild generations with recorded
StrScan/StrScanCore hashes matching the current files. After that rebuild,
`build/str-scan-shared-core-original-v1/result.json` passes all six scanner
checks against the generated kernel. This verifies the shared scanner include
path and selected original behavior; the native scanner remains absent.

### Original scanner retained in the native candidate (2026-10-06)

ScannerRuntime.HC now includes the complete shared original scanner, including
Str2I64, Str2F64, Str2Date and every StrScan format. Its string manipulation
helpers are shared exact original bodies in StringUtilCore/StringAllocUtilCore,
with common StringUtilFlags. Date conversion uses the existing native clock;
the scanner's limited string comparison primitive is implemented for flat
memory. Original whitespace/safe-dollar bitmaps and the boot decimal bitmap
retain the character classes. Console ABI advances to version 45 with 160
exports; public formatting declares all four conversion/scanning entry points.
This candidate has not yet passed native runtime qualification.

`build/scanner-dependency-extraction-v1/result.json` records exact helper
extraction. The refreshed original bootstrap passes two rebuild generations.
The scanner fixture now has eight checks, adding list matching and an explicit
whitespace-containing date to the previous six. Independent original
`build/str-scan-eight-original-v1/result.json` passes mask 255. Cross-build
`build/scanner-runtime-cross-v1` is running; native scanner, exception cleanup
and bound forms remain to be qualified.

The first native scanner cross-build fails while compiling the macro cleanup
directives in ScannerRuntime; its compiler-log.DD is preserved under
`build/scanner-runtime-cross-v1/exports`. This is not native qualification.
The Now/StrNCmp aliases now remain in the retained module's private compilation
scope, matching the existing formatter adapter pattern. A fresh bootstrap is
running before retrying. This adjustment remains to be verified by compilation.

### Scanner exception lifetime test before cleanup fix (2026-10-06)

`tools/test-i386-str-scan.py --cleanup` runs the shared Cleanup.HC fixture:
ten missing-argument calls must throw Scan, restore the exact task data heap,
and leave compiler-control links unchanged. Independent original baseline
`build/str-scan-cleanup-original-red-v1/result.json` fails with mask 5 instead
of 7: exceptions and control links pass, heap restoration fails. The original
StrScan allocates its temporary conversion buffer before checking arguments;
the throw path bypasses its success-only Free. This is a real existing resource
bug rather than a difference to preserve in the port.

A candidate wraps conversion/argument checks in cleanup that frees the buffer
before propagating an exception. It is prepared outside OS sources while the
native scanner cross-build retry runs, so that build's source epoch stays
unchanged. Apply after the retry ends, then require the cleanup contract and
the eight successful conversion checks against freshly rebuilt originals and
native images. Selected missing-argument coverage does not prove all converter
allocation failures or cancellation cleanup.

The scanner retry `build/scanner-runtime-cross-v2` compiled all retained modules
successfully, then failed the static console import audit: the only new import
is char_bmp_dec_numeric, already exported by the boot kernel and required by
the original converter. The exact import contract now includes that symbol;
the audit also requires all four scanner/converter function exports. Running
the updated console layout audit on the preserved module passes. Full
`build/scanner-runtime-cross-v3` is running to assemble and audit the image.
The missing-argument heap fix remains unapplied so a native red baseline can
be captured independently before changing the shared implementation.

`build/scanner-runtime-cross-v3/result.json` now passes assembly and 386 audits
for the pre-cleanup-fix scanner image. Native eight-format and missing-argument
cleanup tests are running on independent writable copies of that fixed image.
The prepared shared cleanup fix is now applied: conversion buffers are freed
before propagating an exception, with normal scanning unchanged. A fresh
original bootstrap rebuild is running to qualify the changed implementation;
no green cleanup result is claimed yet.

Both native scanner tests on the pre-fix image fail during boot with CONSOLE
REJECT load reclaimed; neither reaches its scanner assertions. In particular,
`str-scan-cleanup-native-red-v1` is a boot failure, not evidence of the heap
bug in the native scanner. The cause is the boot console binding list, which
still supplied 49 bindings and omitted the newly imported decimal bitmap.
KernelConsoleLoad now supplies that exact import as binding 49 with count 50.
Fresh bootstrap/cross-build verification is required for this source change.

The shared buffer cleanup fix has rebuilt successfully in original TempleOS;
original cleanup and eight-format regression tests are now running against its
generated kernel. Native behavior remains unqualified until the corrected boot
binding image is built and tested.

The corrected binding image `build/scanner-runtime-cross-v4/result.json` passes
assembly and 386 audits. Native tests now boot and pass the StrScan presence
check. Their first retry stopped because the harness cannot submit a fixture
larger than 255 characters. The driver now transfers source in bounded chunks,
writes a guest HolyC file and includes it; an initial chunk-transfer retry
exposed MemCpy's printed return value, so a U0 transfer helper now avoids that
extra answer. Fresh eight-format and cleanup tests are running on the same
unchanged v4 image. None of these fixture failures qualify scanner behavior.

Original post-fix conversion checks pass mask 255, but the boot-bound cleanup
check still fails mask 5 with heap delta 240. A direct-source oracle is being
developed to remove uncertainty about that binding; its first macro-renaming
attempt entered the debugger with Bad Free while compiling and is invalid as
scanner behavior evidence. The shared cleanup fix remains unproven pending a
working direct oracle and actual native cleanup observations.

`build/str-scan-eight-native-v4/result.json` passes all eight scan formats,
normal boot, console arithmetic and exact VGA checkpoints on TCG/486,-fpu,
8 MiB (19 commands). This is selected scanner qualification only.

Native cleanup `build/str-scan-cleanup-native-v4` reaches the actual scanner
then fails: THROW Scan followed by THROW 0 and BAD PUBLIC MEMORY. The candidate
cleanup catcher incorrectly called throw explicitly; this recursively dispatches
the still-active catcher and can free the same buffer twice. Original and
native dispatchers automatically propagate when a catcher returns without
marking catch_except true. The scanner catch now only frees its buffer. The
new DocParserCompiler cleanup catches and original dollar-wrapper catch now
use that same existing HolyC propagation behavior; these adapter changes still
need their own runtime fault tests.

A direct original oracle now copies the shared scanner with function identifiers
renamed in its source bytes, avoiding macro aliases in function declarations.
The native fixture transfer writes bounded chunks through a U0 helper and
includes the resulting guest file. Earlier tests are preserved and labeled by
their actual failure; the native boot/harness failures do not prove heap cleanup.
Fresh original cleanup and bootstrap checks are running for the revised code.

The direct original oracle now passes:
`build/str-scan-auto-propagation-original-v1/result.json` returns cleanup mask 7
and reports heap delta 0 across ten Scan exceptions. It compiles the current
shared scanner under separate function names and therefore exercises the
revised catch directly. Native cleanup remains pending a fresh cross-build;
the previous native eight-format pass is on the earlier source epoch.

`build/str-scan-auto-propagation-eight-original-v1/result.json` also passes
all eight conversion checks against the direct current scanner source.
Fresh bootstrap and `build/scanner-runtime-cross-v5/result.json` pass after
the automatic-propagation fix and boot binding change. Native eight-format and
cleanup tests are running on independent writable copies of that v5 image;
the selected original heap result is not substituted for native evidence.

Both native scanner gates now pass on the same v5 image: eight conversions
(mask 255, 19 commands) and ten missing-argument exceptions with exact task
heap/control recovery (mask 7, 14 commands), with console arithmetic afterward.
`build/str-scan-eight-native-v5/result.json` and
`build/str-scan-cleanup-native-v5/result.json` record TCG/486,-fpu, 8 MiB and exact
VGA checks. Image SHA256 is `9ef9d772e456928c665d33f7a5b538a8de3c8a8db09ffe524684215f234a3d21`. Current Kernel/Compiler source
hashes match the cross-build report. This closes the selected scanner and
missing-argument cleanup gates, not all allocator failures, cancellation,
converter-internal failures, DolDoc forms or release qualification.

### Native shared dollar parser candidate (2026-10-06)

DocDollarRuntime.HC now binds the shared flags/command grammar to the existing
explicit native compiler context, closes nested controls on completion or
propagated exceptions, and includes original DocDataFmt/DocDataScan. Original
DocBinPtrRst is shared through DocBinPtrCore with its existing document read/
copy/link behavior; original string tail helpers are shared through StringTailCore.
The candidate preserves these grammar paths rather than rejecting binary links
or reducing expressions to integer literals. BEqu and substring search have
flat-memory adapters scoped to the retained console compilation.

Console version 46 has 163 exports, including PrsDollarCmd, DocDataFmt and
DocDataScan, with public declarations and audit requirements. The parser test
now transfers its HolyC fixture in bounded console commands, writes a guest
file and includes it, avoiding the known 255-character input limit. Refreshed
original bootstrap passes; cross-build and original parser regression are
running. Native parser behavior, field formatting/scanning, error/resource
cleanup and actual forms remain unqualified. DocPrint/DocMenu and the macro
utility are still missing; adding these callbacks does not close that gate.

The original six-check parser regression passes at
`build/doc-dollar-runtime-original-v1/result.json`. Native candidate
`build/doc-dollar-runtime-cross-v1/result.json` compiles and passes its 386
boot/module audit. Its native parser contract is now running on a writable copy.
No native expression or field-formatting result is claimed until that test
completes; original and static results are separate evidence.

Native parser run `build/doc-dollar-runtime-native-v1` passes the API check and
compiles its fixture, then DollarParserContract reports Out of memory. The
saved VGA frame confirms this; no behavioral mask is produced. Inspection
finds I386FrontendServices requires CCF_AOT_COMPILE even for the native JIT
expression frontend. The adapter omitted that flag, so frontend initialization
returned NULL; this was an interface precondition failure, not evidence of
exhausted guest RAM. The factory now supplies the same flag used by ordinary
native command input, and frontend/files rejection is classified Compiler
instead of incorrectly reporting OutMem. Fresh bootstrap/build/tests remain
required for this fix.

The new --fields fixture independently passes in original TempleOS at
`build/doc-dollar-fields-original-v1/result.json`: name/repeat bindings,
formatting and refresh, string/integer scan-back with terminator restoration,
delete and exact task heap recovery. It will exercise the shared native form
data functions after the parser adapter is green; chooser and DocPrint/DocMenu
remain separate required work.

Native bound fields now pass at `build/doc-dollar-fields-native-v1/result.json`:
name/repeat binding, formatting and refresh; scan-back into string and negative
I64 storage with terminator restoration; document/entry deletion and exact
caller task heap. The expression contract remains red at
`build/doc-dollar-runtime-native-v2`: global lookup fails before a mask result.

The failure is not a proved borrowed-name lifetime corruption. The synthetic
expression function has a NULL diagnostic name; logging it printed bytes from
address zero and broke UTF-8 log decoding. The actual rejection is a missing
symbol reference: leaving CCF_AOT_COMPILE enabled emits module-relative global
addresses instead of live task addresses. As ordinary native command execution
does, the adapter now initializes the frontend in its required AOT mode then
clears that mode for executed expressions. The diagnostic also keeps <none>
for an unnamed function instead of dereferencing NULL. Fresh qualification is
running; no task-global/function-expression pass is claimed yet.


### Console 46 native parser and bound-field qualification (2026-10-06)

`build/doc-dollar-runtime-native-v3/result.json` passes 22 commands and
`build/doc-dollar-fields-native-v2/result.json` passes 21 commands, both on
TCG/486,-fpu with 8 MiB and exact VGA comparisons at every checkpoint. Both
use `build/doc-dollar-runtime-cross-v3/kernel.img`, SHA-256
`c646578fb2e88895b5bd9804dd654ac9a90f2526522d5a582e78c3517131a1ef`.
Recorded driver, fixture, helper and disk hashes still match; the cross-build's
recorded Kernel/Compiler source hashes match the current worktree.

The expression contract covers precedence, STR_LEN, F64-to-integer conversion,
adjacent strings, task globals, raw F64 bits and function calls. The field
contract covers original DA name/repeat grammar, bindings, format/refresh,
string and negative-integer scan-back, terminator restoration, deletion and
exact caller task data-heap recovery. These passes qualify the runtime-mode
fix and do not qualify malformed input, allocation faults, binary links,
shared compiler-heap recovery or chooser interaction. DocPrint, DocMenu and
the original F2/Shift-F2 macro utility remain required.

The separate frozen console-44 six-module native build is still live at its
existing process handle; its evidence does not qualify console 46.


DocPrint construction test separation (2026-10-06):
`tools/test-i386-doc-form-construction.py --construction-only` now requires
DocPrint/DocDataFmt (mask 3) and retains every original field/button/refresh
behavior assertion. The default still requires DocMenu too (mask 7). This
allows construction qualification before chooser implementation; it does not
relax the full utility gate. A fresh native red run is in progress at
`build/doc-form-construction-only-red-v1` against console 46.


Shared DocPutS/DocPrint preparation (2026-10-06): the original function
bodies are extracted byte-for-byte into `Adam/DolDoc/DocPutSCore.HC`
(SHA-256 5879ff8d23cf2c395cb9e3ba8aaa5838d9ba626aa9c55eef26c80016b2a95cbd).
Original DocPutS.HC includes this core; native inclusion/export is not yet
implemented. The original macro-form oracle now pins both files and is
running at `build/original-macro-menu-put-core-v1`. Native integration must
provide the three original character bitmaps, preserve default DocPut lookup,
locking, cursor/plain-text flags, dollar escaping and last-dollar-entry return
semantics. The construction-only native run has reached DFPrereq; it remains
live and no final result is claimed.


Console 47 DocPrint prototype (2026-10-06): original macro-form regression
after DocPutSCore extraction passes at `build/original-macro-menu-put-core-v1`.
Construction-only native red run terminates at DFPrereq (console 46 lacks
DocPrint); behavior is not reached. Console 47 now includes the unchanged
DocPutS/DocPrint core with the three original bitmap contents and exports
_DOC_PUT_S/_DOC_PRINT (165 console exports). Audit requires both functions.
Fresh two-generation bootstrap has started; native compilation and behavior
remain unqualified. DocMenu is still absent.

Construction fixture now checks DocPutS plain-text NULL return and DocPrint last-dollar-entry return across two buttons with intervening text. Resource qualification needs a compiled function scope; interactive declarations between snapshots would mix compiler allocations with document allocations. No new heap proof is claimed.

Console 47 fresh two-generation bootstrap and native cross-build pass at build/doc-print-runtime-cross-v1, including the 386 boot audit. Native construction acceptance is running at build/doc-print-construction-native-v1; a new --original mode runs the same construction assertions at build/doc-print-construction-original-v1. Neither behavioral result is claimed yet.


### Next form/menu implementation gate (2026-10-06)

The expanded original construction oracle passes nine assertions at
`build/doc-print-construction-original-v1/result.json`. Native console 47
construction is still running at its first DocPrint call; no pass is inferred
from successful compilation.

DocMenu requires more than a callable wrapper. Current native DocEd rejects
nonzero flags, treats Enter as text insertion, and has no DOCF_FORM selection
branch. Original DocMenu runs DocEd, executes the selected entry through
DocEntryRun, unlocks it, restarts with DOF_DONT_HOME when no action is present,
and restores task end callback, border source and break-to-Shift-Esc state.
Original DocEntryRun distinguishes left space/right newline actions, links,
expression values plus MSG_CMD, callbacks (unlock first), macros, list/data
fields and ESC/QUIT/collapsible flags. Preserve this behavior rather than
adding a command-only picker for the macro utility.

Automated acceptance must cover editing and scan-back of name/repeat fields;
keyboard and mouse selection of all six macro actions; cancel and no-action
restart; exact return/action/message semantics; document lock and task-state
restoration; exception and allocation cleanup. Keep original chooser behavior
and native UI evidence separate from the existing interposed original menu
oracle, which intentionally bypasses chooser interaction.

Native construction v1 ends in a harness screen mismatch at the first DocPrint assignment. Inspection of saved VGA startup-command-04.ppm shows a non-NULL pointer printed by the assignment, with COMMAND OK; no native exception is observed. Empty expected output was incorrect. The three pointer assignments now cast to U0, preserving field assertions. Native v2 is running against the same console47 image; no field-behavior pass is claimed yet.

Added PrintedFields.HC and --printed-fields to the parser contract driver: ten compiled-function cycles create real DocPrint-linked name/repeat fields and a button surrounded by text, refresh and scan back values, delete the document and require exact caller task data-heap recovery on each cycle. Original and native runs are live at build/doc-print-fields-original-v1 and build/doc-print-fields-native-v1; no resource pass is claimed yet. Shared compiler heap, chooser and allocation faults remain outside this fixture.


Printed-fields original resource contract passes mask 63 at
`build/doc-print-fields-original-v1`: ten compiled-function cycles, linked
DocPrint entries and exact caller task data-heap recovery. Native resource
run remains live. Construction native v2 rejects the fixture's C-style
(U0) cast with "Use TempleOS postfix typecasting"; this is a fixture error,
not DocPrint execution evidence. v3 uses postfix (U0) and is running.

The original DocMenuEndTaskCB/DocMenu body is extracted byte-for-byte into
Adam/DolDoc/DocMenuCore.HC, SHA-256
3ab9a0cf2120063dbe071b3004f0522048e62c521ed4a084831a7d140ffdc5b4.
Original DocForm.HC includes it; native inclusion is not yet implemented.
The original interposed macro form oracle pins the new core and is running
at build/original-macro-menu-menu-core-v1. This regression intentionally
bypasses the chooser; it cannot qualify native menu selection or restoration.

Original macro-form regression passes after DocMenuCore extraction at build/original-macro-menu-menu-core-v1. Added an entry-action contract (EntryActions.HC / test-i386-doc-entry-actions.py) for left/right expression return values, MSG_CMD payloads, callback execution after unlocking and no-action DOCM_CANCEL. Original oracle is running at build/doc-entry-actions-original-v1; native DocEntryRun remains absent. Links, macros, chooser selection and failures remain additional required coverage.


Original entry-action contract passes mask 63 at
`build/doc-entry-actions-original-v1`: left/right values, MSG_CMD payloads,
unlocked callbacks and no-action cancellation. Native entry-action API is
still absent; this oracle is an implementation target, not native proof.

Native construction v3 raises Compiler while executing the postfix U0 cast;
now void helper functions suppress assignment output without a void cast.
Native printed-fields v1 rejects fixture compilation with Invalid member.
The button local declaration is moved to the initial declarations for a
focused retry; root cause is not yet proved. Both failures remain preserved.
Runs construction v4 and printed-fields v2 are live on unchanged console47
image. Neither field/resource success nor compiler-error resolution is claimed.

Original DocEntryRun is now extracted byte-for-byte into DocEntryRunCore.HC (SHA-256 d5375dc978b8ddafa1d272c4579e810f6e0a467bc87a4d2136eb53a275e6f5b2); original DocRun.HC includes it. Shared original action regression and native API red test are running at build/doc-entry-actions-shared-original-v1 / build/doc-entry-actions-native-red-v1. Native integration must preserve the full action body, including links, input/popup macros, list choices and exception positioning; no reduced expression-only provider is installed. The action driver now exposes only its own fixture and oracle/native modes.

Shared original entry-action regression passes mask63 at build/doc-entry-actions-shared-original-v1. Native construction v4 reaches the first binding/format check and displays both the incidental assignment pointer and assertion value1; saved VGA proves the field type/len and Name:386_ checks succeeded, but not the full contract. All remaining setup assignments are normalized into U0 helpers in v5. Printed-fields native v2 compiles its fixture after moving the local button declaration; execution/resource result is pending.

Printed-fields native v2 ends in an include screen mismatch: saved VGA shows COMMAND OK and value63 after including the two-function fixture. This is useful positive observed output but does not prove the intended explicit-call checkpoints. The fixture now defines one contract function; the driver invokes it ten times explicitly (native v3), and original mode aggregates ten explicit calls. This avoids relying on incidental include evaluation output. Native v3 is live; no complete resource qualification is claimed yet.

Native DocEntryRun red prerequisite is terminal at build/doc-entry-actions-native-red-v1: API lookup returns0 (COMMAND OK), so action assertions are not reached. Added OutputModes.HC / test-i386-doc-output-modes.py to check six original DocPutS modes: ordinary text, escaped dollars, CRLF/tab entries, plain dollar text, literal tabs and hidden cursor, including writable-source restoration. Original oracle is live at build/doc-output-modes-original-v1; no output-mode pass is claimed yet.

Native DocPrint construction passes at build/doc-print-construction-native-v5/result.json: 28 commands, 486,-fpu, 8 MiB, exact VGA comparisons. This covers bound name/repeat fields, refresh, PLAY button, plain return and last-dollar return; chooser, resource faults and broader mode coverage remain open.


Original output-mode oracle passes mask63 at
`build/doc-output-modes-original-v1`. Native output-mode acceptance is live
on console47 cross-v1 at build/doc-output-modes-native-v1. Printed-fields
native v3 fails compilation with Missing ')' at, so no explicit resource
check executes. The prior include-time63 output remains indirect evidence.

To locate the compiler failure rather than continue speculative fixture
changes, I386FrontendReport now logs the current token string, include file
and line for errors. The new DocPutS/DocPrint public declarations are also
moved inside PublicDocument.HH's include guard. Fresh two-generation
bootstrap is live; the cross-v1 image does not contain these changes, and
its construction pass is historical evidence for that source epoch.


Entry-action integration dependency audit: original PopUp runs a SrvCmdLine
child through TaskExe and JobResScan, restores popup ownership and retires
the child; these services are absent natively. PopUpPickLst constructs a real
MU chooser via DocPrint/PopUpMenu. Original In uses an Adam-heap string and
InStr to emit/free it; AStrNew is simply StrNew(buf,adam_task). Native InStr
exists, but AStrNew/In and popup execution/result handoff are still absent.
DocBottom also needs original document recalculation. Restore these services
with task ownership, result, cancellation and heap tests before including the
full shared DocEntryRun body; do not replace its unused-in-one-test branches
with stubs.


Fixture transport root cause (2026-10-06): independent RedSea extraction of
/DollarContract.HC from printed-fields v3 and output-modes v1 shows doubled
dollars collapsed by the outer HolyC string literal. DPTransfer nevertheless
copied the original chunk byte count, writing terminators and stray bytes.
This explains malformed native test input; these compiler errors do not prove
a parser defect, and the incidental include-time63 is invalid resource proof.

Parser, entry-action and output-mode drivers now double every dollar before
encoding the transfer literal, use 60-character chunks and require independent
byte-for-byte extraction of the saved fixture before reporting pass. They pin
the independent reader tool too. Native printed-fields v4 and output-modes v2
are live on the same console47 cross-v1 image. Diagnostics/header-guard cross
v2 remains a separate live build; no new native success is claimed yet.

Diagnostic cross-v2 is terminal: compiler-log.DD identifies undeclared KernelHex at Frontend.HC line170. CompilerRuntime imports only KernelLog; the diagnostic now formats the decimal line number locally and uses that existing service, preserving its import contract. Fresh bootstrap is live. Corrected field/mode runs use cross-v1 and remain separate evidence.


### Console 47 DocPrint selected native gates pass (2026-10-06)

`build/doc-print-fields-native-v4/result.json` passes 36 commands, including
ten explicit calls that each require mask63 and exact caller task data-heap
recovery. `build/doc-output-modes-native-v2/result.json` passes 32 commands
covering ordinary text, escaped dollars, CRLF/tab entries, plain dollar text,
literal tabs and hidden cursor with writable-source restoration. Both use
TCG/486,-fpu / 8 MiB and exact VGA at every checkpoint. Source transfer is
independently validated by RedSea extraction; guest fixture hashes equal the
pinned host fixture hashes. All recorded driver/helper/image hashes still
match. Image cross-v1 SHA-256:
50bbe972962b594a707d7a5d307745e9333c1f22106de5a89386bbed4fb93007.

Together with 28-command construction v5, these qualify selected original
DocPutS/DocPrint behavior on that image. They do not qualify allocator faults,
shared compiler-heap recovery, chooser behavior or the full macro utility.
The new diagnostic/header-guard source epoch has not inherited these results.
The revised single-function original ten-cycle oracle is live at
build/doc-print-fields-original-v2; earlier original resource evidence used
the two-function fixture.


Revised original printed-fields oracle passes mask63 at
`build/doc-print-fields-original-v2`, aggregating ten explicit single-function
calls. Added `tools/test-i386-doc-print-allocation.py`: a selected public
MAlloc/CAlloc call is patched to throw OutMem only around DocPrint("plain");
checks exception/count, original allocator bytes restored, unlocked document,
valid signature and exact caller heap after deletion. Interrupts are restored
and the hook removed before reporting. First MAlloc-call2 red run is live at
build/doc-print-allocation-malloc2-red-v1 on cross-v1. No fault-site recovery
is claimed yet; one site does not qualify all output/parser allocations.

Diagnostic/header-guard cross-v3 passes the 386 boot audit. Native resource and output-mode regressions are live at build/doc-print-fields-diagnostic-v1 / build/doc-output-modes-diagnostic-v1. Added test-i386-original-doc-print-allocation.py to execute the same selected public allocator hook contract in original TempleOS, pinning shared output/formatter sources; original MAlloc2 red run is live. Original/native allocation orders may differ, so each run qualifies only its own selected site.


DocPrint MAlloc2 red run is terminal: saved VGA shows mask39, OutMem and
COMMAND OK. Hook bytes, exception/count and signature pass; unlocked-document
and exact caller heap checks fail. This is actual native failure recovery
evidence, not a screen-output fixture error.

Shared cleanup prototype now tracks pending entry ownership, temporary cursor
filter/dollar buffers and dollar separator restoration, unlocks on propagated
exceptions, and frees DocPrint's formatted buffer on exception. Original and
native use the same core. Ordinary text separator restoration still needs a
follow-up before full source-restoration qualification. No cleanup pass is
claimed. Original MAlloc2 cleanup oracle and fresh bootstrap are live.

The first original hook run returned mask59 / delta0 / calls555601: original
exception handling allocates after the injected throw, so leaving the hook
armed invalidated its exact call-count assertion. The hook now restores its
entry before throwing, isolating the selected allocation in both systems.
Each fault case still needs original/native qualification; their allocation
orders may differ.


Original MAlloc2 cleanup oracle passes mask63, delta0, calls2 at
`build/doc-print-allocation-original-malloc2-cleanup-v1`. This proves the
selected original-site exception/count, lock and heap checks with the
pre-throw hook disarmed. Native cleanup qualification remains required.
Diagnostic cross-v3 image independently passes resource (36 commands) and
output-mode (32 commands) regressions at build/doc-print-fields-diagnostic-v1
and build/doc-output-modes-diagnostic-v1, including exact source extraction.
These runs predate the cleanup prototype and do not qualify it.

Ordinary text separator restoration is now tracked and cleared after restoring its byte. Fresh bootstrap is live for the complete cleanup prototype; original MAlloc3 fault and output-mode regressions are live at build/doc-print-allocation-original-malloc3-cleanup-v1 / build/doc-output-modes-cleanup-original-v1. The prior bootstrap before this final restoration edit passed but does not qualify the current source.


Complete cleanup prototype bootstrap passes both generations. Original
output-mode regression passes mask63 at build/doc-output-modes-cleanup-original-v1.
Original MAlloc3 fault is red at build/doc-print-allocation-original-malloc3-cleanup-v1:
mask47, delta160, calls3. Exception/count, restored hook, lock and signature
pass; exact heap recovery fails. This later site remains a real gap; selected
MAlloc2 green does not close it. The hook now records bounded allocation sizes
and the original trace retry is live at build/doc-print-allocation-original-malloc3-trace-v1.
Native cleanup cross-build is live at build/doc-print-cleanup-cross-v1; no
native cleanup or later-site success is claimed yet.

Original MAlloc3 trace records sizes120/144/120 and delta160. Kernel/KExcept.HC SysTry allocates CExcept with MAlloc. The second protected region is installed only after allocating the formatting buffer, so failure while installing it leaves the buffer outside any owning handler. DocPutS likewise locks before installing its handler. Prepared a follow-up moving formatting allocation and DocLock inside their protected regions; waiting for the live native cross-build to finish before changing its source.

Cleanup cross-v1 completes and passes the 386 audit; it predates the protected-allocation follow-up. Applied the follow-up after that build became terminal. Original MAlloc3 protected-region oracle and fresh bootstrap are now live. No pass on the complete revised source is claimed.


Protected-region original MAlloc3 oracle passes mask63, delta0, calls3 at
`build/doc-print-allocation-original-malloc3-protected-v1`; sizes120/120/144
confirm formatting allocation now occurs after its owner handler is installed.
The original fault index changed with the new handler placement, so this is
a selected-site result, not the old allocation-order proof. Original indices4
and6 plus output-mode regression are live on the same source. Bootstrap is
still live; no revised native fault/ordinary behavior qualification yet.


Original protected-region fault indices4 and6 pass mask63 / delta0 / exact
selected call counts at build/doc-print-allocation-original-malloc4-protected-v1
and build/doc-print-allocation-original-malloc6-protected-v1. Original normal
output modes pass at build/doc-output-modes-protected-original-v1. These
selected sites do not prove all parser/formatter failures.

Added direct DocPutS source-restoration drivers. They allocate writable
"a\nb" before arming the allocator hook, require original source bytes after
the exception, restored hook/count, unlocked/signature-valid document and
exact caller heap after deleting the document/source (mask127). Original
fault index4 is live at build/doc-put-s-source-fault-original-v1; native sites
will be selected independently because handler allocation differs.


Direct original DocPutS fault oracle passes mask127 / delta0 / calls4 at
`build/doc-put-s-source-fault-original-v1`, with sizes120/120/88 before the
injected tag allocation failure. This proves newline source-byte restoration,
unlinked base-entry cleanup, document unlock/signature and exact caller heap
for that selected original site. Native DocPrint MAlloc2 and direct DocPutS
MAlloc2 fault tests are live on cleanup cross-v2. Ten-cycle field and six-mode
native normal regressions also started on that same image; all results are
pending. Keep current core unchanged while these pinned tests finish.

Native selected fault recovery now passes on cleanup cross-v2: build/doc-print-allocation-native-cleanup-v1 and build/doc-put-s-source-fault-native-v1 pass 12 and 14 commands respectively at 486,-fpu / 8 MiB with exact VGA and unchanged pinned inputs. DocPrint MAlloc2 recovers exception/count, hook bytes, lock/signature and exact caller heap; direct DocPutS MAlloc2 also restores the writable newline source exactly (mask127). These selected fault sites do not qualify all grammar/formatter allocations. Normal native field/mode regressions remain live.


Current console47 cleanup image completes all selected gates: native
fields36, modes32, DocPrint fault12 and direct DocPutS fault14 commands at
486,-fpu / 8 MiB. Exact VGA, source extraction and provenance checks pass.
Disk SHA-256 11f827b7970842c8d74d98de90c5ab0616f45f9bbab0b96468965f5e11a5e6f1. Relevant Kernel/Compiler/DolDoc source hashes
still match the cross-build. This does not close remaining full grammar,
allocator, compiler-heap, chooser or release gates.

Frozen console44 native-six-v1 is terminal PASS: six modules rebuilt inside
486,-fpu with 16 MiB. Two-generation installation/selfhost/audit qualification
started against that frozen repository and retained build at
build/macro-playback-candidate-v1/build/native-generations-v1. It cannot
qualify current console47 output/parser changes.


Next entry-action dependency: original In formats text, allocates its lasting
copy in Adam's heap and passes a generated print/free expression to InStr.
Added i386-in-text/Contract.HC and test-i386-in-text-wrapper.py: intercept
InStr and check its format, duplicate pointer arguments, quotes/backslash/
percent plus empty text, twenty cycles, restored bytes and root/caller heap
recovery. Actual input delivery, different-task ownership and faults remain
separate required gates. Original oracle and native In API red run are live
at build/in-text-wrapper-original-v1 / build/in-text-wrapper-native-red-v1.
No In provider has been added yet; no wrapper pass is claimed.


Original In wrapper contract passes mask63 at build/in-text-wrapper-original-v1:
twenty nonempty/empty cycles, format/duplicate-pointer/text checks, restored
InStr hook and exact measured root/caller heaps. InStr is interposed; actual
delivery and different-task ownership remain unproved.

Original In is extracted byte-for-byte into Kernel/JobInCore.HC (SHA-256
82c1e2b9343b0b1dd4a13db1f91641ea4c8fd1b58e061f28e33a2e6fd69f266c).
Original Job.HC includes it. Console48 now includes the same body with private
AStrNew adapter allocating in the native scheduler root, and exports _IN
(166 providers). Static audit requires In. Fresh bootstrap is live. No native
wrapper/delivery/failure pass is claimed; the original unchanged body still
needs exception/allocation qualification.

Native In prerequisite red-v1 is terminal. Its driver pin changed when the new shared-core dependency was added before final observation; this invalidates its provenance and it is not counted as a clean red baseline. No positive native evidence is inferred. A fresh image-bound run is required once console48 is built.

Console48 bootstrap passes both generations; native cross-build is live at build/in-text-runtime-cross-v1. Shared original In wrapper regression is live at build/in-text-wrapper-shared-original-v1. Added test-i386-in-text-delivery.py to require actual quoted/backslash/percent/integer and empty key sequences, explicit TaskWait, restored filter state and ten cycles with exact caller heap. Root heap, submitting-child lifetime and faults remain distinct gates; delivery has not run until the new image is built.

Shared original In wrapper oracle passes at build/in-text-wrapper-shared-original-v1. Cross-v1 compiled all modules but failed a mistakenly changed file-runtime audit expectation48; FileRuntime remains47. Corrected only that audit and independently verified compiled FileRuntime/ConsoleRuntime layouts, then started cross-v2. Added Failure.HC / test-i386-in-text-rejection.py to require propagated Break and exact caller/root heap recovery when InStr throws after pointer handoff; original red oracle is running. No failure recovery pass is claimed.


Console48 cross-v2 passes the 386 boot audit. Native wrapper, actual delivery
and rejection red runs are live against that image. Original rejection red
at build/in-text-rejection-original-red-v1 returns mask15: caught Break,
restored hook and pointer/format pass, caller/root heap recovery fail.

Shared In now initializes buffer pointers before its handler, formats and
copies inside the protected region, clears the root-string pointer after
successful InStr submission, and frees both pointers on propagated exceptions.
The generated print/free expression and normal semantics stay unchanged.
Original cleanup oracle is live at build/in-text-rejection-original-cleanup-v1.
The new cleanup source does not inherit cross-v2's qualification. No recovery
pass or all-failure ownership guarantee is claimed yet.


Original In cleanup-v1 still reports mask15 because the earlier wrapper
driver calls the boot-bound Kernel In. Editing JobInCore.HC without rebuilding
that kernel does not change the executed function. It is invalid evidence
about the new cleanup body, though valid evidence about the old boot binding.
Added test-i386-original-in-core.py: reads/pins the exact current shared body,
renames only its function to ITOracleIn and invokes it from the selected
fixture. Direct-current rejection and normal wrapper oracles are live at
build/in-core-rejection-original-v1 / build/in-core-wrapper-original-v1.
Fresh two-generation bootstrap also started for the actual new kernel body.
No revised cleanup pass is claimed yet.


Current shared In direct-source oracles pass mask63 for both rejection and
normal wrapper at build/in-core-rejection-original-v1 / in-core-wrapper-original-v1.
Native cross-v2 passes wrapper33 and actual-delivery9 commands at 486,-fpu /
8 MiB with exact VGA; twenty captured cycles and ten actual nonempty/empty
cycles recover the measured caller heap. Native rejection red-v1 saved VGA
shows mask15, matching the old leak. These results qualify cross-v2's normal
path, not the edited rejection cleanup. Separate submitting-task lifetime,
root heap after actual delivery and allocator faults remain required.


Added test-i386-in-text-submitter-exit.py: a child queues In("ORPHAN") and
exits immediately; after one warmup, ten further children must retire and
the root heap must recover after draining. Red run is live at
build/in-text-submitter-exit-red-v1 on pre-cleanup cross-v2. This targets
queued ownership, which the intercepted rejection test does not prove.
The current root string is encoded into generated source and released by its
Free expression; queued job retirement before execution must also account
for that string. Do not infer lifetime safety from ordinary delivery/rejection
passes. Native cleanup cross-build remains live and separate.


### In payload lifetime gate (2026-10-06)

Normal delivery and intercepted rejection are separate from job retirement.
The current cleanup image retains 240 root-heap bytes after ten children queue
In("ORPHAN") and immediately exit. A paired no-In retirement control is now
running, with unchanged image/driver/helper pins. No ownership fix is yet
qualified or attributed solely from the combined assertion.

Required ownership design: one owner must retain the formatted input string
until the print job completes, rejects, throws, is cancelled, or is retired
with its recipient. Both console JobDel and memory-module job-ring retirement
must release the same payload; freeing only aux_str (generated source) does
not release the string whose address is embedded in that source. Transfer
must occur atomically with job acceptance, so an exception before acceptance
leaves the caller responsible and cannot double-free. Synchronous submission
from an input-filter task needs the same exception-safe lifetime. Public In
formatting and input semantics remain unchanged. Any change to the private
generated print/free expression requires an updated implementation oracle;
actual delivery and retirement tests remain mandatory.
