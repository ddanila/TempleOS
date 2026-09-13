#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/ModuleFile.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v;
  CI386RedSeaEntry entries[3];
  CI386Heap heap;
  U8 *image,*reuse,*reserve;
  I64 i,j,amount,consumer_size,provider_size;
  I64 (*entry_point)(I64 x,I64 y);
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      !I386HeapInit(&heap,(0x40000)(U8 *),65536) ||
      I386RedSeaFind(&v,v.root,"Consumer.T32M",entries)!=1 ||
      I386RedSeaFind(&v,v.root,"Provider.T32M",entries+1)!=1 ||
      I386RedSeaFind(&v,v.root,"Provider.T32M",entries+2)!=1) return 1;
  consumer_size=(entries[0].size+7)&~7; provider_size=(entries[1].size+7)&~7;
  if (I386RedSeaLoadSet(&v,entries,0,&heap,"Main") ||
      I386RedSeaLoadSet(&v,entries,-1,&heap,"Main") ||
      I386RedSeaLoadSet(&v,entries,0x10000000,&heap,"Main") ||
      I386RedSeaLoadSet(&v,(0xFFFFFFC0)(CI386RedSeaEntry *),2,&heap,"Main") ||
      I386RedSeaLoadSet(&v,entries,2,0,"Main") ||
      I386RedSeaLoadSet(&v,entries,1,&heap,"Main") ||
      I386RedSeaLoadSet(&v,entries,3,&heap,"Main") ||
      I386RedSeaLoadSet(&v,entries,2,&heap,"Missing")) return 2;
  if (I386RedSeaFind(&v,v.root,"Wrong.T32M",entries+1)!=1 ||
      I386RedSeaLoadSet(&v,entries,2,&heap,"Main") ||
      I386RedSeaFind(&v,v.root,"Short.T32M",entries+1)!=1 ||
      I386RedSeaLoadSet(&v,entries,2,&heap,"Main") ||
      I386RedSeaFind(&v,v.root,"Provider.T32M",entries+1)!=1 ||
      heap.used || heap.allocations || !I386HeapValid(&heap)) return 3;
  //Exhaust metadata, first file, second file, then loaded image allocation.
  for (j=0;j<4;j++) {
    amount=65520;
    if (j==1) amount=65464;
    if (j==2) amount=65464-consumer_size;
    if (j==3) amount=65448-consumer_size-provider_size;
    reserve=I386HeapAlloc(&heap,amount);
    if (!reserve || I386RedSeaLoadSet(&v,entries,2,&heap,"Main") || heap.allocations!=1 ||
        heap.used!=amount+16 || !I386HeapFree(&heap,reserve) || heap.used) return 4;
  }
  disk.sectors=32769; v.sectors=32769-v.start;
  entries[1].attr=0x800; entries[1].block=32767; entries[1].size=1024;
  if (I386RedSeaLoadSet(&v,entries,2,&heap,"Main") || heap.used || heap.allocations) return 5;
  disk.sectors=32768; v.sectors=128;
  for (j=0;j<2;j++) {
    if (!j) {
      if (I386RedSeaFind(&v,v.root,"Consumer.T32M",entries)!=1 ||
          I386RedSeaFind(&v,v.root,"Provider.T32M",entries+1)!=1) return 6;
    } else {
      if (I386RedSeaFind(&v,v.root,"Provider.T32M",entries)!=1 ||
          I386RedSeaFind(&v,v.root,"Consumer.T32M",entries+1)!=1) return 7;
    }
    image=I386RedSeaLoadSet(&v,entries,2,&heap,"Main");
    if (!image || heap.allocations!=1) return 8;
    entry_point=image;
    if ((*entry_point)(17,25)!=0x10000004C) return 9;
    amount=56+consumer_size+provider_size;
    reuse=I386HeapAlloc(&heap,amount);
    if (reuse!=(0x40010)(U8 *)) return 10;
    for (i=0;i<amount;i++) reuse[i]=0xA5;
    if ((*entry_point)(1,2)!=0x100000016 || !I386HeapFree(&heap,reuse) ||
        !I386HeapFree(&heap,image) || heap.used || heap.allocations || !I386HeapValid(&heap))
      return 11;
  }
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/ModuleFile.HC"
