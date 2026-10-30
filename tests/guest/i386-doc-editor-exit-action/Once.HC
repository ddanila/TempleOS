U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/ExitAction.HC"
I64 a=DocEditorExitAction(FALSE),b=DocEditorExitAction(TRUE);
U8 *line=MStrPrint("DOC EXIT ACTION MASK %d %d\n",a,b);
Report(line);Free(line);Report("DONE doc link session\n");
