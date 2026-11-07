CTask *wbc_target;
Bool wbc_done;
U32 *wbc_cells,*wbc_saved;
I64 wbc_rows[2];
U0 WBCIdle(U8 *data){while(TRUE)Yield;}
U0 WBCDraw(CDC *dc)
{
  I64 x,y,v,n=0;
  no_warn dc;
  if(wbc_done)return;
  MemCpy(wbc_saved,gr.text_base,19200);
  MemSetU32(gr.text_base,0x0720,4800);
  GrUpdateTaskWin(wbc_target);
  MemCpy(wbc_cells,gr.text_base,19200);
  for(y=0;y<60;y++)for(x=0;x<80;x++) {
    v=0x0720;
    if(10<=x<=20 && 15<=y<=25)v=0xF100;
    if(10<=x<=20 && (y==14 || y==26))v=0x0100+text.border_chars[2];
    if((x==9 || x==21) && 15<=y<=25)v=0x0100+text.border_chars[4];
    if(x==9 && y==14)v=0x0100+text.border_chars[6];
    if(x==21 && y==14)v=0x0100+text.border_chars[8];
    if(x==9 && y==26)v=0x0100+text.border_chars[10];
    if(x==21 && y==26)v=0x0100+text.border_chars[12];
    if(wbc_cells[y*80+x]==v)n++;
  }
  wbc_rows[0]=n;wbc_rows[1]=Fs==sys_winmgr_task;
  MemCpy(gr.text_base,wbc_saved,19200);
  wbc_done=TRUE;
}
U0 WBCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 WBCContract()
{
  I64 l=Fs->win_left,r=Fs->win_right,t=Fs->win_top,b=Fs->win_bottom;
  U0 (*old_final)(CDC *dc);
  U8 *s;
  old_final=gr.fp_final_scrn_update;
  wbc_done=FALSE;wbc_cells=MAlloc(19200);wbc_saved=MAlloc(19200);
  wbc_target=Spawn(&WBCIdle,NULL,"Border target",-1,Fs);
  WinHorz(10,20,wbc_target);WinVert(15,25,wbc_target);
  wbc_target->text_attr=0xF1;wbc_target->border_attr=1;
  Btr(&wbc_target->display_flags,DISPLAYf_NO_BORDER);
  WinHorz(3,52);WinVert(4,29);
#ifdef WBC_NATIVE
  if(!NativeGraphicsPresent(&WBCDraw,FALSE))throw('Frame',TRUE);
#else
  gr.fp_final_scrn_update=&WBCDraw;
  while(!wbc_done)Yield;
  gr.fp_final_scrn_update=old_final;
#endif
  WinHorz(l,r);WinVert(t,b);Kill(wbc_target);
  s=MStrPrint("EXPORT border-cells.bin %X %X\n",wbc_cells,19200);WBCLog(s);Free(s);
  s=MStrPrint("EXPORT border-rows.bin %X %X\n",wbc_rows,sizeof(wbc_rows));WBCLog(s);Free(s);
  WBCLog("WINDOW BORDER DONE\n");Sleep(1000);
  Free(wbc_cells);Free(wbc_saved);
}
