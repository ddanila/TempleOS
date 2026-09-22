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
| Help metadata | `MakeDoc.HC` uses `#help_file`; original lexer creates public `HTT_HELP_FILE` source symbols. | Native command input now resolves help paths through the retained file service, creates source/help-index metadata and publishes it transactionally. Repeated entries preserve lookup order and failed inputs reclaim their metadata. The queue header uses its original directive again; see [help metadata](i386-help-metadata.md). Interactive help browsing remains part of DolDoc integration. |
| Document locking | `DocLock`/`DocUnlock` use `Fs`, `Bt`, `LBts`, `LBtr`, `LBEqu`, `Yield`, `BreakLock`, `BreakUnlock`. | Typed `Fs`, the bit intrinsics and callable `BEqu`/`LBEqu` now exist. Shared x64/native vectors cover signed/wide offsets, old-bit returns and neighboring bytes; decoded native instructions verify LOCK on both `LBEqu` branches. See [bit assignment](i386-bit-assignment.md). The original DocLock/DocUnlock ownership policy now has explicit native adapters and retained public bindings, with contention and keyboard-break recovery tests; see [document locks](i386-document-locks.md). The adapters use internal scheduling and cleanup-aware break polling. The full public Yield/Break contract remains separate integration work. |
| Current task documents | DocNew/DocRst and rendering use DocPut; double buffering also uses DocDisplay and DocBorder. | The original selection bodies are shared with retained native exports. Default task selection, document signatures and input-filter parent forwarding have x64/native coverage; see [document selection](i386-document-access.md). These calls borrow existing documents; creation and lifetime ownership remain open. |
| Globals and callbacks | Document creation reads `doldoc.dft_de_flags` and `blkdev.tmp_filename`, and stores `EdLeftClickLink`. | The original global layout and scan codes now have shared headers. Fixed policy tables use a shared initializer checked against the original parser and native table fingerprint; see [document defaults](i386-document-defaults.md). Native startup now publishes the original global and runs DocInit, with all definition/dictionary entries, defaults and temporary dictionary reclamation tested; see [document initialization](i386-document-initialization.md). Retained editor callbacks and document lifecycle integration remain required. |
| Text-base drawing | DocRecalc uses TextChar, TextLenStr, TextLenAttrStr and TextLenAttr, originally x64 assembly. | Retained native bindings preserve cell/clipping behavior, with 256 original-assembly comparisons and 12 shared cases; see [text base](i386-text-base.md). The surface now has retained VGA presentation, with 12 original-renderer frame comparisons and four native VGA captures plus break/heap restoration; see [text rendering](i386-text-rendering.md). Original device-context construction, aliasing, transforms, lighting and depth-buffer ownership now have retained native bindings and shared checks; see [graphics contexts](i386-graphics-context.md). Normal startup now creates the persistent and working framebuffers, and native presentation preserves text/task/persistent/final-callback layering with pixel and recovery tests; see [graphics frames](i386-graphics-frame.md). Original text borders, rectangle fills, scroll save/restore and window geometry now have retained bindings; see [window and text services](i386-window-text.md). Original resizing, control updates/hit testing and visibility now have retained bindings and callback/lifetime recovery checks; see [window services](i386-window-services.md). Sprite drawing, complete control/window-manager integration and full document layout remain open. |
| Reporting and entry lifetime | Entry/binary deletion and validation report invalid state through a shared literal boundary. | Original entry insertion/deletion, binary lifetime and undo cleanup now have retained native bindings. x64 calls RawPrint; native reporting is visible, timed by the PIT and restores IF/display/input-filter state. Original/native lifetime and native invalid-path tests pass; see [entry lifetime](i386-document-entry-lifetime.md). General formatting and full document construction/reset/delete remain open. |
| Files | `DocFile.HC` calls `FileRead` and `FileWrite` and packs/unpacks binary entries. | Connect public file operations to the persistent document workflow; standalone ATA/RedSea fixture success is insufficient. |

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
text insertion, cursor-left, backspace and serialization of the original cursor
byte. The original-x64 round-trip corpus checks the shared loader against original
`DocSave`; native round-trip evidence comes from the separate two-boot acceptance. `tools/test-i386-doldoc-session.py` boots a
writable copy of the normal 8 MiB image, creates and edits `NativeEdit.DD`, writes
it through the native RedSea service, boots that same image again, and verifies
the reopened bytes. It also verifies that the source image was not changed.

The same acceptance now enters retained `DocEd` from the interactive HolyC
prompt and sends hardware keyboard events through QEMU. It verifies the VGA
cursor and text after typing, cursor-left navigation, insertion and backspace,
returns with Escape, saves, reboots, reopens the file in `DocEd`, and returns to
the same live HolyC environment. The accepted first-session key subset is
ordinary printable text, cursor-left, and backspace. Full `DocPutKey`, document
layout, editor callbacks, mouse input, executable-document behavior, and
embedded records remain later DolDoc integration work.

The retained `DocEd` is currently a small native keyboard/render loop, not the
original complete editor. It redraws serialized text on each key and displays the
cursor as an extra block cell. Newlines, tabs, right/up/down navigation, full
recalculation, editor exception cleanup and executing from a document remain
unimplemented. The persistence acceptance covers a root-directory plain-text
file; it does not establish nested-directory or embedded-record compatibility.
