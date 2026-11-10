#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/I386/ParserHeapSelect.HC"
CI386HeapBlock *Reference(CI386Heap *heap,U32 need,Bool high)
{
  CI386HeapBlock *block,*selected=0;
  U32 position=0;
  while(position<heap->size) {
    block=heap->base+position;
    if(block->tag==I386_HEAP_FREE && block->span>=need) {
      selected=block;if(!high)break;
    }
    position+=block->span;
  }
  return selected;
}
Bool Pick(CI386Heap *heap,U32 need,Bool high,CI386HeapBlock *expected)
{
  U8 before[4120],*control=heap;
  I64 i;
  U32 flags=GetRFlags;
  if(heap->size>4096 || !I386HeapValid(heap))return FALSE;
  for(i=0;i<sizeof(CI386Heap);i++)before[i]=control[i];
  for(i=0;i<heap->size;i++)before[sizeof(CI386Heap)+i]=heap->base[i];
  if(I386ParserHeapSelectKnown(heap,need,high)!=expected)return FALSE;
  for(i=0;i<sizeof(CI386Heap);i++)if(before[i]!=control[i])return FALSE;
  for(i=0;i<heap->size;i++)if(before[sizeof(CI386Heap)+i]!=heap->base[i])return FALSE;
  return I386HeapValid(heap) && !((GetRFlags^flags)&0x200);
}
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;U8 *arena=0x40000,*p,*q,*r,*s,*slots[32];
  I64 i,step,index,need;
  if(!I386HeapInit(&heap,arena,256))return 700;
  if(!Pick(&heap,24,FALSE,arena) || !Pick(&heap,256,TRUE,arena) ||
      !Pick(&heap,264,FALSE,0) || !Pick(&heap,0xFFFFFFF8,TRUE,0))return 701;
  p=I386HeapAlloc(&heap,80);q=I386HeapAlloc(&heap,8);
  r=I386HeapAlloc(&heap,48);s=I386HeapAlloc(&heap,56);
  if(!p || !q || !r || !s || !I386HeapFree(&heap,p) || !I386HeapFree(&heap,r))return 702;
  if(!Pick(&heap,56,FALSE,p-16) || !Pick(&heap,56,TRUE,r-16) ||
      !Pick(&heap,80,FALSE,p-16) || !Pick(&heap,80,TRUE,p-16) ||
      !Pick(&heap,96,2,p-16) || !Pick(&heap,104,TRUE,0))return 703;
  if(!I386HeapFree(&heap,q) || !I386HeapFree(&heap,s) ||
      !Pick(&heap,256,FALSE,arena) || !Pick(&heap,256,TRUE,arena))return 704;
  p=I386HeapAlloc(&heap,240);
  if(!p || !Pick(&heap,24,FALSE,0) || !Pick(&heap,24,TRUE,0) || !I386HeapFree(&heap,p))return 705;
  if(!I386HeapInit(&heap,arena,4096))return 706;
  for(i=0;i<32;i++)slots[i]=0;
  for(step=0;step<512;step++) {
    index=(step*17+step/7)%32;
    if(slots[index]) {if(!I386HeapFree(&heap,slots[index]))return 707;slots[index]=0;}
    else slots[index]=I386HeapAlloc(&heap,(step*73)%129,TRUE);
    for(need=24;need<=280;need+=8)
      if(!Pick(&heap,need,FALSE,Reference(&heap,need,FALSE)) ||
          !Pick(&heap,need,TRUE,Reference(&heap,need,TRUE)))return 708;
  }
  for(i=0;i<32;i++)if(slots[i] && !I386HeapFree(&heap,slots[i]))return 709;
  if(heap.used || heap.allocations || !I386HeapValid(&heap))return 710;
  return 0;
}
