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
| Public records | `Kernel/KernelA.HH` defines `CDocBin`, `CDocSettings`, `CDocEntryBase`, `CDocEntry`, `CEdFindText`, `CDocUndo`, `CDoc` and supporting records/constants. | `PublicTaskTypes.HH` only forward-declares `CDoc`. Extract shared complete document records with their dependencies; verify original x64 layouts and native layouts before loading them publicly. |
| Allocation | `DocNew.HC` uses `MAlloc`, `CAlloc`, `Free`, `MSize2`, `MAllocIdent`, `StrNew` and `MemCpy`. | These are declared in native `PublicMemory.HH`; validate actual document copy/reset/delete ownership and reclamation, including explicit `doc->mem_task`, rather than treating symbol availability as integration. |
| String operations | `DocEntryNewTag` calls `StrLen`; `DocNew` calls `StrCpy`; binary lookup uses `StrCmp`. | Public `StrCmp` is declared by native `StartOS.HC`. `IC_STRLEN` (0x84) is absent from the native intrinsic validator and backend; `StrCpy` is absent from the native public headers. Internal native compiler/memory length helpers do not publish the original intrinsic contract. |
| Circular queues | `DocNew.HC` and `DocBin.HC` use `QueInit`, `QueIns`, `QueRem`; original public declarations use intrinsic opcodes and `CQue *`. | Queue opcodes are absent from the native intrinsic validator/backend. Implement public target-width links, including the companion `QueInsRev`, with declaration validation and execution checks. |
| Document locking | `DocLock`/`DocUnlock` use `Fs`, `Bt`, `LBts`, `LBtr`, `LBEqu`, `Yield`, `BreakLock`, `BreakUnlock`. | Typed `Fs` and the three bit intrinsics exist. Public `LBEqu`, scheduling and break services still need binding and semantic integration. `I386SchedYield` is an internal service, not automatically the public `Yield` contract. |
| Globals and callbacks | Document creation reads `doldoc.dft_de_flags` and `blkdev.tmp_filename`, and stores `EdLeftClickLink`. | Initialize real globals and retain callback code for document lifetime; supplying zero-filled placeholders does not fulfill document semantics. |
| Reporting | `DocEntryDel` and binary validation use `RawPrint` on invalid state. | Provide the real reporting path and its formatting/timing dependencies; a silent stub would conceal integration failures. |
| Files | `DocFile.HC` calls `FileRead` and `FileWrite` and packs/unpacks binary entries. | Connect public file operations to the persistent document workflow; standalone ATA/RedSea fixture success is insufficient. |

## Two semantic hazards to resolve explicitly

`BreakUnlock` in `Kernel/KExcept.HC` delivers pending breaks. For another task,
the original implementation changes `task->rip`; for the current task it calls
`Break`, which also releases device state and resets message/wait state. Merely
publishing the complete `CTask` layout does not make those effects work in the
native scheduler. Test pending-break delivery and document unlock together,
including a task waiting for a document lock and exception cleanup.

`DocFile.HC` serializes only the span between `CDocBin.start` and `CDocBin.end`,
followed by payload bytes. That span contains four U32 fields (16 bytes), while
the surrounding in-memory record contains pointers. Preserve this fixed-width
span independently of native record size. Verify cross-architecture saved-file
fixtures and embedded graphics before claiming persistence compatibility; do not
serialize the entire native record or simply remove its layout assertions.

## Implementation order and acceptance

1. Add the public `StrLen` intrinsic and string-copy binding. Cover empty and
   embedded-terminator strings, interior pointers, high-bit bytes, long strings,
   nested calls and single evaluation of side effects. Verify malformed intrinsic
   declarations are rejected without damaging published definitions. Compare
   with original x64 behavior, including register/flag conventions.
2. Add queue intrinsics and shared document records. Exercise empty, singleton
   and multi-entry queues, insertion in both directions and removal, validating
   both links and memory around the native four-byte pointer fields. Preserve
   x64 record layouts and verify native class completion through public headers.
3. Connect the remaining lifecycle dependencies above and execute original
   document creation, entry insertion/copy, reset and deletion. Measure heap
   ownership and repeated-cycle reclamation. Use failed allocation and lock/break
   cases to verify recovery before the editor depends on these services.
4. Integrate actual document rendering/input and execution, then public file
   persistence: edit, execute, save, reboot, reopen and execute again at 8 MiB.
   Include embedded graphics and document handler registration. Measure memory
   peaks and input responsiveness throughout, then apply the M7 hardware gates.

Bootstrap headroom is a concurrent constraint: the last tested kernel plus early
stage leaves only 192 bytes in the fixed reservation. Keep new document/runtime
code in extended-memory modules; any necessary resident additions must first
make room deliberately and retain module rejection/lifetime tests. Preserve
normal interactive boot independently of diagnostic probes.
