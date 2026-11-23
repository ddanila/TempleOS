F64 PowerMixed(I64 base,F64 exponent)
{
  return base`exponent;
}

F64 PowerSyntax(F64 base,I64 exponent,I64 outer)
{
  return base`exponent`outer;
}

U0 PowerProbe()
{
  F64 v[10];
  I64 i;
  U8 line[256],*p=line;
  v[0]=PowerMixed(9,0.5);
  v[1]=PowerSyntax(2,3,2);
  v[2]=(2`3)`2;
  v[3]=-2`2;
  v[4]=(-2)`2;
  v[5]=2`-2;
  v[6]=2*3`2+1;
  v[7]=PowerMixed(-4,1.5);
  v[8]=PowerSyntax(4,-2,3);
  v[9]=PowerMixed(3,2);
  StrCpy(p,"POWER values ");
  p+=13;
  for (i=0;i<10;i++) {
    StrPrint(p,"%016X",*(&v[i])(U64 *));
    p+=16;
    if (i<9) *p++=' ';
  }
  *p++='\n';
  *p=0;
  p=line;
  while (*p) OutU8(0xE9,*p++);
}
PowerProbe;
