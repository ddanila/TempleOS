U0 HashAddAfter(CHash *entry,CHash *pred,CHashTable *table)
{//Original _HASH_ADD_AFTER: splice after the borrowed predecessor under CLI.
  //The table argument is retained for API compatibility; no bucket is recomputed.
  U32 flags=I386IrqSave;
  entry->next=pred->next;
  pred->next=entry;
  I386IrqRestore(flags);
}
