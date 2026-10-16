U0 BSReport(U8*s){while(*s)OutU8(0xE9,*s++);}
BSReport("START original block device slots\n");
//Suppress original exception logging only while the physical table is borrowed.
#define BS_TABLE_ENTER Bool bs_single=SingleUser(TRUE);
#define BS_TABLE_LEAVE SingleUser(bs_single);
CBlkDev *BSRecord(I64 index){return &blkdev.blkdevs[index];}
#include "Contract.HC"
I64 *values=CAlloc(160),i;U8*s;
for(i=0;i<20;i++){values[i]=BSContract(i);s=MStrPrint("BLOCK DEVICE SLOT %d %d\n",i,values[i]);BSReport(s);Free(s);}
s=MStrPrint("EXPORT block-slot.bin %X %X\n",values,160);BSReport(s);Free(s);
BSReport("DONE original block device slots\n");
