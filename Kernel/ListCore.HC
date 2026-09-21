U8 *LstSub(I64 sub, U8 *lst)
{//Point to lst entry.
//Not efficient.  Use an array of U8 ptrs for efficiency.
  if (!lst) return NULL;
  while (*lst && sub>0) {
    while (*lst)	//Advance to end of cur entry.
      lst++;
    lst++;		//Skip trailing zero.
    if (*lst=='@')	//Check for '@' alias lst entry.
      lst++;
    else
      sub--;
  }
  if (sub||!*lst)
    return NULL;
  else
    return lst;
}

I64 LstMatch(U8 *needle, U8 *haystack_lst,I64 flags=0)
{//-2 if Ambiguous
// -1 if not found
  // Not efficient. Use hash tables for efficiency.
  I64 n,sub=0,res=-1;
  U8 *ptr;
  Bool exact_match=FALSE;
  if (!haystack_lst) return -1;
  n=StrLen(needle);
  while (*haystack_lst) {
    if (*haystack_lst=='@') {	//Check for '@' alias haystack_lst entry
      sub--;
      haystack_lst++;
    }
    ptr=needle;
    if (flags & LMF_IGNORE_CASE)
      while (*ptr && ToUpper(*ptr)==ToUpper(*haystack_lst)) {
	ptr++;
	haystack_lst++;
      }
    else
      while (*ptr && *ptr==*haystack_lst) {
	ptr++;
	haystack_lst++;
      }
    if (!*ptr) {		//Did we reach end of needle?
      if (!*haystack_lst)	//Did we reach end of haystack_lst?
	return sub;		//Found Exact match
      else {
	if (res!=-1) {
	  if (!exact_match)
	    res=-2;		//Ambiguous unless later exact match.
	} else {
	  if (!(flags & LMF_EXACT))
	    res=sub;
	}
      }
    }
    while (*haystack_lst)	//Advance to end of cur entry.
      haystack_lst++;
    haystack_lst++;		//Skip trailing zero
    sub++;
  }
  return res;
}

