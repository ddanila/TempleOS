#include "/Kernel/I386/DocDefaultsCheck.HC"
I64 DocInitCheck()
{
  U8 *names[4],*ptr;
  I64 counts[4],types[4],group,i,count=0,total=0,before;
  CHashDefineStr *definition;
  CHashGeneric *entry;
  CHashTable *temporary;
  names[0]="ST_DOC_CMDS"; names[1]="ST_DOC_FLAGS";
  names[2]="ST_COLORS"; names[3]="ST_LINK_TYPES";
  counts[0]=43; counts[1]=62; counts[2]=16; counts[3]=16;
  types[0]=DHT_DOC_CMD; types[1]=DHT_DOC_FLAG; types[2]=DHT_COLOR; types[3]=0;
  if(!doldoc.hash || doldoc.hash->mask!=511 || doldoc.hash->next) return -1;
  for(group=0;group<4;group++) {
    definition=HashFind(names[group],Fs->hash_table,HTT_DEFINE_STR);
    if(!definition || definition->cnt!=counts[group]) return -2;
    ptr=definition->data;
    for(i=0;i<counts[group];i++) {
      if(!*ptr || definition->sub_idx[i]!=ptr) return -3;
      if(types[group]) {
        entry=HashFind(ptr,doldoc.hash,types[group]);
        if(!entry || entry->type!=types[group] || entry->user_data0!=i) return -4;
      }
      while(*ptr++);
      total++;
    }
    if(*ptr) return -5;
  }
  for(i=0;i<=doldoc.hash->mask;i++) {
    entry=doldoc.hash->body[i];
    while(entry) { count++; entry=entry->next; }
  }
  if(count!=121 || DocDefaultsFingerprint(&doldoc)!=0xC98DFEA78567ACEC) return -6;
  //Exercise the DHT-specific destructor without damaging the published dictionary.
  before=Fs->data_heap->used_u8s;
  for(i=0;i<3;i++) {
    temporary=DocDictionaryNew;
    entry=HashFind("WHITE",temporary,DHT_COLOR);
    if(!entry || entry->user_data0!=15) return -7;
    DocDictionaryDel(temporary);
  }
  if(Fs->data_heap->used_u8s!=before || !HashFind("ER",doldoc.hash,DHT_DOC_CMD)) return -8;
  return total;
}
