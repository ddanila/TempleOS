# Shared window border service

ConsoleRuntime 134 exposes the complete original WinBorder body through
`_WIN_BORDER`, appended at export index 328. Adam/Win.HC and the native window
runtime include the same Kernel/WinBorderCore.HC. The extraction preserves the
original bytes: task validation, old-border return value, conditional coordinate
changes, derived-value update, and interrupt save/restore. No reduced key handler
is introduced; this is one dependency of the still-incomplete original DocPutKey.

The pinned-original contract passes mask 31 in
`build/i386-c2-win-border-reference`, with all execution inputs unchanged. It
covers both initial border states, both interrupt-enable states, repeated
idempotent calls, explicit/current task selection, exact coordinate restoration,
and invalid-task rejection without mutation. It does not qualify callback
exceptions or selecting a different live task. The original implementation's
interrupt handling is preserved, including its existing exception limitations.

The preceding ConsoleRuntime 133 image rejects the contract at WinBorder with
`Invalid lval`; the runner eventually times out, with unchanged execution inputs,
in `build/i386-c2-win-border-native-red`. Both initial bootstrap generations passed. The first cross-build in
`build/i386-c2-win-border-cross` failed at export registration because WinBorder
needed a forward declaration before the later window-runtime include. Its
compiler log and failure record are preserved. The matching declaration is now
present. The second cross-build in `build/i386-c2-win-border-fixed-cross`
then rejected NULL in that early declaration, before its macro definition. Using
literal zero, as adjacent forward declarations do, fixes that ordering issue.
Both failure logs are retained. The final bootstrap passes both generations, and
`build/i386-c2-win-border-zero-cross` passes cross-compilation and the 386 boot
audit with all 1531 source and 24 build-input hashes unchanged. The native contract passes all three commands and mask 31 in
`build/i386-c2-win-border-native`, with all execution inputs unchanged and exact
VGA checkpoints. This functional run uses 64 MiB with the window manager paused;
it does not replace the isolated 8 MiB startup or 16 MiB diagnostic gates. The isolated 8 MiB gate in `build/i386-c2-win-border-startup` passes all nine
behavior/VGA checks with four unchanged pins and no build-provider loads, but
61.670895-second startup exceeds the 60-second target. The coordinator stopped
there, so its dependent 16 MiB diagnostics did not launch. This timing failure
remains open. Full document key
dispatch, terminal startup and all C1–C5 qualification remain open.

```sh
python3 tools/test-i386-win-border.py --out ORIGINAL
python3 tools/test-i386-win-border.py IMAGE --out NATIVE
```

The remaining DocPutKey integration graph includes AutoComplete/
ACFillIn/ACDFillin/ACDDef/ACMan, directory contexts and file selection, editor
code/widget/macro/sprite tools, FindWiz, and God application services. EdFindReplace
and EdGoToLine now have full provider dispatch from ConsoleRuntime; see
`docs/i386-editor-dialogs.md`. This callable-name audit is not a complete dependency proof:
shared globals, types and constants must also be checked when compiling the full
original body. PostMsgWait now shares its complete original body using the existing
MemoryRuntime PostMsg provider and NativeTaskWait; see
`docs/i386-post-msg-wait.md` for the reference and native validation.
