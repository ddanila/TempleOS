# Popup file editor dependency

The unchanged Budget loader calls `PopUpEd` after its account-information
popup. The original wrapper is shared through `Adam/DolDoc/DocPopUpEdCore.HC`
and exported by ConsoleRuntime 141, using the existing popup task and file
editor paths. The native `Ed` implementation remains a limited subset of the
original editor; exporting this wrapper does not complete editor compatibility.

The original-system reference opens an existing file in a popup, posts an edit
key, and separately accepts or cancels. Accepted bytes are `Z`, the DolDoc
cursor byte, and `alpha\n`; cancelled bytes remain `alpha\n`. Both calls
return true for the existing file and restore caller roles and the popup output
pointer (`build/i386-popup-ed-reference-v4`). The first reference attempt
incorrectly expected a false return on cancellation and is retained at
`build/i386-popup-ed-reference-v1`. Both original rebuild generations and the
cross-build/386 audit pass (`build/rebuild-test`, `build/i386-popup-ed-cross`).
The native comparison timed out after opening the editor
(`build/i386-popup-ed-native-v1`). The fixture waits for the popup task's
`TASKf_AWAITING_MSG` before posting input; the native legacy editor polls its
raw input reader and did not reach that state, so this run does not establish
whether it would consume posted messages. A revised fixture waits for the
target document instead; the original passes. The native run completed both
edits with identical accepted and cancelled file bytes, but failed the
cancelled call's return or state check (`build/i386-popup-ed-native-v2`). A
diagnostic rerun confirms the cancelled call returns 0 natively versus 1 on
the original; all recorded caller roles and output pointer match
(`build/i386-popup-ed-native-v3`). The
unchanged Budget loader advances past `PopUpEd` and rejects at `SettingsPush`
(`BgtMain.HC` line 182, `build/i386-budget-native-load-v5`).
Neither run qualifies the full editor, Budget workflow, or C1–C5 milestones.

The expanded original reference checks existing and new files with both
acceptance and cancellation (`build/i386-popup-ed-reference-v6`). For these
ordinary file cases the return value reflects whether the file existed on entry;
the accepted new file is still written, and cancelling a new file leaves it
absent. ConsoleRuntime 143 applies that return behavior to the native editor
subset. Both bootstrap generations and the cross-build/386 audit pass
(`build/rebuild-test`, `build/i386-editor-result-cross`). The four-case native
comparison passes with exact file and return/state captures and unchanged inputs
(`build/i386-popup-ed-native-v4`); this concurrent run does not qualify startup
timing. Full `Ed` link, flag,
error and editor behavior remain open.
