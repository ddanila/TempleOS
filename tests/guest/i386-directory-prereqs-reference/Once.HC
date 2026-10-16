U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Contract.HC"
I64*v=CAlloc(64),i;U8*line;
for(i=0;i<8;i++){v[i]=DPContract(i);line=MStrPrint("DIRECTORY PREREQS %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT directory-prereqs.bin %X %X\n",v,64);Report(line);Free(line);Report("DONE original directory prerequisites\n");
