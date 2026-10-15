# Completing the original menu/GetStr path

The execution prerequisites now include real PopUp tasks and request ownership.
PopUpPrint adds formatted-source ownership for the original PopUpMenu wrapper.
These are services used by the chooser, not a replacement chooser implementation.
The C1–C5 goal and all required original applications remain unchanged.

## Dependency order and acceptance

1. **Formatted popup execution.** Share Kernel/Job.HC's PopUpPrint behavior,
   delegating the complete format to StrPrintJoin and the complete execution to
   PopUp. Scope the temporary source through recovered cancellation and committed
   Exit. Require original/native decimal, signed/wide, mixed and quoted inputs,
   exact caller heap, empty recovered job rings and continued execution.
2. **Original form/editor input path.** Review and share the original DocEd/View/
   DocGetKey path for form documents. The native retained editor currently lacks
   complete DOCF_FORM behavior and original dof_flags handling. Preserve bound
   field editing/scanning, checkbox/list actions, keyboard/mouse selection,
   cancellation, sizing, borders, document/task restoration and resource cleanup.
   An Enter-only button handler or separate reduced list picker is insufficient.
3. **Complete mutually dependent actions and menus.** Compile full DocEntryRunCore,
   DocMenuCore, PopUpMenu and PopUpPickLst bodies with explicit forward bindings.
   Keep left/right values and callbacks, unlocked callbacks, MSG_CMD, links,
   popup and input macros, define-list editing, aliases and CANCEL. Adapt actual
   message/exit/window providers where needed; do not stub unused branches.
   DocBottom is already supplied by the shared navigation core, and DocDataFmt/
   DocDataScan plus In/InStr are existing prerequisites.
4. **Actual popup task presentation.** Restore the full servant DocTermNew/startup
   path with real border/menu/scroll/right-click behavior and focus/window
   integration. The known default-servant startup deficit is not closed by a
   successful execution result. Qualify the chooser in its actual child task,
   including owner retirement, cancellation, constructor failure and repeated use.
5. **Original GetStr and TimeClock.** Bind the original document input algorithm
   and kernel default/prompt wrapper, preserving filtering, selected-entry replay,
   typed-dollar behavior, single/multiline and Shift-Esc/exit semantics. Pass the
   existing thirteen input cases, then expand navigation/lifetime and real input
   workflows. Load unchanged TimeClock and run its storage/reopen/report and
   interactive punch workflows; loading or arithmetic alone is not qualification.

The real original message-driven chooser oracle is already available in
`tests/guest/i386-menu-chooser-reference/MenuChooser.HC`; both runners pin the same
source. It checks left/right/second selection, cancellation, unlocked callback,
MSG_CMD and specific restored fields. Native DocMenu is still missing. Add mouse,
bound-data editing, no-action restart and independent rendering checks as those
paths are integrated; do not interpret the six-value oracle as complete UI parity.

Normal startup remains separate from diagnostics. Preserve the measured 8 MiB
startup and 16 MiB rebuild profile's required regressions while using explicit
64/128 MiB desktop/rebuild budgets. The known 8 MiB spawned-worker capacity gap
remains open. C5 still requires two full native generations with the complete
compatibility suite and application inventory; original x64 rebuilds and focused
popup tests do not satisfy it.

## WinMax prerequisite contract (2026-10-15)

Original DocEd calls WinMax for DOF_WIN_MAX. PublicWindow.HH currently has no
WinMax binding, so restoring this original window service precedes full form
integration. `tools/test-i386-winmax-reference.py` captures the original geometry
using the same `tests/guest/i386-winmax-reference/WinMax.HC` source that
`tools/test-i386-winmax.py` transfers to the native filesystem and checks byte
for byte after a successful run.

The pinned original passes [1,1] in
`build/i386-c1-winmax-shared-reference/result.json`, with unchanged inputs:
with a border, left/right/top/bottom are 1/78/2/58; without a border they are
0/79/1/59. Each case explicitly restores prior bounds and the no-border flag.
The native gate checks the public binding before transferring or executing the
geometry fixture. The finalized native run rejects WinMax as an undefined
identifier in `build/i386-c2-winmax-shared-red/result.json`, with unchanged
inputs. A prerequisite rejection is not a geometry pass.

These are current-task geometry checks only. Before declaring WinMax qualified,
add explicit-target task selection, invalid-task handling, interrupt-state
preservation, derived-control callbacks and exceptional cleanup. Original
WinMax uses PUSHFD/CLI/POPFD without exception cleanup; any repair must have an
explicit failing recovery contract. DocEd flag/lock/title/document restoration,
real form input and full chooser integration remain separate open requirements.
