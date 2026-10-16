U0 DMReport(U8*s){while(*s)OutU8(0xE9,*s++);}
CDrv **DMMapSlot(I64 index){return &blkdev.let_to_drv[index];}
CDrv *DMRecord(I64 index){return &blkdev.drvs[index];}
#include "Contract.HC"
if(!DMSetup('B')){DMReport("FAIL drive map setup\n");Exit;}
I64 *values=CAlloc(120),i;U8*s;
for(i=0;i<15;i++){values[i]=DMContract(i);s=MStrPrint("DRIVE MAP %d %d\n",i,values[i]);DMReport(s);Free(s);}
s=MStrPrint("EXPORT drive-map.bin %X %X\n",values,120);DMReport(s);Free(s);
DMReport("DONE original drive map\n");
