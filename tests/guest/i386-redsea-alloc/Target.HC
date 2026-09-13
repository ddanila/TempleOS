#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,bad;
  U8 sector[512];
  I64 i,first,second,whole;
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      v.first!=2051 || v.root!=2051 || v.sectors!=8192) return 1;
  if (I386RedSeaAlloc(0,1)!=-1 || I386RedSeaAlloc(&v,0)!=-1 ||
      I386RedSeaAlloc(&v,-1)!=-1 || I386RedSeaAlloc(&v,8190)!=-1 ||
      I386RedSeaAlloc(&v,8189)!=0 || I386RedSeaFree(&v,2051,1) ||
      I386RedSeaFree(&v,2050,1) || I386RedSeaFree(&v,10239,2) ||
      I386RedSeaFree(&v,2052,0) || I386RedSeaFree(0,2052,1)) return 2;
  first=I386RedSeaAlloc(&v,4093);
  if (first!=2052 || !I386AtaFlush(&disk)) return 3;
  //The final sector of this requested release is still free: reject all of it.
  if (I386RedSeaFree(&v,first,4094) || !I386AtaRead(&disk,2049,sector)) return 4;
  for (i=0;i<511;i++) if (sector[i]!=255) return 5;
  if (sector[511]!=0x7F) return 6;
  second=I386RedSeaAlloc(&v,4);
  if (second!=6145 || !I386AtaFlush(&disk) || !I386AtaRead(&disk,2049,sector)) return 7;
  for (i=0;i<512;i++) if (sector[i]!=255) return 8;
  if (!I386AtaRead(&disk,2050,sector) || sector[0]!=7 || sector[511]!=0xC0) return 9;
  for (i=1;i<511;i++) if (sector[i]) return 10;
  if (!I386RedSeaFree(&v,first,4093) || I386RedSeaFree(&v,first,4093) ||
      I386RedSeaAlloc(&v,4094)!=0 || !I386RedSeaFree(&v,second,4)) return 11;
  whole=I386RedSeaAlloc(&v,8188);
  if (whole!=2052 || I386RedSeaAlloc(&v,1)!=0 || !I386AtaFlush(&disk)) return 12;
  for (a=2049;a<=2050;a++) {
    if (!I386AtaRead(&disk,a,sector)) return 13;
    for (i=0;i<512;i++) if (sector[i]!=255) return 14;
  }
  if (!I386RedSeaFree(&v,whole,8188) || !I386AtaFlush(&disk)) return 15;
  if (!I386AtaRead(&disk,2049,sector) || sector[0]!=3) return 16;
  for (i=1;i<512;i++) if (sector[i]) return 17;
  if (!I386AtaRead(&disk,2050,sector) || sector[511]!=0xC0) return 18;
  for (i=0;i<511;i++) if (sector[i]) return 19;
  //A forged device limit forces real bitmap-read failure; subsequent use is barred.
  disk.sectors=32771;
  bad.disk=&disk; bad.signature=v.signature; bad.start=32767;
  bad.sectors=4; bad.first=32769; bad.root=32769;
  if (I386RedSeaAlloc(&bad,1)!=-1 || bad.signature ||
      I386RedSeaAlloc(&bad,1)!=-1 || I386RedSeaFree(&bad,32769,1)) return 20;
  disk.sectors=32768;
  if (I386RedSeaAlloc(&v,1)!=2052 || !I386RedSeaFree(&v,2052,1) || !I386AtaFlush(&disk))
    return 21;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaAlloc.HC"
