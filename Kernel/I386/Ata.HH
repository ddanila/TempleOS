#ifndef I386_ATA_INCLUDED
#define I386_ATA_INCLUDED
class CI386Ata {
  U32 signature,sectors,cylinders,heads,sectors_per_track;
  U16 io,control;
  U8 drive,lba,flush;
};
public extern Bool I386AtaIdentify(CI386Ata *disk,I64 channel,I64 drive,I64 polls=100000);
public extern Bool I386AtaRead(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaWrite(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaFlush(CI386Ata *disk,I64 polls=100000);
#endif
