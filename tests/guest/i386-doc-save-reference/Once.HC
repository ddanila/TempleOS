U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
#include "::/DocSave.HC"
I64 *v=CAlloc(144),i;for(i=0;i<8;i++)v[i]=DSPlain(i);for(i=0;i<10;i++)v[8+i]=DSSave(i);
U8 *line=MStrPrint("EXPORT doc-save.bin %X %X\n",v,144);Report(line);Free(line);
Report("DONE original serialization\n");
