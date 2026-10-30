# Prefixed editor links

The original `Ed` accepts editor links, including `FI:` filenames and line,
anchor, find, dictionary and help links. The native `Ed` remains a file-level
editor subset. It now sends `FI:`, `FL:`, `FF:`, `FA:`, `PI:`, `PF:`, `PL:`, `AI:`, `AA:`, `AF:` and `AL:`
links through the original `EdLinkCvt` converter before opening the file. `FL:` positions the cursor with the original line-navigation
service; `FF:` and `FA:` use the original document search and anchor routines.
Other prefixed link types and nonzero editor flags still require the full original
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

The native editor provider now exports the original `DocFind` and
`DocAnchorFind` routines through version 6 of its interface. The direct
original/native navigation contract checks line selection, case-insensitive
occurrence selection, anchor selection, missing targets and heap recovery
(`build/i386-doc-search-public-original-v1`,
`build/i386-doc-search-public-native-v1`). Real `FF:`/`ff:` and `FA:`/`fa:`
link sessions pass on original and native, including edits at the selected
text or anchor and saving (`build/i386-doc-find-link-original-v1`,
`build/i386-doc-find-link-native-v1`, `build/i386-doc-anchor-link-original-v1`,
`build/i386-doc-anchor-link-native-v1`). The anchor test checks the insertion
location against bytes captured from the original
(`build/i386-doc-anchor-link-original-trace-v1`). Both original bootstrap
generations, the native cross-build/386 audit, the `FL:` regression, and an
8 MiB ordinary-include/drive-fields smoke check pass
(`build/doc-find-link-rebuild-v1.log`, `build/i386-doc-find-link-cross-v1`,
`build/i386-doc-find-fl-regression-v1`, `build/i386-doc-find-link-smoke-8m`).
These tests cover bounded targets, not every search occurrence, missing-link
editor behavior, other link types, flags, popup or physical mouse delivery.

Plain-text `PI:`, `PF:` and `PL:` links now set the original plain-text and
no-cursor document flags; the shared original `Plain()` function is public on
native. Seven original, shared-original and native edit-and-save sessions cover
uppercase and lowercase prefixes and a direct `Plain()` call. They verify the
selected edit location and that `$RED$` is retained literally
(`build/i386-doc-plain-links-original-v2`,
`build/i386-doc-plain-links-shared-v1`, `build/i386-doc-plain-links-native-v1`;
runner `tools/test-i386-doc-plain-links.py`). Both original bootstrap
generations, the native cross-build/386 audit, the `FF:` regression and an 8 MiB
ordinary-include/drive-fields smoke check pass (`build/doc-plain-links-rebuild-v2.log`,
`build/i386-doc-plain-links-cross-v2`, `build/i386-doc-plain-ff-regression-v1`,
`build/i386-doc-plain-links-smoke-8m`). The first cross-build lacked the
formatter forward declaration (`build/i386-doc-plain-links-cross-v1`). These
bounded checks do not establish all markup, nonzero editor flags, error
cleanup, popup or physical mouse behavior.

In-memory `AI:`, `AA:`, `AF:` and `AL:` links now edit the borrowed target
document without writing or deleting it. Eight uppercase/lowercase sessions
compare original and native editing at the original selected position and check
target lifetime, locks and caller document roles
(`build/i386-doc-memory-links-original-v4`,
`build/i386-doc-memory-links-shared-v2`, `build/i386-doc-memory-links-native-v2`;
runner `tools/test-i386-doc-memory-links.py`). Original output traces used to
set the four expected edit positions are in
`build/i386-doc-memory-links-original-trace-v4`. Both original bootstrap
generations, the 386 cross-build/audit, the `FF:` file-link regression and an
8 MiB ordinary-include/drive-fields smoke pass
(`build/doc-memory-links-rebuild-v1.log`, `build/i386-doc-memory-links-cross-v1`,
`build/i386-doc-memory-ff-regression-v1`, `build/i386-doc-memory-links-smoke-8m`).
The first native fixture rejected an overlong exception literal before executing
its contract (`build/i386-doc-memory-links-native-v1`). Tests use live valid
documents and zero editor flags; invalid addresses, error unwinding, general post-editor actions, popup and
physical mouse delivery remain unqualified.

On an accepted editor exit, native now runs the current document entry through
`DocEntryRun` before saving or returning, matching the original sequence;
Shift-Escape skips it. Original, shared-original and native tests cover an
actual in-memory link whose selected entry has a callback: Escape runs the
callback unlocked and posts its command result, while Shift-Escape does neither.
They check the target, locks and caller document roles
(`build/i386-doc-editor-exit-action-original-v1`,
`build/i386-doc-editor-exit-action-shared-v1`,
`build/i386-doc-editor-exit-action-native-v1`; runner
`tools/test-i386-doc-editor-exit-action.py`). The earlier native image fails
that contract (`build/i386-doc-editor-exit-action-native-red-v1`). Both
bootstrap generations, the cross-build/386 audit, the in-memory-link regression
and an 8 MiB ordinary-include/drive-fields smoke pass
(`build/doc-exit-action-rebuild-v1.log`, `build/i386-doc-exit-action-cross-v1`,
`build/i386-doc-exit-memory-regression-v1`, `build/i386-doc-exit-action-smoke-8m`).
This is one callback action on a live borrowed document; other entry actions,
errors and file/desktop workflows still need coverage.
