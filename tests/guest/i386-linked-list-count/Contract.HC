class CCountNode { CCountNode *next; I64 value; };
I64 LinkedCountContract()
{
  CCountNode a,b,c;
  I64 mask=0;
  a.next=&b;b.next=&c;c.next=NULL;
  a.value=11;b.value=22;c.value=33;
  if(LinkedLstCnt(NULL)==0)mask|=1;
  if(LinkedLstCnt(&c)==1)mask|=2;
  if(LinkedLstCnt(&b)==2)mask|=4;
  if(LinkedLstCnt(&a)==3)mask|=8;
  if(a.next==&b && b.next==&c && !c.next && a.value==11 && b.value==22 && c.value==33)mask|=16;
  b.next=NULL;
  if(LinkedLstCnt(&a)==2 && LinkedLstCnt(&c)==1)mask|=32;
  return mask;
}
