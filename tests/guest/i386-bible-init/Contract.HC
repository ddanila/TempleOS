U32 BIHash(U32 value,U8 *text)
{
  do {value^=*text;value*=16777619;} while(*text++);
  return value;
}
U32 bi_observed_hash,bi_expected_hash=2197347177;
I64 JRContract()
{
  I64 mask=0,i,base=Fs->data_heap->used_u8s;
  U32 hash=2166136261;
  U8 *buf=StrNew("borrowed text"),*actual_bytes=&bi_observed_hash,*expected_bytes=&bi_expected_hash;
  Bool hash_ok=TRUE;
  CHashDefineStr *entry;
  if(DefineCnt("ST_BIBLE_BOOKS")==66 && DefineCnt("ST_BIBLE_BOOK_LINES")==67 && Str2I64(Define("ST_BIBLE_LINES"))==100110)mask|=1;
  for(i=0;i<DefineCnt("ST_BIBLE_BOOKS");i++)hash=BIHash(hash,DefineSub(i,"ST_BIBLE_BOOKS"));
  for(i=0;i<DefineCnt("ST_BIBLE_BOOK_LINES");i++)hash=BIHash(hash,DefineSub(i,"ST_BIBLE_BOOK_LINES"));
  bi_observed_hash=hash;
  for(i=0;i<4;i++)if(actual_bytes[i]!=expected_bytes[i])hash_ok=FALSE;
  if(hash_ok)mask|=2;
  if(DefineMatch("genesis","ST_BIBLE_BOOKS",LMF_IGNORE_CASE)==0 && DefineMatch("Revelation","ST_BIBLE_BOOKS")==65 && DefineMatch("NoBook","ST_BIBLE_BOOKS")==-1)mask|=4;
  entry=DefineLoad("BI_OWNED",buf);buf[0]='X';Free(buf);
  if(!StrCmp(Define("BI_OWNED"),"borrowed text"))mask|=8;
  if(entry->src_link && entry->src_link[0]=='A' && entry->src_link[1]=='D' && entry->src_link[2]==':')mask|=32;
  HashRemDel(entry,Fs->hash_table);
  DefinePrint("BI_FORMAT","%d:%s",42,"word");
  if(!StrCmp(Define("BI_FORMAT"),"42:word"))mask|=16;
  HashRemDel(HashFind("BI_FORMAT",Fs->hash_table,HTT_DEFINE_STR),Fs->hash_table);
  for(i=0;i<10;i++) {
    DefinePrint("BI_REPEAT","%d:%s",i,"cycle");
    HashRemDel(HashFind("BI_REPEAT",Fs->hash_table,HTT_DEFINE_STR),Fs->hash_table);
  }
  if(Fs->data_heap->used_u8s==base)mask|=64;
  return mask;
}
