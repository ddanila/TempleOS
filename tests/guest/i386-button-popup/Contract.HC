I64 bp_mode,bp_drive,bp_seen;
Bool bp_saved;
U0 BPDriver(CTask *caller)
{
  CTask *popup;CDoc *doc;CDocEntry *entry,*chosen;U8 *buf,*name;I64 size,wanted;
  wanted=1;
  if(bp_mode==0 || bp_mode==1)wanted=42;
  if(bp_mode==2 || bp_mode==5)wanted=0;
  if(bp_mode==3)wanted=7;
  while(TRUE) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) && Bt(&popup->task_flags,TASKf_AWAITING_MSG)) {
      doc=popup->display_doc;
      if(doc && doc->desc=='Menu' && doc->win_task==popup) {
        DocLock(doc);chosen=NULL;
        for(entry=doc->head.next;entry!=doc;entry=entry->next)
          if(entry->type_u8==DOCT_BTTN && entry->de_flags&DOCEF_LEFT_EXP && entry->left_exp==wanted)chosen=entry;
        if(chosen) {
          bp_seen++;buf=DocSave(doc,&size);name=MStrPrint("%c:/button-popup%d.DD",bp_drive,bp_mode);
          bp_saved=FileWrite(name,buf,size);Free(name);Free(buf);
          doc->cur_entry=chosen;doc->cur_col=0;DocUnlock(doc);
          if(bp_mode==1)PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
          else PostMsg(popup,MSG_KEY_DOWN,CH_ESC,0);
          return;
        }
        DocUnlock(doc);
      }
    }
    Yield;
  }
}
I64 BPCheck(I64 mode)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;CTask *old=Fs->popup_task,*driver;
  U8 *record,*name;
  I64 value=0;bp_mode=mode;bp_seen=0;bp_saved=FALSE;
  driver=Spawn(&BPDriver,Fs,"Button dialog input",-1,Fs,16384);
  if(mode<2)value=PopUp1("ACCEPT",42,"Header\n","Footer\n");
  else if(mode<4)value=PopUp2("LEFT",7,"RIGHT",0,"Header\n","Footer\n");
  else if(mode==4)value=PopUpOk("Header\n","Footer\n");
  else if(mode==5)value=PopUpNoYes("Header\n","Footer\n");
  else value=PopUpCancelOk("Header\n","Footer\n");
  while(TaskValidate(driver))Yield;
  record=MStrPrint("%d %d %d %d %d %d %d\n",value,bp_seen,bp_saved,DocPut==put,DocDisplay==display,DocBorder==border,Fs->popup_task==old);
  name=MStrPrint("%c:/button-result%d.TXT",bp_drive,mode);FileWrite(name,record,StrLen(record));Free(name);Free(record);
  if(mode==0 && value!=42 || mode==1 && value!=DOCM_CANCEL || mode==2 && value!=0 ||
     mode==3 && value!=7 || mode==4 && value!=TRUE || mode==5 && value!=FALSE ||
     mode==6 && value!=TRUE)return FALSE;
  return bp_seen==1 && bp_saved && DocPut==put && DocDisplay==display && DocBorder==border && Fs->popup_task==old;
}
