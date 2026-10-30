U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/StrICmp.HC"
I64 result=StrICmpContract;U8 *line=MStrPrint("STRICMP MASK %d\n",result);
Report(line);Free(line);Report("DONE stricmp\n");
