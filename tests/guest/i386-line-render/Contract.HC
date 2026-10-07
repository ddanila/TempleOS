I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,32);I64 mask=0,x,y;Bool ok;
  dc->color=RED;
  ok=GrLine(dc,6,3,2,3);
  for(x=0;x<32;x++)if((GrPeek0(dc,x,3)==RED)!=(2<=x<=6))ok=FALSE;
  if(ok)mask|=1;
  DCClear(dc);ok=GrLine3(dc,2,2,1,6,6,5);
  for(y=0;y<10;y++)for(x=0;x<10;x++)
    if((GrPeek0(dc,x,y)==RED)!=(x==y && 2<=x<=6))ok=FALSE;
  if(ok && dc->db_z==0)mask|=2;
  DCClear(dc);ok=GrLine(dc,-4,7,4,7);
  for(x=0;x<32;x++)if((GrPeek0(dc,x,7)==RED)!=(0<=x<=4))ok=FALSE;
  if(ok)mask|=4;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=4;dc->z=5;
  GrLine3(dc,1,1,0,3,1,0);
  if(GrPeek0(dc,4,5)==RED && GrPeek0(dc,6,5)==RED && GrPeek0(dc,3,5)==BLACK &&
     dc->flags==DCF_TRANSFORMATION && dc->db_z==0)mask|=8;
  dc->flags=0;dc->x=dc->y=dc->z=0;DCClear(dc);DCDepthBufAlloc(dc);
  dc->depth_buf[324]=1;dc->color=GREEN;GrLine3(dc,2,10,2,6,10,6);ok=TRUE;
  for(x=2;x<=6;x++) {
    if(x==4) {if(GrPeek0(dc,x,10)!=BLACK || dc->depth_buf[320+x]!=1)ok=FALSE;}
    else if(GrPeek0(dc,x,10)!=GREEN || dc->depth_buf[320+x]!=x)ok=FALSE;
  }
  if(ok)mask|=16;
  Free(dc->depth_buf);dc->depth_buf=NULL;DCClear(dc);dc->thick=3;
  GrLine3(dc,8,20,0,12,20,0);ok=TRUE;
  for(y=0;y<32;y++)for(x=0;x<32;x++)
    if((GrPeek0(dc,x,y)==GREEN)!=(7<=x<=13 && 19<=y<=21))ok=FALSE;
  if(ok && dc->thick==3 && dc->color==GREEN && !dc->flags)mask|=32;
  DCDel(dc);return mask;
}
