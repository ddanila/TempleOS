I64 tm_mode=0,tm_drive=0,tm_buttons=0;
Bool tm_sent=FALSE,tm_saved=FALSE,tm_refresh=FALSE;
U0 TMTrace(U8 *label,I64 value){U8 *s=MStrPrint("MENU %s %d\n",label,value),*p=s;while(*p)OutU8(0xE9,*p++);Free(s);}
U0 TMDrive(I64 drive){tm_drive=drive;}
U0 TMDriver(CTask *caller)
{
  CTask *popup;
  CDoc *doc;
  CDocEntry *entry,*chosen;
  I64 target=tm_mode,size,old_updates;
  U8 *buffer,*name;
  if(target>=10)target=DOCM_CANCEL;
  while(TRUE) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup)) {
      doc=popup->display_doc;
      if(doc && doc->desc=='Menu' && doc->flags&DOCF_FORM && doc->win_task==popup) {
        DocLock(doc);
        chosen=NULL;tm_buttons=0;
        for(entry=doc->head.next;entry!=doc;entry=entry->next)
          if(entry->type_u8==DOCT_BTTN && entry->de_flags&DOCEF_LEFT_EXP) {
            tm_buttons++;
            if(entry->left_exp==target)chosen=entry;
          }
        if(chosen) {
          TMTrace("chosen",tm_mode);TMTrace("buttons",tm_buttons);
          if(tm_mode<3) {
            TMTrace("save begin",tm_mode);
            buffer=DocSave(doc,&size);
            TMTrace("save done",size);
            name=MStrPrint("%c:/term-menu%d.DD",tm_drive,tm_mode);
            TMTrace("write begin",tm_mode);
            tm_saved=FileWrite(name,buffer,size)>0;
            TMTrace("write done",tm_saved);
            Free(name);Free(buffer);
          } else tm_saved=TRUE;
          doc->cur_entry=chosen;doc->cur_col=0;
          DocUnlock(doc);
          TMTrace("unlock done",tm_mode);
          if(tm_mode>=12)WinToTop(caller);
          old_updates=winmgr.updates;
          if(tm_mode==11 || tm_mode==13)PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
          else PostMsg(popup,MSG_KEY_DOWN,CH_SPACE,0);
          tm_sent=TRUE;TMTrace("sent",tm_mode);
          TMTrace("updates before",winmgr.updates);
          Sleep(1000);
          TMTrace("updates after",winmgr.updates);
          tm_refresh=winmgr.updates>old_updates;
          if(TaskValidate(popup)) {
            TMTrace("popup width",popup->win_width);
            TMTrace("popup height",popup->win_height);
            TMTrace("popup focused",popup==sys_focus_task);
            TMTrace("popup flags",popup->task_flags);
          }
          return;
        }
        DocUnlock(doc);
      }
    }
    Yield;
  }
}
I64 TMChoose(I64 mode)
{
  CDoc *old_put=DocPut,*old_display=DocDisplay;
  CTask *old_popup=Fs->popup_task,*driver;
  U8 *header="C:/Some File.HC";
  I64 expected=mode,result;
  tm_mode=mode;tm_sent=tm_saved=tm_refresh=FALSE;tm_buttons=0;
  if(mode==1)header=NULL;
  if(mode==2)header="";
  if(mode>=10)expected=DOCM_CANCEL;
  driver=Spawn(&TMDriver,Fs,"Menu input",-1,Fs,16384);
  TMTrace("begin",mode);
  result=PopUpTermRight(header);
  TMTrace("returned",result);
  while(TaskValidate(driver))Yield;
  return result==expected && tm_sent && tm_saved && tm_refresh && tm_buttons==11 &&
    DocPut==old_put && DocDisplay==old_display && Fs->popup_task==old_popup;
}
