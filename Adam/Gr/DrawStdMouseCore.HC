public U0 DrawStdMs(CDC *dc,I64 x,I64 y)
{//This is a callback. See $LK,"::/Demo/Graphics/Grid.HC"$.
//Called by $LK,"DrawMs",A="MN:DrawMs"$() which is
  //called by $LK,"WinFinalUpdate",A="MN:WinFinalUpdate"$().
  dc->thick=1;
  dc->flags&=~(DCF_TRANSFORMATION|DCF_SYMMETRY);
  GrArrow3(dc,x+8,y+8,0,x,y,0);
}
