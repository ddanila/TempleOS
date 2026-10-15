U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Replace.HC"
I64*v=CAlloc(80),i;U8*line;
for(i=0;i<10;i++){v[i]=RRContract(i);line=MStrPrint("REPLACE CASE %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT editor-replace.bin %X %X\n",v,80);Report(line);Free(line);Report("DONE original editor replace\n");
