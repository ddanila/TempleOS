Bool ARShape(CDC *dc,I64 left,I64 right,I64 row,Bool head=FALSE)
{
  I64 x,y;Bool pixel;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    pixel=(left<=x<=right && y==row);
    if(head)pixel|=(x==right-2 && (y==row-2 || y==row+2)) || (x==right-1 && (y==row-1 || y==row+1));
    if((GrPeek0(dc,x,y)==RED)!=pixel)return FALSE;
  }
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,24);I64 mask=0;dc->color=RED;
  if(GrArrow3(dc,5,8,0,15,8,0,0) && ARShape(dc,5,15,8))mask|=1;
  DCClear(dc);
  if(GrArrow3(dc,5,8,0,15,8,0,2) && ARShape(dc,5,15,8,TRUE))mask|=2;
  DCClear(dc);
  if(GrArrow3(dc,10,12,0,10,12,0) && ARShape(dc,10,10,12))mask|=4;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=5;
  if(GrArrow3(dc,2,6,0,12,6,0,2) && ARShape(dc,5,15,8,TRUE) && dc->flags==DCF_TRANSFORMATION && dc->color==RED)mask|=8;
  DCClear(dc);dc->flags=0;
  if(GrArrow3(dc,-5,8,0,5,8,0,0) && ARShape(dc,0,5,8))mask|=16;
  DCClear(dc);dc->sym.snx=GR_SCALE;dc->sym.sny=dc->sym.snz=0;
  dc->sym.sx=16;dc->sym.sy=dc->sym.sz=0;dc->flags=DCF_SYMMETRY|DCF_JUST_MIRROR;
  if(GrArrow3(dc,3,8,0,8,8,0,0) && ARShape(dc,24,29,8) && dc->flags==(DCF_SYMMETRY|DCF_JUST_MIRROR))mask|=32;
  DCDel(dc);return mask;
}
