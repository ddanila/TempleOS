# Normal buffer compilation

Console interface 264 publishes the original `CmpBuf` signature through
`Kernel/I386/PublicAssembly.HH`. Its first call loads the existing four complete
assembly/join stages. The callback uses the complete shared
`Compiler/CmpBufCore.HC` and `CmpJoinCore.HC` bodies; it does not select a smaller
parser or a separate buffer compiler. The original x86-64 compiler includes the
same buffer body. `I386AOTDel` is also shared with the existing module writer in
`Compiler/I386/AOTReleaseCore.HC` for caller-side packet cleanup.

The source buffer remains borrowed. A successful result is a caller-owned
`CAOT` packet with its original import/export, absolute relocation, heap-global
and code-buffer ownership. The contract also consumes executable packets through
the production `CmpFixUpJITAsm`: that routine releases the packet records and
root while retaining the code buffer, which the caller releases after execution.
This test consumer covers the recorded packet forms; it does not qualify every
module record or replace the native module serializer.

## Native context corrections

Public `CmpCtrlNew` now supplies `CCF_TARGET_I386` in the native console. The
shared constructor defaults to zero extra flags on the original architecture.
Without the native flag, the shared parser emitted parameter accesses at
`EBP+16`, although i386 calls place the first argument at `EBP+8`. Retained
buffer v1/v2 failures show wrong internal-call, default-argument and loop values.
The same sources return 26, 26 and 45 after target selection, with exact packet
cleanup. See [the control checks](i386-public-control.md) for the explicit
architecture-bit oracle.

Map writing exposed a second integration failure. `CmpBuf` queues an ordinary
public control; DolDoc dollar parsing creates a private arena control inside it.
`NativeDocParserClose` previously passed the borrowed public boundary to the
private arena validator. The validator correctly rejected that record, so the
map's rich link failed. Closing now unwinds nested arena controls to the parser's
own validated control, then deletes that control. It preserves the outer queue
entry without weakening arena ownership checks. Complete copied-writer probes
pass outside the queued context and fail inside it; the published writer also
passes outside that context. The final public API contract writes its map with
the actual queued control.

## Contract and evidence

```sh
python3 tools/test-i386-public-buffer.py IMAGE --out CONTRACT_OUT
python3 tools/check-i386-buffer-code.py CONTRACT_OUT --out ELF_OUT
```

`build/i386-public-buffer-contract-v5/result.json` passes fourteen cases: scalar
and wide results, a block, ordinary functions, a default argument, initialized
global data, literal `#exe` streaming, a polling loop, an external import, map
output, empty/null/semicolon buffers, and returned literal data. Every call
preserves the borrowed source and outer control queue and reports zero errors
and warnings. The optional arguments are exercised both explicitly and by their
defaults. All six services publish exactly once; a fresh normal expression and
arithmetic framebuffer recovery pass afterward. Packet metadata and code bounds
are checked independently of the executed result.

The exact map contains the original default-source link with drive substitution,
one debug bin, line range 1..1 and native code offsets 0..51. The only filesystem
changes are the fixture and map. The image's native filesystem audit passes.
`build/i386-public-buffer-elf-v1/result.json` independently executes six saved,
unrelocated packets as Linux ELF32 code, including internal calls and defaults.

Literal streaming deliberately retains generated literal data until its owner
task exits, as the original `ExeCmdLine` policy requires. The pinned original
`ExePutS`/`ExeCmdLine` probe in
`build/i386-public-buffer-stream-reference-v3` returns 42 and retains 40 bytes
on each heap; it is not a complete original `CmpBuf` packet oracle. Native
streaming retains 104 bytes on each heap. The literal case runs in an owned
child task: it retains its data while alive, terminates successfully, and restores
both backing-heap usage and allocation counts exactly. All other buffer cases,
including cold loading and map writing, have zero caller heap deltas. Counters
are neither subtracted nor adjusted.

The full native contract does not qualify failed `CmpBuf` ownership, OOM,
asynchronous cancellation, complete file/module compilation, every relocation
form, full desktop/apps, or native release generations. In particular, the
original failed-buffer control lifetime remains open. C1-C5 remain active and
bundled qualification remains 2/686.

## Regression boundaries and remaining ownership work

The final source/image audit is
`build/i386-public-buffer-cross-v3/final-verification-audit.json`. It verifies
1,847 source hashes, 26 build inputs, all sixteen modules, both original bootstrap
generations, the complete shared bodies and sixteen scoped receipts. The final
image passes the ten-group extended expression suite, all 46 error-cleanup rows,
the assembly contract, twelve public control checks, and the 24-check lexer
oracle at 8 MiB. Original control and lexer oracles retain zero extra target flags;
native oracles require exactly the requested flags plus `CCF_TARGET_I386`.
Nested DolDoc expressions and all ten printed-field cycles pass at 64 MiB KVM.
The two 16 MiB TCG diagnostic phases and complete 307,200-pixel welcome frames
at 8/16 MiB pass as functional/resource observations.

The initial 8 MiB TCG dollar runs and an isolated startup run terminate at their
180-second startup limit, before any dollar assertions. They remain failures.
A separate 600-second functional observation reaches startup in about 219 seconds
and then checks the welcome frame and arithmetic. This does not qualify the
60-second startup gate or turn the failed short-budget runs into parser passes.
`tools/test-i386-doc-dollar-parser.py` now accepts explicit native RAM/accelerator
profiles while preserving its old defaults; the 64 MiB results record that profile.

`tools/test-i386-doc-public-boundary.py` adds a deliberately failing C4 cleanup
oracle, retained in `build/i386-public-buffer-doc-boundary-v2`. A valid command
and two malformed commands preserve the public queue/flags and successfully
reclaim their owner task. The original grammar handles malformed commands by
returning `DOCT_ERROR`, not by propagating the compiler exception. The malformed
button retains its allocated tag while clearing ownership flags, leaving a
16-byte native caller delta after ordinary entry/document deletion. The pinned
original probe in `build/i386-public-buffer-doc-error-reference-v1` returns the
same error type, zero ownership flags and non-null tag. Its whole diagnostic
heap deltas include other original output allocations and are not an isolated
16-byte baseline. The shared conversion body is unchanged at this checkpoint.
That checkpoint retained the failing ownership oracle. The subsequent
[partial-entry ownership correction](i386-dollar-error-ownership.md) releases
those payloads and expands the test without adjusting counters.

The failed-buffer ownership contract and preserved failing baseline are described
in [the C4 failure checkpoint](i386-public-buffer-errors.md). Successful buffer
coverage above does not qualify that outstanding cleanup path.

Ten absorbed compiler-error buffer paths now release their control, code and
partial packet graphs before returning NULL, with exact caller heap recovery.
The canonical comparison and output-cache/diagnostic ownership boundaries are
in [the failure ownership checks](i386-public-buffer-errors.md). Broader failure
modes and complete C1-C5 qualification remain open.
