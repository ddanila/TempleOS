# Public three-dimensional integer vector math

The native public graphics context exposes the original `D3I32Dist`,
`D3I32DistSqr`, `D3I32Norm` and `D3I32NormSqr` routines already compiled from
`GrMath.HC`. Their implementations and existing software floating-point
providers remain shared with the native runtime.

The shared fixture checks zero vectors, a 3-4-12 vector, distance symmetry,
negative coordinates, and the larger light-source vector used by KeepAway. It
returns mask 127 on the pinned original, rebuilt original and native 64 MiB
image with unchanged inputs (`build/i386-d3norm-reference-v2`,
`build/i386-d3norm-rebuilt-v1`, `build/i386-d3norm-native-v1`). The initial
original fixture timed out because its whole-structure assignment was rejected
by the original compiler (`build/i386-d3norm-reference-v1`); field-by-field
initialization fixed the fixture. The original two-generation rebuild, native
cross-build and 386 audit pass (`build/i386-d3norm-rebuild-v1.log`,
`build/i386-d3norm-cross-v1`). Integer overflow and all possible floating-point
rounding cases are outside these checks.

Unchanged KeepAway advances past `D3I32Norm` and stops at the `GrBorder` call
on line 299 (`build/i386-app-keepaway-d3norm-v1`, inputs unchanged). This is a
load check; gameplay and C1–C5 remain open.
