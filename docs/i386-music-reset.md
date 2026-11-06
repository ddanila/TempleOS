# Public music settings reset

The complete original Psalmody loader now gets past Find and all four God
providers, then reports an undefined identifier at JukeBox.HC line 191
(`build/i386-psalmody-find-probe-v2/result.json`). The statement parser advances
the token before reporting that error. The preceding line calls
`MusicSettingsRst`, whose existing native implementation lacked a public
binding. The exact original prefix defining JukeReward and SingleSong compiles,
and SingleSong has a nonzero address with fresh rendered arithmetic
(`build/i386-jukebox-prefix-probe-v1/result.json`). These probes preserve their
inputs; they do not qualify the application.

`tools/test-i386-music-reset.py` modifies the public music state, calls the reset,
and checks exact defaults: note number 0, octave 4, meter 4/4, staccato factor
0.9, tempo 2.5, note length 1.0 and last beat 0. It also checks preservation of
the current song name/task, mute flag, note map and time correction, and requires
the reset clock value to be nonnegative (mask 63). The fixture restores the
saved music structure afterward. Floating defaults are compared as exact IEEE
binary64 bytes using an independent host oracle.

* `build/i386-music-reset-original-v1/result.json`: integer and floating vectors
  pass on the pinned original, with unchanged inputs.
* `build/i386-music-reset-native-v1/result.json`: candidate v6 rejects the reset
  call before state checks; unchanged inputs.

```
python3 tools/test-i386-music-reset.py --out build/music-reset-original
python3 tools/test-i386-music-reset.py build/IMAGE/kernel.img --out build/music-reset-native
```

Candidate v7 exposes the existing `Adam/MusicResetCore.HC` function through
console interface 219 and PublicSound.HH. It does not change that implementation
or its existing native clock-lock adaptation. Both bootstrap generations and the 386 cross-build pass (96 BIOS / 332
protected-mode instructions). All 1,370 delivered source/document files match
the snapshot (`build/i386-public-tables-music-reset-source-audit-v1.json`). The
implementation is now applied to main as part of cumulative candidate v8, after
the native build's terminal input audit. Speaker output, exact clock timing, concurrent locking,
playback and complete Psalmody/C1–C5 qualification remain open.

`build/i386-music-reset-candidate-v1/result.json` passes on candidate v7:
exact integer/binary64 defaults, mask 63, fresh rendered arithmetic and
unchanged execution inputs. The complete Psalmody loader is being retested;
this component result alone does not qualify the application.

The v7 Psalmody probe gets past the reset and JukeBox, then rejects the
CHashFun dbg_info member in JukePuppet line 11. Including the complete existing
Kernel/SymbolTypes.HH resolves that type visibility gap and reaches missing
TaskCaller at line 17 (`build/i386-psalmody-symbol-types-probe-v1/result.json`).
Both probes preserve their inputs; function debug metadata and task stack
inspection still need their own compatibility work.
