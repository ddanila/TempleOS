U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PrefixedLink.HC"
I64 result=DocPrefixedLinkSession;U8 *line=MStrPrint("DOC PREFIXED LINK MASK %d\n",result);
Report(line);Free(line);Report("DONE doc link session\n");
