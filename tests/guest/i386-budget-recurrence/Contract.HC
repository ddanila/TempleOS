Bool bp_reopen;
CTask *bp_parent;
CDoc *bp_old_put;
U8 *bp_before,*bp_after;
I64 bp_before_size,bp_after_size,bp_mask,bp_stage,bp_amount_bits,bp_kind,bp_edit_kind;
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
I64 bp_dates[12]={730061,730091,730122,730061,730122,730181,730061,730242,730426,730061,730426,730792};
U8 *BPKindName(I64 kind)
{switch(kind){case 1:return "Interval";case 2:return "Monthly";case 3:return "Bimonthly";case 4:return "Semiannual";case 5:return "Annual";case 6:return "CANCEL";}return "Null";}
U8 *BPKindEnd(I64 kind)
{switch(kind){case 2:return "01/04/1999";case 3:return "03/04/1999";case 4:return "11/04/1999";case 5:return "11/04/2000";}return "";}
I64 BPCount()
{I64 n=0;CBgtEntry *e;for(e=b_head.next;e!=&b_head;e=e->next)n++;return n;}
U0 BPMark(U8 *name,U8 *state)
{BPLog("BP ");BPLog(name);BPLog(" ");BPLog(state);BPLog("\n");}
U0 BPType(U8 *name,I64 selected,I64 returned,I64 bit)
{
  CDoc *form=BPFormWait(3),*menu;CTask *owner=form->win_task,*child;
  I64 child_num,size;U8 *data,*expected=MStrPrint("[%s]",BPKindName(returned));CDocEntry *e;
  BPMark(name,"ready");
  while(TRUE) {
    child=owner->popup_task;
    if(child && TaskValidate(child) && (menu=child->display_doc) && menu->desc=='Menu')break;
    Sleep(1);
  }
  child_num=child->task_num;data=BPCapture(menu,&size);BPExport(MStrPrint("%s.menu",name),data,size);BPMark(name,"opened");
  while(menu->cur_entry==menu || menu->cur_entry->type_u8!=DOCT_MENU_VAL || StrCmp(menu->cur_entry->tag,BPKindName(selected)))Sleep(1);
  data=BPCapture(menu,&size);BPExport(MStrPrint("%s.selected",name),data,size);BPMark(name,"selected");
  while(owner->popup_task==child && TaskValidate(child) && child->task_num==child_num)Sleep(1);
  while(TRUE) {
    e=BPFirstField(form);
    if(e && !StrCmp(e->tag,expected) && *e->data(U16 *)==returned)break;
    Sleep(1);
  }
  Free(expected);BPFormExport(form,name,3);bp_mask|=bit;BPMark(name,"returned");
}
Bool BPDraftFields(CDoc *doc,I64 fields,I64 kind,U8 *desc)
{
  CDocEntry *e;I64 i=0;U8 *expected;Bool okay=TRUE;
  for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA || e->type_u8==DOCT_LST) {
    if(fields==3)switch(i) {
      case 0:expected=MStrPrint("[%s]",BPKindName(kind));break;
      case 1:expected=StrNew("Start Date:11/04/1998_");break;
      case 2:expected=MStrPrint("End Date  :%s_",BPKindEnd(kind));break;
      case 3:expected=MStrPrint("Period    :%8.2f_",0.0);break;
      default:expected=StrNew("");okay=FALSE;
    } else switch(i) {
      case 0:expected=StrNew("Date              :11/04/1998_");break;
      case 1:expected=MStrPrint("%10.2f_",100.0);break;
      case 2:expected=StrNew("Credit (from) Acct:BANK_");break;
      case 3:expected=StrNew("Debit  (to)   Acct:RENT_");break;
      case 4:expected=MStrPrint("Desc              :%s_",desc);break;
      default:expected=StrNew("");okay=FALSE;
    }
    if(StrCmp(e->tag,expected))okay=FALSE;Free(expected);i++;
  }
  if(fields==3)return okay && i==4;
  return okay && i==5;
}
U0 BPDraft(U8 *name,I64 fields,I64 kind,U8 *desc,I64 bit)
{
  CDoc *doc=BPFormWait(fields);CDocEntry *e,*last;Bool unlock;CTask *owner=doc->win_task;I64 owner_num=owner->task_num;
  BPMark(name,"ready");
  while(TRUE) {
    unlock=DocLock(doc);
    last=NULL;for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA)last=e;
    if(last && doc->cur_entry==last && doc->cur_col==last->min_col && BPDraftFields(doc,fields,kind,desc)) {
      BPFormExport(doc,name,fields);bp_mask|=bit;if(unlock)DocUnlock(doc);break;
    }
    if(unlock)DocUnlock(doc);Sleep(1);
  }
  BPMark(name,"draft");
  while(bp_parent->popup_task==owner && TaskValidate(owner) && owner->task_num==owner_num)Sleep(1);
}
Bool BPOkay(I64 kind,U8 *desc,Bool expanded)
{
  CBgtTemplate *t=t_head.next;CBgtEntry *e,*previous=&b_head;I64 n=0;
  if(t==&t_head || t!=t_head.last || t->next!=&t_head || t->last!=&t_head || t->type!=kind || t->flags || t->period ||
      StrCmp(t->start_date,"11/04/1998") || StrCmp(t->end_date,BPKindEnd(kind)) ||
      t->b.date!=730061<<32 || t->b.amount(U64)!=bp_amount_bits || t->b.type || t->b.flags ||
      StrCmp(t->b.credit,"BANK") || StrCmp(t->b.debit,"RENT") || StrCmp(t->b.desc,desc))return FALSE;
  for(e=b_head.next;e!=&b_head;e=e->next) {
    if(n>=3 || e->last!=previous || e->flags || e->amount(U64)!=bp_amount_bits || e->type!=BE_TEMPLATE_COPY || e->template!=t ||
        e->credit!=t->b.credit || e->debit!=t->b.debit || e->desc!=t->b.desc ||
        e->date!=(bp_dates[(kind-2)*3+n]<<32)+4)return FALSE;
    previous=e;n++;
  }
  if(expanded)return n==3 && previous==b_head.last;
  return !n && previous==b_head.last;
}
Bool BPNoFiles()
{return !FileFind(bgt_data_file) && !FileFind(bgt_string_file);}
U0 BPLive(U8 *name)
{
  CBgtTemplate *t=t_head.next;CBgtEntry *e;I64 n=BPCount(),*data=MAlloc(40+n*72,bp_parent),*p=data;
  *p++=t;*p++=t->b.credit;*p++=t->b.debit;*p++=t->b.desc;*p++=n;
  for(e=b_head.next;e!=&b_head;e=e->next) {
    *p++=e;*p++=e->date;*p++=e->type;*p++=e->flags;*p++=e->amount(U64);
    *p++=e->template;*p++=e->credit;*p++=e->debit;*p++=e->desc;
  }
  BPExport(name,data,40+n*72);BPExport(MStrPrint("%s.schedule",name),BPCopy(&t->start,BT_SIZE),BT_SIZE);
}
U0 BPSnapshot(U8 *name)
{I64 size;U8 *data=BPCapture(bp_parent->put_doc,&size);BPExport(name,data,size);}
U0 BPWaitNew(CDoc *doc)
{while(bp_parent->popup_task || BPCount!=3 || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);}
U0 BPWatch(U8 *)
{
  CDoc *doc;CBgtEntry *first;CBgtTemplate *original;U8 *credit,*debit,*desc;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) || doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;
  if(bp_reopen) {BPLive("live.bin");bp_after=BPCapture(doc,&bp_after_size);bp_stage=3;BPLog("BR ready\n");return;}
  BPLog("BP ready\n");
  BPType("new-cancel",5,1,64);BPType("new-cancel-action",6,1,8388608);BPType("new-select",bp_kind,bp_kind,128);
  BPDraft("created-schedule",3,bp_kind,NULL,256);BPDraft("created-entry",5,bp_kind,"plan",512);
  BPWaitNew(doc);if(BPOkay(bp_kind,"plan",TRUE) && BPNoFiles)bp_mask|=1024;
  BPSnapshot("created.DD");BPLive("created-live.bin");doc=bp_parent->put_doc;first=b_head.next;original=t_head.next;
  credit=original->b.credit;debit=original->b.debit;desc=original->b.desc;BPLog("BP created\n");
  while(doc->cur_entry!=first->doc_e)Sleep(1);BPLog("BP edit selected\n");
  BPType("edit-cancel-select",bp_edit_kind,bp_edit_kind,2048);BPDraft("edit-cancel-schedule",3,bp_edit_kind,NULL,4096);
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && t_head.next==original && BPOkay(bp_kind,"plan",TRUE) && BPNoFiles)bp_mask|=8192;
  BPSnapshot("cancelled.DD");BPLive("cancelled-live.bin");BPLog("BP cancelled\n");
  BPType("edit-select",bp_edit_kind,bp_edit_kind,16384);BPDraft("edited-schedule",3,bp_edit_kind,NULL,32768);
  BPDraft("edited-entry",5,bp_edit_kind,"edited plan",65536);
  BPWaitNew(doc);
  if(BPOkay(bp_edit_kind,"edited plan",TRUE) && t_head.next!=original &&
      t_head.next->b.credit!=credit && t_head.next->b.debit!=debit && t_head.next->b.desc!=desc && BPNoFiles)bp_mask|=131072;
  BPSnapshot("edited.DD");BPLive("edited-live.bin");doc=bp_parent->put_doc;first=b_head.next;BPLog("BP edited\n");
  while(doc->cur_entry!=first->doc_e)Sleep(1);BPLog("BP delete selected\n");
  while(bp_parent->put_doc==doc || b_head.next!=&b_head || t_head.next!=&t_head || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  if(BPNoFiles)bp_mask|=262144;BPSnapshot("deleted.DD");doc=bp_parent->put_doc;BPLog("BP deleted\n");
  BPType("recreate-select",bp_kind,bp_kind,524288);BPDraft("recreated-schedule",3,bp_kind,NULL,1048576);
  BPDraft("recreated-entry",5,bp_kind,"plan",2097152);BPWaitNew(doc);
  if(BPOkay(bp_kind,"plan",TRUE) && BPNoFiles)bp_mask|=4194304;
  BPLive("final-live.bin");bp_after=BPCapture(bp_parent->put_doc,&bp_after_size);bp_stage=3;BPLog("BP recreated\n");
}
U0 BPPaths()
{
  Cd("~/Budget");bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");bgt_data_file=FileNameAbs("Bgt.DATA.Z");
}
U0 BudgetEntry(I64 kind=2,Bool reopen=FALSE)
{
  CTask *watcher;I64 watch_num;
  CDoc *old_display=Fs->display_doc;CMenu *old_menu=Fs->cur_menu;CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  if(BT_SIZE!=44 || BE_SIZE!=32 || sizeof(BPSchedule)!=44 || sizeof(CBgtEntryForm)!=2056)throw('BPLayout',TRUE);
  if(kind<2 || kind>5)throw('BPKind',TRUE);bp_kind=kind;bp_edit_kind=kind+1;if(bp_edit_kind>5)bp_edit_kind=2;
  bp_amount_bits=0x4059000000000000;if(sizeof(U8 *)==8)bp_amount_bits++;
  bp_reopen=reopen;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;BPPaths;
  watcher=Spawn(&BPWatch,NULL,"Budget recurrence observer");if(!watcher)throw('BPWatch',TRUE);watch_num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==watch_num)Yield;
  if(bp_stage==3)bp_mask|=1;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=2;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings)bp_mask|=4;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=8;
  if(TaskValidate(ac.task)==old_ac)bp_mask|=16;
  BgtAcctsRead;BgtDataRead;if(BPOkay(bp_kind,"plan",FALSE))bp_mask|=32;BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  if(bp_reopen)BPLog("BR done\n");else BPLog("BP done\n");
}
