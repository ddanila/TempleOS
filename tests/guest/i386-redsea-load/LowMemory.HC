#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/ModuleFile.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;CI386RedSea v;CI386RedSeaEntry entry;
  CI386ModuleHeader header;CI386Heap heap;U8 *image;
  I64 capacity,i;I64 (*entry_point)(I64 x,I64 y);
  if(!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
     I386RedSeaFind(&v,v.root,"Good.T32M",&entry)!=1 ||
     I386RedSeaRead(&v,&entry,0,&header,32)!=32)return 1;
  capacity=(entry.size+7)&~7;capacity+=64;
  //Enough for one file and small metadata overhead; fewer than two buffers.
  if(capacity>=((entry.size+7)&~7)+((header.code_size+15)&~7)+32 ||
     !I386HeapInit(&heap,(0x40000)(U8 *),capacity))return 2;
  for(i=0;i<2;i++) {
    image=I386RedSeaLoad(&v,&entry,&heap,"Main");
    if(!image)return 3;
    if(heap.allocations!=1 || I386HeapSize(&heap,image)!=header.code_size+8)return 4;
    entry_point=image;
    if((*entry_point)(17,25)!=0x10000002A)return 5;
    if((*entry_point)(1,2)!=0x100000014 || !I386HeapFree(&heap,image) ||
       heap.used || heap.allocations || !I386HeapValid(&heap))return 6;
  }
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/ModuleFile.HC"
