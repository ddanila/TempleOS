U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Replace.HC"
I64*v=CAlloc(112),i;U8*line;
for(i=0;i<10;i++){v[i]=RRContract(i);line=MStrPrint("REPLACE CASE %d %d\n",i,v[i]);Report(line);Free(line);}
for(i=0;i<3;i++){v[i+10]=RRLine(i);line=MStrPrint("GOTO CASE %d %d\n",i,v[i+10]);Report(line);Free(line);}v[13]=RRMeta;
line=MStrPrint("EXPORT editor-replace.bin %X %X\n",v,112);Report(line);Free(line);Report("DONE original editor replace\n");
