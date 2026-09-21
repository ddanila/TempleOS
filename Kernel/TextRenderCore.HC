//Text-layer composition corresponding to GrUpdateTextBG/FG on a packed 8-bit surface.
I64 TextRenderAttr(I64 cell,Bool blink)
{
  I64 attr=(cell>>8)&255;
  if(cell&ATTRF_SEL) attr^=255;
  if(cell&ATTRF_INVERT) attr=((attr<<4)|(attr>>4))&255;
  if(cell&ATTRF_BLINK && blink) attr=((attr<<4)|(attr>>4))&255;
  return attr;
}
U0 TextRenderCore(U8 *pixels,U32 *cells,U8 *font,I64 cols,I64 rows,
  Bool blink,I64 pan_x,I64 pan_y,Bool hide_col,Bool hide_row)
{
  I64 width=cols*8,height=rows*8,ncols=cols,nrows=rows,sx=0,sy=0,dx=0,dy=0;
  I64 row,col,x,y,pos,base,end=width*height-7*width-8,cell,attr,packed,ox,oy;
  U8 glyph;
  if(pan_x>7) pan_x=7; if(pan_x< -7) pan_x=-7;
  if(pan_y>7) pan_y=7; if(pan_y< -7) pan_y=-7;
  if(pan_x || hide_col) { ncols--; dx=pan_x; if(pan_x<0) { sx=1; dx+=8; } }
  if(pan_y || hide_row) { nrows--; dy=pan_y; if(pan_y<0) { sy=1; dy+=8; } }
  for(pos=0;pos<width*height;pos++) pixels[pos]=0;
  //All backgrounds precede all foregrounds, so shifted glyphs can overlap cells.
  for(row=0;row<nrows;row++) for(col=0;col<ncols;col++) {
    cell=cells[(row+sy)*cols+col+sx]; attr=TextRenderAttr(cell,blink)>>4;
    base=(row*8+dy)*width+col*8+dx;
    for(y=0;y<8;y++) for(x=0;x<8;x++) pixels[base+y*width+x]=attr;
  }
  for(row=0;row<nrows;row++) for(col=0;col<ncols;col++) {
    cell=cells[(row+sy)*cols+col+sx]; attr=TextRenderAttr(cell,blink)&15;
    base=(row+sy)*8*width+(col+sx)*8;
    packed=cell.u16[1]&0x3FF+pan_x+pan_y<<5;
    if(packed) {
      ox=packed&31; if(ox&16) ox|=~31;
      oy=packed>>5; if(oy&16) oy|=~31;
      base+=oy*width+ox;
      //Preserve the original strict bound for shifted glyphs.
      if(base<0 || base>=end) goto next_cell;
    }
    for(y=0;y<8;y++) {
      glyph=font[(cell&255)*8+y];
      if(y==7 && cell&ATTRF_UNDERLINE) glyph=255;
      for(x=0;x<8;x++) if(glyph&(1<<x)) pixels[base+y*width+x]=attr;
    }
next_cell:
  }
}
