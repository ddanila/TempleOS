# GetStr compatibility

GetStr is the next missing public API encountered while compiling unchanged
TimeClock source (TimeClk.HC line 127). This work contributes to C1 reference
coverage and C4 API compatibility; it does not qualify TimeClock or C2–C5.

## Original-system observations

`tools/test-i386-getstr-reference.py` restores all 686 original paths using the
same archived/repaired revisions as the TimeClock reference capture. Original
compiler and kernel binaries are restored too. The disposable guest feeds
`In` text into `GetStr`, exports each returned allocation including its NUL,
and compares the captured bytes with explicit host expectations.

| Input | Default / flags | Returned bytes before NUL |
| --- | --- | --- |
| `alpha` then Enter | none | `alpha` |
| Enter | none | empty |
| Enter | `fallback` | `fallback` |
| `alpha` Enter `beta` Enter Esc | `GSF_WITH_NEW_LINE` | `alpha\nbeta\n` |
| `discard` then Shift-Esc | none | empty |
| `discard` then Shift-Esc | `fallback` | `fallback` |

All six pass in `build/i386-c1-getstr-reference/result.json`. The trailing
newline and cancellation/default behavior are observed original behavior,
not implementation conveniences. The shared reference-restoration helper was
also rechecked with the existing TimeClock storage/report oracle:
`build/i386-c1-timeclock-reference-helper/result.json` passes.

```sh
python3 tools/test-i386-getstr-reference.py --out build/getstr-reference
python3 tools/test-i386-getstr.py IMAGE --out build/getstr-native
```

Both runners require fresh output directories. Native testing uses a writable
copy, records unchanged input hashes and requires public-interface results and
exact VGA answers on the no-FPU 486 QEMU profile at 64 MiB.

The native baseline `build/i386-c1-getstr-red/result.json` fails at the first
`GetStr` call with `Invalid lval` / `INPUT REJECT`, after the declaration
command succeeds. Input hashes remain unchanged. This is the expected missing
binding failure, not evidence that the later five cases execute natively.

## Architectural work

The original `Kernel/SerialDev/Message.HC` wrapper prints the optional prompt,
calls `fp_getstr2`, and replaces an empty result with a separately allocated
default or empty string. `Adam/DolDoc/DocGet.HC` implements that service against
the task's output document: prompt markers delimit input, `DocGetKey` drives
editing, and `DocScanLine` extracts document entries. Enter submits single-line
input; multiline input ends on Esc. Shift-Esc cancels or exits the task when
`GSF_SHIFT_ESC_EXIT` is set. Ctrl-Shift-Enter inserts a line without submitting.
Esc can execute the current document entry before ending multiline input.

The port already has a DolDoc editing model and public task key queues, but
`NativePutS` now records ordinary output in the task-owned document and
projects it onto `console_text`, but forces plain-text recording; it does not yet
provide the original structured output/key-echo chain. `NativeReadKey` consumes task messages; the full-screen `DocEd`
loop is a separate client. Therefore merely exposing a new string-buffer loop,
or invoking the full-screen editor for each prompt, would leave the original
inline document/input semantics missing.

Next work must connect output/input to the task's canonical document, share
line extraction and key processing where possible, and preserve terminal
history and command entry. Add tests for real keyboard editing, prompt
formatting, Ctrl-Shift-Enter, Esc entry execution, filter exit, cancellation,
exception cleanup and `GSF_SHIFT_ESC_EXIT`; the six scripted cases alone do not
qualify those behaviors. Recheck existing terminal, input-filter and document
workflows after integration. No native GetStr implementation is claimed here.

## Shared line extraction

The original `DocScanLine` body is now shared verbatim through
`Adam/DolDoc/DocScanLineCore.HC`, included by both the original `DocGet.HC` and
the native document runtime. Console interface 69 exposes the public API.
There is no new input-buffer implementation or change to GetStr semantics.

The expanded original reference fixture captures empty, text/tab and second-line
bytes, checks newline/end-entry pointers and cursor positions, and checks
signed X/positive Y positioning reconstruction (`$SX,-3$$SY,2$`). All ten
exported buffers pass exact host expectations in
`build/i386-c1-getstr-scan-shift-reference/result.json`. The bootstrap rebuilds
and boots two original generations with the shared include; the cross-build
and 386 loader audits pass in `build/i386-c1-doc-scan-cross`.

`tools/test-i386-doc-scan.py` independently exercises these public document APIs
on the native image. The preimplementation baseline rejects the absent API
(`build/i386-c1-doc-scan-red-v2/result.json`). Assignment and setup operations
are wrapped in void helpers so pointer-valued results cannot become
address-dependent framebuffer expectations. The GetStr native fixture uses
a returning helper for the same reason; its updated failing baseline is
`build/i386-c1-getstr-red-v2/result.json`. GetStr itself is still missing.

