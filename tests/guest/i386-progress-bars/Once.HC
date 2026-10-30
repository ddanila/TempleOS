U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ProgressBars.HC"
I64 result=ProgressBarsContract;U8 *line=MStrPrint("PROGRESS BARS MASK %d\n",result);
Report(line);Free(line);Report("DONE progress bars\n");
