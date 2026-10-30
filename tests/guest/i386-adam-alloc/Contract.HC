I64 aa_mask;
Bool aa_done;
U0 AAWorker(U8 *unused)
{
  U8 *a,*b,*c,*d,*empty,*src;
  I64 i; Bool ok;
  a=AMAlloc(37);b=ACAlloc(37);src=MAlloc(37);
  for(i=0;i<37;i++)src[i]=i+17;
  c=AMAllocIdent(src);d=AStrNew("Adam heap");empty=AStrNew(NULL);
  if(MHeapCtrl(a)==adam_task->data_heap && MSize(a)>=37)aa_mask|=1;
  ok=MHeapCtrl(b)==adam_task->data_heap;
  for(i=0;i<37;i++)if(b[i])ok=FALSE;
  if(ok)aa_mask|=2;
  ok=MHeapCtrl(c)==adam_task->data_heap && MSize(c)==MSize(src) && !AMAllocIdent(NULL);
  for(i=0;i<37;i++)if(c[i]!=src[i])ok=FALSE;
  if(ok)aa_mask|=4;
  if(MHeapCtrl(d)==adam_task->data_heap && !StrCmp(d,"Adam heap") &&
      MHeapCtrl(empty)==adam_task->data_heap && !*empty)aa_mask|=8;
  if(Fs!=adam_task && MHeapCtrl(src)==Fs->data_heap)aa_mask|=16;
  Free(a);Free(b);Free(c);Free(d);Free(empty);Free(src);aa_done=TRUE;
  while(TRUE)Yield;
}
I64 AAContract()
{
  CTask *worker; I64 deadline=cnts.jiffies+10000;
  aa_mask=0;aa_done=FALSE;worker=Spawn(&AAWorker,NULL,"Adam allocation",-1,Fs);
  while(!aa_done && cnts.jiffies<deadline)Yield;
  Kill(worker);return aa_mask;
}
