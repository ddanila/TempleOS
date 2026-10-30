U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/LeftLink.HC"
I64 result=LeftLinkContract;U8 *line=MStrPrint("LEFT LINK MASK %d\n",result);
Report(line);Free(line);Report("DONE left link\n");
