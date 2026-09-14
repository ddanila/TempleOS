#include "/Kernel/I386/HashTable.HH"
//Link HashTableCore first for native ownership validation.
public Bool I386HashTableResize(CI386Heap *heap,CHashTable *table,I64 buckets)
{//Stable table address; strings and entries must be live, disjoint and acyclic.
  U32 flags=I386IrqSave;
  CHash **body,**old_body,*entry,*next,*reverse;
  I64 i,slot,old_count;
  Bool result=FALSE;
  if(!I386HashBucketCount(buckets) || !I386HashOwnedValid(heap,table) ||
      table->locked_flags) goto done;
  if(table->mask==buckets-1) { result=TRUE; goto done; }
  body=I386HeapAlloc(heap,buckets*sizeof(CHash *),TRUE);
  if(!body) goto done;
  old_body=table->body; old_count=table->mask+1;
  //Reverse each old chain, then prepend: equal-name instance order is preserved.
  //No allocation, yielding or failure-prone callbacks after links start changing.
  for(i=0;i<old_count;i++) {
    entry=old_body[i]; reverse=0;
    while(entry) { next=entry->next; entry->next=reverse; reverse=entry; entry=next; }
    while(reverse) {
      entry=reverse; reverse=entry->next;
      slot=HashStr(entry->str)&(buckets-1);
      entry->next=body[slot]; body[slot]=entry;
    }
  }
  table->body=body; table->mask=buckets-1;
  result=I386HeapFree(heap,old_body);
done:
  I386IrqRestore(flags); return result;
}
