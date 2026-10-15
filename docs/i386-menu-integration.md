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

## DocEd state oracle before form integration (2026-10-15)

`tests/guest/i386-doced-state-reference/DocEdState.HC` now calls the actual
DocEd with real queued MSG_KEY_DOWN events. It does not replace View, DocGetKey
or keyboard dispatch. Both pinned-original and shared-original controls pass
six masks of 255, with unchanged inputs, in
`build/i386-c1-doced-state-reference/result.json` and
`build/i386-c4-doced-state-reference/result.json`.

Each mask checks exit result, restored put/display/border roles, text attribute,
title/source, incoming lock state, geometry, document owner/parent and unchanged
SHOW state under DONT_SHOW. Modes cover Esc, Shift-Esc, WIN_MAX, WIN_MAX with
SIZE_MIN, a DONT_HOME/DONT_TEXT_ATTR combination, and an initially locked doc.
WIN_MAX alone retains maximized bounds; SIZE_MIN restores original bounds.
The fixture then explicitly restores geometry for the next case.

The preserve-option combination currently checks post-return restoration only;
it does not yet observe cursor or text attribute while View is active. All
cases skip window-manager synchronization and SHOW changes, so normal visible
presentation and Refresh cadence remain unqualified by this oracle. Bound-data
editing/scanning, checkboxes, lists, mouse, action callbacks and exceptional or
forced-exit lifetimes still need separate contracts before full forms qualify.

`tools/test-i386-doced-state.py` first requires a flagged DocEd call to accept
queued Esc and return true, then transfers the identical fixture and checks
persisted source bytes after success. The native implementation currently
returns false for any nonzero flags and reads private NativeReadKey for its
retained loop. Removing the flags rejection alone cannot supply the original
message-driven View/form path; complete original input/action integration and
scoped border/title/document ownership are required.

### Complete original editor core extracted

`Adam/DolDoc/DocEdCore.HC` now contains the complete original View and DocEd
bodies. Adam/DolDoc/DocEd.HC includes it after the existing border callbacks.
The extraction preserves the function bodies byte for byte, including bound
DATA/CHECK_BOX scanning, border tags and callbacks, option handling, actual
View/DocGetKey input, and ordinary restoration. Original help-index assignments
are retained in the core. Native DocEd does not yet bind this core.

The first extraction passes a two-generation original bootstrap, the six-mask
state oracle and the real chooser oracle [11,12,22,-1,17,1]. After preserving original help-index metadata, the final two-generation
bootstrap also passes. Both final controls pass with unchanged inputs in
`build/i386-c4-doced-core-final-state/result.json` (six masks of 255) and
`build/i386-c4-doced-core-final-chooser/result.json` ([11,12,22,-1,17,1]).
This refactor does not add exception/forced-exit cleanup to the original body:
border/title allocations and old document roles must enter native cleanup scopes
before full form lifetimes qualify. Complete original DocPutKey/DocChar/action
semantics remain required; the retained native basic editor is not an equivalent.

The native flagged-call gate now rejects an exact VGA answer of zero using the
existing harness rejected_answers option. `build/i386-c2-doced-flags-fast-red`
fails explicitly on that answer, with unchanged inputs, before fixture transfer.
The previous timeout run also showed zero on its final framebuffer; the new
failure avoids waiting out the full command timeout for this known mismatch.

## Recovered DocEd recalculation failure cleanup (2026-10-15)

The shared core now records temporary border/title allocations, saved task
roles/attributes/title source, incoming document-lock ownership and original
geometry in CDocEdState. DocEdStateRestore is used on ordinary return and
propagating exceptions; temporary allocation pointers are cleared as they are
released. The complete original border construction, callbacks, View input and
bound-data scan remain in the core. This intentionally repairs the original
missing exception cleanup; native DocEd still does not bind this core.

The real TX+TC tag callback in
`tests/guest/i386-doced-failure-reference/DocEdFailure.HC` throws DEFail during
DocEd's DocRecalc. The test catches the original exception and checks put/
display/border roles, text attribute/title source/title text, incoming lock
state and exact caller heap. Both initially unlocked and locked cases must
return mask 31. The pre-fix shared-original control returns [3,15] in
`build/i386-c4-doced-failure-quoted-before/result.json`; the repaired control
passes [31,31] in `build/i386-c4-doced-failure-cleanup/result.json`, both with
unchanged inputs. An earlier unquoted fixture did not compile and is excluded.
The pinned-original quoted run times out and does not supply a returned mask.

Two original rebuild generations pass. Ordinary state cases remain six masks
of 255 in `build/i386-c4-doced-cleanup-state/result.json`; the real chooser stays
[11,12,22,-1,17,1] in `build/i386-c4-doced-cleanup-chooser/result.json`, with
unchanged inputs. `tools/test-i386-doced-failure.py` is ready to transfer the
same source to the native guest once its flagged-call prerequisite is supplied;
no native failure-cleanup pass is claimed.

