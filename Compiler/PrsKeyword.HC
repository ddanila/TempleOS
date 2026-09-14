I64 PrsKeyWord(CCmpCtrl *cc)
{//Cvt cur token to $LK,"KEYWORD",A="FF:::/Compiler/OpCodes.DD,KEYWORD"$ or -1.
  CHashGeneric *tmph;
  if (cc->token==TK_IDENT &&(tmph=cc->hash_entry) && tmph->type&HTT_KEYWORD)
    return tmph->user_data0;
  else
    return -1;
}
