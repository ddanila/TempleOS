#include "::/MenuChooser.HC"
I64 *v=CAlloc(48),i;
for(i=0;i<6;i++)v[i]=MCLarge(i);
U8 *line=MStrPrint("EXPORT large-page.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original large page\n");
