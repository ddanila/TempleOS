# Escaped literal storage after a later syntax error

Compiler93 enables existing terminal publication when a failed input has a
registered output carrying the parser's CCF_HAS_MISC_DATA mark and an actual
literal/data span. The old gate required declarations or published children;
a completed literal store could therefore outlive its output allocation after
a later parse failure. The structurally validated ownership journal now retains
that pool even when the input declared no symbols. Error counts stay set and the
failed input still returns failure. Atomic-definition behavior is unchanged.

The same fixture runs a compile-time compound block and an ordinary runtime
compound block. Each stores a literal pointer into an existing global, finishes
with another value, then encounters `Unknown stream_bad;`. A real captured
diagnostic must contain exactly one Undefined message. Native also requires
exactly one corresponding compiler rejection and waits for normal command
recovery before the next command. Server readiness is awaited, never fabricated.

The twelve observations cover the completed store, caller controller restoration,
32 later compilations, public heap churn, generated-function access, parent
closure and 256 patterned code allocations. As in the successful lifetime tests,
native uses separate console commands to close the parent controller explicitly;
the original runs fixture calls in its restored Once source.

```
python3 tools/test-i386-stream-failure.py --out ORIGINAL
python3 tools/test-i386-stream-failure.py --runtime-block --out ORIGINAL-RUNTIME
python3 tools/test-i386-stream-failure.py IMAGE --out NATIVE
python3 tools/test-i386-stream-failure.py IMAGE --runtime-block --out NATIVE-RUNTIME
```

Original-v3 and runtime-original-v3 pass every functional observation. On the
prior compiler92 image, baseline-v3 and runtime-baseline-v3 fail observations
8, 10 and 11: later generated code and command closure expose corrupted bytes.
Native-v1 and runtime-native-v1 on the candidate pass all twelve observations
and exact original payloads. All evidence uses build/i386-stream-failure-*;
terminal audits independently verify source/image/fixture/helper pins.

The 32-byte payload including NUL has SHA-256
`a218073603158def988769fefd4f6b2683ea14e94edf4062983d5b95a58f3f16`.

## Nonliteral exception control

After eight warm-up executions, the fixture measures the public code heap's
used_u8s around 32 plain `throw('Compiler');` inputs. Native requires exactly
40 deliberate nonliteral rejections across warm-up and measurement, a completed
recovery marker, and zero used-byte growth. Both baseline and corrected native
report zero. The original records 169,984 bytes of growth in both modes; this is
an observed reference difference, not an original zero-recovery guarantee.
The failed v2 attempts preserve the contradicted original-zero assumption.
This counter is not reserved pages, private-parser allocations or peak RAM.

Both bootstrap generations and the full native build pass with current source
and build-input audits. This covers a later syntax error after a completed
literal store. OutMem, errors during publication, execution faults with partial
side effects, cancellation, task death, cross-task references and normal public
compiler delivery remain open. No complete ownership or C1–C5 release claim is
made, and no additional whole application workflow is qualified.


The successful literal-store regressions pass in both modes on this candidate,
as do all seventeen pending-answer cases and unchanged whole Carry/ClassMeta
workflows with exact original documents. Their terminal input pins are
independently checked. These regressions share the same build prefix.


Final source26 passes all loading stages and every compiler/statement/executor/
stream observation; 1,039 input pins are independently verified. Both fresh
8 MiB normal and 16 MiB diagnostic welcome rasters match all 307,200 pixels.
Both diagnostic program/code-ownership/file-break phases complete. The cross-build
records the exact checks in memory-audit.json. Inventory guards pass five tests,
with whole-workflow qualification counts unchanged at two of 686.
