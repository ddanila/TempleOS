U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/BibleLink.HC"
I64 a=DocBibleLinkContract;U8 *line=MStrPrint("DOC BIBLE LINK MASK %d\n",a);
Report(line);Free(line);Report("DONE doc link session\n");
