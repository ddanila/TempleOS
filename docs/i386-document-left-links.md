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

Interactive link navigation, callback failures and the original terminal
right-click path remain unqualified. C1–C5 remain open.
