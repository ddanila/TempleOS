# Note and octave conversion oracle

`tools/test-i386-note-conversion.py` checks `Ona2Note`, `Ona2Octave` and
`Note2Ona` against 1,482 independently calculated bytes: all 256 signed I8
pitch values, 925 signed note/octave pairs, 37 default-octave calls and eight
I64 boundary pairs. The host oracle uses truncation toward zero for signed
division and byte wrapping for I8 results.

`build/i386-note-conversion-original-v2/result.json` passes with unchanged
inputs. `build/i386-note-conversion-native-v2/result.json` fails with unchanged
inputs at the first `Ona2Note` call, fixture line 8, on interface 222. No native
behavior assertion runs. The v1 attempts used unsupported local array
initializers; both failures are preserved. Moving those fixed tables to globals
leaves the expected bytes unchanged.

Psalmody currently stops at missing `Ona2Octave` in its draw code. This oracle
covers the three conversion functions needed to progress that integration;
it does not qualify frequencies, playback or the complete application.

```
python3 tools/test-i386-note-conversion.py --out ORIGINAL_OUT
python3 tools/test-i386-note-conversion.py IMAGE --out NATIVE_OUT
```

## Native conversion family (2026-11-06)

Interface 224 shares the byte-identical original three-function body through
`Adam/Snd/NoteConversionCore.HC`, used by both original sound sources and the
native sound provider. All three public bindings are exported; the 611-symbol
export bitmap now has twenty words. The initial cross-build rejected the new
export entries before their definitions; explicit forward declarations fix
that ordering without changing the function bodies.

Both bootstrap generations pass in
`build/rebuild-note-conversion-v2-verified/result.json`. The full-content
cross-v2 image packages successfully with a 1,722-source unchanged audit and
passing boot instruction audit. `build/i386-note-conversion-native-v3/result.json`
passes all 1,482 oracle bytes and fresh arithmetic. The welcome-screen v1
regression passes exact welcome, clear and input at 8 MiB TCG. Both input audits
are unchanged. This does not qualify the full diagnostic suite.

`build/i386-psalmody-note-conversion-v1/result.json` verifies the original app
bytes, advances beyond Ona2Octave, then fails at the embedded Sprite call in
PsalmodyDraw line 381. Inputs are unchanged. Recording, deletion and abort
assertions still do not execute; the application remains unqualified.
