U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/KeyDescription.HC"
I64 *v=CAlloc(16);v[0]=KNContract;v[1]=KDContract;
U8*line=MStrPrint("EXPORT key-description.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original key description\n");
