I64 sc_ready,sc_count;
U0 SCStart(U8 *data)
{
  CCtrl *c;
  WinScrollsInit(Fs);
  for(c=Fs->next_ctrl;c!=&Fs->next_ctrl;c=c->next)sc_count++;
  sc_ready=1;
  while(TRUE)Yield;
}
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,i;
  CTask *task;
  sc_ready=sc_count=0;
  task=Spawn(&SCStart,NULL,"OwnScroll",-1,Fs);
  for(i=0;i<1000 && !sc_ready;i++)Yield;
  if(sc_ready && sc_count==2)mask|=1;
  if(Kill(task))mask|=2;
  if(Fs->data_heap->used_u8s==base)mask|=4;
  return mask;
}
