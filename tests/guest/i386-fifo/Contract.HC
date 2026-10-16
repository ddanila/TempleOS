Bool FQIRQ(Bool enabled){return ((GetRFlags>>9)&1)==enabled;}
I64 FQU8(Bool enabled)
{
  I64 before=Fs->data_heap->used_u8s,flags=GetRFlags,i;
  CFifoU8 *f;
  U8 value=0,expected;
  Bool ok=TRUE;
  if(enabled)f=FifoU8New(8,Fs);else f=FifoU8New(8);
  if(MHeapCtrl(f)!=Fs->data_heap || MHeapCtrl(f->buf)!=Fs->data_heap)ok=FALSE;
  if(f->mask!=7 || FifoU8Cnt(f))ok=FALSE;
  if(enabled)SetRFlags(flags|512);else SetRFlags(flags&~512);
  value=77;
  if(FifoU8Rem(f,&value) || value!=77 || !FQIRQ(enabled))ok=FALSE;
  if(FifoU8Peek(f,&value) || value!=77 || !FQIRQ(enabled))ok=FALSE;
  for(i=0;i<7;i++)if(!FifoU8Ins(f,0+i) || !FQIRQ(enabled))ok=FALSE;
  if(FifoU8Ins(f,99) || !FQIRQ(enabled))ok=FALSE;
  if(FifoU8Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  if(!FifoU8Peek(f,&value) || value!=0 || FifoU8Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  for(i=0;i<3;i++) {
    expected=0+i;
    if(!FifoU8Rem(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
  }
  for(i=7;i<10;i++)if(!FifoU8Ins(f,0+i) || !FQIRQ(enabled))ok=FALSE;
  if(FifoU8Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  for(i=3;i<10;i++) {
    expected=0+i;
    if(!FifoU8Peek(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
    if(!FifoU8Rem(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
  }
  if(FifoU8Cnt(f) || !FQIRQ(enabled))ok=FALSE;
  if(!FifoU8Ins(f,42) || !FifoU8Ins(f,43))ok=FALSE;
  FifoU8Flush(f);
  if(FifoU8Cnt(f) || !FQIRQ(enabled))ok=FALSE;
  if(!FifoU8Ins(f,44) || !FifoU8Rem(f,&value) || value!=44 || !FQIRQ(enabled))ok=FALSE;
  FifoU8Flush(f);if(!FQIRQ(enabled))ok=FALSE;
  SetRFlags(flags);FifoU8Del(f);
  f=FifoU8New(1);
  if(FifoU8Ins(f,1) || FifoU8Cnt(f))ok=FALSE;
  FifoU8Del(f);
  return ok && Fs->data_heap->used_u8s==before && ((GetRFlags^flags)&512)==0;
}
I64 FQI64(Bool enabled)
{
  I64 before=Fs->data_heap->used_u8s,flags=GetRFlags,i;
  CFifoI64 *f;
  I64 value=0,expected;
  Bool ok=TRUE;
  if(enabled)f=FifoI64New(8,Fs);else f=FifoI64New(8);
  if(MHeapCtrl(f)!=Fs->data_heap || MHeapCtrl(f->buf)!=Fs->data_heap)ok=FALSE;
  if(f->mask!=7 || FifoI64Cnt(f))ok=FALSE;
  if(enabled)SetRFlags(flags|512);else SetRFlags(flags&~512);
  value=77;
  if(FifoI64Rem(f,&value) || value!=77 || !FQIRQ(enabled))ok=FALSE;
  if(FifoI64Peek(f,&value) || value!=77 || !FQIRQ(enabled))ok=FALSE;
  for(i=0;i<7;i++)if(!FifoI64Ins(f,0xFEDCBA9800000000+i) || !FQIRQ(enabled))ok=FALSE;
  if(FifoI64Ins(f,99) || !FQIRQ(enabled))ok=FALSE;
  if(FifoI64Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  if(!FifoI64Peek(f,&value) || value!=0xFEDCBA9800000000 || FifoI64Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  for(i=0;i<3;i++) {
    expected=0xFEDCBA9800000000+i;
    if(!FifoI64Rem(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
  }
  for(i=7;i<10;i++)if(!FifoI64Ins(f,0xFEDCBA9800000000+i) || !FQIRQ(enabled))ok=FALSE;
  if(FifoI64Cnt(f)!=7 || !FQIRQ(enabled))ok=FALSE;
  for(i=3;i<10;i++) {
    expected=0xFEDCBA9800000000+i;
    if(!FifoI64Peek(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
    if(!FifoI64Rem(f,&value) || value!=expected || !FQIRQ(enabled))ok=FALSE;
  }
  if(FifoI64Cnt(f) || !FQIRQ(enabled))ok=FALSE;
  if(!FifoI64Ins(f,42) || !FifoI64Ins(f,43))ok=FALSE;
  FifoI64Flush(f);
  if(FifoI64Cnt(f) || !FQIRQ(enabled))ok=FALSE;
  if(!FifoI64Ins(f,44) || !FifoI64Rem(f,&value) || value!=44 || !FQIRQ(enabled))ok=FALSE;
  FifoI64Flush(f);if(!FQIRQ(enabled))ok=FALSE;
  SetRFlags(flags);FifoI64Del(f);
  f=FifoI64New(1);
  if(FifoI64Ins(f,1) || FifoI64Cnt(f))ok=FALSE;
  FifoI64Del(f);
  return ok && Fs->data_heap->used_u8s==before && ((GetRFlags^flags)&512)==0;
}
Bool fq_ready=FALSE;
U0 FQIdle(U8 *data){fq_ready=TRUE;while(TRUE)Yield;}
I64 FQOwner()
{
  CTask *owner;CFifoU8 *a;CFifoI64 *b;I64 before;Bool ok;
  fq_ready=FALSE;owner=Spawn(&FQIdle,NULL,"FIFO owner",-1,Fs);
  while(!fq_ready)Yield;
  before=owner->data_heap->used_u8s;
  a=FifoU8New(16,owner);b=FifoI64New(16,owner);
  ok=MHeapCtrl(a)==owner->data_heap && MHeapCtrl(a->buf)==owner->data_heap &&
    MHeapCtrl(b)==owner->data_heap && MHeapCtrl(b->buf)==owner->data_heap;
  FifoU8Del(a);FifoI64Del(b);
  ok=ok&&owner->data_heap->used_u8s==before;
  Kill(owner);return ok;
}
U0 FQProduceU8(U8 *data)
{
  CFifoU8 *f=data;I64 i;
  for(i=0;i<256;i++)while(!FifoU8Ins(f,0+i))Yield;
}
I64 FQTransferU8()
{
  CFifoU8 *f=FifoU8New(8);
  CTask *producer=Spawn(&FQProduceU8,f,"FIFO producer",-1,Fs);
  I64 i,deadline=cnts.jiffies+10000;
  U8 value,expected;Bool ok=TRUE;
  for(i=0;i<256;i++) {
    while(!FifoU8Rem(f,&value)) {
      if(cnts.jiffies>deadline) {ok=FALSE;goto fq_done;}
      Yield;
    }
    expected=0+i;if(value!=expected)ok=FALSE;
  }
  if(FifoU8Cnt(f))ok=FALSE;
fq_done:
  if(TaskValidate(producer))Kill(producer);
  FifoU8Del(f);return ok;
}
U0 FQProduceI64(U8 *data)
{
  CFifoI64 *f=data;I64 i;
  for(i=0;i<256;i++)while(!FifoI64Ins(f,0x1234567800000000+i))Yield;
}
I64 FQTransferI64()
{
  CFifoI64 *f=FifoI64New(8);
  CTask *producer=Spawn(&FQProduceI64,f,"FIFO producer",-1,Fs);
  I64 i,deadline=cnts.jiffies+10000;
  I64 value,expected;Bool ok=TRUE;
  for(i=0;i<256;i++) {
    while(!FifoI64Rem(f,&value)) {
      if(cnts.jiffies>deadline) {ok=FALSE;goto fq_done;}
      Yield;
    }
    expected=0x1234567800000000+i;if(value!=expected)ok=FALSE;
  }
  if(FifoI64Cnt(f))ok=FALSE;
fq_done:
  if(TaskValidate(producer))Kill(producer);
  FifoI64Del(f);return ok;
}
I64 FQContract()
{
  I64 mask=0;
  if(FQU8(FALSE))mask|=1;
  if(FQU8(TRUE))mask|=2;
  if(FQI64(FALSE))mask|=4;
  if(FQI64(TRUE))mask|=8;
  if(FQOwner)mask|=16;
  if(FQTransferU8)mask|=32;
  if(FQTransferI64)mask|=64;
  return mask;
}
