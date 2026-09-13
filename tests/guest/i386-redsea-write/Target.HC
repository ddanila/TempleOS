#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/RedSea.HH"
U0 Pattern(U8 *p,I64 count,I64 seed)
{
  I64 i;
  for (i=0;i<count;i++) p[i]=((i*29)^(i>>3)^seed)&255;
}
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v;
  CI386RedSeaEntry entry,again;
  U8 source[1026],readback[1302];
  I64 i,j,offset,count,seed,expected;
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      I386RedSeaFind(&v,v.root,"DATA.BIN",&entry)!=1) return 1;
  for (i=0;i<1026;i++) source[i]=0xA5;
  for (i=0;i<1302;i++) readback[i]=0x5A;
  Pattern(source+1,1024,0x67);
  if (I386RedSeaWrite(0,&entry,0,source+1,1)!=-1 ||
      I386RedSeaWrite(&v,0,0,source+1,1)!=-1 ||
      I386RedSeaWrite(&v,&entry,0,0,1)!=-1 ||
      I386RedSeaWrite(&v,&entry,-1,source+1,1)!=-1 ||
      I386RedSeaWrite(&v,&entry,0,source+1,-1)!=-1 ||
      I386RedSeaWrite(&v,&entry,1299,source+1,2)!=-1 ||
      I386RedSeaWrite(&v,&entry,1301,source+1,0)!=-1 ||
      I386RedSeaWrite(&v,&entry,0,(0xFFFFFFF0)(U8 *),32)!=-1) return 2;
  for (j=0;j<5;j++) {
    entry.attr=0x801;
    if (j==1) entry.attr=0x810;
    if (j==2) entry.attr=0x900;
    if (j==3) entry.attr=0xA00;
    if (j==4) entry.attr=0;
    if (I386RedSeaWrite(&v,&entry,0,source+1,1)!=-1) return 3;
  }
  entry.attr=0x800;
  entry.size=0x7FFFFFFFFFFFFFFF;
  if (I386RedSeaWrite(&v,&entry,0,source+1,1)!=-1) return 4;
  entry.size=1300;
  //First update spans partial/full/partial sectors; second overwrites a whole sector.
  for (j=0;j<3;j++) {
    offset=509; count=520; seed=0x67;
    if (j==1) { offset=0; count=512; seed=0xA9; }
    if (j==2) { offset=1295; count=5; seed=0x3C; }
    Pattern(source+1,1024,seed);
    if (I386RedSeaWrite(&v,&entry,offset,source+1,count)!=count || !I386AtaFlush(&disk))
      return 5;
    for (i=0;i<1024;i++)
      if (source[i+1]!=(((i*29)^(i>>3)^seed)&255)) return 6;
    if (source[0]!=0xA5 || source[1025]!=0xA5) return 7;
  }
  if (I386RedSeaWrite(&v,&entry,1300,source+1,0)!=0 ||
      I386RedSeaRead(&v,&entry,0,readback+1,1300)!=1300) return 8;
  for (i=0;i<1300;i++) {
    expected=((i*19)^(i>>4))&255;
    if (i>=509 && i<1029) expected=(((i-509)*29)^((i-509)>>3)^0x67)&255;
    if (i<512) expected=((i*29)^(i>>3)^0xA9)&255;
    if (i>=1295) expected=(((i-1295)*29)^((i-1295)>>3)^0x3C)&255;
    if (readback[i+1]!=expected) return 9;
  }
  if (readback[0]!=0x5A || readback[1301]!=0x5A ||
      I386RedSeaFind(&v,v.root,"DATA.BIN",&again)!=1 || again.size!=1300 ||
      again.block!=entry.block || again.datetime!=entry.datetime) return 10;
  //A second-sector device error reports the first confirmed sector only.
  disk.sectors=32769; v.sectors=32769-v.start; entry.block=32767; entry.size=1024;
  Pattern(source+1,1024,0x67);
  if (I386RedSeaWrite(&v,&entry,0,source+1,1024)!=512 ||
      I386RedSeaWrite(&v,&entry,512,source+1,512)!=-1) return 11;
  for (i=0;i<1024;i++) if (source[i+1]!=(((i*29)^(i>>3)^0x67)&255)) return 12;
  if (!I386AtaFlush(&disk)) return 13;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/RedSeaWrite.HC"
