I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,32),*img=DCNew(2,2),*brush=DCNew(1,1);
  I64 mask=0,saved_color;
  img->body[0]=RED;img->body[1]=BLUE;img->body[8]=GREEN;img->body[9]=YELLOW;
  dc->color=0;
  if(GrBlot3(dc,2,2,0,img)==1 && GrPeek0(dc,2,2)==RED &&
     GrPeek0(dc,3,2)==BLUE && GrPeek0(dc,2,3)==GREEN)mask|=1;
  dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=4;dc->z=5;
  GrBlot3(dc,1,1,1,img);
  if(GrPeek0(dc,4,5)==RED && GrPeek0(dc,5,5)==BLUE &&
     dc->flags==DCF_TRANSFORMATION && !dc->color)mask|=2;
  dc->flags=0;dc->x=dc->y=dc->z=0;DCDepthBufAlloc(dc);
  GrBlot3(dc,12,12,5,img);img->body[0]=WHITE;GrBlot3(dc,12,12,6,img);
  Bool ok=GrPeek0(dc,12,12)==RED && dc->depth_buf[396]==5;
  GrBlot3(dc,12,12,3,img);
  if(ok && GrPeek0(dc,12,12)==WHITE && dc->depth_buf[396]==3)mask|=4;
  Free(dc->depth_buf);dc->depth_buf=NULL;img->body[0]=RED;
  dc->sym.snx=GR_SCALE;dc->sym.sny=dc->sym.snz=0;
  dc->sym.sx=8;dc->sym.sy=dc->sym.sz=0;dc->flags=DCF_SYMMETRY;
  GrBlot3(dc,3,18,0,img);
  if(GrPeek0(dc,3,18)==RED && GrPeek0(dc,4,18)==BLUE &&
     GrPeek0(dc,13,18)==RED && GrPeek0(dc,12,18)==BLUE && dc->flags==DCF_SYMMETRY)mask|=8;
  dc->flags=DCF_SYMMETRY|DCF_JUST_MIRROR;GrBlot3(dc,3,22,0,img);
  if(GrPeek0(dc,3,22)==BLACK && GrPeek0(dc,13,22)==RED &&
     dc->flags==(DCF_SYMMETRY|DCF_JUST_MIRROR))mask|=16;
  dc->flags=DCF_TRANSFORMATION;dc->color=GREEN;dc->color.c0.rop=ROPB_MONO;
  saved_color=dc->color;dc->brush=brush;
  img->body[0]=0;img->body[1]=1;img->body[8]=255;img->body[9]=0;
  GrBlot3(dc,20,26,0,img);
  if(GrPeek0(dc,20,26)==BLACK && GrPeek0(dc,21,26)==GREEN &&
     GrPeek0(dc,20,27)==GREEN && GrPeek0(dc,21,27)==BLACK &&
     dc->brush==brush && dc->color==saved_color && dc->flags==DCF_TRANSFORMATION)mask|=32;
  dc->brush=NULL;DCDel(brush);DCDel(img);DCDel(dc);return mask;
}
