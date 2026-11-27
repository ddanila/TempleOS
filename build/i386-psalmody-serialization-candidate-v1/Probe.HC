I64 PsmSliderMilli(I64 setting,U64 slope,U64 offset,I64 fraction_bits)
{
  //Slope and offset are the original literal values in unsigned fixed point.
  //Round the exact affine expression once to a 53-bit significand.
  U64 numerator=slope*setting+offset*80;
  I64 shift=Bsr(numerator/80)-52;
  U64 denominator=80(U64)<<shift;
  U64 significand=numerator/denominator,remainder=numerator%denominator;
  if (remainder*2>denominator ||
      remainder*2==denominator && significand&1)
    significand++;
  F64 factor=ToF64(significand)/ToF64(1(U64)<<(fraction_bits-shift));
  F64 biased=factor+0x3F40624DD2F1A9FE(F64);
  F64 scaled=biased*0x408F3FFFFFFFFFFF(F64);
  return ToI64(Round(scaled));
}

U0 PsmSerializationSweep()
{
  I64 setting,tempo,staccato;
  U8 *s,*p;
  for (setting=0;setting<80;setting++) {
    tempo=PsmSliderMilli(setting,0x8CCCCCCCCCCCD0,0x10000000000000,53);
    staccato=PsmSliderMilli(setting,0xE147AE147AE150,0x1EB851EB851EBA,56);
    s=MStrPrint("PSM SWEEP %d %d.%03d %d.%03d\n",setting,
          tempo/1000,tempo%1000,staccato/1000,staccato%1000);
    p=s;
    while (*p) OutU8(0xE9,*p++);
    Free(s);
  }
  p="PSM FLOAT DONE\n";
  while (*p) OutU8(0xE9,*p++);
}
PsmSerializationSweep;
