U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Interpolation.HC"
I64 *v=CAlloc(8);v[0]=SIContract;
U8 *line=MStrPrint("EXPORT interpolation.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original interpolation\n");
