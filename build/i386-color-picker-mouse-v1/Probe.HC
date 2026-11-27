U0 PalLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PalValue(U8 *label,I64 value)
{
  U8 *line=MStrPrint("COLOR %s %d\n",label,value);
  PalLog(line);Free(line);
}
U0 PalWatch(I64 unused)
{
  I64 x=-1,y=-1;
  U8 *line;
  while(TRUE) {
    if(x!=ms.pos.x || y!=ms.pos.y) {
      x=ms.pos.x;y=ms.pos.y;
      line=MStrPrint("COLOR PTR %d %d\n",x,y);
      PalLog(line);Free(line);
    }
    Sleep(20);
  }
}
U0 PalProbe()
{
  CTask *watch=Spawn(&PalWatch,NULL,"Color pointer",,Fs);
  PalLog("COLOR BASIC BEGIN\n");
  PalValue("BASIC",PopUpColor("Choose a basic color\n\n",FALSE,FALSE));
  PalLog("COLOR TRANSPARENT BEGIN\n");
  PalValue("TRANSPARENT",PopUpColor("Choose transparency\n\n",TRUE,FALSE));
  PalLog("COLOR DEFAULT BEGIN\n");
  PalValue("DEFAULT",PopUpColor("Choose default\n\n",FALSE,TRUE));
  PalLog("COLOR CANCEL BEGIN\n");
  PalValue("CANCEL",PopUpColor("Cancel the picker\n\n"));
  Kill(watch);
  PalLog("COLOR DONE\n");
}
PalLog("COLOR READY\n");
