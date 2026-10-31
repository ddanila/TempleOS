U8 *PFMarker()
{
  if(Let2Drv('B',FALSE))return "B:/PF.OUT";
  return "C:/PF.OUT";
}
Bool PFWait(I64 expected)
{
  I64 end=cnts.jiffies+5000,size;
  CDirEntry de;U8 *data;
  while(cnts.jiffies<end) {
    if(FileFind(PFMarker,&de,FUF_JUST_FILES)) {
      Free(de.full_name);
      data=FileRead(PFMarker,&size);
      if(data) {
        if(size==1 && *data==expected) {Free(data);return TRUE;}
        Free(data);
      }
    }
    Yield;
  }
  return FALSE;
}
I64 PopUpFileContract()
{
  CTask *popup=NULL,*old=Fs->popup_task;
  I64 mask=0,i;
  PopUpFile("::/Probe/PFCase",FALSE,NULL,&popup);
  if(popup && TaskValidate(popup) && PFWait('1'))mask|=1;
  if(popup && TaskValidate(popup))Kill(popup);
  for(i=0;i<1000 && TaskValidate(popup);i++)Yield;
  if(!TaskValidate(popup))mask|=2;
  popup=NULL;
  PopUpFile("::/Probe/PFCase.HC",FALSE,NULL,&popup);
  if(popup && TaskValidate(popup) && PFWait('2'))mask|=4;
  if(popup && TaskValidate(popup))Kill(popup);
  for(i=0;i<1000 && TaskValidate(popup);i++)Yield;
  if(!TaskValidate(popup))mask|=8;
  if(Fs->popup_task==old)mask|=16;
  return mask;
}
