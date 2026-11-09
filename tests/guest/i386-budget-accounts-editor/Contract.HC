Bool bp_reopen;
CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage,bp_amount_bits;
U0 BPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *BPCapture(CDoc *doc,I64 *size)
{
  U8 *data,*copy;Bool unlock=DocLock(doc);
  data=DocSave(doc,size);copy=MAlloc(*size+1,bp_parent);MemCpy(copy,data,*size);copy[*size]=0;Free(data);
  if(unlock)DocUnlock(doc);
  return copy;
}
extern U0 BPExport(U8 *name,U8 *data,I64 size);
extern U0 BPFile(U8 *path,U8 *name);
CDoc *BPPopupWait(I64 kind)
{
  CTask *popup;CDoc *doc;
  while(TRUE) {
    popup=bp_parent->popup_task;
    if(popup && TaskValidate(popup) && (doc=popup->display_doc) && doc->desc==kind)return doc;
    Sleep(1);
  }
}
U0 BPDraftWait(CDoc *doc,U8 *name,U8 *needle,I64 bit)
{
  I64 size;U8 *data;
  while(TRUE) {
    data=BPCapture(doc,&size);
    if(doc->flags&DOCF_PLAIN_TEXT && StrMatch(needle,data)) {
      BPExport(name,data,size);bp_mask|=bit;return;
    }
    Free(data);Sleep(10);
  }
}
Bool BPEntryOkay()
{
  CBgtEntry *e=b_head.next;
  return e!=&b_head && e==b_head.last && e->next==&b_head && e->last==&b_head &&
      e->date==730000<<32 && e->amount==100 && e->type==BE_NORMAL && !e->flags &&
      !StrCmp(e->credit,"BANK") && !StrCmp(e->debit,"RENT") && !StrCmp(e->desc,"salary");
}
U0 BPWatch(U8 *)
{
  CDoc *doc,*editor;CBgtEntry *entry;I64 size;U8 *data;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) ||
      doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;
  if(bp_reopen) {bp_after=BPCapture(doc,&bp_after_size);bp_stage=3;BPLog("BR ready\n");return;}
  entry=b_head.next;BPLog("BP ready\n");
  BPPopupWait('Menu');BPLog("BP cancel instructions\n");
  editor=BPPopupWait('Edit');BPLog("BP cancel editor\n");
  BPDraftWait(editor,"cancel-draft.DD","GHOST",256);BPLog("BP cancel draft\n");
  while(bp_parent->popup_task || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  doc=bp_parent->put_doc;
  if(b_head.next==entry && BPEntryOkay &&
      BgtAcctColor("BANK")==1 && !HashFind("GHOST",accts_table,SFT_GENERIC))bp_mask|=64;
  data=BPCapture(bp_parent->put_doc,&size);BPExport("cancelled.DD",data,size);
  BPFile(bgt_accts_file,"cancel-accounts.DD");BPLog("BP cancelled\n");
  BPPopupWait('Menu');BPLog("BP accept instructions\n");
  editor=BPPopupWait('Edit');BPLog("BP accept editor\n");
  BPDraftWait(editor,"accept-draft.DD","GIFTS",512);BPLog("BP accept draft\n");
  while(bp_parent->popup_task || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey ||
      BgtAcctColor("BANK")!=4 || !HashFind("GIFTS",accts_table,SFT_GENERIC))Sleep(1);
  if(b_head.next==entry && BPEntryOkay && BgtAcctColor("BANK")==4 &&
      HashFind("GIFTS",accts_table,SFT_GENERIC) && !HashFind("CHARITY",accts_table,SFT_GENERIC))bp_mask|=128;
  bp_after=BPCapture(bp_parent->put_doc,&bp_after_size);bp_stage=3;BPFile(bgt_accts_file,"accepted-accounts.DD");BPLog("BP accepted\n");
}
U0 BPPaths()
{
  Cd("~/Budget");bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");bgt_data_file=FileNameAbs("Bgt.DATA.Z");
}
U0 BPExport(U8 *name,U8 *data,I64 size)
{
  if(bp_reopen)BPLog(MStrPrint("EXPORT reopen-%s %X %X\n",name,data,size));
  else BPLog(MStrPrint("EXPORT %s %X %X\n",name,data,size));
}
U0 BPFile(U8 *path,U8 *name)
{
  I64 size;U8 *data=FileRead(path,&size);
  if(!data)throw('BPFile',TRUE);
  BPExport(name,data,size);
}
U0 BudgetEntry(Bool reopen=FALSE)
{
  CTask *watcher;
  I64 watch_num;
  CDoc *old_display=Fs->display_doc;
  CMenu *old_menu=Fs->cur_menu;
  CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  bp_reopen=reopen;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
  BPPaths;
  if(!reopen) {
    BgtAcctsRead;QueInit(&b_head);QueInit(&t_head);
    CBgtEntry *e=CAlloc(sizeof(CBgtEntry));e->date=730000<<32;e->amount=100;
    e->credit=StrNew("BANK");e->debit=StrNew("RENT");e->desc=StrNew("salary");BgtIns(e);
    BgtDataWrite;BgtAcctsWrite;BgtDel;
    BPFile(bgt_data_file,"seed-data.bin");BPFile(bgt_string_file,"seed-strings.DD");BPFile(bgt_accts_file,"seed-accounts.DD");
  }
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
  if(BPEntryOkay && BgtAcctColor("BANK")==4 && HashFind("GIFTS",accts_table,SFT_GENERIC) &&
      !HashFind("CHARITY",accts_table,SFT_GENERIC))bp_mask|=32;
  BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);
  BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  if(bp_reopen)BPLog("BR done\n");else BPLog("BP done\n");
}
