Bool NativeResidentZ(U8 *name)
{ I64 n=StrLen(name);return n>=2 && name[n-2]=='.' && name[n-1]=='Z'; }
U8 *NativeResidentAlt(U8 *name)
{
  I64 n=StrLen(name),size=n+3;U8 *alt=I386HeapAlloc(console_config->heap,size,TRUE);
  if(!alt)return 0;MemCpy(alt,name,n);
  if(NativeResidentZ(name))alt[n-2]=0;else {alt[n]='.';alt[n+1]='Z';}
  return alt;
}
CHashGeneric *NativeResidentLookup(U8 *name)
{ return HashFind(name,Fs->gs->seth_task->hash_table,HTT_FILE); }
U0 NativeResidentRemove(CHashGeneric *entry)
{
  CHashTable *table=Fs->gs->seth_task->hash_table;CHash **link;I64 i;
  while(table) {
    for(i=0;i<=table->mask;i++) {
      link=table->body+i;
      while(*link) {
        if(*link==entry) {*link=entry->next;Free(entry->str);Free(entry->user_data0);Free(entry);return;}
        link=&(*link)->next;
      }
    }
    table=table->next;
  }
}
U0 NativeResidentPut(U8 *name,U8 *stored,I64 bytes)
{
  CTask *owner=Fs->gs->seth_task;CHashGeneric *entry=NativeResidentLookup(name),*created=0;
  U8 *data=0,*copy=0;I64 n=StrLen(name);
  try {
    data=MAlloc(bytes+1,owner);MemCpy(data,stored,bytes);data[bytes]=0;
    if(!entry) {
      created=CAlloc(sizeof(CHashGeneric),owner);copy=MAlloc(n+1,owner);MemCpy(copy,name,n+1);
      created->str=copy;created->type=HTT_FILE;entry=created;
    }
  } catch {Free(data);Free(copy);Free(created);Fs->catch_except=FALSE;}
  if(!created)Free(entry->user_data0);
  entry->user_data0=data;entry->user_data1=bytes;
  if(created)HashAdd(entry,owner->hash_table);
}
U8 *NativeResidentCopy(U8 *raw,I64 bytes,I64 attr,I64 *size)
{
  U8 *expanded=0,*result;I64 count=bytes;
  if(attr&0x400) {
    expanded=console_config->files->expand(console_config->heap,raw,bytes,&count);
    if(!expanded)return 0;raw=expanded;
  }
  try {result=MAlloc(count+1);MemCpy(result,raw,count);result[count]=0;}
  catch {if(expanded)I386HeapFree(console_config->heap,expanded);Fs->catch_except=FALSE;}
  if(expanded)I386HeapFree(console_config->heap,expanded);
  *size=count;return result;
}
