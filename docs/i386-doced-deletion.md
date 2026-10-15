# Deleting documents with active DocEd clients

These C4 cases call public DocDel while the original flagged DocEd path waits
in View. They cover normal deletion and retirement, not cancellation of the
deleter or the retained ordinary non-form editor.

## Two retirement cycles repaired

Console 96 deadlocks on deleting a caller-owned edited document. Its deletion
frame names the editor as window_owner while waiting for that editor to exit.
The editor's owner-retirement barrier waits back on the deleting frame. The
failed run is `build/i386-c2-doced-delete/result.json`, with unchanged inputs.
The destructor does not dereference the window task, so this dependency is
removed. Console 97 then passes the three caller-owned cases in
`build/i386-c2-docdel-window-green`, but the editor-owned case still deadlocks
in `build/i386-c2-owned-delete-red`.

The second cycle is the foreign allocation owner. A deletion frame that keeps
that task alive as a render dependency cannot simultaneously retire it as a
document user. Console 98 retains the foreign task's existing lifetime_refs
instead: logical task exit can finish, while task/heap storage remains allocated
until the destructor finishes. The reference is admitted and released under
IRQ exclusion. It is released after document disposal, including reached cleanup
paths. A same-task owner needs no extra storage reference. The retiring-resource
guard still rejects new borrowers, duplicate deletion and recursive self-delete.

This runs the full destructor while storage remains live. It does not replace
DocEntryDel with whole-task heap reclamation, which would miss owned entry data
allocated in another task's heap. Public layouts and services are unchanged;
Console is version 98 and Memory remains 25.

## Caller-owned target matrix

`tests/guest/i386-doced-delete-reference/DocEdDelete.HC` deletes three targets:

| Case | Target |
| --- | --- |
| 0 | The edited document |
| 1 | The saved display document; the edited document survives |
| 2 | The original parent document; the edited document survives |

Mask 63 requires active View binding (1), editor retirement without normal return
(2), parent-task role preservation (4), exact caller-heap recovery of DocSize(target)
(8), valid/unlocked/window-restored/parent-cleared survivor where applicable (16),
and a target-live observation in the editor's end hook (32). Case 0 has no
surviving edited document, so bit 16 checks completed editor retirement there.
No deleted target is dereferenced afterward.

The shared-original control returns [13,13,13] instead of [63,63,63] in
`build/i386-c4-doced-delete-before/result.json`: it frees the allocations but
leaves the editor alive. The repaired native run passes all three cases in
seven commands, with unchanged inputs and exact fixture bytes, in
`build/i386-c2-docdel-retained-green/result.json`.

## Editor-owned target and cross-heap entry data

`tests/guest/i386-doced-owned-delete-reference/OwnedDelete.HC` creates the document
in the editor's own heap. An actual TX entry owns a parent-allocated buffer via
DOCEF_REMALLOC_DATA. The parent deletes the document while the editor waits in
View. An end hook records the live document and its actual editor-heap allocation.

Mask 127 checks active View (1), actual editor-heap ownership (2), retired editor
without normal return (4), parent roles (8), target-live end hook (16), exact
parent-buffer recovery through the full destructor (32), and restoration of the
parent's original child-list head after bounded yields (64). The last check
requires successful task reaping, rather than only an invalid task signature;
it catches a retained-owner reference left behind after deletion. It does not
measure every public pool's reserved/backing bytes.

The shared-original control returns [43] in
`build/i386-c4-owned-delete-reap-before/result.json`, with unchanged inputs.
The final native run passes in five commands in
`build/i386-c2-owned-delete-retained/result.json`, with unchanged inputs and
exact fixture bytes. Both runners stage the same source additively, then use
normal guest #include. The parent buffer must be freed by DocEntryDel, so simply
letting the editor's heap disappear cannot satisfy this contract.

## Final candidate and regression scope

