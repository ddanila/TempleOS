//Shared allocation-copy behavior; primitive bindings select the target.
U8 *MAllocIdent(U8 *src,CTask *mem_task=0)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.  NULL allocs off current task's heap.
  U8 *res;
  I64 size;
  if (!src) return 0;
  size=MSize(src);
  res=MAlloc(size,mem_task);
  MemCpy(res,src,size);
  return res;
}

U8 *StrNew(U8 *buf,CTask *mem_task=0)
{//Accepts a $LK,"CTask",A="MN:CTask"$ or $LK,"CHeapCtrl",A="MN:CHeapCtrl"$.  NULL allocs off current task's heap.
  U8 *res;
  I64 size;
  if (buf) {
    size=StrLen(buf)+1;
    res=MAlloc(size,mem_task);
    MemCpy(res,buf,size);
  } else {
    res=MAlloc(1,mem_task);
    *res=0;
  }
  return res;
}

