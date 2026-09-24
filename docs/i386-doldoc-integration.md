# Native DolDoc integration dependencies

This records the original integration boundary and subsequent native progress.
A limited ordinary-text editor now runs on i386 using canonical document records;
the full original `Adam/DolDoc/MakeDoc.HC` integration remains the target. The
prototype below is an intermediate step, not completion of the medium goal.

## Medium goal: first usable native editing session

Acceptance requires a normal native i386 boot on the 8 MiB QEMU development
profile into an environment using the original DolDoc editor. The user must be
able to type a small HolyC program, execute it and see the output, recover from
a syntax error, and interrupt a running program without losing the editing
session. Save the document to RedSea, shut down and reboot the same disk, reopen
it and execute it again. Verify persisted contents and measure peak memory,
normal boot time and input responsiveness. Normal boot must not run the
long diagnostic suite.

Implement in three connected stages: safe interruption and resource cleanup;
original document lifecycle, rendering and editing integration; then persistent
save/reboot/reopen acceptance. Use the original document representation and
editor code throughout. Component tests and the current line-oriented console
are supporting evidence, not completion of this goal. Full M5/M7 graphics,
help, sound and physical-machine acceptance remain part of the overall port.

## First source boundary

`MakeDoc.HC` declares `CDolDocGlbls`, initializes `doldoc`, then includes
`DocExt`, `DocBin`, `DocNew`, and the remaining document/editor units. Its final
registration installs document keyboard/output handlers through `KeyDevAdd`,
`fp_getstr2` and `fp_doc_put`. Loading a few document routines does not establish
that the console has become a DolDoc terminal.

`DocNew.HC` is the initial ownership/lifecycle target, but cannot be loaded in
isolation without its real dependencies. In particular, `DocNew` installs
`EdLeftClickLink`, `DocRst` calls `DocTop`, default-document operations use
`DocPut`, and binary entry deletion uses `DocBinDel`. `DocBin.HC` in turn reaches
`DocRead` and `DocDel`. Preserve forward declarations and link the actual
implementations as their dependency groups become available.

