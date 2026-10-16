U0 DDReport(U8*s){while(*s)OutU8(0xE9,*s++);}
DDReport("START original drive deletion\n");
U0 DDGate(){DrvDel(NULL);}
#include "Contract.HC"
I64 *values=CAlloc(448),i;U8*s;
for(i=0;i<56;i++){values[i]=DDContract(i);s=MStrPrint("DRIVE DELETE %d %d\n",i,values[i]);DDReport(s);Free(s);}
s=MStrPrint("EXPORT drive-delete.bin %X %X\n",values,448);DDReport(s);Free(s);
DDReport("DONE original drive deletion\n");
