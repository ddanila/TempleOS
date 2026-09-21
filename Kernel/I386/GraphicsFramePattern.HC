#ifndef I386_GRAPHICS_FRAME_PATTERN_INCLUDED
#define I386_GRAPHICS_FRAME_PATTERN_INCLUDED
#include "/Kernel/I386/TextRenderPattern.HC"
U0 GraphicsFramePattern(U32 *cells,CDC *persistent)
{
  I64 x,y;
  TextRenderPattern(cells);
  DCFill(persistent,TRANSPARENT);
  //Persistent graphics overwrite both task drawing and text; holes reveal either.
  for(y=140;y<340;y++) for(x=240;x<560;x++)
    if((x/16+y/16)&1) persistent->body[y*640+x]=(x/32+y/32)&15;
}
U0 GraphicsFrameDraw(CDC *dc)
{
  I64 x,y;
  if(dc->alias!=gr.dc2 || dc->flags&DCF_ON_TOP) throw('FrmDraw',TRUE);
  for(y=80;y<240;y++) for(x=80;x<400;x++) dc->body[y*640+x]=(x/20+y/20)&15;
}
U0 GraphicsFrameFinal(CDC *dc)
{
  I64 x,y;
  if(dc->alias!=gr.dc2 || !(dc->flags&DCF_ON_TOP)) throw('FrameEnd',TRUE);
  for(y=180;y<300;y++) for(x=300;x<320;x++) dc->body[y*640+x]=WHITE;
  for(y=230;y<250;y++) for(x=250;x<370;x++) dc->body[y*640+x]=BLACK;
}
#endif
