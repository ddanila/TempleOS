U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Contract.HC"
if(!DSSetup('B')){Report("FAIL drive state setup\n");Exit;}
I64*v=CAlloc(72),i;U8*line;
for(i=0;i<9;i++){v[i]=DSContract(i);line=MStrPrint("DRIVE STATE %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT drive-state.bin %X %X\n",v,72);Report(line);Free(line);Report("DONE original drive state\n");
