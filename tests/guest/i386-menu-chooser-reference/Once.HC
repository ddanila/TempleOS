#include "::/MenuChooser.HC"
I64 *v=CAlloc(120),i;
for(i=0;i<14;i++)v[i]=MCChoose(i);
v[14]=mc_unlocked;
U8 *line=MStrPrint("EXPORT menu-chooser.bin %X %X\n",v,120);Report(line);Free(line);
Report("DONE original menu chooser\n");
