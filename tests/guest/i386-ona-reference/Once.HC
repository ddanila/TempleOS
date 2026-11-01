U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Notes.HC"
F64 *v=ONCollect;
U8 *line=MStrPrint("EXPORT ona.bin %X %X\n",v,256*8);Report(line);Free(line);
Report("DONE original ona\n");
