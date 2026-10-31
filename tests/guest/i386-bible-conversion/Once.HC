U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/BibleConversion.HC"
I64 a=BibleConversionContract;U8 *line=MStrPrint("BIBLE CONVERSION MASK %d\n",a);
Report(line);Free(line);Report("DONE doc link session\n");
