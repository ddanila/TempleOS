# Escaped compile-time literal ownership

Compiler91 preserves a compile-time statement's output when CCF_HAS_MISC_DATA
marks a returned address into its literal pool. Previously the compile-time
executor freed every output, even though ordinary command execution already
retained escaped literals. The existing publisher transfers the retained code
allocation through parent controllers and into task storage. No public layout,
export or console250 table change is needed.

The normal fixture assigns a compile-time literal pointer to a public global,
checks the task answer and controller restoration, runs 32 later compilations,
churns public data/code heaps, and accesses the pointer through a generated
function. Native then closes that command's parent controller before a separate
command checks the same pointer. Finally 256 code-heap allocations across sizes
32 through 4096 bytes remain live and are filled with 0xA5 while the literal is
checked. All chunks are subsequently freed. Exact payload bytes include NUL.

```
python3 tools/test-i386-stream-literal.py --out OUT-ORIGINAL
python3 tools/test-i386-stream-literal.py IMAGE --out OUT-NATIVE
```

`build/i386-stream-literal-original-v3` passes twelve observations. On the prior
compiler90 image, `build/i386-stream-literal-baseline-v3` fails observation 11:
the live allocations replace the escaped literal with 31 bytes of 0xA5 followed
by NUL. This establishes reuse of freed storage rather than inferring lifetime
from unchanged bytes. Both inputs and raw exports are retained and audited.
The first two fixture versions passed on the baseline because their churn did
not force reuse of the relevant allocation size; they are not ownership proofs.

`build/i386-stream-literal-native-v1` passes all twelve observations (96 bytes).
Its exact 32-byte literal matches the original, SHA-256
`5b524b039b24bee3d5a821f2c719935fef02389f00ecf34e4d209904999dc924`.
Normal arithmetic pixels, additive packaging, volume integrity and all pinned
inputs are checked. The original runs both fixture calls in its restored Once
source; native uses separate console commands so parent-controller closure is
explicitly exercised there.

Both x64 bootstrap generations and the full 1,763-source native build pass,
with independent current source/build-input audits. The pending-answer fixture
passes all seventeen cases on the new image. These are component tests, not
complete stream qualification. Repeated reclamation/task death, error/OutMem,
cancellation, arbitrary escaping pointers, AOT and normal public compiler
delivery remain open. The literal belongs to retained code storage; the test
does not claim it is a separately Free-able allocation or establish heap recovery.


Final regressions: `build/i386-stream-literal-source26-v1` passes all 26 stages
and every compiler/statement/executor/stream observation, with all 1,039 input
pins independently verified. Carry-v1 and ClassMeta-v1 pass their unchanged whole
qualified workflows and exact original documents. Welcome8-v1 and diagnostic16-v1
match all 307,200 welcome pixels; both diagnostic program/code-ownership/file-break
phases complete. The cross-build's memory audit records exact marker and raster
checks. Inventory guards pass all five tests, with whole-workflow counts unchanged.
