I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,value;
  I64 *words=CAlloc(32),*p;
  U8 *q,*n;
  words[0]=0;words[1]=4;p=words+1;
  *p--=*p^2;
  if(words[1]==6 && !words[0] && p==words)mask|=1;
  words[0]=0;words[1]=4;q=(words+1)(U8 *);
  *q(I64 *)--=*q(I64 *)^2;
  if(words[1]==6 && !words[0] && q==words(U8 *))mask|=2;
  words[0]=4;words[1]=0;p=words;
  value=(*p++=*p^2);
  if(value==6 && words[0]==6 && p==words+1)mask|=4;
  words[0]=4;words[1]=0;n=words(U8 *);
  *n++=*n+0x100;
  if(words[0]==4 && !words[1] && n==words(U8 *)+1)mask|=8;
  words[0]=4;words[1]=9;p=words;
  words[2]=*p++;
  if(words[2]==4 && words[1]==9 && p==words+1)mask|=16;
  Free(words);if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
