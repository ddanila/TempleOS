#include "/Kernel/ArcSeed.HH"
U0 ArcCtrlSeed(CArcCtrl *c,I64 compression_type)
{
  if(compression_type==CT_7_BIT) c->min_bits=7;
  else c->min_bits=8;
  c->min_table_entry=1<<c->min_bits;
  c->free_idx=c->min_table_entry;
  c->next_bits_in_use=c->min_bits+1;
  c->free_limit=1<<c->next_bits_in_use;
  c->saved_basecode=0xFFFFFFFF;
  c->entry_used=1;
}
