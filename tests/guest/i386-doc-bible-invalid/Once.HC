U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/BibleInvalid.HC"
I64 a=BibleInvalidContract;U8 *line=MStrPrint("BIBLE INVALID MASK %d\n",a);
Report(line);Free(line);Report("DONE doc link session\n");
