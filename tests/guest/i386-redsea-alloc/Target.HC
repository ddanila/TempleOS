#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
class COwnedBitmapTest {I64 *owned;I64 writes,fail;Bool missing_owner;};
Bool OwnedRead(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{no_warn context;return I386AtaRead(disk,block,buffer);}
Bool OwnedWrite(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{
  COwnedBitmapTest *test=context;
  test->writes++;
  if(*test->owned!=2052)test->missing_owner=TRUE;
  if(test->writes==test->fail)return FALSE;
  return I386AtaWrite(disk,block,buffer);
}
Bool OwnedFlush(U8 *context,CI386Ata *disk)
{no_warn context;return I386AtaFlush(disk);}
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,bad;
  U8 sector[512];
  I64 i,first,second,whole,owned=0,fault;
  COwnedBitmapTest test;CI386RedSeaIo io;
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
  //Ownership must precede every bitmap write, including a failed first write.
  io.context=&test;io.begin=0;io.end=0;io.read=&OwnedRead;
  io.write=&OwnedWrite;io.flush=&OwnedFlush;test.owned=&owned;
  for(fault=1;fault<=2;fault++) {
    test.writes=0;test.fail=fault;test.missing_owner=FALSE;v.io=&io;
    if(I386RedSeaAllocOwned(&v,4097,&owned)!=-1 || owned!=2052 ||
        v.signature || test.missing_owner || test.writes!=fault)return 22;
    //A stale/nonempty ownership record must never be overwritten.
    if(I386RedSeaAllocOwned(&v,1,&owned)!=-1 || owned!=2052)return 23;
    if(!I386RedSeaMount(&v,&disk,2048))return 24;
    v.io=&io;test.writes=0;test.fail=2;
    if(I386RedSeaReleaseOwned(&v,owned,4097) || v.signature)return 25;
    if(!I386RedSeaMount(&v,&disk,2048))return 26;
    v.io=&io;test.writes=0;test.fail=0;
    if(!I386RedSeaReleaseOwned(&v,owned,4097) || test.missing_owner ||
        !I386RedSeaFlush(&v))return 27;
    owned=0;
    if(!I386AtaRead(&disk,2049,sector) || sector[0]!=3)return 28;
    for(i=1;i<512;i++)if(sector[i])return 29;
    if(!I386AtaRead(&disk,2050,sector) || sector[511]!=0xC0)return 30;
    for(i=0;i<511;i++)if(sector[i])return 31;
  }
  test.writes=0;test.fail=0;
  if(I386RedSeaAllocOwned(&v,4,&owned)!=2052 || owned!=2052 ||
      test.missing_owner || !I386RedSeaReleaseOwned(&v,owned,4) ||
      I386RedSeaReleaseOwned(&v,2051,1) ||
      I386RedSeaReleaseOwned(&v,2050,1))return 32;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaAlloc.HC"
