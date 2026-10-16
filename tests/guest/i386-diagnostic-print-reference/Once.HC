#include "Contract.HC"
U0 DPReport(U8*s){while(*s)OutU8(0xE9,*s++);}
I64 *values=CAlloc(64),i;U8*s;
for(i=0;i<8;i++){if(i<6)values[i]=DPContract(i);else values[i]=DPRaw(i);s=MStrPrint("DIAGNOSTIC %d %d\n",i,values[i]);DPReport(s);Free(s);}
s=MStrPrint("EXPORT diagnostic-print.bin %X %X\n",values,64);DPReport(s);Free(s);
DPReport("DONE original diagnostic printing\n");
