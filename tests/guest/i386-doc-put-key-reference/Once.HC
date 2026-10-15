U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/PutKey.HC"
I64 *v=CAlloc(48),i;for(i=0;i<6;i++)v[i]=PKContract(i);
U8*line=MStrPrint("EXPORT doc-put-key.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original put key\n");
