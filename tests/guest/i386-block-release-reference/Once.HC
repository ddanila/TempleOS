U0 BRReport(U8*s){while(*s)OutU8(0xE9,*s++);}
BRReport("START original block device release\n");
CDrv *BRRecord(I64 index){return &blkdev.drvs[index];}
#include "Contract.HC"
CBlkDev *BRBlockRecord(I64 index){return &blkdev.blkdevs[index];}
#include "Table.HC"
I64 *values=CAlloc(128),i;U8*s;
for(i=0;i<16;i++){if(i<8)values[i]=BRContract(i);else values[i]=BRTable(i-8);s=MStrPrint("BLOCK DEVICE RELEASE %d %d\n",i,values[i]);BRReport(s);Free(s);}
s=MStrPrint("EXPORT block-release.bin %X %X\n",values,128);BRReport(s);Free(s);
BRReport("DONE original block device release\n");
