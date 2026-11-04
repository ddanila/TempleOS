Bool ProbePublishedRemove(CHashTable *table,CHash *entry)
{
  I64 i;
  CHash **link;
  for(i=0;i<=table->mask;i++) {
    link=&table->body[i];
    while(*link) {
      if(*link==entry) { *link=entry->next; entry->next=0; return TRUE; }
      link=&(*link)->next;
    }
  }
  return FALSE;
}
