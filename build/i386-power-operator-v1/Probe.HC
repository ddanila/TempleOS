F64 PowerSquare(F64 base)
{
  return base`2;
}

F64 PowerDynamic(F64 base,F64 exponent)
{
  return base`exponent;
}

U0 PowerProbe()
{
  F64 square=PowerSquare(3),cube=PowerDynamic(2,3),
      fraction=PowerDynamic(9,0.5),inverse=PowerDynamic(2,-2);
  U8 line[200],*p;
  StrPrint(line,"POWER values %016X %016X %016X %016X\n",
      *(&square)(U64 *),*(&cube)(U64 *),*(&fraction)(U64 *),*(&inverse)(U64 *));
  p=line;
  while (*p) OutU8(0xE9,*p++);
}
PowerProbe;
