//Original task-owned archive expansion over the retained native dictionary service.
#include "/Kernel/Arc.HH"
import U0 I386ArcEntryGet(CArcCtrl *c);
#include "/Kernel/ArcSeed.HC"
#include "/Kernel/ArcExpand.HC"
U32 NativeArcBFieldExtU32(U8 *src,I64 bit,I64 count)
{
  I64 i;U32 result=0;
  for(i=0;i<count;i++)if(src[(bit+i)>>3]&(1<<((bit+i)&7)))result|=1<<i;
  return result;
}
#define BFieldExtU32 NativeArcBFieldExtU32
#define ArcEntryGet I386ArcEntryGet
//Initialized from the native arena before public console services run.
U64 mem_mapped_space;
#include "/Kernel/ExpandBufCore.HC"
