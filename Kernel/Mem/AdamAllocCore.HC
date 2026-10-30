U8 *AMAlloc(I64 size)
{//Alloc memory in Adam's heap.
  return MAlloc(size,adam_task);
}

U8 *ACAlloc(I64 size)
{//Alloc and set to zero memory in Adam's heap.
  return CAlloc(size,adam_task);
}

U8 *AMAllocIdent(U8 *src)
{//Alloc in Adam's heap, ident copy of heap node.
  return MAllocIdent(src,adam_task);
}

U8 *AStrNew(U8 *buf)
{//Alloc copy of string in Adam's heap.
  return StrNew(buf,adam_task);
}
