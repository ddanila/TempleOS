//Portable equivalent of original _STRIMATCH: ASCII case folding, first match.
#ifndef STR_I_MATCH_NAME
#define STR_I_MATCH_NAME StrIMatch
#endif
public U8 *STR_I_MATCH_NAME(U8 *needle,U8 *haystack_str)
{
  U8 *start,*n,*h;U8 left,right;
  if(!needle || !haystack_str)return NULL;
  if(!*needle)return haystack_str;
  for(start=haystack_str;*start;start++) {
    n=needle;h=start;
    while(*n && *h) {
      left=*n;right=*h;
      if('a'<=left<='z')left+='A'-'a';
      if('a'<=right<='z')right+='A'-'a';
      if(left!=right)break;
      n++;h++;
    }
    if(!*n)return start;
  }
  return NULL;
}
