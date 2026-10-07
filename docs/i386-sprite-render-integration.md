# Original Sprite3 integration

The complete renderer is shared in Adam/Gr/SpriteRenderCore.HC. Original
and shared reference runs pass six basic pixel/state checks. Complex
primitive rendering, transformed drawing, clipping, symmetry, depth,
bitmap/spline/mesh behavior and exceptional cleanup still need tests.

ConsoleRuntime now includes the original GrMath.HC and renderer before
DocRecalcCore. This is a pending integration: no successful native build or
runtime rendering is claimed. Keep every original renderer branch; integrate
the actual primitive implementations and their dependencies.

| Required operation | Original implementation location |
| --- | --- |
| `DCThickScale` | Adam/Gr/GrMath.HC:90 |
| `GrPlot3` | Adam/Gr/GrPrimatives.HC:441 |
| `GrPrint3` | Adam/Gr/GrPrimatives.HC:828 |
| `GrTextBox3` | Adam/Gr/GrComposites.HC:152 |
| `GrTextDiamond3` | Adam/Gr/GrComposites.HC:183 |
| `GrFloodFill3` | Adam/Gr/GrPrimatives.HC:972 |
| `GrLine3` | Adam/Gr/GrPrimatives.HC:770 |
| `GrArrow3` | Adam/Gr/GrComposites.HC:103 |
| `DCSymmetry3Set` | Adam/Gr/GrMath.HC:143 |
| `GrBlot3` | Adam/Gr/GrPrimatives.HC:1000 |
| `GrRect3` | Adam/Gr/GrComposites.HC:75 |
| `GrCircle3` | Adam/Gr/GrPrimatives.HC:906 |
| `GrEllipse3` | Adam/Gr/GrPrimatives.HC:852 |
| `GrRegPoly3` | Adam/Gr/GrPrimatives.HC:917 |
| `Gr2BSpline3` | Adam/Gr/GrPrimatives.HC:1307 |
| `Gr3BSpline3` | Adam/Gr/GrPrimatives.HC:1352 |
| `Gr3Mesh` | Adam/Gr/GrComposites.HC:249 |
| `Mat4x4TranslationEqu` | Adam/Gr/GrMath.HC:103 |
