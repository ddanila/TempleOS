I64 KeywordMapTest(CHashTable *table)
{
  CCompilerKeyword *descriptor; CHashGeneric *entry; I64 i;
  for(i=0;i<COMPILER_KEYWORDS_NUM;i++) {
    descriptor=compiler_keywords+i;
    entry=HashFind(descriptor->name,table,descriptor->type);
    if(!entry || StrCmp(entry->str,descriptor->name) || entry->type!=descriptor->type ||
        entry->user_data0!=descriptor->value) return 100+i;
    if(HashFind(descriptor->name,table,descriptor->type,2)) return 200+i;
  }
  if(HashFind("Include",table,HTT_KEYWORD) || HashFind("USE32",table,HTT_KEYWORD) ||
      HashFind("define",table,HTT_ASM_KEYWORD)) return 300;
  return 0;
}
