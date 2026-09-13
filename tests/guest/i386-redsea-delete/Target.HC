#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,again;
  CI386RedSeaEntry entry;
  U8 buffer[700],output[700],*code="I64 Answer() { return 42; }\n";
  I64 i,length=0;
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048)) return 1;
  for (i=0;i<700;i++) buffer[i]=((i*17)^(i>>2)^0x95)&255;
  if (I386RedSeaDelete(0,v.root,"Missing")!=-1 ||
      I386RedSeaDelete(&v,v.root,0)!=-1 || I386RedSeaDelete(&v,v.root,"")!=-1 ||
      I386RedSeaDelete(&v,v.root,"Missing")!=0 || I386RedSeaDelete(&v,v.root,".")!=-1 ||
      I386RedSeaDelete(&v,v.root,"Full")!=-1 || I386RedSeaDelete(&v,v.root,"F5")!=-1 ||
      I386RedSeaDelete(&v,2057,"Missing")!=-1) return 2;
  if (I386RedSeaCreate(&v,v.root,"Temp.BIN",buffer,700)!=1) return 3;
  disk.flush=FALSE;
  if (I386RedSeaDelete(&v,v.root,"Temp.BIN")!=-1) return 4;
  disk.flush=TRUE;
  if (I386RedSeaFind(&v,v.root,"Temp.BIN",&entry)!=1 || entry.block!=2054 ||
      I386RedSeaDelete(&v,v.root,"Temp.BIN")!=1 ||
      I386RedSeaFind(&v,v.root,"Temp.BIN",&entry)!=0 ||
      I386RedSeaDelete(&v,v.root,"Temp.BIN")!=0) return 5;
  if (!I386AtaRead(&disk,2049,output) || output[0]!=0x8F ||
      !I386AtaRead(&disk,2054,output)) return 6;
  for (i=0;i<512;i++) if (output[i]!=buffer[i]) return 7;
  while (code[length]) length++;
  if (I386RedSeaCreate(&v,v.root,"Reused.HC",code,length,12345)!=1 ||
      I386RedSeaFind(&v,v.root,"Reused.HC",&entry)!=1 || entry.block!=2054) return 8;
  if (I386RedSeaCreate(&v,v.root,"EmptyTemp",0,0)!=1 ||
      I386RedSeaDelete(&v,v.root,"EmptyTemp")!=1 ||
      I386RedSeaDelete(&v,v.root,"EmptyTemp")!=0) return 9;
  if (!I386RedSeaMount(&again,&disk,2048) ||
      I386RedSeaFind(&again,again.root,"Temp.BIN",&entry)!=0 ||
      I386RedSeaFind(&again,again.root,"EmptyTemp",&entry)!=0 ||
      I386RedSeaFind(&again,again.root,"Reused.HC",&entry)!=1 || entry.block!=2054 ||
      entry.size!=length || entry.datetime!=12345 ||
      I386RedSeaRead(&again,&entry,0,output,700)!=length) return 10;
  for (i=0;i<length;i++) if (output[i]!=code[i]) return 11;
  for (i=0;i<700;i++) if (buffer[i]!=(((i*17)^(i>>2)^0x95)&255)) return 12;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaWrite.HC"
#include "/Kernel/I386/RedSeaAlloc.HC"
#include "/Kernel/I386/RedSeaCreate.HC"
#include "/Kernel/I386/RedSeaDelete.HC"
