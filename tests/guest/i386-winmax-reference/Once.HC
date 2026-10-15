U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/WinMax.HC"
I64 *v=CAlloc(16);v[0]=WMCase(TRUE);v[1]=WMCase(FALSE);
U8 *line=MStrPrint("EXPORT winmax.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original WinMax\n");
