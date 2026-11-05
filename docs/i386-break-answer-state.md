# Answers around break checkpoints

The revised task-answer presentation exposed an old oracle assumption in the
focused compiler run: command 114 set `TASKf_PENDING_BREAK`, reported the native
Exception line, and displayed its completed flags assignment, 3329. The previous
oracle expected only Exception. The terminal run remains a failure in
`build/i386-answer-oracles-v1/build/i386-answer-state-compiler-v1/failure.json`,
with hashes of its image, runtime, helper, checkpoint and frames. Commands through
113 passed; later commands are not qualified by that run.

`tools/test-i386-answer-break-reference.py` executes real original ExePutS and
CmdLinePmt with four cases. It waits for actual server readiness, captures task
answer/type/flags before inspection, and uses real queued GetStr input. A still
pending synthetic break bit is restored only after that capture, so the host
inspection itself is safe. No compiler, break or prompt routine is substituted.

`build/i386-answer-break-reference-v2/result.json` passes with unchanged inputs:

- `41;Break;` leaves answer 41, and the prompt displays and consumes it.
- Setting the pending-break flag, with or without a preceding 41, completes its
  assignment and leaves 2048 as the original task's pending answer. That task's
  original initial flags are zero. The pending bit remains set until the fixture
  restores it after capture.
- A function that sets the pending bit and calls BreakUnlock before returning
  leaves the earlier 41. The interrupted function does not replace that answer.

The initial v1 capture recorded these values without qualifying them; v2 adds
exact record and prompt-output assertions. Empty pre-prompt documents remain
required. No intermediate automatic answer is accepted.

The native compiler checks pending breaks at explicit safe checkpoints and
prints its existing Exception diagnostic. A focused raw-flags probe passes with
initial flags zero, pending answer 2048, and cleared flags afterward in
`build/i386-answer-break-oracles-v1/build/i386-answer-break-flags-v1/result.json`.
Thus the 3329 seen after the long compiler prefix is not yet explained. A fixed
1281 baseline assumption failed a separate native check and is not accepted as
an oracle. The original result establishes retention of completed answers, not
the correctness of arbitrary native values.

The dedicated native workflow and full compiler prefix are being rerun with an
explicit baseline-flags probe. Their sources are isolated in
`build/i386-answer-break-oracles-v1`; no new break oracle is committed or merged.
Existing commands and Exception checks remain in that experimental migration.
Native immediate pending-break handling and diagnostic display remain explicit
architecture differences; whole break/API compatibility is unqualified.

## Scoped native checks

`tools/test-i386-answer-break.py` passes all 15 native commands in
`build/i386-answer-break-oracles-v1/build/i386-answer-break-native-v2/result.json`,
with exact pixels and unchanged inputs. These check completed 41 through a
direct break, pending assignment 2048, consumed flags/answer, interrupted private
publication, locked pending state and unlock, and fresh compilation afterward.
It uses 8 MiB KVM 486 without FPU and live WinMgr. The earlier v1 assumed a
1281 baseline and failed; that assumption was removed rather than accepted. The
committed driver's report text clarifies that immediate checkpoint/diagnostic
behavior differs from original; its checked commands are unchanged from v2.

The four-command cold flags probe also passes on TCG in
`build/i386-answer-break-oracles-v1/build/i386-answer-break-flags-tcg-v1/result.json`.
Both cold accelerators therefore produce zero initial flags, pending answer
2048 and consumed flags afterward. The 3329 in the longer compiler session
remains an open discrepancy. That session is being rerun with the complete
original command prefix and an additional baseline-flags read; no full-group
pass or whole break qualification is claimed.
