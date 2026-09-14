I64 ControlSeedTest(I64 pointer_bytes)
{
  CCmpCtrl *cc=DeleteAllocRaw(sizeof(CCmpCtrl));
  CLexFile *file=DeleteAllocRaw(sizeof(CLexFile));
  CHashTable table;
  U32 bitmap[8];
  U8 buffer[8];
  I64 flags=CCF_DONT_FREE_BUF|CCF_KEEP_AT_SIGN|CCF_TARGET_I386,result=0;
  if(!cc || !file) return 134;
  CmpCtrlSeed(cc,flags,&table,bitmap);
  if(cc->next!=cc || cc->last!=cc || cc->flags!=flags ||
      cc->opts!=((1<<OPTf_WARN_UNUSED_VAR)|(1<<OPTf_WARN_HEADER_MISMATCH)) ||
      cc->htc.hash_mask!=HTG_TYPE_MASK-HTT_IMPORT_SYS_SYM ||
      cc->htc.define_hash_table!=&table || cc->htc.glbl_hash_table!=&table ||
      cc->htc.local_hash_table!=&table || cc->htc.hash_table_lst!=&table ||
      cc->char_bmp_alpha_numeric!=bitmap || cc->next_stream_blk!=&cc->next_stream_blk ||
      cc->last_stream_blk!=&cc->next_stream_blk) result=135;
  if(cc->token || cc->cur_str || cc->cur_i64 || cc->cur_f64(U64) || cc->cur_buf_ptr ||
      cc->lex_include_stk || cc->lex_prs_stk || cc->fun_lex_file || cc->htc.next ||
      cc->htc.fun || cc->htc.local_var_lst || cc->abs_cnts || cc->hash_entry ||
      cc->coc.coc_next || cc->coc.coc_next_misc || cc->coc.coc_last_misc ||
      cc->coc.coc_head.next || cc->coc.coc_head.last || cc->ps || cc->aotc ||
      cc->aot_depth || cc->error_cnt || cc->warning_cnt) result=136;
  file->depth=-1; file->full_name="source"; file->flags=LFSF_DEFINE;
  LexFileSeed(file,buffer);
  cc->lex_include_stk=file; cc->cur_buf_ptr=buffer;
  if(file->buf!=buffer || file->buf_ptr!=buffer || file->line_start!=buffer ||
      file->line_num!=1 || file->depth!=-1 || file->flags!=LFSF_DEFINE ||
      StrCmp(file->full_name,"source") || file->next || file->doc || file->cur_entry || file->last_U16) result=137;
  cc->token=TK_F64; cc->cur_i64=0xFEDCBA9876543210; cc->cur_f64(U64)=0x3FF8000000000000;
  cc->abs_cnts.abs_addres=0x1234; cc->abs_cnts.c_addres=0x5678; cc->abs_cnts.externs=0x9ABCDEF0;
  cc->htc.old_flags=0x100000009; cc->pass_trace=0x10000000A;
  cc->coc.coc_head.ic_cnt=-2; cc->coc.coc_head.ic_precedence=0x1234;
  cc->aot_depth=0x10000000B; cc->pmt_line=0x10000000C;
  file->line_num=0x10000000D;
  if(cc->token!=TK_F64 || cc->cur_i64!=0xFEDCBA9876543210 || cc->cur_f64(U64)!=0x3FF8000000000000 ||
      cc->abs_cnts!=0x9ABCDEF056781234 || cc->htc.old_flags!=0x100000009 ||
      cc->pass_trace!=0x10000000A || cc->coc.coc_head.ic_cnt!=-2 ||
      cc->coc.coc_head.ic_precedence!=0x1234 || cc->aot_depth!=0x10000000B ||
      cc->pmt_line!=0x10000000C || file->line_num!=0x10000000D) result=138;
  if(sizeof(CCmpCtrl)!=216+32*pointer_bytes || sizeof(CLexFile)!=24+7*pointer_bytes ||
      sizeof(CCodeCtrl)!=8+5*pointer_bytes || sizeof(CAbsCntsI64)!=8 ||
      sizeof(CPrsStk)!=4096) result=139;
  //Names, buffers, bitmap and hash table are borrowed in this seed-only fixture.
  DeleteFreeRaw(file); DeleteFreeRaw(cc); return result;
}
