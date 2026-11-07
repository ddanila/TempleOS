CDoc *se_doc;
U8 *se_name;
U0 SELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool SEFile()
{
  I64 size;U8 *s=FileRead(se_name,&size);Bool okay=s && size==7 && !MemCmp(s,"Z\x05Keep\n",7);
  Free(s);return okay;
}
U0 SEObserve(CTask *caller)
{
  I64 stage=0,col;U8 *text,*s;Bool ready;
  while(stage<5) {
    ready=FALSE;
    if(caller->display_doc==se_doc && caller->put_doc==se_doc &&
        !Bt(&se_doc->locked_flags,DOClf_LOCKED)) {
      if(stage<2) {
        text=DocScanLine(se_doc,se_doc->head.next,&col);
        if(!stage)ready=!StrCmp(text,"Keep") && col==0;
        else ready=!StrCmp(text,"ZKeep") && col==1;
        Free(text);
      } else if(stage==2)ready=SEFile;
      else if(stage==3)ready=Bt(&se_doc->flags,DOCf_AUTO_SAVE);
      else ready=!Bt(&se_doc->flags,DOCf_AUTO_SAVE);
      if(ready) {
        s=MStrPrint("SAVE EDITOR READY %d\n",stage);SELog(s);Free(s);stage++;
      }
    }
    Yield;
  }
}
U0 SECheck(U8 *name)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old_focus=sys_focus_task,*observer;
  I64 inhibit=Fs->win_inhibit,flags=Fs->display_flags,size,mask=0;
  U8 *text,*s;Bool accepted;
  se_name=name;FileWrite(name,"unchanged\n",10);
  se_doc=DocNew(name);DocPrint(se_doc,"Keep\n");DocTop(se_doc);
  Fs->win_inhibit&=~WIF_SELF_FOCUS;LBts(&Fs->display_flags,DISPLAYf_SHOW);WinFocus(Fs);
  observer=Spawn(&SEObserve,Fs,"Save key observer",-1,Fs,16384);
  accepted=DocEd(se_doc,DOF_DONT_HOME);
  while(TaskValidate(observer))Yield;
  if(accepted)mask|=1;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=2;
  if(!Bt(&se_doc->locked_flags,DOClf_LOCKED))mask|=4;
  text=DocSave(se_doc,&size);
  if(size==7 && !MemCmp(text,"Z\x05Keep\n",7))mask|=8;
  if(SEFile)mask|=16;
  if(!Bt(&se_doc->flags,DOCf_AUTO_SAVE))mask|=32;
  s=MStrPrint("EXPORT save-editor-text.bin %X %X\n",text,size);SELog(s);Free(s);
  s=MStrPrint("EXPORT save-editor-mask.bin %X %X\n",&mask,sizeof(mask));SELog(s);Free(s);
  SELog("SAVE EDITOR DONE\n");Sleep(1000);
  Free(text);DocDel(se_doc);Fs->win_inhibit=inhibit;Fs->display_flags=flags;
  if(TaskValidate(old_focus))WinFocus(old_focus);
}
U0 SEReopen(U8 *name)
{
  I64 size;U8 *text=FileRead(name,&size),*s;
  s=MStrPrint("EXPORT save-editor-reopen.bin %X %X\n",text,size);SELog(s);Free(s);
  SELog("SAVE EDITOR REOPEN DONE\n");Sleep(1000);Free(text);
}
