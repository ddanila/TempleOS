U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/StringMatch.HC"
I64 result=StringMatchContract;U8 *line=MStrPrint("STRING MATCH MASK %d\n",result);
Report(line);Free(line);Report("DONE string match\n");
