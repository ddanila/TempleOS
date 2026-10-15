U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocEdFailure.HC"
I64 *v=CAlloc(16);v[0]=DEFailure(FALSE);v[1]=DEFailure(TRUE);
U8 *line=MStrPrint("EXPORT doced-failure.bin %X %X\n",v,16);Report(line);Free(line);
Report("DONE original DocEd failure\n");
