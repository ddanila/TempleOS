U0 Report(U8 *s) { while(*s) OutU8(0xE9,*s++); }
U0 DumpMemory()
{
  U8 *names="CMemUnused\0CMemUsed\0CMemBlk\0CMemRange\0CBlkPool\0CHeapCtrl\0",*name,*s;
  CHashClass *c;
  CMemberLst *m;
  I64 i;
  for(i=0;i<6;i++) {
    name=names;
    c=HashFind(name,Fs->hash_table,HTT_CLASS);
    s=MStrPrint("MEMORY CLASS %s %d\n",name,c->size); Report(s); Free(s);
    for(m=c->member_lst_and_root;m;m=m->next) {
      s=MStrPrint("MEMORY FIELD %s %s %d %d %d %d\n",name,m->str,m->offset,m->size,m->member_class->ptr_stars_cnt,m->dim.total_cnt);
      Report(s); Free(s);
    }
    names+=StrLen(names)+1;
  }
  Report("DONE memory layout\n");
}
DumpMemory;
