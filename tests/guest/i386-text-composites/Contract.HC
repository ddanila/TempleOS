Bool TCBox(CDC *dc,I64 left,I64 top,I64 right,I64 bottom)
{
  I64 x,y;Bool edge;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    edge=(left<=x<=right && (y==top || y==bottom)) || (top<=y<=bottom && (x==left || x==right));
    if((GrPeek0(dc,x,y)==RED)!=edge)return FALSE;
  }
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(96,48);U8 *font=CAlloc(2048);U64 *saved_font=text.font;
  I64 flags=GetRFlags,mask=0,before;
  SetRFlags(flags&~0x200);text.font=font;dc->color=RED;
  if(!GrTextBox3(dc,10,10,0,NULL) && !GrTextDiamond3(dc,48,24,0,NULL) && TCBox(dc,-10,-10,-10,-10))mask|=1;
  if(GrTextBox3(dc,10,10,0,"") && TCBox(dc,8,8,12,20))mask|=2;
  DCClear(dc);
  if(GrTextBox3(dc,10,10,0,"AB\nC") && TCBox(dc,8,8,28,28))mask|=4;
  DCClear(dc);
  if(GrTextBox3(dc,10,10,0,"A\tB") && TCBox(dc,8,8,84,20))mask|=8;
  DCClear(dc);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=4;dc->z=5;
  if(GrTextBox3(dc,10,10,0,"AB") && TCBox(dc,11,12,31,24) && dc->flags==DCF_TRANSFORMATION && dc->color==RED)mask|=16;
  DCClear(dc);dc->flags=0;dc->x=dc->y=dc->z=0;before=Fs->data_heap->used_u8s;
  if(GrTextDiamond3(dc,48,24,0,"") && GrPeek0(dc,48,10)==RED && GrPeek0(dc,58,24)==RED && GrPeek0(dc,48,38)==RED && GrPeek0(dc,38,24)==RED && GrPeek0(dc,48,24)==BLACK && Fs->data_heap->used_u8s==before)mask|=32;
  text.font=saved_font;SetRFlags(flags);Free(font);DCDel(dc);return mask;
}
