#define STR_I_MATCH_NAME PortableStrIMatch
#include "/Kernel/StrIMatchCore.HC"
Bool SIMBoth(U8 *needle,U8 *haystack,I64 offset)
{
  U8 *expected=NULL;
  if(offset>=0)expected=haystack+offset;
  return StrIMatch(needle,haystack)==expected && PortableStrIMatch(needle,haystack)==expected;
}
I64 JRContract(I64 unused)
{
  I64 mask=0,a,b,offset;U8 needle[2],hay[2],upper_a,upper_b;Bool ok=TRUE;
  needle[1]=hay[1]=0;
  if(SIMBoth(NULL,"abc",-1) && SIMBoth("a",NULL,-1) && SIMBoth(NULL,NULL,-1))mask|=1;
  if(SIMBoth("","abc",0) && SIMBoth("","",0) && SIMBoth("a","",-1))mask|=2;
  if(SIMBoth("Bc","aBCdBc",1) && SIMBoth("ABC","abcABC",0))mask|=4;
  if(SIMBoth("aAb","aaAAb",2) && SIMBoth("ABA","ABAbA",0))mask|=8;
  if(SIMBoth("abcd","xxAbc",-1) && SIMBoth("xy","zz",-1) && SIMBoth("C","abC",2))mask|=16;
  for(a=0;a<256;a++)for(b=0;b<256;b++) {
    needle[0]=a;hay[0]=b;upper_a=a;upper_b=b;
    if(a>=97 && a<=122)upper_a=a-32;
    if(b>=97 && b<=122)upper_b=b-32;
    offset=-1;if(!a || upper_a==upper_b)offset=0;
    if(!SIMBoth(needle,hay,offset))ok=FALSE;
  }
  if(ok)mask|=32;
  return mask;
}
