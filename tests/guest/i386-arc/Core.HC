U64 ArcCoreMix(U64 hash,U64 value) { return (hash^value)*1099511628211; }
U64 ArcCoreTest(CArcCtrl *c,I64 bits)
{
  I64 i,j,base,index,previous=-1; CArcEntry *tmp; U64 hash=1469598103934665603;
  c->min_bits=bits; c->min_table_entry=1<<bits;
  c->free_idx=c->min_table_entry; c->next_bits_in_use=bits+1;
  c->free_limit=1<<c->next_bits_in_use; c->saved_basecode=0xFFFFFFFF;
  c->entry_used=1; ArcStep(c);
  if(c->cur_entry || c->next_entry!=c->compress+c->min_table_entry) return 0;
  for(i=0;i<20000;i++) {
    //No-op calls retain every field, including non-low bits of entry_used.
    c->entry_used=0x100; ArcStep(c);
    if(c->entry_used!=0x100) return 0;
    c->entry_used|=1; ArcStep(c);
    if(c->entry_used!=0x100) return 0;
    index=c->cur_entry-c->compress;
    if(index<c->min_table_entry || index>=4096 || !c->next_entry) return 0;
    hash=ArcCoreMix(hash,index); hash=ArcCoreMix(hash,c->next_entry-c->compress);
    hash=ArcCoreMix(hash,c->free_idx); hash=ArcCoreMix(hash,c->free_limit);
    hash=ArcCoreMix(hash,c->cur_bits_in_use); hash=ArcCoreMix(hash,c->next_bits_in_use);
    base=((i*19)^(i>>3))&(c->min_table_entry-1);
    if(i%7==0 && previous>=0) base=previous;
    previous=index;
    c->cur_entry->basecode=base; c->cur_entry->ch=i;
    c->cur_entry->next=c->hash[base]; c->hash[base]=c->cur_entry;
  }
  for(i=0;i<4096;i++) {
    tmp=c->hash[i]; j=0;
    while(tmp) {
      if(++j>4096 || tmp<c->compress || tmp>=c->compress+4096 || tmp->basecode!=i) return 0;
      hash=ArcCoreMix(hash,tmp-c->compress); hash=ArcCoreMix(hash,tmp->ch);
      tmp=tmp->next;
    }
    hash=ArcCoreMix(hash,j);
  }
  return hash;
}
