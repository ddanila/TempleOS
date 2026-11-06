CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage;
U0 BPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *BPCapture(CDoc *doc,I64 *size)
{
  U8 *data,*copy;Bool unlock=DocLock(doc);
  data=DocSave(doc,size);copy=MAlloc(*size,bp_parent);MemCpy(copy,data,*size);Free(data);
  if(unlock)DocUnlock(doc);
  return copy;
}
U0 BPWatch(U8 *)
{
  CDoc *doc;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) ||
      doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;BPLog("BP ready\n");
  CTask *popup;CDoc *form;CDocEntry *e;I64 fields;
  while(TRUE) {
    popup=bp_parent->popup_task;
    if(popup && TaskValidate(popup) && (form=popup->display_doc) && form->desc=='Form') {
      fields=0;
      for(e=form->head.next;e!=form;e=e->next)if(e->type_u8==DOCT_DATA)fields++;
      if(fields==5)break;
    }
    Sleep(1);
  }
  bp_stage=2;BPLog("BP form\n");
  while(bp_parent->popup_task || bp_parent->put_doc==doc || b_head.next==&b_head)Sleep(1);
  bp_after=BPCapture(bp_parent->put_doc,&bp_after_size);
  bp_stage=3;BPLog("BP entered\n");
}

U0 BPPaths()
{
  Cd("~/Budget");bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");bgt_data_file=FileNameAbs("Bgt.DATA.Z");
}
U0 BPExport(U8 *name,U8 *data,I64 size)
{BPLog(MStrPrint("EXPORT %s %X %X\n",name,data,size));}
U0 BPFile(U8 *path,U8 *name)
{
  I64 size;U8 *data=FileRead(path,&size);
  if(!data)throw('BPFile',TRUE);
  BPExport(name,data,size);
}
U0 BudgetEntry()
{
  CTask *watcher;
  I64 watch_num;
  CDoc *old_display=Fs->display_doc;
  CMenu *old_menu=Fs->cur_menu;
  CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
  BPPaths;
  watcher=Spawn(&BPWatch,NULL,"Budget session observer");
  if(!watcher)throw('BPWatch',TRUE);
  watch_num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==watch_num)Yield;
  if(bp_stage==3)bp_mask|=1;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=2;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings)bp_mask|=4;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=8;
  if(TaskValidate(ac.task)==old_ac)bp_mask|=16;
  BgtAcctsRead;BgtDataRead;
  if(b_head.next==b_head.last && b_head.last->next==&b_head &&
      b_head.next->amount==125.5 && b_head.next->date==730000<<32 &&
      !StrCmp(b_head.next->credit,"BANK") && !StrCmp(b_head.next->debit,"RENT") &&
      !StrCmp(b_head.next->desc,"popup entry"))bp_mask|=32;
  BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);
  BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  BPLog("BP done\n");
}
