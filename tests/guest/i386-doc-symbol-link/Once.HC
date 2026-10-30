U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/SymbolLink.HC"
I64 a=DocSymbolLinkSession(FALSE),b=DocSymbolLinkSession(TRUE),c=DocSymbolLinkMissing;
U8 *line=MStrPrint("DOC SYMBOL LINK MASK %d %d %d\n",a,b,c);
Report(line);Free(line);Report("DONE doc link session\n");
