U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/Search.HC"
I64*v=CAlloc(128),i;v[0]=SFString;for(i=0;i<8;i++)v[i+1]=SFNext(i);for(i=0;i<5;i++)v[i+9]=SFPair(i);for(i=0;i<2;i++)v[i+14]=SFFunction(i);
U8*line=MStrPrint("EXPORT editor-search.bin %X %X\n",v,128);Report(line);Free(line);Report("DONE original editor search\n");
