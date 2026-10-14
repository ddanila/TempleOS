# Typed DolDoc dollar input

Original GetStr echoes through document key insertion. Dollar handling is part
of that editing path: the first dollar starts a command buffer, a second dollar
immediately inserts one literal dollar, and a completed command goes through
DocPrint. Typed `$RED$cash$$` therefore extracts as `cash$`; typed
`$$RED$$cash$$$$` extracts as `$RED$cash$$`.

## Shared implementation

`Adam/DolDoc/DocDollarInputCore.HC` extracts this state machine from EdCharIns.
The original editor calls it under its document lock. Native DocPutKey calls the
same core under a lock with exception cleanup before ordinary editing. Both
use the original printable bitmap, now represented by a shared data macro in
`Kernel/PrintableBitmap.HH`. Buffer growth allocates and copies before publishing
the new capacity, so a failed allocation does not publish unallocated space.
Fault-injected growth and parser-error recovery still need dedicated tests.

The console's command-source recording explicitly selects plain text while
inserting source characters, restoring that mode on normal and exceptional
returns. Its existing literal-dollar transcript contract stays distinct from
the inline document input path that GetStr still needs. Full GetKey/DocGetKey,
GetStr, keyboard navigation, output hooks and document rendering remain open.
This change does not qualify all DocPutKey behavior.

## Dollar grammar and macro lookup

The first native candidate produced a DOCT_ERROR entry for `$RED$`. Extracted
text alone still appeared as `cash$`, which demonstrated why entry type and
attribute assertions are necessary. The original grammar temporarily clears
`cc->htc.hash_table_lst` while reading document command/flag names. Native Lex
has a separate define table and was expanding RED to a number anyway.

NativeDocDollarLex now carries that suppression into CCF_NO_DEFINES and restores
its prior state after normal or exceptional return. Attribute expressions keep
normal expansion. A fixture shadows FG with a HolyC macro and requires
`$FG,RED$` to remain a foreground command with RED's numeric color attribute.
The pinned original and shared-core original runs both pass that distinction.

## Test-first evidence

`tools/test-i386-doc-dollar-input.py` checks partial state, completed text,
foreground entry type/value, command-name versus attribute macro handling,
escaped dollars, plain-text bypass and buffer growth through public APIs.
The preceding image fails the partial-state check in
`build/i386-c2-doc-dollar-structural-red/result.json`. The first integrated
candidate fails the foreground-entry check in
`build/i386-c2-dollar-input-native/result.json`; the raw entry probe identifies
DOCT_ERROR in `build/i386-c2-dollar-entry-probe-v2`.

The pinned original reference passes in
`build/i386-c1-dollar-qualified-reference/result.json`. The original system with the
current extracted editor/core overrides passes in
`build/i386-c2-dollar-qualified-shared-reference/result.json`. Each captures nineteen
buffers, including thirteen GetStr cases, direct typed-dollar and plain-text results and
four DocScanLine buffers, with typed-state/growth/macro assertions. Overrides
and unchanged input hashes are recorded explicitly. These runs qualify the
exercised component behavior, not original/native desktop parity.

An initial direct-entry fixture needed a CDocEntry cast to access its derived
attribute field. A later cleanup directive used unsupported #undef. Both
fixture errors are corrected in the final reference runs; their earlier
timeouts are not treated as behavior failures.

The corrected candidate is console interface 74. Original bootstrap rebuilds
and cross-build/386 boot audits pass in
`build/i386-c2-dollar-parser-fixed-cross`. Complete native-generation and
minimal background-concurrency qualification remain separate work.

## Corrected native verification

The final native suite passes 22 commands in
`build/i386-c2-dollar-qualified-native/result.json`, with exact VGA matches and
unchanged image/checker/harness hashes. The document group passes 33 commands
in `build/i386-c2-dollar-final-documents/result.json`, including the existing
allocation checks. Thirteen transcript commands pass in
`build/i386-c2-dollar-final-transcript/result.json`. The nine-command 8 MiB
startup gate passes in 42.2591 seconds, with no build-provider loads, in
`build/i386-c2-dollar-parser-fixed-startup/result.json`.

Native fixtures now encode dollar bytes with hex escapes. HolyC string decoding
otherwise collapses doubled dollars before the document sees them, so the
first escaped-literal fixture did not supply its intended bytes. A plain-mode
setup assignment also printed its numeric result at the top level; the final
fixture performs setup in a void helper. These fixture corrections do not
remove escaped-dollar or plain-mode assertions. The preceding image still
fails partial state in `build/i386-c2-dollar-byte-red/result.json`.

The expanded GetStr test uses the same exact-byte encoding. It rejects its
helper definition at the missing GetStr binding on the current image in
`build/i386-c2-getstr-byte-red/result.json`. None of its thirteen native input
cases executes yet. No complete GetStr, desktop or native-generation acceptance
is claimed by this component checkpoint.
