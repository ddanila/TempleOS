#ifndef I386_TEXT_RENDER_PATTERN_INCLUDED
#define I386_TEXT_RENDER_PATTERN_INCLUDED
U0 TextRenderPattern(U32 *cells)
{
  I64 i,x,y;
  for(i=0;i<4800;i++) {
    x=y=0;
    if(!(i%7)) x=i%31-15;
    if(!(i%11)) y=i%31-15;
    cells[i]=((i*17)&255)|((i*7)&255)<<8|(x&31)<<16|(y&31)<<21|(i/256%16)<<28;
  }
}
#endif
