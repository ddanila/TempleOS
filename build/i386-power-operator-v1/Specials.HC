F64 PowerDynamic(F64 base,F64 exponent)
{
  return base`exponent;
}

U0 PowerProbe()
{
  F64 v[32];
  I64 i;
  U8 line[640],*p=line;
  v[0]=PowerDynamic(0x8000000000000000(F64),0x8000000000000000(F64));
  v[1]=PowerDynamic(2,0x8000000000000000(F64));
  v[2]=PowerDynamic(0,0x8000000000000000(F64));
  v[3]=PowerDynamic(-2,0x8000000000000000(F64));
  v[4]=PowerDynamic(0x8000000000000000(F64),-3);
  v[5]=PowerDynamic(0x8000000000000000(F64),3);
  v[6]=PowerDynamic(0x7FF0000000000000(F64),2);
  v[7]=PowerDynamic(0x7FF0000000000000(F64),-2);
  v[8]=PowerDynamic(0xFFF0000000000000(F64),3);
  v[9]=PowerDynamic(0xFFF0000000000000(F64),-3);
  v[10]=PowerDynamic(2,0x7FF0000000000000(F64));
  v[11]=PowerDynamic(2,0xFFF0000000000000(F64));
  v[12]=PowerDynamic(1,0x7FF0000000000000(F64));
  v[13]=PowerDynamic(1,0xFFF0000000000000(F64));
  v[14]=PowerDynamic(0x7FF8000000000123(F64),2);
  v[15]=PowerDynamic(2,0xFFF8000000000321(F64));
  v[16]=PowerDynamic(0x7FF0000000000123(F64),2);
  v[17]=PowerDynamic(2,0xFFF0000000000321(F64));
  v[18]=PowerDynamic(0x7FF8000000000123(F64),0xFFF8000000000321(F64));
  v[19]=PowerDynamic(0x7FF8000000000321(F64),0xFFF8000000000123(F64));
  v[20]=PowerDynamic(0x7FF8000000000123(F64),0);
  v[21]=PowerDynamic(0,0x7FF8000000000123(F64));
  v[22]=PowerDynamic(-2,0x43E0000000000000(F64));
  v[23]=PowerDynamic(-2,0xC3E0000000000000(F64));
  v[24]=PowerDynamic(-2,1025);
  v[25]=PowerDynamic(-2,-1075);
  v[26]=PowerDynamic(-2,-1073);
  v[27]=PowerDynamic(0x0000000000000001(F64),0.5);
  v[28]=PowerDynamic(0x0010000000000000(F64),0.5);
  v[29]=PowerDynamic(0x7FEFFFFFFFFFFFFF(F64),1);
  v[30]=PowerDynamic(2,0x8000000000000001(F64));
  v[31]=PowerDynamic(2,0x0000000000000001(F64));
  StrCpy(p,"POWER values ");
  p+=13;
  for (i=0;i<32;i++) {
    StrPrint(p,"%016X",*(&v[i])(U64 *));
    p+=16;
    if (i<31) *p++=' ';
  }
  *p++='\n';
  *p=0;
  p=line;
  while (*p) OutU8(0xE9,*p++);
}
PowerProbe;
