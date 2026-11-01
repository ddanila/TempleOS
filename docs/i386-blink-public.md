# Public Blink

The native public date and time interface exposes `Blink`, whose original
body is shared through `Kernel/BlinkCore.HC`. Native calls use the existing
jiffy counter through `NativeJiffies`; no synthetic clock or fixed phase is
introduced.

The live-clock fixture checks zero frequency, transitions at 10 and 5 Hz, and
agreement between the default and explicit 2.5 Hz calls across both phases. It
returns mask 15 on the pinned original, rebuilt original and native 64 MiB
image with unchanged inputs (`build/i386-blink-public-reference-v2`,
`build/i386-blink-public-rebuilt-v1`, `build/i386-blink-public-native-v1`).
The original two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-blink-public-rebuild-v1.log`, `build/i386-blink-public-cross-v1`).
The earlier `build/blink-shared-original-v1` fixture separately checks selected
deterministic jiffy values. These checks do not establish precise real-time
frequency or all scheduler and display combinations.

An initial live-clock fixture assumed `tS` and the Blink jiffy counter shared
an epoch; the original returned mask 11 (`build/i386-blink-public-reference-v1`).
The final fixture compares default and explicit Blink calls without that
assumption. Unchanged KeepAway advances past `Blink` and stops at `Beep` on
line 428 (`build/i386-app-keepaway-blink-v1`, inputs unchanged). This is a load
check; gameplay and C1–C5 remain open.
