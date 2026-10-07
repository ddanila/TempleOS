Bool SPLLine(CDC *dc,I64 left,I64 right,I64 row)
{
  I64 x,y;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++)
    if((GrPeek0(dc,x,y)==RED)!=(left<=x<=right && y==row))return FALSE;
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,24);CD3I32 ctrl[4];I64 mask=0,i,before;
  dc->color=RED;for(i=0;i<4;i++){ctrl[i].x=4+4*i;ctrl[i].y=8;ctrl[i].z=0;}
  before=Fs->data_heap->used_u8s;
  if(Gr2Bezier3(dc,ctrl) && SPLLine(dc,4,12,8))mask|=1;
  DCClear(dc);
  if(Gr3Bezier3(dc,ctrl) && SPLLine(dc,4,16,8))mask|=2;
  DCClear(dc);
  if(Gr2BSpline3(dc,ctrl,4) && SPLLine(dc,4,16,8) && Fs->data_heap->used_u8s==before)mask|=4;
  DCClear(dc);
  if(Gr3BSpline3(dc,ctrl,4) && SPLLine(dc,4,16,8) && Fs->data_heap->used_u8s==before)mask|=8;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=5;
  if(Gr3BSpline3(dc,ctrl,4) && SPLLine(dc,7,19,10) && dc->flags==DCF_TRANSFORMATION && ctrl[0].x==4 && ctrl[0].y==8 && Fs->data_heap->used_u8s==before)mask|=16;
  DCClear(dc);dc->flags=0;
  if(!Gr2BSpline3(dc,ctrl,2) && !Gr3BSpline3(dc,ctrl,2) && SPLLine(dc,-1,-1,-1) && Fs->data_heap->used_u8s==before)mask|=32;
  DCDel(dc);return mask;
}
