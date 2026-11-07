# Shared ordinary function compilation

The --functions source-integration mode implies --statements and --classes. It
loads twenty-three stages, including complete shared global/function/statement
bodies and the actual LoadOneImport/SysSymImportsResolve bodies. Original loader
flags are copied directly from KernelA.HH. Required assembly/join/disassembly/
line-execution and AOT-store services remain explicit externs; no replacement
implementations are injected for them.

The public backend adapter distinguishes a real function frame by its existing
IC_ENTER and function metadata. It preserves that frame, argument count, local
storage and return class. Expression compilations still use a temporary frame,
including expressions evaluated while parsing a function's array bound/default
argument. Only expression IC_RET nodes are changed to function epilogues.
The target backend, optimizer and parser bodies remain the actual shared sources.

Seven differential cases cover integer arguments/defaults, for/if/goto/break,
nested calls, local arrays, switch, ordinary locals and F64 function parameters/
return. The original reference uses normal ExePutS compilation. Native invokes
the actual PrsFun function through its published address with public controls
and an isolated owned table whose parent remains borrowed. All calls happen
after their declaration controller has been released. Exact return records must
match the original. Generated code is then freed separately from metadata, and
both native heaps must recover exactly. Original heap recovery is not asserted.

These are source-loaded diagnostic compiler results, not delivered normal public
compiler APIs. Explicit-register policy, static/string/global ownership, mixed
signatures/variadics, recursion, complete error/unwind behavior, assembly/stream/
AOT closure, normal public delivery and full C1–C5 qualification remain open.
No inventory workflow is qualified by this narrow compiler integration check.

The expression-only adapter first passes all twenty-three publication stages
and every preceding regression, then faults with vector 6 in ring 3 on the
ordinary-function fixture. The patched five-case prototype matches the original
and recovers both heaps exactly. The formal reference extends this to ordinary
locals and floating-point argument/return handling; its fourteen-qword record
is seven successful metadata checks followed by 26, 25, 26, 20, 9, 12 and the exact
F64 bits for 3.5. Native adds two required heap-recovery checks. The native
execution profile is KVM 486,-fpu with 64 MiB; these source probes do not establish
minimal-profile memory requirements or release-generation reproducibility.

The normal native image rejects the fixture's first Lex call at line 10 before
function behavior. Internal PrsFun lookup is test instrumentation, not an
original public API requirement. The original reference compiles normally
through ExePutS. A first reference mistakenly used continue, which HolyC does
not support; the corrected fixture uses goto and the failed syntax attempt is
retained. An early adapter prototype also used unsupported ternary syntax and
is retained as a separate pre-execution failure.

Evidence: build/i386-public-functions-formal-original-v2,
build/i386-public-functions-formal-api-baseline-v1,
build/i386-public-functions-source-baseline-v1/terminal-baseline-audit.json,
build/i386-public-functions-source-v3/terminal-input-audit.json and
build/i386-public-functions-formal-native-v1.

Formal native acceptance passes all seven cases and both heap-recovery checks,
with all earlier regressions in the same guest. Its independent terminal audit
checks all 1031 input hashes, exact 112-byte original execution records, actual
shared bodies, delivered source identity, fixture-only volume changes and
unchanged boot bytes. See terminal-integration-audit.json in the formal native
evidence directory.
