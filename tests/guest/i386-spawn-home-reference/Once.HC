U0 SPReport(U8*s){while(*s)OutU8(0xE9,*s++);}
CDrv **SPMapSlot(I64 index){return &blkdev.let_to_drv[index];}
#include "Contract.HC"
U8 *SPSavedHome=blkdev.home_dir;
Cd("B:/");DirMk("SpawnHome");blkdev.home_dir=StrNew("B:/SpawnHome");
if(!SPSetup){SPReport("FAIL spawn home setup\n");Exit;}
SPReport(SPHome);SPReport(" | ");SPReport(SPName);SPReport("\n");
I64 *values=CAlloc(56),i;U8*s;
for(i=0;i<7;i++){values[i]=SPContract(i);s=MStrPrint("SPAWN HOME %d %d\n",i,values[i]);SPReport(s);Free(s);s=MStrPrint("CHILD %d %s %s\n",SPResult,SPActualDir,SPActualName);SPReport(s);Free(s);}
s=MStrPrint("EXPORT spawn-home.bin %X %X\n",values,56);SPReport(s);Free(s);
Free(blkdev.home_dir);blkdev.home_dir=SPSavedHome;
SPReport("DONE original spawn home\n");
