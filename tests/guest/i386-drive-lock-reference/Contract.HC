Bool LKFour(U8 *data,U8 *expected){I64 i;for(i=0;i<4;i++)if(data[i]!=expected[i])return FALSE;return TRUE;}
I64 LKStage,LKResult,LKMode,LKRelease;
CBlkDev *LKDevice;
CDrv *LKDrive;
U8 *LKPath;
U0 LKChild(U8 *unused)
{
 U8 *data;I64 size;
 LKStage=1;
 if(LKMode==0)LKResult=!BlkDevUnlock(LKDevice);
 else if(LKMode==1){
  LKResult=BlkDevLock(LKDevice)&&LKDevice->owning_task==Fs;
  LKStage=2;while(!LKRelease)Yield;
  LKResult=LKResult&&BlkDevUnlock(LKDevice);
 }else if(LKMode==2){
  data=FileRead(LKPath,&size);
  LKResult=data&&size==4&&LKFour(data,"lock");Free(data);
 }else if(LKMode==3){
  LKResult=BlkDevLock(LKDevice)&&LKDevice->owning_task==Fs;
 }else if(LKMode==4){
  LKResult=DrvLock(LKDrive)&&LKDrive->owning_task==Fs&&LKDevice->owning_task==Fs;
 }else if(LKMode==5)LKResult=FileWrite(LKPath,"next",4)>0;
 LKStage=3;
}
Bool LKWait(I64 stage)
{
 I64 end=cnts.jiffies+2000;
 while(LKStage<stage&&cnts.jiffies<end)Yield;
 return LKStage>=stage;
}
Bool LKSetup(U8 letter)
{
 U8 *dir=MStrPrint("%c:/",letter);Bool ok=Cd(dir);Free(dir);
 DirMk("Probe");Cd("Probe");DirMk("DriveLock");ok=ok&&Cd("DriveLock");
 LKPath=FileNameAbs("Contract.TXT");
 LKDrive=Let2Drv(letter);LKDevice=LKDrive->bd;
 return ok&&FileWrite(LKPath,"lock",4)>0;
}
I64 LKContract(I64 mode)
{
 CDirEntry entry;
 CBlkDev a,b,c;CTask *child=NULL;I64 i,m=0,before=Fs->data_heap->used_u8s;
 I64 device_flags=LKDevice->flags;
 Bool ok=FALSE,held=FALSE,caught=FALSE;U8 *data;I64 size;
 CDrv *drive=Fs->cur_dv;U8 *directory=StrNew(Fs->cur_dir);
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 MemCpy(&a,LKDevice,sizeof(CBlkDev));a.locked_flags=0;a.owning_task=NULL;a.lock_fwding=NULL;
 MemCpy(&b,&a,sizeof(CBlkDev));MemCpy(&c,&a,sizeof(CBlkDev));
 if(mode==0){ok=BlkDevLock(&a)&&a.owning_task==Fs&&Bt(&a.locked_flags,BDlf_LOCKED);
  ok=ok&&!BlkDevLock(&a)&&BlkDevUnlock(&a)&&!a.owning_task&&!a.locked_flags&&!BlkDevUnlock(&a);}
 else if(mode==1){a.flags=BDF_INITIALIZED|BDF_INIT_IN_PROGRESS|BDF_READ_ONLY|BDF_REMOVABLE;
  BlkDevLock(&a);ok=BlkDevUnlock(&a,TRUE)&&a.flags==(BDF_READ_ONLY|BDF_REMOVABLE);}
 else if(mode==2){a.lock_fwding=&b;b.lock_fwding=&c;
  ok=BlkDevLock(&a)&&c.owning_task==Fs&&!a.owning_task&&!b.owning_task;
  ok=ok&&!BlkDevLock(&b)&&BlkDevUnlock(&a)&&!c.owning_task&&!c.locked_flags;}
 else if(mode==3){a.bd_signature=0;try{BlkDevLock(&a);}catch{caught=Fs->except_ch=='BlkDev';Fs->catch_except=TRUE;}
  ok=caught;caught=FALSE;try{BlkDevUnlock(NULL);}catch{caught=Fs->except_ch=='BlkDev';Fs->catch_except=TRUE;}ok=ok&&caught;}
 else if(mode==4||mode==5||mode==6||mode==9){
  LKStage=LKResult=LKRelease=0;LKMode=0;
  if(mode==5)LKMode=1;else if(mode==6)LKMode=2;else if(mode==9)LKMode=5;
  held=BlkDevLock(LKDevice);child=Spawn(&LKChild,NULL,"Lock contender",-1,Fs);
  ok=held&&child&&LKWait(1);
  for(i=0;i<20;i++)Yield;
  if(mode==4){ok=ok&&LKWait(3)&&LKResult&&LKDevice->owning_task==Fs;}
  else ok=ok&&LKStage==1&&!LKResult&&LKDevice->owning_task==Fs;
  if(held){BlkDevUnlock(LKDevice);held=FALSE;}
  if(mode==5){ok=ok&&LKWait(2)&&LKDevice->owning_task==child;LKRelease=1;}
  ok=ok&&LKWait(3);while(TaskValidate(child))Yield;
  ok=ok&&LKResult&&!LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  if(mode==9){data=FileRead(LKPath,&size);ok=ok&&data&&size==4&&LKFour(data,"next");Free(data);}
 }else if(mode==7||mode==8){
  LKStage=LKResult=0;LKMode=3;if(mode==8)LKMode=4;
  child=Spawn(&LKChild,NULL,"Lock owner exit",-1,Fs);ok=child&&LKWait(3);
  while(TaskValidate(child))Yield;
  ok=ok&&LKResult&&!LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  if(mode==8)ok=ok&&!LKDrive->owning_task&&!Bt(&LKDrive->locked_flags,DVlf_LOCKED);
 }
 if(mode==10){
  LKStage=LKResult=LKRelease=0;LKMode=1;
  child=Spawn(&LKChild,NULL,"Killed lock owner",-1,Fs);
  ok=child&&LKWait(2)&&LKDevice->owning_task==child;
  Kill(child);while(TaskValidate(child))Yield;
  ok=ok&&LKResult&&!LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED);
 }
 if(mode==11||mode==12){
  LKStage=LKResult=LKRelease=0;LKMode=1;if(mode==12)LKMode=2;
  held=BlkDevLock(LKDevice);child=Spawn(&LKChild,NULL,"Killed lock waiter",-1,Fs);
  ok=held&&child&&LKWait(1);for(i=0;i<20;i++)Yield;
  ok=ok&&LKStage==1&&!LKResult&&LKDevice->owning_task==Fs;
  Kill(child);while(TaskValidate(child))Yield;
  ok=ok&&LKDevice->owning_task==Fs&&Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  if(held)ok=BlkDevUnlock(LKDevice)&&ok;
 }
 if(mode==13){
  held=BlkDevLock(LKDevice);data=FileRead(LKPath,&size);
  ok=held&&data&&size==4&&!LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  Free(data);if(LKDevice->owning_task==Fs)BlkDevUnlock(LKDevice);
 }
 if(14<=mode<=17){
  held=DrvLock(LKDrive);ok=held;
  if(mode==15||mode==17)ok=BlkDevUnlock(LKDevice)&&ok;
  if(mode<16){
   data=FileRead(LKPath,&size);ok=ok&&data&&size==4;Free(data);
  }else ok=ok&&FileWrite(LKPath,"more",4)>0;
  ok=ok&&!LKDrive->owning_task&&!Bt(&LKDrive->locked_flags,DVlf_LOCKED)&&
    !LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  if(LKDrive->owning_task==Fs)DrvUnlock(LKDrive);
  if(LKDevice->owning_task==Fs)BlkDevUnlock(LKDevice);
 }
 if(mode==18||mode==19){
  held=DrvLock(LKDrive);ok=held;
  if(mode==19)ok=BlkDevUnlock(LKDevice)&&ok;
  ok=ok&&FileFind(LKPath,&entry,FUF_JUST_FILES);
  Free(entry.full_name);
  ok=ok&&LKDrive->owning_task==Fs&&Bt(&LKDrive->locked_flags,DVlf_LOCKED)&&
    LKDevice->owning_task==Fs&&Bt(&LKDevice->locked_flags,BDlf_LOCKED);
  if(LKDrive->owning_task==Fs)DrvUnlock(LKDrive);
  if(LKDevice->owning_task==Fs)BlkDevUnlock(LKDevice);
 }
 //Keep lock cases independent of interrupted media initialization. Original
 //RAM-drive entry can set INIT_IN_PROGRESS before waiting on the device lock.
 LKDevice->flags=device_flags;
 if(ok)m|=1;
 if(Fs->cur_dv==drive&&!StrCmp(Fs->cur_dir,directory))m|=2;
 if(!LKDevice->owning_task&&!Bt(&LKDevice->locked_flags,BDlf_LOCKED))m|=4;
 if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 Free(directory);
 if(Fs->data_heap->used_u8s==before)m|=16;
 return m;
}
I64 LKCheck(I64 mode){I64 m=LKContract(mode);if(m!=31)throw('DrvLock',TRUE);return m;}
