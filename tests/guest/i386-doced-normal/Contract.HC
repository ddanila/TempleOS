I64 ne_case,ne_active[4];
CDoc *ne_doc,*ne_old_display,*ne_old_border;
U0 NELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 NEObserve(CTask *caller)
{
  I64 stage=0,m,col;U8 *text,*s;Bool ready;
  while(stage<2) {
    if(caller->display_doc==ne_doc && caller->put_doc==ne_doc &&
        !Bt(&ne_doc->locked_flags,DOClf_LOCKED)) {
      text=DocScanLine(ne_doc,ne_doc->head.next,&col);
      if(!stage)ready=!StrCmp(text,"First") && col==0;
      else ready=!StrCmp(text,"ZFirst") && col==1;
      Free(text);
      if(ready) {
        m=1;
        s=MStrPrint("NORMAL EDIT FOCUS %d %d %d\n",ne_case,stage,caller==sys_focus_task);NELog(s);Free(s);
        if(caller->border_doc && caller->border_doc!=ne_old_border &&
            caller->border_doc->flags&DOCF_BORDER_DOC)m|=2;
        if(caller->title_src==TTS_ED_FILENAME && !StrCmp(caller->task_title,"NormalEdit.DD"))m|=4;
        if(ne_doc->parent_doc==ne_old_display && ne_doc->win_task==caller)m|=8;
        if(caller->text_attr==DOC_ATTR_DFT_TEXT)m|=16;
        if(caller->win_left==1 && caller->win_right==78 && caller->win_top==2 && caller->win_bottom==58)m|=32;
        if(!Bt(&ne_doc->locked_flags,DOClf_LOCKED))m|=64;
        ne_active[ne_case*2+stage]=m;
        s=MStrPrint("NORMAL EDIT READY %d %d\n",ne_case,stage);NELog(s);Free(s);stage++;
      }
    }
    Yield;
  }
}
U0 NECheck(I64 editor_flags=0)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *observer,*old_focus=sys_focus_task;I64 old_inhibit=Fs->win_inhibit,old_display_flags=Fs->display_flags;I64 result[2],size,attr=Fs->text_attr,src=Fs->title_src;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  U8 *title=StrNew(Fs->task_title),*text,*s;Bool accepted,bordered=!Bt(&Fs->display_flags,DISPLAYf_NO_BORDER);
  Bool old_ac=AutoComplete(FALSE);
  MemSet(ne_active,0,sizeof(ne_active));
  WinBorder(TRUE);WinHorz(1,78);WinVert(2,58);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;
  LBts(&Fs->display_flags,DISPLAYf_SHOW);LBts(&Fs->display_flags,DISPLAYf_CHILDREN_NOT_ON_TOP);
  WinFocus(Fs);
  for(ne_case=0;ne_case<2;ne_case++) {
    ne_doc=DocNew("NormalEdit.DD");DocPrint(ne_doc,"First\nSecond\n");DocTop(ne_doc);
    ne_old_display=display;ne_old_border=border;
    observer=Spawn(&NEObserve,Fs,"Editor observer",-1,Fs,16384);
    accepted=DocEd(ne_doc,editor_flags);
    while(TaskValidate(observer))Yield;
    result[ne_case]=0;
    if(accepted==(ne_case==0))result[ne_case]|=1;
    if(DocPut==put && DocDisplay==display && DocBorder==border)result[ne_case]|=2;
    if(Fs->text_attr==attr && Fs->title_src==src && !StrCmp(Fs->task_title,title))result[ne_case]|=4;
    if(!Bt(&ne_doc->locked_flags,DOClf_LOCKED))result[ne_case]|=8;
    if(Fs->win_left==1 && Fs->win_right==78 && Fs->win_top==2 && Fs->win_bottom==58)result[ne_case]|=16;
    if(ne_doc->win_task==Fs && ne_doc->parent_doc==display)result[ne_case]|=32;
    text=DocSave(ne_doc,&size);
    if(size==15 && text[0]=='Z' && text[1]==CH_CURSOR && !MemCmp(text+2,"First\nSecond\n",13))result[ne_case]|=64;
    s=MStrPrint("EXPORT normal-edit-%d.bin %X %X\n",ne_case,text,size);NELog(s);Free(s);
    s=MStrPrint("NORMAL EDIT RETURN %d\n",ne_case);NELog(s);Free(s);Sleep(1000);
    Free(text);DocDel(ne_doc);
  }
  s=MStrPrint("EXPORT normal-active.bin %X %X\n",ne_active,sizeof(ne_active));NELog(s);Free(s);
  s=MStrPrint("EXPORT normal-return.bin %X %X\n",result,sizeof(result));NELog(s);Free(s);
  WinBorder(bordered);WinHorz(left,right);WinVert(top,bottom);Free(title);
  Fs->win_inhibit=old_inhibit;Fs->display_flags=old_display_flags;
  if(TaskValidate(old_focus))WinFocus(old_focus);AutoComplete(old_ac);
  NELog("NORMAL EDIT DONE\n");Sleep(1000);
}
