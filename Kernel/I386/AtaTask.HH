#ifndef I386_ATA_TASK_INCLUDED
#define I386_ATA_TASK_INCLUDED
#include "/Kernel/I386/Ata.HH"
#include "/Kernel/I386/AtaChannel.HH"
//Task context only, with working maskable IRQ dispatch and a cooperative scheduler.
//One canonical channel gate for both drives. No cancellation/exception unwinding.
//Root uses bounded IF-clear polling and cannot wait for another owner.
public extern Bool I386AtaTaskIdentify(CI386AtaChannel *channel,CI386Ata *disk,I64 drive,I64 polls=100000);
public extern Bool I386AtaTaskRead(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaTaskWrite(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000);
public extern Bool I386AtaTaskFlush(CI386AtaChannel *channel,CI386Ata *disk,I64 polls=100000);
#endif
