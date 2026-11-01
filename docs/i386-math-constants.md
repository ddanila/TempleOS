# Public mathematical constants

The original binary64 definitions for `pi`, `exp_1`, `log2_10`, `log2_e`,
`log10_2`, `loge_2`, `sqrt2` and `eps` are shared through
`Kernel/MathConstants.HH`. The native public math header includes the same
constant definitions used by the original kernel.

The fixture compares each named value to its original binary64 literal and
checks arithmetic use of `sqrt2`. It returns mask 255 on the pinned original,
rebuilt original and native 64 MiB image with unchanged inputs
(`build/i386-math-constants-reference-v2`,
`build/i386-math-constants-rebuilt-v1`, `build/i386-math-constants-native-v1`).
The original two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-math-constants-rebuild-v1.log`,
`build/i386-math-constants-cross-v1`). The first fixture attempt was interrupted
and corrected after an overlong exception tag prevented completion
(`build/i386-math-constants-reference-v1`).

Unchanged KeepAway advances past `sqrt2` and stops at `Blink` on line 381
(`build/i386-app-keepaway-constants-v1`, inputs unchanged). This is a load
check; gameplay and C1–C5 remain open.
