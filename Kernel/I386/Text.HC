#include "/Kernel/I386/Text.HH"
//One task owns the initialized text record and writable 153600-byte planar buffer.
//Font is 256 little-endian 8x8 glyphs in TempleOS's low-bit-left format.
public Bool I386TextInit(CI386Text *text,U8 *planes,U8 *font,
  I64 foreground=0,I64 background=15)
{
  I64 plane,i;
  U8 fill;
  if(!text || !planes || !font || foreground<0 || foreground>15 ||
      background<0 || background>15 || (planes+0)(U64)>0x100000000-153600 ||
      (font+0)(U64)>0x100000000-2048) return FALSE;
  text->planes=planes; text->font=font;
  text->column=0; text->row=0;
  text->foreground=foreground; text->background=background;
  for(plane=0;plane<4;plane++) {
    fill=0; if(background&(1<<plane)) fill=255;
    for(i=0;i<38400;i++) planes[plane*38400+i]=fill;
  }
  return TRUE;
}
U0 I386TextCell(CI386Text *text,U8 ch)
{
  I64 plane,y;
  U8 glyph,value;
  for(plane=0;plane<4;plane++)
    for(y=0;y<8;y++) {
      glyph=text->font[ch*8+y]; value=0;
      if(text->foreground&(1<<plane)) value=glyph;
      if(text->background&(1<<plane)) value|=~glyph;
      text->planes[plane*38400+(text->row*8+y)*80+text->column]=value;
    }
}
U0 I386TextNewLine(CI386Text *text)
{
  I64 plane,i;
  U8 *buffer,fill;
  text->column=0;
  if(++text->row<60) return;
  text->row=59;
  for(plane=0;plane<4;plane++) {
    buffer=text->planes+plane*38400;
    for(i=0;i<37760;i++) buffer[i]=buffer[i+640];
    fill=0; if(text->background&(1<<plane)) fill=255;
    for(i=37760;i<38400;i++) buffer[i]=fill;
  }
}
public U0 I386TextPut(CI386Text *text,U8 ch)
{//Initialized record required. Backspace erases one cell, including across wrapping.
  I64 count;
  if(ch==10) I386TextNewLine(text);
  else if(ch==13) text->column=0;
  else if(ch==8) {
    if(text->column) text->column--;
    else if(text->row) { text->row--; text->column=79; }
    else return;
    I386TextCell(text,32);
  } else if(ch==9) {
    count=8-text->column%8;
    while(count--) I386TextPut(text,32);
  } else if(ch>=32) {
    I386TextCell(text,ch);
    if(++text->column==80) I386TextNewLine(text);
  }
}
public U0 I386TextWrite(CI386Text *text,U8 *string)
{
  while(*string) I386TextPut(text,*string++);
}
