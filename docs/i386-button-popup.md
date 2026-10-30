# Button popup services

The original one-button and two-button dialog builders and the `PopUpOk`,
`PopUpNoYes`, and `PopUpCancelOk` wrappers now share their original bodies
through `Adam/DolDoc/DocButtonPopupCore.HC` and are exported by ConsoleRuntime
140. These builders create DolDoc button menus and use the existing popup and
menu services; they do not bypass input or return a canned answer.

The original-system contract checks seven accepted or cancelled choices,
caller document/task restoration, and seven serialized dialog documents
(`build/i386-button-popup-reference-v5`). The first two reference attempts
failed in fixture compilation because the original compiler rejected ternary
expressions; their screenshots are retained. Both original bootstrap generations
and the cross-build/386 audit pass (`build/rebuild-test` and
`build/i386-button-popup-cross-v2`). The initial native comparison matches the first four documents and passes
the first three cases, but fails the fourth, selecting the left button of a
two-button menu (`build/i386-button-popup-native-v1`). A diagnostic rerun
records return values and caller-state checks (`build/i386-button-popup-native-v2`). The unchanged Budget loader
now reaches `PopUpEd` at `BgtMain.HC` line 53 and is rejected there
(`build/i386-budget-native-load-v4`), before Install. No full application or
C1–C5 qualification is claimed.
