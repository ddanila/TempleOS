U0 RainbowMark(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}
U8 rainbow_expected[10]={BLACK,BROWN,RED,LTRED,YELLOW,GREEN,BLUE,PURPLE,LTGRAY,WHITE};
U0 RainbowProbe()
{
  if (MemCmp(rainbow_expected,gr_rainbow_10,10)) throw('Rainbow',TRUE);
  RainbowMark("RAINBOW BYTES DONE\n");
}
RainbowProbe;
