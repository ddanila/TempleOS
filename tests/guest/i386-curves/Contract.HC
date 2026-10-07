Bool CVPoint(CDC *dc,I64 px,I64 py)
{
  I64 x,y;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++)
    if((GrPeek0(dc,x,y)==RED)!=(x==px && y==py))return FALSE;
  return TRUE;
}
Bool CVShift(CDC *base,CDC *moved,I64 dx,I64 dy)
{
  I64 x,y,expected,count=0;
  for(y=0;y<moved->height;y++)for(x=0;x<moved->width;x++) {
    expected=BLACK;
    if(0<=x-dx<base->width && 0<=y-dy<base->height)expected=GrPeek0(base,x-dx,y-dy);
    if(GrPeek0(moved,x,y)!=expected)return FALSE;
    if(expected==RED)count++;
  }
  return count>8;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(40,32),*base=DCNew(40,32);I64 mask=0;
  dc->color=base->color=RED;
  if(GrCircle3(dc,16,12,0,0) && GrEllipse3(dc,16,12,0,0,6) && GrRegPoly3(dc,16,12,0,4,4,0) && CVPoint(dc,-1,-1))mask|=1;
  if(GrCircle3(dc,16,12,0,4,0) && GrEllipse3(dc,16,12,0,6,4,0,0) && CVPoint(dc,-1,-1))mask|=2;
  if(GrCircle3(dc,16,12,0,4,1,0,0) && CVPoint(dc,20,12))mask|=4;
  DCClear(dc);
  if(GrEllipse3(dc,16,12,0,6,4,0,1,0,0) && CVPoint(dc,22,12))mask|=8;
  DCClear(dc);GrEllipse3(base,16,12,0,6,4);
  dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=5;
  if(GrEllipse3(dc,16,12,0,6,4) && CVShift(base,dc,3,2) && dc->flags==DCF_TRANSFORMATION)mask|=16;
  DCClear(dc);DCClear(base);GrRegPoly3(base,16,12,0,6,4,5);
  if(GrRegPoly3(dc,16,12,0,6,4,5) && CVShift(base,dc,3,2) && dc->flags==DCF_TRANSFORMATION)mask|=32;
  DCDel(base);DCDel(dc);return mask;
}
