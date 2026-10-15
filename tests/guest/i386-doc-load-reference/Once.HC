U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocLoad.HC"
I64 *v=CAlloc(56),i;for(i=0;i<7;i++){Report("LOAD begin\n");v[i]=DLContract(i);Report("LOAD end\n");}
U8 *line=MStrPrint("EXPORT doc-load.bin %X %X\n",v,56);Report(line);Free(line);
Report("DONE original document load\n");
