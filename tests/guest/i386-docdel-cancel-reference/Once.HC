U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DeleteCancel.HC"
I64 *v=CAlloc(8);*v=CAContract;
U8 *line=MStrPrint("EXPORT delete-cancel.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original deletion cancellation\n");
