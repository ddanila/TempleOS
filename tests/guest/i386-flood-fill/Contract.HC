Bool FFCanvas(CDC *dc,I64 left,I64 top,I64 right,I64 bottom)
{
  I64 x,y;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++)
    if((GrPeek0(dc,x,y)==RED)!=(left<=x<=right && top<=y<=bottom))return FALSE;
  return TRUE;
}
U0 FFBoundary(CDC *dc)
{
  I64 x,y;
  dc->color=BLUE;
  for(x=4;x<=11;x++){GrPlot0(dc,x,3);GrPlot0(dc,x,8);}
  for(y=3;y<=8;y++){GrPlot0(dc,4,y);GrPlot0(dc,11,y);}
  dc->color=RED;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,16),*brush=DCNew(1,1);
  I64 mask=0,before=Fs->data_heap->used_u8s;CColorROPU32 saved;
  dc->color=RED;
  if(GrFloodFill(dc,0,0)==512 && FFCanvas(dc,0,0,31,15) && Fs->data_heap->used_u8s==before)mask|=1;
  if(GrFloodFill(dc,0,0)==0 && GrFloodFill(dc,-1,0)==0 && GrFloodFill(dc,32,0)==0 && FFCanvas(dc,0,0,31,15))mask|=2;
  DCClear(dc);FFBoundary(dc);
  if(GrFloodFill(dc,5,4)==24 && FFCanvas(dc,5,4,10,7))mask|=4;
  DCClear(dc);FFBoundary(dc);dc->color=GREEN;GrPlot0(dc,5,4);dc->color=BLUE;
  if(GrFloodFill(dc,5,4,TRUE)==24 && GrPeek0(dc,5,4)==BLUE && GrPeek0(dc,10,7)==BLUE && GrPeek0(dc,0,0)==BLACK)mask|=8;
  DCClear(dc);FFBoundary(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=7;
  if(GrFloodFill3(dc,2,2,0)==24 && FFCanvas(dc,5,4,10,7) && dc->flags==DCF_TRANSFORMATION)mask|=16;
  DCClear(dc);dc->flags=DCF_DONT_DRAW;dc->brush=brush;dc->color2=GREEN;saved=dc->color2;
  if(GrFloodFill(dc,0,0)==0 && FFCanvas(dc,-1,-1,-1,-1) && dc->brush==brush && dc->color2==saved && dc->flags==DCF_DONT_DRAW && Fs->data_heap->used_u8s==before)mask|=32;
  dc->brush=NULL;DCDel(brush);DCDel(dc);return mask;
}
