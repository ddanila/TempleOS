# Elapsed-seconds clock

The native console now publishes its existing `tS` function. It converts the
native scheduler's PIT-derived jiffies to floating-point seconds; the original
uses HPET where available and otherwise its system timer. The native clock's
resolution therefore follows the scheduler tick rather than the original HPET.

The pinned original and native fixtures pass mask 3 with unchanged inputs
(`build/i386-public-ts-original-v1`, `build/i386-public-ts-native-v1`; runner
`tools/test-i386-public-ts.py`). They check nonnegative elapsed time and two
increases across sleeps, not clock precision, drift, wrap, or isolated startup
speed. The previous native image rejected the missing binding
(`build/i386-public-ts-native-red`). Both bootstrap generations and the 386
cross-build/audit pass (`build/public-ts-rebuild-v1.log`,
`build/i386-public-ts-cross-v1`). C1–C5 remain open.
The 8 MiB ordinary-include and drive-fields smoke test also passes with
unchanged inputs (`build/i386-public-ts-smoke-8m`); it is not a startup-timing
or full minimal-profile gate.
