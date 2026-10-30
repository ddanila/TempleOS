U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/KeyMapSortContract.HC"
I64 result=KeyMapSortContract;U8 *line=MStrPrint("KEY MAP SORT MASK %d\n",result);
Report(line);Free(line);Report("DONE key map sort\n");
