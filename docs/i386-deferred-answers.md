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

Console answer callbacks capture the last value and copy its raw type/pointer
count while the class descriptor is live. Presentation happens after the source
completes and its control has been unwound. A final void result clears answer;
new_answer is consumed. No class pointer is retained for display after unwind.
Nested NativeExeDoc requests execution without automatic answer presentation;
its explicit output and result return remain active. The low-level compiler's
per-expression callbacks, command/answer counters and public service ABI remain
unchanged. Current native numeric formatting is retained; original prompt timing
and `ans=` formatting are not qualified by this change.

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
`build/i386-welcome-keyboard-gate-minimal-v1`. A full diagnostic run for the new
runtime is also live at `build/i386-deferred-answers-gate-v1` inside the isolated
worktree. Their terminal outcomes are still required. Existing console oracles
that expected intermediate automatic answers must be reconciled with the
original observations while retaining their commands and explicit-output
checks. The repeated-initial-prompt host color bug remains separate.

The active branch contains the new executable reference/native checks and
records the unchanged-runtime failure; its runtime remains unchanged while the
long-running gate's inputs are pinned. The experimental branch makes the tested
implementation reviewable without mutating those inputs. Full minimal
regressions, complete terminal/API/exception behavior, second-boot demo coverage,
all application qualifications and C1-C5 remain open.
