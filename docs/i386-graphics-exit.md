# Managed graphics presentation and forced Exit

NativeGraphicsPresent now separates the lifetime of its root-owned storage from
the task presenting a frame. NativeGraphicsReady validates that storage owner and
the existing context/buffer invariants; a different managed task can present
through the same exclusive presentation guard. A different managed task now
waits cooperatively for that guard; same-task recursion returns false. This is
a prerequisite for a managed refresh worker, not
a scheduled window manager or a complete arbitration policy.

## Executable task-lifecycle contract

```
python3 tools/test-i386-graphics-exit.py IMAGE --out build/FRESH-graphics-exit
```

The preceding image rejects the first child before entering its callback. The
observed result is 30 instead of 31
(`build/i386-c4-graphics-exit-red/result.json`); later exit cases are unexecuted.
The new contract requires callback entry, actual task termination before the
call returns, successful presentation reuse, intact/unlocked parent-owned
documents, and exact parent heap recovery after their deletion.

Five cases cover draw callback Exit, final callback Exit, frame-to-document,
document-to-frame and document/frame/document nesting. The parent restores the
final callback and its console surface before checking the returned mask. Each
case must return 31. The child inherits its parent's code/heap lifetime and the
parent waits for retirement before observing resources.

## One cleanup stack for mixed render scopes

Kernel/I386/RenderScope.HC provides a shared stack-resident cleanup mechanism.
Document scopes retain their lock/alias/depth/tag state. Compositor scopes retain
the drawing alias, and the outer native presenter retains its busy flag.
Normal return or caught exception unregisters each scope after cleaning its
resources. Scheduler task termination releases scopes in callback nesting order,
then invokes the previous cleanup chain.

A common stack matters: separate per-family drains could skip an intermediate
compositor cleanup when a document callback enters a frame and then another
document. The combined nesting test exercises that sequence. The structure is
also prepared to remove interleaved scopes from other cooperative tasks, but
concurrent-task interleaving is covered separately by the wait test below.

The presenter acquires its busy flag only after entering the protected scope,
and clears it before removing that scope on ordinary return. GraphicsFrameCore
tracks its temporary alias. Original/non-native uses retain no-op lifecycle
hooks and the established text/task/persistent/final layering.

All twenty-four commands pass on the corrected image, with 31 returned for all
five cases (`build/i386-c4-graphics-exit-green/result.json`). The renderer exit
suite (twenty commands, including terminal cleanup), ordinary tag exception/retry
suite and existing graphics group (eleven commands, all pixel checkpoints) also
pass: `build/i386-c4-graphics-exit-doc-regression/result.json`,
`build/i386-c4-graphics-exit-catch-regression/result.json` and
`build/i386-c4-graphics-exit-regression/result.json`.

Bootstrap rebuild, native cross-build and 386 boot audit pass
(`build/i386-c4-graphics-exit-cross`). Startup passes at 8 MiB in 45.88 seconds
without build-provider loads (`build/i386-c4-graphics-exit-startup/result.json`).

## Cooperative presentation and cancellation

```
python3 tools/test-i386-graphics-wait.py IMAGE --out build/FRESH-graphics-wait
```

Each scope records whether it acquired the lease. A waiting or recursive scope
cannot release another scope's lease during normal cleanup or task termination.
Acquisition yields through the managed scheduler and checks readiness again on
every attempt. Text presentation registers its lease in the same cleanup stack.

The test starts a graphics holder inside a document callback, lets the parent
document scope close below the child's scopes, and starts a competing graphics
or text presenter. The waiter must stay alive without returning until the
holder is killed. Two further cases kill and replace the waiter first; this
must leave the holder's lease intact. Checks include recursive refusal,
retained tags, unlocked documents, presentation retry and exact parent-heap
recovery. This exercises managed APIs, not raw-console or focus arbitration.

The prior image returns 117 instead of 127 in the first case
(`build/i386-c4-graphics-wait-red/result.json`). All 25 commands pass on the
corrected image, with 127 in all four cases
(`build/i386-c4-graphics-wait-green/result.json`). The prior 24-command Exit
suite remains green (`build/i386-c4-graphics-wait-exit-regression/result.json`),
as do all 16 graphics/text-frame commands and their pixel checkpoints
(`build/i386-c4-graphics-wait-frames/result.json`). Bootstrap, cross-build and
386 boot audit pass; 8 MiB startup passes in 45.83 seconds without build-provider
loads (`build/i386-c4-graphics-wait-startup/result.json`).

## Remaining qualification

Bulk raw console/focus uploads now join the presentation lease and have separate
[contention and stale-focus contracts](i386-raw-presentation.md). Native mouse
overlays now share that lease and validate the displayed backing; see
[mouse presentation](i386-mouse-presentation.md). Original cursor composition,
full editor/view ownership and debugger transitions during a held frame still
need integration. Storage-owner termination, arbitrary callback-installed cleanup
wrappers, all allocator/geometry failures and scheduled refresh remain open.
Do not enable a background worker merely because the forced-exit cases pass:
the automatic A/B document gate and the rest of the refresh plan still apply.
