# Native public Call

The native Call API retains the original KernelB signature and _CALL export.
A null target returns zero. Valid no-argument targets execute through the existing
NativeCallArgs bridge, preserving complete I64 and software-F64 return bits in
EDX:EAX. Console version 244 adds function slot 652, for 653 total bindings.

The reusable tools/test-i386-call.py contract passes mask 255 on the actual
original system (build/i386-call-original-v2) and normal delivered native image
(build/i386-call-native-v2). It checks null, full-width, negative and F64 returns,
zero-result side effects, nesting, exception propagation, stack restoration and
continued calls. Independent audits verify restored original sources, exact
fixtures, current inputs, matching masks, native fixture-only volume changes and
unchanged boot bytes. The pre-change image rejects Call at fixture line 6;
its recorded builder pins correspond to revision 750ab3e1.

The first native fixture returned mask 127 because it compared raw GetRSP in an
inline condition against a value captured during assignment. The stack-machine
backend observes one additional eight-byte temporary in that assignment context.
Diagnostic original/native runs both pass mask 255 with matching assignments;
all three captured pointers within each run are equal. The inline comparison
selects offset zero on the original and offset +8 on native. These controls are
retained under build/i386-call-stack-diagnostic-original-v1 and
build/i386-call-stack-diagnostic-native-v1. The corrected formal contract keeps
the restoration check but measures both points in matching contexts. No Call
implementation change was needed for this correction.

Both bootstrap generations and the source-pinned cross-build pass. Normal 8 MiB
and diagnostic 16 MiB profiles match all 307,200 welcome pixels; both diagnostic
program/ownership/file-cleanup phases complete. See build/i386-call-memory-audit.json.
The complete unchanged PrsExp source now publishes successfully in
build/i386-public-expression-loader-v5, along with all 24 original token checks.
This remains a diagnostic source-loaded parser, not delivered expression execution.

The subsequent optimizer prototype publishes the complete original optimizer
and diagnostic printer bodies, then fails while defining/initializing canonical
type records (loader-v6). A split, instrumented constructor probe is running as
loader-v7. Real type/backend/stream integration and C1–C5 remain open. Call tests
cover valid no-argument targets; they do not validate arbitrary instruction bytes
or claim allocation-failure recovery.
