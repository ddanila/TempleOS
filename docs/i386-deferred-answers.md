# Deferred console answers: original baseline and isolated implementation

The native console emitted an automatic answer for every non-void expression,
including expressions inside included scripts and nested document execution.
The unchanged RegistryDemo consequently printed extra 0/1234 lines before its
actual output. The original records answers while executing and presents the
final result at a prompt.

## Original six-case observation

`tools/test-i386-answer-prompt-reference.py` restores the pinned original OS and
executes the real original ExePutS, includes, ExeDoc and CmdLinePmt. The private
prompt routine is found through its original function/system-export symbol; its
body is not replaced. Real GetStr consumes queued In input. Documents and task
answer fields are captured before and after prompt consumption.

`build/i386-answer-prompt-reference-v5/result.json` passes:

- `11;22;` and an included value file produce no execution-time scalar output;
  the prompt emits only 22 and clears new_answer while preserving answer=22.
- An included file ending with a void call has no scalar answer. The prompt
  clears its answer value to zero and consumes new_answer.
- Explicit MARK output remains visible; a final void call produces no scalar.
- Nested ExeDoc does not print its intermediate scalar results.
- After `41;Unknown prompt_bad;`, ExePutS reports failure, but the completed
  answer remains 41 and is presented/consumed at the following prompt.

The error case waits for the actual RLf_ADAM_SERVER bit to become set; it never
sets that flag. The earlier v4 attempt entered the real boot debugger because
LexExcept intentionally does so before server readiness. Earlier v1 could not
find the private function through a function-only lookup; v2 used an incorrect
empty-document assertion. v3 is a valid five-case capture. Empty DocSave output
is zero bytes, not a lone 0x05 marker. None of these earlier attempts replaces
the six-case passing baseline.

## Isolated runtime change

The implementation is on the user's fork branch
`experiment/i386-deferred-console-answers`, in the detached worktree originally
created at `build/i386-answer-isolated-v1`. It is not yet merged into the active
`experiment/i386-cache-merge-progress` branch, whose complete gate remains live.

Console execution defers automatic output until the source completes. Final
presentation reads the task's pending answer and raw type. Its owned private
compiler scope also records pointer depth, since the public RT_PTR value aliases
RT_I64. That private scope has a new epoch and size; all modules are rebuilt
together. The public task layout and service ABI are unchanged. No class pointer
is retained after its compiler control is unwound. Nested NativeExeDoc executes
without presenting automatic answers, while explicit output remains active.
The low-level per-expression callbacks and counters remain unchanged. Current
native numeric formatting is retained; original `ans=`/timing formatting is
still unqualified.

The first callback-only prototype missed declaration initializers that execute
a nested document: the outer callback can describe an earlier expression while
the nested document leaves the actual pending task answer. The extended original
nine-case capture is `build/i386-answer-prompt-reference-v8` in the main worktree.
The old prototype fails the expanded native test at its integer initializer,
printing stale `0x0` instead of 22, with unchanged inputs, in
`build/i386-answer-oracles-v1/build/i386-answer-state-old-red-v1/result.json`.
The revised task-owned metadata avoids both that stale value and a borrowed
class descriptor. All 34 expanded native commands pass in
`build/i386-answer-oracles-v1/build/i386-answer-state-native-v1/result.json`,
including integer/F64/pointer initializers, exact checkpoint pixels, consumed
answer flags and filesystem integrity. The image and runner inputs remain
unchanged; the run uses 8 MiB KVM 486 without FPU and live WinMgr.

Evidence in that worktree:

- `build/answer-isolated-rebuild-v1.log`: two original bootstrap rebuild
  generations pass; not native C5 release generations.
- `build/i386-deferred-answers-v1`: native image builds, 386 boot audit passes,
  and all 1,361 delivered source/document files match the worktree.
- `build/i386-answer-prompt-native-v2/result.json`: all 22 commands pass at
  8 MiB KVM 486 without FPU with live WinMgr and exact checkpoint pixels. They
  cover final values, includes, void suppression/clearing, explicit output,
  nested ExeDoc/ExePutS, declaration-only preservation, pointer/F64/signed/unsigned
  formatting, syntax-error pending value, task flags and filesystem integrity.
  Inputs remain unchanged. The earlier unchanged-runtime test in the main
  worktree (`build/i386-answer-prompt-native-red-v1`) fails the same final-answer
  expectation, establishing a regression baseline.
- `build/i386-registry-demo-native-v2/result.json`: the unchanged demo now passes
  its original-derived first-launch display, increment/time persistence,
  fixture identity and filesystem checks at 64 MiB KVM/live WinMgr. This does
  not prove second launch or reboot persistence.

