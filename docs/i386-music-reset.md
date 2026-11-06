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
or its existing native clock-lock adaptation. Bootstrap/runtime validation is
pending; it remains in a plain source snapshot while the ongoing native build
pins main's inputs. Speaker output, exact clock timing, concurrent locking,
playback and complete Psalmody/C1–C5 qualification remain open.
