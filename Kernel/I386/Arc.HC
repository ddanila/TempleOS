#include "/Kernel/I386/Arc.HH"
U0 I386ArcEntryGet(CArcCtrl *c)
{//Native pointer arithmetic replaces the x64 assembly's fixed record strides.
  I64 i;
  CArcEntry *tmp,**link;
  if(c->entry_used&1) {
    i=c->free_idx;
    c->entry_used&=~1;
    c->cur_entry=c->next_entry;
    c->cur_bits_in_use=c->next_bits_in_use;
    if(c->next_bits_in_use<ARC_BITS_MAX) {
      c->next_entry=&c->compress[i++];
      if(i==c->free_limit) {
        c->next_bits_in_use++;
        c->free_limit=1<<c->next_bits_in_use;
      }
    } else {
      do if(++i==c->free_limit) i=c->min_table_entry;
      while(c->hash[i]);
      tmp=&c->compress[i];
      c->next_entry=tmp;
      link=&c->hash[tmp->basecode];
      while(*link) {
        if(*link==tmp) { *link=tmp->next; break; }
        link=&(*link)->next;
      }
    }
    c->free_idx=i;
  }
}
