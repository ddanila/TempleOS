U0 PsmStaccatoSweep()
{
  I64 setting;
  F64 original,encoded;
  U8 *s,*p;
  for (setting=0;setting<=80;setting++) {
    original=0.88*setting/80+0.12;
    encoded=0x3FEC28F5C28F5C2A(F64)*setting/80+0x3FBEB851EB851EBA(F64);
    s=MStrPrint("PSM SWEEP %d %.3f %.3f\n",setting,
          original+0.0005,encoded+0x3F40624DD2F1A9FE(F64));
    p=s;
    while (*p) OutU8(0xE9,*p++);
    Free(s);
  }
  p="PSM FLOAT DONE\n";
  while (*p) OutU8(0xE9,*p++);
}
PsmStaccatoSweep;
