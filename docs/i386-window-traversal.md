# Window-ring presentation by task identity

`NativeWindowPresent` presents the visible, uncovered members of the public
window ring through the shared whole-window update. It uses the existing frame
lease and text-before-current-drawing composition. It is an explicit component;
it does not start a window-manager task or qualify automatic desktop refresh.

## Membership and lifetime

At the beginning of its drawing callback, the presenter copies task numbers in
window order into a temporary array. Counting, allocation and copying do not
yield in the native single-CPU runtime. Before each update it scans the live ring
again for that number, rechecks retirement/show/coverage, then immediately enters
the protected task-update path. No task pointer from a callback is dereferenced
after that callback returns. Deleted identities are skipped. New identities become eligible on
the following frame. Existing identities are evaluated at most once in the
captured order; the following frame uses the new order.

The array has a common native render scope. Normal return, callback exception
and forced Exit release it alongside nested task/control/document aliases and
the frame lease. Owner retirement continues to cancel active render borrowers;
future targets are numbers rather than owner references that could block their
retirement while another callback waits for them.

## One ordering anchor

The console task is recorded as graphics_owner and supplies the presentation
window; the buffers were reserved during kernel initialization. The kernel's
memory root currently serves as the sys_winmgr_task proxy. Those are distinct
tasks.
Previously native visibility started at graphics_owner while WinToTop used
sys_winmgr_task. That rotation could force the console behind other windows even
when it was raised above them. Visibility and numeric traversal now start at
sys_winmgr_task, consistently with public window order. Buffer ownership and the graphics association are
unchanged. Actual managed window-manager rebinding remains an integration gate.

The isolated visibility regression must therefore pass sys_winmgr_task to its
checker. Its six full-cell/bitmap, clipping, canary and IRQ checks are unchanged;
only the isolated ring's anchor argument changes from Fs to the actual updater
anchor. The old setup disconnected a different ring while the updater traversed
the real one.

Console service version 83 exports `_WINDOW_PRESENT` (225 symbols). Memory
remains version 24; public CTask and service-table layouts are unchanged.

## Executable contract and failing controls

```
python3 tools/test-i386-window-list.py IMAGE --out OUT
python3 tools/test-i386-window-list.py BASE_IMAGE --naive-control --out OUT
```

The fixture covers reorder-during-draw, a parent covering its child windows,
deleting a future target and creating a replacement identity, caught callback
failure, managed presenter Exit, retry, exact parent heap and presentation reuse.
The cover case temporarily sets CHILDREN_NOT_ON_TOP while raising the parent,
then restores it, preserving the original default child-raising policy.

Two controls distinguish membership and visibility mistakes. A guest-supplied
naive next-pointer walk skips B when A raises itself and returns 61 instead of
63. The early numeric prototype, still using the graphics-owner visibility
anchor, passes reordering but returns 61 when the raised console should cover
both test windows. Neither control is claimed to be the committed OS's scheduled
renderer; the former is a deliberate mutation and the latter an intermediate
prototype image.

The pixel phase paints the left half red and the right half blue through real
task drawing aliases. A yielding callback deletes the right-hand task. The next
observation requires red/white halves with no call into that retired target.
Both observations compare all 307,200 pixels against independent font/palette
construction in the input harness. Cleanup restores the raw console.

## Remaining integration

This does not implement the complete original GrUpdateTasks contract. Protected
per-frame derived-control updates, ODE/event work, original per-window error
isolation/reporting, scheduled cadence, cursor/view policy, normal stdout/input
and sys_winmgr_task rebinding still need integration. Repeated live lookup has a
quadratic task-count cost to measure in release profiling. Overlapping-window
mutation, automatic A/B refresh and full desktop/application qualification remain
open. C1–C5 are incomplete.

## Current evidence (2026-10-15)

The current fixture has 36 commands. The deliberate naive control fails its first
reorder case with mask 61 in
`build/i386-c4-window-ring-naive-red/result.json`. The early numeric prototype
passes that case and fails the cover case with mask 61 in
`build/i386-c4-window-ring-anchor-red/result.json`. Their inputs remain pinned;
later cases are not executed on those failing controls.

Original self-rebuild, native cross-build and the 386 boot instruction audit pass.
The final 8 MiB startup check passes in 46.62 seconds without build-provider loads
(`build/i386-c4-window-ring-final-startup/result.json`). The corrected isolated
ring check and all 23 windows/graphics/text-frame commands pass with their pixel
checks (`build/i386-c4-window-ring-final-frames/result.json`).

Early fixture attempts used an unresolved interactive forward declaration and a
ternary expression; they stopped before runtime cases. A later order expectation
was corrected to use the following frame's changed order. Those attempts are not
used as OS failure evidence. The two explicit controls above demonstrate the
actual membership/visibility failures.

All 36 current-image commands pass in
`build/i386-c4-window-ring-final-green/result.json`, including all six mask-63
cases and both independent full-frame observations. The 48-command whole-window
and 31-command persistent-worker recovery regressions also pass in
`build/i386-c4-window-ring-final-windows/result.json` and
`build/i386-c4-window-ring-final-recovery/result.json`. All 1,469 recorded
source/build-input hashes match; source image and recorded test input hashes
were checked before committing.
