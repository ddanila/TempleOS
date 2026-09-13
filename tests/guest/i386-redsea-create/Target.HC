#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,again;
  CI386RedSeaEntry entry;
  U8 buffer[702],output[702],*code="I64 Answer() { return 42; }\n";
  I64 i,length=0;
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048)) return 1;
  for (i=0;i<702;i++) { buffer[i]=0xA5; output[i]=0x5A; }
  for (i=0;i<700;i++) buffer[i+1]=((i*17)^(i>>2)^0x95)&255;
  if (I386RedSeaCreate(&v,v.root,"",0,0)!=-1 ||
      I386RedSeaCreate(&v,v.root,".",0,0)!=-1 ||
      I386RedSeaCreate(&v,v.root,"..",0,0)!=-1 ||
      I386RedSeaCreate(&v,v.root,"bad/name",0,0)!=-1 ||
      I386RedSeaCreate(&v,v.root,"Bad",0,1)!=-1 ||
      I386RedSeaCreate(&v,v.root,"Bad",buffer,-1)!=-1 ||
      I386RedSeaCreate(&v,v.root,"Bad",(0xFFFFFFF0)(U8 *),32)!=-1 ||
      I386RedSeaCreate(&v,2053,"FullDirectory",0,0)!=0 ||
      I386RedSeaCreate(&v,2057,"ReadOnly",0,0)!=-1) return 2;
  disk.flush=FALSE;
  if (I386RedSeaCreate(&v,v.root,"NoFlush",0,0)!=-1) return 3;
  disk.flush=TRUE;
  if (I386RedSeaCreate(&v,v.root,"Created.BIN",buffer+1,700,0xFEDCBA9876543210)!=1 ||
      I386RedSeaCreate(&v,v.root,"Created.BIN",buffer+1,700)!=0) return 4;
  while (code[length]) length++;
  if (I386RedSeaCreate(&v,v.root,"Answer.HC",code,length,12345)!=1 ||
      I386RedSeaCreate(&v,v.root,"EmptyNew",0,0)!=1) return 5;
  for (i=0;i<700;i++) if (buffer[i+1]!=(((i*17)^(i>>2)^0x95)&255)) return 6;
  if (buffer[0]!=0xA5 || buffer[701]!=0xA5 || !I386RedSeaMount(&again,&disk,2048)) return 7;
  if (I386RedSeaFind(&again,again.root,"Created.BIN",&entry)!=1 || entry.block!=2054 ||
      entry.size!=700 || entry.datetime!=0xFEDCBA9876543210 ||
      I386RedSeaRead(&again,&entry,0,output+1,700)!=700) return 8;
  for (i=0;i<700;i++) if (output[i+1]!=buffer[i+1]) return 9;
  if (output[0]!=0x5A || output[701]!=0x5A ||
      I386RedSeaFind(&again,again.root,"Answer.HC",&entry)!=1 || entry.block!=2056 ||
      entry.size!=length || entry.datetime!=12345 ||
      I386RedSeaRead(&again,&entry,0,output,length)!=length) return 10;
  for (i=0;i<length;i++) if (output[i]!=code[i]) return 11;
  if (I386RedSeaFind(&again,again.root,"EmptyNew",&entry)!=1 || entry.block || entry.size ||
      I386RedSeaFind(&again,again.root,"Ghost",&entry)!=0 ||
      I386RedSeaFind(&again,again.root,"Ghost2",&entry)!=0) return 12;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaWrite.HC"
#include "/Kernel/I386/RedSeaAlloc.HC"
#include "/Kernel/I386/RedSeaCreate.HC"
