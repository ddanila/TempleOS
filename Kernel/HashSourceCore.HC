U0 HashSrcFileSet(CCmpCtrl *cc,CHashSrcSym *h,I64 line_num_offset=0)
{//Set $LK,"CHashSrcSym",A="MN:CHashSrcSym"$ link and help_index by cur cc pos.
  CLexFile *tmpf=cc->lex_include_stk;
  I64 line_num=tmpf->line_num+line_num_offset;
  if (line_num<1) line_num=1;
  Free(h->src_link);
  h->src_link=MStrPrint("FL:%s,%d",tmpf->full_name,line_num);
  if (Bt(&cc->opts,OPTf_KEEP_PRIVATE))
    h->type|=HTF_PRIVATE;
  Free(h->idx);
  if (cc->cur_help_idx && *cc->cur_help_idx)
    h->idx=StrNew(cc->cur_help_idx);
  else
    h->idx=NULL;
}

