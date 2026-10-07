U8 gt_a[8]={0x18,0x24,0x42,0x7E,0x42,0x42,0x42,0};
U8 gt_b[8]={0x7C,0x42,0x42,0x7C,0x42,0x42,0x7C,0};
Bool GTGlyph(I64 x,I64 y,I64 ox,I64 oy,U8 *glyph)
{
  x-=ox;y-=oy;
  if(0<=x<8 && 0<=y<8)return (glyph[y]>>x)&1;
  return FALSE;
}
Bool GTMatches(CDC *dc,I64 ax,I64 ay,I64 bx=-1000,I64 by=-1000,I64 cx=-1000,I64 cy=-1000)
{
  I64 x,y,expected;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    expected=BLACK;
    if(GTGlyph(x,y,ax,ay,gt_a) || GTGlyph(x,y,bx,by,gt_b) || GTGlyph(x,y,cx,cy,gt_a))expected=RED;
    if(GrPeek0(dc,x,y)!=expected) {
      U8 *line=MStrPrint("OBS text pixel %d %d actual %d expected %d\n",x,y,GrPeek0(dc,x,y),expected),*scan=line;
      while(*scan)OutU8(0xE9,*scan++);
      Free(line);return FALSE;
    }
  }
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(80,32);U8 *font=CAlloc(2048);
  U64 *saved_font=text.font;I64 flags=GetRFlags,mask=0;
  MemCpy(font+8*'A',gt_a,8);MemCpy(font+8*'B',gt_b,8);
  SetRFlags(flags&~0x200);text.font=font;dc->color=RED;
  if(GrPutChar(dc,3,2,'A')==1 && GTMatches(dc,3,2))mask|=1;
  DCClear(dc);
  if(GrPutChar(dc,-2,-1,'A')==1 && GTMatches(dc,-2,-1))mask|=2;
  DCClear(dc);
  if(GrPrint(dc,1,2,"%c%c",'A','B')==2 && GTMatches(dc,1,2,9,2))mask|=4;
  DCClear(dc);
  if(GrPrint(dc,0,0,"%s","A\nB\tA")==3 && GTMatches(dc,0,0,0,8,64,8))mask|=8;
  DCClear(dc);
  if(GrVPrint(dc,2,1,"%s","AB")==2 && GTMatches(dc,2,1,2,9))mask|=16;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=4;dc->z=5;
  if(GrPrint3(dc,1,1,2,"%s","AB")==2 && GTMatches(dc,4,5,12,5) &&
     dc->flags==DCF_TRANSFORMATION && dc->color==RED)mask|=32;
  dc->flags=0;dc->x=dc->y=dc->z=0;
  I64 gx,gy;Bool clipping_ok=TRUE;
  for(gx=-7;gx<=80;gx++)if(gx<=7 || gx>=73)
    for(gy=-7;gy<=7;gy++) {
      DCClear(dc);GrPutChar(dc,gx,gy,'A');
      if(!GTMatches(dc,gx,gy))clipping_ok=FALSE;
    }
  if(clipping_ok)mask|=64;
  text.font=saved_font;SetRFlags(flags);Free(font);DCDel(dc);return mask;
}
