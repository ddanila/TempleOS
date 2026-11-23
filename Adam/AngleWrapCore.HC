public F64 Wrap(F64 é,F64 base=-ã)
{//Returns angle in range [base,base+2*ã)
  F64 res=é%(2*ã);
  if (res>=base+2*ã)
    res-=2*ã;
  else if (res<base)
    res+=2*ã;
  return res;
}

