#include "/Kernel/I386/HeapIrq.HH"
#include "/Kernel/I386/Cpu.HH"
//Link Heap.HC and Cpu.HC once. Every user of a shared heap must serialize access.
//One CPU; no NMI allocation, yielding, or exception recovery inside these calls.
public Bool I386HeapIrqInit(CI386Heap *hc,U8 *base,I64 size)
{//Initialization still requires exclusive ownership and no live allocations.
  U32 flags=I386IrqSave;
  Bool result=I386HeapInit(hc,base,size);
  I386IrqRestore(flags);
  return result;
}
public Bool I386HeapIrqValid(CI386Heap *hc)
{
  U32 flags=I386IrqSave;
  Bool result=I386HeapValid(hc);
  I386IrqRestore(flags);
  return result;
}
public U8 *I386HeapIrqAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE)
{//Whole validation, mutation and optional zeroing run with IF clear.
  U32 flags=I386IrqSave;
  U8 *result=I386HeapAlloc(hc,size,zero);
  I386IrqRestore(flags);
  return result;
}
public Bool I386HeapIrqFree(CI386Heap *hc,U8 *ptr)
{
  U32 flags=I386IrqSave;
  Bool result=I386HeapFree(hc,ptr);
  I386IrqRestore(flags);
  return result;
}
public I64 I386HeapIrqSize(CI386Heap *hc,U8 *ptr)
{
  U32 flags=I386IrqSave;
  I64 result=I386HeapSize(hc,ptr);
  I386IrqRestore(flags);
  return result;
}
