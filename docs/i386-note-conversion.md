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