The registry-demo driver also validates its source against the reference's
relative pinned-source map, allowing the same original capture to be used from
an isolated checkout without depending on its absolute host path.

## Integration and remaining gates

The original complete default TCG run remains live in the main worktree at
`build/i386-welcome-keyboard-gate-minimal-v1`. The earlier prototype's full
run at `build/i386-deferred-answers-gate-v1` in the first isolated worktree is
terminal: it stopped at `Holder h;h.p=0;h.value=42;` because the old oracle
expected both assignment answers. Its `failure.json` pins the checkpoint, image,
helper, screenshots and log; this is not a full-suite pass. Existing console oracles
that expected intermediate automatic answers must be reconciled with the
original observations while retaining their commands and explicit-output
checks. The repeated-initial-prompt host color bug has a separate focused regression
and fix documented in `docs/i386-prompt-identity.md`.

The active branch contains the new executable reference/native checks and
records the unchanged-runtime failure; its runtime remains unchanged while the
long-running gate's inputs are pinned. The experimental branch makes the tested
implementation reviewable without mutating those inputs. Full minimal
regressions, complete terminal/API/exception behavior, second-boot demo coverage,
all application qualifications and C1-C5 remain open.

## Oracle migration and revised build

The current development worktree is `build/i386-answer-oracles-v1`. Its console
oracles retain every previous literal command and all explicit directory/report
output. Eleven added state checks preserve field coverage where intermediate
assignment echoes used to provide it. The original `DocExe` initializer check
still requires its nested answer. The command-retention audit is
`build/oracle-migration-retention.json`; a passing static audit does not replace
running the commands.

The revised runtime passes two original bootstrap generations in
`build/answer-state-rebuild-v1.log`, builds `build/i386-answer-state-v1`, passes
the 386 instruction audit and all 1,361 delivered-source comparisons, and passes
the native task-symbol ownership test in
`build/answer-state-task-symbols-v1.log`. These are scoped prerequisites, not C5
native rebuild generations or a complete minimal regression result. Focused
compiler and document groups are running against this image.

## Combined picker and answer runtime

The worktree `build/i386-answer-break-oracles-v1` combines this runtime with the
consumed-mouse-transition test sequencing. Both original bootstrap generations
pass in `build/i386-answer-picker-combined-rebuild-v1.log`; the normal image is
`build/i386-answer-picker-combined-v1`. Its 386 audit and all 1,361 delivered
source/doc comparisons pass. The combined image passes all 34 exact-pixel
answer commands in
`build/i386-answer-oracles-v1/build/i386-answer-picker-combined-prompts-v1/result.json`
and the complete isolated TCG picker workflow in
`build/i386-answer-picker-combined-clicks-v1/result.json` in the main worktree.
Inputs remain unchanged. These are scoped regressions, not native C5 generations.

The separate instrumented compiler session passes 147 commands at 8 MiB TCG
486 without FPU/live WinMgr in
`build/i386-answer-break-oracles-v1/build/i386-answer-break-compiler-v1/result.json`.
It reads zero flags immediately before the pending assignment, then verifies
2048, cleanup, locked/unlock behavior, scalar formats and module building. The
frozen runner source and hash are stored beside that result. Its 77.8-second
startup is not evidence of the 60-second minimal startup gate. A second run
without the extra pre-break query remains running, because that query could
otherwise mask the earlier 3329 discrepancy. No new shared break oracle is
qualified yet.

The repeat without the extra pre-break query now passes all 146 compiler-group
commands at 8 MiB TCG 486,-fpu/live WinMgr in
`build/i386-answer-break-compiler-unprobed-v1/result.json` in this worktree.
The exact runner is preserved beside it. The isolated physical hotkey group
also passes all 17 commands, including six Ctrl-Alt-C cases and the locked
unlock's completed 2048, in `build/i386-answer-picker-breaks-v1/result.json`.
Focused startup is 77.9 and 76.0 seconds respectively, not 60-second startup
qualification. The old 3329 has not recurred but remains a historical unexplained
failure. No oracle accepts it as an alternative.

The final command-retention audit (`build/answer-oracle-retention-final-v1.json`)
checks occurrences rather than just unique strings: all 509 original command
expressions remain, with thirteen added explicit state checks. Pending-break
oracles now retain Exception and require the completed value 2048. The checked
unprobed runner is byte-identical to the committed helper.

A new original differential exposes a separate source-publication gap; see
`docs/i386-completed-declaration-publication.md`. Completed functions survive
errors and breaks on the original, while the normal native public API loses one
after a caught custom throw. Existing BreakPrivate rollback checks are legacy
native behavior, not original fidelity. Public Break availability is also open.
The new failing checks remain strict; full C4/API/OS qualification is not claimed.
