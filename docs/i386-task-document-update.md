# Protected original task-document updates

The native runtime now exposes the original `DocUpdateTaskDocs` entry point.
The implementation remains in `Adam/DolDoc/DocRecalcLib.HC`, shared with the
original system. It updates title/border metadata, selects and renders the
shown display document with cursor handling, then renders the border document
with the task's scroll temporarily cleared. The renderer still executes in the
calling worker's Fs context.

A native task-update scope registers the target owner before reading its fields
or selecting either document. It participates in the common render cleanup
stack and managed owner-retirement barrier. Document recalc scopes continue to
protect each document's memory/window owner. Normal builds use empty lifecycle
hooks. Native cleanup also restores saved scroll on callback exception or
forced Exit, before owner teardown can proceed.

Console service version 81 publishes `_DOC_UPDATE_TASK_DOCS` as its 221st symbol;
memory service remains version 24. Public CTask and service-table layouts are
unchanged. The declaration is within the public document header's include guard.

## Contracts

```
python3 tools/test-i386-task-document-update.py IMAGE --out OUT
python3 tools/test-i386-refresh-worker-recovery.py IMAGE --out OUT
```

The task-update session covers six independent renderer/owner Exit and kill
cases through the original update function. A border tag then calls Exit while
scroll is cleared. Observations require worker Fs/document-lock identity,
restored x/y/z scroll, unlocked retained document, exact parent heap and reusable
graphics/text presentation. A separate normal-return border case checks the
new tag and the same restoration/resource invariants. Both return mask 63.

The preceding image's internal function is callable for a meaningful baseline:
`--legacy-module` reads its `DocUpdateTaskDocs` and `DocNew` code offsets and binds
through the live DocNew address. It does not guess a loaded address. The image,
module, fixture and runner are pinned. Its border Exit case returns 61 instead
of 63 (`build/i386-c4-task-update-red/result.json`), missing scroll restoration;
the later normal-return case is unexecuted on that image.

The persistent-worker session installs the existing one-shot task-end callback
which throws `WinAbort` to its outer frame loop. Deleting a document cancels its
yielding render, unwinds all nested scopes and returns without killing the
worker. The same task then renders a replacement tag successfully. Finally it
stops with its callback cleared, and its parent recovers the exact original heap
and presentation helpers. This tests an explicit request loop; it does not
replace original window-manager semantics or enable refresh at boot.

## Remaining integration

A scheduled window update still needs original border/text clearing, task drawing,
controls and cursor/view arbitration around this document path. Protect the
whole task update, not just this inner document helper. The task ring must be
rescanned after yields, and worker recovery must not reuse retired targets.
Normal stdout/input integration and the automatic A/B refresh gate remain open,
as do the C1–C5 full compatibility milestones.

## Current-image evidence (2026-10-15)

The final source passes original-system self-rebuild, native cross-build and the
386 boot instruction audit. Current image reports:

- `build/i386-c4-task-update-final-green/result.json`: 38 commands; all six owner
  cases plus border Exit and normal-return cases return 63.
- `build/i386-c4-task-update-final-recovery/result.json`: 31 commands; persistent
  worker cancellation, replacement, shutdown and exact heap return 63.
- `build/i386-c4-task-update-final-replace/result.json`: all 44 prior replacement
  and retirement commands remain green.
- `build/i386-c4-task-update-final-frames/result.json`: all 16 graphics/text-frame
  commands and pixel checkpoints pass.
- `build/i386-c4-task-update-final-startup/result.json`: 8 MiB interactive startup
  passes in 47.15 seconds with no build-provider loads.

The rebuilt original automatic-refresh control passes with `[1,65,1,66]` and
both glyph pixel checks in
`build/i386-c4-task-update-original-refresh/result.json`. Its source hashes match
the current files. The native automatic-refresh gate remains unimplemented;
these explicit presentation sessions do not satisfy it.

The subsequent [whole-window component](i386-window-update.md) shares the original
border/document/task/control ordering and adds native scope cleanup around task
and control callbacks. The document helper above remains its inner stage;
normal-boot scheduling and full desktop qualification are still open.