The native run passes all seventeen commands with exact VGA checkpoints at
64 MiB on `486,-fpu`, including all the extraction cases above and subsequent
arithmetic. Its source image and harness hashes remain unchanged. Evidence:
`build/i386-c1-doc-scan-native/result.json`. This qualifies the exercised line
extraction cases, not GetStr or the remaining DocGet services. Allocation
failure/unwind and the rest of the input state machine remain separate work.

## Prior minimal-profile regression (superseded below)

`build/i386-c1-doc-scan-startup/result.json` fails at 8 MiB. Normal boot and
public headers finish, but the first `SPNext` function definition rejects with
OutMem. The raw arena is `0x657200` bytes, with `0x655438` used and a largest
free payload of only `0xC8` bytes when a `0x219`-byte parser allocation fails.
The console's loaded image grew from 2,054,560 to 2,060,208 bytes (5,648 bytes).
This is a current regression; the earlier source candidate's successful 8 MiB
qualification does not qualify this one.

The startup runner now checks `INPUT REJECT` immediately rather than waiting
for an expected framebuffer that cannot appear. Restore the existing 8 MiB
workload before qualifying a replacement image. Review resident code/symbol
footprint and reclaimable memory ownership; do not hide the failure by raising
the declared minimal RAM or weakening the retained-function test. Full desktop
64 MiB and native rebuild 128 MiB budgets remain separate from this gate.

The fail-fast rerun `build/i386-c1-doc-scan-startup-rejection/result.json`
reproduces the same allocation rejection and reports `Guest command rejected`
instead of the earlier framebuffer timeout. The original failed run is retained.

## Minimal-profile recovery checkpoint

The [fixed-buffer allocation work](i386-fixed-buffer-allocation.md) traces the
failure to graphics page-bucket overhead and preserves both 640x480 contexts.
The current candidate passes the nine-command 8 MiB retained-state/VGA gate in
41.95 seconds with zero build-provider loads. Evidence:
`build/i386-c1-exact-buffer-checks/startup-8m/result.json`. This supersedes the
startup regression above; GetStr implementation and full release qualification
remain open.

## Canonical console foundation

[Console transcript integration](i386-console-transcript.md) now gives the main
terminal a task-owned output/display document and prompt markers. Command
submission uses DocScanLine over that document; typed source and ordinary
output are retained. The 8 MiB startup gate still passes. The corrected native
positioning fixture now requires actual X/Y entry types, and the original
reference has matching structural assertions. Structured output and original
DocGetKey/GetStr semantics remain implementation work.

## Expanded input/reference contract

The current pinned-reference runner captures thirteen GetStr results and four
DocScanLine buffers. All seventeen match explicit host byte expectations in
`build/i386-c1-getstr-dollar-reference/result.json`. Added observations are:

| Scripted input before Enter | Returned bytes before NUL |
| --- | --- |
| `abc`, Backspace, `Z` | `abZ` |
| `abc`, three Backspaces; default `fallback` | `fallback` |
| `alpha`, Tab, `beta` | `alpha\tbeta` |
| Two spaces, `alpha`, two spaces | Spaces preserved on both sides |
| `$RED$cash$$` | `cash$` |
| `$$RED$$cash$$$$` | `$RED$cash$$` |
| Bytes `82 A3` in hex | The same two bytes |

These are scripted key-message observations from the original system, not
physical-keyboard qualification. The initial expanded oracle expected literal
single-dollar input and fails in `build/i386-c1-getstr-edit-reference/result.json`.
Inspection of original EdCharIns in Adam/DolDoc/DocChar.HC explains the result:
it buffers a typed dollar command, invokes DocPrint when the command closes,
and treats doubled dollars as one literal dollar. The revised oracle explicitly
tests both paths; the literal-input case is retained separately rather than
removed. Escaping in the reference HolyC file is distinct from the native
runner's interactive command source and is accounted for by each fixture.

`tools/test-i386-getstr.py` contains the matching thirteen native cases. On the
current interface-73 image its helper definition fails with `Invalid lval` at
GetStr (`build/i386-c2-getstr-dollar-red/result.json`), with all input hashes
unchanged. This is a missing-binding red test, not thirteen independent observed
native failures. GetStr, DocGetKey/GetKey echo, typed dollar state and the other
input/recovery behaviors listed above remain implementation/qualification work.

## Typed-dollar prerequisite integrated

