I64 HasLower(U8 *src)
{
  I64 ch;
  while (ch=*src++)
    if ('a'<=ch<='z')
      return TRUE;
  return FALSE;
}

U0 HashFunSegFind(CHashTable *h,U8 *addr,
	Bool *_has_lower,U64 *_best,CHash **_res)
{
  Bool *has_lower=*_has_lower;
  CHashExport *tmpex;
  U64 i,j,best=*_best;
  CHash *res=*_res;
  for (i=0;i<=h->mask;i++) {
    tmpex=h->body[i];
    while (tmpex) {
      j=0;
      if (tmpex->type&HTT_FUN) {
	if (!Bt(&tmpex(CHashFun *)->flags,Cf_EXTERN) &&
	      !Bt(&tmpex(CHashFun *)->flags,Ff_INTERNAL))
	  j=tmpex(CHashFun *)->exe_addr;
      } else if (tmpex->type&HTT_EXPORT_SYS_SYM)
	j=tmpex->val;
      if (j) {
	j=addr(I64)-j;
	if (0<=j<=best) {
	  if (tmpex->type&HTT_EXPORT_SYS_SYM) {
	    if (j<best || j==best && !has_lower) {
	      has_lower=HasLower(tmpex->str);
	      best=j;
	      res=tmpex;
	    }
	  } else if (tmpex->type&HTT_FUN) {
	    if (j<best || j==best &&
		  (res && res->type&HTT_EXPORT_SYS_SYM||!has_lower)) {
	      has_lower=HasLower(tmpex->str);
	      best=j;
	      res=tmpex;
	    }
	  }
	}
      }
      tmpex=tmpex->next;
    }
  }
  *_has_lower=has_lower;
  *_best=best;
  *_res =res;
}

