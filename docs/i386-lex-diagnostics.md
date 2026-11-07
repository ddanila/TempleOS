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
the corrected original public API reference; its result remains pending.

All real public dependencies are now delivered, but the complete unchanged
Compiler/CExcept.HC diagnostic bodies are not yet delivered through native
startup. No instrumentation or substitute handler has been added to production.
Full compiler diagnostics and C1–C5 qualification remain open.
