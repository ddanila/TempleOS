U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/TaskWindow.HC"
I64 *v=CAlloc(8);v[0]=TWContract;
U8*line=MStrPrint("EXPORT task-window.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original task window defaults\n");
