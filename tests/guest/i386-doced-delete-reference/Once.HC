U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdDelete.HC"
I64 *v=CAlloc(24),i;
for(i=0;i<3;i++)v[i]=DDContract(i);
U8 *line=MStrPrint("EXPORT doced-delete.bin %X %X\n",v,24);Report(line);Free(line);
Report("DONE original DocEd deletion\n");
