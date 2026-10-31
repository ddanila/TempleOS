U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ReadMissing.HC"
I64 mask=DocReadMissingContract;
U8 *line=MStrPrint("DOC READ MISSING %d\n",mask);
Report(line);Free(line);Report("DONE doc read missing\n");
