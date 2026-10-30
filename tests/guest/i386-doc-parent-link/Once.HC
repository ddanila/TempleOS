U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ParentLink.HC"
I64 a=DocParentLinkContract(0),b=DocParentLinkContract(1);
U8 *line=MStrPrint("DOC PARENT LINK MASK %d %d\n",a,b);
Report(line);Free(line);Report("DONE doc link session\n");
