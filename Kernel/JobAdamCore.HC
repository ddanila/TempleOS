I64 Adam(U8 *fmt,...)
{//Make adam_task execute code.
  I64 res;
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  CJob *tmpc;
  if (Fs==adam_task) {
    tmpc=TaskExe(adam_task,Fs,buf,0);
    JobsHndlr(GetRFlags);
  } else {
    TaskWait(adam_task);
    tmpc=TaskExe(adam_task,Fs,buf,1<<JOBf_WAKE_MASTER);
  }
  JobResScan(tmpc,&res);
  Free(buf);
  return res;
}
