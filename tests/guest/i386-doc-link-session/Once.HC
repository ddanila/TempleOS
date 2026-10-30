U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/LinkSession.HC"
I64 result=DocLinkSession;U8 *line=MStrPrint("DOC LINK SESSION MASK %d\n",result);
Report(line);Free(line);Report("DONE doc link session\n");
