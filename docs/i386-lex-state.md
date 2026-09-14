# Lexer save points on i386

`Compiler/LexState.HH/HC` shares character backup, snapshot linking, detachment
and restoration between targets. The x86-64 LexPush/Pop entry points use these
helpers and retain MAllocIdent/Free and the original prepare-before-allocation
order. Native adapters in `Compiler/I386/LexState.HH/HC` use an explicit heap.

A snapshot shallowly copies CLexFile. It borrows the buffer, filename, document
and document-entry references; it does not own or duplicate those payloads.
Snapshot `next` links the saved-position stack, whereas active-file `next` links
the include stack. Restoration copies bytes after the first target-width pointer,
so it restores file state and padding while preserving the active include link.
The control's current buffer pointer and last-character flag/value are restored
separately. Other control flags retain their current values.

The existing last-character behavior is preserved: the I64 control value narrows
to the file's U8 field during backup; a zero saved byte clears CCF_USE_LAST_U16,
and restoring a saved byte widens it back to the control value. Discarding a save
point changes only the saved-position stack, not the current input state.

Native snapshots have private heap/control/active-file ownership metadata after
the public CLexFile prefix. Push allocates before touching lexer state, so a
failed native allocation leaves that state unchanged. Pop rejects an empty stack,
a wrong heap/control, or a restore with a changed active-file pointer. Discard
remains legal after the active file changes. Validation, optional restoration and
heap release run with interrupts masked, restoring the caller's prior state.

Callers must exclusively own live control/file/stack records and keep borrowed
payloads live when restoring. Do not free and reuse the active file while a save
point may be restored: pointer identity is not a generation check. The checks do
not validate arbitrary corrupt graphs or unreadable control/file pointers. Drain
save points before destroying their control record. No lexer tokenization,
include-file loading, native document handling or full CmpCtrlDel is supplied by
these adapters.

## Verification

Run after the x86-64 rebuild bootstrap:

```sh
python3 tools/test-rebuild.py
python3 tools/test-i386.py --lex-state
python3 tools/build-i386-kernel.py --test
```

The dedicated fixture runs the same state cases through the production x86-64
entry points and the native adapters. It covers all 256 saved-byte values with
and without the last-character flag, high control bits and line numbers, borrowed
high-address document pointers, file padding, include-link preservation, nested
save points, restoration and discard. Native cases also cover allocation failure,
wrong heap/control, crossing an active-file boundary, empty/repeated pop, both
interrupt states and full heap reclamation.

All cases pass with the executable instruction audit. Both x86-64 rebuild/reboot
generations and the complete standalone 314504-byte kernel boot checks pass on
the 8 MiB QEMU/486 development profile. Strict 386 validation and native lexer/
compiler execution remain required; see `port-progress.md`.

## Lexical file ownership

`Compiler/LexFiles.HH/HC` shares file attachment and release policy. Attachment
sets the root depth to -1 and nested depths relative to the current top. It does
not initialize source buffers, names or line numbers, nor change cur_buf_ptr.
The existing x86-64 LexFilePush/Pop use these helpers with CAlloc, Free and DocDel.

Release unlinks the top before disposing of it. Every nested input owns its
payload; CCF_DONT_FREE_BUF retains only the last/root payload. Raw inputs release
their buffer, whereas document inputs release their nonnull document through the
document service and do not separately free buf. Filenames and file records are
always released. Empty stacks have no release effects. The caller still manages
the current buffer pointer when moving between inputs, as in the existing lexer.

`I386LexFilePush` allocates a zeroed public CLexFile prefix with private heap/control
ownership metadata. Its 64-byte allocation consumes an 80-byte heap span. Failure
leaves the include stack unchanged. `I386LexFilePop` returns success/failure rather
than the new top; it rejects a wrong heap/control, an empty stack, outstanding
save points, or a missing service for an owned nonnull document before unlinking.
A retained root document needs no release service. The callback receives the
caller's document context, independently of the heap-release context.

The caller exclusively owns live file/control records. Names and owned raw buffers
must belong to the supplied heap. Document services must return normally, preserve
their caller's interrupt state and not reenter or destroy the active control.
Heap operations mask interrupts and restore their prior state; document callbacks
run in the caller's state. Release failures from invalid nested ownership do not
roll back a partially disposed file. These are ownership checks, not validation of
arbitrary corrupt graphs. Drain snapshots and detach other references before pop.

The expanded `--lex-state` fixture passes root/nested depth, all raw/document and
root-retention combinations, null documents, callback contexts/counts and unchanged
current-buffer semantics on both targets. Native tests cover the 80-byte minimum,
allocation failure, wrong ownership, missing services, snapshot/pop interaction,
retained payloads, both interrupt states and complete heap reclamation. Existing
snapshot tests, instruction audits, both x86-64 rebuild generations and full
standalone kernel boot checks also pass. Native document destruction itself,
source-file loading, full control destruction and tokenization remain unfinished.

## Raw source character consumption

`Compiler/LexInput.HH/HC` now shares the current-buffer read loop with the
production x86-64 LexGetChar. It skips CH_CURSOR, updates plain-file newline
counts/line starts and reports buffer boundaries. A shared final step normalizes
CH_SHIFT_SPACE. Character constants come from a byte-preserved extraction in
`Kernel/CharCodes.HH`. The x86-64 document, prompt, echo and include handlers remain
in LexGetChar; its replay path still returns the saved value without reading or
counting it again.

`I386LexRawChar` consumes raw file stacks using these helpers and owned file pop.
It supports saved-character replay, normalization, wide line counters, repeated
EOF at a stable terminator, null buffers and returns to parent input, including
its saved byte. It returns -1 for unavailable document/prompt/echo handling or a
failed include pop. A rejected include transition retains the child and parks its
cursor at the terminator, allowing the caller to resolve the condition. This is
not a rollback guarantee for earlier characters already consumed. Buffers must be
live and zero-terminated; controls and counters require exclusive ownership.

The shared host/native fixture passes every nonzero byte, replay without extra
advancement/counting, cursor chains, shift-space normalization, wide line counts,
EOF/null behavior, nested raw input returns and parent saved bytes. Native cases
cover unsupported modes, document parents and live-snapshot pop rejection followed
by recovery. A real x86-64 document text/tab/newline prefix and its destruction
also pass, along with the prior state/ownership suites and instruction audit.

Standalone boot now reads its source into a stable terminated buffer, initializes
a native control/file, consumes the source with this reader and reclaims all three
allocations. The host independently checks raw and normalized checksums, character
and newline counts and the temporary heap footprint. Both x86-64 rebuild generations
and the full 331352-byte kernel boot checks pass on the 8 MiB QEMU/486 profile.
This supplies raw source input; tokenization, native document/prompt services,
general control construction/destruction and the compiler/JIT remain unfinished.
