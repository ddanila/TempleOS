I64 pe_mode,pe_drive,pe_seen;
U0 PEDriver(CTask *caller)
{
  CTask *popup;CDoc *doc;
  while(TRUE) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup)) {
      doc=popup->display_doc;
      if(doc && doc->win_task==popup && StrFind("popup-ed-input",doc->filename.name)) {
        pe_seen++;
        PostMsg(popup,MSG_KEY_DOWN,'Z',0);
        if(pe_mode&1)PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
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
  U8 *name,*data,*capture,*record;I64 value,size;
  name=MStrPrint("%c:/popup-ed-input%d.DD",pe_drive,mode);
  if(mode<2)FileWrite(name,"alpha\n",6);
  pe_mode=mode;pe_seen=0;
  driver=Spawn(&PEDriver,Fs,"Popup editor input",-1,Fs,16384);
  value=PopUpEd(name,Fs,&popup);
  while(TaskValidate(driver))Yield;
  data=FileRead(name,&size);Free(name);
  capture=MStrPrint("%c:/popup-ed%d.DD",pe_drive,mode);
  if(data) {FileWrite(capture,data,size);Free(data);}
  else FileWrite(capture,"<absent>",8);
  Free(capture);
  record=MStrPrint("%d %d %d %d %d %d %d\n",value,pe_seen,!popup,DocPut==put,DocDisplay==display,DocBorder==border,Fs->popup_task==old);
  capture=MStrPrint("%c:/popup-ed-result%d.TXT",pe_drive,mode);
  FileWrite(capture,record,StrLen(record));Free(capture);Free(record);
  if(mode<2 && !value || mode>=2 && value)return FALSE;
  return pe_seen==1 && !popup && DocPut==put && DocDisplay==display &&
    DocBorder==border && Fs->popup_task==old;
}
