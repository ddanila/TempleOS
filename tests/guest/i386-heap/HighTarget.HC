#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
extern U8 *I386HeapAllocHigh(CI386Heap *heap,I64 size,Bool zero=FALSE);
CI386Heap high_heap;
U8 *high_persistent[1024],*high_transient[1024];
U64 HighHash(U8 *bytes,I64 count)
{
  U64 hash=0x123456789ABCDEF0;I64 i;
  for(i=0;i<count;i++)hash=(hash<<5)^(hash>>59)^bytes[i];
  return hash;
}
I64 Main(I64 unused_a,I64 unused_b)
{
  CI386Heap *heap=&high_heap;
  U8 *stack,*p,*t;
  CI386HeapBlock *block;
  I64 phase,i,j;
  U64 arena_hash,control_hash;
  //The identical live workload must recover a 64 KiB block only when its
  //temporary records are separated from durable payloads. No payload moves.
  for(phase=0;phase<2;phase++) {
    if(!I386HeapInit(heap,0x40000,196608))return 501;
    for(i=0;i<1024;i++) {
      p=high_persistent[i]=I386HeapAlloc(heap,80);
      if(!phase)t=I386HeapAlloc(heap,64,TRUE);
      else t=I386HeapAllocHigh(heap,64,TRUE);
      high_transient[i]=t;
      if(!p || !t || I386HeapSize(heap,t)!=64 || (t+0)(U64)&7)return 502;
      for(j=0;j<64;j++)if(t[j])return 503;
      for(j=0;j<80;j++)p[j]=i+j;
      for(j=0;j<64;j++)t[j]=i^j;
      if(phase && p+80>t)return 504;
    }
    for(i=0;i<1024;i++)if(!I386HeapFree(heap,high_transient[i]))return 505;
    stack=I386HeapAlloc(heap,65536,TRUE);
    if(!phase && stack || phase && !stack)return 506;
    if(stack) {
      for(j=0;j<65536;j++)if(stack[j])return 507;
      if(!I386HeapFree(heap,stack))return 508;
    }
    for(i=0;i<1024;i++) {
      p=high_persistent[i];
      for(j=0;j<80;j++)if(p[j]!=(i+j)(U8))return 509;
    }
    arena_hash=HighHash(heap->base,heap->size);control_hash=HighHash(heap,sizeof(CI386Heap));
    if(I386HeapAllocHigh(0,1) || I386HeapAllocHigh(heap,-1) ||
        I386HeapAllocHigh(heap,0x100000000) || I386HeapAllocHigh(heap,heap->size) ||
        HighHash(heap->base,heap->size)!=arena_hash ||
        HighHash(heap,sizeof(CI386Heap))!=control_hash)return 510;
    //A later corrupt header must reject allocation before any earlier block changes.
    block=heap->base;
    while((block+0)(U64)+block->span<(heap->base+0)(U64)+heap->size)
      block=block(U8 *)+block->span;
    block->reserved=1;
    arena_hash=HighHash(heap->base,heap->size);
    if(I386HeapAllocHigh(heap,8) || HighHash(heap->base,heap->size)!=arena_hash ||
        HighHash(heap,sizeof(CI386Heap))!=control_hash)return 511;
    block->reserved=0;
    for(i=0;i<1024;i++)if(!I386HeapFree(heap,high_persistent[i]))return 512;
    if(heap->used || heap->allocations || !I386HeapValid(heap))return 513;
  }
  //A tiny free prefix is absorbed; a zero-byte request still owns a valid block.
  if(!I386HeapInit(heap,0x40000,512) || !(p=I386HeapAllocHigh(heap,481,TRUE)) ||
      p!=heap->base+16 || heap->used!=512 || I386HeapSize(heap,p)!=481 ||
      !I386HeapFree(heap,p) || !(p=I386HeapAllocHigh(heap,0)) ||
      I386HeapSize(heap,p)!=0 || !I386HeapFree(heap,p) || heap->used ||
      heap->allocations || !I386HeapValid(heap))return 514;
  return 0;
}
