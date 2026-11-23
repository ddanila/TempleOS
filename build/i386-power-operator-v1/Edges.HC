F64 PowerDynamic(F64 base,F64 exponent)
{
  return base`exponent;
}

U0 PowerProbe()
{
  F64 v[10];
  I64 i;
  U8 line[256],*p=line;
  v[0]=PowerDynamic(-2,3);
  v[1]=PowerDynamic(-2,4);
  v[2]=PowerDynamic(-4,0.5);
  v[3]=PowerDynamic(-4,1.5);
  v[4]=PowerDynamic(0,-2);
  v[5]=PowerDynamic(0,0);
  v[6]=PowerDynamic(0x8000000000000000(F64),2);
  v[7]=PowerDynamic(2,1024);
  v[8]=PowerDynamic(2,-1074);
  v[9]=PowerDynamic(2,-1075);
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
