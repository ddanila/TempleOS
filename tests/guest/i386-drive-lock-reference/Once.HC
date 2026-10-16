U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Contract.HC"
I64 *v=CAlloc(112),i;U8 *line;
if(!LKSetup('B')){Report("FAIL lock fixture setup\n");Exit;}
for(i=0;i<14;i++){v[i]=LKContract(i);line=MStrPrint("DRIVE LOCK %d %d\n",i,v[i]);Report(line);Free(line);}
Free(LKPath);
line=MStrPrint("EXPORT drive-lock.bin %X %X\n",v,112);Report(line);Free(line);Report("DONE original drive locking\n");
