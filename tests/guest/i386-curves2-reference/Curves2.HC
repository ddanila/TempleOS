Bool C2Same(CDC *a,CDC *b)
{
  I64 x,y;
  for(y=0;y<a->height;y++)for(x=0;x<a->width;x++)
    if(GrPeek0(a,x,y)!=GrPeek0(b,x,y))return FALSE;
  return TRUE;
}
I64 C2Contract()
{
  CDC *dc=DCNew(40,32),*base=DCNew(40,32);I32 *depth;I64 mask=0;
  dc->color=base->color=RED;
  if(GrEllipse(dc,16,12,0,6) && GrPeek0(dc,16,12)==BLACK)mask|=1;
  if(GrEllipse(dc,16,12,6,4,0,1,0,0) && GrPeek0(dc,22,12)==RED)mask|=2;
  DCClear(dc);if(GrEllipse(dc,16,12,6,4) && GrPeek0(dc,22,12)==RED)mask|=4;
  if(GrFloodFill(dc,16,12)>0 && GrPeek0(dc,16,12)==RED)mask|=8;
  DCClear(dc);GrEllipse(base,16,12,6,4);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;
  if(GrEllipse(dc,16,12,6,4) && C2Same(base,dc) && dc->flags==DCF_TRANSFORMATION)mask|=16;
  dc->flags=0;DCClear(dc);depth=DCDepthBufAlloc(dc);
  if(depth && GrEllipse(dc,16,12,6,4) && dc->depth_buf==depth)mask|=32;
  DCClear(dc);
  if(GrCircle(dc,16,12,4,1,0,0) && GrPeek0(dc,20,12)==RED)mask|=64;
  DCClear(dc);DCClear(base);GrRegPoly(base,16,12,6,4,5);dc->flags=DCF_TRANSFORMATION;
  if(GrRegPoly(dc,16,12,6,4,5) && C2Same(base,dc) && GrPeek0(dc,22,12)==RED)mask|=128;
  DCDel(base);DCDel(dc);return mask;
}
I64 C2Check(){I64 v=C2Contract;if(v!=255)throw('Curves2',TRUE);return v;}
