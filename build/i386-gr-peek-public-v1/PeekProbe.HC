U0 PeekMark(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}

U0 PeekProbe()
{
  CDC *dc=DCNew(8,8);
  dc->color=GREEN;
  GrPlot(dc,2,3);
  if (GrPeek(dc,2,3)!=GREEN || GrPeek(dc,1,3)==GREEN ||
      GrPeek(dc,-1,3)!=-1 || GrPeek(dc,2,8)!=-1 ||
      GrPeek(dc,8,3)!=-1 || GrPeek(dc,2,-1)!=-1)
    throw('Peek',TRUE);
  DCDel(dc);
  PeekMark("PEEK OFFSCREEN DONE\n");
}
PeekProbe;
