I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(16,16),*large=DCNew(96,96);
  I64 mask=0,x,y,n,count=0,expected_count=0;
  Bool ok=TRUE,expected;
  I64 bound,left_edge,rr;
  dc->color=RED;
  if(!GrFillCircle(dc,4,4,0,0) && GrFillCircle(dc,4,4,0,1)==1 && GrPeek0(dc,4,4)==RED)mask|=1;
  DCClear(dc);
  if(GrFillCircle(dc,8,8,0,3)==9 && GrPeek0(dc,7,7)==RED && GrPeek0(dc,9,9)==RED && GrPeek0(dc,6,8)==BLACK)mask|=2;
  DCClear(dc);
  if(GrFillCircle(dc,0,0,0,3)==4 && GrPeek0(dc,0,0)==RED && GrPeek0(dc,1,1)==RED && GrPeek0(dc,2,1)==BLACK)mask|=4;
  DCClear(dc);DCDepthBufAlloc(dc);dc->depth_buf[136]=2;
  if(GrFillCircle(dc,8,8,3,3)==8 && GrPeek0(dc,8,8)==BLACK && dc->depth_buf[136]==2 && GrPeek0(dc,7,7)==RED && dc->depth_buf[119]==3)mask|=8;
  Free(dc->depth_buf);dc->depth_buf=NULL;
  for(n=0;n<8;n++) {
    DCClear(dc);if(GrFillSemiCircle(dc,8,8,0,3,n)!=3)ok=FALSE;
    for(y=6;y<=10;y++)for(x=6;x<=10;x++) {
      expected=FALSE;
      switch(n) {
        case 0:case 4: expected=y==7 && 7<=x<=9;break;
        case 1:case 5: expected=y==9 && 7<=x<=9;break;
        case 2:case 6: expected=x==7 && 7<=y<=9;break;
        case 3:case 7: expected=x==9 && 7<=y<=9;break;
      }
      if((GrPeek0(dc,x,y)==RED)!=expected)ok=FALSE;
    }
  }
  if(ok)mask|=16;
  large->color=GREEN;count=GrFillCircle(large,48,48,0,64);ok=TRUE;
  for(y=0;y<96;y++)for(x=0;x<96;x++) {
    expected=FALSE;
    if(16<=y<=80) {
      rr=1089-(y-48)*(y-48);bound=0;
      while((bound+1)*(bound+1)<=rr)bound++;
      left_edge=48-bound;
      if(bound*bound<rr)left_edge--;
      expected=left_edge<=x<=48+bound;
    }
    if(expected)expected_count++;
    if((GrPeek0(large,x,y)==GREEN)!=expected)ok=FALSE;
  }
  if(ok && count==expected_count)mask|=32;
  DCDel(large);DCDel(dc);return mask;
}
