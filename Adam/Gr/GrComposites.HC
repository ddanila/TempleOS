#help_index "Graphics"
#include "/Adam/Gr/GrFillPolyCore.HC"

public I64 GrRectB(CDC *dc=gr.dc,I64 x1,I64 y1,I64 x2,I64 y2)
{//2D. Two point. Clipping but not transformation.
  if (x2<x1) SwapI64(&x1,&x2);
  if (y2<y1) SwapI64(&y1,&y2);
  return GrRect(dc,x1,y1,x2-x1+1,y2-y1+1);
}

#include "/Adam/Gr/GrRect3Core.HC"

public U0 GrBorder(CDC *dc=gr.dc,I64 x1,I64 y1,I64 x2,I64 y2,
	I64 step=1,I64 start=0)
{//2D. Transformation with thick.
//Can be used with ROPF_DITHER+WHITE<<16+BLACK for dotted rect.
  GrLine3(dc,x1,y1,0,x2,y1,0,step,start);
  GrLine3(dc,x2,y1,0,x2,y2,0,step,start);
  GrLine3(dc,x2,y2,0,x1,y2,0,step,start);
  GrLine3(dc,x1,y2,0,x1,y1,0,step,start);
}

#include "/Adam/Gr/GrArrowCore.HC"

#help_index "Graphics/Char;Char/Graphics"
#include "/Adam/Gr/GrTextCompositesCore.HC"

#help_index "Graphics/Mesh"
#include "/Adam/Gr/GrMeshCore.HC"

#help_index "Graphics/Misc;Mouse/Ptr"
public U0 DrawStdMs(CDC *dc,I64 x,I64 y)
{//This is a callback. See $LK,"::/Demo/Graphics/Grid.HC"$.
//Called by $LK,"DrawMs",A="MN:DrawMs"$() which is
  //called by $LK,"WinFinalUpdate",A="MN:WinFinalUpdate"$().
  dc->thick=1;
  dc->flags&=~(DCF_TRANSFORMATION|DCF_SYMMETRY);
  GrArrow3(dc,x+8,y+8,0,x,y,0);
}

gr.fp_draw_ms=&DrawStdMs;

public U0 DrawWaitMs(CDC *dc,I64 x,I64 y)
{//This is a callback. See $LK,"::/Demo/Graphics/Grid.HC"$.
  I64 old_pen_width=dc->thick;
  CColorROPU32 old_color=dc->color;
  dc->thick=3;
  dc->color=LTRED;
  GrCircle3(dc,x,y,0,7);
  GrLine3(dc,x-6,y+6,0,x+6,y-6,0);
  dc->color=RED;
  GrCircle(dc,x,y,7);
  GrLine(dc,x-6,y+6,x+6,y-6);
  dc->thick=old_pen_width;
  dc->color=old_color;
}

#help_index "Graphics/GR Files;Graphics/Scrn"
public Bool GRScrnCaptureRead(U8 *filename,CDC *dc=gr.dc,I64 x=0,I64 y=0)
{//GrBlot TempleOS GR File to dc,x,y.
  CDC *dc2;
  if (dc2=GRRead(filename)) {
    dc->color=ROP_EQU;
    GrBlot(dc,x,y,dc2);
    DCDel(dc2);
    return TRUE;
  }
  return FALSE;
}

public I64 GRScrnCaptureWrite(U8 *filename,Bool include_zoom=TRUE)
{//Capture scrn to a TempleOS GR File.
  I64 size;
  CDC *dc=DCScrnCapture(include_zoom);
  size=GRWrite(filename,dc,DCSF_COMPRESSED|DCSF_PALETTE_GET);
  DCDel(dc);
  return size;
}
