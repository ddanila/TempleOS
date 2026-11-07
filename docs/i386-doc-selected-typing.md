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
