Bool bp_reopen;
CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after,*bp_selected,*bp_cancelled;
I64 bp_selected_size,bp_cancelled_size,bp_picker_info[8],bp_link_checks;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage;
U0 BPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *BPCapture(CDoc *doc,I64 *size)
{
  U8 *data,*copy;Bool unlock=DocLock(doc);
  data=DocSave(doc,size);copy=MAlloc(*size,bp_parent);MemCpy(copy,data,*size);Free(data);
  if(unlock)DocUnlock(doc);
  return copy;
}
extern U0 BPExport(U8 *name,U8 *data,I64 size);
CDoc *BPMenuWait()
{
  CTask *popup;CDoc *menu;
  while(TRUE) {
    popup=bp_parent->popup_task;
    if(popup && TaskValidate(popup) && (menu=popup->display_doc) && menu->desc=='Menu' &&
        menu->flags&DOCF_FORM)return menu;
    Sleep(1);
  }
}
U0 BPMenuSnapshot(CDoc *menu,I64 which)
{
  CDocEntry *entry;Bool unlock=DocLock(menu),links=TRUE;
  I64 *info=bp_picker_info+which*4,count=0,n,size;U8 *order=MAlloc(1024,bp_parent),*ptr=order,*data,*name;
  info[0]=0;info[1]=info[2]=info[3]=-1;
  for(entry=menu->head.next;entry!=menu;entry=entry->next)if(entry->type_u8==DOCT_MENU_VAL) {
    if(entry==menu->cur_entry)info[1]=count;
    if(!StrCmp(entry->tag,"BANK"))info[2]=count;
    if(!StrCmp(entry->tag,"RENT"))info[3]=count;
    if(!(entry->de_flags&DOCEF_LEFT_EXP) || !entry->left_exp || StrCmp(entry->tag,entry->left_exp(U8 *)))links=FALSE;
    n=StrLen(entry->tag);MemCpy(ptr,entry->tag,n);ptr+=n;*ptr++='\n';count++;
  }
  info[0]=count;
  data=BPCapture(menu,&size);
  if(unlock)DocUnlock(menu);
  if(which)name="picker2.DD";else name="picker1.DD";BPExport(name,data,size);
  if(which)name="order2.txt";else name="order1.txt";BPExport(name,order,ptr-order);
  if(links && count==13)bp_link_checks++;
}
U0 BPMenuSelected(CDoc *menu,U8 *name)
{
  Bool unlock,found;
  while(TRUE) {
    unlock=DocLock(menu);
    found=menu->cur_entry!=menu && menu->cur_entry->type_u8==DOCT_MENU_VAL && !StrCmp(menu->cur_entry->tag,name);
    if(unlock)DocUnlock(menu);
    if(found)return;
    Sleep(1);
  }
}
Bool BPEntriesOkay()
{
  CBgtEntry *first=b_head.next,*middle,*last;
  if(first==&b_head)return FALSE;
  middle=first->next;if(middle==&b_head)return FALSE;
  last=middle->next;
  if(last==&b_head || last!=b_head.last || last->next!=&b_head || first->last!=&b_head ||
      middle->last!=first || last->last!=middle || t_head.next!=&t_head || t_head.last!=&t_head)return FALSE;
  return first->date==730000<<32 && middle->date==730001<<32 && last->date==730002<<32 &&
      first->type==BE_NORMAL && middle->type==BE_NORMAL && last->type==BE_NORMAL &&
      !first->flags && !middle->flags && !last->flags && !first->template && !middle->template && !last->template &&
      first->amount==100 && middle->amount==20 && last->amount==30 &&
      !StrCmp(first->credit,"WAGES") && !StrCmp(first->debit,"BANK") && !StrCmp(first->desc,"salary") &&
      !StrCmp(middle->credit,"BANK") && !StrCmp(middle->debit,"FOOD") && !StrCmp(middle->desc,"groceries") &&
      !StrCmp(last->credit,"BANK") && !StrCmp(last->debit,"RENT") && !StrCmp(last->desc,"rent");
}
U0 BPWatch(U8 *)
{
  CDoc *doc,*menu;CBgtEntry *first,*middle,*last;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) ||
      doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;
  if(bp_reopen) {
    bp_after=BPCapture(doc,&bp_after_size);bp_stage=3;BPLog("BR ready\n");return;
  }
  first=b_head.next;middle=first->next;last=b_head.last;BPLog("BP ready\n");
  while(doc->cur_entry!=middle->doc_e)Sleep(1);
  bp_selected=BPCapture(doc,&bp_selected_size);BPLog("BP selected\n");
  menu=BPMenuWait;BPMenuSnapshot(menu,0);
  if(bp_picker_info[0]==13 && bp_picker_info[1]==bp_picker_info[2])bp_mask|=64;
  BPLog("BP picker1 ready\n");BPMenuSelected(menu,"RENT");BPLog("BP RENT selected\n");
  while(bp_parent->popup_task || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  doc=bp_parent->put_doc;
  if(!StrCmp(view_acct,"RENT") && b_head.next==first && first->next==middle &&
      middle->next==last && b_head.last==last && doc->cur_entry==middle->doc_e && BPEntriesOkay)bp_mask|=128;
  bp_after=BPCapture(doc,&bp_after_size);BPLog("BP RENT view\n");
  menu=BPMenuWait;BPMenuSnapshot(menu,1);if(bp_link_checks==2)bp_mask|=1024;BPLog("BP picker2 ready\n");
  BPMenuSelected(menu,"BANK");
  if(bp_picker_info[4]==13 && bp_picker_info[5]==bp_picker_info[7])bp_mask|=256;
  BPLog("BP BANK selected\n");
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && !StrCmp(view_acct,"RENT") && b_head.next==first &&
      first->next==middle && middle->next==last && b_head.last==last && BPEntriesOkay)bp_mask|=512;
  bp_cancelled=BPCapture(bp_parent->put_doc,&bp_cancelled_size);
  bp_stage=3;BPLog("BP picker cancelled\n");
}
U0 BPAdd(I64 day,F64 amount,U8 *credit,U8 *debit,U8 *desc)
{
  CBgtEntry *e=CAlloc(sizeof(CBgtEntry));e->date=day<<32;e->amount=amount;
  e->credit=StrNew(credit);e->debit=StrNew(debit);e->desc=StrNew(desc);BgtIns(e);
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
U0 BudgetPicker(Bool reopen=FALSE)
{
  CTask *watcher;
  I64 watch_num;
  CDoc *old_display=Fs->display_doc;
  CMenu *old_menu=Fs->cur_menu;
  CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  bp_reopen=reopen;bp_mask=bp_stage=bp_link_checks=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
  BPPaths;
  if(!reopen) {
  BgtAcctsRead;QueInit(&b_head);QueInit(&t_head);
  BPAdd(730002,30,"BANK","RENT","rent");
  BPAdd(730000,100,"WAGES","BANK","salary");
  BPAdd(730001,20,"BANK","FOOD","groceries");
  BgtDataWrite;BgtAcctsWrite;BgtDel;
  BPFile(bgt_data_file,"seed-data.bin");BPFile(bgt_string_file,"seed-strings.DD");BPFile(bgt_accts_file,"seed-accounts.DD");
  }
  watcher=Spawn(&BPWatch,NULL,"Budget session observer");
  if(!watcher)throw('BPWatch',TRUE);
  watch_num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==watch_num)Yield;
  //Check again after Budget returns, beyond popup teardown and callback return.
  if(bp_reopen) {if(StrCmp(view_acct,"BANK"))bp_stage=0;}
  else if(StrCmp(view_acct,"RENT"))bp_mask&=~512;
  if(bp_stage==3)bp_mask|=1;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=2;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings)bp_mask|=4;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=8;
  if(TaskValidate(ac.task)==old_ac)bp_mask|=16;
  BgtAcctsRead;BgtDataRead;
  if(BPEntriesOkay)bp_mask|=32;
  BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);
  if(!bp_reopen) {BPExport("selected.DD",bp_selected,bp_selected_size);BPExport("cancelled.DD",bp_cancelled,bp_cancelled_size);BPExport("picker-info.bin",bp_picker_info,64);}
  BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  if(bp_reopen)BPLog("BR done\n");else BPLog("BP done\n");
}
