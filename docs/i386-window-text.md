# Native window geometry and text borders

The native console retains the original `TextBorder`, `TextRect`,
`WinScrollNull` and `WinScrollRestore` bodies. Original and native
`WinDerivedValsUpdate` use shared geometry arithmetic, with their respective
interrupt save/restore boundaries. The caller still owns `TASKf_TASK_LOCK`.
Normal graphics startup initializes the console task to 80 by 60 cells and
640 by 480 pixels.

The full original `CTextGlbls` record is shared through
`Kernel/TextGlobalsTypes.HH`. Native startup initializes the screen dimensions,
standard and Cyrillic font pointers, VGA aliases, and original graphics-mode
border characters. Native document text primitives use `gr.text_base`, and both
text and layered graphics presentation read `text.font`. The raw command console
continues to own its separate pixel buffer; publishing the record does not
provide the original raw-output services or populate `raw_scrn_image`.

`TextRect` now checks bounds again after clipping. A rectangle wholly left or
right of the screen could previously produce a negative width, which is unsafe
for the original assembly fill primitive. Both architectures use the corrected
routine.

`WindowTextCheck` exercises ten groups on original x64 and native i386:
negative-origin geometry; interrupt-state preservation; wide signed scroll
save/restore; partial, complete and reversed rectangle clipping; both original
border styles with nonzero viewport and scroll offsets; and guarded buffer
bounds. Tests temporarily install an isolated text surface and restore it before
returning. A native command separately verifies the actual console viewport.
These checks run only in the test harness, not during normal startup.

This is a dependency of original document layout, including DolDoc text-button
borders. It does not provide `TaskDerivedValsUpdate`, control callbacks,
window z-order, `WinHorz`/`WinVert`, or the complete original window manager.
Full document construction, formatting, layout, editing and persistence remain
required for the usable editing-session milestone.

Two original x64 rebuild/reboot generations passed. The shared checks passed
in the original cross-build guest and the native QEMU/486 suite at 8 MiB.
The native run covers 217 commands / 280 input lines,
including these ten groups, existing graphics/text frame comparisons, recovery
and all 17 module rejections. ConsoleRuntime 23 retains 253888 bytes.