| Boundary | Evidence in existing source | Current native gap / next gate |
| --- | --- | --- |
| Public records | `Kernel/DocTypes.HH`, included by KernelA and native PublicKernel, defines all eight original document/editor records and their constants. | All 131 original x64 fields are preserved. Native layout assertions and a shared wide-field/callback/binary-span corpus cover the complete records. CDirContext remains opaque; original color/palette declarations are now shared through the graphics-context header. Connect the original document services to these records; see [document layouts](i386-document-records.md). |
| Allocation | `DocNew.HC` uses `MAlloc`, `CAlloc`, `Free`, `MSize2`, `MAllocIdent`, `StrNew` and `MemCpy`. | These are declared in native `PublicMemory.HH`; validate actual document copy/reset/delete ownership and reclamation, including explicit `doc->mem_task`, rather than treating symbol availability as integration. |
| String operations | `DocEntryNewTag` calls `StrLen`; `DocNew` calls `StrCpy`; binary lookup uses `StrCmp`. | Public `StrCmp` is declared by native `StartOS.HC`. `StrLen` (opcode 0x84) now has native lowering, public startup publication and x64/native execution tests. `StrCpy` now binds the retained native routine with original null-input, void-return and direction-flag semantics; its shared behavioral corpus passes on x64 and native boot/worker tasks. |
| Circular queues | `DocNew.HC` and `DocBin.HC` use `QueInit`, `QueIns`, `QueRem`; original public declarations use intrinsic opcodes and `CQue *`. | The canonical `CQue` record is now shared through `Kernel/QueueTypes.HH` and loaded by native public headers (8 bytes native, 16 bytes x64). All four queue opcodes, including `QueInsRev`, now validate the public signature and update four-byte native links. A shared original-x64/cross-generated/native corpus checks both directions, removal and neighboring memory. Actual document ownership integration remains open. |
| Help metadata | `MakeDoc.HC` uses `#help_file`; original lexer creates public `HTT_HELP_FILE` source symbols. | Native command input resolves help paths through the retained file service, creates source/help-index metadata and publishes it transactionally. Repeated entries preserve lookup order and failed inputs reclaim their metadata. The native disk includes the original `Doc` tree, and public `Help(name)` provides read-only VGA paging of common titles, links and labels without rewriting lossy projections. Keyboard selection follows direct `FI:`, `FA:`, `FF:` and `FL:` file links with nested return; `MN:` resolves published native symbols through retained source links, `FL:` begins at its one-based line, `FF:` begins at its requested text occurrence, and `FA:` maps an invisible anchor to the visible projection. `HI:` builds a live selectable listing from every public help-file registration and source-linked symbol whose semicolon-delimited index contains the exact category. Full original help layout remains open; see [help metadata](i386-help-metadata.md). |
| Document locking | `DocLock`/`DocUnlock` use `Fs`, `Bt`, `LBts`, `LBtr`, `LBEqu`, `Yield`, `BreakLock`, `BreakUnlock`. | Typed `Fs`, the bit intrinsics and callable `BEqu`/`LBEqu` now exist. Shared x64/native vectors cover signed/wide offsets, old-bit returns and neighboring bytes; decoded native instructions verify LOCK on both `LBEqu` branches. See [bit assignment](i386-bit-assignment.md). The original DocLock/DocUnlock ownership policy now has explicit native adapters and retained public bindings, with contention and keyboard-break recovery tests; see [document locks](i386-document-locks.md). The adapters use internal scheduling and cleanup-aware break polling. The full public Yield/Break contract remains separate integration work. |
| Current task documents | DocNew/DocRst and rendering use DocPut; double buffering also uses DocDisplay and DocBorder. | The original selection bodies are shared with retained native exports. Default task selection, document signatures and input-filter parent forwarding have x64/native coverage; see [document selection](i386-document-access.md). These calls borrow existing documents; creation and lifetime ownership remain open. |
| Globals and callbacks | Document creation reads `doldoc.dft_de_flags` and `blkdev.tmp_filename`, and stores `EdLeftClickLink`. | The original global layout and scan codes now have shared headers. Fixed policy tables use a shared initializer checked against the original parser and native table fingerprint; see [document defaults](i386-document-defaults.md). Native startup now publishes the original global and runs DocInit, with all definition/dictionary entries, defaults and temporary dictionary reclamation tested; see [document initialization](i386-document-initialization.md). Retained editor callbacks and document lifecycle integration remain required. |
| Text-base drawing | DocRecalc uses TextChar, TextLenStr, TextLenAttrStr and TextLenAttr, originally x64 assembly. | Retained native bindings preserve cell/clipping behavior, with 256 original-assembly comparisons and 12 shared cases; see [text base](i386-text-base.md). The surface now has retained VGA presentation, with 12 original-renderer frame comparisons and four native VGA captures plus break/heap restoration; see [text rendering](i386-text-rendering.md). Original device-context construction, aliasing, transforms, lighting and depth-buffer ownership now have retained native bindings and shared checks; see [graphics contexts](i386-graphics-context.md). Normal startup now creates the persistent and working framebuffers, and native presentation preserves text/task/persistent/final-callback layering with pixel and recovery tests; see [graphics frames](i386-graphics-frame.md). Original text borders, rectangle fills, scroll save/restore and window geometry now have retained bindings; see [window and text services](i386-window-text.md). Original resizing, control updates/hit testing and visibility now have retained bindings and callback/lifetime recovery checks; see [window services](i386-window-services.md). Sprite drawing, complete control/window-manager integration and full document layout remain open. |
| Reporting and entry lifetime | Entry/binary deletion and validation report invalid state through a shared literal boundary. | Original entry insertion/deletion, binary lifetime and undo cleanup now have retained native bindings. x64 calls RawPrint; native reporting is visible, timed by the PIT and restores IF/display/input-filter state. Original/native lifetime and native invalid-path tests pass; see [entry lifetime](i386-document-entry-lifetime.md). General formatting and full document construction/reset/delete remain open. |
| Files | `DocFile.HC` calls `FileRead` and `FileWrite` and packs/unpacks binary entries. | Native `Ed`, `DocRead`/`DocWrite`, nested creation and `Dir(path)` now provide a persistent edit and browse workflow over the task-owned RedSea service. `EdDir(path)` adds a VGA keyboard picker that descends into directories, returns to the parent, opens and creates files through `Ed`, renames files or directories within one parent, and deletes regular files or empty directories after an explicit `Y/N` confirmation. Public `FileMove` copies a regular file between directories on one volume. Its checksummed volume-header intent and mount recovery produce exactly one complete name across all seven write and six flush interruptions, with exact bitmap ownership. Copy-on-write replacement preserves exact old or new bytes across all four write and three flush interruptions. Nonempty directories are protected and each picker mutation refreshes the listing. Bidirectional original/native document loading now passes for the implemented structured/binary subset. Cross-parent directory moves, broader DolDoc command compatibility and the original interactive file browser remain open. |

