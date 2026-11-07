# Native sound-effect tasks

The original `Noise` and `Sweep` task bodies are shared with the native console.
They use the existing speaker, scheduler, task frame-pointer and music-state
services, including the original task-end callback that frees the frame,
decrements the mute count and silences the speaker. The original music state
record is shared with the native public sound interface.

`Ona2Freq` accepts an `I8`, so the native provider uses the original x87 result
for every one of its 256 possible input bytes. The pinned and rebuilt originals
produced identical 2,048-byte captures; the committed oracle and generated
native table retain that result (`build/i386-ona-reference-v1`,
`build/i386-ona-rebuilt-v2`). The native test calls `Ona2Freq` for the entire
domain and matches the capture byte-for-byte with unchanged inputs
(`build/i386-ona-native-v1`). `tools/gen-i386-ona-frequencies.py --check`
verifies that the committed table is generated from the pinned capture. This
qualifies the discrete original note function, not general exponentiation.

The shared sound-effects fixture checks zero or negative duration, normal
`Noise` and `Sweep` task creation and completion, observed speaker gating,
mute restoration, final silence, and forced termination after the task frame
is registered. It returns mask 63 on the pinned original, rebuilt original and
native 64 MiB image with unchanged inputs
(`build/i386-sound-effects-reference-v2`,
`build/i386-sound-effects-rebuilt-v2`, `build/i386-sound-effects-native-v2`).
The original two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-sound-effects-rebuild-v1.log`,
`build/i386-sound-effects-cross-v1`). At 8 MiB, the full fixture could not be compiled because the guest heap was
exhausted (`build/i386-sound-effects-native-8m-v1`). A smaller fixture did run
a `Noise` task, observe its speaker gate and verify cleanup
(`build/i386-sound-effects-small-8m-v2`); it does not cover the full lifecycle
fixture. The 8 MiB resource limitation remains open. These tests do not establish every note,
frequency sweep waveform, overlapping effect, allocation failure or physical
speaker behavior.

Unchanged KeepAway advances past `Noise` and stops at mouse state `ms` on line
504 (`build/i386-app-keepaway-effects-v1`, inputs unchanged). This is a load
check; gameplay and C1–C5 remain open.

The native note provider now stores 12 octave bases and 128 packed correction
bytes (224 bytes of table data instead of 2,048). The generator derives these
from the same pinned oracle, and the decoded results still match all 256
original values byte-for-byte (`build/i386-ona-compact-native-v1`). The 64 MiB
sound-effects lifecycle fixture also passes on the compact image
(`build/i386-ona-compact-effects-64m-v1`). Both original rebuild generations,
the native cross-build and the 386 audit pass
(`build/i386-ona-compact-rebuild-v1.log`, `build/i386-ona-compact-cross-v1`).
The loaded console span is 584 bytes smaller than the preceding image, but the
full 8 MiB fixture still exhausts the same compiler heap on the same allocation
(`build/i386-ona-compact-effects-8m-v1`). The 8 MiB resource gate remains open;
decoding overhead has not been profiled.

With shared low-memory backing, the full asynchronous sound-effects fixture now
passes at 8 MiB with unchanged inputs (`build/i386-backing-fallback-effects-8m-v1`).
Its concurrent startup was 74.80 seconds and does not qualify the timing gate.

## Original timer divisor in the speaker regression

The shared original `Snd` uses `SYS_TIMER_FREQ=(18333*65536/1000)` and
`Ona2Freq(60)==440.0`, producing a divisor of 2,730. Both the formula and constant
match pinned revision `c26482bb6ad3f80106d28504ec5db3c6a360732c`. The older native
speaker-on check assumed a divisor near 2,711, so it rejected the faithful
original implementation. The check now derives the divisor from the public
original constant, retaining bounded sampling and speaker-enable/IF
checks. No sound implementation or timer constant changes.

`build/i386-speaker-register-diagnostic-v4/result.json` captures maximum count
2,730, enabled speaker bits 3, IF 512 before and after, exact 440.0 frequency bits
and note 60, with unchanged inputs. It uses TCG `486` and a file-exported register
record. Earlier v1 exceeded the input harness's command limit; v2/v3 stopped on
strict typing-screen checks before collecting the record. These are preserved
fixture failures, not additional sound results.

`build/i386-speaker-original-divisor-v2/result.json` passes the candidate sound
checks and emitted-waveform oracle: nominal 440/880 Hz tone bands and no emitted
bytes after off/reset. The source disk is unchanged. The terminal audit pins the
actual copied runner and verifies it differs from the applied repository runner
only in its explicit ROOT path. The copied checker's older input-runner hash
field refers to the repository path; the audit records the actual tested runner
hash separately. V1 was explicitly stopped after identifying a wrong ROOT in
the copied harness. This focused pass fixes the stale assertion; it does not
claim a complete broad-suite or C1–C5 pass.
