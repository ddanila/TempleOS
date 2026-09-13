#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Ata.HH"
extern Bool I386AtaDecode(CI386Ata *disk,U16 *words,I64 channel,I64 drive);
I64 DecodeTest()
{
  CI386Ata disk;
  U16 words[256];
  U8 *bytes;
  I64 i,j;
  bytes=&disk;
  for (i=0;i<256;i++) words[i]=0;
  words[1]=100; words[3]=4; words[6]=17;
  if (!I386AtaDecode(&disk,words,1,1) || disk.sectors!=6800 || disk.lba ||
      disk.cylinders!=100 || disk.heads!=4 || disk.sectors_per_track!=17 ||
      disk.io!=0x170 || disk.control!=0x376 || disk.drive!=1) return 20;
  words[53]=1; words[54]=80; words[55]=8; words[56]=32;
  if (!I386AtaDecode(&disk,words,0,0) || disk.sectors!=20480 || disk.lba ||
      disk.cylinders!=80 || disk.heads!=8 || disk.sectors_per_track!=32) return 21;
  //An explicitly valid current translation must not fall back to default geometry.
  for (j=0;j<5;j++) {
    words[54]=80; words[55]=8; words[56]=32;
    if (j==0) words[54]=0;
    if (j==1) words[55]=0;
    if (j==2) words[55]=17;
    if (j==3) words[56]=0;
    if (j==4) words[56]=256;
    for (i=0;i<sizeof(CI386Ata);i++) bytes[i]=0xA5;
    if (I386AtaDecode(&disk,words,0,0)) return 22;
    for (i=0;i<sizeof(CI386Ata);i++) if (bytes[i]!=0xA5) return 23;
  }
  //LBA disks remain usable even when they do not report usable CHS geometry.
  words[49]=0x200; words[60]=0xFFFF; words[61]=0xFFFF;
  if (!I386AtaDecode(&disk,words,0,0) || !disk.lba || disk.sectors!=0x10000000 ||
      disk.cylinders || disk.heads || disk.sectors_per_track) return 24;
  words[60]=0; words[61]=0;
  if (I386AtaDecode(&disk,words,0,0)) return 25;
  words[49]=0; words[53]=0;
  words[1]=65535; words[3]=16; words[6]=255;
  if (!I386AtaDecode(&disk,words,0,0) || disk.sectors!=267382800) return 26;
  words[106]=0x5000; words[117]=2048;
  if (I386AtaDecode(&disk,words,0,0)) return 27;
  words[117]=256;
  if (!I386AtaDecode(&disk,words,0,0)) return 28;
  words[0]=0x8000;
  for (i=0;i<sizeof(CI386Ata);i++) bytes[i]=0xA5;
  if (I386AtaDecode(&disk,words,0,0) || I386AtaDecode(0,words,0,0) ||
      I386AtaDecode(&disk,0,0,0) || I386AtaDecode(&disk,words,2,0) ||
      I386AtaDecode(&disk,words,0,2)) return 29;
  for (i=0;i<sizeof(CI386Ata);i++) if (bytes[i]!=0xA5) return 30;
  return 0;
}
I64 ChsTest(CI386Ata *disk)
{//Force the normal no-LBA branch on QEMU; this is not a CHS-only device probe.
  U8 buffer[514];
  I64 i,j,lba,span,capacity,saved;
  span=disk->heads*disk->sectors_per_track;
  capacity=disk->cylinders*span;
  if (!disk->lba || span<512 || disk->heads<2 || capacity>disk->sectors ||
      capacity<=2*span) return 31;
  disk->lba=FALSE;
  for (i=0;i<514;i++) buffer[i]=0xA5;
  if (!I386AtaRead(disk,0,buffer+1) || buffer[511]!=0x55 || buffer[512]!=0xAA) return 32;
  for (j=0;j<5;j++) {
    lba=span-1;
    if (j==1) lba=span;
    if (j==2) lba=span+disk->sectors_per_track-1;
    if (j==3) lba=span+disk->sectors_per_track;
    if (j==4) lba=capacity-1;
    if (!I386AtaRead(disk,lba,buffer+1)) return 33;
    for (i=0;i<512;i++)
      if (buffer[i+1]!=(((i*37)^(i>>1)^lba^(lba>>8))&255)) return 34;
    if (buffer[0]!=0xA5 || buffer[513]!=0xA5) return 35;
  }
  for (i=0;i<514;i++) buffer[i]=0xA5;
  if (I386AtaRead(disk,capacity,buffer+1)) return 36;
  saved=disk->heads; disk->heads=0;
  if (I386AtaRead(disk,0,buffer+1)) return 37;
  disk->heads=17;
  if (I386AtaRead(disk,0,buffer+1)) return 37;
  disk->heads=saved;
  saved=disk->sectors_per_track; disk->sectors_per_track=256;
  if (I386AtaRead(disk,0,buffer+1)) return 38;
  disk->sectors_per_track=saved;
  saved=disk->cylinders; disk->cylinders=65536;
  if (I386AtaRead(disk,0,buffer+1)) return 39;
  disk->cylinders=saved;
  for (i=0;i<514;i++) if (buffer[i]!=0xA5) return 40;
  disk->lba=TRUE;
  return 0;
}
I64 Main(I64 a,I64 b)
{
  CI386Ata disk,absent;
  U8 buffer[514];
  I64 i,j,lba,result;
  result=DecodeTest();
  if (result) return result;
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
      if (buffer[i+1]!=(((i*37)^(i>>1)^lba^(lba>>8))&255)) return 5;
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
  for (i=0;i<512;i++) if (buffer[i+1]!=(((i*37)^(i>>1)^9)&255)) return 12;
  return ChsTest(&disk);
}
#include "/Kernel/I386/Ata.HC"
