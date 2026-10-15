U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdState.HC"
I64 *v=CAlloc(48),i;
for(i=0;i<6;i++){Report("DOCED begin\n");v[i]=DEState(i);Report("DOCED end\n");}
U8 *line=MStrPrint("EXPORT doced-state.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original DocEd state\n");
