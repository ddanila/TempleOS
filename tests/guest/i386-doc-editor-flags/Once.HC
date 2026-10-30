U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Cd("T:/");
#include "T:/Probe/EditorFlags.HC"
I64 i,r,all=TRUE;U8 *line;
for(i=0;i<11;i++) {
  r=DocEditorFlagContract(i);line=MStrPrint("DOC EDITOR FLAG %d %d\n",i,r);Report(line);Free(line);
  if(r!=7)all=FALSE;
}
if(all)Report("DOC EDITOR FLAGS PASS\n");
Report("DONE doc link session\n");
