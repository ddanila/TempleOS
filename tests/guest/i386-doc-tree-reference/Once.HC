U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
Bool TGDelete(U8 *name){return Del(name)>0;}
#include "::/DocTree.HC"
I64 *v=CAlloc(8);v[0]=TGContract('B');
U8 *line=MStrPrint("EXPORT doc-tree.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original doc tree\n");
