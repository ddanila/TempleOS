#include "/Kernel/I386/RedSea.HH"

U0 I386RedSeaFormatWord(U8 *p,U64 value)
{
  I64 i;
  for(i=0;i<8;i++) p[i]=value>>(8*i);
}

public Bool I386RedSeaFormat(CI386Ata *disk,I64 start,I64 sectors)
{//Initialize a zeroed target with one empty root. Caller owns the ATA channel.
 //The volume header is written last; boot code is installed separately.
  U8 sector[512];
  I64 bitmap,first,root,valid_bits,block,bit,i;
  if(!disk || disk->signature!=0x41543332 || !disk->flush ||
      start<2048 || start>=disk->sectors || sectors<4096 ||
      sectors>disk->sectors-start || sectors>0x10000000) return FALSE;
  bitmap=(sectors+4095)/4096;
  first=start+1+bitmap; root=first;
  valid_bits=start+sectors-(first-1);
  if(root+1>=start+sectors || valid_bits>bitmap*4096) return FALSE;
  if(!I386AtaTransfer(disk,0,sector,100000,FALSE,0)) return FALSE;
  for(i=0;i<512;i++) if(sector[i]) return FALSE;
  if(!I386AtaTransfer(disk,start,sector,100000,FALSE,0)) return FALSE;
  for(i=0;i<512;i++) if(sector[i]) return FALSE;
  for(block=0;block<bitmap;block++) {
    for(i=0;i<512;i++) sector[i]=0;
    for(bit=0;bit<4096;bit++)
      if(block*4096+bit<2 || block*4096+bit>=valid_bits)
        sector[bit/8]|=1<<(bit&7);
    if(!I386AtaTransfer(disk,start+1+block,sector,100000,TRUE,0)) return FALSE;
  }
  for(i=0;i<512;i++) sector[i]=0;
  sector[0]=0x10; sector[1]=0x08; sector[2]='.';
  I386RedSeaFormatWord(sector+40,root);
  I386RedSeaFormatWord(sector+48,512);
  sector[64]=0x10; sector[65]=0x08; sector[66]='.'; sector[67]='.';
  I386RedSeaFormatWord(sector+64+40,root);
  if(!I386AtaTransfer(disk,root,sector,100000,TRUE,0) ||
      !I386AtaFlushPolled(disk,100000,0)) return FALSE;
  for(i=0;i<512;i++) sector[i]=0;
  sector[3]=0x88;
  I386RedSeaFormatWord(sector+8,start);
  I386RedSeaFormatWord(sector+16,sectors);
  I386RedSeaFormatWord(sector+24,root);
  I386RedSeaFormatWord(sector+32,bitmap);
  I386RedSeaFormatWord(sector+40,1);
  sector[510]=0x55; sector[511]=0xAA;
  return I386AtaTransfer(disk,start,sector,100000,TRUE,0) &&
    I386AtaFlushPolled(disk,100000,0);
}
