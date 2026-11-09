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
I64 bm_state[3],bm_target[2];
CBgtEntry *bm_rows[3];
U0 BMMark(U8 *s){BPLog("BM ");BPLog(s);BPLog("\n");}
U0 BMTrack(U8 *)
{while(TRUE){bm_state[0]=ms.pos.x;bm_state[1]=ms.pos.y;bm_state[2]=ms.lb+2*ms.rb;Yield;}}
U0 BMPoint(CDoc *doc,CDocEntry *e,U8 *name)
{
  CTask *task=doc->win_task;
  bm_target[0]=task->pix_left+task->scroll_x+(e->x-doc->line_start_col+2)*FONT_WIDTH+FONT_WIDTH/2;
  bm_target[1]=task->pix_top+task->scroll_y+(e->y-doc->top_line_num)*FONT_HEIGHT+FONT_HEIGHT/2;
  BPExport(name,bm_target,sizeof(bm_target));
}
U0 BMSnapshot(U8 *name,CDoc *doc)
{
  I64 size,i,*live,*p;CBgtEntry *e;U8 *data=BPCapture(doc,&size);BPExport(name,data,size);
  if(doc==bp_parent->put_doc) {
    live=p=MAlloc(216,bp_parent);e=b_head.next;
    for(i=0;i<3;i++) {
      if(e==&b_head)throw('BMLive',TRUE);
      *p++=e;*p++=e->date;*p++=e->type;*p++=e->flags;*p++=e->amount(U64);
      *p++=e->template;*p++=e->credit;*p++=e->debit;*p++=e->desc;e=e->next;
    }
    if(e!=&b_head)throw('BMLive',TRUE);BPExport(MStrPrint("%s.live",name),live,216);
  }
}
U8 *BMDesc(I64 i)
{switch(i){case 0:return "first";case 1:return "second";case 2:return "third";}return "";}
Bool BMRows()
{
  CBgtEntry *e=b_head.next;I64 i=0;
  while(e!=&b_head && i<3) {
    if(e!=bm_rows[i] || e->date!=(730000+i)<<32 || e->type!=BE_NORMAL || e->flags ||
        e->amount!=100 || e->template || StrCmp(e->credit,"BANK") || StrCmp(e->debit,"RENT") ||
        StrCmp(e->desc,BMDesc(i)))return FALSE;
    e=e->next;i++;
  }
  return i==3 && e==&b_head;
}
U0 BMSelect(CDoc *doc,I64 row,U8 *name,I64 bit)
{
  while(doc->cur_entry!=bm_rows[row]->doc_e || sys_focus_task!=bp_parent || ms.lb || ms.left_dbl_time)Sleep(1);
  if(BMRows)bp_mask|=bit;
  I64 *position=MAlloc(16,bp_parent);position[0]=row;position[1]=doc->cur_col;
  BPExport(MStrPrint("%s.position",name),position,16);
  BMSnapshot(name,doc);BMMark(name);
}
U0 BMWatch(U8 *)
{
  CDoc *doc,*form,*menu;CTask *child;CDocEntry *e;I64 i;
  while(!(doc=bp_parent->put_doc) || doc==bp_old_put || !(doc->flags&DOCF_FORM) || doc->user_put_key!=&BgtPutKey)Sleep(1);
  e=b_head.next;for(i=0;i<3;i++){bm_rows[i]=e;e=e->next;}
  Sleep(1000);BMSnapshot("before.DD",doc);bp_stage=1;
  if(bp_reopen) {
    BMPoint(doc,bm_rows[0]->doc_e,"target.bin");bp_stage=3;BMMark("reopen ready");return;
  }
  BMPoint(doc,bm_rows[1]->doc_e,"second-target.bin");BMMark("ready");
  BMSelect(doc,1,"selected.DD",64);
  form=BPFormWait(5);Sleep(1000);BPFormExport(form,"edit",5);BMMark("edit ready");
  while(bp_parent->popup_task)Sleep(1);
  if(bp_parent->put_doc==doc && BMRows && doc->cur_entry==bm_rows[1]->doc_e)bp_mask|=128;
  BMSnapshot("cancelled.DD",doc);BMMark("edit cancelled");
  while(TRUE) {
    child=bp_parent->popup_task;
    if(child && TaskValidate(child) && (menu=child->display_doc) && menu->desc=='Menu')break;
    Sleep(1);
  }
  Sleep(1000);BMSnapshot("accounts-menu.DD",menu);
  for(e=menu->head.next;e!=menu;e=e->next)if(e->type_u8==DOCT_MENU_VAL && !StrCmp(e->tag,"RENT"))break;
  if(e==menu)throw('BMMenu',TRUE);BMPoint(menu,e,"rent-target.bin");BMMark("account ready");
  while(bp_parent->popup_task || StrCmp(view_acct,"RENT") || bp_parent->put_doc==doc)Sleep(1);
  doc=bp_parent->put_doc;
  while(doc->user_put_key!=&BgtPutKey)Sleep(1);
  I64 frame=winmgr.updates+2;while(winmgr.updates<frame)Sleep(1);
  if(BMRows)bp_mask|=256;
  BMSnapshot("rent.DD",doc);BMPoint(doc,bm_rows[0]->doc_e,"first-target.bin");BMMark("account selected");
  BMSelect(doc,0,"first.DD",512);bp_stage=3;BMMark("save ready");
}
U0 BMSeed()
{
  CBgtEntry *e;I64 i;
  BgtAcctsRead;QueInit(&b_head);QueInit(&t_head);
  for(i=0;i<3;i++) {
    e=CAlloc(sizeof(CBgtEntry));e->date=(730000+i)<<32;e->amount=100;
    e->credit=StrNew("BANK");e->debit=StrNew("RENT");e->desc=StrNew(BMDesc(i));BgtIns(e);
  }
  BgtDataWrite;BgtAcctsWrite;BgtDel;
}
U0 BudgetMouse(Bool reopen=FALSE)
{
  CTask *watcher,*tracker;I64 num,track_num,i;CBgtEntry *e;
  CDoc *old_display=Fs->display_doc;CMenu *old_menu=Fs->cur_menu;CTaskSettings *old_settings=Fs->next_settings;
  I64 left=Fs->win_left,right=Fs->win_right,top=Fs->win_top,bottom=Fs->win_bottom;
  Bool old_ac=TaskValidate(ac.task);
  bp_reopen=reopen;bp_mask=bp_stage=0;bp_parent=Fs;bp_old_put=Fs->put_doc;
  Cd("~/Budget");bgt_string_file=FileNameAbs("Strs.DD.Z");bgt_accts_file=FileNameAbs("Accts.DD.Z");bgt_data_file=FileNameAbs("Bgt.DATA.Z");
  if(!reopen)BMSeed;
  BPLog(MStrPrint("BM STATE %X\n",bm_state));
  tracker=Spawn(&BMTrack,NULL,"Budget mouse position observer");track_num=tracker->task_num;
  watcher=Spawn(&BMWatch,NULL,"Budget mouse workflow observer");num=watcher->task_num;
  WinFocus(Fs);Budget;
  while(TaskValidate(watcher) && watcher->task_num==num)Yield;
  if(TaskValidate(tracker) && tracker->task_num==track_num)Kill(tracker,TRUE,FALSE);
  if(bp_stage==3)bp_mask|=1;
  if(Fs->put_doc==bp_old_put && Fs->display_doc==old_display)bp_mask|=2;
  if(Fs->cur_menu==old_menu && Fs->next_settings==old_settings)bp_mask|=4;
  if(Fs->win_left==left && Fs->win_right==right && Fs->win_top==top && Fs->win_bottom==bottom)bp_mask|=8;
  if(TaskValidate(ac.task)==old_ac)bp_mask|=16;
  BgtAcctsRead;BgtDataRead;e=b_head.next;for(i=0;i<3;i++){bm_rows[i]=e;e=e->next;}
  if(BMRows)bp_mask|=32;BgtDel;
  BPExport("mask.bin",&bp_mask,8);BPFile(bgt_data_file,"data.bin");BPFile(bgt_string_file,"strings.DD");BPFile(bgt_accts_file,"accounts.DD");BMMark("done");
}
