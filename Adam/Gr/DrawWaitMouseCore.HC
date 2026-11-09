public U0 DrawWaitMs(CDC *dc,I64 x,I64 y)
{//This is a callback. See $LK,"::/Demo/Graphics/Grid.HC"$.
  I64 old_pen_width=dc->thick;
  CColorROPU32 old_color=dc->color;
  dc->thick=3;
  dc->color=LTRED;
  GrCircle3(dc,x,y,0,7);
  GrLine3(dc,x-6,y+6,0,x+6,y-6,0);
  dc->color=RED;
  GrCircle(dc,x,y,7);
  GrLine(dc,x-6,y+6,x+6,y-6);
  dc->thick=old_pen_width;
  dc->color=old_color;
}

