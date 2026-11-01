#include "::/MenuChooser.HC"
I64 *v=CAlloc(104),i;
for(i=0;i<12;i++)v[i]=MCChoose(i);
v[12]=mc_unlocked;
U8 *line=MStrPrint("EXPORT menu-chooser.bin %X %X\n",v,104);Report(line);Free(line);
Report("DONE original menu chooser\n");
