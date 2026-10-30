U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/AddressLink.HC"
I64 a=DocAddressLinkSession(FALSE),b=DocAddressLinkSession(TRUE),c=DocAddressLinkMissing;
U8 *line=MStrPrint("DOC ADDRESS LINK MASK %d %d %d\n",a,b,c);
Report(line);Free(line);Report("DONE doc link session\n");
