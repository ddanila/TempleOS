# Lexer diagnostic integration evidence

The corrected original public-API reference passes the default-null LexExcept
path in `build/i386-lex-diagnostics-original-v3` (mask 31). Its independent audit
checks the restored original source tree, fixture and exact warning/exception
documents. It uses real CCmpCtrl, waits for actual Adam-server readiness, and
checks counters, Compiler exception, FixSet location and unchanged input position.
Exported document allocations remain alive until guest shutdown.

Earlier fixtures freed exported buffers after a delay. This did not guarantee
that the host had copied them: the no-register-locals control's exception export
was visibly overwritten. The timeouts, trace passes and no-register control
remain preserved under the earlier original/copy/trace/minimal/after-position
artifacts. They do not establish a public API defect or register-allocation bug.
The earlier register-preservation hypothesis is withdrawn pending valid evidence.
An explicit-message original API control also passed mask 31.

The native source-loaded v1 probe completed all state checks but failed output
comparison against that overwritten reference allocation. V2 in
`build/i386-lex-diagnostics-native-loader-v2` uses retained export allocations and
the corrected original public API reference. It passes mask 31 and exact
warning/exception documents. Its independent audit verifies the complete unchanged
body and both documents. The reusable original v4 contract additionally retains
its result allocation; it also passes exact output and mask checks.

The five bodies are now shared unchanged in `Compiler/LexDiagnosticsCore.HC`,
included by original CExcept and the native console. Console version 241 adds
public LexPutToken, LexPutLine, LexPutPos, LexWarn and LexExcept exports. The
native include maps Dbg to NativeDebug, the implementation behind the existing
public _DBG export. The first cross-build rejected the missing internal Dbg name;
its compiler log is preserved in `build/i386-lex-diagnostics-cross-v1`.

The pre-change normal image rejects the first LexWarn call in
`build/i386-lex-diagnostics-baseline-v1`, with independent input/startup/volume
and boot-byte audit. The revised normal image passes mask 31 and exact original fixture/documents in
`build/i386-lex-diagnostics-native-v1`. Its independent audit verifies input
pins, normal startup, fixture-only volume changes and unchanged boot bytes.
The source-loaded original Lex/LexExtStr regression passes all 24 cases in
`build/i386-public-token-loader-v15`, using the delivered diagnostic bindings.
Its independent audit verifies the original fixture, result and token bodies.
Normal 8 MiB and diagnostic 16 MiB profiles match all 307,200 welcome pixels;
the diagnostic run completes both program/ownership/file-cleanup phases. See
`build/i386-lex-diagnostics-memory-audit.json`.

An original real-token error reference also passes mask 15 in
`build/i386-lex-token-error-original-v1`: an overlong character constant reaches
the Compiler exception, error counter, saved location and expected message.
Native source-loaded original Lex also passes mask 15 in
`build/i386-lex-token-error-native-v1`, independently audited against the
original fixture, unchanged token stages, volume and boot bytes. This checks
exception identity, counters, saved location and the error-message substring.
The complete documents differ in the fourth PrintErr caller name: original
`&LELog`, native `&LexSystemToken`; the first three caller names and diagnostic
payload match. Different top-level execution contexts may affect this prefix,
but its cause and full diagnostic equivalence remain unqualified.

The contract covers an identifier token, normal document output, counters,
saved source location, preserved input and the default-null Compiler exception.
It does not qualify raw output, boot debugger interaction, function-context
warnings, document-backed input or allocation
failure. Test export buffers are deliberately retained until guest shutdown;
this is not a production allocation-recovery test. Full compiler diagnostics,
normal-startup token delivery and C1–C5 qualification remain open.

The reusable `tools/test-i386-lex-token-format.py` contract passes against both
the original (`build/i386-lex-token-format-original-v3`) and normal native image
(`build/i386-lex-token-format-native-v2`). All eight LexPutToken branches match
exactly: identifier, string, integer, character constant, float, newline,
displayable and non-displayable token. Independent audits verify the original
source tree, fixtures, recorded inputs, native volume and boot bytes. Export
allocations remain alive until shutdown. This exercises token formatting only;
it does not deliver the complete lexer during normal startup.
