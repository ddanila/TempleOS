U64 *animation_base=text.font;
#include "::/Demo/Graphics/CharAnimation.HC"
U0 AnimationProbe()
{
  I64 i,seen=0;
  U64 value;
  U8 *s="DONE character animation\n";
  for (i=0;i<80 && seen!=15;i++) {
    if (text.font!=animation_base) {
      value=text.font(U64 *)[CH_SPACE];
      if (value==0x0011AA440011AA44) seen|=1;
      if (value==0x0022558800225588) seen|=2;
      if (value==0x0044AA110044AA11) seen|=4;
      if (value==0x0088552200885522) seen|=8;
    }
    Sleep(20);
  }
  if (seen!=15) throw('FontAnim',TRUE);
  while (*s) OutU8(0xE9,*s++);
}
AnimationProbe;
