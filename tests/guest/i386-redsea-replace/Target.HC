#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,full,again;
  CI386RedSeaEntry entry;
  U8 buffer[700],output[702],*code="I64 Answer() { return 42; }\n";
  I64 i,length=0;
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      !I386RedSeaMount(&full,&disk,12288)) return 1;
  for (i=0;i<700;i++) buffer[i]=((i*17)^(i>>2)^0x95)&255;
  for (i=0;i<702;i++) output[i]=0xA5;
  if (I386RedSeaReplace(0,v.root,"Saved.HC",0,0)!=-1 ||
      I386RedSeaReplace(&v,v.root,0,0,0)!=-1 ||
      I386RedSeaReplace(&v,v.root,"Missing",0,0)!=0 ||
      I386RedSeaReplace(&v,v.root,"Full",0,0)!=-1 ||
      I386RedSeaReplace(&v,v.root,"F5",0,0)!=-1 ||
      I386RedSeaReplace(&v,2057,"Missing",0,0)!=-1 ||
      I386RedSeaReplace(&v,v.root,"Saved.HC",0,1)!=-1 ||
      I386RedSeaReplace(&v,v.root,"Saved.HC",buffer,-1)!=-1 ||
      I386RedSeaReplace(&v,v.root,"Saved.HC",(0xFFFFFFF0)(U8 *),32)!=-1) return 2;
  disk.flush=FALSE;
  if (I386RedSeaReplace(&v,v.root,"Saved.HC",0,0)!=-1) return 3;
  disk.flush=TRUE;
  if (I386RedSeaReplace(&full,full.root,"Kept",buffer,700)!=0 ||
      I386RedSeaFind(&full,full.root,"Kept",&entry)!=1 || entry.block!=12291 ||
      entry.size!=1 || I386RedSeaRead(&full,&entry,0,output,1)!=1 || output[0]!='K') return 4;
  output[0]=0xA5;
  if (I386RedSeaReplace(&v,v.root,"Saved.HC",buffer,700,0xFEDCBA9876543210)!=1 ||
      I386RedSeaFind(&v,v.root,"Saved.HC",&entry)!=1 || entry.block!=2055 ||
      entry.size!=700 || entry.attr!=0x822 || entry.datetime!=0xFEDCBA9876543210 ||
      I386RedSeaRead(&v,&entry,0,output+1,700)!=700) return 5;
  for (i=0;i<700;i++) if (output[i+1]!=buffer[i]) return 6;
  if (output[0]!=0xA5 || output[701]!=0xA5 ||
      !I386AtaRead(&disk,2049,output) || output[0]!=0xEF) return 7;
  if (I386RedSeaReplace(&v,v.root,"Saved.HC",0,0)!=1 ||
      I386RedSeaFind(&v,v.root,"Saved.HC",&entry)!=1 || entry.block || entry.size ||
      entry.attr!=0x822 || !I386AtaRead(&disk,2049,output) || output[0]!=0x8F) return 8;
  while (code[length]) length++;
  if (I386RedSeaReplace(&v,v.root,"Saved.HC",code,length,12345)!=1 ||
      !I386RedSeaMount(&again,&disk,2048) ||
      I386RedSeaFind(&again,again.root,"Saved.HC",&entry)!=1 || entry.block!=2054 ||
      entry.size!=length || entry.attr!=0x822 || entry.datetime!=12345 ||
      I386RedSeaRead(&again,&entry,0,output,700)!=length) return 9;
  for (i=0;i<length;i++) if (output[i]!=code[i]) return 10;
  for (i=0;i<700;i++) if (buffer[i]!=(((i*17)^(i>>2)^0x95)&255)) return 11;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaWrite.HC"
#include "/Kernel/I386/RedSeaAlloc.HC"
#include "/Kernel/I386/RedSeaReplace.HC"
