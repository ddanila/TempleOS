I64 RefUpper(I64 ch){if('a'<=ch<='z')return ch-'a'+'A';return ch;}
I64 StrICmpContract()
{
  U8 a[3],b[3];I64 x,y,expected,mask=0;Bool full=TRUE,limited=TRUE;
  a[1]=b[1]=0;a[2]=b[2]=0;
  for(x=0;x<256;x++)for(y=0;y<256;y++) {
    a[0]=x;b[0]=y;
    if(RefUpper(x)<RefUpper(y))expected=-1;
    else if(RefUpper(x)>RefUpper(y))expected=1;
    else expected=0;
    if(StrICmp(a,b)!=expected)full=FALSE;
    if(StrNICmp(a,b,1)!=expected || StrNICmp(a,b,0)!=0)limited=FALSE;
  }
  if(full)mask|=1;if(limited)mask|=2;
  if(StrICmp("AbC","aBc")==0 && StrICmp("abc","ABCD")==-1 && StrICmp("ABCD","abc")==1)mask|=4;
  if(StrNICmp("abcX","ABcy",3)==0 && StrNICmp("abcX","ABcy",4)==-1 && StrNICmp("abc","ABCD",8)==-1 && StrNICmp("abc","ABC",-1)==0)mask|=8;
  return mask;
}
