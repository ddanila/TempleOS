# Document left-link callback

New native documents now install the original `EdLeftClickLink` callback, as
original `DocNew` does. The callback body is shared with `DocTerm.HC`: it
resolves the entry link, releases the document lock before opening the editor
or popup editor, and frees the allocated link afterward.

The pinned original and shared-source original pass a five-group contract
(mask 31): callback installation, lock retention for an entry without a link,
and controlled regular-editor, popup-editor and no-link callback branches
(`build/i386-doc-left-link-original-v2`,
`build/i386-doc-left-link-shared-original-v1`; runner
`tools/test-i386-doc-left-link.py`). The editor and popup calls in the branch
checks are test doubles; this is not an interactive navigation test. The
initial original fixture used unsupported `#undef` directives and timed out
before running the contract (`build/i386-doc-left-link-original-v1`); the
fixture was reordered to avoid those directives.

Both original bootstrap generations and the native cross-build/386 audit pass
(`build/doc-left-link-rebuild-v1.log`, `build/i386-doc-left-link-cross-v1`).
The native public document test passes the same contract with unchanged inputs
(`build/i386-doc-left-link-native-v1`); the compiler reports an argument
mismatch warning for the test-only `LLCallback` declaration. The 8 MiB
ordinary-include and drive-fields smoke check also passes
(`build/i386-doc-left-link-smoke-8m`).

A subsequent session exercises the real default callback through `DocEntryRun`:
it creates a file, queues a character and Escape, opens the linked file in the
real editor, verifies the saved character, and checks document roles and lock
restoration. The pinned and shared originals pass all five checks
(`build/i386-doc-link-session-original-v2`,
`build/i386-doc-link-session-shared-v1`; runner
`tools/test-i386-doc-link-session.py`). The first original attempt tried to
write to the boot medium `T:` and timed out; tracing located the write and the
fixture now uses original writable RAM drive `B:`. The native fixture uses its
writable `C:` disk and passes the same five checks with unchanged inputs
(`build/i386-doc-link-session-native-v2`).

This is a programmatic activation with queued input, not physical mouse input or
popup navigation. Callback failures and the original terminal right-click path
remain unqualified. C1–C5 remain open.
