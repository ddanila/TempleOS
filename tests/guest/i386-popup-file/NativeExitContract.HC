//The observer is a sibling of the caller, so popup exit cannot kill it.
CTask *pfn_caller,*pfn_driver;
I64 pfn_result,pfn_returned;
U8 *PFNMarker()
{
  if(Let2Drv('B',FALSE))return "B:/PF.OUT";
  return "C:/PF.OUT";
}
U0 PFNCaller(U8 *unused)
{
  CTask *popup=NULL;
  PopUpFile("::/Probe/PFCase",FALSE,Fs,&popup);
  pfn_returned=TRUE;
}
U0 PFNDriver(U8 *unused)
{
  CTask *popup; CDirEntry de;
  I64 end=cnts.jiffies+10000,i;
  while(cnts.jiffies<end) {
    popup=pfn_caller->popup_task;
    if(popup && TaskValidate(popup) &&
        Bt(&popup->task_flags,TASKf_CMD_LINE_PMT) &&
        FileFind(PFNMarker,&de,FUF_JUST_FILES)) {
      Free(de.full_name);
      pfn_result|=1;
      PostMsg(popup,MSG_KEY_DOWN,CH_SHIFT_ESC,0);
      for(i=0;i<2000 && (TaskValidate(popup) || TaskValidate(pfn_caller));i++)Yield;
      if(!TaskValidate(popup))pfn_result|=2;
      if(!TaskValidate(pfn_caller))pfn_result|=4;
      if(!pfn_returned)pfn_result|=8;
      return;
    }
    Yield;
  }
}
I64 PFNativeStart()
{
  pfn_result=pfn_returned=0;
  pfn_caller=Spawn(&PFNCaller,NULL,"Popup caller",-1,Fs,0);
  pfn_driver=Spawn(&PFNDriver,NULL,"Popup observer",-1,Fs,16384);
  return pfn_caller && pfn_driver;
}
I64 PFNativeWait()
{
  I64 end=cnts.jiffies+15000;
  while(TaskValidate(pfn_driver) && cnts.jiffies<end)Yield;
  return pfn_result;
}
