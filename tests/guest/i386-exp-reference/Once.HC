U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Exp.HC"
U64 *v=EXCollect;
U8 *line=MStrPrint("EXPORT exp.bin %X %X\n",v,256*8);Report(line);Free(line);
Report("DONE original exp\n");
