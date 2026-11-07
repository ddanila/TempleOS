# Shared command-line execution frontier

`ExeCmdLine` in `Kernel/KTask.HC` is the terminal statement executor used by
`PrsHostExecuteLine` for shared `exe {}` parsing. The source-loaded compiler
runner's `--execute-line` option loads its complete current body after the
actual LexStmt2Bin body. It adds no executor stub or replacement body. Normal
public native delivery and compile-time stream buffer ownership remain separate
open dependencies.

```
python3 tools/test-i386-public-execute-line.py --out build/execute-original-fresh
python3 tools/test-i386-public-expression-source.py build/IMAGE/kernel.img --execute-line --out build/execute-source-fresh
```

The original reference in `build/i386-public-execute-line-original-v3` passes
its 16-word oracle. It covers multiple statements, I64/F64 answer state, side
effects, empty statements, JUST_LOAD nonexecution, EXE_BLK's closing-brace stop,
locked and transient title behavior, valid-case data/code heap recovery, syntax
rejection and subsequent valid execution. The title and answer fields are
restored by the fixture after observation.

There is one intentional error-handling difference: the pinned original leaves
the task title changed after syntax rejection (word 11 is zero). The current
KTask body already includes an unwind fix and must restore it (word 11 one).
The fixture reports that observation independently of title restoration on valid
calls; native does not inherit the original's weaker error-path expectation.
The initial v1 oracle assumed the stronger behavior on the original and failed;
its raw output and terminal audit are retained.

The direct normal native baseline fails at the first missing public Lex use,
before execution (`build/i386-public-execute-line-api-baseline-v1`). This is not
an ExeCmdLine semantic pass or failure. The previous statement-frame candidate
is used unchanged; the additional source stage is diagnostic compiler delivery.

The first source25 run published the entire executor but timed out during its
contract (`build/i386-public-execute-line-source-v1`). Diagnosis found a real
standalone-source default mismatch: CompilerB.HH declares LexStmt2Bin's omitted
cmp_flags as CMPF_PRS_SEMICOLON (8), while CMain.HC defined it as zero. ExeCmdLine
calls it with two arguments. With zero, PrsStmt leaves a semicolon unconsumed and
the executor repeats it. The production definition now uses the same constant
as its public declaration. Explicit callers supplying zero retain that option.
The source runner checks the published third-argument metadata before executing
any contracts, and the executor fixture emits a per-input progress trace.

The corrected full run `build/i386-public-compiler-stream-source-v1` publishes
all 26 stages and passes all earlier contracts. The published argument-default
metadata is 8; the actual ExeCmdLine contract then returns sixteen ones. Against
the original's complete 128 bytes, only word 11 differs, for the documented title
unwind fix. The independent terminal audit verifies all 1,038 inputs and this
precise differential. Native valid-case data/code heap recovery is exact.

The production six-case independent ELF32 execution and target-opcode rejection
also pass (`build/i386-execute-line-default-production-v1`). Both x64 bootstrap
generations and all 1,762 full-build source pins pass. All sixteen native T32M
modules and the 454,184-byte Kernel32.BIN are byte-identical to the prior verified
statement-frame candidate; runtime/console ABI versions remain 88/248. The new
full image has fresh passing 8 MiB normal and 16 MiB diagnostic welcome checks,
including both program, code ownership and file-break cleanup phases. Evidence:
`build/i386-execute-line-default-cross-v1/terminal-source-audit.json` and
`build/i386-execute-line-default-memory-audit-v1.json`.

Normal public Lex/ExeCmdLine delivery, full stream ownership/unwind/AOT coverage,
and complete C1–C5 qualification remain open.
