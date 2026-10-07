Bool FPRect(CDC *dc,I64 left,I64 top,I64 right,I64 bottom)
{
  I64 x,y;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++)
    if((GrPeek0(dc,x,y)==RED)!=(left<=x<=right && top<=y<=bottom))return FALSE;
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,24);CD3I32 p[4];I64 mask=0,i;
  dc->color=RED;
  if(GrRect3(dc,5,4,0,6,4)>0 && FPRect(dc,5,4,11,8))mask|=1;
  DCClear(dc);
  if(GrRect3(dc,-2,-1,0,5,4)>0 && FPRect(dc,0,0,3,3))mask|=2;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=5;
  if(GrRect3(dc,2,2,0,6,4)>0 && FPRect(dc,5,4,11,8) && dc->flags==DCF_TRANSFORMATION)mask|=4;
  DCClear(dc);dc->flags=DCF_SYMMETRY|DCF_JUST_MIRROR;
  dc->sym.snx=GR_SCALE;dc->sym.sny=dc->sym.snz=0;dc->sym.sx=16;dc->sym.sy=dc->sym.sz=0;
  if(GrRect3(dc,3,4,0,5,4)>0 && FPRect(dc,24,4,29,8) && dc->flags==(DCF_SYMMETRY|DCF_JUST_MIRROR))mask|=8;
  DCClear(dc);dc->flags=0;
  if(GrFillPoly3(dc,2,p)==0 && FPRect(dc,-1,-1,-1,-1))mask|=16;
  p[0].x=5;p[0].y=4;p[1].x=11;p[1].y=4;p[2].x=11;p[2].y=8;p[3].x=5;p[3].y=8;
  for(i=0;i<4;i++)p[i].z=0;
  if(GrFillPoly3(dc,4,p)>0 && FPRect(dc,5,4,11,8))mask|=32;
  DCDel(dc);return mask;
}
