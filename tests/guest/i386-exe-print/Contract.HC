I64 EPValue=40;
I64 JRContract()
{
  I64 mask=0,base,i;
  if(ExePrint("6*7;")==42)mask|=1;
  if(ExePrint("%d+%d;",19,23)==42)mask|=2;
  if(ExePrint("EPValue+2;")==42)mask|=4;
  if(ExePrint("EPValue=%d;",41)==41 && EPValue==41)mask|=8;
  if(ExePrint("%s;","EPValue+1")==42)mask|=16;
  base=Fs->data_heap->used_u8s;
  for(i=0;i<10;i++)ExePrint("%d+2;",40);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  EPValue=40;
  return mask;
}
