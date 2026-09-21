U8 *Define(U8 *dname)
{//Look for DEFINE named in hash table, return ptr string.
  CHashDefineStr *tmph;
  if (tmph=HashFind(dname,Fs->hash_table,HTT_DEFINE_STR))
    return tmph->data;
  else if (dname)
    UndefinedDefine(dname);
  else
    return NULL;
}

U8 *DefineSub(I64 sub,U8 *dname)
{//Return DEFINE list entry indexed by number.
  CHashDefineStr *tmph;
  if (tmph=HashFind(dname,Fs->hash_table,HTT_DEFINE_STR)) {
    if (0<=sub<tmph->cnt)
      return tmph->sub_idx[sub];
    else
      return NULL;
  } else if (dname)
    UndefinedDefine(dname);
  else
    return NULL;
}

I64 DefineCnt(U8 *dname)
{//Return cnt of entries in define list.
  CHashDefineStr *tmph;
  if (tmph=HashFind(dname,Fs->hash_table,HTT_DEFINE_STR))
    return tmph->cnt;
  else if (dname)
    UndefinedDefine(dname);
  else
    return -1;
}

I64 DefineMatch(U8 *needle,U8 *haystack_lst_dname,I64 flags=0)
{//Find match for string in define list.
  return LstMatch(needle,Define(haystack_lst_dname),flags);
}

