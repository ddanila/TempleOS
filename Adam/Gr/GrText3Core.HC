#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original graphics text operations, with corrected left glyph alignment.
public Bool GrPutChar3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 ch)
{//3D. Transformation. DCF_SYMMETRY is silly.
  GRAPHICS_RESOLVE_DEFAULT_DC
  if (dc->flags & DCF_TRANSFORMATION)
    (*dc->transform)(dc,&x,&y,&z);
  return GrPutChar(dc,x,y,ch);
}

public I64 GrPrint3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *fmt,...)
{//3D. Transformation. DCF_SYMMETRY is silly.
  GRAPHICS_RESOLVE_DEFAULT_DC
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  I64 res;
  if (dc->flags & DCF_TRANSFORMATION)
    (*dc->transform)(dc,&x,&y,&z);
  res=GrPrint(dc,x,y,"%s",buf);
  Free(buf);
  return res;
}

public I64 GrVPrint3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *fmt,...)
{//3D. Vertical text. Transformation. DCF_SYMMETRY is silly.
  GRAPHICS_RESOLVE_DEFAULT_DC
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  I64 res;
  if (dc->flags & DCF_TRANSFORMATION)
    (*dc->transform)(dc,&x,&y,&z);
  res=GrVPrint(dc,x,y,"%s",buf);
  Free(buf);
  return res;
}

