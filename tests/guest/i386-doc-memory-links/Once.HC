U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/MemoryLinks.HC"
I64 a=DocMemoryLinkSession(0,FALSE),b=DocMemoryLinkSession(0,TRUE);
I64 c=DocMemoryLinkSession(1,FALSE),d=DocMemoryLinkSession(1,TRUE);
I64 e=DocMemoryLinkSession(2,FALSE),f=DocMemoryLinkSession(2,TRUE);
I64 g=DocMemoryLinkSession(3,FALSE),h=DocMemoryLinkSession(3,TRUE);
U8 *line=MStrPrint("DOC MEMORY LINK MASK %d %d %d %d %d %d %d %d\n",a,b,c,d,e,f,g,h);
Report(line);Free(line);Report("DONE doc link session\n");
