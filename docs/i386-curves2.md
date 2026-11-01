# Public 2D curves and flood fill

The original 2D circle, ellipse and regular-polygon wrappers are shared with the
native runtime. The public raster interface also exposes the already-shared
original flood-fill and pixel read/write routines. The wrappers keep the
original behavior of ignoring 3D transforms and temporarily removing the depth
buffer while drawing; their default context follows the existing native graphics
binding.

The shared fixture checks degenerate and zero-arc ellipses, an ellipse outline
and flood-filled interior, untransformed rendering, depth-buffer restoration,
a circle point and regular-polygon rendering. It returns mask 255 on the pinned
original, rebuilt original and native 64 MiB image with unchanged inputs
(`build/i386-curves2-reference-v3`, `build/i386-curves2-rebuilt-v2`,
`build/i386-curves2-native-v2`). An earlier fixture incorrectly expected a
zero-length polygon arc to draw a point; the original returned mask 127
(`build/i386-curves2-reference-v2`), so the final check uses a full polygon.
The original two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-curves2-rebuild-v1.log`, `build/i386-curves2-cross-v1`). These
cases do not establish every curve, clipping, color operation or error path.

Unchanged KeepAway advances past `GrEllipse` and `GrFloodFill` and next fails
on `SpriteInterpolate` at line 269 (`build/i386-app-keepaway-curves2-v1`,
inputs unchanged). This is a load check; gameplay and C1–C5 remain open.
