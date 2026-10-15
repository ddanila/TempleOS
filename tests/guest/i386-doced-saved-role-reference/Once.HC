U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdSavedRole.HC"
I64 *v=CAlloc(48),i;
for(i=0;i<6;i++)v[i]=SRContract(i);
U8 *line=MStrPrint("EXPORT doced-saved-role.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original DocEd saved roles\n");
