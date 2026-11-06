Bool tc_ready;
U8 *tc_self_pc;
U0 TCSelf() {tc_self_pc=TaskCaller(NULL,0);}
U0 TCSleep() {tc_ready=TRUE;while(TRUE)Sleep(1000);}
U0 TCWorker(U8 *unused) {TCSleep;}
U0 TCLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
Bool TCWithin(U8 *pc,U8 *name)
{
  CHashFun *f=HashFind(name,Fs->hash_table,HTT_FUN);
  CDbgInfo *dbg;
  if(!f || !(dbg=f->dbg_info))return FALSE;
  return dbg->body[0]<=(pc+0)(U64)<dbg->body[dbg->max_line+1-dbg->min_line];
}
U0 TCCheck()
{
  I64 values[7],end,i;U8 *pc,*s;CTask *child;
  MemSet(values,0,sizeof(values));
  TCSelf;values[0]=TCWithin(tc_self_pc,"TCSelf");
  tc_ready=FALSE;child=Spawn(&TCWorker,NULL,"caller",-1,Fs,16384);
  end=cnts.jiffies+5000;
  while(child && TaskValidate(child) && !tc_ready && cnts.jiffies<end)Yield;
  if(child && TaskValidate(child) && tc_ready) {
    Suspend(child,TRUE);
    values[1]=TaskCaller(child,0,TRUE)!=NULL;
    values[4]=1;
    for(i=0;i<32;i++) {
      pc=TaskCaller(child,i,TRUE);
      if(pc!=TaskCaller(child,i,FALSE))values[4]=0;
      if(TCWithin(pc,"TCSleep"))values[2]=1;
      if(TCWithin(pc,"TCWorker"))values[3]=1;
    }
    values[5]=TaskCaller(child,128,TRUE)==NULL;
    Kill(child);
    end=cnts.jiffies+5000;
    while(TaskValidate(child) && cnts.jiffies<end)Yield;
    values[6]=!TaskValidate(child);
  }
  s=MStrPrint("EXPORT callers.bin %X %X\n",values,sizeof(values));TCLog(s);Free(s);
  TCLog("TASK CALLER DONE\n");Sleep(1000);
}
