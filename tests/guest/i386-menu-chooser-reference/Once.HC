#include "::/MenuChooser.HC"
I64 *v=CAlloc(48),i;
for(i=0;i<5;i++)v[i]=MCChoose(i);
v[5]=mc_unlocked;
U8 *line=MStrPrint("EXPORT menu-chooser.bin %X %X\n",v,48);Report(line);Free(line);
Report("DONE original menu chooser\n");
