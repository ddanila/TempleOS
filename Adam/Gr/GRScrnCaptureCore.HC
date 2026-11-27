#include "/Adam/Gr/GrDefaultContext.HH"
#help_index "Graphics/GR Files;Graphics/Scrn"
public Bool GRScrnCaptureRead(U8 *filename,CDC *dc=GRAPHICS_DEFAULT_DC,I64 x=0,I64 y=0)
{//GrBlot TempleOS GR File to dc,x,y.
  CDC *dc2;
  GRAPHICS_RESOLVE_DEFAULT_DC
  if (dc2=GRRead(filename)) {
    dc->color=ROP_EQU;
    try { GrBlot(dc,x,y,dc2); }
    catch { DCDel(dc2); }
    DCDel(dc2);
    return TRUE;
  }
  return FALSE;
}

public I64 GRScrnCaptureWrite(U8 *filename,Bool include_zoom=TRUE)
{//Capture scrn to a TempleOS GR File.
  I64 size;
  CDC *dc=DCScrnCapture(include_zoom);
  if(!dc)return 0;
  try { size=GRWrite(filename,dc,DCSF_COMPRESSED|DCSF_PALETTE_GET); }
  catch { DCDel(dc); }
  DCDel(dc);
  return size;
}
