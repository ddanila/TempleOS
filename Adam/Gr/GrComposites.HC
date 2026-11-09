#help_index "Graphics"
#include "/Adam/Gr/GrFillPolyCore.HC"

#include "/Adam/Gr/GrBorder2Core.HC"

#include "/Adam/Gr/GrRect3Core.HC"

#include "/Adam/Gr/GrArrowCore.HC"

#help_index "Graphics/Char;Char/Graphics"
#include "/Adam/Gr/GrTextCompositesCore.HC"

#help_index "Graphics/Mesh"
#include "/Adam/Gr/GrMeshCore.HC"

#help_index "Graphics/Misc;Mouse/Ptr"
#include "/Adam/Gr/DrawStdMouseCore.HC"

gr.fp_draw_ms=&DrawStdMs;

#include "/Adam/Gr/DrawWaitMouseCore.HC"

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
