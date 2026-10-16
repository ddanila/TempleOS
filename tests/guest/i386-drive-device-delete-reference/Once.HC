U0 DBReport(U8*s){while(*s)OutU8(0xE9,*s++);}
DBReport("START original device drive deletion\n");
extern U0 DrvBlkDevDel(CBlkDev *bd);
CDrv *DBRecord(I64 index){return &blkdev.drvs[index];}
#include "Contract.HC"
I64 *values=CAlloc(64),i;U8*s;
for(i=0;i<8;i++){values[i]=DBContract(i);s=MStrPrint("DEVICE DRIVE DELETE %d %d\n",i,values[i]);DBReport(s);Free(s);}
s=MStrPrint("EXPORT drive-device-delete.bin %X %X\n",values,64);DBReport(s);Free(s);
DBReport("DONE original device drive deletion\n");
