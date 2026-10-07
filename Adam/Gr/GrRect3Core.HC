#include "/Adam/Gr/GrDefaultContext.HH"
public I64 GrRect3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,I64 w,I64 h)
{//3D. Width Height. Clipping and transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  CD3I32 poly[4];
  poly[0].x=x;
  poly[0].y=y;
  poly[0].z=z;
  poly[1].x=x+w;
  poly[1].y=y;
  poly[1].z=z;
  poly[2].x=x+w;
  poly[2].y=y+h;
  poly[2].z=z;
  poly[3].x=x;
  poly[3].y=y+h;
  poly[3].z=z;
  return GrFillPoly3(dc,4,poly);
}

