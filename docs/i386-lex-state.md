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
