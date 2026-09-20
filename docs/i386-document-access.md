# Original task-document selection

Both x64 rebuild generations, the native exception/task suite and the full native
kernel suite pass. This connects original document selection to native public
CTask and CDoc records; it does not initialize an editor or render a doc.

`Adam/DolDoc/DocAccess.HC` contains the unchanged DocPut, DocDisplay and DocBorder
bodies extracted from DocDblBuf. Original DocDblBuf includes the shared source.
The native console compiles that source with the native Fs intrinsic and retains
its code and three export records for kernel lifetime. PublicDocument.HH exposes
the original signatures, including the default current-task argument. ConsoleRuntime
14 adds `_DOC_PUT`, `_DOC_DISPLAY` and `_DOC_BORDER` alongside document locking.
Its configuration and service table sizes remain unchanged.

DocPut forwards input-filter tasks to their parent's put_doc exactly once.
DocDisplay and DocBorder select the supplied task's own slots. All three reject
missing documents and documents whose signature is invalid. Selection borrows
the document pointer; it neither creates a document nor takes lifetime ownership.
The caller must supply live tasks and readable document records, as in the
original API.

The same eight-case corpus checks default-task equivalence, empty slots, distinct
valid selections, individual signature failures, parent forwarding, rejection of
an invalid parent document, and preservation of child display/border selection.
It runs against original x64 functions, native AOT functions in the exception/task
fixture, and disk-loaded source calling retained native public bindings.

The original platform DocLock/DocUnlock wrappers now live in Adam/DolDoc/DocLock.HC,
loaded by MakeDoc before DocBin. DocNew no longer defines those wrappers, so
native lifecycle integration can use the already published native lock services.
The shared lock policy and native lock implementation are unchanged.

Actual document creation still needs initialized globals, the real editor callback,
reporting, DocTop/DocFormFwd/DocRecalc and binary lifecycle integration. Rendering,
editing, execution and persistent save/reboot/reopen acceptance remain open.

The console corpus covers 166 commands / 229 input lines with exact VGA checks,
including seven hardware hotkey cases, eleven document-lock commands and eight
selection cases. Startup recovery, normal boot with an invalid diagnostic probe,
and all 17 module-rejection cases pass. All 1106 OS source hashes, eight build-input
hashes and both disk hashes match. The normal QEMU preview is refreshed.

ConsoleRuntime 14 retains 91096 bytes from a 91080-byte image. Kernel size stays
363296 bytes, leaving 25824 bytes after the 4096-byte early stage. Normal QEMU/486
boot at 8 MiB measured 15.004 seconds; diagnostics measured 127.368 seconds.
