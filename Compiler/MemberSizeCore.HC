I64 MemberLstSize(CHashClass *tmpc)
{
  CMemberLst *tmpm;
  CMemberLstMeta *tmp_meta;
  I64 res=0;
  tmpm=tmpc->member_lst_and_root;
  while (tmpm) {
    res+=MSize2(tmpm->str);
    res+=LinkedLstSize(tmpm->dim.next);
    if (tmpm->flags & MLF_STR_DFT_AVAILABLE)
      res+=MSize2(tmpm->dft_val);
    if (tmpm->flags & MLF_FUN)
      res+=HashEntrySize2(tmpm->fun_ptr-tmpm->fun_ptr->ptr_stars_cnt);
    tmp_meta=tmpm->meta;
    while (tmp_meta) {
      res+=MSize2(tmp_meta->str);
      if (tmp_meta->flags&MLMF_IS_STR)
	res+=MSize2(tmp_meta->user_data);
      res+=MSize2(tmp_meta);
      tmp_meta=tmp_meta->next;
    }
    res+=MSize2(tmpm);
    tmpm=tmpm->next;
  }
  return res;
}
