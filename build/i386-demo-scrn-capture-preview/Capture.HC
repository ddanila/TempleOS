Bool GRScrnCaptureRead(U8 *filename,CDC *dc=gr.dc,I64 x=0,I64 y=0)
{
  CDC *saved=GRRead(filename);
  if(!saved)return FALSE;
  dc->color=ROP_EQU;
  GrBlot(dc,x,y,saved);
  DCDel(saved);
  return TRUE;
}
I64 GRScrnCaptureWrite(U8 *filename,Bool include_zoom=TRUE)
{
  CDC *saved;
  I64 size;
  if(!include_zoom || !NativeGraphicsPresent)return 0;
  saved=DCCopy(gr.dc2);
  if(!saved)return 0;
  size=GRWrite(filename,saved,DCSF_COMPRESSED|DCSF_PALETTE_GET);
  DCDel(saved);
  return size;
}
U0 CaptureTrace(U8 *p){while(*p)OutU8(0xE9,*p++);}
U0 CaptureVerify()
{
  CDC *saved=GRRead("~/DemoScrnShot");
  if(!saved || saved->width!=640 || saved->height!=480 ||
      saved->width_internal!=640)throw('Capture',TRUE);
  U8 *line=MStrPrint("EXPORT saved-scrn.raw %X %X\n",saved->body,640*480);
  CaptureTrace(line);
  Sleep(1000);
  Free(line);DCDel(saved);
}
