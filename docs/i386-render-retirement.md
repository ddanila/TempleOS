# Render borrowers and managed owner retirement

The native render-scope registry now associates document rendering with both
the document's memory owner and its window task. A borrower keeps its own Fs
and callback execution context. No per-owner renderer substitution is used.

## Exit barrier

Managed Exit runs the original one-shot end callback first. Once retirement is
committed, it publishes TASKf_KILL_TASK, retires linked children and invokes the
resident render-retirement hook before public job, heap and symbol teardown.
The hook first abandons the exiting task's own native render scopes without
invoking prior task cleanup. This releases cross-owned locks before waiting for
other borrowers. Native release functions suppress break delivery while doing
that non-yielding cleanup; normal scheduler finishing still runs prior cleanup.

The barrier cancels other managed tasks with active scopes naming this owner.
Their existing Exit/cleanup paths unwind document locks, aliases and frame
leases on their own stacks. The barrier rescans after yielding rather than
retaining pointers into another task's stack or assuming one kill request
completed retirement. The owner's document and callback code remain live until
that barrier returns.

Borrow admission rejects invalid or pending/committed-kill owners. It reads
public task validity/flags, not private scheduler fields through a document's
task pointer. DocRecalc registers before its four-millisecond lock wait and
refreshes the owner association after acquiring the document lock.

Memory service version 24 publishes a kernel-lifetime retirement-hook slot;
console version 80 binds its resident handler after successful initialization.
The service-table and public CTask layouts remain unchanged. The memory symbol
table has 49 entries; the console still has 220. Boot validates the new versions
and callback-slot export.

## Document deletion

Native DocDel publishes a scoped deleting-resource guard before canceling
render users. New render borrowers are rejected while the guard is live.
Deletion then acquires the ordinary document lock and frees its contents.
The guard participates in the same cleanup stack, including cancellation while
waiting for a lock. Document lock waits now use the managed yield provider, so
pending kills are observed there as well.

A callback attempting to delete its own actively rendered document receives
DocBusy before mutation. The renderer can unwind, retain the old tag/document,
and retry. This is a defensive rejection of unsafe recursive deletion. An
already active deletion guard also rejects a second deletion. Disposal cleanup
frees the document even if break delivery interrupts the final unlock.

## Executable contract

```
python3 tools/test-i386-render-owner-retire.py IMAGE --out build/FRESH-render-retirement
```

Six cases pair explicit Exit/external kill with a terminal owner, a bare managed
owner, and a root-allocated document whose window/callback owner is a terminal.
The renderer is a sibling under the root, not a child of that owner. Terminal
cases compile the callback in the owner's scope. The callback confirms worker
Fs/document-lock identity and yields indefinitely. The test allows 128
cooperative turns for automatic retirement; fallback cleanup on the old image
lets its failed mask be observed without leaving the test hung.

Separate cases delete a document while another task renders it, and reject
self-deletion before retrying its retained tag. Required observations include
actual callback entry, automatic cancellation without a returned frame or an
unexpected exception, task retirement, exact parent heap and both presentation
helpers still usable afterward. This fixture contains 35 commands.

## Boundaries before scheduled refresh

The immortal root cannot be killed; a retirement barrier waits for its explicit
render call to return. Scheduled refresh therefore uses a cancellable managed
task. Arbitrary private cleanup wrappers hiding native render scopes are not
qualified by this work.

Cyclic dependencies between an exiting parent, its descendants and render
resources are not qualified. Linked-child retirement still precedes the owner
barrier, preserving the existing lifetime of parent temporaries during child
cleanup.

Pointers must be valid when borrowing starts. Unscoped raw pointers, callback
code owned by an unrelated third task, and arbitrary unregistered document
clients are not protected automatically. A future window update must register
its target owner before any yield or callback, and select documents inside that
protected context. It must also handle renderer cancellation/restart, document
replacement, original cursor/view policy and actual sys_winmgr_task rebinding.
No scheduled worker is enabled by this hook alone. The automatic A/B refresh
gate and C1–C5 remain open.

## Current evidence (2026-10-15)

The previous image fails the first owner case with mask 61 instead of 63 in
`build/i386-c4-render-owner-retire-red/result.json`; later old-image cases were
not executed. All 35 current-image commands pass in
`build/i386-c4-render-owner-retire-green/result.json`: the six owner cases and
concurrent deletion return 63; rejected self-deletion and retry return 7.
Bootstrap self-rebuild, cross-build and the 386 boot instruction audit pass.
The 8 MiB startup gate passes in 46.49 seconds with zero build-provider loads
(`build/i386-c4-render-retire-startup/result.json`).

Current-image regressions also pass: five public task-end cases, five descendant
cases (28 commands), 24 graphics Exit commands, 20 document Exit commands,
10 callback-fault commands, 33 document commands, 16 graphics/text-frame
commands, 23 mouse commands and 17 linked-owner commands. Reports are under
`build/i386-c4-render-retire-{end-regression,descendants,graphics-exit,doc-exit,callback,documents,frames,mouse,linked}/result.json`.
All 1,463 recorded source/build-input hashes match the current files; the source
image hash and recorded test input hashes were checked before committing.

## Displayed-document replacement

`python3 tools/test-i386-render-document-replace.py IMAGE --out OUT` passes all
44 commands in `build/i386-c4-render-document-replace-verified/result.json`.
A managed renderer yields inside the old root-owned document's tag while a
separate task installs a replacement display document and deletes the old one.
The test observes cancellation before deletion completes, no old-frame return
or unexpected exception, and the replacement still selected. A fresh renderer
then evaluates its tag to `alive` with worker Fs/document-lock identity intact.
After restoring the saved display pointer and deleting the replacement, exact
root heap and graphics/text helper reuse return mask 255. All earlier retirement
cases run in the same session. Image, runner, base fixture and replacement
fixture hashes are pinned and unchanged.

The initial fixture exceeded the terminal's 255-character input limit before
executing the replacement case. The corrected fixture splits helpers into valid
input lines. An intermediate attempt was explicitly interrupted to fix a
root-owner relationship assertion. Neither attempt is OS-failure evidence.
This covers explicit replacement with fresh-worker recovery; automatic worker
supervision and scheduled window updates remain open.

The [task-document update contract](i386-task-document-update.md) adds a target
scope before document selection and restores temporary border scroll on Exit.
It also exercises recovery of a persistent managed render task through the
existing one-shot end callback, rather than requiring a new task per frame.
Scheduled integration remains open.

## Console 98 deletion storage retention

DocDel no longer pins the window task it must drain. Foreign allocation owners
are held by the existing task-storage lifetime reference rather than a render
owner dependency; they may finish logically while their heaps remain live for
the full destructor. The reference is released after disposal. The original
retiring-resource/self-delete guards and cleanup stack remain in use. Actual
DocEd/renderer deletion and cross-heap-owned-data tests pass; see
[deletion contracts](i386-doced-deletion.md). Caller cancellation and cyclic
parent/descendant retirement are still separate unqualified gates.