## Formatting dependency progress

The original list/definition lookup group is now shared and retained natively:
`LstSub`, `LstMatch`, `Define`, `DefineSub`, `DefineCnt` and `DefineMatch`.
See [definition lookup](i386-definition-lookup.md). This closes the definition
substitution dependency of `StrPrintJoin`, including inherited tables and
`UndefDef` recovery. Its numerical helpers now have retained public bindings,
including software rounding, logarithms, powers of ten and original integer
multiples; see [public numerical providers](i386-public-math.md). Calendar
conversion and the writable time offset now also have retained native bindings,
with 1333 native checks; see [calendar conversion](i386-date-conversion.md).
Full formatting still needs file/document serialization,
address-to-symbol formatting and the output boundary. These dependencies must be
connected to their actual providers before publishing a complete formatter or
claiming that `DocDataFmt` and `DocRecalc` are integrated. `StrPrintJoin` calls
`DocSave` for document substitution, while `DocSave` calls `DocRecalc`, which
uses `DocDataFmt` and formatting. Integrate this cycle with real providers;
do not break it with placeholder serialization or recalculation.

The first foreground-record attempt emitted only `red` from
`$FG,2$red$FG$ plain`. Retained statement case 34 ruled out generic generated
circular-queue traversal. A numeric-byte fixture then exposed the actual fault:
`DocEntryNewBase` allocates the short `CDocEntryBase`, while an entry containing
`attr` requires the full `CDocEntry` used by the original parser. Writing the
foreground attribute into the short record overwrote allocator metadata.

The corrected native path allocates full color records and now supports
`DOCT_FOREGROUND` and `DOCT_BACKGROUND` values 0 through 15 plus `DOC_DFT`, and
boolean `DOCT_INVERT`/`DOCT_UNDERLINE` records. Its isolated check performs an
exact save, structured load and second save of a 76-byte color/style fixture,
verifies heap balance, and remains part
of the twelve-result `DocAllocationCheck`. Public
`DocSave` and `DocRead` now use this record-aware path; literal dollar bytes are
escaped and restored. The native editor walks canonical entries and applies each
color and style changes to subsequent VGA glyphs, including restoration of the
document defaults. Both rebuild generations and the focused QEMU/486 8 MiB gates
pass. Other DolDoc commands, embedded binary payloads and cross-architecture
saved-file compatibility remain open.

## Two semantic hazards to resolve explicitly

The [public live-task ring](i386-public-task-ring.md) now tracks attached tasks,
including blocked workers. Native document locks now share the original policy through explicit platform callbacks.
Native dispatch now follows public list order and
skips blocked, suspended and awaiting-message tasks, independently of private
wakeup insertion order. All-ineligible selection idles for an IRQ. Integrating
public `Yield` still requires original message/job/popup services and break
handling before publishing its original callable contract. Wake deadlines now use
the [shared jiffy clock](i386-jiffy-clock.md);
see [task eligibility](i386-task-eligibility.md).

