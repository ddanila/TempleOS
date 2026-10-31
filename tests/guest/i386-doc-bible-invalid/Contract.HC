I64 BibleInvalidContract()
{
  I64 before=Fs->data_heap->used_u8s,mask=0,i;Bool ok=TRUE;U8 *p;
  for(i=0;i<3;i++)if(Ed("BF:NoSuchBook,1:1",EDF_BAIL))ok=FALSE;
  if(ok)mask|=1;
  p=MAlloc(32);if(p) {MemSet(p,0x5A,32);if(p[31]==0x5A)mask|=2;Free(p);}
  if(Fs->data_heap->used_u8s==before)mask|=4;
  return mask;
}
