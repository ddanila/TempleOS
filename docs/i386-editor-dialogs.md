# Public editor dialog dispatch

ConsoleRuntime 136 exposes EdFindReplace and EdGoToLine at export indices 330
and 331. EditorRuntime 5 appends both functions to its service record; the
permanent Console dispatch loads the existing optional editor provider and calls
the full original functions. All original function bodies in
DocEditorReplaceCore.HC are unchanged. The three original RSAC_* menu constants
now live in shared DocReplaceMenuTypes.HH, included by both the implementation
and public document headers. This closes two callable dependencies of original
DocPutKey without substituting a reduced key handler. Full DocPutKey integration
remains open.

The original control in `build/i386-c2-editor-dialogs-reference-tags` passes six
cases: go-to-line accept/cancel, find/replace form cancellation, prompted ALL,
replacement-menu cancellation, and unprompted replacement. The fixture formats
the line-number entry with DocDataFmt and directly selects the ALL button, then
posts real Esc/ShiftEsc messages. Thus it exercises the original form scan,
accept/cancel and post-exit action paths, not keyboard field editing or mouse/
arrow navigation. The caller's put/display/border and popup roles must recover.

Three serialized documents and three entry-tag transcripts are captured. The
serialized go-to-line form is empty, and the find/replace form retains only nine
newline bytes: DocSave omits their bound data fields. Entry-tag transcripts
therefore independently record the numeric field, text values and checkboxes.
The replacement chooser document is 141 bytes. All final original execution
inputs remain unchanged. The rebuilt-original control in `build/i386-c2-editor-
dialogs-rebuilt` also passes all six cases and produces identical hashes for all
six captures, with unchanged inputs.

Fixture failures are retained. The initial control returned mask 62 because a
successful empty-file write returns INVALID_CLUS rather than a positive number.
The first correction wrongly assumed FileWrite returns byte count and returned
mask 50. Original FileWrite returns a cluster number. The read-back fixture
passes mask 63; the final fixture uses byte-by-byte read-back verification and
adds the entry-tag captures. Evidence directories are `build/i386-c2-editor-
dialogs-reference`, `-reference-fixed`, `-reference-readback` and `-reference-
tags`; executed prior fixtures are preserved alongside their results and
overlays.

Both bootstrap generations pass. Cross-build and the 386 audit pass in
`build/i386-c2-editor-dialogs-cross`, with all 1532 source and 24 build-input
hashes unchanged. The packaged provider passes all nineteen search/selection
commands, exact source delivery and exactly one lazy load in
`build/i386-c2-editor-dialogs-provider`, with execution inputs unchanged. The
preceding image rejects the undefined dialog functions in `build/i386-c2-editor-
dialogs-native-red`. The first candidate dialog run was intentionally terminated
after its captured screen proved a fixture answer mismatch: assigning
ed_drive=67 prints 67, but the harness expected no answer. Its report,
screenshot, runner and termination record are preserved in
`build/i386-c2-editor-dialogs-native`. The corrected native run expects 67; that
run exposed missing RSAC_* constants in the caller namespace when the
replacement chooser evaluated its dollar-command expressions. Its log and
termination record are preserved in `build/i386-c2-editor-dialogs-native-
answers`. The original constants are now shared through the public document
header; fresh bootstrap and cross-build pass with all 1533 source and 24 build-
input hashes unchanged in `build/i386-c2-editor-dialogs-constants-cross`. Its
`constants-comparison.json` confirms that all compiled modules are byte-
identical to the preceding candidate; only the three source/header files differ.
The corrected native dialog run passes all nine commands and all six exact
captures in `build/i386-c2-editor-dialogs-native-constants`, with unchanged
execution inputs and exactly one editor load on first use. The same complete
contract passes at 8 MiB in `build/i386-c2-editor-dialogs-native-8m`, including
all nine commands and identical captures. Its 60.494272-second startup
observation was not isolated and does not qualify the 60-second target. Both
runs leave the window manager active. The final source-delivery/provider
regression also passes all nineteen commands in `build/i386-c2-editor-dialogs-
constants-provider`, with unchanged inputs and one lazy load. The wrong-version
recovery test passes all 21 commands in `build/i386-c2-editor-dialogs-wrong-
version`, with unchanged inputs: repeated rejection, in-guest repair, successful
retry, cached reuse after disk corruption, restored module bytes, caller heap,
directory and roles. Editor version rejection now mutates version 5 to the
previous version 4. The earlier wrong-version recovery result applies to the
identical compiled modules, as confirmed by constants-comparison.json. Fresh
isolated startup and 16 MiB diagnostics are queued against the committed
candidate; C1–C5 and all inventory entries remain unqualified.

```sh
python3 tools/test-i386-editor-dialogs.py --out ORIGINAL
python3 tools/test-i386-editor-dialogs.py IMAGE --reference ORIGINAL --out NATIVE
python3 tools/test-i386-editor-dialogs.py IMAGE --ram-mib 8 --reference ORIGINAL --out NATIVE_8M
python3 tools/test-i386-editor-provider.py IMAGE --out PROVIDER
python3 tools/test-i386-editor-provider-recovery.py IMAGE --fault wrong-version --out RECOVERY
```
