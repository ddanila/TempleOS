U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/Main.HC"
I64 result=EmbeddedCheck;U8 *line=MStrPrint("DOCUMENT INCLUDE MASK %d\n",result);
Report(line);Free(line);Report("DONE document include\n");
