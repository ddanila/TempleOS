# Raw terminal presentation ownership

The native ConsolePresentText path now uses the graphics presentation lease
after graphics startup. Ordinary text uploads, explicit graphics/text frames,
console restoration and terminal focus uploads cannot pass one another while a
managed frame callback yields. Early display initialization retains its direct
upload path, before a graphics owner exists.

Same-task raw presentation defers the upload and leaves dirty rows pending;
it must neither deadlock nor release the caller's outer frame lease. A foreign
caller waits through the managed scheduler. Its cleanup scope owns the lease
only after acquisition, so killing an unacquired waiter cannot release another
task's frame. Normal return and exception cleanup release an acquired lease.

## Surfaces must be revalidated after waiting

Before waiting, the raw path identifies a terminal by its surface pointer and
records its task and task number. After acquisition it checks task validity,
the task number, current focus, and the live terminal's surface identity before
dereferencing the saved surface. A superseded request returns without uploading
or consuming dirty rows. A retired terminal's old surface is never reused by
that request. Task-number comparison also guards against task-address reuse;
the tests below do not require allocator reuse at a particular address.

This validation matters even when the old terminal remains alive: resuming an
older request after a newer focus upload must not paint the old window over the
current focused terminal.

## Executable contracts

```
python3 tools/test-i386-raw-present-wait.py IMAGE --out build/FRESH-raw-wait
python3 tools/test-i386-focus-present-wait.py IMAGE --out build/FRESH-focus-wait
```

The eighteen-command raw gate covers four combinations of normal/terminated
frame holders and ordinary/canceled-and-replaced raw waiters. Each case requires
mask 127, recursive raw deferral retaining the outer lease, actual waiting,
successful restoration, task retirement, exact parent heap and the complete
console framebuffer. An explicit graphics retry follows. The old image returns
125 instead of 127 (`build/i386-c4-raw-present-wait-red-final/result.json`),
rejected directly by the current fixture's independent VGA check. All eighteen
commands pass on the corrected image, with mask 127 in all four cases
(`build/i386-c4-raw-present-wait-final/result.json`).

The twenty-one-command focus gate queues two focus requests behind a yielding
frame and suspends the older waiter. It lets the newer request finish, then
resumes the old waiter last. Before any cleanup/refocus, independent full VGA
pixels must still show the newer terminal. One case retains the old terminal;
the other retires it before releasing the holder. A real focus-next hotkey
returns to the root console, followed by retirement and exact parent-heap checks.
The input harness supports an explicit exit-key chord so this observation ends
through the delivered focus hotkey while preserving the root's command history.

Both cases return mask 127 and pass their full-frame terminal observations
(`build/i386-c4-focus-present-wait-verified/result.json`). The final source image
also passes all sixteen graphics/text-frame commands and pixel checkpoints,
the existing two-terminal history/focus/exit workflow, and terminal editor
kill/save/recovery:
`build/i386-c4-raw-present-final-frames/result.json`,
`build/i386-c4-raw-present-final-terminals/result.json` and
`build/i386-c4-raw-present-final-terminal-kill/result.json`.
Bootstrap rebuilding, cross-build and 386 boot audit pass. Startup passes at
8 MiB in 49.90 seconds without build-provider loads
(`build/i386-c4-raw-present-final-startup/result.json`).

## Remaining display work

Mouse-overlay helpers still upload directly. Debugger transitions during a held
frame, full editor/mouse arbitration,
frame and raw-view selection for scheduled refresh, refresh-worker document/code
lifetime, storage-owner termination and the automatic A/B refresh gate remain
open. These tests qualify bulk terminal uploads and stale focus requests, not a
complete window manager or C2/C4 completion.
