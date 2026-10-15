U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/OwnedDelete.HC"
I64 *v=CAlloc(8);*v=ODContract;
U8 *line=MStrPrint("EXPORT owned-delete.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original owned DocDel\n");
