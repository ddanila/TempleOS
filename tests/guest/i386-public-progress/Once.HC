U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PublicProgress.HC"
I64 result=PublicProgressContract;U8 *line=MStrPrint("PUBLIC PROGRESS MASK %d\n",result);
Report(line);Free(line);Report("DONE public progress\n");
