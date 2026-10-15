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

### Shared candidate and five-case controls

Kernel/WinMaxCore.HC is now included by both original Adam/Win.HC and the native
window-order runtime. Console 93 publishes _WIN_MAX as export 230 (231 total).
The original sizing and ordering calls are preserved. Saved interrupt state is
restored through try/catch, following WinSize.HC's existing cleanup pattern;
this does not promise geometry rollback when callbacks fail.

Both `build/i386-c1-winmax-five-final-reference/result.json` and
`build/i386-c4-winmax-shared-five-reference/result.json` pass [1,1,1,1,1], with
unchanged inputs. The additional cases check explicit Fs with IF on/off and
invalid-task bounds/IF preservation. Two original self-rebuild generations pass.
The native cross-build is running at `build/i386-c2-winmax-cross`; native paired
geometry, actual different-task targeting, callback recovery and startup remain
unqualified. Older reference paths above describe historical two-case fixtures.

### Native geometry/startup qualification and recovery contract

The Console 93 cross-build completes with a limited 386 audit of 96 BIOS and
255 protected-mode instructions; all 1477 source/build input hashes match.
`build/i386-c2-winmax-five-green/result.json` passes all 31 commands, with
unchanged inputs and exact persisted fixture bytes. This qualifies the paired
current-task geometry, IF on/off and invalid-task cases on 486,-fpu at 64 MiB.
`build/i386-c2-winmax-startup/result.json` passes nine normal-boot checks at
8 MiB in 50.85 seconds, with the manager enabled and build providers unloaded.
Neither run establishes C5 native-generation qualification.

The additional shared fixture in `tests/guest/i386-winmax-recovery-reference`
uses a real Spawn task to check target geometry, unchanged caller geometry,
focus and window order. A real derived-control callback then throws WMFail;
the caller must catch the original exception, observe IF enabled and an
unlocked task, remove/free the control, restore geometry and continue.
The outer try must be entered with IF enabled: an earlier diagnostic entered
with IF disabled and could not isolate WinMax cleanup. Its results are not
acceptance evidence. Another diagnostic modified fixture inputs during a run;
its inputs_unchanged=false likewise excludes it.

The rebuilt shared-original staged control passes [1,1] in
`build/i386-c4-winmax-recovery-staged/result.json`, with unchanged inputs.
Stage markers separate targeting from recovery in the original control;
a timeout without an exported result does not establish a returned IF value.
Forced Exit, owner retirement during callbacks, and complete form/editor
lifetimes remain separate open requirements.

The corrected native recovery session also passes, with unchanged inputs and
exact transferred fixture bytes, in
`build/i386-c2-winmax-recovery-entry-if/result.json` (31 commands). Thus the
actual different-task and recovered callback-throw paths qualify on this
cross-built image. This is not forced Exit/owner-retirement qualification.

The pinned-original staged run terminates at its 120-second limit, with unchanged
inputs, in `build/i386-c1-winmax-recovery-staged/result.json`. Its log reaches
TARGET end and RECOVERY begin, but never RECOVERY end or an export. The shared
body completes the same source; this is an intentional recovery repair rather
than evidence that the original returned a particular IF value.
