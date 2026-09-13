#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Ata.HH"
U0 I386AtaPause(U16 control)
{
  I64 i;
  for (i=0;i<4;i++) InU8(control);
}
Bool I386AtaSelect(U16 io,U16 control,U8 device,I64 polls)
{//Do not change selection while the current device is busy.
  I64 i;
  U8 status;
  for (i=0;i<polls;i++) {
    status=InU8(io+7);
    if (status==255) return FALSE;
    if (!(status&0x80)) {
      OutU8(io+6,device); I386AtaPause(control); return TRUE;
    }
    InU8(0x80);
  }
  return FALSE;
}
Bool I386AtaWait(U16 io,U8 mask,U8 wanted,Bool errors,I64 polls)
{
  I64 i;
  U8 status;
  for (i=0;i<polls;i++) {
    status=InU8(io+7);
    if (!status || status==255) return FALSE;
    if (!(status&0x80)) {
      if (errors && (status&0x21)) return FALSE;
      if ((status&mask)==wanted) return TRUE;
    }
    InU8(0x80);
  }
  return FALSE;
}
Bool I386AtaDecode(CI386Ata *disk,U16 *words,I64 channel,I64 drive)
{//Decode a complete IDENTIFY response without I/O; publish only a usable profile.
  U32 cylinders,heads,spt,sectors;
  Bool lba;
  if (!disk || !words || channel<0 || channel>1 || drive<0 || drive>1 ||
      (words[0]&0x8000)) return FALSE;
  if ((words[106]&0xD000)==0x5000 && (words[117]!=256 || words[118])) return FALSE;
  cylinders=words[1]; heads=words[3]; spt=words[6];
  if (words[53]&1) { cylinders=words[54]; heads=words[55]; spt=words[56]; }
  if (!cylinders || !heads || heads>16 || !spt || spt>255) {
    cylinders=0; heads=0; spt=0;
  }
  lba=(words[49]&0x200)!=0;
  sectors=cylinders*heads*spt;
  if (lba) {
    sectors=words[60]|(words[61]<<16);
    if (sectors>0x10000000) sectors=0x10000000;
  }
  if (!sectors) return FALSE;
  disk->signature=0x41543332; disk->sectors=sectors;
  disk->cylinders=cylinders; disk->heads=heads; disk->sectors_per_track=spt;
  disk->io=0x1F0; disk->control=0x3F6;
  if (channel) { disk->io=0x170; disk->control=0x376; }
  disk->drive=drive; disk->lba=lba;
  return TRUE;
}
public Bool I386AtaIdentify(CI386Ata *disk,I64 channel,I64 drive,I64 polls=100000)
{//Boot-owned compatibility ports, IF clear. Leave device IRQs disabled.
  U16 words[256],io=0x1F0,control=0x3F6;
  I64 i;
  if (!disk || channel<0 || channel>1 || drive<0 || drive>1 || polls<1 || polls>100000)
    return FALSE;
  if (channel) { io=0x170; control=0x376; }
  OutU8(control,0x0A);
  if (!I386AtaSelect(io,control,0xA0|(drive<<4),polls)) return FALSE;
  if (!I386AtaWait(io,0x80,0,FALSE,polls)) return FALSE;
  OutU8(io+2,0); OutU8(io+3,0); OutU8(io+4,0); OutU8(io+5,0);
  OutU8(io+7,0xEC); I386AtaPause(control);
  if (!I386AtaWait(io,8,8,TRUE,polls)) return FALSE;
  for (i=0;i<256;i++) words[i]=InU16(io);
  I386AtaPause(control);
  if (!I386AtaWait(io,8,0,TRUE,polls)) return FALSE;
  return I386AtaDecode(disk,words,channel,drive);
}
public Bool I386AtaRead(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000)
{//One logical sector via LBA28 or CHS; publish only after successful completion.
  U16 words[256];
  I64 i,cylinder,track;
  U16 io;
  U8 device,sector,cl,ch;
  if (!disk || disk->signature!=0x41543332 || !buffer || polls<1 || polls>100000 ||
      lba<0 || lba>=disk->sectors || lba>=0x10000000 || disk->drive>1 ||
      !((disk->io==0x1F0 && disk->control==0x3F6) ||
        (disk->io==0x170 && disk->control==0x376))) return FALSE;
  device=0xE0|(disk->drive<<4)|((lba>>24)&15);
  sector=lba; cl=lba>>8; ch=lba>>16;
  if (!disk->lba) {
    if (!disk->cylinders || disk->cylinders>65535 || !disk->heads || disk->heads>16 ||
        !disk->sectors_per_track || disk->sectors_per_track>255 ||
        lba>=disk->cylinders*disk->heads*disk->sectors_per_track) return FALSE;
    sector=lba%disk->sectors_per_track+1;
    track=lba/disk->sectors_per_track;
    cylinder=track/disk->heads;
    device=0xA0|(disk->drive<<4)|(track%disk->heads);
    cl=cylinder; ch=cylinder>>8;
  }
  io=disk->io;
  OutU8(disk->control,0x0A);
  if (!I386AtaSelect(io,disk->control,device,polls) ||
      !I386AtaWait(io,0x48,0x40,FALSE,polls)) return FALSE;
  OutU8(io+1,0); OutU8(io+2,1);
  OutU8(io+3,sector); OutU8(io+4,cl); OutU8(io+5,ch);
  OutU8(io+7,0x20); I386AtaPause(disk->control);
  if (!I386AtaWait(io,8,8,TRUE,polls)) return FALSE;
  for (i=0;i<256;i++) words[i]=InU16(io);
  I386AtaPause(disk->control);
  if (!I386AtaWait(io,8,0,TRUE,polls)) return FALSE;
  for (i=0;i<256;i++) { buffer[2*i]=words[i]; buffer[2*i+1]=words[i]>>8; }
  return TRUE;
}
