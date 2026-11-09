Bool bp_reopen;
CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage,bp_amount_bits,bp_period_bits;
class BPSchedule {U16 type,flags;U8 first[16],last[16];F64 period;};
U0 BPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 *BPCopy(U8 *data,I64 size)
{U8 *copy=MAlloc(size+1,bp_parent);MemCpy(copy,data,size);copy[size]=0;return copy;}
U8 *BPCapture(CDoc *doc,I64 *size)
{
  U8 *data,*copy;Bool unlock=DocLock(doc);
  data=DocSave(doc,size);copy=BPCopy(data,*size);Free(data);
  if(unlock)DocUnlock(doc);return copy;
}
U0 BPExport(U8 *name,U8 *data,I64 size)
{
  if(bp_reopen)BPLog(MStrPrint("EXPORT reopen-%s %X %X\n",name,data,size));
  else BPLog(MStrPrint("EXPORT %s %X %X\n",name,data,size));
}
U0 BPFile(U8 *path,U8 *name)
{I64 size;U8 *data=FileRead(path,&size);if(!data)throw('BPFile',TRUE);BPExport(name,data,size);}
CDoc *BPFormWait(I64 fields)
{
  CTask *popup;CDoc *doc;CDocEntry *e;I64 n;
  while(TRUE) {
    popup=bp_parent->popup_task;
    if(popup && TaskValidate(popup) && (doc=popup->display_doc) && doc->desc=='Form') {
      n=0;for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA)n++;
      if(n==fields)return doc;
    }
    Sleep(1);
  }
}
CDocEntry *BPFirstField(CDoc *doc)
{CDocEntry *e;for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA || e->type_u8==DOCT_LST)return e;return NULL;}
U0 BPFormExport(CDoc *doc,U8 *name,I64 fields)
{
  I64 size,n=0;U8 *data,*tags=MAlloc(4096,bp_parent),*p=tags;CDocEntry *e;
  Bool unlock=DocLock(doc);
  data=BPCapture(doc,&size);BPExport(MStrPrint("%s.DD",name),data,size);
  for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA || e->type_u8==DOCT_LST) {
    size=StrLen(e->tag);if(p-tags+size+1>4096)throw('BPTags',TRUE);
    MemCpy(p,e->tag,size);p+=size;*p++='\n';n++;
  }
  BPExport(MStrPrint("%s.fields",name),tags,p-tags);
  e=BPFirstField(doc);if(fields==3)size=BT_SIZE;else size=sizeof(CBgtEntryForm);
  data=BPCopy(e->data,size);BPExport(MStrPrint("%s.state",name),data,size);
  if(unlock)DocUnlock(doc);
}
U0 BVMark(U8 *name,U8 *state)
{BPLog("BV ");BPLog(name);BPLog(" ");BPLog(state);BPLog("\n");}
U0 BVDraft(U8 *name,I64 fields,U8 *expected)
{
  CDoc *doc=BPFormWait(fields);CDocEntry *e,*last;
  U8 *tags,*p;Bool unlock,okay;
  BVMark(name,"ready");
  while(TRUE) {
    unlock=DocLock(doc);tags=MAlloc(4096);p=tags;last=NULL;
    for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA || e->type_u8==DOCT_LST) {
      StrCpy(p,e->tag);p+=StrLen(p);*p++='\n';last=e;
    }
    *p=0;okay=!StrCmp(tags,expected) && doc->cur_entry==last && doc->cur_col==last->min_col;
    Free(tags);
    if(okay)BPFormExport(doc,name,fields);
    if(unlock)DocUnlock(doc);if(okay)break;Sleep(1);
  }
  BVMark(name,"draft");
}
U0 BVReturned(U8 *name,CDoc *doc,I64 bit)
{
  I64 size;U8 *data;
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && b_head.next==&b_head && b_head.last==&b_head &&
      t_head.next==&t_head && t_head.last==&t_head && !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=bit;
  data=BPCapture(bp_parent->put_doc,&size);BPExport(MStrPrint("%s-report.DD",name),data,size);
  BVMark(name,"returned");
}
U0 BVWatch(U8 *)
{
  CDoc *doc,*form,*menu;CTask *owner,*child;CDocEntry *e;I64 size;U8 *data;BPSchedule *s;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) || doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_stage=1;BPLog("BV ready\n");
  BVDraft("zero",3,"[Interval]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :    0.00_\n");
  BVReturned("zero",doc,1);
  BVDraft("negative",3,"[Interval]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :   -1.00_\n");
  BVReturned("negative",doc,2);
  form=BPFormWait(3);owner=form->win_task;BVMark("null-menu","ready");
  while(TRUE) {
    child=owner->popup_task;
    if(child && TaskValidate(child) && (menu=child->display_doc) && menu->desc=='Menu')break;
    Sleep(1);
  }
  data=BPCapture(menu,&size);BPExport("null-menu.DD",data,size);BVMark("null-menu","opened");
  while(owner->popup_task)Sleep(1);
  while((e=BPFirstField(form)) && (StrCmp(e->tag,"[Null]") || *e->data(U16 *)))Sleep(1);
  BVMark("null-menu","returned");
  BVDraft("null",3,"[Null]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :    1.00_\n");
  BVReturned("null",doc,4);
  BVDraft("valid",3,"[Interval]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :    1.00_\n");
  BVDraft("entry-cancel",5,"Date              :01/01/2001_\n      5.00_\nCredit (from) Acct:GHOST_\nDebit  (to)   Acct:VOID_\nDesc              :discard me_\n");
  //The cancelled base form must return to the same committed schedule.
  form=BPFormWait(3);e=BPFirstField(form);s=e->data;
  if(s->type==1 && !s->flags && !StrCmp(s->first,"01/01/2001") && !StrCmp(s->last,"01/03/2001") && s->period(U64)==bp_period_bits)bp_mask|=16;
  BPFormExport(form,"retained",3);BVMark("retained","ready");
  BVDraft("invalidated",3,"[Interval]\nStart Date:01/01/2001_\nEnd Date  :01/03/2001_\nPeriod    :    0.00_\n");
  if(s->period(U64)==bp_period_bits)bp_mask|=32;
  BVReturned("invalidated",doc,8);bp_stage=3;BPLog("BV done actions\n");
}
U0 BudgetValidation()
{
  CTask *watcher;I64 num;
  CDoc *old_display=Fs->display_doc;CMenu *old_menu=Fs->cur_menu;CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  bp_reopen=FALSE;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
  bp_period_bits=0x3FF0000000000000;if(sizeof(U8 *)==8)bp_period_bits++;
  if(BT_SIZE!=44 || BE_SIZE!=32 || sizeof(BPSchedule)!=44 || sizeof(CBgtEntryForm)!=2056)throw('BVLayout',TRUE);
  watcher=Spawn(&BVWatch,NULL,"Budget validation observer");num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==num)Yield;
  if(bp_stage==3)bp_mask|=64;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=128;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings && Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=256;
  if(TaskValidate(ac.task)==old_ac && !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=512;
  BPExport("mask.bin",&bp_mask,8);BPFile(bgt_accts_file,"accounts.DD");BPLog("BV done\n");
}
