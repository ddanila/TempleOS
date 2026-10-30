I64 pe_mode,pe_drive,pe_seen;
U0 PEDriver(CTask *caller)
{
  CTask *popup;CDoc *doc;
  while(TRUE) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) && Bt(&popup->task_flags,TASKf_AWAITING_MSG)) {
      doc=popup->display_doc;
      if(doc && doc->win_task==popup && doc->desc!='Menu') {
        pe_seen++;
        PostMsg(popup,MSG_KEY_DOWN,'Z',0);
        if(pe_mode)PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
        else PostMsg(popup,MSG_KEY_DOWN,CH_ESC,0);
        return;
      }
    }
    Yield;
  }
}
I64 PECheck(I64 mode)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old=Fs->popup_task,*popup=NULL,*driver;
  U8 *name,*data,*capture;I64 value,size;
  name=MStrPrint("%c:/popup-ed-input.DD",pe_drive);
  FileWrite(name,"alpha\n",6);pe_mode=mode;pe_seen=0;
  driver=Spawn(&PEDriver,Fs,"Popup editor input",-1,Fs,16384);
  value=PopUpEd(name,Fs,&popup);
  while(TaskValidate(driver))Yield;
  data=FileRead(name,&size);Free(name);
  if(!data)return FALSE;
  capture=MStrPrint("%c:/popup-ed%d.DD",pe_drive,mode);
  FileWrite(capture,data,size);Free(capture);Free(data);
  if(!value)return FALSE;
  return pe_seen==1 && !popup && DocPut==put && DocDisplay==display &&
    DocBorder==border && Fs->popup_task==old;
}
