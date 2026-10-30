U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/FileExtension.HC"
I64 result=FileExtensionContract;U8 *line=MStrPrint("FILE EXTENSION MASK %d\n",result);
Report(line);Free(line);Report("DONE file extension public\n");
