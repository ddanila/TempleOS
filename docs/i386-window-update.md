# Shared whole-window rendering and cleanup

The native frame renderer can now invoke the original window drawing body in
`Adam/Gr/GrUpdateTaskWinCore.HC`. It retains the original order: border and text
clearing, wallpaper or displayed/border documents, task drawing, then controls
with saved/restored scroll. The original `GrUpdateTaskWin` wrapper retains its
per-window exception policy. The native entry point requires the caller's active
frame lease and propagates failures to its frame/worker recovery policy.

`DrawCtrls` now uses `Adam/Ctrls/DrawCtrlsCore.HC` on both architectures. It keeps
the original control order, show/border filtering and temporary border geometry.
The original PUSHFD/CLI/POPFD geometry sections use the existing portable
GetRFlags/SetRFlags operations and the same task-lock policy. Both normal return
and caught callback failures release the alias and restore expanded geometry.

Native task/control scopes additionally register the target owner before field
or callback access. Forced Exit drains nested control geometry/alias cleanup,
window scroll/alias cleanup and frame ownership in stack order. A window scope
also publishes and restores `sys_task_being_scrn_updated`, including nested
updates. Callback Fs remains the renderer's; task drawing/control aliases retain
the target window and memory ownership used by the original system.

The original window-inhibit flags are shared from
`Kernel/WindowInhibitFlags.HH`, with the original values retained. Console service
version 82 exports DrawCtrls, GrUpdateTaskWin and the current-update task slot
(224 symbols total). Memory remains version 24. Public CTask and service-table
layouts are unchanged.

## Reference cleanup defect and intentional correction

```
python3 tools/test-i386-control-draw-reference.py --out OUT
python3 tools/test-i386-control-draw-reference.py --current-system --out OUT
```

The pinned original returns `[31,25]` for normal and throwing border controls in
`build/i386-c1-control-draw-red-verified/result.json`. The throwing callback leaves
geometry expanded and its alias allocated. The fixture records these failures
before fallback cleanup restores the old system so the result can be exported.
The rebuilt original with the shared cleanup returns `[31,31]` in
`build/i386-c4-control-draw-green/result.json`. This is an intentional error-cleanup
correction on both architectures, not a claim that the pinned original passed.
A first host attempt looked for the wrong exported filename; only the verified
baseline above is used as the failing oracle.

The rebuilt original automatic A/B refresh control still returns `[1,65,1,66]`
and matches both glyph images in
`build/i386-c4-window-update-original-refresh/result.json`.

## Native executable contract

```
python3 tools/test-i386-window-update.py IMAGE --out OUT
```

The 48-command fixture uses an independent managed renderer. Eight owner cases
pair task drawing/border-control yielding with terminal/bare owner Exit or kill.
It requires actual callback entry, worker/window/update-context identity, no
returned canceled frame, task retirement, exact parent heap and graphics/text
reuse. Surviving-owner cases check document/task/control order 123, normal
completion, caught callback failure and forced callback Exit. Window bounds,
scroll, document locks and the current-update pointer must all recover.

## Boundaries before scheduled integration

The native component propagates callback errors; original desktop error
isolation/reporting must be integrated into the scheduled worker. No scheduled
worker, task-ring traversal or sys_winmgr_task rebinding is enabled here. The root
still serves as the background proxy. Mouse/cursor composition, full editor/view
arbitration, normal stdout/input and the native automatic A/B gate remain open.
Control-list mutation/deletion during a yielding callback and callbacks/code
owned by an unrelated third task are not qualified by owner retirement alone.
Ordering and cleanup checks do not establish whole-window pixel parity or
complete desktop compatibility. C1–C5 remain incomplete.

## Supporting current-image checks

Original-system self-rebuild, native cross-build and the 386 boot audit pass.
The 8 MiB interactive startup gate passes in 48.65 seconds without build-provider
loading (`build/i386-c4-window-update-startup/result.json`). All 38 task-document
commands, 31 persistent-worker recovery commands, 44 replacement/retirement
commands and 16 graphics/text-frame commands pass, including frame pixels.
Reports are under
`build/i386-c4-window-update-{documents,recovery,replace,frames}/result.json`.
The recorded 1,468 source/build-input hashes match the current files.

All 48 native commands pass in
`build/i386-c4-window-update-verified/result.json`: eight owner cases and the
normal/fault/Exit surviving-owner cases return mask 63; normal callback order is
123. Inputs remain pinned and unchanged. The first fixture session already
returned 63 in its first case, but its oracle omitted the `0` and `0` printed by
two top-level assignments. The verified session includes those outputs and
passes every full-console observation. This was a fixture correction, not an OS
failure or a relaxed rendering oracle.

The subsequent [window-ring component](i386-window-traversal.md) invokes this
body through a task-number snapshot and live lookup, with matching order and
visibility anchors. It adds deleted/new target, callback reorder, parent-cover
and two full-frame pixel observations. It is still an explicit frame component;
normal-boot scheduling remains open.
