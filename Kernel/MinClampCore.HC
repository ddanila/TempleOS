F64 Clamp(F64 d,F64 lo,F64 hi)
{//Clamp to F64 [] range.
  if (d<lo)
    return lo;
  if (d>hi)
    return hi;
  return d;
}

F64 Min(F64 n1,F64 n2)
{//Min of two F64s.
  if (n1<=n2)
    return n1;
  else
    return n2;
}
