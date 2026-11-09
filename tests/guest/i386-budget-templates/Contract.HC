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
Bool BPDraftFields(CDoc *doc,I64 fields,U8 *first,U8 *last,F64 period,U8 *desc)
{
  CDocEntry *e;I64 i=0;U8 *expected;Bool okay=TRUE;
  for(e=doc->head.next;e!=doc;e=e->next)if(e->type_u8==DOCT_DATA || e->type_u8==DOCT_LST) {
    if(fields==3)switch(i) {
      case 0:expected=StrNew("[Interval]");break;
      case 1:expected=MStrPrint("Start Date:%s_",first);break;
      case 2:expected=MStrPrint("End Date  :%s_",last);break;
      case 3:expected=MStrPrint("Period    :%8.2f_",period);break;
      default:expected=StrNew("");okay=FALSE;
    } else switch(i) {
      case 0:expected=StrNew("Date              :09/04/1998_");break;
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
U0 BPDraft(U8 *name,I64 fields,U8 *first,U8 *last,F64 period,U8 *desc,I64 bit)
{
  CDoc *doc=BPFormWait(fields);CDocEntry *e;BPSchedule *s;CBgtEntryForm *b;Bool okay,unlock;CTask *owner=doc->win_task;I64 owner_num=owner->task_num;
  BPLog("BP ");BPLog(name);BPLog(" ready\n");
  while(TRUE) {
    unlock=DocLock(doc);e=BPFirstField(doc);okay=FALSE;
    okay=BPDraftFields(doc,fields,first,last,period,desc);
    if(okay) {
      BPFormExport(doc,name,fields);bp_mask|=bit;if(unlock)DocUnlock(doc);break;
    }
    if(unlock)DocUnlock(doc);Sleep(1);
  }
  BPLog("BP ");BPLog(name);BPLog(" draft\n");
  while(bp_parent->popup_task==owner && TaskValidate(owner) && owner->task_num==owner_num && owner->display_doc==doc)Sleep(1);
}
I64 BPCount()
{I64 n=0;CBgtEntry *e;for(e=b_head.next;e!=&b_head;e=e->next)n++;return n;}
Bool BPOkay(Bool expanded)
{
  CBgtTemplate *t=t_head.next;CBgtEntry *e,*previous=&b_head;I64 copies=0,normals=0;
  if(t==&t_head || t!=t_head.last || t->next!=&t_head || t->last!=&t_head ||
      t->type!=BT_INTERVAL || t->flags || t->period(U64)!=bp_period_bits ||
      StrCmp(t->start_date,"09/04/1998") || StrCmp(t->end_date,"09/08/1998") ||
      t->b.date!=730000<<32 || t->b.amount(U64)!=bp_amount_bits || t->b.type || t->b.flags ||
      StrCmp(t->b.credit,"BANK") || StrCmp(t->b.debit,"RENT") || StrCmp(t->b.desc,"rent plan"))return FALSE;
  for(e=b_head.next;e!=&b_head;e=e->next) {
    if(e->last!=previous || e->flags || e->amount(U64)!=bp_amount_bits || StrCmp(e->credit,"BANK") || StrCmp(e->debit,"RENT"))return FALSE;
    if(e->type==BE_TEMPLATE_COPY) {
      if(e->template!=t || e->credit!=t->b.credit || e->debit!=t->b.debit || e->desc!=t->b.desc ||
          e->date!=((730000+copies*2)<<32)+4)return FALSE;
      copies++;
    } else {
      if(e->type!=BE_NORMAL || e->template || StrCmp(e->desc,"cash batch") ||
          e->date!=((730001+normals)<<32)+4)return FALSE;
      normals++;
    }
    previous=e;
  }
  if(expanded)return previous==b_head.last && normals==2 && copies==3;
  return previous==b_head.last && normals==2 && !copies;
}
U0 BPLive(U8 *name)
{
  CBgtTemplate *t=t_head.next;CBgtEntry *e;I64 n=BPCount(),*data=MAlloc(40+n*72,bp_parent),*p=data;
  *p++=t;*p++=t->b.credit;*p++=t->b.debit;*p++=t->b.desc;*p++=n;
  for(e=b_head.next;e!=&b_head;e=e->next) {
    *p++=e;*p++=e->date;*p++=e->type;*p++=e->flags;*p++=e->amount(U64);
    *p++=e->template;*p++=e->credit;*p++=e->debit;*p++=e->desc;
  }
  BPExport(name,data,40+n*72);
}
U0 BPSnapshot(U8 *name)
{I64 size;U8 *data=BPCapture(bp_parent->put_doc,&size);BPExport(name,data,size);}
U0 BPWatch(U8 *)
{
  CDoc *doc;CBgtEntry *first;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) || doc->user_put_key!=&BgtPutKey)Sleep(1);
  bp_before=BPCapture(doc,&bp_before_size);bp_stage=1;
  if(bp_reopen) {
    BPLive("live.bin");bp_after=BPCapture(doc,&bp_after_size);bp_stage=3;BPLog("BR ready\n");return;
  }
  BPLog("BP ready\n");
  BPDraft("cancel-schedule",3,"01/01/2001","01/15/2001",7,NULL,64);
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && b_head.next==&b_head && t_head.next==&t_head &&
      !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=128;
  BPSnapshot("cancelled.DD");BPLog("BP cancelled\n");
  BPDraft("template-schedule",3,"09/04/1998","09/08/1998",2,NULL,256);
  BPDraft("template-entry",5,NULL,NULL,0,"rent plan",512);
  while(bp_parent->popup_task || BPCount!=3 || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  if(t_head.next!=&t_head && t_head.next==t_head.last && !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=1024;
  BPSnapshot("template.DD");BPLive("template-live.bin");doc=bp_parent->put_doc;first=b_head.next;BPLog("BP template entered\n");
  while(doc->cur_entry!=first->doc_e)Sleep(1);BPLog("BP periodic selected\n");
  BPDraft("periodic-cancel-schedule",3,"09/04/1998","09/06/1998",1,NULL,2048);
  BPDraft("periodic-cancel-entry",5,NULL,NULL,0,"cash batch",4096);
  BPDraft("periodic-return-schedule",3,"09/04/1998","09/06/1998",1,NULL,8192);
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && BPCount==3 && b_head.next==first && t_head.next==t_head.last &&
      !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=16384;
  BPSnapshot("periodic-cancelled.DD");BPLive("periodic-cancelled-live.bin");BPLog("BP periodic cancelled\n");
  BPDraft("periodic-schedule",3,"09/04/1998","09/06/1998",1,NULL,32768);
  BPDraft("periodic-entry",5,NULL,NULL,0,"cash batch",65536);
  while(bp_parent->popup_task || BPCount!=5 || bp_parent->put_doc==doc || bp_parent->put_doc->user_put_key!=&BgtPutKey)Sleep(1);
  if(BPOkay(TRUE) && !FileFind(bgt_data_file) && !FileFind(bgt_string_file))bp_mask|=131072;
  BPLive("final-live.bin");bp_after=BPCapture(bp_parent->put_doc,&bp_after_size);bp_stage=3;BPLog("BP periodic entered\n");
}
U0 BPPaths()
{
  Cd("~/Budget");bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");bgt_data_file=FileNameAbs("Bgt.DATA.Z");
}
U0 BudgetEntry(Bool reopen=FALSE)
{
  CTask *watcher;I64 watch_num;
  CDoc *old_display=Fs->display_doc;CMenu *old_menu=Fs->cur_menu;CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  if(BT_SIZE!=44 || BE_SIZE!=32 || sizeof(BPSchedule)!=44 || sizeof(CBgtEntryForm)!=2056)throw('BPLayout',TRUE);
  bp_amount_bits=0x4059000000000000;bp_period_bits=0x4000000000000000;
  if(sizeof(U8 *)==8) {bp_amount_bits++;bp_period_bits++;}
  bp_reopen=reopen;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;BPPaths;
  watcher=Spawn(&BPWatch,NULL,"Budget template observer");if(!watcher)throw('BPWatch',TRUE);watch_num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==watch_num)Yield;
  if(bp_stage==3)bp_mask|=1;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=2;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings)bp_mask|=4;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=8;
  if(TaskValidate(ac.task)==old_ac)bp_mask|=16;
  BgtAcctsRead;BgtDataRead;if(BPOkay(FALSE))bp_mask|=32;BgtDel;
  BPExport("before.DD",bp_before,bp_before_size);BPExport("after.DD",bp_after,bp_after_size);BPExport("mask.bin",&bp_mask,8);
  BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");
  if(bp_reopen)BPLog("BR done\n");else BPLog("BP done\n");
}
