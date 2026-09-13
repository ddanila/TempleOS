#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Ata.HH"
I64 Main(I64 a,I64 b)
{
  CI386Ata disk,absent;
  U8 buffer[514];
  I64 i,j,lba;
  disk.signature=0x55AA; disk.sectors=0x1234;
  if (I386AtaIdentify(0,0,0) || I386AtaIdentify(&disk,2,0) ||
      I386AtaIdentify(&disk,0,2) || I386AtaIdentify(&disk,0,0,0) ||
      I386AtaIdentify(&disk,0,0,100001) || disk.signature!=0x55AA || disk.sectors!=0x1234)
    return 1;
  if (!I386AtaIdentify(&disk,0,0) || disk.sectors!=32768 || disk.io!=0x1F0 ||
      disk.control!=0x3F6 || disk.drive) return 2;
  for (i=0;i<514;i++) buffer[i]=0xA5;
  if (!I386AtaRead(&disk,0,buffer+1) || buffer[511]!=0x55 || buffer[512]!=0xAA ||
      buffer[0]!=0xA5 || buffer[513]!=0xA5) return 3;
  for (j=0;j<4;j++) {
    lba=2048;
    if (j==1) lba=2049;
    if (j==2) lba=32767;
    if (!I386AtaRead(&disk,lba,buffer+1)) return 4;
    for (i=0;i<512;i++)
      if (buffer[i+1]!=(((i*37)^(i>>1)^(lba&255))&255)) return 5;
    if (buffer[0]!=0xA5 || buffer[513]!=0xA5) return 6;
  }
  for (i=0;i<514;i++) buffer[i]=0xA5;
  if (I386AtaRead(0,0,buffer+1) || I386AtaRead(&disk,0,0) ||
      I386AtaRead(&disk,-1,buffer+1) || I386AtaRead(&disk,32768,buffer+1) ||
      I386AtaRead(&disk,0,buffer+1,0) || I386AtaRead(&disk,0,buffer+1,100001)) return 7;
  //Inject an overstated capacity to reach the real device's out-of-range error.
  disk.sectors=32769;
  if (I386AtaRead(&disk,32768,buffer+1)) return 8;
  disk.sectors=32768;
  for (i=0;i<514;i++) if (buffer[i]!=0xA5) return 9;
  if (!I386AtaRead(&disk,2048,buffer+1)) return 10;
  absent.signature=0x55AA; absent.sectors=0x6677;
  if (I386AtaIdentify(&absent,1,0,32) || I386AtaIdentify(&absent,0,1,32) ||
      absent.signature!=0x55AA || absent.sectors!=0x6677 ||
      !I386AtaRead(&disk,2049,buffer+1)) return 11;
  for (i=0;i<512;i++) if (buffer[i+1]!=(((i*37)^(i>>1)^1)&255)) return 12;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
