#ifndef I386_HEAP_INCLUDED
#define I386_HEAP_INCLUDED
#define I386_HEAP_MAGIC 0x48323349
#define I386_HEAP_FREE 0x46523349
#define I386_HEAP_USED 0x55523349
class CI386Heap
{
  U8 *base;
  U32 size,used,peak,allocations,signature;
};
class CI386HeapBlock
{
  U32 span,requested,tag,reserved;
};
#assert sizeof(CI386HeapBlock)==16
public extern Bool I386HeapInit(CI386Heap *hc,U8 *base,I64 size);
public extern Bool I386HeapValid(CI386Heap *hc);
public extern U8 *I386HeapAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE);
public extern Bool I386HeapFree(CI386Heap *hc,U8 *ptr);
public extern I64 I386HeapSize(CI386Heap *hc,U8 *ptr);
#endif