The final image is `build/i386-c2-docdel-retained-cross/kernel.img`, using 64 MiB,
QEMU TCG and 486,-fpu for these tests. Run with fresh output directories:

```sh
python3 tools/test-i386-doced-delete.py build/i386-c2-docdel-retained-cross/kernel.img --out build/new-doc-delete
python3 tools/test-i386-doced-owned-delete.py build/i386-c2-docdel-retained-cross/kernel.img --out build/new-owned-delete
```

The first runner also accepts --case 0, 1 or 2. Both original runners accept
--current-system and require a passing source-matched original rebuild.

Cross-build and limited 386 boot audit pass; all 1480 source/build hashes match.
Two original bootstrap generations and the original state control pass. Native
saved-role, ordinary state, callback-failure and synchronized form regressions
pass in `build/i386-c2-docdel-retained-roles`, `build/i386-c2-docdel-state`,
`build/i386-c2-docdel-failure` and `build/i386-c2-docdel-form`. Normal 8 MiB startup
passes nine checks in 49.45 seconds in `build/i386-c2-docdel-retained-startup`.
The existing 35-command renderer retirement/self-deletion suite also passes in
`build/i386-c2-docdel-render-retirement`, with unchanged inputs.

## Remaining gates

Cancel/recover the deleting task while it holds a foreign-owner storage reference;
force caller Exit while a retained owner is also its child; verify reference
release before descendant-reaping waits; exercise cleanup interruption, admission
and allocation failure, late input/scan and remaining border-borrower interactions.
Cyclic parent/descendant retirement remains unqualified. Test precise backing
memory budgets separately from the allocation/reaping checks above. Complete
form/action/menu/editor/application parity and C1–C5 remain open.

## Recovered cancellation and committed descendant Exit

The paired `i386-docdel-cancel` runners require mask 255: a throwing task-end
callback recovers the blocked deleter, preserving its heap and document roles;
the document can then be deleted again. The owner must be physically reaped
while the recovered deleter remains alive, so caller exit cannot hide a leaked
reference. Original and Console 98 controls pass with unchanged inputs.

The paired `i386-docdel-caller-exit` runners require mask 127. Here the document
owner is the deleter's own child. Original behavior passes; Console 98 produces
mask 91 because the child storage reference prevents physical reaping while
its exiting parent waits for the child list to empty.

The Console 99 / Memory 26 implementation introduces selective exit preparation.
After committing Exit, Memory calls the existing owner-retirement hook before
and after the child barrier. When children remain, Console invokes only optional
non-yielding preparation callbacks under IRQ exclusion with break polling
suppressed. DocDel releases its foreign storage reference and detaches its
abandoned target and release flags, preventing a later dereference after child
heap destruction. It does not remove the registered cleanup scope. Other scope
resources remain live until descendants finish; the existing final drain and
independent-borrower retirement then run. This does not establish correctness
for arbitrary cyclic resource dependencies.

`tools/test-i386-parent-frame-retirement.py` separately checks the ordering
invariant through public task state. A parent is blocked inside a graphics draw
callback with its alias allocated. Its child's end callback compares the still
live parent's data-heap allocation count with the draw-time count. The test
requires that observation, both tasks retiring, no normal frame return, and a
subsequent successful presentation. It never dereferences the retired alias.

The selective implementation passes the committed Exit mask 127, recovered
cancellation mask 255, normal caller-owned and editor-owned deletion, 28-command
descendant and end-callback suites, the 35-command renderer retirement suite,
and parent-frame mask 7 with presentation reuse. Evidence directories use the
`build/i386-c2-selective-exit-` prefix. The rejected broad-drain image visibly
returns mask 6 in `build/i386-c2-broad-drain-parent-frame-red/qemu/startup-command-08.ppm`.
The two-generation original bootstrap and cross-build pass; all 1480 source/build
pins match. Normal 8 MiB startup passes nine checks in 50.92 seconds. These are
bounded contracts, not general qualification of parent/descendant resource cycles.
