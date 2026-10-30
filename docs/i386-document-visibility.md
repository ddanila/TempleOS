# Document visibility controls

The original `DocCursor`, `DocHighlightCursor` and `DocScroll` bodies are
shared through `Adam/DolDoc/DocVisibilityCore.HC` and published by the native
console. They change their respective document flags and return the previous
visibility state; a missing default document returns false.

The pinned original, the extracted source on the original, and the native
image pass the same six-check fixture (mask 63, unchanged inputs;
`build/i386-doc-visibility-original-v1`,
`build/i386-doc-visibility-shared-original-v1`,
`build/i386-doc-visibility-native-v1`; runner
`tools/test-i386-doc-visibility.py`). It checks both directions, repeated
calls, preservation of another flag, default-document selection and an absent
document. It does not qualify visual output, concurrent mutation or task exit.
The preceding native image rejected the missing `DocCursor` binding
(`build/i386-doc-visibility-native-red`). Both bootstrap generations and the
386 cross-build/audit pass (`build/doc-visibility-rebuild-v1.log`,
`build/i386-doc-visibility-cross-v1`). C1–C5 remain open.
An 8 MiB ordinary-include and drive-fields smoke check also passes with
unchanged inputs (`build/i386-doc-visibility-smoke-8m`); it is not a startup
timing or full minimal-profile qualification.

The original `DocMax` body is also shared and published. The pinned original,
shared original and native image pass previous-value, zero, default and absent
document checks (mask 15; `build/i386-doc-max-original-v1`,
`build/i386-doc-max-shared-original-v1`, `build/i386-doc-max-native-v1`;
runner `tools/test-i386-doc-max.py`). The prior native image rejects the
missing binding (`build/i386-doc-max-native-red`). Both bootstrap generations,
the 386 cross-build/audit and an 8 MiB ordinary-include smoke test pass
(`build/doc-max-rebuild-v2.log`, `build/i386-doc-max-cross-v1`,
`build/i386-doc-max-smoke-8m`). Automatic document truncation, concurrent
updates and the full minimal-profile timing gate are not covered.
