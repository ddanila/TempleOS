I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(8,8),*img=DCNew(3,2);
  I64 mask=0,before;
  img->body[0]=RED;img->body[1]=TRANSPARENT;img->body[2]=BLUE;
  img->body[8]=GREEN;img->body[9]=YELLOW;img->body[10]=WHITE;
  dc->color=0;
  if(GrBlot(dc,2,2,img)==1 && GrPeek0(dc,2,2)==RED &&
     GrPeek0(dc,3,2)==BLACK && GrPeek0(dc,4,2)==BLUE && GrPeek0(dc,3,3)==YELLOW)mask|=1;
  DCClear(dc);
  if(GrBlot(dc,-1,-1,img)==1 && GrPeek0(dc,0,0)==YELLOW &&
     GrPeek0(dc,1,0)==WHITE && GrPeek0(dc,2,0)==BLACK && !GrBlot(dc,20,20,img))mask|=2;
  DCFill(dc,1);dc->color.c0.rop=ROPB_XOR;
  GrBlot(dc,2,2,img);
  if(GrPeek0(dc,2,2)==(RED^1) && GrPeek0(dc,3,2)==1 && GrPeek0(dc,4,2)==(BLUE^1))mask|=4;
  DCClear(dc);DCFill(img,COLOR_MONO);img->flags|=DCF_NO_TRANSPARENTS;
  dc->color=GREEN;dc->color.c0.rop=ROPB_MONO;GrBlot(dc,1,1,img);
  if(GrPeek0(dc,1,1)==GREEN && GrPeek0(dc,3,2)==GREEN && GrPeek0(dc,4,2)==BLACK)mask|=8;
  dc->color.c0.rop=ROPB_COLLISION;dc->bkcolor=BLACK;before=dc->collision_cnt;
  GrBlot(dc,1,1,img);
  Bool transparent_ok=dc->collision_cnt==before;
  DCFill(img,RED);GrBlot(dc,1,1,img);
  if(transparent_ok && dc->collision_cnt==before+6 && GrPeek0(dc,1,1)==GREEN)mask|=16;
  dc->flags=DCF_RECORD_EXTENTS|DCF_DONT_DRAW;dc->min_x=dc->min_y=I64_MAX;
  dc->max_x=dc->max_y=I64_MIN;DCDepthBufAlloc(dc);
  I32 *saved_depth=dc->depth_buf;I64 saved_color=dc->color;
  GrBlot(dc,5,6,img);
  if(dc->min_x==5 && dc->max_x==7 && dc->min_y==6 && dc->max_y==7 &&
     dc->depth_buf==saved_depth && dc->color==saved_color && GrPeek0(dc,5,6)==BLACK)mask|=32;
  DCDel(img);DCDel(dc);
  CDC *wide=DCNew(32,8),*source;
  I64 width,offset,row,col,sy,sx,oy,mode,expected;
  Bool alignment_ok=TRUE;
  for(mode=0;mode<2;mode++)for(width=1;width<=24;width++) {
    source=DCNew(width,3);
    if(mode)source->flags|=DCF_NO_TRANSPARENTS;
    for(sy=0;sy<3;sy++)for(sx=0;sx<width;sx++) {
      expected=(sx*3+sy*5)%(17-mode);
      if(expected==16)expected=TRANSPARENT;
      source->body[sy*source->width_internal+sx]=expected;
    }
    for(offset=-3;offset<=11;offset++)for(oy=-1;oy<=2;oy++) {
      DCFill(wide,9);wide->color=0;GrBlot(wide,offset,oy,source);
      for(row=0;row<8;row++)for(col=0;col<32;col++) {
        expected=9;sx=col-offset;sy=row-oy;
        if(0<=sx<width && 0<=sy<3) {
          expected=(sx*3+sy*5)%(17-mode);
          if(expected==16)expected=9;
        }
        if(GrPeek0(wide,col,row)!=expected)alignment_ok=FALSE;
      }
    }
    DCDel(source);
  }
  if(alignment_ok)mask|=64;
  DCDel(wide);return mask;
}
