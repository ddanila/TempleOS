U0 BRReport(U8*s){while(*s)OutU8(0xE9,*s++);}
BRReport("START original block device release\n");
CDrv *BRRecord(I64 index){return &blkdev.drvs[index];}
#include "Contract.HC"
I64 *values=CAlloc(64),i;U8*s;
for(i=0;i<8;i++){values[i]=BRContract(i);s=MStrPrint("BLOCK DEVICE RELEASE %d %d\n",i,values[i]);BRReport(s);Free(s);}
s=MStrPrint("EXPORT block-release.bin %X %X\n",values,64);BRReport(s);Free(s);
BRReport("DONE original block device release\n");
