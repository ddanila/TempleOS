U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/CallerExit.HC"
I64 *v=CAlloc(8);*v=CEContract;
U8 *line=MStrPrint("EXPORT caller-exit.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original deleter Exit\n");
