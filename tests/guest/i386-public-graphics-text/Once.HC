U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PublicText.HC"
I64 result=PublicTextContract;U8 *line=MStrPrint("PUBLIC TEXT MASK %d\n",result);
Report(line);Free(line);Report("DONE public text\n");
