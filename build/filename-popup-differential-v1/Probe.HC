U0 FNLog(U8 *s)
{
  while(*s) OutU8(0xE9,*s++);
}
U0 FNProbe()
{
  CTask *prior_popup=Fs->popup_task;
  U8 *name,*line;
  FNLog("FILENAME accept\n");
  name=PopUpFileName("C:/Default.DATA");
  if(!name || StrCmp(name,"C:/Default.DATA") || Fs->popup_task!=prior_popup)
    FNLog("FAIL filename default or popup state\n");
  if(name) {
    line=MStrPrint("FILENAME returned %s\n",name);
    FNLog(line);
    Free(line);
    Free(name);
  }
  FNLog("FILENAME cancel\n");
  name=PopUpFileName("C:/Cancel.DATA");
  if(name || Fs->popup_task!=prior_popup)
    FNLog("FAIL filename cancellation or popup state\n");
  Free(name);
  FNLog("FILENAME done\n");
}
