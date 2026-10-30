//Original string comparison folds ASCII a-z only and returns -1, 0 or 1.
I64 StrICmpFold(U8 ch)
{
  if('a'<=ch<='z')return ch-'a'+'A';
  return ch;
}
I64 StrNICmp(U8 *left,U8 *right,I64 count)
{
  I64 a,b;
  while(count) {
    a=StrICmpFold(*left++);b=StrICmpFold(*right++);
    if(a<b)return -1;
    if(a>b)return 1;
    if(!a)return 0;
    count--;
  }
  return 0;
}
I64 StrICmp(U8 *left,U8 *right)
{ return StrNICmp(left,right,-1); }
