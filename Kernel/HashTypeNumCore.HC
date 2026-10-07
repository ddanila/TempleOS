I64 HashTypeNum(CHash *tmph)
{//Return bit num of hash type, limited to just types.
  U32 bits;
  I64 bit=0;
  if (!tmph) return -1;
  bits=tmph->type&HTG_TYPE_MASK;
  if (!bits) return -1;
  while (!(bits&1)) { bits>>=1; bit++; }
  return bit;
}

