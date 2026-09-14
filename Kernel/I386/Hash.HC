#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/Cpu.HH"
//Base records are shared with x64. Table storage, strings and entries are caller-owned.
//Use power-of-two bucket counts, mask=count-1, and live acyclic table/entry chains.
public I64 HashStr(U8 *st)
{//Preserve SYS_HASH_STR's 64-bit shift/add carry and final SHR/ADC fold.
  U64 hash=0;
  if(!st) return 0;
  while(*st) { hash=(hash<<1)+*st+++(hash>>63); }
  return hash+(hash>>16)+((hash>>15)&1);
}
public CHash **HashBucketFind(U8 *needle_str,CHashTable *haystack_table)
{
  return haystack_table->body+(HashStr(needle_str)&haystack_table->mask);
}
public U0 HashAdd(CHash *entry,CHashTable *table)
{//Single CPU: publish the complete head update without IRQ interleaving or yielding.
  CHash **bucket=HashBucketFind(entry->str,table);
  U32 flags=I386IrqSave;
  entry->next=*bucket; *bucket=entry;
  I386IrqRestore(flags);
}
CHash *I386HashLookup(U8 *needle,CHashTable *table,I64 mask,I64 *instance,U64 hash)
{//Caller keeps the searched chain stable; matching preserves the public use counter.
  CHash *entry=table->body[hash&table->mask];
  U8 *a,*b;
  U32 flags;
  while(entry) {
    if(entry->type&mask) {
      a=needle; b=entry->str;
      while(*a && *a==*b) { a++; b++; }
      if(*a==*b) {
        *instance=*instance-1;
        if(*instance==0) {
          flags=I386IrqSave;
          entry->use_cnt++;
          I386IrqRestore(flags);
          return entry;
        }
      }
    }
    entry=entry->next;
  }
  return 0;
}
public CHash *HashSingleTableFind(U8 *needle_str,CHashTable *haystack_table,
  I64 mask,I64 instance=1)
{
  if(instance<=0) return 0;
  return I386HashLookup(needle_str,haystack_table,mask,&instance,HashStr(needle_str));
}
public CHash *HashFind(U8 *needle_str,CHashTable *haystack_table,I64 mask,I64 instance=1)
{
  U64 hash;
  CHash *entry;
  if(instance<=0) return 0;
  hash=HashStr(needle_str);
  while(haystack_table) {
    entry=I386HashLookup(needle_str,haystack_table,mask,&instance,hash);
    if(entry) return entry;
    haystack_table=haystack_table->next;
  }
  return 0;
}
