U0 Report(U8 *s) { while(*s) OutU8(0xE9,*s++); }
U0 DumpDocs()
{
  U8 *names="CDocBin\0CDocSettings\0CDocEntryBase\0CDocEntry\0CEdFindText\0CEdFileName\0CDocUndo\0CDoc\0",*name,*s;
  CHashClass *c;
  CMemberLst *m;
  for(name=names;*name;name+=StrLen(name)+1) {
    c=HashFind(name,Fs->hash_table,HTT_CLASS);
    if(!c) { Report("FAIL doc layout\n"); return; }
    s=MStrPrint("DOC RECORD %s %d\n",name,c->size); Report(s); Free(s);
    for(m=c->member_lst_and_root;m;m=m->next) {
      s=MStrPrint("DOC FIELD %s %s %d %d %d %d\n",name,m->str,m->offset,m->size,
        m->member_class->ptr_stars_cnt,m->dim.total_cnt);
      Report(s); Free(s);
    }
  }
  s=MStrPrint("DOC BIN SPAN %d\n",offset(CDocBin.end)-offset(CDocBin.start));
  Report(s); Free(s);
  Report("DONE doc layout\n");
}
DumpDocs;
