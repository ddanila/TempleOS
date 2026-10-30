U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/FindLink.HC"
I64 result=DocFindLinkSession(FALSE),lower=DocFindLinkSession(TRUE);
U8 *line=MStrPrint("DOC FIND LINK MASK %d %d\n",result,lower);
Report(line);Free(line);Report("DONE doc link session\n");
