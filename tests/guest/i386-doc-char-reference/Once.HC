U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocChar.HC"
I64 *v=CAlloc(88),i;for(i=0;i<8;i++)v[i]=DCContract(i);for(i=0;i<3;i++)v[8+i]=DCForm(i);
U8 *line=MStrPrint("EXPORT doc-char.bin %X %X\n",v,88);Report(line);Free(line);
Report("DONE original document characters\n");
