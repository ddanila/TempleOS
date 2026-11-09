CDoc *ml_doc,*ml_old_put,*ml_old_display;
CTask *ml_owner,*ml_observer,*ml_old_focus,*ml_first_child,*ml_last_child;
I64 ml_flags,ml_inhibit,ml_attr,ml_left,ml_right,ml_top,ml_bottom,ml_before;
I64 ml_count,ml_mask,ml_return_inhibit,ml_final_size,ml_heaps[3];
U8 *ml_final,ml_stream[4096];
I64 ml_stream_size;
Bool ml_done,ml_ac,ml_border;
U0 MLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool MLCapture(CDoc *,U8 *,U8 *text)
{//Observe the original output stream, then allow normal document insertion.
  while(*text) {
    if(ml_stream_size>=sizeof(ml_stream)-1)throw('MLStream',TRUE);
    ml_stream[ml_stream_size++]=*text++;
  }
  ml_stream[ml_stream_size]=0;
  return FALSE;
}
U0 MLObserve(U8 *)
{
  U8 *p,*s;I64 count,last=-1;Bool ready=FALSE,unlock;
  CDocEntry *e;
  LBtr(&Fs->display_flags,DISPLAYf_SHOW);
  while(!ml_done) {
    count=0;unlock=DocLock(ml_doc);
    for(e=ml_doc->head.next;e!=ml_doc;e=e->next) {
      if(e->type_u8==DOCT_TEXT&&e->tag) {
        if(!ready&&StrMatch("<ESC> to Exit",e->tag)){ready=TRUE;MLLog("ML READY\n");}
        p=e->tag;
        while(p=StrMatch("CMD:",p)){count++;p+=4;}
      }
    }
    if(unlock)DocUnlock(ml_doc);
    if(count!=last){last=ml_count=count;s=MStrPrint("ML COUNT %d\n",count);MLLog(s);Free(s);}
    Sleep(10);
  }
}
U0 MLStart()
{
  ml_owner=Fs;ml_old_put=DocPut;ml_old_display=DocDisplay;ml_old_focus=sys_focus_task;
  ml_before=Fs->data_heap->used_u8s;ml_heaps[0]=ml_before;ml_first_child=Fs->next_child_task;ml_last_child=Fs->last_child_task;ml_flags=Fs->display_flags;ml_inhibit=Fs->win_inhibit;
  ml_attr=Fs->text_attr;ml_left=Fs->win_left;ml_right=Fs->win_right;ml_top=Fs->win_top;ml_bottom=Fs->win_bottom;
  ml_border=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER);ml_ac=AutoComplete(FALSE);
  ml_done=FALSE;ml_mask=ml_count=ml_stream_size=0;ml_stream[0]=0;
  WinBorder(FALSE);WinHorz(0,79);WinVert(0,59);LBts(&Fs->display_flags,DISPLAYf_SHOW);
  LBts(&Fs->display_flags,DISPLAYf_NOT_RAW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;Fs->text_attr=(WHITE<<4)|BLUE;
  ml_doc=DocNew("MsgLoopWorkflow.DD");ml_doc->flags|=DOCF_HIDE_CURSOR|DOCF_NO_SCROLL_BARS;ml_doc->user_put_s=&MLCapture;
  Fs->put_doc=Fs->display_doc=ml_doc;WinFocus(Fs);Sleep(250);FlushMsgs;
  ml_observer=Spawn(&MLObserve,NULL,"MsgLoop observer",-1,Fs,16384);
}
U0 MLFinish()
{
  I64 ch=0,deadline=cnts.jiffies+20000;U8 *s;
  ml_return_inhibit=Fs->win_inhibit;ml_done=TRUE;
  while((Fs->next_child_task!=ml_first_child||Fs->last_child_task!=ml_last_child)&&cnts.jiffies<deadline)Yield;
  if(Fs->next_child_task!=ml_first_child||Fs->last_child_task!=ml_last_child)throw('MLWatch',TRUE);
  s=MStrPrint("EXPORT msg-loop-stream.bin %X %X\n",ml_stream,ml_stream_size+1);MLLog(s);Free(s);
  ml_final=DocSave(ml_doc,&ml_final_size);ml_heaps[1]=Fs->data_heap->used_u8s;
  s=MStrPrint("EXPORT msg-loop.DD %X %X\n",ml_final,ml_final_size);MLLog(s);Free(s);
  s=MStrPrint("EXPORT msg-loop-return.bin %X 8\n",&ml_return_inhibit);MLLog(s);Free(s);MLLog("ML CAPTURE\n");
  while(ch!='q'&&cnts.jiffies<deadline){ScanKey(&ch);Sleep(10);}
  if(ch!='q')throw('MLWait',TRUE);
  Free(ml_final);Fs->put_doc=ml_old_put;Fs->display_doc=ml_old_display;DocDel(ml_doc);
  Fs->win_inhibit=ml_inhibit;Fs->text_attr=ml_attr;
  WinBorder(ml_border);WinHorz(ml_left,ml_right);WinVert(ml_top,ml_bottom);Fs->display_flags=ml_flags;
  if(TaskValidate(ml_old_focus))WinFocus(ml_old_focus);Sleep(100);FlushMsgs;
  if(Fs->put_doc==ml_old_put&&Fs->display_doc==ml_old_display&&Fs->win_inhibit==ml_inhibit&&Fs->text_attr==ml_attr)ml_mask|=1;
  ml_heaps[2]=Fs->data_heap->used_u8s;if(ml_heaps[2]==ml_before)ml_mask|=2;
  if(ml_return_inhibit==WIG_USER_TASK_DFT)ml_mask|=4;
  AutoComplete(ml_ac);
  s=MStrPrint("EXPORT msg-loop-heaps.bin %X 18\n",ml_heaps);MLLog(s);Free(s);
  s=MStrPrint("EXPORT msg-loop-mask.bin %X 8\n",&ml_mask);MLLog(s);Free(s);MLLog("ML DONE\n");
}
