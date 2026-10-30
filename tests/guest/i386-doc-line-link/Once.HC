U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/LineLink.HC"
I64 result=DocLineLinkSession(FALSE),lower=DocLineLinkSession(TRUE);
U8 *line=MStrPrint("DOC LINE LINK MASK %d %d\n",result,lower);
Report(line);Free(line);Report("DONE doc link session\n");
