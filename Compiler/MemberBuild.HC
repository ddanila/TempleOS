#include "/Compiler/MemberBuild.HH"
#include "/Compiler/MemberLookup.HH"
//Caller owns live records and trees. Diagnostics must not mutate them or yield.
Bool MemberInsert(CMemberLst *tmpm,CHashClass *tmpc,Bool local_var,
  Bool warn_dup_types,U0 (*diagnostic)(U8 *context,Bool warning),U8 *context)
{
  U8 *st=tmpm->str;
  CMemberLst **tmpm1,*tmpm2;

  if (MemberFind(st,tmpc) && StrCmp(st,"pad") &&
	StrCmp(st,"reserved") && StrCmp(st,"_anon_"))
  {
    (*diagnostic)(context,FALSE);
    return FALSE;
  }
  tmpm1=&tmpc->member_lst_and_root;
  while (tmpm2=*tmpm1) {
    if (StrCmp(tmpm2->str,st)<=0)
      tmpm1=&tmpm2->left;
    else
      tmpm1=&tmpm2->right;
  }
  *tmpm1=tmpm;

  if (local_var) {
    tmpm->member_class_base=
	tmpm->member_class-tmpm->member_class->ptr_stars_cnt;
    if (warn_dup_types &&
	 MemberClassBaseFind(tmpm->member_class_base,tmpc))
      (*diagnostic)(context,TRUE);
    tmpm1=&tmpc->member_class_base_root;
    while (tmpm2=*tmpm1) {
      if (tmpm->member_class_base<tmpm2->member_class_base)
	tmpm1=&tmpm2->left_class_base;
      else if (tmpm->member_class_base>tmpm2->member_class_base)
	tmpm1=&tmpm2->right_class_base;
      else {
	tmpm1=0;
	break;
      }
    }
    if (tmpm1)
      *tmpm1=tmpm;
  } else
    tmpm->member_class_base=0;

  tmpm->left=0;
  tmpm->right=0;
  tmpm->left_class_base=0;
  tmpm->right_class_base=0;
  tmpm2=tmpc->last_in_member_lst;
  tmpm2->next=tmpc->last_in_member_lst=tmpm;
  return TRUE;
}

Bool  MemberLstCmp(CMemberLst *tmpm1,CMemberLst *tmpm2,I64 cnt=0x7FFFFFFFFFFFFFFF)
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

