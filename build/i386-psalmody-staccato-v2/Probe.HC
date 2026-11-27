U0 PsmStaccatoProbe(I64 setting)
{
  F64 slope=0.88,offset=0.12,bias=0.0005;
  F64 initial=slope*setting/80+offset;
  F64 biased=initial+bias;
  F64 scaled=biased*1000;
  U8 *s=MStrPrint("PSM FLOAT %016X %016X %016X %016X %016X %016X %6.3f\n",
        slope(U64),offset(U64),bias(U64),initial(U64),biased(U64),scaled(U64),biased);
  U8 *p=s;
  while (*p) OutU8(0xE9,*p++);
  Free(s);
}
PsmStaccatoProbe(71);