`BreakUnlock` in `Kernel/KExcept.HC` delivers pending breaks. For another task,
the original implementation changes `task->rip`; for the current task it calls
`Break`, which also releases device state and resets message/wait state. Merely
publishing the complete `CTask` layout does not make those effects work in the
native scheduler. The native document adapter now tests pending-break delivery after document
unlock, interruption of a contending waiter, and exception cleanup. This does
not yet implement the full public BreakUnlock contract for arbitrary tasks.
Queued ATA acquisitions now have an explicit cancellation path through retained
FileRuntime; see [ATA wait cancellation](i386-ata-wait-cancellation.md). It detaches
the stack waiter and resumes acquisition with failure, leaving granted owners
alone. Before delivering Break, coordinate sleep/join/message waits and let file
and compiler references unwind; removing one queue entry does not make an
arbitrary context jump safe. Native sleep and join cancellation now detach their
waiters safely, including a target reaped before a cancelled join resumes; see
[sleep/join cancellation](i386-sleep-join-cancellation.md). The coordinated
public Break path and message/job/popup behavior still need integration. Pending
message reads now also detach safely without consuming queued data; see
[message-read cancellation](i386-message-read-cancellation.md). Raw keyboard
waits also have a cancellation primitive through the retained console service;
see [keyboard-read cancellation](i386-keyboard-read-cancellation.md). Coordinated
wait selection now has task-owned registrations for sleep, join, queued ATA
acquisitions and message reads; see
[resource wait registration](i386-resource-wait-registration.md). Raw-keyboard
registration now uses the same dispatcher; see
[keyboard wait registration](i386-keyboard-wait-registration.md). An internal
[pending-break checkpoint path](i386-pending-break-checkpoints.md) now has native
exception coverage. Compiler input now has a protected
[break cleanup boundary](i386-compiler-break-cleanup.md). The [queued-file break path](i386-file-break-cleanup.md) exercises a real
borrowed file context through cancellation and compiler recovery. An [IRQ-side keyboard request path](i386-keyboard-break-requests.md) now targets
active console submissions. [Generated loop checkpoints](i386-loop-break-checkpoints.md)
now interrupt native while/goto/do-while loops and allow a HolyC handler to catch
the break. Uninstrumented non-returning calls, multi-task focus and original
public Break delivery remain required.

`DocFile.HC` serializes only the span between `CDocBin.start` and `CDocBin.end`,
followed by payload bytes. That span contains four U32 fields (16 bytes), while
the surrounding in-memory record contains pointers. Preserve this fixed-width
span independently of native record size. Verify cross-architecture saved-file
fixtures and embedded graphics before claiming persistence compatibility; do not
serialize the entire native record or simply remove its layout assertions.

## Implementation order and acceptance

1. **String primitives implemented.** Public `StrLen` and `StrCpy` now have native
   bindings and original-x64 comparisons. Keep their regression coverage while
   integrating document callers; see [intrinsic publication](i386-intrinsic-publication.md)
   and [public memory/string services](i386-public-memory.md). This does not yet
   demonstrate original document creation or copying.
2. **Queue primitives and shared document records implemented.** Shared `CQue`
   layouts and all four operations preserve original behavior. Complete document
   records now share one header, with original x64 layouts and a fixed native
   contract. Native `#help_file` metadata supplies the directive needed by MakeDoc,
   with ownership and rollback. Keep these checks while integrating real callers.
3. Connect the remaining lifecycle dependencies above and execute original
   document creation, entry insertion/copy, reset and deletion. Measure heap
   ownership and repeated-cycle reclamation. Use failed allocation and lock/break
   cases to verify recovery before the editor depends on these services.
4. Integrate actual document rendering/input and execution, then public file
   persistence: edit, execute, save, reboot, reopen and execute again at 8 MiB.
   Include embedded graphics and document handler registration. Measure memory
   peaks and input responsiveness throughout, then apply the M7 hardware gates.

Bootstrap headroom remains a constraint: retaining task-context keyboard reading
and decoding in ConsoleRuntime leaves 25824 bytes in the fixed reservation
after document-lock integration,
compared with 368 bytes before that move.
See [storage diagnostics](i386-storage-diagnostics.md). Keep new document/runtime
code in extended-memory modules; any necessary resident additions must first
make room deliberately and retain module rejection/lifetime tests. Preserve
normal interactive boot independently of diagnostic probes.

