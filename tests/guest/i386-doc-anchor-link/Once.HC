U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/AnchorLink.HC"
I64 result=DocAnchorLinkSession(FALSE),lower=DocAnchorLinkSession(TRUE);
U8 *line=MStrPrint("DOC ANCHOR LINK MASK %d %d\n",result,lower);
Report(line);Free(line);Report("DONE doc link session\n");
