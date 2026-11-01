U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Curves2.HC"
I64 *v=CAlloc(8);v[0]=C2Contract;
U8 *line=MStrPrint("EXPORT curves2.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original curves2\n");
