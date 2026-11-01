#include "/Adam/Gr/GrDefaultContext.HH"
public I64 GrRectB(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 x2,I64 y2)
{//2D. Two point. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  if (x2<x1) SwapI64(&x1,&x2);
  if (y2<y1) SwapI64(&y1,&y2);
  return GrRect(dc,x1,y1,x2-x1+1,y2-y1+1);
}

public U0 GrBorder(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 x2,I64 y2,
	I64 step=1,I64 start=0)
{//2D. Transformation with thick.
  GRAPHICS_RESOLVE_DEFAULT_DC
//Can be used with ROPF_DITHER+WHITE<<16+BLACK for dotted rect.
  GrLine3(dc,x1,y1,0,x2,y1,0,step,start);
  GrLine3(dc,x2,y1,0,x2,y2,0,step,start);
  GrLine3(dc,x2,y2,0,x1,y2,0,step,start);
  GrLine3(dc,x1,y2,0,x1,y1,0,step,start);
}
