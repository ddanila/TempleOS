# Public word-character bitmap

After the candidate public byte-table exports, original `GodExt.HC` and
`GodBible.HC` load, but `HolySpirit.HC` rejects `char_bmp_word` at line 95.
This is recorded by `build/i386-psalmody-god-probe-v2/result.json`; Psalmody
has not launched. The kernel already owns the original bitmap through
`Kernel/CharBitmaps.HC`, but does not export this particular array.

`tools/test-i386-word-bitmap.py` captures all 64 bytes of the public
`U32 char_bmp_word[16]`. The independent host oracle allows ASCII letters,
digits, underscore, apostrophe and byte values 128–255. Every other bit through
511 must be clear, including lexer token values above 255.

* `build/i386-word-bitmap-original-v1/result.json`: all 512 bits pass against
  the pinned original system; execution inputs unchanged.
* `build/i386-word-bitmap-native-v1/result.json`: the public-table candidate
  image rejects `char_bmp_word` while compiling the fixture, before execution;
  inputs unchanged.

```
python3 tools/test-i386-word-bitmap.py --out build/word-bitmap-original
python3 tools/test-i386-word-bitmap.py build/IMAGE/kernel.img \
  --out build/word-bitmap-native
```

The implementation candidate in `build/i386-public-tables-candidate-v2/source`
adds a data export pointing at the existing kernel array and an exact public
array declaration. This implementation is now applied to main after the native
build's terminal input audit. This
regression does not qualify the other character bitmaps, God provider, Psalmody
or C1–C5.

The candidate now passes both bootstrap generations and the cross-build/386
audit (`build/i386-public-tables-candidate-v2/source/build/public-tables-cross-v1`).
`build/i386-word-bitmap-candidate-v1/result.json` passes all 512 bits and fresh
rendered arithmetic with unchanged inputs. The delivered-source audit passes
all 1,368 files (`build/i386-public-tables-word-source-audit-v1.json`). These
results establish that earlier candidate; the cumulative main-source audit is
`build/i386-public-tables-main-source-audit-v1.json`.
