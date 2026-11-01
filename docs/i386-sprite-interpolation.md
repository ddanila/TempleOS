# Sprite interpolation and transformed drawing

The original sprite interpolation and translated/rotated sprite drawing
routines are shared with the native runtime and exposed through the public
raster interface. The interpolation routine allocates a new sprite, chooses
noninterpolated fields from the appropriate input, and interpolates supported
record coordinates with the original algorithm. The transformed drawing
wrappers retain the original graphics-context matrix, position and flag restoration behavior.

The shared fixture checks point-record interpolation at the endpoints, quarter
and midpoint, selection of noninterpolated color, line and circle coordinates
(including a negative coordinate), sprite size, and a zero-angle Y rotation
against translated drawing with matrix and flag restoration. It returns mask
255 on the pinned original, rebuilt original and native 64 MiB image with
unchanged inputs (`build/i386-interpolation-reference-v2`,
`build/i386-interpolation-rebuilt-v2`, `build/i386-interpolation-native-v2`). The original two-generation rebuild,
native cross-build and 386 audit pass (`build/i386-interpolation-rebuild-v1.log`,
`build/i386-interpolation-cross-v1`). The fixture does not establish every
sprite record type, nonzero rotation, mismatched input, allocation failure or
complete rendering behavior.

Unchanged KeepAway advances past `SpriteInterpolate` and `Sprite3YB` and stops
at `D3I32Norm` on line 292 (`build/i386-app-keepaway-interpolation-v1`, inputs
unchanged). This is a load check; gameplay and C1–C5 remain open.
