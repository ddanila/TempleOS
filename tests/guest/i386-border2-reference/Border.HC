I64 BRCount(CDC *dc)
{
  I64 x,y,n=0;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++)if(GrPeek0(dc,x,y)==RED)n++;
  return n;
}
Bool BRShift(CDC *base,CDC *dc,I64 dx,I64 dy)
{
  I64 x,y,expect;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    expect=BLACK;if(x>=dx && y>=dy)expect=GrPeek0(base,x-dx,y-dy);
    if(GrPeek0(dc,x,y)!=expect)return FALSE;
  }
  return TRUE;
}
I64 BRContract()
{
  CDC *dc=DCNew(24,20),*base=DCNew(24,20);I64 mask=0,n;
  dc->color=base->color=RED;GrBorder(base,4,4,12,10);n=BRCount(base);
  if(n==28 && GrPeek0(base,4,4)==RED && GrPeek0(base,12,10)==RED && GrPeek0(base,8,7)==BLACK)mask|=1;
  dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;GrBorder(dc,4,4,12,10);
  if(BRShift(base,dc,3,2) && dc->flags==DCF_TRANSFORMATION)mask|=2;
  dc->flags=0;DCClear(dc);dc->thick=3;GrBorder(dc,4,4,12,10);
  if(BRCount(dc)>n)mask|=4;
  DCClear(dc);dc->thick=1;
  if(GrRectB(dc,8,6,4,2)==25 && GrPeek0(dc,4,2)==RED && GrPeek0(dc,8,6)==RED && GrPeek0(dc,3,2)==BLACK)mask|=8;
  DCDel(base);DCDel(dc);return mask;
}
I64 BRCheck(){I64 v=BRContract;if(v!=15)throw('Border',TRUE);return v;}
