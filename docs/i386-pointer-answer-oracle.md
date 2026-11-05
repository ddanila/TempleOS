# Independent native pointer-answer oracle

A completed `U8 *lost="bad";` declaration survives a following parse error on
the pinned original. The old compiler regression expected `lost;` to fail. That
source command remains in the native regression, with an independent value/state
oracle instead of a fixed address or a wildcard screen match.

After the command completes, the harness pauses its isolated QEMU guest, captures
physical RAM, and resumes it in a finally block. The pure checker follows the
console task's public hash-table chain, finds the newest matching global, checks
its U8-pointer metadata and four-byte variable storage, and requires the original
`bad` bytes plus terminator at the referenced address. The consumed task answer
must equal that variable's pointer and retain the expected raw category. Only
then does the harness construct the exact hexadecimal text and compare every
screen pixel. It does not read screen text to choose an accepted address.

The public task offsets are asserted by CompilerTaskLayoutProbe.HC. Hash/symbol
layouts follow the shared 32-bit public records. Bounded traversals reject
missing globals, invalid pointers, locked/malformed tables and cycles. Every
used capture records its RAM digest, checker digest, selected task/table/symbol,
type/storage addresses, literal and expected answer.

`tools/test-i386-pointer-oracle.py` passes one valid snapshot and eleven
corruption/missing-state guards. `tools/test-i386-pointer-answer.py` passes eight
live commands in `build/i386-pointer-answer-v2/result.json`, including error
survival, exact nonzero pointer display, redefinition to `ok`, and byte reads
97/107. Both captures and all checkpoint pixels pass at 8 MiB KVM 486 without
FPU/live WinMgr with unchanged inputs. Its v1 failure was a QMP argument-name
error before capture; no successful result is inferred from it.

The complete retained compiler group passes all 146 commands in
`build/i386-command-policy-compiler-v1/result.json`. Its captured bad-string
pointer is 0x7C99F6; the smaller test uses different addresses, demonstrating why
a fixed address is insufficient. All original submitted source occurrences,
including `lost;`, remain in the migration audit. The native numeric display
style is retained. This does not qualify every pointer operation, arbitrary
hash mutation, original timing, or all declaration/compiler APIs.
