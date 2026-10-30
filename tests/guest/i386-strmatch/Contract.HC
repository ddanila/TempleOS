I64 StringMatchContract()
{
  U8 a[2],b[2],*s="ababa";I64 x,y,expected,mask=0;Bool okay=TRUE;
  if(!StrMatch(NULL,s) && !StrMatch("a",NULL) && !StrMatch(NULL,NULL) && StrMatch("",s)==s)mask|=1;
  if(StrMatch("aba",s)==s && StrMatch("bab",s)==s+1 && !StrMatch("abba",s) && !StrMatch("a",""))mask|=2;
  a[1]=b[1]=0;
  for(x=0;x<256;x++)for(y=0;y<256;y++) {
    a[0]=x;b[0]=y;if(x<y)expected=-1;else if(x>y)expected=1;else expected=0;
    if(StrNCmp(a,b,1)!=expected || StrNCmp(a,b,0))okay=FALSE;
  }
  if(okay)mask|=4;
  if(StrNCmp("abcX","abcy",3)==0 && StrNCmp("abcX","abcy",4)==-1 &&
     StrNCmp("abc","abcd",8)==-1 && StrNCmp("abc","abcd",-1)==-1 &&
     StrNCmp("abcd","abc",-1)==1)mask|=8;
  return mask;
}
