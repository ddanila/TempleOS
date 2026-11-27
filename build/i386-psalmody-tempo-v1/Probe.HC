U0 PsmTempoTrace()
{
  I64 setting;
  F64 factor,biased,scaled;
  U8 *s,*p;
  for (setting=0;setting<80;setting++) {
    factor=4.4*setting/80+0.5;
    biased=factor+0.0005;
    scaled=biased*Pow10I64(3);
    s=MStrPrint("PSM SWEEP %d %016X %016X %016X %016X %d %.3f\n",
          setting,Pow10I64(3)(U64),factor(U64),biased(U64),scaled(U64),
          ToI64(Round(scaled)),biased);
    p=s;
    while (*p) OutU8(0xE9,*p++);
    Free(s);
  }
  p="PSM FLOAT DONE\n";
  while (*p) OutU8(0xE9,*p++);
}
PsmTempoTrace;
