I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,32);
  I64 mask=0,x,y,count=0;
  dc->color=RED;GrPlot3(dc,-1,0,0);GrPlot3(dc,2,3,4);
  if(GrPeek0(dc,2,3)==RED && GrPeek0(dc,0,0)==BLACK && dc->db_z==4)mask|=1;
  dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=4;dc->z=5;
  GrPlot3(dc,1,2,3);GrPlot3B(dc,3,4,1);
  if(GrPeek0(dc,4,6)==RED && GrPeek0(dc,6,8)==RED &&
     dc->flags==DCF_TRANSFORMATION && dc->db_z==6)mask|=2;
  dc->flags=0;dc->x=dc->y=dc->z=0;DCDepthBufAlloc(dc);
  GrPlot3(dc,12,12,5);dc->color=GREEN;GrPlot3(dc,12,12,6);
  Bool ok=GrPeek0(dc,12,12)==RED && dc->depth_buf[396]==5;
  GrPlot3(dc,12,12,3);
  if(ok && GrPeek0(dc,12,12)==GREEN && dc->depth_buf[396]==3)mask|=4;
  Free(dc->depth_buf);dc->depth_buf=NULL;dc->color=BLUE;
  dc->sym.snx=GR_SCALE;dc->sym.sny=dc->sym.snz=0;
  dc->sym.sx=8;dc->sym.sy=dc->sym.sz=0;dc->flags=DCF_SYMMETRY;
  GrPlot3(dc,6,10,0);
  if(GrPeek0(dc,6,10)==BLUE && GrPeek0(dc,10,10)==BLUE &&
     dc->flags==DCF_SYMMETRY && dc->color==BLUE)mask|=8;
  dc->flags=DCF_SYMMETRY|DCF_JUST_MIRROR;GrPlot3(dc,6,14,0);
  if(GrPeek0(dc,6,14)==BLACK && GrPeek0(dc,10,14)==BLUE &&
     dc->flags==(DCF_SYMMETRY|DCF_JUST_MIRROR))mask|=16;
  dc->flags=0;dc->thick=3;dc->color=GREEN;GrPlot3(dc,20,20,0);
  for(y=18;y<=22;y++)for(x=18;x<=22;x++)
    if(GrPeek0(dc,x,y)==GREEN)count++;
  if(count==9 && GrPeek0(dc,19,19)==GREEN && GrPeek0(dc,21,21)==GREEN &&
     dc->color==GREEN && dc->thick==3 && !dc->flags)mask|=32;
  DCDel(dc);return mask;
}
