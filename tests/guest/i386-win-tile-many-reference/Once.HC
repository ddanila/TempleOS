U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/WinTile.HC"
I64 *v=CAlloc(16),i;for(i=0;i<2;i++)v[i]=TILCase(i);
U8*line=MStrPrint("EXPORT wintile.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original five-window tiling\n");
