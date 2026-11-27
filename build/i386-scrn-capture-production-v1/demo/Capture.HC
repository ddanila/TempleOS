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
