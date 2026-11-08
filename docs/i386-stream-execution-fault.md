# Active compile-time stream context after execution faults

Compiler94 restores outstanding stream hash contexts and discards unfinished
stream buffers at terminal retirement, before the existing publication journal
runs. Successful streams keep their normal path. Retirement performs no new
allocation, validates tracked context/queue storage, unlinks buffers before
release and retains the exception. It does not inject incomplete generated text.
The restored outer function context still goes through the existing partial-
function validation rather than being silently cleared.

An execution fault can leave cc->htc.next and the stream queue attached because
PrsStreamBlkCore never reached its normal epilogue. Compiler93 retained the
literal-output candidate but rejected terminal publication with that context
still active. The general controller cleanup then freed the escaped data. Plain
runtime blocks already passed on that image; the defect concerned active streams.

## Original comparison

```
python3 tools/test-i386-stream-execution-fault.py --out ORIGINAL
python3 tools/test-i386-stream-execution-fault.py --runtime-block --out ORIGINAL-RUNTIME
python3 tools/test-i386-stream-execution-fault.py --nested --out ORIGINAL-NESTED
python3 tools/test-i386-stream-execution-fault.py IMAGE --nested --out NATIVE-NESTED
```

The block stores a literal pointer, throws Compiler from the same compiled block,
and places a write after the throw that must never execute. The fixture exports
the actual eight-byte exception code; undefined-identifier diagnostics are
rejected. It checks literal bytes, later compilations, heap churn, generated
function access and native parent-command closure. A nested mode first appends
a declaration to its outer stream's generated text. That declaration must never
appear in the symbol table after the fault, including after subsequent commands.
All three modes pass thirteen observations on the original and candidate.

Evidence uses build/i386-stream-execution-fault-*:

- original-v3, runtime-original-v3 and nested-original-v2 pass.
- baseline-v2 and nested-baseline-v1 on compiler93 fail the final reuse check and
  log TERMINAL publication rejected. Earlier v1 captures are retained.
- native-v2, runtime-native-v2 and nested-native-v2 pass, with no terminal-context
  or publication rejections. The current build uses console250's unchanged
  663-entry public table; no public layout or export is added.

The exact 40-byte literal including NUL matches the original, SHA-256
`16df548a78e3c1616822159f98514600176a939c720849ee1ccfb651a7b56e41`.

Both baseline and corrected native recover public code-heap used_u8s across
32 plain Compiler exceptions after eight warm-ups. The original's observed
169,984-byte growth remains documented rather than asserted as zero. This is a
used-byte control, not a reserved-page, private-parser or peak-RAM budget.

Both x64 bootstrap generations and the full native build pass with independently
checked current source/build-input pins. OutMem, retirement/publication failures,
arbitrary partial initializer/function contexts, cancellation, task/cross-task
teardown and public compiler delivery remain open. This is not full stream or
C1–C5 qualification and adds no qualified whole application workflow.


Prior later-syntax-error lifetime modes and all seventeen pending-answer cases
pass on this candidate. Carry and ClassMeta pass their unchanged complete
qualified workflows with exact original documents. Fresh 8 MiB normal and
16 MiB diagnostic boots match all 307,200 welcome pixels; both diagnostic
program/code-ownership/file-break phases complete. The cross-build records
explicit marker/raster evidence in memory-audit.json. Terminal regression input
pins are independently verified.


The final source26 run passes every loading stage and all prior compiler,
statement, executor and shared-stream observations, with 1,039 independently
verified input pins. Inventory guards pass all five tests; qualification counts
remain two of 686 whole workflows.


The final six mode runs use the corrected execution-fault report label; earlier
runner versions and their source snapshots remain preserved. This metadata
correction changes no fixture or production behavior.
