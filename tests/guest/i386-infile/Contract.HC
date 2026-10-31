U64 IFFileObserved,IFFileAddress1,IFFileAddress2;
I64 IFFileMessages()
{
  I64 a,b;
  if(ScanMsg(&a,&b,1<<2,Fs)!=2 || a!=65 || b)return FALSE;
  if(ScanMsg(&a,&b,1<<2,Fs)!=2 || a!=66 || b)return FALSE;
  return ScanMsg(&a,&b,1<<2,Fs)==0;
}
I64 IFFileContract()
{
  U8 *old=DirCur;
  I64 mask=0;
  Cd("::/Probe");
  FlushMsgs(Fs);
  InFile("InputCase");
  TaskWait;IFFileAddress1=IFFileObserved;
  if(IFFileMessages)mask|=1;
  FlushMsgs(Fs);
  InFile("InputCase.IN");
  TaskWait;IFFileAddress2=IFFileObserved;
  if(IFFileMessages)mask|=2;
  if(Fs->last_input_filter_task==Fs && Fs->next_input_filter_task==Fs &&
      !Bt(&Fs->task_flags,TASKf_FILTER_INPUT))mask|=4;
  if(!StrCmp(Fs->cur_dir,"/Probe"))mask|=8;
  Cd(old);Free(old);
  return mask;
}

I64 IFFileLowProof()
{//The repeated task reuses a slot in the boot-selected conventional arena.
  return 0x11000<=IFFileAddress1<0x88000 && IFFileAddress2==IFFileAddress1;
}
