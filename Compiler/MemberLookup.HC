#include "/Compiler/MemberLookup.HH"
//Caller supplies StrCmp and stable, live compiler trees/metadata. No allocation or yielding.
I64 MemberMetaData(U8 *needle_str,CMemberLst *haystack_member_lst)
{//Find meta data name, return meta data val. See $LK,"::/Demo/ClassMeta.HC"$.
  CMemberLstMeta *meta=haystack_member_lst->meta;
  while (meta) {
    if (!StrCmp(meta->str,needle_str))
      return meta->user_data;
    meta=meta->next;
  }
  return 0;
}

CMemberLstMeta *MemberMetaFind(U8 *needle_str,CMemberLst *haystack_member_lst)
{//Find meta data name, return meta data struct. See $LK,"::/Demo/ClassMeta.HC"$.
  CMemberLstMeta *meta=haystack_member_lst->meta;
  while (meta) {
    if (!StrCmp(meta->str,needle_str))
      return meta;
    meta=meta->next;
  }
  return 0;
}

CMemberLst *MemberFind(U8 *needle_str,CHashClass *haystack_class)
{//Find class member. See $LK,"ClassRep",A="MN:ClassRep"$() and $LK,"DocForm",A="MN:DocForm"$().
  I64 i;
  CMemberLst *tmpm;
  do {
    tmpm=haystack_class->member_lst_and_root;
    while (tmpm) {
      if (!(i=StrCmp(tmpm->str,needle_str))) {
	tmpm->use_cnt++;
	return tmpm;
      }
      if (i<=0)
	tmpm=tmpm->left;
      else
	tmpm=tmpm->right;
    }
  } while (haystack_class=haystack_class->base_class);
  return 0;
}

CMemberLst *MemberClassBaseFind(CHashClass *needle_class,
	CHashClass *haystack_class)
{//Find class member class base. For finding dup class local vars.
  CMemberLst *tmpm;
  tmpm=haystack_class->member_class_base_root;
  while (tmpm) {
    if (needle_class==tmpm->member_class_base)
      return tmpm;
    if (needle_class<tmpm->member_class_base)
      tmpm=tmpm->left_class_base;
    else
      tmpm=tmpm->right_class_base;
  }
  return 0;
}

