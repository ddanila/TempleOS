//Original public table/list policy with explicit allocator and destructor services.
CHashTable *HashTableNewCore(I64 size,CTask *task,
  U8 *(*allocate)(I64 size,CTask *task),U0 (*release)(U8 *allocation))
{
  CHashTable *table=0;
  try {
    table=(*allocate)(sizeof(CHashTable),task);
    table->body=(*allocate)(size*sizeof(CHash *),task);
  } catch {
    (*release)(table); //Leave the exception unhandled so the caller receives it.
  }
  table->mask=size-1;
  return table;
}
U0 HashTableDelCore(CHashTable *table,U0 (*destroy)(CHashSrcSym *symbol),
  U0 (*release)(U8 *allocation))
{
  I64 i;
  CHashSrcSym *node,*next;
  if(!table) return;
  for(i=0;i<=table->mask;i++) {
    node=table->body[i];
    while(node) {
      next=node->next;
      (*destroy)(node); node=next;
    }
  }
  (*release)(table->body); (*release)(table);
}
I64 HashLstAddCore(U8 *list,I64 type,CHashTable *table,
  U8 *(*allocate)(I64 size,CTask *task),U8 *(*copy)(U8 *str,CTask *task),
  U0 (*release)(U8 *allocation),U0 (*insert)(CHash *entry,CHashTable *table))
{
  I64 count=0;
  CHashGeneric *entry;
  if(list) while(*list) {
    if(*list=='@') list++;
    else count++;
    entry=0;
    try {
      entry=(*allocate)(sizeof(CHashGeneric),0);
      entry->user_data0=count-1; entry->type=type;
      entry->str=(*copy)(list,0);
    }
    catch { (*release)(entry); }
    (*insert)(entry,table);
    while(*list++);
  }
  return count;
}
