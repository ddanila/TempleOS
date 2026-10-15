U0 Report(U8*text){while(*text)OutU8(0xE9,*text++);}
#include "T:/Contract.HC"
I64 su_masks[11],su_i;
for(su_i=0;su_i<11;su_i++)su_masks[su_i]=SUContract(su_i);
U8*su_line=MStrPrint("EXPORT string-util.bin %X %X\n",su_masks,sizeof(su_masks));
Report(su_line);Free(su_line);
Report("DONE original string utilities\n");
