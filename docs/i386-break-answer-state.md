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
prints its existing Exception diagnostic. Its task flags begin at 1281, so a
completed pending-bit assignment is 3329. Those architecture/runtime differences
are explicit; this is not whole break/API compatibility qualification. The
migrated compiler oracle retains every old command and Exception expectation,
adds baseline/locked-state checks, and requires the completed answer as well.
A dedicated native workflow is running in
`build/i386-answer-break-oracles-v1/build/i386-answer-break-native-v1`.
