# Frame-capture bitmap and GR dependencies

`tools/test-i386-frame-capture.py` uses an 8-by-4 bitmap with bytes 0 through
31, an identity matrix and a separate depth buffer. Its twelve checks cover
independent copies, unchanged-image diff, exact one-pixel and rectangular diff
bounds/pixels, compressed save/load, and real GR file write/read.

The uncompressed export must equal an independently constructed 32-byte header
(`<q6i`: timestamp 0x0102030405060708, origin -2/5, dimensions 8/8/4, flags zero)
followed by bytes 0 through 31. The file must match those bytes, and its reload
must retain the timestamp, origin, dimensions and pixels.

`build/i386-frame-capture-original-v1/result.json` passes all twelve checks and
both byte exports with unchanged inputs. The interface-222 native image fails
at the first DCCopy call (fixture line 10), before any behavior assertions run,
in `build/i386-frame-capture-native-v1/result.json`; inputs are unchanged.

These dependencies are required by screencast frame recording. Actual screen
composition/capture timing, frame sequences, all allocation-failure cleanup and
complete screencast behavior remain unqualified.

```
python3 tools/test-i386-frame-capture.py --out OUT_ORIGINAL
python3 tools/test-i386-frame-capture.py IMAGE --out OUT_NATIVE
```
