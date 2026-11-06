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

## Native wrapper (2026-11-07)

Interface 225 shares the exact original Sprite body through SpriteOutputCore.HC
and exports it with the original public signature. Both bootstrap generations
and the full-content cross-build pass. The source/helper audit matches 1,723
sources and 26 helpers. `build/i386-sprite-output-native-v2/result.json` passes
all six checks and fresh arithmetic; the welcome-v1 regression passes exact
welcome/clear/input at 8 MiB TCG. Both input audits are unchanged.

`build/i386-psalmody-sprite-output-v1/result.json` verifies the original app
bytes and advances past Sprite, then fails at missing CmpCtrlNew in
PsalmodyFile line 203. Inputs are unchanged. Recording/deletion/abort assertions
do not execute. The song loader also needs Lex and LexExtStr; that compiler
control path remains to be qualified. Complete Psalmody remains unqualified.