### Native lifecycle progress

The first part of step 3 is now executable. `DocNew`, `DocRst`, `DocDel`, and
`DocSize` are retained public i386 services using the canonical `CDoc`, entry,
undo, and binary records and task-owned heaps. The shared `DocLifecycleCheck`
runs against both the original x86-64 implementation and the retained native
implementation. It creates a named document, verifies its queues and editor
buffers, inserts a tagged text entry, measures it, resets and reuses it, then
deletes it and checks bounded heap growth. The original recalc path lazily
retains a 48-byte cache; the native lifecycle itself returns to its starting
heap use.

This does not yet make the line console a DolDoc editor. The next TDD increment
now exercises the canonical document through retained `DocPutKey`, `DocSave`,
`DocWrite`, and `DocRead` services. Shared original/native checks cover plain
text insertion, newline insertion, cursor-left, backspace across a line boundary,
line joining and serialization of the original cursor byte. The original-x64
round-trip corpus checks the shared loader against original
`DocSave`; native round-trip evidence comes from the separate three-boot acceptance. `tools/test-i386-doldoc-session.py` boots a
writable copy of the normal 8 MiB image, creates and edits `NativeEdit.DD`,
`NativeMulti.DD`, `NativeNavigation.DD`, `NativeVertical.DD`, and
`NativeBoundary.DD`, writes them through the native RedSea service, boots that same
image again, and verifies the reopened bytes. It also creates a multiline
`NativeProgram.HC`, executes and saves it through F5, reboots, changes its result
from `42` to `48`, replaces it through F5, then reboots and executes the saved
revision. The source image is never changed.

The acceptance also calls public `DirMk` for `C:/Project` and `C:/Project/Sub`,
saves and executes `C:/Project/Sub/Main.HC` as `49`, and reopens and executes that
nested file on the third boot. File writes now hold the task-owned ATA session
while resolving the parent and mutating its directory.
It separately creates `Project/Sub/Relative.HC`, saves and executes it as `64`,
then reopens it with the same relative spelling after reboot. The document keeps
the spelling supplied by the user while storage resolves it under the C-drive
project tree.

The same acceptance now enters retained `DocEd` from the interactive HolyC
prompt and sends hardware keyboard events through QEMU. It verifies the VGA
cursor and text after typing, multiline and horizontal navigation, insertion and deletion,
returns with Escape, saves, reboots, reopens the file in `DocEd`, and returns to
the same live HolyC environment. The accepted key subset is ordinary printable
text, Enter/newline, Backspace, all four arrows, Home/End, Delete, Tab, Ctrl-K/U/Z
and their Shift reset forms for blink/underline/invert. Blink is driven by the
kernel jiffy pointer in the console service contract and redraws both phases
while the editor is idle. Full `DocPutKey`, document
layout, editor callbacks, mouse input, the original `ExeDoc` path, and most
embedded records remain later DolDoc integration work. Color, inversion and
underline records now survive native save and reopen and render through the small editor.

