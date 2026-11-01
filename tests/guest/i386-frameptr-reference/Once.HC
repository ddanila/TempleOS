U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Frame.HC"
I64 *v=CAlloc(8);v[0]=FPContract;
U8 *line=MStrPrint("EXPORT frame.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original frame\n");
