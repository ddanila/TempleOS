I64 SplineFrames()
{
  CD3I32 points[5];
  CDC *dc=DCNew(96,80);
  I64 i,closed,order,mask=0,used,bytes=dc->width_internal*dc->height;
  U8 *filename;
  points[0].x=10;points[0].y=17;points[0].z=-9;
  points[1].x=26;points[1].y=59;points[1].z=28;
  points[2].x=48;points[2].y=11;points[2].z=-4;
  points[3].x=67;points[3].y=49;points[3].z=19;
  points[4].x=84;points[4].y=22;points[4].z=-17;
  dc->color=RED;
  for(order=2;order<=3;order++)for(closed=0;closed<=1;closed++) {
    DCClear(dc);
    filename=MStrPrint("C:/Spline%d%d.BIN",order,closed);
    used=Fs->data_heap->used_u8s;
    if(order==2)i=Gr2BSpline(dc,points,5,closed);
    else i=Gr3BSpline(dc,points,5,closed);
    if(i && used==Fs->data_heap->used_u8s && FileWrite(filename,dc->body,bytes)>0)
      mask|=1<<((order-2)*2+closed);
    Free(filename);
  }
  DCDel(dc);
  return mask;
}
