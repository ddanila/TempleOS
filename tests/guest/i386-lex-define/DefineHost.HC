I64 DefineCase(U8 *input,U8 *expected)
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHashGeneric keyword;
  CHash *bucket=0; CHashDefineStr *entry; U8 *source; I64 result;
  IdentZero(&table,sizeof(CHashTable)); IdentZero(&keyword,sizeof(CHashGeneric));
  table.body=&bucket; keyword.str="define"; keyword.type=HTT_KEYWORD; keyword.user_data0=KW_DEFINE;
  HashAdd(&keyword,&table);
  source=MStrPrint("#define Test %s",input);
  IdentSeed(&cc,&file,source); file.full_name="DefineFixture";
  cc.htc.hash_table_lst=cc.htc.define_hash_table=&table;
  Lex(&cc);
  entry=HashFind("Test",&table,HTT_DEFINE_STR);
  result=!entry;
  if(entry) {
    if(StrCmp(entry->data,expected)) result=1;
    Free(entry->str); Free(entry->src_link); Free(entry->idx); Free(entry->data); Free(entry);
  }
  MacroTextFree(&cc); Free(source);
  return result;
}
