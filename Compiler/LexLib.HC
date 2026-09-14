#include "/Compiler/LexState.HC"
U0 LexPush(CCmpCtrl *cc)
{//Create token-stream save point. Preserve the existing allocation/failure order.
  CLexFile *snapshot;
  LexPrepareSnapshot(cc);
  snapshot=MAllocIdent(cc->lex_include_stk);
  LexSnapshotAttach(cc,snapshot);
}
U0 LexPopRestore(CCmpCtrl *cc)
{//Caller must not cross an include-file boundary while restoring a save point.
  Free(LexSnapshotRestore(cc));
}
U0 LexPopNoRestore(CCmpCtrl *cc)
{
  Free(LexSnapshotDetach(cc));
}

#include "/Compiler/MemberLookup.HC"

#include "/Compiler/MemberBuild.HC"
U0 MemberCompilerDiagnostic(U8 *context,Bool warning)
{
  CCmpCtrl *cc=context;
  if(warning) LexWarn(cc,"Duplicate type at ");
  else LexExcept(cc,"Duplicate member at ");
}
U0 MemberAdd(CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{
  MemberInsert(member,type,mode==PRS1B_LOCAL_VAR,
    Bt(&cc->opts,OPTf_WARN_DUP_TYPES),&MemberCompilerDiagnostic,cc);
}
CMemberLst *MemberLstNew(I64 _reg)
{
  CMemberLst *res=CAlloc(sizeof(CMemberLst));
  res->reg=_reg;
  return res;
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
