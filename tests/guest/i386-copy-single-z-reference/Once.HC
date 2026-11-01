U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
extern Bool CopySingleZ(U8 *f1,U8 *f2);
Bool CSDelete(U8 *name){return Del(name)>0;}
#include "::/CopySingleZ.HC"
I64 *v=CAlloc(8);v[0]=CSContract('B');
U8*line=MStrPrint("EXPORT copy-single-z.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original copy single z\n");
