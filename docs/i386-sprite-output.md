# Command-line Sprite output

The six-check oracle in `tools/test-i386-sprite-output.py` covers default and
tagged Sprite insertion into the current output document, exact copied bitmap
bytes, distinct binary records/use counts, independence after source mutation,
and a NULL result when there is no output document.

`build/i386-sprite-output-original-v1/result.json` passes all six checks.
`build/i386-sprite-output-native-v1/result.json` rejects Sprite at fixture
line 10, before behavior assertions. Both input audits are unchanged. This
matches Psalmody's next missing public service after note conversion. Rendering,
interactive editing and complete Psalmody workflows remain unqualified.

```
python3 tools/test-i386-sprite-output.py --out ORIGINAL_OUT
python3 tools/test-i386-sprite-output.py IMAGE --out NATIVE_OUT
```
