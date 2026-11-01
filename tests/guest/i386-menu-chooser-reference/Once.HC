#include "::/MenuChooser.HC"
I64 *v=CAlloc(72),i;
for(i=0;i<8;i++)v[i]=MCChoose(i);
v[8]=mc_unlocked;
U8 *line=MStrPrint("EXPORT menu-chooser.bin %X %X\n",v,72);Report(line);Free(line);
Report("DONE original menu chooser\n");
