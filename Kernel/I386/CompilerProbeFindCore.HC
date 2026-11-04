CHash *ProbeSymbolFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{
  I64 i;
  CHash *entry;
  for(i=0;i<=table->mask;i++)
    for(entry=table->body[i];entry;entry=entry->next)
      if(entry->type&mask && !StrCmp(entry->str,name)) return entry;
  return 0;
}
