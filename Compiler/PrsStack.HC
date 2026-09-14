U0 PrsPush(CPrsStk *ps,I64 val)
{
  if(ps->ptr<0 || ps->ptr>=254) throw('Compiler');
  ps->stk[++ps->ptr]=val;
}

I64 PrsPop(CPrsStk *ps)
{
  if(ps->ptr<1 || ps->ptr>254) throw('Compiler');
  return ps->stk[ps->ptr--];
}

U0 PrsPush2(CPrsStk *ps,I64 val)
{
  if(ps->ptr2<0 || ps->ptr2>=254) throw('Compiler');
  ps->stk2[++ps->ptr2]=val;
}

I64 PrsPop2(CPrsStk *ps)
{
  if(ps->ptr2<1 || ps->ptr2>254) throw('Compiler');
  return ps->stk2[ps->ptr2--];
}

U0 PrsPopDeref(CPrsStk *ps)
{
  I64 i=PrsPop(ps);
  CHashClass *tmpc=PrsPop(ps);
  if (i.u16[0]!=IC_DEREF) {
    PrsPush(ps,tmpc);
    PrsPush(ps,i);
  }
}

