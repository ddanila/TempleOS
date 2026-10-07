CHashDefineStr *DefineLoad(U8 *dname,U8 *st)
{//Create DEFINE hash entry with string.
  CHashDefineStr *tmph=CAlloc(sizeof(CHashDefineStr));
  tmph->type=HTT_DEFINE_STR;
  tmph->str=StrNew(dname);
  tmph->data=StrNew(st);
  tmph->cnt=-1;
  tmph->src_link=MStrPrint("AD:0x%X",Caller);
  HashAdd(tmph,Fs->hash_table);
  return tmph;
}
