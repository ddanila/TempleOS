I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(8,8);
  I64 mask=0,before;
  dc->color=RED;GrPlot0(dc,1,2);
  if(GrPeek0(dc,1,2)==RED && GrPeek0(dc,2,2)==BLACK)mask|=1;
  dc->color=3;dc->color.c0.rop=ROPB_XOR;GrPlot0(dc,1,2);
  if(GrPeek0(dc,1,2)==(RED^3))mask|=2;
  dc->bkcolor=BLACK;dc->color=RED;dc->color.c0.rop=ROPB_COLLISION;
  before=dc->collision_cnt;GrPlot0(dc,1,2);GrPlot0(dc,2,2);
  if(dc->collision_cnt==before+1 && GrPeek0(dc,1,2)==(RED^3))mask|=4;
  DCDepthBufAlloc(dc);dc->color=BLUE;dc->db_z=5;GrPlot0(dc,3,3);
  dc->color=GREEN;dc->db_z=6;GrPlot0(dc,3,3);
  dc->db_z=-1;GrPlot0(dc,3,3);
  Bool ok=GrPeek0(dc,3,3)==BLUE && dc->depth_buf[27]==5;
  dc->db_z=3;GrPlot0(dc,3,3);
  if(ok && GrPeek0(dc,3,3)==GREEN && dc->depth_buf[27]==3)mask|=8;
  dc->flags=DCF_LOCATE_NEAREST|DCF_RECORD_EXTENTS|DCF_DONT_DRAW;
  dc->cur_x=1;dc->cur_y=1;dc->nearest_dist=I64_MAX;
  dc->min_x=dc->min_y=I64_MAX;dc->max_x=dc->max_y=I64_MIN;
  GrPlot0(dc,4,5);
  if(dc->nearest_dist==25 && dc->min_x==4 && dc->max_x==4 &&
     dc->min_y==5 && dc->max_y==5 && GrPeek0(dc,4,5)==BLACK)mask|=16;
  dc->flags=0;Free(dc->depth_buf);dc->depth_buf=NULL;
  dc->color=RED;dc->color.c1.color=GREEN;dc->color.c1.rop=ROPBF_DITHER;
  GrPlot0(dc,1,2);GrPlot0(dc,2,2);
  ok=GrPeek0(dc,1,2)==GREEN && GrPeek0(dc,2,2)==RED;
  dc->color.c1.rop=ROPBF_PROBABILITY_DITHER;dc->dither_probability_u16=0;
  GrPlot0(dc,1,2);
  if(ok && GrPeek0(dc,1,2)==RED)mask|=32;
  DCDel(dc);return mask;
}
