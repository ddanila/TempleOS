# Public Beep

The original `Beep` body is shared with the native runtime and exposed through
the public sound interface. It calls the existing PIT speaker provider, waits
using the scheduler or original busy-wait path, and silences the speaker.

The shared fixture uses an observer task to sample the speaker gate, checks
that it observes enabled and disabled states, checks the normal call's elapsed
time and final silence, and verifies that the busy call also ends with the gate
off. It returns mask 31 on the pinned original, rebuilt original and native 64 MiB image with
unchanged inputs (`build/i386-beep-reference-v1`, `build/i386-beep-rebuilt-v1`,
`build/i386-beep-native-v2`).
The original two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-beep-rebuild-v1.log`, `build/i386-beep-cross-v1`). This does not
qualify precise duration, every note, cancellation or physical speaker hardware.

An additional 8 MiB QEMU waveform test of the underlying `Snd` provider
observes the expected 440 Hz and 880 Hz tones and silence after stop and reset
(`build/i386-beep-speaker-v3`). It checks `Snd`, not the audio waveform of
`Beep` itself. The first attempt expected a non-welcome console and timed out
at its initial screen; the second reached the sound group but hit its long
command's welcome-screen wrapping limit (`build/i386-beep-speaker-v1`,
`build/i386-beep-speaker-v2`). The runner now offers `--welcome` and uses
short gate checks in that mode; its non-welcome PIT-divisor and interrupt-flag
checks are unchanged.

Unchanged KeepAway advances past `Beep` and stops at `Noise` on line 487
(`build/i386-app-keepaway-beep-v1`, inputs unchanged). This is a load check;
gameplay and C1–C5 remain open.
