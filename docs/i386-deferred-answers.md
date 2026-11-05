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
`build/i386-welcome-keyboard-gate-minimal-v1`. The earlier experimental full run at
`build/i386-answer-isolated-v1/build/i386-deferred-answers-gate-v1` stopped at
the obsolete Holder per-expression output oracle. Its terminal `failure.json`
pins the image, helper, checkpoint, screenshots and log. It is not a full pass. Existing console oracles
that expected intermediate automatic answers must be reconciled with the
original observations while retaining their commands and explicit-output
checks. The repeated-initial-prompt host color bug remains separate.

The active branch contains the new executable reference/native checks and
records the unchanged-runtime failure; its runtime remains unchanged while the
long-running gate's inputs are pinned. The experimental branch makes the tested
implementation reviewable without mutating those inputs. Full minimal
regressions, complete terminal/API/exception behavior, second-boot demo coverage,
all application qualifications and C1-C5 remain open.

## Nested declaration initializer reference

The extended original capture at
`build/i386-answer-prompt-reference-v8/result.json` passes nine cases. Three
additional cases execute integer, F64 and pointer documents from declaration
initializers. The outer ExePutS returns zero while the nested execution leaves a
pending task answer for CmdLinePmt. For the integer case the prompt presents 22;
the floating case presents 3.7500000; the zero pointer is recorded with the
original RT_PTR/RT_I64 alias and presented as integer zero. No automatic output
appears before the prompt.

The original floating calculation produces the canonical 3.75 representation
plus one ULP. The reference accepts that observed representation or canonical
3.75, requires the same raw bits after prompt consumption, and checks the actual
formatted value. Native formatting remains a separate architecture difference.
The earlier callback-only prototype did not cover these initializer cases;
final presentation must use the task's pending answer rather than the last
outer callback. The expanded native driver includes all three initializer
cases and checks their values and consumed flags. Native qualification of this
extension is pending.

## Revised experimental state and verification

Fork commit `82312957` on `experiment/i386-deferred-console-answers` fixes the
initializer gap in the current development worktree
`build/i386-answer-oracles-v1`. Presentation reads the task pending answer. Its
owned private compiler scope records pointer depth; the public task layout and
service ABI are unchanged. The private scope epoch/size changes, so the image
rebuilds all modules together. No class descriptor survives its control unwind.

The earlier prototype fails the new integer initializer, displaying stale 0x0
instead of 22 (`build/i386-answer-state-old-red-v1/result.json`). The revised
image passes all 34 commands in `build/i386-answer-state-native-v1/result.json`,
including integer/F64/pointer initializer values, consumed flags, exact pixels
and filesystem checks at 8 MiB KVM 486 without FPU and live WinMgr. Inputs remain
unchanged. It also passes the native task-symbol ownership test and the
1,361-file delivered-source audit. Two original bootstrap rebuild generations
pass; these are not native C5 generations. Paths in this paragraph are relative
to the current development worktree.

The migrated console oracles retain every old literal command and add eleven
explicit field checks where intermediate assignment output used to check state.
Explicit directory/report output and the original DocExe initializer expectation
remain intact. Focused compiler/document runs and a fresh complete diagnostic
gate (`build/i386-answer-state-gate-v1`) are running against the frozen revised
inputs. The first-prompt color fix is on that same experimental branch and has
its own passing physical-keyboard regression. Integration and full C1-C5
qualification remain pending.
