U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/WinMax.HC"
I64 *v=CAlloc(16);
Report("TARGET begin\n");v[0]=WMTarget;Report("TARGET end\n");
Report("RECOVERY begin\n");v[1]=WMRecover;Report("RECOVERY end\n");
U8 *line=MStrPrint("EXPORT winmax.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original WinMax recovery\n");
