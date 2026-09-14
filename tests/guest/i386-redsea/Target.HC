#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/FileRead.HH"
public extern I64 TestFiles(CI386RedSea *v);
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v,bad;
  CI386RedSeaEntry entry,dir;
  U8 buffer[1502],*p,*source="I64 Twice(I64 x) { return x*2; }\n";
  I64 i,j,saved;
  if (sizeof(CI386RedSeaEntry)!=64 || !I386AtaIdentify(&disk,0,0) ||
      !I386RedSeaMount(&v,&disk,2048) || v.first!=2050 || v.root!=2050 || v.sectors!=128)
    return 1;
  i=TestFiles(&v); if(i) return i;
  p=&bad;
  for (i=0;i<sizeof(CI386RedSea);i++) p[i]=0xA5;
  if (I386RedSeaMount(0,&disk,2048) || I386RedSeaMount(&bad,0,2048) ||
      I386RedSeaMount(&bad,&disk,-1)) return 2;
  for (j=0;j<6;j++) if (I386RedSeaMount(&bad,&disk,3072+j)) return 3;
  for (i=0;i<sizeof(CI386RedSea);i++) if (p[i]!=0xA5) return 4;
  if (!I386RedSeaMount(&bad,&disk,3078)) return 25;
  if (I386RedSeaFind(&v,v.root,"DATA.BIN",&entry)!=1 || entry.block!=2053 ||
      entry.size!=1300 || entry.datetime!=0x123456789ABCDEF0)
    return 5;
  for (i=0;i<1502;i++) buffer[i]=0xA5;
  if (I386RedSeaRead(&v,&entry,0,buffer+1,1500)!=1300) return 6;
  for (i=0;i<1300;i++) if (buffer[i+1]!=(((i*19)^(i>>4))&255)) return 7;
  for (i=1301;i<1502;i++) if (buffer[i]!=0xA5) return 8;
  if (buffer[0]!=0xA5 || I386RedSeaRead(&v,&entry,1300,buffer+1,1)!=0 ||
      I386RedSeaRead(&v,&entry,1301,buffer+1,1)!=-1) return 9;
  if (I386RedSeaRead(&v,&entry,509,buffer+1,520)!=520) return 10;
  for (i=0;i<520;i++) if (buffer[i+1]!=((((i+509)*19)^((i+509)>>4))&255)) return 11;
  if (I386RedSeaFind(&v,v.root,"Tools",&dir)!=1 ||
      I386RedSeaRead(&v,&dir,0,buffer,1)!=-1 ||
      I386RedSeaFind(&v,dir.block,"Source.HC",&entry)!=1 ||
      I386RedSeaRead(&v,&entry,0,buffer,1500)!=entry.size) return 12;
  for (i=0;i<entry.size;i++) if (buffer[i]!=source[i]) return 13;
  if (I386RedSeaFind(&v,v.root,"Empty",&entry)!=1 ||
      I386RedSeaRead(&v,&entry,0,buffer,1)!=0) return 14;
  p=&entry;
  for (i=0;i<sizeof(CI386RedSeaEntry);i++) p[i]=0xA5;
  if (I386RedSeaFind(&v,v.root,"absent",&entry)!=0 ||
      I386RedSeaFind(&v,2057,"Outside",&entry)!=-1 ||
      I386RedSeaFind(&v,2053,"DATA.BIN",&entry)!=-1 ||
      I386RedSeaFind(&v,v.root,"",&entry)!=-1) return 15;
  for (i=0;i<sizeof(CI386RedSeaEntry);i++) if (p[i]!=0xA5) return 16;
  if (I386RedSeaFind(&v,v.root,"DATA.BIN",&entry)!=1) return 17;
  for (i=0;i<1502;i++) buffer[i]=0xA5;
  saved=entry.size; entry.size=0x7FFFFFFFFFFFFFFF;
  if (I386RedSeaRead(&v,&entry,0,buffer+1,1)!=-1) return 18;
  entry.size=saved;
  if (I386RedSeaRead(&v,&entry,-1,buffer+1,1)!=-1 ||
      I386RedSeaRead(&v,&entry,0,buffer+1,-1)!=-1) return 19;
  if (I386RedSeaRead(&v,&entry,0,(0xFFFFFFF0)(U8 *),32)!=-1) return 26;
  for (i=0;i<1502;i++) if (buffer[i]!=0xA5) return 20;
  //Inject overstated device/volume bounds: second sector reaches a real I/O error.
  disk.sectors=32769; v.sectors=32769-v.start; entry.block=32767; entry.size=1024;
  if (I386RedSeaRead(&v,&entry,0,buffer+1,1024)!=512) return 21;
  for (i=0;i<512;i++) if (buffer[i+1]!=0x6C) return 22;
  for (i=513;i<1502;i++) if (buffer[i]!=0xA5) return 23;
  if (buffer[0]!=0xA5 || I386RedSeaRead(&v,&entry,512,buffer+513,512)!=-1) return 24;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"

#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/FileRead.HC"
#include "Files.HC"
