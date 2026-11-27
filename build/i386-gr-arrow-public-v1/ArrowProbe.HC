U0 ArrowMark(U8 *s)
{
  while (*s) OutU8(0xE9,*s++);
}

U0 ArrowProbe()
{
  CDC *dc=DCNew(32,24);
  U8 *pixels=MAlloc(32*24),*message;
  I64 x,y;
  dc->color=RED;
  if (!GrArrow3(dc,5,10,0,24,10,0) ||
      GrPeek0(dc,5,10)!=RED || GrPeek0(dc,24,10)!=RED)
    throw('Arrow',TRUE);
  for (y=0;y<24;y++)
    for (x=0;x<32;x++)
      pixels[y*32+x]=GrPeek0(dc,x,y);
  message=MStrPrint("EXPORT arrow-pixels.bin %X %X\n",pixels,32*24);
  ArrowMark(message);
  Sleep(800);
  Free(message);
  Free(pixels);
  DCDel(dc);
  ArrowMark("ARROW RASTER DONE\n");
}
ArrowProbe;
