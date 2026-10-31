U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/RejectUnwind.HC"
I64 a=EditorRejectUnwind(0),b=EditorRejectUnwind(1),c=EditorRejectUnwind(2);
U8 *line=MStrPrint("EDITOR REJECT UNWIND %d %d %d\n",a,b,c);
Report(line);Free(line);Report("DONE doc link session\n");
