#include "/Kernel/I386/HashTable.HH"
#include "/Kernel/I386/Cpu.HH"
//Link Hash, Heap and Cpu once. No NMI use; table users must obey exclusive lifetime.
class CI386HashOwner { CHashTable table; CI386Heap *heap; U32 signature; };
Bool I386HashBucketCount(I64 count)
{
  return count>0 && count<=0x3FFFFFFF && !(count&(count-1));
}
Bool I386HashOwnedValid(CI386Heap *heap,CHashTable *table)
{//IF clear. Prove allocation extents before reading the private owner or buckets.
  CI386HashOwner *owner=table;
  if(I386HeapSize(heap,table)!=sizeof(CI386HashOwner)) return FALSE;
  if(owner->heap!=heap || owner->signature!=0x54334849 || table->mask<0 ||
      table->mask>=0x3FFFFFFF || !I386HashBucketCount(table->mask+1) ||
      table->body==table) return FALSE;
  return I386HeapSize(heap,table->body)==(table->mask+1)*sizeof(CHash *);
}
public Bool I386HashTableValid(CI386Heap *heap,CHashTable *table)
{
  U32 flags=I386IrqSave;
  Bool result=I386HashOwnedValid(heap,table);
  I386IrqRestore(flags); return result;
}
public CHashTable *I386HashTableNew(CI386Heap *heap,I64 buckets)
{//Two owned allocations; failed bucket allocation releases the unexposed record.
  U32 flags=I386IrqSave;
  CI386HashOwner *owner=0;
  if(I386HashBucketCount(buckets)) {
    owner=I386HeapAlloc(heap,sizeof(CI386HashOwner),TRUE);
    if(owner) {
      owner->table.body=I386HeapAlloc(heap,buckets*sizeof(CHash *),TRUE);
      if(!owner->table.body) { I386HeapFree(heap,owner); owner=0; }
      else {
        owner->table.mask=buckets-1; owner->heap=heap; owner->signature=0x54334849;
      }
    }
  }
  I386IrqRestore(flags); return owner;
}
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
public Bool I386HashTableRemove(CI386Heap *heap,CHashTable *table,CHash *entry)
{//Detach exact identity; never free caller-owned entry/string or touch a parent.
  U32 flags=I386IrqSave;
  CHash **link;
  Bool result=FALSE;
  if(!entry || !I386HashOwnedValid(heap,table) || table->locked_flags) goto done;
  link=HashBucketFind(entry->str,table);
  while(*link && *link!=entry) link=&(*link)->next;
  if(*link==entry) { *link=entry->next; entry->next=0; result=TRUE; }
done:
  I386IrqRestore(flags); return result;
}
public Bool I386HashTableDelete(CI386Heap *heap,CHashTable *table)
{//Caller has detached incoming references. Parent table and entry lifetimes are separate.
  U32 flags=I386IrqSave;
  I64 i;
  CI386HashOwner *owner=table;
  Bool result=FALSE;
  if(!I386HashOwnedValid(heap,table) || table->locked_flags) goto done;
  for(i=0;i<=table->mask;i++) if(table->body[i]) goto done;
  if(!I386HeapFree(heap,table->body)) goto done;
  owner->signature=0; table->body=0;
  result=I386HeapFree(heap,table);
done:
  I386IrqRestore(flags); return result;
}
