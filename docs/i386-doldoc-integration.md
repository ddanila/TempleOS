# Native DolDoc integration dependencies

This is a source inspection of the current native boundary, not evidence that
DolDoc compiles or runs on i386. It directs the next M4/M5 changes toward the
existing implementation in `Adam/DolDoc/MakeDoc.HC`. Keep that implementation;
do not introduce a replacement document format or reduced editor.

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
| Public records | `Kernel/DocTypes.HH`, included by KernelA and native PublicKernel, defines all eight original document/editor records and their constants. | All 131 original x64 fields are preserved. Native layout assertions and a shared wide-field/callback/binary-span corpus cover the complete records. CDirContext remains opaque; palette constants referenced by color aliases still need native publication. Connect the original document services to these records; see [document layouts](i386-document-records.md). |
| Allocation | `DocNew.HC` uses `MAlloc`, `CAlloc`, `Free`, `MSize2`, `MAllocIdent`, `StrNew` and `MemCpy`. | These are declared in native `PublicMemory.HH`; validate actual document copy/reset/delete ownership and reclamation, including explicit `doc->mem_task`, rather than treating symbol availability as integration. |
| String operations | `DocEntryNewTag` calls `StrLen`; `DocNew` calls `StrCpy`; binary lookup uses `StrCmp`. | Public `StrCmp` is declared by native `StartOS.HC`. `StrLen` (opcode 0x84) now has native lowering, public startup publication and x64/native execution tests. `StrCpy` now binds the retained native routine with original null-input, void-return and direction-flag semantics; its shared behavioral corpus passes on x64 and native boot/worker tasks. |
| Circular queues | `DocNew.HC` and `DocBin.HC` use `QueInit`, `QueIns`, `QueRem`; original public declarations use intrinsic opcodes and `CQue *`. | The canonical `CQue` record is now shared through `Kernel/QueueTypes.HH` and loaded by native public headers (8 bytes native, 16 bytes x64). All four queue opcodes, including `QueInsRev`, now validate the public signature and update four-byte native links. A shared original-x64/cross-generated/native corpus checks both directions, removal and neighboring memory. Actual document ownership integration remains open. |
| Help metadata | `MakeDoc.HC` uses `#help_file`; original lexer creates public `HTT_HELP_FILE` source symbols. | Native command input now resolves help paths through the retained file service, creates source/help-index metadata and publishes it transactionally. Repeated entries preserve lookup order and failed inputs reclaim their metadata. The queue header uses its original directive again; see [help metadata](i386-help-metadata.md). Interactive help browsing remains part of DolDoc integration. |
| Document locking | `DocLock`/`DocUnlock` use `Fs`, `Bt`, `LBts`, `LBtr`, `LBEqu`, `Yield`, `BreakLock`, `BreakUnlock`. | Typed `Fs`, the bit intrinsics and callable `BEqu`/`LBEqu` now exist. Shared x64/native vectors cover signed/wide offsets, old-bit returns and neighboring bytes; decoded native instructions verify LOCK on both `LBEqu` branches. See [bit assignment](i386-bit-assignment.md). Public scheduling and break services still need binding and semantic integration. `I386SchedYield` is an internal service, not automatically the public `Yield` contract. |
| Globals and callbacks | Document creation reads `doldoc.dft_de_flags` and `blkdev.tmp_filename`, and stores `EdLeftClickLink`. | Initialize real globals and retain callback code for document lifetime; supplying zero-filled placeholders does not fulfill document semantics. |
| Reporting | `DocEntryDel` and binary validation use `RawPrint` on invalid state. | Provide the real reporting path and its formatting/timing dependencies; a silent stub would conceal integration failures. |
| Files | `DocFile.HC` calls `FileRead` and `FileWrite` and packs/unpacks binary entries. | Connect public file operations to the persistent document workflow; standalone ATA/RedSea fixture success is insufficient. |

## Two semantic hazards to resolve explicitly

The [public live-task ring](i386-public-task-ring.md) now tracks attached tasks,
including blocked workers. Native dispatch now follows public list order and
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
native scheduler. Test pending-break delivery and document unlock together,
including a task waiting for a document lock and exception cleanup.
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
wait selection now has task-owned registrations for sleep and join; see
[task wait registration](i386-task-wait-registration.md). Registration of the
other wait types and cleanup before exception delivery remain required.

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

Bootstrap headroom is a concurrent constraint: the kernel plus early
stage leaves 1128 bytes in the fixed reservation after jiffy/wake-time integration
(5000 after task-flag eligibility, 5944 after moving source/lexer diagnostics).
See [storage diagnostics](i386-storage-diagnostics.md). Keep new document/runtime
code in extended-memory modules; any necessary resident additions must first
make room deliberately and retain module rejection/lifetime tests. Preserve
normal interactive boot independently of diagnostic probes.
