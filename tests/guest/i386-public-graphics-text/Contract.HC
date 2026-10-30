Bool PublicTextPixels(CDC *dc,I64 ax,I64 ay,I64 bx,I64 by)
{
  I64 x,y,rx,ry,expected;
  U8 *font=text.font;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    expected=BLACK;rx=x-ax;ry=y-ay;
    if(0<=rx<8 && 0<=ry<8 && (font['A'*8+ry]>>rx)&1)expected=RED;
    rx=x-bx;ry=y-by;
    if(0<=rx<8 && 0<=ry<8 && (font['B'*8+ry]>>rx)&1)expected=RED;
    if(dc->body[y*dc->width_internal+x]!=expected)return FALSE;
  }
  return TRUE;
}
I64 PublicTextContract()
{
  CDC *dc=DCNew(32,16);I64 mask=0;
  DCClear(dc);dc->color=RED;
  if(GrPrint(dc,1,2,"%c%c",'A','B')==2 && PublicTextPixels(dc,1,2,9,2))mask|=1;
  DCClear(dc);
  if(GrPrint(dc,30,2,"%s","A")==1 && PublicTextPixels(dc,30,2,-100,-100))mask|=2;
  DCClear(dc);
  if(GrVPrint(dc,2,0,"%s","AB")==2 && PublicTextPixels(dc,2,0,2,8))mask|=4;
  DCDel(dc);return mask;
}
