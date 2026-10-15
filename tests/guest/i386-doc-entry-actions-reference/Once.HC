U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEntryActions.HC"
I64 *v=CAlloc(64),i;for(i=0;i<8;i++)v[i]=DAAction(i);
U8 *line=MStrPrint("EXPORT doc-entry-actions.bin %X %X\n",v,64);Report(line);Free(line);
Report("DONE original entry actions\n");
