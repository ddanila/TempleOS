I64 JRContract()
{
  I64 *words=CAlloc(16),mask=0;
  I64 *p;
  U8 *q;
  U8 reg *r;
  words[0]=4;words[1]=0;p=words;
  *p++=*p^2;
  if(words[0]==6 && !words[1] && p==words+1)mask|=1;
  words[0]=4;words[1]=0;q=words(U8 *);
  *q(I64 *)++=*q(I64 *)^2;
  if(words[0]==6 && !words[1] && q==words(U8 *)+8)mask|=2;
  words[0]=0x0404040404040404;words[1]=0;q=words(U8 *);
  *q(I64 *)++=*q(I64 *)&0xFFFF|*q(I64 *)^0x0202020202020202&~0xFFFF;
  if(words[0]==0x0606060606060404 && !words[1] && q==words(U8 *)+8)mask|=4;
  words[0]=0x0404040404040404;words[1]=0;r=words(U8 *);
  *r(I64 *)++=*r(I64 *)&0xFFFF|*r(I64 *)^0x0202020202020202&~0xFFFF;
  if(words[0]==0x0606060606060404 && !words[1] && r==words(U8 *)+8)mask|=8;
  Free(words);
  return mask;
}
