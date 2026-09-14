#ifndef I386_ATA_INCLUDED
#define I386_ATA_INCLUDED
class CI386AtaPoll {
  U8 *context;
  U0 (*step)(U8 *context);
  Bool touched;
};
class CI386Ata {
  U32 signature,sectors,cylinders,heads,sectors_per_track;
  U16 io,control;
  U8 drive,lba,flush;
};
//Internal shared protocol: optional synchronous poll callback, IF clear on return.
//The caller owns channel exclusion, callback lifetime and touched initialization.
public extern Bool I386AtaIdentifyPolled(CI386Ata *disk,I64 channel,I64 drive,I64 polls,CI386AtaPoll *poll);
public extern Bool I386AtaTransfer(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls,Bool write,CI386AtaPoll *poll);
public extern Bool I386AtaFlushPolled(CI386Ata *disk,I64 polls,CI386AtaPoll *poll);
public extern Bool I386AtaIdentify(CI386Ata *disk,I64 channel,I64 drive,I64 polls=100000);
public extern Bool I386AtaRead(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaWrite(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaFlush(CI386Ata *disk,I64 polls=100000);
#endif
