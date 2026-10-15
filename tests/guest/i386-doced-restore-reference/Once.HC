U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdRestore.HC"
I64 *v=CAlloc(16);v[0]=DRRestore(0);v[1]=DRRestore(1);
U8 *line=MStrPrint("EXPORT doced-restore.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original DocEd restoration\n");