[Typed-dollar input](i386-dollar-input.md) now shares the original EdCharIns
state machine with native DocPutKey. Its native suite passes 22 commands,
including partial state, real foreground entries, command/attribute macro
lookup, escaped literals, plain mode and buffer growth. The extended reference
runner now captures nineteen buffers and checks these states on both the
pinned original and the original using the extracted core. Source overrides
are explicit in the shared-mode report. Native fixtures encode dollar bytes
with hex escapes to account for HolyC string literal decoding.

This supplies a document-key prerequisite for GetStr. GetKey/DocGetKey's echo
and prompt path, entry replay, filters, task exit and recovery still require
integration. `build/i386-c2-getstr-byte-red/result.json` rejects the missing
GetStr helper definition on the interface-74 candidate with unchanged input
hashes. It does not exercise thirteen native input cases.


## Execution dependency checkpoint (2026-10-15)

A fresh Console-89 GetStr gate still rejects its helper definition before the
thirteen input cases (`build/i386-c2-getstr-console89-red/result.json`, unchanged
inputs). The implementation dependency audit requires the full DocEntryRun path,
including real popup macros and list/menu selection. [Popup execution](i386-popup-execution.md)
now has a passing shared original core and native ordinary execution gate.
Popup chooser UI, full servant document startup and entry actions remain open;
GetStr itself is not bound or qualified by this dependency pass. Preserve its
original document/filter/Escape semantics rather than substituting a line buffer.

## Original input implementation candidate (2026-10-16)

Console-126 still rejects the missing binding before fixture execution
(build/i386-c2-getstr-console126-red, unchanged inputs). The original wrapper
and complete DocGetStr2 implementation are now extracted byte-for-byte into
Kernel/GetStrCore.HC and Adam/DolDoc/DocGetStrCore.HC. Both original call sites
include the shared bodies. Native integration uses the existing DocGetKey,
DocEntryRun, DocScanLine and document output paths, including the original
Escape replay, multiline extraction and Shift-Escape behavior. The public
fp_getstr2 hook remains overridable; shared input flag definitions are available
to native callers. No replacement line buffer is introduced.

The original and shared-source controls pass all 21 exported byte buffers,
including thirteen scripted input cases, document extraction, an overridden
hook, exact flag forwarding, formatted prompt and fallback after an empty hook
result (build/i386-c2-getstr-hook-declared-reference and -hook-declared-shared).
The initial expanded fixture used a function-pointer initializer unsupported
by the original parser; separating declaration and assignment fixes the fixture.
Bootstrap and the Console-127 cross-build pass. Its first native fixture stops
on an address printed by a top-level hook-save assignment, before input cases;
a void setup helper removes that nondeterministic display expectation.

Unchanged TimeClock compilation advances past GetStr and fails in Install at
DocClear (build/i386-c3-timeclock-getstr-load). DocClear's original implementation
is already compiled in DocRecalcLib; Console-128 adds its missing public binding.
The corrected native GetStr suite, Console-128 build and unchanged application
workflows remain in progress. All inventory qualifications and C1–C5 remain open.

The corrected Console-127 fixture passes all 26 native commands with unchanged
inputs (build/i386-c2-getstr-void-setup-native). Hook replacement, forwarded
flags, formatted prompt/default behavior and all thirteen scripted-input cases
match the original oracle. The Console-128 bootstrap and cross-build pass;
its full GetStr rerun and unchanged TimeClock load/punch/reboot workflows are
running. These remain distinct from physical-keyboard, filter/replay and task-exit
qualification.

Console-128 passes the full 26-command native GetStr suite with unchanged
inputs (build/i386-c2-getstr-docclear-native). Its cross-build matches all 1514
source and 24 build-input hashes. Unchanged TimeClock now passes source
availability, a fresh-install precondition, Load/Install and continuation
arithmetic in four commands (build/i386-c3-timeclock-docclear-load-result).
The harness accounts for the first installation's top-level DirMk result;
the earlier empty-answer expectation is retained as a fixture failure, not an
application rejection. Native punch/storage/reboot checks are running. The
minimal-profile memory gates and full C1–C5 qualification remain open.

The isolated committed f0639b4a image passes all nine 8 MiB startup/storage/VGA
checks in 58.910551 seconds, with no build-provider load and all four execution
pins unchanged (build/i386-c2-getstr-startup). Separate 16 MiB diagnostics are
running from the same source snapshot. The native punch fixture's initial
FileWrite byte-count assumption was incorrect: the API returns an allocation
location. The corrected fixture retains independent exact persisted-byte checks;
all seven command stages and host record checks pass, with cold reboot reopen
still running. A separate deterministic report/reboot run compares the entire
saved DolDoc document against the original 5,400-second report golden.
