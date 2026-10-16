class CPWState
{
  I64 count,code,a,b,sum,sleeping,order;
};
U0 PWWorker(U8 *data)
{
  CPWState *state=data;
  I64 code,a,b,i;
  while(TRUE) {
    code=GetMsg(&a,&b);
    if(state->sleeping) {state->sleeping=2;Sleep(1000);}
    else for(i=0;i<20;i++)Yield;
    state->code=code;state->a=a;state->b=b;
    state->sum+=a;state->count++;state->order=(state->order<<8)|code;
  }
}
I64 PWSelf(Bool explicit_flags)
{
  I64 a,b,code,flags=GetRFlags,ok;
  CJob *job;
  FlushMsgs;
  if(explicit_flags)PostMsgWait(Fs,MSG_CMD,123,-456,1<<JOBf_DONT_FILTER);
  else PostMsgWait(Fs,MSG_CMD,123,-456);
  job=Fs->srv_ctrl.last_waiting;
  ok=job!=&Fs->srv_ctrl.next_waiting;
  if(ok)ok=job->job_code==JOBT_MSG && job->msg_code==MSG_CMD &&
    Bt(&job->flags,JOBf_DONT_FILTER)==explicit_flags;
  code=ScanMsg(&a,&b);
  return ok && code==MSG_CMD && a==123 && b==-456 && ((GetRFlags^flags)&512)==0;
}
I64 PWContract()
{
  CPWState *state=CAlloc(sizeof(CPWState));
  CTask *worker,*invalid;
  I64 mask=0,flags,after;
  if(PWSelf(FALSE))mask|=1;
  if(PWSelf(TRUE))mask|=2;
  worker=Spawn(&PWWorker,state,"Message wait",-1,Fs);
  TaskWait(worker);
  PostMsgWait(worker,MSG_CMD,7,11);
  if(state->count==1 && state->code==MSG_CMD && state->a==7 && state->b==11 &&
      Bt(&worker->task_flags,TASKf_IDLE) &&
      worker->srv_ctrl.next_waiting==&worker->srv_ctrl.next_waiting)mask|=4;
  PostMsg(worker,MSG_CMD,13,17);
  PostMsgWait(worker,MSG_CMD,19,23,1<<JOBf_DONT_FILTER);
  if(state->count==3 && state->sum==39 && state->a==19 && state->b==23 &&
      Bt(&worker->task_flags,TASKf_IDLE))mask|=8;
  flags=GetRFlags;SetRFlags(flags&~512);
  PostMsgWait(worker,MSG_CMD,29,31);
  after=GetRFlags;SetRFlags(flags);
  if(state->count==4 && state->sum==68 && state->a==29 && state->b==31 &&
      !(after&512) && Bt(&worker->task_flags,TASKf_IDLE))mask|=16;
  PostMsgWait(worker,MSG_KEY_DOWN_UP,61,0);
  if(state->count==6 && state->sum==190 && state->code==MSG_KEY_UP &&
      state->a==61 && !state->b &&
      (state->order&65535)==((MSG_KEY_DOWN<<8)|MSG_KEY_UP))mask|=128;
  state->sleeping=1;
  PostMsgWait(worker,MSG_CMD,53,59);
  if(state->sleeping==2 && state->count==6 &&
      Bt(&worker->task_flags,TASKf_IDLE) &&
      worker->srv_ctrl.next_waiting==&worker->srv_ctrl.next_waiting)mask|=64;
  Kill(worker);Free(state);
  invalid=CAlloc(sizeof(CTask));flags=GetRFlags;
  PostMsgWait(invalid,MSG_CMD,37,41);
  PostMsgWait(NULL,MSG_CMD,43,47);
  if(!invalid->task_flags && !invalid->srv_ctrl.next_waiting &&
      ((GetRFlags^flags)&512)==0)mask|=32;
  Free(invalid);return mask;
}
