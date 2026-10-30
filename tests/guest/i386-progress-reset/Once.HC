U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ProgressReset.HC"
I64 result=ProgressResetContract;U8 *line=MStrPrint("PROGRESS RESET MASK %d\n",result);
Report(line);Free(line);Report("DONE progress reset\n");
