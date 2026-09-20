//Build an owned definition list; publish only after all allocations succeed.
CHashDefineStr *DefineLstLoadCore(U8 *name,U8 *list,CHashTable *table,U8 *caller,
  U8 *(*allocate)(I64 size,CTask *task),U8 *(*copy)(U8 *str,CTask *task),
  U8 *(*source_link)(U8 *caller),U0 (*destroy)(CHashSrcSym *entry),
  U0 (*insert)(CHash *entry,CHashTable *table))
{
  CHashDefineStr *entry=0;
  U8 *ptr,**idx;
  I64 count=0,bytes,i;
  try {
    entry=(*allocate)(sizeof(CHashDefineStr),0);
    entry->type=HTT_DEFINE_STR;
    entry->str=(*copy)(name,0);
    entry->src_link=(*source_link)(caller);
    ptr=list;
    while(*ptr) {
      if(*ptr!='@') count++;
      while(*ptr++);
    }
    bytes=ptr+1-list;
    entry->data=(*allocate)(bytes,0);
    for(i=0;i<bytes;i++) entry->data[i]=list[i];
    entry->cnt=count;
    idx=entry->sub_idx=(*allocate)(count*sizeof(U8 *),0);
    ptr=entry->data;
    while(*ptr) {
      if(*ptr!='@') *idx++=ptr;
      while(*ptr++);
    }
  } catch { (*destroy)(entry); }
  (*insert)(entry,table);
  return entry;
}
