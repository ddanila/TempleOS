# Retained expression code and external function completion

The actual original system passes the Lifetime.HC contract with mask 15. It
compiles PXLate(5), frees its public compiler control, catches the real UndefExt
exception from the still-unresolved call, defines the function through ExePutS,
and executes the retained code to obtain 42. A new expression then returns 43.
Returned code is freed independently; the exported result remains allocated until
guest shutdown. Run tools/test-i386-public-expression-lifetime.py --out OUT for
the original reference. The normal native image still rejects missing Lex at
line 7, before this API can run.

The source-loaded backend adapter passed mask 11 before the fix: code survived
control release and the unresolved exception was caught, but the retained call
still used the old undefined target after function completion. The adapter had
converted IC_CALL_INDIRECT2 into a direct relocated call and frozen the current
address. That loses the original mutable function-slot semantics.

The adapter now retains the indirect call and its original exe_addr slot. Its
linker handles the backend's IET_IMM_U32 slot relocation separately from ordinary
IET_REL_I32 direct calls. Temporary copied call metadata remains compile-owned;
returned code refers to the persistent public function descriptor, whose slot is
updated by real function completion. Other direct calls retain their normal
relocation path. The complete shared backend remains in use.

The patched source-loaded probe passes mask 15 and exactly matches the original
export. All prior nineteen publication stages, 24 token checks, graph mask 63,
nine basic executions, six type checks and eleven runtime cases pass as well.
Its independent terminal audit checks 1027 current input pins, exact packaged
inputs and original records, one expected undefined exception, fixture-only
volume changes, boot bytes and volume consistency. The actual original reference,
normal missing-Lex baseline and pre-fix source mask 11 have independent input and
fixture audits. This is one retained-code/unresolved-call/completion path, not
normal compiler delivery or full code lifetime, debug, exception, task, function
redefinition, class/header, stream or C1–C5 qualification.

Evidence: build/i386-public-expression-lifetime-original-v1,
build/i386-public-expression-lifetime-baseline-v1 and
build/i386-public-expression-lifetime-source-baseline-v1 and
build/i386-public-expression-lifetime-source-native-v1.
