U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ParentEdit.HC"
I64 a=DocParentEditContract;U8 *line=MStrPrint("DOC PARENT EDIT MASK %d\n",a);
Report(line);Free(line);Report("DONE doc link session\n");
