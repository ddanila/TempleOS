U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdOwner.HC"
I64 *v=CAlloc(8);*v=DOContract;
U8 *line=MStrPrint("EXPORT doced-owner.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original DocEd owner retirement\n");