This covers a recovered callback during initial recalculation while the caller
and document remain alive. Native integration still requires stack cleanup
registration and leases for the edited document, old roles and temporary border
through forced Exit and owner retirement; late View/action/scan failures and
constructor-allocation failures need their own gates. Do not treat CDocEdState's
ordinary exception handler as the complete native lifetime solution.

## Complete original core compiles natively (Console 94)

The shared core has function-name bindings DOC_ED_FUNCTION and DOC_VIEW_FUNCTION,
which default to original DocEd/View. The native console now compiles the same
complete source as NativeOriginalDocEd/NativeOriginalView after its real input,
window, border, data and refresh providers. The module audit requires both
functions. These are internal compiled functions: no new public header binding
or console export-table entry is added, and public DocEd still uses the retained
native editor and rejects flags. There is no native form acceptance claim.

`build/i386-c2-doced-core-cross` cross-builds and passes the limited 386 audit
(96 BIOS/255 protected instructions). All 1478 source/build hashes match.
Two original bootstrap generations pass, and the shared-original callback
failure check remains [31,31] with unchanged inputs in
`build/i386-c4-doced-named-core-failure/result.json`. Console is version 94;
its public table remains 231 entries and its private service table stays 48
bytes; public layouts and Memory 25 are unchanged.

The next binding requirement is lifetime integration, not a reduced form loop.
NativeRenderDrainExiting/NativeRenderCleanup release callbacks must not yield.
DocEdStateRestore can lock a document, retire its temporary border and invoke
window/control callbacks while restoring SIZE_MIN geometry, so it cannot be
registered directly as a forced-exit release callback. Separate ordinary/
recovered restoration from committed teardown. Track incoming versus currently
held document locks; borrow the edited and saved role documents; restore/detach
task roles while resources are alive; ensure manager borrowers drain before
owner heaps disappear. Cover callback Exit and owner retirement with actual
cross-task tests before qualifying this path. Only then route real forms and
flags to the complete core and continue full original key/action integration.

Normal 8 MiB startup passes all nine checks in 50.18 seconds in
`build/i386-c2-doced-core-startup/result.json`, with the manager active and
build providers unloaded. This checks the retained normal image, not execution
of the internal original DocEd candidate.

## Native DocEd lifetime candidate (Console 95)

Flagged calls and DOCF_FORM documents now enter the complete shared core;
ordinary non-form editing retains its existing editor. DocEdStateCore.HC holds
the common restored state. Native DocEdScope.HC registers a main cleanup frame
and leases for the edited and saved put/display/border documents before any
maximization, locking or allocation. Ordinary/recovered cleanup retains these
leases through restoration, then closes them in reverse order, including when
restoration itself throws. An incoming locked document is reacquired through
DocLock rather than merely checking whether some task holds the lock bit.

Committed release uses DocUnlockCore with the non-polling break-unlock adapter
and releases only the exiting task's actual ownership. It restores/detaches task
roles and title state and restores the edited document's prior valid window
owner (falling back to its memory owner). The temporary border belongs to the
exiting task's heap: it is detached, without DocDel or user callbacks during
stack drain. Existing owner retirement drains render borrowers before that heap
is reclaimed. This is a separate teardown path from ordinary SIZE_MIN window
restoration, which may call controls and yield.

The cross-task fixture `tests/guest/i386-doced-exit-reference/DocEdExit.HC`
allocates its document in the parent, then calls real DocEd in a spawned child.
A real tag callback calls Exit. Mask 63 requires callback entry, no worker
return, unlocked parent-owned document, unchanged parent roles, continued
DocPrint/DocSize use, and restored parent window ownership. The shared-original
control fails with mask 27 in `build/i386-c4-doced-exit-state-before/result.json`,
with unchanged inputs. Its stale lock/window owner are recorded before explicit
test-only repair permits the control to finish. Earlier diagnostic fixtures
used normal DocUnlock on a dead task's lock or assumed plain DocPrint returned
an entry; those observations are not this final oracle's acceptance evidence.

Console 95 cross-builds and passes the limited 386 audit; all 1480 source/build
hashes match. Original bootstrap and shared-original state/failure contracts
pass. Native state, recovered-failure and callback-Exit suites pass in
`build/i386-c2-doced-scopes-{state,failure,exit}` (39/27/27 commands), with
unchanged inputs and exact persisted fixture bytes. Normal 8 MiB startup passes
nine checks in 49.10 seconds in `build/i386-c2-doced-scopes-startup`.
No full form-action or owner-retirement acceptance is claimed yet. Complete
DocPutKey/DocChar/DocEntryRun semantics, visible/synchronized sessions, late
failures and constructor failure still need integration and tests.

## Final Console 95 qualification and WinMgr define dependency

