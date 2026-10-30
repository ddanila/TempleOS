# Logic application compatibility

The pinned original Logic source includes ten embedded gate sprite references
in its initializer and implements a truth-table gate synthesizer. The original
reference fixture loads the unchanged application and checks one deterministic
truth-table synthesis for each of the ten supported gate modes, including the
chosen input wiring, output identity and first-pass result. It passes mask 1023
with unchanged inputs (`build/i386-logic-reference-v1`; runner
`tools/test-i386-logic-reference.py`). This is a component oracle, not the
interactive prompt, drawing, cancellation or complete application workflow.

The current native image packages the pinned Logic source unchanged, but its
Load script is rejected at the `$IB` initializer in `Logic.HC` line 73 with a
missing-expression error and unchanged inputs
(`build/i386-logic-native-load-v1`; runner
`tools/test-i386-application-native-load.py`). No native synthesis case ran.
The native lexer already handles `DOCT_INS_BIN` and `DOCT_INS_BIN_SIZE` in a
document stream, and the shared expression parser handles their tokens. File
includes currently load a zero-terminated byte buffer through
`I386LexIncludeTake`, so this result identifies a document-backed include gap;
it does not establish that changing only the include attachment is sufficient.
The current document branch returns EOF at the end of a document, and
`I386LexFileAdvance` rejects document children; compiler-control cleanup also
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
