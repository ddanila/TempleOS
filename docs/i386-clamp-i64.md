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

## Candidate execution

The candidate passes both bootstrap generations and the cross-build/386 audit
(`build/i386-public-tables-candidate-v3/source/build/public-tables-cross-v1`).
Its delivered-source audit matches all 1,368 files
(`build/i386-public-tables-clamp-source-audit-v1.json`).
`build/i386-clamp-i64-candidate-v1/result.json` passes all 22 result values and
fresh rendered arithmetic with unchanged execution inputs.

`build/i386-source-startup-candidate-v1/result.json` also passes the corrected
custom, syntax-error and missing-source cases on this image, including all pixel
checkpoints and unchanged inputs. The separate 16 MiB diagnostic attempt
`build/i386-public-tables-clamp-minimal-v1` ended at its 240-second harness
timeout before a completed welcome-frame oracle; it is not a pass. A longer
observation run is recorded separately as v2. Neither run changes the minimal
interactive startup budget or establishes full C4/C5 qualification.

The diagnostic in `build/i386-psalmody-god-probe-v4/result.json` checks SC_DELETE
without explicitly including ScanCodes, then loads the complete original
GodExt, GodBible, HolySpirit and GodSong sources successfully. The unchanged
Psalmody loader now rejects `FileOcc` at JukeBox line 135. That function belongs
to `Adam/Opt/Utils/Find.HC`; the next prerequisite is the full original find
utility and its public dependencies. No Psalmody UI execution is claimed.
