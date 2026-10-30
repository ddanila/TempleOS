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
pointer (`build/i386-popup-ed-reference-v2`). The first reference attempt
incorrectly expected a false return on cancellation and is retained at
`build/i386-popup-ed-reference-v1`. Both original rebuild generations and the
cross-build/386 audit pass (`build/rebuild-test`, `build/i386-popup-ed-cross`).
The native comparison is in progress at `build/i386-popup-ed-native-v1`; it
has opened the editor but has not consumed the fixture's posted input. The
unchanged Budget loader advances past `PopUpEd` and rejects at `SettingsPush`
(`BgtMain.HC` line 182, `build/i386-budget-native-load-v5`).
Neither run qualifies the full editor, Budget workflow, or C1–C5 milestones.
