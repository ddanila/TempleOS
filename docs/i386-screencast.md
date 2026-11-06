# Screencast state and sound queue reference

`tools/test-i386-screencast.py` exercises the original ScrnCast and Snd bodies
in an isolated original guest. The fixture selects audio-only recording to
inspect actual queue nodes without creating video frames.

`build/i386-screencast-original-v2/result.json` passes with unchanged inputs.
All twelve independently expected values are one. The checks cover starting
from stopped, recording/audio flags, initial pitch in the queue sentinel,
the start-generated rest, duplicate pitch entries, final rest, nondecreasing
capture timestamps, repeated enable, stop and restart. In particular, calling
ScrnCast(TRUE) while already recording returns TRUE but clears recording;
subsequent Snd calls do not append until a new start. The oracle preserves this
observed original behavior rather than assuming an idempotent enable operation.

`build/i386-screencast-native-v1/result.json` fails with unchanged inputs:
the interface-221 image rejects the CSndData declaration at fixture line 4.
None of the native state/queue assertions execute.

This is a state/audio-queue contract, not audible-output, frame-capture,
playback, mute/debug-mode, allocation-failure or whole Psalmody qualification.
The native implementation still needs the real public screencast state and
capture behavior; a placeholder global would not satisfy these checks.

```
python3 tools/test-i386-screencast.py --out OUT_ORIGINAL
python3 tools/test-i386-screencast.py IMAGE --out OUT_NATIVE
```
