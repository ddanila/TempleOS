U0 ZLog(U8 *s)
{
  while(*s)OutU8(0xE9,*s++);
}

U0 ZReport(CTask *owner,I64 phase)
{
  I64 i;
  U8 *digits="0123456789abcdef";
  U8 *header=MStrPrint("Z MAP %d %d %d\n",phase,owner->pix_left,owner->pix_top);
  ZLog(header);
  Free(header);
  for(i=0;i<TEXT_ROWS*TEXT_COLS;i++)
    OutU8(0xE9,digits[gr.win_z_buf[i]&15]);
  ZLog("\nZ MAP END\n");
}

U0 ZWatch(CTask *owner)
{
  while(!owner->draw_it)Sleep(20);
  Sleep(500);
  ZReport(owner,0);
  Sleep(3500);
  WinHorz(20,58,owner);
  WinVert(12,43,owner);
  Refresh(2,TRUE);
  Sleep(500);
  ZReport(owner,1);
}

U0 ZSetup()
{
  WinHorz(5,43);
  WinVert(6,37);
  WinToTop;
  Refresh(2,TRUE);
}

ZLog("Z READY\n");
