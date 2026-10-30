U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/PlainLinks.HC"
I64 a=DocPlainLinkSession(0,FALSE),b=DocPlainLinkSession(0,TRUE);
I64 c=DocPlainLinkSession(1,FALSE),d=DocPlainLinkSession(1,TRUE);
I64 e=DocPlainLinkSession(2,FALSE),f=DocPlainLinkSession(2,TRUE);
I64 g=DocPlainLinkSession(3,FALSE);
U8 *line=MStrPrint("DOC PLAIN LINK MASK %d %d %d %d %d %d %d\n",a,b,c,d,e,f,g);
Report(line);Free(line);Report("DONE doc link session\n");
