U0 HSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 HSCheck()
{
  CHash *entry=HashFind("HashSrcFileSet",Fs->hash_table,HTT_FUN|HTT_EXPORT_SYS_SYM);
  U0 (*set_source)(CCmpCtrl *cc,CHashSrcSym *h,I64 offset);
  CCmpCtrl *cc=NULL;CHashSrcSym *h=NULL;
  I64 initial=Fs->data_heap->used_u8s,used,i,mask=0;U8 *s,*buffer;
  if(!entry){HSLog("HASH SOURCE UNAVAILABLE\n");return;}
  if(entry->type&HTT_FUN)set_source=entry(CHashFun *)->exe_addr;
  else set_source=entry(CHashExport *)->val;
  if(!set_source){HSLog("HASH SOURCE UNAVAILABLE\n");return;}
  try {
    cc=CmpCtrlNew(StrNew("abc"));buffer=cc->cur_buf_ptr;h=CAlloc(sizeof(CHashSrcSym));
    h->type=HTT_DEFINE_STR|HTF_PUBLIC;
    Free(cc->lex_include_stk->full_name);cc->lex_include_stk->full_name=StrNew("C:/Probe/Source.HC");
    cc->lex_include_stk->line_num=7;
    (*set_source)(cc,h,0);
    if(!StrCmp(h->src_link,"FL:C:/Probe/Source.HC,7") && !h->idx)mask|=1;
    cc->cur_help_idx=StrNew("Compiler/Test");(*set_source)(cc,h,3);
    if(!StrCmp(h->src_link,"FL:C:/Probe/Source.HC,10") &&
       h->idx!=cc->cur_help_idx && !StrCmp(h->idx,"Compiler/Test"))mask|=2;
    Bts(&cc->opts,OPTf_KEEP_PRIVATE);(*set_source)(cc,h,-99);
    if(!StrCmp(h->src_link,"FL:C:/Probe/Source.HC,1") && h->type&HTF_PRIVATE)mask|=4;
    Btr(&cc->opts,OPTf_KEEP_PRIVATE);*cc->cur_help_idx=0;(*set_source)(cc,h,0);
    if(!h->idx && h->type&HTF_PRIVATE)mask|=8;
    Free(cc->lex_include_stk->full_name);cc->lex_include_stk->full_name=StrNew("C:/Probe/Other.HC");
    cc->lex_include_stk->line_num=9;Free(cc->cur_help_idx);cc->cur_help_idx=NULL;
    (*set_source)(cc,h,0);
    if(!StrCmp(h->src_link,"FL:C:/Probe/Other.HC,9") &&
       h->type==(HTT_DEFINE_STR|HTF_PUBLIC|HTF_PRIVATE))mask|=16;
    if(cc->cur_buf_ptr==buffer && !StrCmp(buffer,"abc") &&
       cc->lex_include_stk->line_num==9 && !cc->cur_help_idx)mask|=32;
    used=Fs->data_heap->used_u8s;
    for(i=0;i<32;i++)(*set_source)(cc,h,0);
    if(Fs->data_heap->used_u8s==used)mask|=64;
  } catch {
    if(h){Free(h->src_link);Free(h->idx);Free(h);}if(cc)CmpCtrlDel(cc);
  }
  Free(h->src_link);Free(h->idx);Free(h);CmpCtrlDel(cc);
  if(Fs->data_heap->used_u8s==initial)mask|=128;
  s=MStrPrint("EXPORT hash-source-mask.bin %X 8\n",&mask);HSLog(s);Free(s);
  HSLog("HASH SOURCE DONE\n");Sleep(1000);
}
