U0 Report(U8*s){while(*s)OutU8(0xE9,*s++);}
Bool RGDelete(U8 *name){return Del(name)>0;}
CDoc *RGDoc(){CHashGlblVar *symbol=HashFind("sys_registry_doc",adam_task->hash_table,HTT_GLBL_VAR);if(symbol&&symbol->data_addr)return *(symbol->data_addr)(CDoc **);return NULL;}
#include "::/Registry.HC"
I64 *v=CAlloc(8);v[0]=RGContract('B');
U8 *line=MStrPrint("EXPORT registry.bin %X %X\n",v,8);Report(line);Free(line);
Report("DONE original registry\n");
