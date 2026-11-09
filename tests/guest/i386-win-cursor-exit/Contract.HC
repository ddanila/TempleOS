CTask *cw_parent,*cw_worker;
CDoc *cw_doc;
Bool cw_start,cw_entered,cw_returned;
I64 cw_mask,cw_api_mask;
U8 *CWExitTag(CDoc *,CDocEntry *,CTask *mem_task)
{
  if(Fs==cw_worker){cw_entered=TRUE;Exit;}
  return StrNew("Cursor",mem_task);
}
U0 CWWorker(U8 *)
{
  cw_worker=Fs;while(!cw_start)Yield;
  WinCursorPosSet(cw_parent,cw_parent->pix_left+12,cw_parent->pix_top+4);
  cw_returned=TRUE;
}
U0 WinCursorExitContract()
{
  CDoc *put=Fs->put_doc,*display=Fs->display_doc;
  CTask *first=Fs->next_child_task,*last=Fs->last_child_task;
  CDocEntry *e;I64 before,deadline,size;U8 *text,*line,*p;
  Bool paused=Bt(&sys_winmgr_task->task_flags,TASKf_SUSPENDED),okay;
  cw_parent=Fs;cw_start=cw_entered=cw_returned=FALSE;cw_mask=0;
  if(!paused) {
    while(Bt(&sys_semas[SEMA_REFRESH_IN_PROGRESS],0))Yield;
    Suspend(sys_winmgr_task,TRUE);
  }
  before=Fs->data_heap->used_u8s;
  cw_doc=DocNew("CursorExit.DD");cw_doc->flags|=DOCF_NO_SCROLL_BARS;
  e=CAlloc(sizeof(CDocEntry));e->type=DOCT_TEXT|0xF000;
  e->de_flags=DOCEF_TAG|DOCEF_TAG_CB;e->tag=StrNew("Cursor");e->tag_cb=&CWExitTag;
  DocInsEntry(cw_doc,e);Fs->put_doc=Fs->display_doc=cw_doc;
  cw_worker=Spawn(&CWWorker,NULL,"Cursor callback worker",-1,Fs,16384);cw_start=TRUE;
  deadline=cnts.jiffies+10000;
  while((TaskValidate(cw_worker) || Fs->next_child_task!=first || Fs->last_child_task!=last) && cnts.jiffies<deadline)Yield;
  if(cw_entered && !cw_returned)cw_mask|=1;
  if(!TaskValidate(cw_worker) && Fs->next_child_task==first && Fs->last_child_task==last)cw_mask|=2;
  okay=!Bt(&cw_doc->locked_flags,DOClf_LOCKED);
  if(okay)cw_mask|=4;
  if(cw_doc->doc_signature==DOC_SIGNATURE_VAL && cw_doc->win_task==Fs && e->next==cw_doc && e->last==cw_doc)cw_mask|=8;
  if(okay) {
    e->de_flags&=~DOCEF_TAG_CB;e->tag_cb=NULL;
    if(DocLock(cw_doc)){cw_mask|=16;DocUnlock(cw_doc);}
    DocPrint(cw_doc,"After\n");text=DocSave(cw_doc,&size);
    if(StrFind("After",text))cw_mask|=32;Free(text);
  }
  Fs->put_doc=put;Fs->display_doc=display;
  if(Fs->put_doc==put && Fs->display_doc==display)cw_mask|=64;
  if(okay){DocDel(cw_doc);if(Fs->data_heap->used_u8s==before)cw_mask|=128;}
  cw_api_mask=0;
  try {if(!WinCursorPosSet(cw_worker,0,0))cw_api_mask|=1;}
  catch {Fs->catch_except=TRUE;}
  if(!WinCursorPosSet(Fs,-1,-1))cw_api_mask|=2;
  okay=LBtr(&Fs->display_flags,DISPLAYf_SHOW);
  if(!WinCursorPosSet(Fs,Fs->pix_left+4,Fs->pix_top+4))cw_api_mask|=4;
  LBEqu(&Fs->display_flags,DISPLAYf_SHOW,okay);
  if(!paused)Suspend(sys_winmgr_task,FALSE);
  line=MStrPrint("EXPORT cursor-api-mask.bin %X 8\n",&cw_api_mask);p=line;while(*p)OutU8(0xE9,*p++);Free(line);
  line=MStrPrint("EXPORT cursor-mask.bin %X 8\n",&cw_mask);p=line;while(*p)OutU8(0xE9,*p++);Free(line);
}
