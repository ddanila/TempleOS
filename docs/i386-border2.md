# Public 2D border and rectangle

The original `GrBorder` and `GrRectB` composite routines are shared with the
native runtime and exposed through the public raster interface. The border uses
the original 3D line renderer for each edge; the two-point rectangle normalizes
its coordinates and uses the original rectangle primitive.

The shared fixture checks outline and interior pixels, translated rendering
with transformation-flag restoration, a thicker border and reversed rectangle
coordinates. It returns mask 15 on the pinned original, rebuilt original and
native 64 MiB image with unchanged inputs (`build/i386-border2-reference-v1`,
`build/i386-border2-rebuilt-v1`, `build/i386-border2-native-v1`). The original
two-generation rebuild, native cross-build and 386 audit pass
(`build/i386-border2-rebuild-v1.log`, `build/i386-border2-cross-v1`). Clipping,
line patterns, error paths and all raster operations remain outside this
fixture.

Unchanged KeepAway advances past `GrBorder` and stops at `sqrt2` on line 346
(`build/i386-app-keepaway-border2-v1`, inputs unchanged). This is a load check;
gameplay and C1–C5 remain open.
