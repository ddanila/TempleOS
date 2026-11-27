U0 PalLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
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
PalLog("DOODLE READY\n");
