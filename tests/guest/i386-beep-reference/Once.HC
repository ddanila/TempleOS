U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Beep.HC"
I64 *v=CAlloc(8);v[0]=BEContract;
U8 *line=MStrPrint("EXPORT beep.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original beep\n");
