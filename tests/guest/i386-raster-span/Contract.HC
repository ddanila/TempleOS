I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(8,8);I64 mask=0,i;
  dc->color=RED;
  if(GrHLine(dc,5,1,2)==5 && GrPeek0(dc,1,2)==RED && GrPeek0(dc,5,2)==RED && GrPeek0(dc,6,2)==BLACK)mask|=1;
  if(GrVLine(dc,3,6,2)==5 && GrPeek0(dc,3,2)==RED && GrPeek0(dc,3,6)==RED && GrPeek0(dc,3,7)==BLACK)mask|=2;
  if(GrHLine(dc,-3,2,0)==3 && GrVLine(dc,7,-2,1)==2 && GrPeek0(dc,0,0)==RED && GrPeek0(dc,3,0)==BLACK && GrPeek0(dc,7,1)==RED)mask|=4;
  DCClear(dc);DCDepthBufAlloc(dc);dc->depth_buf[28]=3;dc->color=GREEN;
  Bool ok=GrHLine(dc,1,5,3,1,5)==4;
  for(i=1;i<=5;i++) {
    if(i==4) {if(GrPeek0(dc,i,3)!=BLACK || dc->depth_buf[24+i]!=3)ok=FALSE;}
    else if(GrPeek0(dc,i,3)!=GREEN || dc->depth_buf[24+i]!=i)ok=FALSE;
  }
  if(ok)mask|=8;
  dc->depth_buf[38]=3;dc->color=BLUE;ok=GrVLine(dc,6,5,1,5,1)==4;
  for(i=1;i<=5;i++) {
    if(i==4) {if(GrPeek0(dc,6,i)!=BLACK || dc->depth_buf[i*8+6]!=3)ok=FALSE;}
    else if(GrPeek0(dc,6,i)!=BLUE || dc->depth_buf[i*8+6]!=i)ok=FALSE;
  }
  if(ok)mask|=16;
  dc->color=RED;dc->color.c1.color=GREEN;dc->color.c1.rop=ROPBF_DITHER;
  ok=GrHLine(dc,0,3,6,0,0)==4 && GrPeek0(dc,0,6)==RED && GrPeek0(dc,1,6)==GREEN && GrPeek0(dc,2,6)==RED && GrPeek0(dc,3,6)==GREEN;
  dc->color.c1.rop=ROPBF_PROBABILITY_DITHER;dc->dither_probability_u16=0;
  GrHLine(dc,0,3,7,0,0);
  for(i=0;i<4;i++)if(GrPeek0(dc,i,7)!=RED)ok=FALSE;
  if(ok)mask|=32;
  DCDel(dc);return mask;
}
