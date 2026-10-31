U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ReadUnwind.HC"
I64 mask=DocReadUnwindContract;
U8 *line=MStrPrint("DOC READ UNWIND %d\n",mask);
Report(line);Free(line);Report("DONE doc read unwind\n");
