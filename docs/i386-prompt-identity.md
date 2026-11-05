# First-prompt identity in visual checks

The welcome checker previously remembered the first submitted line as text.
Once that row scrolled away, a later identical command was incorrectly treated
as the initial black prompt. The real later prompt is green. The focused
compiler session stopped before command 124 was submitted; only fourteen prompt
pixels differed from its valid cursor-on expected frame.

Expected transcript rows now mark the actual first input row with a str subtype.
That marker travels with retained history and disappears when the row scrolls
away. Later equal strings stay ordinary rows. The raw keyboard sequence marks
its first edited row similarly. Welcome styles are computed by a shared helper;
all-pixel comparisons, cursor variants, colors, links and explicit row overrides
remain active. No guest/runtime code changes in this correction.

Run `python3 tools/test-i386-prompt-identity.py IMAGE --out FRESH`. The physical
keyboard workflow repeats the first command while its original row is retained,
prints sixty-four newlines, repeats the command after its original row has
retired, then executes fresh arithmetic. It uses 8 MiB KVM 486 without FPU with
live WinMgr and exact checkpoint pixels. An explicit `--runner` selects a
baseline host helper without editing either helper in place.

In `build/i386-answer-oracles-v1`, the baseline
`build/i386-prompt-identity-red-v1/result.json` fails after scrolling and before
submitting the repeated command. `identity-fixed-v1/result.json` passes every
checkpoint with unchanged source/runner pins. Its runner source snapshot is
retained beside the result. Re-rendering the original focused-session capture
with the corrected styles also matches the full frame exactly. The captured
failure remains in `build/i386-welcome-compiler-v1/failure.json` in the main
worktree. This is a host oracle fix, not evidence that the remaining focused
compiler cases or complete minimal gate have passed.
