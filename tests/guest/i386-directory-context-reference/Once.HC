U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Context.HC"
if(!DCSetup('B')){Report("FAIL directory context setup\n");Exit;}
I64*v=CAlloc(96),i;U8*line;
for(i=0;i<12;i++){v[i]=DCContract(i);line=MStrPrint("DIRECTORY CONTEXT %d %d\n",i,v[i]);Report(line);Free(line);}
line=MStrPrint("EXPORT directory-context.bin %X %X\n",v,96);Report(line);Free(line);Report("DONE original directory context\n");