The retained `DocEd` is currently a small native keyboard/render loop, not the
original complete editor. It walks supported canonical entries on each key and
displays the cursor as an extra block cell. Full
recalculation and whole-editor exception cleanup remain unimplemented. Retained
`DocExe` serializes the locked canonical document with `DOCF_NO_CURSOR`, restores
the original flags on every path, copies its filename, releases the document
lock, and passes the owned source snapshot to the same compiler input used by the
live console. Releasing the lock before execution is required so Ctrl+Alt+C can
deliver `Break`; document locks deliberately defer breaks. Native `DocEd` binds
F5 to this service and keeps the result or diagnostic visible until Escape. It is
an i386 adapter and does not yet replace the original `ExeDoc`/editor action path. The persistence acceptance
covers five root-directory plain-text files, executable root and nested source
files, root-directory growth and two created project directories. A separate
host-side walk validates exact parent links, unique reachable extents and the
allocation bitmap. The structured subset round-trips `FG`, `BG`, `BK`, `IV` and
`UL` records. It now also preserves one bounded canonical sprite reference,
`$SP,"tag",BI=n$`, and the original fixed 16-byte `CDocBin` trailer followed by
its arbitrary payload. In-memory and RedSea tests cover validation/renumbering,
entry-to-payload linkage, exact second serialization, truncation and allocation
failure cleanup. This does not yet establish general embedded-record
compatibility. The original x64
`DocSave` now produces a text, sprite-reference and binary-payload fixture during
the real cross-build; that exact export is packaged into RedSea and the native
`DocRead`/`DocSave` path reproduces all 48 bytes on an 8 MiB QEMU/486 boot.
In the reverse direction, native i386 persists its 37-byte binary fixture to a
writable RedSea image, an independent host walk extracts it, and original x64
`DocRead` validates its live records before `DocSave` reproduces every byte.
This closes bidirectional cross-reading for the implemented subset. A following bounded renderer
now consumes original `SPT_COLOR`, `SPT_PT`, `SPT_LINE` and `SPT_RECT` payloads,
clips them to the 640x480 surface, and composes them over the editor text. A
RedSea save/reopen fixture proves an exact 16x8 red rectangle on VGA. This is a
small interpreter, not full `Sprite3` or original `DocRecalc` placement.

Native `DocEd` also binds original Ctrl-S directly to `DocWrite`. The editor
heading displays `Saved` or `Save failed` without leaving the document; the next
edit clears the status. The integrated check reopens exact saved bytes, while a
missing-parent case verifies failure visibility and continued in-memory editing.

The retained file-level `Ed(path)` service now supplies the normal interactive
workflow around those lower-level calls. It loads an existing document or creates
one at the requested path, interprets Escape as accept-and-save, and interprets
Shift-Escape as discard. This matches the original split between `DocEd` and its
file-editor caller while keeping the native subset explicit.

The retained renderer now measures the canonical cursor before drawing and
clips document output to the 56 text rows below its fixed heading. It expands
tabs and word-wrap behavior consistently in both passes, so vertical navigation
in a document longer than the screen selects a new viewport without invoking the
terminal's whole-screen scroll. When word wrap is disabled, it also selects an
80-column horizontal viewport around the canonical cursor. Original `DocRecalc`
and embedded layout remain open.

The native ordinary-text core now accepts Page Up and Page Down using the
56-row editor body: each key moves 55 logical lines while preserving the target
column and respecting document boundaries. A 65-line hardware/VGA case moves
from line 63 to line 08 and back to line 63 with exact fixed-heading frames.

Hardware-keyboard acceptance now covers the execution recovery sequence inside
one editor session: F5 reports a syntax error, the document is corrected and
returns `42`; a thrown runtime exception returns to the unchanged document and a
corrected source runs; and a program that emits a runtime marker and loops is
interrupted with Ctrl+Alt+C. The prompt remains usable afterward. The saved
multiline program is executed through F5 before writing and through F5 again
after reboot. A separate F5 source checks software-F64 display with
`1.5+2.25;` returning `3.75`.

Compiler diagnostics now retain the current token's one-based line and source
filename. When F5 fails in the document being edited, Escape places the cursor
at the first byte of that line. The acceptance starts on line 3, reports a
missing expression on line 2, verifies the exact cursor frame, replaces that
line and reruns the document to produce `1`, `42` and `3`.

Native `DocEd` now implements the original plain-F1 help action and its Shift-F1
About variant. Both use the packaged read-only help viewer. The hardware test
opens the Help Index from an unsaved edit, exits it, and compares the restored
editor text and cursor at exact VGA-pixel level before saving later in the same
session.

F4 connects `DocEd` to the native picker at the current document's parent
directory and inserts the selected absolute filename at the canonical cursor.
Shift-F4 selects and inserts a directory path. Each path is inserted through
`DocPutKey` under one undo snapshot; Escape redraws the original document
without changing its unsaved state or cursor. Standalone `EdDir` continues to
use the same browser for nested editing and project mutations.

