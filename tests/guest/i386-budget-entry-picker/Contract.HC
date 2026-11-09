Bool bp_reopen;
CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage,bp_amount_bits;
U0 BPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *BPCapture(CDoc *doc,I64 *size)
{
  U8 *data,*copy;Bool unlock=DocLock(doc);
  data=DocSave(doc,size);copy=MAlloc(*size,bp_parent);MemCpy(copy,data,*size);Free(data);
  if(unlock)DocUnlock(doc);
  return copy;
}
extern U0 BPExport(U8 *name,U8 *data,I64 size);
CDoc *BPPopupWait(I64 kind)
{
  CTask *popup;CDoc *form;CDocEntry *e;I64 fields;
  while(TRUE) {
    popup=bp_parent->popup_task;
    if(popup && TaskValidate(popup) && (form=popup->display_doc) && form->desc==kind) {
      if(kind=='Menu')return form;
      fields=0;
      for(e=form->head.next;e!=form;e=e->next)if(e->type_u8==DOCT_DATA)fields++;
      if(fields==5)return form;
    }
    Sleep(1);
  }
}
U0 BPMenu(U8 *name,U8 *selection)
{
  CDoc *menu=BPPopupWait('Menu');I64 size;U8 *data=BPCapture(menu,&size);
  BPExport(name,data,size);BPLog("BP ");BPLog(name);BPLog(" ready\n");
  while(menu->cur_entry==menu || menu->cur_entry->type_u8!=DOCT_MENU_VAL ||
      StrCmp(menu->cur_entry->tag,selection))Sleep(1);
  BPLog("BP ");BPLog(name);BPLog(" selected\n");
  while(bp_parent->popup_task && bp_parent->popup_task->display_doc==menu)Sleep(1);
}
Bool BPFields(CDoc *form,U8 *credit,U8 *debit,U8 *name)
{
  CDocEntry *e;I64 i=0,n,expected_bits=bp_amount_bits,*bits=MAlloc(8,bp_parent);Bool okay=TRUE,unlock=DocLock(form);
  U8 *expected,*tags=MAlloc(4096,bp_parent),*ptr=tags,*export_name;
  if(!StrCmp(name,"credit-cancelled.DD"))expected_bits=0x405F600000000000;
  for(e=form->head.next;e!=form;e=e->next)if(e->type_u8==DOCT_DATA) {
    n=StrLen(e->tag);MemCpy(ptr,e->tag,n);ptr+=n;*ptr++='\n';
    if(i==1) {*bits=*e->data(U64 *);if(*bits!=expected_bits)okay=FALSE;}
    else {
      switch(i) {
        case 0:expected="09/04/1998";break;
        case 2:expected=credit;break;
        case 3:expected=debit;break;
        case 4:expected="popup entry";break;
        default:okay=FALSE;expected="";
      }
      if(StrCmp(e->data,expected))okay=FALSE;
    }
    i++;
  }
  if(unlock)DocUnlock(form);
  export_name=MStrPrint("%s.fields",name);BPExport(export_name,tags,ptr-tags);
  export_name=MStrPrint("%s.amount",name);BPExport(export_name,bits,8);
  return okay && i==5;
}
U0 BPForm(U8 *name,U8 *credit,U8 *debit,I64 bit)
{
  CDoc *form=BPPopupWait('Form');I64 size;U8 *data=BPCapture(form,&size);
  BPExport(name,data,size);
  if(BPFields(form,credit,debit,name) && b_head.next==&b_head &&
      !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=bit;
  BPLog("BP ");BPLog(name);BPLog(" ready\n");
}
U0 BPWatch(U8 *)
{
  CDoc *doc;I64 size;U8 *data;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) ||
      doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;
  if(bp_reopen) {
    bp_after=BPCapture(doc,&bp_after_size);bp_stage=3;BPLog("BR ready\n");return;
  }
  BPLog("BP ready\n");
  BPPopupWait('Form');BPLog("BP form\n");
  BPMenu("credit-cancel.DD","RENT");BPForm("credit-cancelled.DD","","",64);
  BPMenu("credit-accept.DD","BANK");BPForm("credit-accepted.DD","BANK","",128);
  BPMenu("debit-cancel.DD","CASH");BPForm("debit-cancelled.DD","BANK","",256);
  BPMenu("debit-accept.DD","RENT");BPForm("debit-accepted.DD","BANK","RENT",512);
  while(bp_parent->popup_task || bp_parent->put_doc==doc || b_head.next==&b_head || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_after=BPCapture(bp_parent->put_doc,&bp_after_size);
  bp_stage=3;BPLog("BP entered\n");
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
  bp_amount_bits=0x405F600000000000;
  if(sizeof(U8 *)==8)bp_amount_bits=0x405F600000000002;
  bp_reopen=reopen;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
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
      b_head.next->amount(U64)==bp_amount_bits && b_head.next->date==730000<<32 &&
      !StrCmp(b_head.next->credit,"BANK") && !StrCmp(b_head.next->debit,"RENT") &&
      !StrCmp(b_head.next->desc,"popup entry"))bp_mask|=32;
  BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);
  BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  if(bp_reopen)BPLog("BR done\n");else BPLog("BP done\n");
}
