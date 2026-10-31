U8 *PFSMarker()
{
  if(Let2Drv('B',FALSE))return "B:/PF.OUT";
  return "C:/PF.OUT";
}
U0 PFSTrace(U8 *s) {while(*s)OutU8(0xE9,*s++);}
I64 pfs_sent;
U0 PFSDriver(CTask *caller)
{
  CTask *popup; CDirEntry de;
  I64 end=cnts.jiffies+5000;
  PFSTrace("PFS DRIVER START\n");
  while(cnts.jiffies<end) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) &&
        Bt(&popup->task_flags,TASKf_CMD_LINE_PMT) &&
        FileFind(PFSMarker,&de,FUF_JUST_FILES)) {
      Free(de.full_name);
      PFSTrace("PFS SEND\n");
      pfs_sent=TRUE;
      PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
      PFSTrace("PFS POST RETURN\n");
      if(TaskValidate(popup))PFSTrace("PFS VALID IMMEDIATE\n");
      else PFSTrace("PFS RETIRED IMMEDIATE\n");
      Yield;
      PFSTrace("PFS YIELD RETURN\n");
      end=cnts.jiffies+2000;
      while(cnts.jiffies<end && TaskValidate(popup))Yield;
      if(TaskValidate(popup))PFSTrace("PFS POPUP STILL VALID\n");
      else PFSTrace("PFS POPUP RETIRED\n");
      return;
    }
    Yield;
  }
  PFSTrace("PFS DRIVER TIMEOUT\n");
}
I64 PopUpFileSyncContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old=Fs->popup_task,*popup=NULL,*driver;
  I64 result,mask=0;
  pfs_sent=0;
  driver=Spawn(&PFSDriver,Fs,"PopUpFile exit driver",-1,Fs,16384);
  PFSTrace("PFS CALL\n");
  result=PopUpFile("::/Probe/PFCase",FALSE,Fs,&popup);
  PFSTrace("PFS RETURN\n");
  while(TaskValidate(driver))Yield;
  if(pfs_sent)mask|=1;
  if(!popup)mask|=2;
  if(Fs->popup_task==old)mask|=4;
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  if(result==0)mask|=16;
  return mask;
}
