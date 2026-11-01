# Public Min, Max and Clamp

The native public math interface exposes the original `Min`, `Max` and `Clamp`
function bodies. `Max` was already compiled into the console for internal use;
`Min` and `Clamp` are now shared from the original kernel math source.

The shared comparison fixture checks finite values in both argument orders,
integer-to-F64 arguments, values below, inside and above the clamp range, and
reversed bounds. It returns mask 127 on the pinned original, rebuilt original
and native 64 MiB image with unchanged inputs
(`build/i386-minmax-reference-v3`, `build/i386-minmax-rebuilt-final`,
`build/i386-minmax-native-final`). It does not establish NaN, infinity, signed-zero
or all rounding behavior. The original rebuild, native cross-build and 386 audit
pass (`build/i386-minmax-rebuild-final.log`, `build/i386-minmax-cross-final`).

Unchanged KeepAway advances past its `Max` error at line 257 and stops at an
undefined identifier on line 263, the `GrEllipse` call
(`build/i386-app-keepaway-minmax-v1`). This is a load test, not a gameplay test;
C1–C5 remain incomplete.
