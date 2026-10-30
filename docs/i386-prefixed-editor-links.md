# Prefixed editor links

The original `Ed` accepts editor links, including `FI:` filenames and line,
anchor, find, dictionary and help links. The native `Ed` remains a file-level editor subset. It now sends `FI:` file
and `FL:` links through the original `EdLinkCvt` converter before opening the
file. `FL:` additionally positions the cursor with the original line-navigation
service. Other
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

For `FL:` and lowercase `fl:`, a real editor session inserts a character at the
requested second line and saves it. The pinned original and native systems pass
all five checks, including task-document and lock restoration
(`build/i386-doc-line-link-original-v2`, `build/i386-doc-line-link-native-v1`;
runner `tools/test-i386-doc-line-link.py`). The original adds a cursor marker
between the inserted character and the line text; the fixture checks the
surrounding line content rather than requiring byte-identical document output.
The first reference expectation assumed adjacent text and failed; the captured
original bytes are in `build/i386-doc-line-link-original-trace-v1`. Both
bootstrap generations and the cross-build/386 audit pass
(`build/doc-fl-link-rebuild-v1.log`, `build/i386-doc-fl-link-cross-v1`). The
previous FI session and 8 MiB ordinary-include/drive-fields smoke also pass
(`build/i386-doc-fl-fi-regression-v1`, `build/i386-doc-fl-link-smoke-8m`).
This does not establish every line number, missing files, other link types,
flags, mouse input or popup navigation.
