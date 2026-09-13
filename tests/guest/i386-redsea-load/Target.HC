#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/ModuleFile.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v;
  CI386RedSeaEntry entry,bad;
  CI386Heap heap;
  U8 *image,*reuse,*reserve;
  I64 i,j;
  I64 (*entry_point)(I64 x,I64 y);
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      !I386HeapInit(&heap,(0x40000)(U8 *),65536) ||
      I386RedSeaFind(&v,v.root,"Good.T32M",&entry)!=1 || entry.size>=2048) return 1;
  if (I386RedSeaLoad(0,&entry,&heap,"Main") || I386RedSeaLoad(&v,0,&heap,"Main") ||
      I386RedSeaLoad(&v,&entry,0,"Main") || I386RedSeaLoad(&v,&entry,&heap,0) ||
      I386RedSeaLoad(&v,&entry,&heap,"Missing")) return 2;
  entry.attr|=0x400;
  if (I386RedSeaLoad(&v,&entry,&heap,"Main")) return 3;
  entry.attr=0x800;
  if (I386RedSeaFind(&v,v.root,"Wrong.T32M",&bad)!=1 || I386RedSeaLoad(&v,&bad,&heap,"Main") ||
      I386RedSeaFind(&v,v.root,"Short.T32M",&bad)!=1 || I386RedSeaLoad(&v,&bad,&heap,"Main") ||
      I386RedSeaFind(&v,v.root,"Tiny.T32M",&bad)!=1 || I386RedSeaLoad(&v,&bad,&heap,"Main") ||
      heap.used || heap.allocations || !I386HeapValid(&heap)) return 4;
  reserve=I386HeapAlloc(&heap,65520);
  if (!reserve || I386RedSeaLoad(&v,&entry,&heap,"Main") || heap.allocations!=1 ||
      !I386HeapFree(&heap,reserve)) return 5;
  //Leave room for the complete file buffer but none for the resulting image.
  reserve=I386HeapAlloc(&heap,65504-((entry.size+7)&~7));
  if (!reserve || I386RedSeaLoad(&v,&entry,&heap,"Main") || heap.allocations!=1 ||
      !I386HeapFree(&heap,reserve) || heap.used) return 6;
  disk.sectors=32769; v.sectors=32769-v.start;
  bad.attr=0x800; bad.block=32767; bad.size=1024;
  if (I386RedSeaLoad(&v,&bad,&heap,"Main") || heap.used || heap.allocations) return 7;
  disk.sectors=32768; v.sectors=128;
  for (j=0;j<2;j++) {
    image=I386RedSeaLoad(&v,&entry,&heap,"Main");
    if (!image || heap.allocations!=1 || I386HeapSize(&heap,image)<8) return 8;
    entry_point=image;
    if ((*entry_point)(17,25)!=0x10000002A) return 9;
    reuse=I386HeapAlloc(&heap,entry.size);
    if (reuse!=(0x40010)(U8 *)) return 10; //The released first file allocation.
    for (i=0;i<entry.size;i++) reuse[i]=0xA5;
    if ((*entry_point)(1,2)!=0x100000014 || !I386HeapFree(&heap,reuse) ||
        !I386HeapFree(&heap,image) || heap.used || heap.allocations || !I386HeapValid(&heap))
      return 11;
  }
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/ModuleFile.HC"
