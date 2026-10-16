U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Contract.HC"
if(!DOSetup('B')){Report("FAIL directory owner setup\n");Exit;}
I64*v=CAlloc(32),i;U8*line;
for(i=0;i<4;i++){v[i]=DOContract(i);line=MStrPrint("DIRECTORY OWNER %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT directory-owner.bin %X %X\n",v,32);Report(line);Free(line);Report("DONE original directory owner\n");