The native editor now supports Ctrl-F search plus forward F3 and reverse
Shift-F3 repeat. Because ordinary typing can leave adjacent canonical text
entries, the search builds a temporary logical stream with an entry/column map
rather than assuming one record per word. Matches wrap in both directions and
move only the cursor; the canonical queue and serialized bytes are unchanged.
An absent query leaves that cursor in place and displays `Not found`. Temporary
projection allocation exceptions are caught inside the search operation so its
buffers and document lock are released without terminating `DocEd`.

Tab from the Ctrl-F search field now opens a bounded replacement field. Enter
finds the next match and replaces it through the shared canonical editing
primitive, leaving the cursor after the inserted text. The hardware/VGA case
checks both fields and the modified document. Replace-all, interactive
replace/skip choices, search options and selection-scoped replacement remain
future original-editor integration.

The native editor also captures up to sixteen canonical snapshots before text,
deletion, style and replacement mutations. Alt-Backspace restores that snapshot
through the same structured document loader, including the serialized cursor and
embedded records, then consumes it. Snapshot publication is failure-atomic; a
seventeenth undo point evicts the oldest complete snapshot, and editor exit
releases the stack. Consecutive insertion, Backspace and Delete runs coalesce
within a one-second window; a different operation, cursor movement, command or
longer pause starts a new undo point. The exact VGA test proves both a single
undo for a typed word and distinct undo states across the timeout.

Shift-Left and Shift-Right now create canonical selections. The shared editing
core splits text records failure-atomically at character boundaries, marks the
selected records with `DOCET_SEL`, and clears or deletes the span for ordinary
navigation, typing, Backspace and Delete. The VGA renderer displays selected
records with inverted foreground/background colors. Reversing horizontal Shift
movement toggles the traversed character back out, allowing an overshot
selection to contract. At that point, vertical line-wise selection remained open.

Ctrl-Shift-Up and Ctrl-Shift-Down now select from an exact canonical cursor
boundary to the document start or end. They split a partial text record before
marking the traversed records, allowing whole-file copy, cut, paste and typing
without changing the persistent representation. At that point, vertical
line-wise selection remained open.

Shift-Up and Shift-Down now preserve the current visual column while moving one
line and mark the complete canonical range between the old and new cursor
boundaries, including intervening newline records. Typing, deletion and the
clipboard therefore consume the selected multiline span. Reversible vertical
movement toggles the same canonical range out of the selection. Shift-Page-Up
and Shift-Page-Down apply the same reversible range selection across 55 lines
while preserving the visual column.

Ctrl-C, Ctrl-X and Ctrl-V now operate on those selected records. Copy constructs
a complete replacement clipboard before releasing the previous one and clears
the source selection; cut copies before deleting; paste copies clipboard records
at a canonical text boundary. Paste first serializes and reloads the clipboard
into a temporary canonical document, completes every allocation and cursor
split, and only then splices its entries and binary records into the target.
Every injected allocation failure preserves exact target bytes and heap usage.
The clipboard survives editor sessions in the native console task. Cut and
paste capture the editor undo point first.

Ctrl-G now provides a native one-based line prompt. It walks the canonical text
and newline entries, positions at the first editable byte of a valid line, and
preserves the cursor with a visible `Line not found` status for an invalid line.

The retained ordinary-text path now has deterministic allocation-failure
coverage. A private injector fails an exact document allocation while normal
calls continue through the public task heap. The native check covers all three
`DocNew` allocations, both allocations needed for the first text entry, replacing
existing text, creating a newline and allocating the serialized result. Partial
objects are reclaimed, `DocLock` is released, document bytes remain unchanged,
heap use returns to its baseline, and a later edit/save succeeds. The injector is
called only by the focused test group and does not run during normal startup.
`DocRead` now catches load-time exceptions, frees its owned disk buffer and
deletes the partial document. The check writes a real RedSea fixture, injects a
failure during its first loaded entry, verifies exact heap balance, then reopens
and serializes the same file successfully. Failure-atomic file replacement and
the complete original editor dependency graph remain open.
