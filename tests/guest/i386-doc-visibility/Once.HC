U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/DocVisibility.HC"
I64 result=DocVisibilityContract;U8 *line=MStrPrint("DOC VISIBILITY MASK %d\n",result);
Report(line);Free(line);Report("DONE doc visibility\n");
