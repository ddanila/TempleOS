U0 TSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 ts_values[9];
U0 TSProbe(Bool initialize=FALSE)
{
  CCtrl *h=CtrlFindUnique(Fs,CTRLT_WIN_HSCROLL),*v=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL),*c;
  CDoc *old_put=DocPut,*old_display=DocDisplay,*doc;
  I64 base=Fs->data_heap->used_u8s,flags=Fs->display_flags,inhibit=Fs->win_inhibit,ch=0,i;
  CWinScroll hs,vs;
  U8 *s;
  MemCpy(&hs,&Fs->horz_scroll,sizeof(CWinScroll));MemCpy(&vs,&Fs->vert_scroll,sizeof(CWinScroll));
  ts_values[0]=h!=NULL;ts_values[1]=v!=NULL;
  if(initialize)WinScrollsInit(Fs);
  c=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL);
  ts_values[2]=c && c->win_task==Fs && c->state==&Fs->vert_scroll && c->wheel_chg!=NULL;
  doc=DocNew("TerminalScrollProbe.DD");doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;
  Fs->put_doc=Fs->display_doc=doc;LBts(&Fs->display_flags,DISPLAYf_SHOW);LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);
  Fs->win_inhibit=WIG_USER_TASK_DFT;Fs->horz_scroll.flags=Fs->vert_scroll.flags=0;
  DocPrint(doc,"one\ntwo\nthree\n");WinFocus(Fs);Sleep(250);FlushMsgs;
  TSLog("TERMINAL SCROLL READY\n");
  for(i=0;i<2000 && ch!='q';i++){ScanKey(&ch);Sleep(10);}
  if(ch!='q')throw('TSWait',TRUE);
  ts_values[3]=Bt(&Fs->vert_scroll.flags,WSSf_SET_TO_POS);
  ts_values[4]=doc->x;ts_values[5]=doc->y;
  ts_values[6]=doc->cur_col;
  Fs->put_doc=old_put;Fs->display_doc=old_display;DocDel(doc);
  if(initialize) {
    if(!h){c=CtrlFindUnique(Fs,CTRLT_WIN_HSCROLL);if(c){QueRem(c);Free(c);}}
    if(!v){c=CtrlFindUnique(Fs,CTRLT_WIN_VSCROLL);if(c){QueRem(c);Free(c);}}
  }
  MemCpy(&Fs->horz_scroll,&hs,sizeof(CWinScroll));MemCpy(&Fs->vert_scroll,&vs,sizeof(CWinScroll));Fs->display_flags=flags;Fs->win_inhibit=inhibit;
  ts_values[7]=Fs->data_heap->used_u8s==base;
  ts_values[8]=Fs->put_doc==old_put && Fs->display_doc==old_display;
  s=MStrPrint("EXPORT terminal-scroll.bin %X %X\n",ts_values,sizeof(ts_values));TSLog(s);Free(s);TSLog("TERMINAL SCROLL DONE\n");
}
