# Managed graphics presentation and forced Exit

NativeGraphicsPresent now separates the lifetime of its root-owned storage from
the task presenting a frame. NativeGraphicsReady validates that storage owner and
the existing context/buffer invariants; a different managed task can present
through the same exclusive presentation guard. Busy or recursive presentation
still returns false. This is a prerequisite for a managed refresh worker, not
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
concurrent-task interleaving is not separately qualified by these cases.

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

## Remaining qualification

Callbacks which yield while another presenter, raw console, editor or focus
change competes for display ownership still need an arbitration policy and
end-to-end tests. Storage-owner termination, arbitrary callback-installed cleanup
wrappers, all allocator/geometry failures and scheduled refresh remain open.
Do not enable a background worker merely because the forced-exit cases pass:
the automatic A/B document gate and the rest of the refresh plan still apply.
