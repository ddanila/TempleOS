#include "/Kernel/I386/ArcExpand.HH"
#include "/Kernel/ArcExpand.HC"
I64 I386ArcReadCode(CArcCtrl *c)
{
  I64 i,bit,result=0;
  if(c->next_bits_in_use<1 || c->next_bits_in_use>ARC_BITS_MAX || c->src_pos<0 ||
      c->src_pos>c->src_size || c->next_bits_in_use>c->src_size-c->src_pos) return -1;
  for(i=0;i<c->next_bits_in_use;i++) {
    bit=c->src_pos+i;
    if(c->src_buf[bit>>3]&(1<<(bit&7))) result|=1<<i;
  }
  return result;
}
I64 I386ArcRead(U8 *context,CArcCtrl *c) { return I386ArcReadCode(c); }
Bool I386ArcExpandBuf(CArcCtrl *c)
{
  U64 src,dst,stack;
  if(!c || !c->src_buf || !c->dst_buf || !c->stk_base || !c->stk_ptr ||
      c->src_size<0 || c->src_size>0xFFFFFFFF*8 || c->src_pos<0 || c->src_pos>c->src_size ||
      c->dst_size<0 || c->dst_size>0xFFFFFFFF || c->dst_pos<0 || c->dst_pos>c->dst_size ||
      c->next_bits_in_use<8 || c->next_bits_in_use>ARC_BITS_MAX) return FALSE;
  src=(c->src_buf+0)(U64); dst=(c->dst_buf+0)(U64); stack=(c->stk_base+0)(U64);
  if(src+((c->src_size+7)>>3)>0xFFFFFFFF || dst+c->dst_size>0xFFFFFFFF ||
      stack+4096>0xFFFFFFFF || c->stk_ptr<c->stk_base || c->stk_ptr>c->stk_base+4096) return FALSE;
  return ArcExpandStep(c,&I386ArcRead,&I386ArcEntryGet);
}
