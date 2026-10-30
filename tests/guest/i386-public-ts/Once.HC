U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PublicTS.HC"
I64 result=PublicTSContract;U8 *line=MStrPrint("PUBLIC TS MASK %d\n",result);
Report(line);Free(line);Report("DONE public ts\n");
