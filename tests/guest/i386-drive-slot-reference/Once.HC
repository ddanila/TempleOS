U0 DSReport(U8*s){while(*s)OutU8(0xE9,*s++);}
DSReport("START original drive slots\n");
#define DS_TABLE_ENTER Bool ds_single=SingleUser(TRUE);
#define DS_TABLE_LEAVE SingleUser(ds_single);
CDrv *DSRecord(I64 index){return &blkdev.drvs[index];}
#include "Contract.HC"
I64 *values=CAlloc(336),i;U8*s;
for(i=0;i<42;i++){values[i]=DSContract(i);s=MStrPrint("DRIVE SLOT %d %d\n",i,values[i]);DSReport(s);Free(s);}
s=MStrPrint("EXPORT drive-slot.bin %X %X\n",values,336);DSReport(s);Free(s);
DSReport("DONE original drive slots\n");
