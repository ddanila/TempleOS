U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 key_echo_count=0,key_echo_ch=0,key_echo_sc=0,key_wait_observed=0,key_producer_done=0;
Bool CaptureKey(I64 ch,I64 sc)
{
  key_echo_count++;key_echo_ch=ch;key_echo_sc=sc;
  return TRUE;
}
U0 KeyProducer(U8 *data)
{
  CTask *target=data;
  I64 mask=1<<TASKf_IDLE|1<<TASKf_AWAITING_MSG;
  while((target->task_flags&mask)!=mask) Yield;
  key_wait_observed=1;
  PostMsg(target,MSG_KEY_DOWN,'e',0x12);
  key_producer_done=1;
}
U0 CaptureKeyInput()
{
  I64 *v=CAlloc(28*sizeof(I64)),ch=99,sc=99;
  Bool old_desc=LBtr(&Fs->win_inhibit,WIf_SELF_KEY_DESC),
       old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT),
       old_idle=LBtr(&Fs->task_flags,TASKf_IDLE),
       old_await=LBtr(&Fs->task_flags,TASKf_AWAITING_MSG);
  CKeyDevEntry *hook;
  CTask *producer;
  U8 *line;
  FlushMsgs;
  v[0]=ScanKey(&ch,&sc);v[1]=ch;v[2]=sc;
  PostMsg(Fs,MSG_KEY_UP,'u',0x9E);
  PostMsg(Fs,MSG_MS_MOVE,7,8);
  PostMsg(Fs,MSG_KEY_DOWN,'a',0x1E);
  v[3]=ScanKey(&ch,&sc);v[4]=ch;v[5]=sc;
  v[6]=ScanMsg(NULL,NULL,~1);
  PostMsg(Fs,MSG_KEY_DOWN,0,0x4B);
  v[7]=ScanKey(NULL,NULL);
  PostMsg(Fs,MSG_KEY_DOWN,0,0x48);
  v[8]=GetKey(&sc);v[9]=sc;
  hook=KeyDevAdd(&CaptureKey,NULL,10,TRUE);
  PostMsg(Fs,MSG_KEY_DOWN,'b',0x30);
  v[10]=GetKey(&sc,TRUE);v[11]=sc;
  v[12]=key_echo_count;v[13]=key_echo_ch;v[14]=key_echo_sc;
  PostMsg(Fs,MSG_KEY_DOWN,'c',0x2E|SCF_KEY_DESC);
  v[15]=ScanKey(&ch,&sc,TRUE);v[16]=ch;v[17]=sc;
  v[18]=key_echo_count;v[19]=key_echo_ch;v[20]=key_echo_sc;
  LBts(&Fs->win_inhibit,WIf_SELF_KEY_DESC);
  PostMsg(Fs,MSG_KEY_DOWN,'x',0x2D|SCF_KEY_DESC);
  PostMsg(Fs,MSG_KEY_DOWN,'d',0x20);
  v[21]=ScanKey(&ch,&sc);v[22]=ch;v[23]=sc;
  v[24]=ScanKey(NULL,NULL);
  LBtr(&Fs->task_flags,TASKf_IDLE);LBtr(&Fs->task_flags,TASKf_AWAITING_MSG);
  producer=Spawn(&KeyProducer,Fs,"Key producer",-1,Fs,8192);
  ch=GetKey(&sc,FALSE,FALSE);
  while(!key_producer_done || TaskValidate(producer)) Yield;
  v[25]=ch;v[26]=sc;
  v[27]=key_wait_observed && !Bt(&Fs->task_flags,TASKf_IDLE);
  KeyDevRem(hook);
  LBEqu(&Fs->win_inhibit,WIf_SELF_KEY_DESC,old_desc);
  LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old_silent);
  LBEqu(&Fs->task_flags,TASKf_IDLE,old_idle);
  LBEqu(&Fs->task_flags,TASKf_AWAITING_MSG,old_await);
  line=MStrPrint("EXPORT key-input.bin %X %X\n",v,28*sizeof(I64));
  Report(line);Free(line);
}
CaptureKeyInput;
Report("DONE original key input contract\n");
