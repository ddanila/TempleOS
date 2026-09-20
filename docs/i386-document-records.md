# Shared document and editor records

`Kernel/DocTypes.HH` is the canonical source for the original DolDoc constants
and eight document/editor records. Both KernelA and the native public kernel
header include it. The extraction preserves every original field and format
string. KernelA's legacy byte encoding is unchanged outside the replaced block.

The pre-extraction x64 capture at revision 8bda89c records 131 fields, including
union aliases, callback pointers, embedded records and zero-sized span markers.
`tests/fixtures/doc-layout.json` stores that capture and the explicit i386
contract. `tools/check-doc-layout.py` compares the rebuilt x64 descriptors with
the capture and checks the native assertion file against the same contract.

| Record | x64 bytes | i386 bytes |
| --- | ---: | ---: |
| CDocBin | 56 | 40 |
| CDocSettings | 24 | 24 |
| CDocEntryBase | 88 | 80 |
| CDocEntry | 208 | 160 |
| CEdFindText | 304 | 304 |
| CEdFileName | 264 | 260 |
| CDocUndo | 48 | 36 |
| CDoc | 768 | 680 |

These are HolyC layouts, not host C struct layouts. Pointers and callback fields
are four bytes on i386; I64 fields and union alternatives remain eight bytes.
The four original eight-byte record-size assertions remain. Explicit tail
alignment before each assertion preserves that requirement without adding named
fields or changing x64 offsets. CDocEntryBase therefore ends at 80 bytes on i386,
including four bytes of tail padding. Embedded CDocUndo remains 36 bytes because
its original definition has no eight-byte size requirement.

CDocBin's serialized span, from `start` through `end`, remains four U32 fields
and exactly 16 bytes. Its offset changes from 32 to 20; serialization must use
the markers, never the whole pointer-bearing record. The shared behavioral
corpus checks all 16 bytes against fixed values on original x64 and native code.
It also exercises high-bit document flags, wide user data, embedded records,
linked-entry pointers and calls through document and entry callback fields.

Native public-header diagnostics load all 271 offset/size assertions in batches
of at most 16, verify each input reclaims its temporaries, check the retained
editor format metadata, compile the complete behavioral corpus in one input,
and reclaim the published records with the rest of the test scope. Semicolons
separate the assertion directives to bound lexer lookahead recursion. Normal
startup exposes the actual records, including CDoc and CDocEntry.

The records do not supply document lifecycle services. CDirContext remains an
opaque pointer dependency. Color aliases still depend on the original palette
constants; those need public native bindings with drawing integration. Locking,
break handling, reporting, document globals, callbacks and persistent files must
be connected before the existing DocNew/DocBin group or full editor can run.
The 16-byte span check is component evidence; cross-architecture document files
and embedded graphics still require integrated fixtures.

Loading the full records increases retained public-header storage from 71248 to
169920 bytes. A standalone normal QEMU/486 boot measured 60.617 seconds, versus
25.038 seconds for the preceding committed header set. The normal harness now
allows 90 seconds (previously 60); diagnostics allow 1200 seconds for the larger
boot/worker corpus. These are harness deadlines, not responsiveness targets or
claims of vintage hardware performance. Normal startup still skips diagnostics.
Compiler allocation and validation cost must be addressed before the integrated
interactive performance gate can close.

The completed native suite measured normal startup at 60.612 seconds and diagnostic
startup at 726.823 seconds. It passed 124 console commands across 187 input lines,
exact VGA checkpoints, startup-source recovery and all 17 module rejection cases.
Both x64 rebuild generations and the independent layout comparison passed against
the same 1084 OS source hashes. The temporary document-enabled probe allocation
of 656880 bytes and the worker allocation of 533664 bytes are fully reclaimed.
