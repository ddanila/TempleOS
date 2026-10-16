U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Contract.HC"
I64*v=CAlloc(96),i;U8*line;
for(i=0;i<12;i++){v[i]=DLContract(i);line=MStrPrint("DRIVE LOOKUP %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT drive-lookup.bin %X %X\n",v,96);Report(line);Free(line);Report("DONE original drive lookup\n");
