# Public signed integer clamp

Original `GodSong.HC` requires `ClampI64` while constraining its selected octave.
After the public word-bitmap candidate, `GodExt.HC`, `GodBible.HC` and
`HolySpirit.HC` load, but `GodSong.HC` rejects `ClampI64` at line 72
(`build/i386-psalmody-god-probe-v3/result.json`). Psalmody has not launched.

The original `_CLAMP_I64` assembly in `Kernel/KUtils.HC` applies a signed lower
bound followed by a signed upper bound. Thus reversed bounds return the upper
bound, regardless of input. `Kernel/KernelB.HH` declares three I64 arguments and
an I64 result, with no defaults.

`tools/test-i386-clamp-i64.py` checks 22 cases against independent host
`min(max(value, lower), upper)` results. Cases cover both endpoints, equal and
reversed bounds, I64 minimum/maximum and positive/negative values beyond 32 bits.
The exported result vector is compared byte for byte; the native success path
also requires fresh rendered arithmetic.

* `build/i386-clamp-i64-original-v1/result.json`: all 22 cases pass; inputs unchanged.
* `build/i386-clamp-i64-native-v1/result.json`: the word-bitmap image rejects the
  missing function while compiling the fixture; inputs unchanged.

```
python3 tools/test-i386-clamp-i64.py --out build/clamp-original
python3 tools/test-i386-clamp-i64.py build/IMAGE/kernel.img --out build/clamp-native
```

The plain source snapshot `build/i386-public-tables-candidate-v3/source` adds
`_CLAMP_I64` as a function export for the existing `NativeSourceClampI64` helper,
whose signed lower-then-upper behavior already matches the original assembly.
It adds the exact public declaration and advances the console interface to 215.
It remains under validation and is not yet applied to main, whose core inputs
are pinned by the running C5 native build. Unsigned clamping, other math APIs,
full God/Psalmody workflows and C1–C5 remain unqualified.
