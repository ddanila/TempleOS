# Prefixed editor links

The original `Ed` accepts editor links, including `FI:` filenames and line,
anchor, find, dictionary and help links. The native `Ed` remains a file-level editor subset. It now sends `FI:` file
links through the original `EdLinkCvt` converter before opening the file. Other
prefixed link types and nonzero editor flags still require the full original
editor path.

`tools/test-i386-doc-prefixed-link.py` exercises a real `FI:` link through
`DocEntryRun`: it writes a test file, queues a character and Escape, and checks
the callback result, lock and task document restoration, and saved content.
The pinned original and current shared-source original pass all five checks
(`build/i386-doc-prefixed-link-original-v2`,
`build/i386-doc-prefixed-link-shared-original-v1`). The previous native image failed the same contract with a literal `/FI:C:`
parent (`build/i386-doc-prefixed-link-native-red-v2`). The updated native image
passes real edit-and-save sessions for uppercase `FI:` and lowercase `fi:`
(`build/i386-doc-fi-link-native-v1`); the original passes both cases
(`build/i386-doc-fi-link-original-v2`).

The complete original `Ed`/`Plain` and `DocFileEd` bodies are now shared in
`Adam/DolDoc/EdLinkOpenCore.HC` and `Adam/DolDoc/DocFileEdCore.HC`. Both original
bootstrap generations and the native cross-build/386 audit pass
(`build/doc-prefixed-ed-rebuild-v1.log`,
`build/i386-prefixed-ed-share-cross-v1`). The updated image also passes both
original bootstrap generations, the 386 cross-build/audit, the unprefixed
link session and an 8 MiB ordinary-include/drive-fields smoke check
(`build/doc-fi-link-rebuild-v2.log`, `build/i386-doc-fi-link-cross-v2`,
`build/i386-doc-fi-link-unprefixed-native-v1`,
`build/i386-doc-fi-link-smoke-8m`). These
extractions retain all link types; they are not yet the native editor provider.
That integration requires real directory-context handling and the original
help, dictionary and raw-editor dependencies, as well as original document
navigation and error/cleanup behavior. `docs/i386-directory-context.md`
records the directory-context work still required. This test does not cover
mouse or popup delivery, every link type, error paths or the full desktop.
C1–C5 remain open.
