#include "/Kernel/I386/MemoryPublic.HH"
//Readable live objects are required, as for the original ring-0 allocation API.
//The bootstrap allocator has different headers and cannot service these calls.
U8 *MemoryBase(U8 *ptr)
{
  I64 marker,capacity;
  U64 address=(ptr+0)(U64),distance=0;
  if(address<16) goto bad;
  marker=ptr(I64 *)[-1];
  if(marker<0) {
    if(marker<16-address(I64) || marker>-8) goto bad;
    distance=-marker; ptr+=marker;
  }
  if((ptr+0)(U64)&7 || (capacity=I386MemSize(ptr))<0 || distance>capacity) goto bad;
  return ptr;
bad:
  KernelLog("BAD PUBLIC MEMORY\n"); KernelStop;
  return 0;
}
U8 *MemoryAlloc(I64 size,CTask *selector=0)
{
  U32 flags=I386IrqSave;
  CHeapCtrl *hc;
  U8 *ptr;
  if(!selector) selector=I386TaskSelf;
  hc=selector;
  if(selector && selector->task_signature==TASK_SIGNATURE_VAL) hc=selector->data_heap;
  if(!hc || hc->hc_signature!=HEAP_CTRL_SIGNATURE_VAL || hc->locked_flags ||
      !I386MemPoolValid(hc->bp)) {
    KernelLog("BAD MALLOC HEAP\n"); KernelStop;
  }
  ptr=I386MemAlloc(hc,size);
  I386IrqRestore(flags);
  if(!ptr) throw('OutMem',TRUE);
  return ptr;
}
U0 MemoryFree(U8 *ptr)
{
  U32 flags;
  CI386PublicPool *pool;
  if(!ptr) return;
  flags=I386IrqSave;
  ptr=MemoryBase(ptr); pool=(ptr-offset(CMemUsed.start))(CMemUsed *)->hc->bp;
  if(!I386MemFree(ptr)) { KernelLog("BAD FREE\n"); KernelStop; }
  //Core Free has finished reading the page header. The provider remains live.
  if(pool->reclaim) (*pool->reclaim)(pool);
  I386IrqRestore(flags);
}
I64 MemorySize(U8 *ptr)
{
  if(!ptr) return 0;
  return I386MemSize(MemoryBase(ptr));
}
I64 MemorySize2(U8 *ptr)
{
  if(!ptr) return 0;
  return I386MemSize(MemoryBase(ptr))+offset(CMemUsed.start);
}
CHeapCtrl *MemoryHeap(U8 *ptr)
{
  if(!ptr) return 0;
  ptr=MemoryBase(ptr);
  return (ptr-offset(CMemUsed.start))(CMemUsed *)->hc;
}
U8 *MemoryCAlloc(I64 size,CTask *selector=0)
{
  U8 *ptr=MemoryAlloc(size,selector);
  I64 i;
  for(i=0;i<size;i++) ptr[i]=0;
  return ptr;
}
U8 *MemoryAligned(I64 size,I64 alignment,CTask *selector=0,I64 misalignment=0)
{
  I64 mask,total;
  U8 *ptr,*result;
  if(size<0 || size>0xFFFFFFFF || alignment<1 || alignment>0x80000000 ||
      alignment&(alignment-1) || misalignment<0 || misalignment>0xFFFFFFFF) {
    throw('OutMem',TRUE); return 0;
  }
  mask=alignment-1; total=size+mask+8+misalignment;
  ptr=MemoryAlloc(total,selector);
  result=(((ptr+0)(U64)+8+mask)&~mask)+misalignment;
  //Pointer arithmetic has target width; this marker is a signed I64 value.
  result(I64 *)[-1]=(ptr+0)(I64)-(result+0)(I64);
  return result;
}
U8 *MemoryCAligned(I64 size,I64 alignment,CTask *selector=0,I64 misalignment=0)
{
  U8 *ptr=MemoryAligned(size,alignment,selector,misalignment);
  I64 i;
  for(i=0;i<size;i++) ptr[i]=0;
  return ptr;
}

U8 *MemoryCopy(U8 *dst,U8 *src,I64 count)
{//The public MemCpy primitive copies forward; it is not MemMove.
  I64 i;
  asm { CLD }
  for(i=0;i<count;i++) dst[i]=src[i];
  return dst+count;
}
U8 *MemorySet(U8 *dst,I64 value,I64 count)
{
  I64 i;
  asm { CLD }
  for(i=0;i<count;i++) dst[i]=value;
  return dst+count;
}
I64 MemoryStrLen(U8 *src)
{
  I64 length=0;
  while(src[length]) length++;
  return length;
}
//This include is last: bind the original helpers to retained native primitives.
#define MAlloc MemoryAlloc
#define MSize MemorySize
#define MemCpy MemoryCopy
#define StrLen MemoryStrLen
#define MAllocIdent MemoryIdent
#define StrNew MemoryStrNew
#include "/Kernel/Mem/AllocCopy.HC"
