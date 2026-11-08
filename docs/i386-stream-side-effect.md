# Literal addresses stored through side effects

Compiler92 preserves the parser's CCF_HAS_MISC_DATA mark in command output
records. The executor already merges that mark with its returned-address test.
Previously a command output used zero for the saved mark, so an escaped literal
could be freed whenever the command finished with another value. The same bug
affected ordinary commands and compile-time blocks. This change uses the original
parser's conservative ownership signal; it does not scan selected globals or
assume that unknown callees cannot retain pointer arguments.

The fixture stores a literal pointer into a global inside a compound block
ending in zero. It verifies the pending answer differs from that pointer, runs
32 further compilations, churns data/code heaps and accesses the pointer through
a generated function. Native closes the parent command before a later command
checks the bytes and holds 256 patterned code allocations of varying sizes.
The same fixture runs as a compile-time block and an ordinary runtime block.

```
python3 tools/test-i386-stream-side-effect.py --out ORIGINAL
python3 tools/test-i386-stream-side-effect.py --runtime-block --out ORIGINAL-RUNTIME
python3 tools/test-i386-stream-side-effect.py IMAGE --out NATIVE
python3 tools/test-i386-stream-side-effect.py IMAGE --runtime-block --out NATIVE-RUNTIME
```

Original-v2 and runtime-original-v1 pass all twelve observations per mode.
Baseline-v2 and runtime-baseline-v1 on the prior compiler91 image both fail
observations 10 and 11: the pointer no longer refers to intact bytes after parent
closure, and code-heap reuse does not restore them. Initial single-mode captures
are also retained. All evidence uses the build/i386-stream-side-effect-* prefix.
Native-v1 and runtime-native-v1 pass all twelve observations per mode, together
with normal arithmetic pixels, additive packaging, filesystem integrity and
independently checked input pins. Their complete payloads match the original.
The original runs fixture calls in its restored Once source; native uses separate
console commands to exercise parent-controller closure explicitly.

The 36-byte payload, including NUL, has SHA-256
`ba28c90a263cd31f3625d28bd69c36059bdc57c0a002770acbb454ea38f741c6`.

The earlier returned-pointer lifetime test and all seventeen pending-answer cases
also pass on the new image. Both x64 bootstrap generations and the full native
build pass with current source/build-input audits. No public export/layout or
console250 table change is needed; only the compiler service epoch advances.

Literal-bearing command outputs now retain their code/data conservatively even
when a particular callee happens to copy or ignore its argument. This matches the
parser's original signal. No peak-resource or reclamation claim follows from
these cases. Constant-expression/AOT paths, errors/OutMem, cancellation, task
teardown, cross-task references and full public compiler delivery still require
qualification. This component test closes no C1–C5 milestone or whole workflow.


Final source26 passes every stage and compiler/statement/executor/stream
observation, with 1,039 input pins independently verified. Carry and ClassMeta
pass their unchanged whole workflows and exact original documents. Fresh 8 MiB
normal and 16 MiB diagnostic boots match all 307,200 welcome pixels; both
diagnostic program/code-ownership/file-break phases complete. Evidence uses the
same build prefix; the cross-build includes memory-audit.json.


The complete 34-command ordinary console regression also passes at 8 MiB KVM
without FPU, with live WinMgr and exact VGA checks. This covers typed formatting,
void suppression, declaration-only preservation, syntax recovery, nested document
execution and integer/F64/pointer initializers after changing ordinary command
retention. All terminal pins are independently checked. Inventory guards pass
all five tests; whole-workflow qualification counts remain two of 686.


Compiler93 follows up later syntax failures: an input with retained literal
outputs now reaches the existing terminal publication journal even when it
created no declarations. Both compile-time and runtime failure cases preserve
the original bytes after recovery; an independent nonliteral exception control
keeps native code-heap used-byte growth at zero. See
[failure evidence](i386-stream-failure.md). Other failure and release gates remain
open.
