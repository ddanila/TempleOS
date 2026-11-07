# Lexer diagnostic integration evidence

The real public dependencies DocPutLine, FixSet, dbg, AdamErr, IsSingleUser,
PutFileLink, PrintErr/PrintWarn and FlushMsgs are available on native i386.
The complete original diagnostic bodies in Compiler/CExcept.HC have not yet
been delivered through native startup.

The original reference probe uses a real CCmpCtrl with a filename, identifier
and input line. It checks warning/error counters, catching the Compiler exception,
the saved FixSet location, unchanged input position and output documents. It
waits for actual RLf_ADAM_SERVER readiness and temporarily enables single-user
mode to suppress duplicate Adam output.

The shipped original default-null LexExcept call fails to complete within the
observation window in `build/i386-lex-diagnostics-original-v2`. An uninstrumented
source copy also times out in `build/i386-lex-diagnostics-copy-v1`. Both reach
the before-exception marker after producing a valid warning document.

The explicit-message original API control passes mask 31 in
`build/i386-lex-diagnostics-message-v1`, with an independent reference audit.
An instrumented source copy passes all stages in
`build/i386-lex-diagnostics-trace-v1`. A single marker after LexPutPos also passes
mask 31 (`build/i386-lex-diagnostics-after-position-v1`); markers after AdamErr
or immediately before throw do not resolve the default-null failure.

An uninstrumented, renamed original body compiled with OPTf_NO_REG_VAR enabled
passes mask 31 and both documents in `build/i386-lex-diagnostics-no-reg-v1`.
Its audit verifies the exact body apart from the diagnostic name, absence of
trace calls, restored reference tree and exact fixture. This supports a register
preservation/code-generation hypothesis; it does not prove the root cause or
qualify the shipped original default-null API. The null-message path remains
an explicit compatibility gap rather than being replaced by the passing
explicit-message test.

A native source-loaded probe of all five unchanged diagnostic bodies is retained
under `build/i386-lex-diagnostics-native-loader-v1`. It requires the mask and both
default-null documents to match the no-register-locals source control exactly.
Its native result is not yet verified in this record. No instrumentation,
substitute error handler or production change is supplied by that probe. Full compiler diagnostics and C1–C5 qualification remain open.
