# Screencast state and sound queue reference

`tools/test-i386-screencast.py` exercises the original ScrnCast and Snd bodies
in an isolated original guest. The fixture selects audio-only recording to
inspect actual queue nodes without creating video frames.

`build/i386-screencast-original-v2/result.json` passes the initial twelve
checks with unchanged inputs. The expanded twenty-check fixture also passes
with unchanged inputs in `build/i386-screencast-original-v3/result.json`.
All independently expected values are one. The checks cover starting
from stopped, recording/audio flags, initial pitch in the queue sentinel,
the start-generated rest, duplicate pitch entries, final rest, nondecreasing
capture timestamps, repeated enable, stop and restart. In particular, calling
ScrnCast(TRUE) while already recording returns TRUE but clears recording;
subsequent Snd calls do not append until a new start. The oracle preserves this
observed original behavior rather than assuming an idempotent enable operation.

`build/i386-screencast-native-v1/result.json` fails with unchanged inputs:
the interface-221 image rejects the CSndData declaration at fixture line 4.
None of the native state/queue assertions execute.

The additional checks exercise Mute/IsMute, suppression of muted notes,
updated current pitch without queue insertion in debugger mode, SndRst clearing
a deliberately stuck sound semaphore, speaker-off state, and preservation of
the interrupt-enable flag.

This is a state/audio-queue contract, not audible-output, frame-capture,
playback, allocation-failure or whole Psalmody qualification.
Console interface 222 now publishes the actual screencast state, ScrnCast,
Mute and IsMute. The original Snd/ScrnCast/SndRst bodies and state types are
shared with the x64 system, byte-for-byte at extraction. Native initialization
creates the real queue sentinel and timestamps; capture nodes and the format
string use scheduler-root allocation. Mute maps the original interrupt-save
region to native save/restore primitives. The original PIT divisor expression
replaces the prior native approximation; audible frequency/waveform qualification
remains open.

Both bootstrap generations and cross-v2 pass. The source audit verifies all
1,717 source hashes and build-helper hashes unchanged. All twenty native checks
and fresh arithmetic pass with unchanged inputs in
`build/i386-screencast-native-v2/result.json`. Exact welcome/clear/input also
passes at 8 MiB TCG 486,-fpu in `build/i386-screencast-welcome-v1`.

Video frame recording is not yet connected to the native compositor. The
original bitmap/GR dependency oracle passes, while the native image rejects
its first DCCopy invocation. This remains required work before complete
screencast or Psalmody qualification. The expanded full-content image is
verified in `build/i386-screencast-full-v2`; the first repack attempt incorrectly
reused nonzero filesystem padding and was rejected by the directory verifier.
Both artifacts are preserved.

```
python3 tools/test-i386-screencast.py --out OUT_ORIGINAL
python3 tools/test-i386-screencast.py IMAGE --out OUT_NATIVE
```

The Beep integration regression passes at 8 MiB TCG 486,-fpu in
`build/i386-screencast-beep-v2/result.json`, with unchanged inputs: actual
speaker on/off observation, delay, busy cleanup and fresh arithmetic. The v1
attempt stopped before Beep because the old harness omitted the fixture's
unused-parameter warning; v2 expects that exact single warning. This does not
qualify the emitted waveform or frequency.
