U0 LexBackupLastChar(CCmpCtrl *cc)
{
  CLexFile *tmpf=cc->lex_include_stk;
  tmpf->buf_ptr=cc->cur_buf_ptr;
  if (cc->flags & CCF_USE_LAST_U16) {
    tmpf->last_U16=cc->last_U16;
    cc->flags&=~CCF_USE_LAST_U16;
  } else
    tmpf->last_U16=0;
}

U0 LexPush(CCmpCtrl *cc)
{//Create token-stream save point.
  CLexFile *tmpf;
  LexBackupLastChar(cc);
  if (cc->lex_include_stk->last_U16)
    cc->flags|=CCF_USE_LAST_U16;
  tmpf=MAllocIdent(cc->lex_include_stk);
  tmpf->next=cc->lex_prs_stk;
  cc->lex_prs_stk=tmpf;
}

U0 LexPopRestore(CCmpCtrl *cc)
{//Restore token-stream saved-point.
//Bad things can happen if you cross an #include file boundary.
  CLexFile *tmpf=cc->lex_prs_stk;
  cc->cur_buf_ptr=tmpf->buf_ptr;
  if (cc->last_U16=tmpf->last_U16)
    cc->flags|=CCF_USE_LAST_U16;
  else
    cc->flags&=~CCF_USE_LAST_U16;
  MemCpy(cc->lex_include_stk(U8 *)+sizeof(U8 *),tmpf(U8 *)+sizeof(U8 *),
	sizeof(CLexFile)-sizeof(U8 *));
  cc->lex_prs_stk=tmpf->next;
  Free(tmpf);
}

U0 LexPopNoRestore(CCmpCtrl *cc)
{//Don't restore token-stream saved-point.
  CLexFile *tmpf=cc->lex_prs_stk;
  cc->lex_prs_stk=tmpf->next;
  Free(tmpf);
}

#include "/Compiler/MemberLookup.HC"

U0 MemberAdd(CCmpCtrl *cc,CMemberLst *tmpm,CHashClass *tmpc,I64 mode)
{
  U8 *st=tmpm->str;
  CMemberLst **tmpm1,*tmpm2;

  if (MemberFind(st,tmpc) && StrCmp(st,"pad") &&
	StrCmp(st,"reserved") && StrCmp(st,"_anon_"))
    LexExcept(cc,"Duplicate member at ");
  tmpm1=&tmpc->member_lst_and_root;
  while (tmpm2=*tmpm1) {
    if (StrCmp(tmpm2->str,st)<=0)
      tmpm1=&tmpm2->left;
    else
      tmpm1=&tmpm2->right;
  }
  *tmpm1=tmpm;

  if (mode==PRS1B_LOCAL_VAR) {
    tmpm->member_class_base=
	tmpm->member_class-tmpm->member_class->ptr_stars_cnt;
    if (Bt(&cc->opts,OPTf_WARN_DUP_TYPES) &&
	 MemberClassBaseFind(tmpm->member_class_base,tmpc))
      LexWarn(cc,"Duplicate type at ");
    tmpm1=&tmpc->member_class_base_root;
    while (tmpm2=*tmpm1) {
      if (tmpm->member_class_base<tmpm2->member_class_base)
	tmpm1=&tmpm2->left_class_base;
      else if (tmpm->member_class_base>tmpm2->member_class_base)
	tmpm1=&tmpm2->right_class_base;
      else {
	tmpm1=NULL;
	break;
      }
    }
    if (tmpm1)
      *tmpm1=tmpm;
  } else
    tmpm->member_class_base=NULL;

  tmpm->left=NULL;
  tmpm->right=NULL;
  tmpm->left_class_base=NULL;
  tmpm->right_class_base=NULL;
  tmpm2=tmpc->last_in_member_lst;
  tmpm2->next=tmpc->last_in_member_lst=tmpm;
}

CMemberLst *MemberLstNew(I64 _reg)
{
  CMemberLst *res=CAlloc(sizeof(CMemberLst));
  res->reg=_reg;
  return res;
}

Bool  MemberLstCmp(CMemberLst *tmpm1,CMemberLst *tmpm2,I64 cnt=I64_MAX)
{
  while (tmpm1 && tmpm2 && cnt--) {
    if (StrCmp(tmpm1->str,tmpm2->str) ||
	  tmpm1->member_class!=tmpm2->member_class ||
	  tmpm1->member_class_base!=tmpm2->member_class_base)
      return FALSE;
    if (tmpm1->flags&MLF_DFT_AVAILABLE || tmpm2->flags&MLF_DFT_AVAILABLE) {
      if (tmpm1->flags&(MLF_DFT_AVAILABLE|MLF_STR_DFT_AVAILABLE)!=
	    tmpm2->flags&(MLF_DFT_AVAILABLE|MLF_STR_DFT_AVAILABLE))
	return FALSE;
      if (tmpm1->flags&MLF_STR_DFT_AVAILABLE) {
	if (StrCmp(tmpm1->dft_val,tmpm2->dft_val))
	  return FALSE;
      } else if (tmpm1->dft_val!=tmpm2->dft_val)
	return FALSE;
    }
    tmpm1=tmpm1->next;
    tmpm2=tmpm2->next;
  }
  if (cnt<0 || !tmpm1 && !tmpm2)
    return TRUE;
  else
    return FALSE;
}

#include "/Kernel/SymbolDelete.HH"
U0 SymbolCompilerFree(U8 *context,U8 *allocation)
{
  Free(allocation);
}
U0 MemberLstDel(CMemberLst *members)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&SymbolCompilerFree;
  SymbolMemberLstDel(&owner,members);
}
U0 ClassMemberLstDel(CHashClass *symbol)
{
  CSymbolRelease owner;
  owner.context=0; owner.release=&SymbolCompilerFree;
  SymbolClassMemberLstDel(&owner,symbol);
}

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

U8 *LexExtStr(CCmpCtrl *cc,I64 *_size=NULL,Bool lex_next=TRUE)
{//Lex $LK,"TK_STR",A="MN:TK_STR"$'s to one combined str. _size includes terminator.
  I64 len=cc->cur_str_len,len1,len2;
  U8 *st=cc->cur_str,*st1,*st2;
  cc->cur_str=NULL;
  while (cc->token==TK_STR) {
    st1=st;
    len1=len;
    if (!lex_next && LexGetChar(cc)!='\\') {
      cc->flags|=CCF_USE_LAST_U16;
      break;
    }
    if (Lex(cc)==TK_STR) {
      len2=cc->cur_str_len;
      st2=cc->cur_str;
      cc->cur_str=NULL;
      len=len1+len2-1;
      st=MAlloc(len);
      if (len1>1)
	MemCpy(st,st1,len1-1);
      MemCpy(st+len1-1,st2,len2);
      Free(st1);
      Free(st2);
    }
  }
  if (_size) *_size=len;
  return st;
}
