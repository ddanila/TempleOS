# Live User exception and interruption recovery

`tools/test-i386-live-user-prompt.py --recovery` exercises the normal User child
through physical keyboard input. It first requires the unchanged complete prompt
oracle for idle, integer and floating-point input. It then exercises:

1. An uncaught `throw('Recover')` reaching the original terminal catch.
2. An undefined identifier reaching the compiler error path.
3. Physical Ctrl+Alt+C after an executed marker from an infinite yielding loop.

After each case, the observer first requires its exception witness and the
original idle-prompt flag. Only then may the host type separate marker and
arithmetic commands, which must execute, produce
the original deferred answers 1 and 42, and restore the original idle directory
prompt. The observer captures task answer/type/new-answer/prompt fields and full
DolDoc bytes. Every previously captured document prefix must remain unchanged.
The new document portion must contain the exact command echoes, the appropriate
exception/error witnesses, two elapsed fields and both deferred answers. Stack
links are retained in the raw documents without cross-architecture equality.
These are selected recovery checks, not full error-document equivalence.

The fixture explicitly zeros its three trigger words, and the host requires
that zero export before sending recovery input. The first diagnostic fixture
omitted initialization. JIT globals use MAlloc in PrsGlobalCore, so original
zeros were incidental and native could capture phases prematurely. That fixture
and its initial runs are excluded; the versioned native run was interrupted
once the defect was confirmed. See
`build/live-user-recovery-prototype-v1/invalid-fixture.json`. This was a fixture
error, not evidence of different global-initialization semantics.

The next native run exposed a host synchronization error: input was sent while
LexExcept was still reporting and executing FlushMsgs. Its screenshot shows
truncated recovery commands followed by new compiler errors. The corrected
observer waits for the specific exception witness and fresh idle prompt before
signaling the host to type recovery input. The earlier timing-dependent run is
excluded; see `build/live-user-recovery-native-v2/invalid-synchronization.json`.

Recovery mode implies the existing retirement mode: physical Exit must end
public task validity, and native physical memory must show no managed child
record and a free heap block containing the former child address. Parent
observation buffers remain allocated. This does not establish total heap
recovery, non-yielding loop interruption, all syntax/include failures, borrowed
control handling, or complete C2/C4 qualification.

```sh
python3 tools/test-i386-live-user-prompt.py --recovery --out FRESH_REFERENCE
python3 tools/test-i386-live-user-prompt.py --recovery --disk IMAGE --out FRESH_NATIVE
```

`tests/i386/live-user-recovery-reference.json` pins the corrected fixture and
selected observations. Its initial observation receipt is explicitly excluded
as acceptance; corrected versioned runs independently verify the same expected
values and witnesses. The pinned original source manifest and existing prompt
oracle retain their provenance checks.


The V3 native observer continuously serialized the document while awaiting the
next exception. The failure screenshot shows a shortened function definition
and a compiler error before the loop marker. V4 checks the expected exception
state first and serializes only afterward; the same complete program then
passes. This does not establish an OutU8/parser incompatibility, nor prove input
delivery under continuous concurrent DocSave pressure. That stress observation
remains unqualified and is retained in
`build/live-user-recovery-native-v3/observation-limit.json`.

## Corrected evidence

Both V4 runs pass the full initial prompt oracle and all three recovery cases.
Native then passes independent physical record/free-block reclamation. The
candidate is the disposable public-control ownership V3 image, SHA256
2c8bfa935004e8f8d307c053edd99211f99c90122c839bc945f55f1e56b6546e.

- `build/live-user-recovery-reference-v4/result.json`: PASS, SHA256
  bbfb587550087761f5eef5d4075b06b210715cf79d1ff9585dce8247abce51a8.
- `build/live-user-recovery-native-v4/result.json`: PASS, SHA256
  438b00724da2f5b81af870c52d8faeafc9560476a3caa0e59448ef9a0ea49a86.
- `build/live-user-recovery-comparison-v1/result.json`: PASS, SHA256
  f975821772adf6d4491c59f43fa310dd52af426b44584026d31c5ee1970c9b6a.

The independent comparison rehashes every pinned input and checks exactly one
Ctrl-down, Alt-down, C-down/up, Alt-up, Ctrl-up sequence in each raw key trace.
Its first Ctrl event occurs after the executed loop marker in the debug log.
The fixture retains failed function documents if compilation prevents entering
the loop. Original/live source provenance, raw documents and raw key events
remain available; nothing is rounded or replaced in the saved observations.

This extends the ownership prototype's evidence to these selected exception,
compiler-error and yielding-loop break paths before Exit. Production remains
unchanged. Minimal-memory support, input pressure, broader errors and full
C1-C5/inventory qualification remain open.
