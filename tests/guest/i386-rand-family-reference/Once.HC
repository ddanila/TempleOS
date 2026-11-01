U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
#include "::/RandFamily.HC"
I64 *v=RFCollect;
U8*line=MStrPrint("EXPORT rand-family.bin %X %X\n",v,RF_WORDS*8);Report(line);Free(line);
Report("DONE original rand family\n");
