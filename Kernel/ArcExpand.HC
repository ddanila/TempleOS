#include "/Kernel/ArcExpand.HH"
Bool ArcExpandStep(CArcCtrl *c,I64 (*read)(CArcCtrl *c),U0 (*entry)(CArcCtrl *c))
{
  U8 *dst_ptr,*dst_limit;
  I64 basecode,lastcode,code;
  CArcEntry *tmp,**link;

  dst_ptr=c->dst_buf+c->dst_pos;
  dst_limit=c->dst_buf+c->dst_size;

  while (dst_ptr<dst_limit && c->stk_ptr!=c->stk_base)
    *dst_ptr++ = * -- c->stk_ptr;

  if (c->stk_ptr==c->stk_base && dst_ptr<dst_limit) {
    if (c->saved_basecode==0xFFFFFFFF) {
      lastcode=(*read)(c);
      if(lastcode<0) goto failed;
      c->src_pos+=c->next_bits_in_use;
      *dst_ptr++=lastcode;
      (*entry)(c);
      c->last_ch=lastcode;
    } else
      lastcode=c->saved_basecode;
    while (dst_ptr<dst_limit && c->src_pos+c->next_bits_in_use<=c->src_size) {
      basecode=(*read)(c);
      if(basecode<0) goto failed;
      c->src_pos+=c->next_bits_in_use;
      if (c->cur_entry==&c->compress[basecode]) {
	*c->stk_ptr++=c->last_ch;
	code=lastcode;
      } else
	code=basecode;
      while (code>=c->min_table_entry) {
	*c->stk_ptr++=c->compress[code].ch;
	code=c->compress[code].basecode;
      }
      *c->stk_ptr++=code;
      c->last_ch=code;

      c->entry_used=TRUE;
      tmp=c->cur_entry;
      tmp->basecode=lastcode;
      tmp->ch=c->last_ch;
      link=&c->hash[lastcode];
      tmp->next=*link;
      *link=tmp;

      (*entry)(c);
      while (dst_ptr<dst_limit && c->stk_ptr!=c->stk_base)
	*dst_ptr++ = * -- c->stk_ptr;
      lastcode=basecode;
    }
    c->saved_basecode=lastcode;
  }
  c->dst_pos=dst_ptr-c->dst_buf;
  return TRUE;
failed:
  c->dst_pos=dst_ptr-c->dst_buf;
  return FALSE;
}
