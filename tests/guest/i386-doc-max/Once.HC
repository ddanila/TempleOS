U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/DocMax.HC"
I64 result=DocMaxContract;U8 *line=MStrPrint("DOC MAX MASK %d\n",result);
Report(line);Free(line);Report("DONE doc max\n");
