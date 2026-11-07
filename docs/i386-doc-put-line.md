# Public document-line output on i386

`DocPutLine` is a dependency of the original compiler's `LexPutLine` diagnostic
path. The implementation is shared unchanged in `Adam/DolDoc/DocPutLineCore.HC`,
included by the original document output source and the native document runtime.
The native public declaration and `_DOC_PUT_LINE` export use console version 238.

`tools/test-i386-doc-put-line.py` checks first-line output with a dollar and tab,
return of the next line's first entry, preservation of the source document,
output through the current task's document, the end sentinel, and rejection of
an invalid document signature. The original reference passes mask 31 and exact
saved bytes `A$$\tB\n\x05` (the dollar is escaped in the saved representation;
0x05 is the document cursor). Evidence is in `build/i386-doc-put-line-original-v2`.
Its independent audit verifies the fixture, restored reference tree and exact
output. The historical builder pin matches commit 013cbb50.

The missing-symbol baseline v1 reaches normal startup but rejects the fixture
at DocPutLine. Its input audit detects a concurrent builder edit, so it is
retained as diagnostic evidence; baseline v2 repeats with stable inputs.
Baseline v2 reproduces the missing-symbol rejection with stable inputs. Its
independent audit verifies normal startup, exact fixture-only volume changes
and unchanged boot bytes. Native behavior passes the same mask 31 and exact original output in
`build/i386-doc-put-line-native-v1`, with current input pins, normal startup,
arithmetic and an independent terminal contract audit. Final-image memory checks pass: the 8 MiB welcome run and 16 MiB diagnostic
run each match all 307,200 welcome pixels. Diagnostics complete both program,
heap-ownership and file-break cleanup phases with normal source startup.
Evidence: `build/i386-doc-put-line-welcome8-v1` and
`build/i386-doc-put-line-diagnostic16-v1`, including the independent diagnostic
audit. These are regression profiles, not full C5 installed generations. The
unchanged original body has separately passed source-loaded publication in
`build/i386-public-doc-put-line-loader-v1`. Publication alone is not behavior.

This contract does not cover document lock contention, allocation-failure
recovery or complete compiler diagnostics. FixSet, AdamErr, public lexer error
handling and normal-startup token delivery remain separate work. No inventory
item or C1–C5 milestone is qualified by this dependency alone.
