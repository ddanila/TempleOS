#include "/Compiler/ControlInit.HH"
//Fresh zeroed records with stable lifetime; referenced tables/bitmaps are borrowed.
U0 CmpCtrlSeed(CCmpCtrl *cc,I64 flags,CHashTable *symbols,U32 *alpha_numeric)
{
  cc->next=cc->last=cc;
  cc->flags=flags;
  cc->opts=1<<OPTf_WARN_UNUSED_VAR|1<<OPTf_WARN_HEADER_MISMATCH;
  cc->htc.hash_mask=HTG_TYPE_MASK-HTT_IMPORT_SYS_SYM;
  cc->htc.define_hash_table=cc->htc.hash_table_lst=
    cc->htc.glbl_hash_table=cc->htc.local_hash_table=symbols;
  cc->char_bmp_alpha_numeric=alpha_numeric;
  cc->next_stream_blk=cc->last_stream_blk=&cc->next_stream_blk;
}
U0 LexFileSeed(CLexFile *file,U8 *buffer)
{
  file->buf=file->buf_ptr=file->line_start=buffer;
  file->line_num=1;
}
