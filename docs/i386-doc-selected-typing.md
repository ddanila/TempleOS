# Printable insertion into selected text

This is a separate C4 compatibility gap exposed while adding ordinary typing
controls to the printable metadata test. The selected-text replacement behavior
of the retained native editor must not be treated as the original contract.

`tests/guest/i386-doc-selected-typing/Contract.HC` sends uppercase A with Shift
and lowercase z through public DocPutKey, first with unselected Keep text and
then with the same entry manually marked DOCET_SEL. It uses DONT_SWAP_OUT to
isolate insertion from scheduling. Every case requires the original exact
text, cursor entry/column, selection flag, unchanged key description, unlocked
return, unchanged caller document roles and exact caller heap recovery.

The pinned original passes four masks127 in
`build/i386-doc-selected-typing-original-v1`. Its exported text buffer is
`AKeep\0zKeep\0AKeep\0zKeep\0`: insertion retains the selected entry, moves the
cursor to column1 and preserves its selection flag. Both unselected controls
have the same resulting text and remain unselected. The buffer is explicitly
initialized and exports the actual text, correcting the insufficient output
capture in the earlier metadata-test v3 experiment.

Native `i386-doc-selected-typing-native-baseline-v1` fails with masks
[127,127,120,120]. The unselected controls agree, but selected cases produce
only A and z and fail text, cursor and selection checks. Description, lock,
roles and caller-heap checks pass. Independent terminal audits reverify input
hashes and exported masks/text; the native volume retains every preexisting
file and adds only the fixture, with allocation integrity intact.

Source inspection explains the observed native divergence. Original DocPutKey
calls EdCharIns for printable input. The native wrapper only routes some
character cases through original helpers and otherwise calls DocBasicEditCore.
That fallback explicitly invokes DocBasicSelectionDelete before ordinary
printable insertion. Its comment asserts replacement behavior that is
contradicted by this executable original observation.

The required end state is original insertion behavior through the public key
dispatch, including normal editor integration. Changing only this fixture,
clearing selection before calling DocPutKey or retaining replacement as an
undocumented compatibility exception would not close the gap. Complete
character handling, interactive selection, arbitrary entry types and full
DocPutKey remain unqualified.

Reproduce using fresh output directories:

```
python3 tools/test-i386-doc-selected-typing.py --out build/NEW-original
python3 tools/test-i386-doc-selected-typing.py build/i386-doc-key-description-cross-v1/kernel.img --out build/NEW-native
```

## Original printable handler integration

Native DocPutKey now routes every printable character without Ctrl/Alt through
EdCharIns, with SCF_KEY_DESC handled by the existing description-only branch.
The wrapper's separate dollar, action, data/hex and form-Tab branches are
removed because EdCharIns already performs them in original order. Nonprintable
navigation/deletion and missing shortcuts still use the retained dispatch;
this does not complete DocPutKey. No public ABI/version change is needed.

`build/i386-doc-selected-typing-native-v1` passes all four masks127 and exports
the exact original text and mask buffers. The metadata suite
(`i386-doc-description-typing-v1`, nine queries and two ordinary typing controls),
nineteen clipboard cases (`i386-clipboard-keys-typing-v1`) and five scheduling
cases (`i386-doc-yield-typing-v1`) also match their original binary exports.
Independent terminal audits reverify input hashes, arithmetic and filesystem
integrity. Clipboard caller/root heap deltas remain zero.

Both bootstrap generations pass in `rebuild-doc-selected-typing-v1-verified`.
The cross-build `i386-doc-selected-typing-cross-v1` passes its 386 audit
(96 BIOS/332 protected-mode instructions), and the post-export audit verifies
all 1737 production source hashes against the bootstrap inputs. The existing
x64 bootstrap gate is not C5 native release-generation qualification.

The normal 8 MiB welcome and full 16 MiB diagnostic startup both pass exact
307200-pixel comparisons. The diagnostic audit checks both program-probe
completion phases, both code-heap ownership results, both file-break cleanup
phases and startup DONE. These concurrent runs do not establish the isolated
60-second timing gate.

The physical keyboard/VGA editor test (`i386-doc-typing-physical-v1`) passes
multiline insertion, vertical movement, exact displayed cursor and serialized
text/cursor bytes. The six callback/default-document/insertion/overstrike/undo
cases (`i386-doc-typing-core-v1`) and eight form-Tab cases
(`i386-doc-typing-tabs-8m-v1`) pass. Repeated delivered diagnostic loads
(`i386-doc-typing-allocation-v1`) each return13, unload cleanly and pass the
existing dollar-growth allocation-failure recovery check. Terminal audits
reverify all test input hashes. The paired [dollar-state fixture](i386-dollar-input.md)
also passes on the original and this image.

The first 64 MiB action and Tab runs hit their startup deadline before any
case, under concurrent load; they remain recorded as incomplete. The first
8 MiB action repeat compiled the fixture but stopped at the exact-screen
oracle because it omitted two visible unused-variable warnings. No action
case had run. The host oracle now requires those two warning rows; the guest
fixture and all seven action assertions are unchanged. Frozen inputs and
actual/expected screenshots are retained with the incomplete run.

The final action repeat (`i386-doc-typing-actions-8m-v2`) passes all seven
cases, exact warning/result screens and fresh arithmetic. Its fixture hash
matches the pinned original's earlier passing seven-case run. Only the host
warning-row expectation changed. The terminal audit rechecks all input hashes.

The older 22-command dollar keyboard/VGA run (`i386-doc-typing-dollar-v1`)
remains live at this checkpoint, beyond startup and through its first typed
command-state assertions. It is not counted as a full pass here. The paired
six-case packaged dollar oracle is terminal and passing on both systems.
Full dispatcher/desktop behavior, the historical capacity-reuse expectations,
broader memory pressure and C1–C5 release qualification remain open.
