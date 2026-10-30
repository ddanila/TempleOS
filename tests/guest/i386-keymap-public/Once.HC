U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/KeyMapPublic.HC"
I64 result=KeyMapPublicContract;U8 *line=MStrPrint("KEY MAP PUBLIC MASK %d\n",result);
Report(line);Free(line);Report("DONE key map public\n");
