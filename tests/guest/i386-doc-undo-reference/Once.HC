U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Undo.HC"
I64 *v=CAlloc(56),i;v[0]=DUClock;for(i=0;i<6;i++)v[i+1]=DUContract(i);
U8*line=MStrPrint("EXPORT doc-undo.bin %X %X\n",v,56);Report(line);Free(line);
Report("DONE original undo\n");
