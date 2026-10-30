# Logic application compatibility

The pinned original Logic source includes ten embedded gate sprite references
in its initializer and implements a truth-table gate synthesizer. The original
reference fixture loads the unchanged application and checks one deterministic
truth-table synthesis for each of the ten supported gate modes, including the
chosen input wiring, output identity and first-pass result. It passes mask 1023
with unchanged inputs (`build/i386-logic-reference-v1`; runner
`tools/test-i386-logic-reference.py`). This is a component oracle, not the
interactive prompt, drawing, cancellation or complete application workflow.

An earlier native image packaged the pinned Logic source unchanged, but its
Load script is rejected at the `$IB` initializer in `Logic.HC` line 73 with a
missing-expression error and unchanged inputs
(`build/i386-logic-native-load-v1`; runner
`tools/test-i386-application-native-load.py`). No native synthesis case ran.
The native lexer already handles `DOCT_INS_BIN` and `DOCT_INS_BIN_SIZE` in a
document stream, and the shared expression parser handles their tokens. At that point file
includes loaded a zero-terminated byte buffer through
`I386LexIncludeTake`, so this result identifies a document-backed include gap;
it does not establish that changing only the include attachment is sufficient.
At that point the document branch returned EOF at the end of a document, and
`I386LexFileAdvance` rejected document children; compiler-control cleanup also
requires a document destructor callback for owned document inputs. Those
boundaries must be extended together before attaching document includes.

To close the gap, preserve the full serialized DolDoc and binary records,
parse them with original document semantics, attach an owned document as the
include's lexer input, and release it exactly once on normal return, compiler
errors, cancellation and snapshot/unwind paths. Check nested includes and
binary identity, and test both interactive compilation and native module
building. Avoid treating embedded graphics as empty strings or editing Logic
around its original source. C1–C5 remain open.

The unchanged Logic document has now been tested independently of compilation.
On both the pinned original and the current 64 MiB native image, `DocRead`
produces all ten binary records with byte-identical payloads and links all ten
sprite entries and ten inline-binary entries to their numbered records. The
fixture compares each record to the serialized file and checks the entry types
and links, passing mask 31 with unchanged inputs
(`build/i386-logic-document-original` and `build/i386-logic-document-native`;
runner `tools/test-i386-logic-document.py`). This demonstrates that the current
loader handles this real document; it does not establish general DolDoc parity,
rendering, child-include attachment or document cleanup during compiler unwind.

The i386 lexer now has an internal owned-document child primitive. It rejects
invalid and already-owned documents, retains a per-child destructor, resumes
the parent when the child reaches EOF, and retains an exhausted child while a
lexer snapshot still refers to it. The destructor must return normally and be
safe with interrupts masked. At that stage this was not connected to file includes; compiler control teardown
and the file path still needed to dispatch and transfer ownership. Existing raw and borrowed-root behavior remains in place.

The native lexer foundation fixture now exercises normal document-child EOF,
return to a raw parent, snapshot discard and restore, duplicate and wrong-heap
attachment rejection, invalid entry-list rejection, registered-destructor
precedence and exactly-once release. The combined lexer fixture passes its
386 execution and instruction audit (`build/lex-document-child-foundation-v5.log`);
separate snapshot-boundary and compiler-control regressions also pass
(`build/lex-document-child-snapshot-v3.log`,
`build/lex-document-child-control-v3.log`). Both original bootstrap generations
and the 386 cross-build/audit pass (`build/rebuild-test`,
`build/i386-lex-document-child-cross-v3`). An 8 MiB native smoke run also passes an ordinary file include and sector
fixture with unchanged inputs (`build/i386-lex-document-child-8m-v3`); it is
not a complete minimal-profile or startup timing gate. The original loader and release
qualification remain open; these are private lexer mechanics, not Logic parity.

Compiler-control cleanup now dispatches each active owned document child to its
registered destructor, retaining the prior callback behavior for unregistered
or root documents. Direct cleanup marks the task's compiler busy before
snapshot discard can release a detached child; a task fixture reproduced that
reentrancy gap as runner result 60 (`build/doc-child-control-unwind-v6.log`).
The corrected fixture passes with active children under both interrupt states,
and with a snapshot-retained detached child and exact heap recovery
(`build/doc-child-control-unwind-v7.log`). The separate control fixture checks
multiple children and callback precedence, and the lexer and ATA task fixtures
also pass (`build/doc-child-control-fixture-v2.log`,
`build/doc-child-control-lexer-v2.log`,
`build/doc-child-control-ata-fixture.log`). The task fixture uses rejecting
RedSea stubs because it mounts no disks, and its larger source uses a separate
1 MiB test heap and 0x9C000 descriptor scratch; these are not production boot
changes. Both bootstrap generations and the 386 cross-build/audit pass
(`build/rebuild-test`, `build/i386-doc-child-control-cross`), as does an 8 MiB
ordinary-include smoke check with unchanged inputs
(`build/i386-doc-child-control-8m`). This smoke run is not a startup timing
gate. At that stage real file-to-document attachment, interrupt-safe real document
teardown, cancellation during loading, and native Logic remained open.

A focused deletion fixture now loads the actual Logic document repeatedly and
checks `DocDel` with interrupts masked and enabled. On both the pinned original
and 64 MiB native image, the interrupt state is preserved and task-heap usage
returns to its warmed baseline after each deletion (mask 15, unchanged inputs;
`build/i386-document-irq-delete-original` and
`build/i386-document-irq-delete-native`). This is an uncontended current-task
check; it does not establish safety during task exit, cancellation or
compiler-owned document teardown. The native run was not an isolated startup
timing measurement.

Post-bootstrap file includes now load the serialized source into a DolDoc using
the original document loader, transfer ownership to the lexer child, and free
the original source buffer. Root-header bootstrap still uses raw file input.
A nested include fixture checks the exact embedded binary bytes and size on
the pinned original and on the 64 MiB native image (mask 3;
`build/i386-document-include-original-v2` and
`build/i386-document-include-native-v1`). The prior image fails that fixture
at the binary initializer (`build/i386-document-include-native-red`). Repeated
includes and exact warmed task-heap recovery pass on both original and native;
the native run also exercises compiler-error unwind and a successful later
include (`build/i386-document-include-cleanup-original-v3` and
`build/i386-document-include-cleanup-native-v3`).

The unchanged Logic application now advances past its embedded binary
initializer and fails on the missing `GetI64` at line 112
(`build/i386-logic-native-load-bridge-v1`). No native synthesis case has run.
Both bootstrap generations and the 386 cross-build/audit pass
(`build/doc-file-bridge-rebuild-v2.log`,
`build/i386-doc-file-bridge-cross-v2`); an ordinary include smoke check also
passes at 8 MiB (`build/i386-doc-file-bridge-smoke-8m`). These checks do not
qualify cancellation or task death while loading, out-of-memory behavior,
ahead-of-time module building, general document parity, or startup timing.
C1–C5 remain open.

The unchanged TimeClock keyboard workflow also passes on this image, including
multiline entry, cancellation and cold-reboot record recovery with unchanged
inputs (`build/i386-doc-file-bridge-timeclock-keyboard`). This is not full
application or startup qualification.

A native ahead-of-time build now also compiles a nested source document with
binary and binary-size entries, persists the module and verifies its function
export. A separate JIT invocation checks the source's exact four binary bytes
and size (`build/i386-document-include-aot-v1`; runner
`tools/test-i386-document-include-aot.py`). This does not execute or install
the emitted module or establish general AOT document compatibility.
