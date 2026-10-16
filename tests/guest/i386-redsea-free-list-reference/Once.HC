U0 RFReport(U8*s){while(*s)OutU8(0xE9,*s++);}
RFReport("START original RedSea free list\n");
extern U0 RedSeaFreeFreeLst(CDrv *dv);U0 RFGate(){RedSeaFreeFreeLst(NULL);}
#include "Contract.HC"
I64 *values=CAlloc(256),i;U8*s;
for(i=0;i<32;i++){values[i]=RFContract(i);s=MStrPrint("FREE LIST %d %d\n",i,values[i]);RFReport(s);Free(s);}
s=MStrPrint("EXPORT redsea-free-list.bin %X %X\n",values,256);RFReport(s);Free(s);
RFReport("DONE original RedSea free list\n");
