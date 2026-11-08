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

