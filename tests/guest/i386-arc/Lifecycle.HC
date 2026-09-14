I64 ArcLifecycleTest()
{
  CArcCtrl *c;
  I64 mode,expand,bits,i;
  U8 *bytes;
  for(mode=-1;mode<=4;mode++) for(expand=0;expand<2;expand++) {
    c=ArcNew(expand,mode); if(!c) return 10;
    bits=8; if(mode==CT_7_BIT) bits=7;
    if(c->min_bits!=bits || c->min_table_entry!=1<<bits || c->free_idx!=(1<<bits)+1 ||
        c->next_bits_in_use!=bits+1 || c->cur_bits_in_use!=bits+1 ||
        c->free_limit!=1<<(bits+1) || c->saved_basecode!=0xFFFFFFFF || c->entry_used!=1 ||
        c->cur_entry || c->next_entry!=c->compress+(1<<bits) || c->last_ch ||
        c->src_pos || c->src_size || c->dst_pos || c->dst_size || c->src_buf || c->dst_buf ||
        c->stk_ptr!=c->stk_base) return 11;
    if(expand) { if(!c->stk_base) return 12; }
    else if(c->stk_base) return 13;
    bytes=c->compress;
    for(i=0;i<4096*(sizeof(CArcEntry)+sizeof(CArcEntry *));i++) if(bytes[i]) return 14;
    if(!ArcDelete(c)) return 15;
  }
  return 0;
}
