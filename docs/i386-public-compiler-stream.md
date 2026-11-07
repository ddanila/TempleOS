# Shared compiler stream execution

The original contract passes all nine observations in
`build/i386-public-compiler-stream-original-v2`. It checks exactly-once effects,
appended text fragments, expression-context injection, nested blocks, full-width
I64 and F64 generated expressions, empty generated text, restored stream queues,
flags/title state, and directory emission from an existing Kernel source path.
The expected drive letter comes from the running system rather than a fixed
original/native drive assumption. The complete 72-byte output and independently
verified input hashes are retained.

```
python3 tools/test-i386-public-compiler-stream.py --out build/compiler-stream-original-fresh
python3 tools/test-i386-public-expression-source.py build/IMAGE/kernel.img --compiler-stream --out build/compiler-stream-source-fresh
```

The source runner loads the complete current ExeCmdLine body from KTask.HC,
then the complete shared DirFileCore.HC body and StreamPrint/StreamDir bodies
from CMisc.HC. They use the actual shared PrsStreamBlkCore, LexStmt2Bin, lexer
reinjection and target backend. Bodies are not replaced with adapters or stubs.
The contract registers its public controller on the task's controller queue,
so StreamPrint finds the real innermost stream block through Fs->last_cc.

This source-loaded namespace is distinct from the existing private native
compiler's StreamPrint provider, whose buffers use private parser ownership.
Normal public compiler delivery remains open. Normal public DirFile delivery is
covered by the follow-up in docs/i386-dir-file.md. The directory observation
covers one real existing source context, not the full DirFile upward-search API.
Error/OutMem/cancellation recovery, nested includes and repeated reclamation
remain unqualified. Literal-bearing statement code is intentionally retained
under CCF_HAS_MISC_DATA; this contract is not a heap-recovery oracle.

`build/i386-public-compiler-stream-source-v1` passes all 26 stages, all earlier
compiler regressions and every new stream observation. Its complete 72 bytes
match the original reference exactly. The same run passes all sixteen executor
observations, including native title restoration, after verifying the published
LexStmt2Bin default consumes semicolons. All 1,038 pinned inputs are independently
checked in its terminal audit. This establishes the tested source-loaded shared
compiler path; it does not replace the normal native compiler provider.
