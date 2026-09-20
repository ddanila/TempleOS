# Original entry allocation and form navigation on i386

Current integration uses [retained document services](i386-retained-document-services.md);
the source-loading measurements below record the earlier integration stage.

Native startup loads DocEntryAlloc.HC and
DocFormNav.HC after the original DocInit. These are extracted original bodies,
shared with DocNew.HC and DocForm.HC on x64, rather than replacements for DocNew
or the editor. The preserved functions are IsEditableText, DocEntryNewBase,
DocEntryNewTag, DocEntrySize, DocEntryCopy, DocFormFwd and DocFormBwd.

Entry allocation uses doc->mem_task, the original default flags and original
settings. Copying preserves allocated entry size, duplicates owned auxiliary
storage, detaches entry links and creates a separately owned binary entry with
the destination document's next binary number. Size accounting retains original
semantics: DocEntrySize does not include separately tracked document binaries.
Form navigation uses the initialized original form-type bitmap, link and skip
flags, sentinel recovery and original indentation handling.

Tests use initialized public CDoc/CDocEntry/CDocBin records to exercise these
services. They deliberately do not claim DocNew, DocRst or DocDel integration.
The allocation corpus checks text contents/settings, independent copies, binary
numbering and queue insertion, task-heap ownership, size accounting and complete
reclamation after releasing its known allocations. The navigation corpus covers
forward/backward traversal, indentation, forms, skipped entries, links and the
empty-eligible-set fallback. Both corpora run in original x64 and native source.

The original allocation/copy exception behavior is unchanged: this slice does
not establish transactional cleanup for every partially copied entry on OutMem.
Actual entry deletion and document reset still require the real binary-deletion
and reporting paths. DocTop additionally needs DocRecalc, and DocNew stores the
real EdLeftClickLink callback. These dependencies remain required before exposing
full document creation and connecting the original editor.

## Validation and remaining cost

All extracted function bodies match the previous original source exactly. Both
x64 rebuild/reboot generations and the full native QEMU/486 8 MiB suite pass.
Each shared entry-allocation and form-navigation corpus returns eight cases in
both original x64 and native execution. The prompt suite passes 176 commands /
239 lines, seven hardware breaks, eleven document-lock commands, eight document
selection cases and exact VGA. Startup recovery and all 17 module rejections pass.
All 1127 source hashes, nine build-input hashes and both disk hashes match.

Normal startup measured 41.141 seconds, up from 29.401 seconds because the native
compiler loads more original document code. Separate diagnostics measured
154.589 seconds. Kernel size remains 363584 bytes, with 25536 bytes of reserved
load headroom. Retaining compiled document services rather than recompiling them
at each boot is increasingly important as integration proceeds. These results
remain QEMU/486 development evidence, not strict 386 or physical-PC acceptance.