The zero-flag DOCF_FORM path uses ordinary SHOW and Refresh synchronization.
Its first run exposes UndefDef from the actual border callback's ST_DOC_CMDS
lookup in WinMgr. `build/i386-c2-doced-form-defines-red/result.json` rejects the
background WINMGR window exception explicitly, with unchanged inputs. This
failure was absent from the earlier DONT_SHOW/DONT_WINMGR_SYNC state checks.

DocInitCore.HC now shares its complete standard-list loading in
DocStdDefinesInit; DocInit still calls it before creating the global dictionary.
Each independent WinMgr worker initializes these lists plus ST_COLORS in its
own hash table. It does not call DocInit or replace doldoc.hash. This keeps
standard border callbacks usable independently of the console task's private
hash table and allows normal worker ownership/reclamation on restart.

The final candidate is `build/i386-c2-doced-worker-defines-cross/kernel.img`:
all 1480 source/build pins match and its limited 386 audit passes. Final native
runs, all with unchanged inputs, are:

- `build/i386-c2-doced-final-state`: 39 commands, six state masks 255 and exact
  persisted shared fixture.
- `build/i386-c2-doced-final-failure`: 27 commands, both recovered callback masks
  31, exact caller heap and persisted fixture.
- `build/i386-c2-doced-final-exit`: 27 commands, mask 63 for actual callback Exit,
  parent-owned lock/window recovery and continued use, exact persisted fixture.
- `build/i386-c2-doced-form-defines-green`: eight commands, zero-flag form Esc
  with real Refresh, all four standard lists visible through WinMgr's hash,
  no background window exception, then continued arithmetic.
- `build/i386-c2-doced-final-startup`: nine normal 8 MiB checks in 49.55 seconds,
  manager enabled and build providers unloaded.

The final original two-generation bootstrap passes; state and real chooser
controls remain six masks of 255 and [11,12,22,-1,17,1] in
`build/i386-c4-doced-defines-{state,chooser}` with unchanged inputs. Native form
runs use the explicit 64 MiB profile; minimal startup remains at 8 MiB.

This does not qualify full field editing, DocEntryRun/DocMenu actions, public
View, ordinary non-form original editor parity, independent owner retirement,
recovered cancellation, late scan/input/constructor failures or interruption of
restoration itself. In particular closing scopes when restoration throws does
not by itself prove all temporary allocations have finished cleanup. Add exact
resource gates for those paths and for committed-exit border borrowers; do not
infer complete teardown heap recovery from TaskValidate becoming false.

## Independent edited-document owner retirement qualifies

The native edited-document lease now has actual sibling-owner retirement gates
at initial tag-callback and View-waiting points. The shared-original controls
return mask 11, while the unchanged Console 95 image passes masks 31 and 15.
The View case hides both windows and waits for role binding after initial
recalculation, so its safety does not depend on that callback's inner lease.
An end hook in the callback case records the owner's live heap/document at
editor retirement. See [contracts, fixture staging and remaining lifetime
matrix](i386-doced-owner-retirement.md). This does not qualify saved-role
retirement, recovered cancellation, explicit DocDel or complete teardown heap
recovery, and does not close any C1–C5 milestone.

## Saved-role teardown and parent restoration (Console 96)

The saved put/display/border owner matrix exposed a surviving document with a
parent_doc link to a retired saved display. Console 96 preserves and leases the
original parent, restores that live parent on committed teardown, or clears it
when its owner/document is retiring. It preserves a different callback-selected
parent and ordinary DocEd parent behavior. Six cases, including original-parent
retirement, live-parent preservation and a callback-selected live parent, now pass; old native and shared-original
controls fail. See [masks, final-image regressions and remaining gates](i386-doced-owner-retirement.md).
This does not close any C1–C5 milestone or the recovered-cancellation/restoration
failure gates.

## Explicit deletion and foreign-owner storage (Console 98)

DocDel's active-editor tests exposed window-owner and allocation-owner wait
cycles. Deletion no longer keeps the window task as a dependency. Foreign owner
storage is retained through the existing task lifetime reference while logical
owner retirement completes, then the full destructor frees entries/document and
drops that reference. Caller-owned and editor-owned target suites pass, including
cross-heap REMALLOC_DATA release and successful task reaping. The prior renderer
retirement/self-delete suite also passes. See [deletion evidence and remaining
caller-cancellation/descendant gates](i386-doced-deletion.md). These gates do not
close C1–C5 or full form/action compatibility.

## Complete action and chooser bodies compile (Console 100)

DocEntryRunCore, DocMenuCore and the complete original PopUpMenu/PopUpPickLst
bodies now compile into Console. The native adapter uses existing real message,
Exit, popup and window providers. Four public exports are added. Eight paired
original/native direct action cases check results, unlocked callbacks, messages,
lock policy, command reset and exact heap recovery. This advances the original
menu dependency graph without substituting a reduced chooser. See
[entry-action integration and boundaries](i386-entry-actions.md). Actual chooser
input remains a separate acceptance gate, as does full original DocPutKey.
