U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Transform.HC"
I64*v=CAlloc(88),i;for(i=0;i<3;i++)v[i]=TTCollapse(i);for(i=0;i<2;i++)v[i+3]=TTFlags(i);for(i=0;i<6;i++)v[i+5]=TTEntry(i);
U8*line=MStrPrint("EXPORT doc-transform.bin %X %X\n",v,88);Report(line);Free(line);Report("DONE original transforms\n");
