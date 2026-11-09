#ifndef I386_TEXT_INCLUDED
#define I386_TEXT_INCLUDED
class CI386Text
{
  U8 *planes,*font;
  U32 column,row,foreground,background,underline;
  U32 dirty_first,dirty_last; //Text rows, exclusive end; empty is 60,0.
  //Optional compact projection for document terminals before raster materialization.
  U8 *cells; //4800 packed nine-byte glyph/attribute cells.
};
public extern Bool I386TextInit(CI386Text *text,U8 *planes,U8 *font,
  I64 foreground=0,I64 background=15);
public extern Bool I386TextCellsInit(CI386Text *text,U8 *cells,U8 *font,
  I64 foreground=0,I64 background=15);
public extern Bool I386TextMaterialize(CI386Text *text,U8 *planes);
public extern U0 I386TextPut(CI386Text *text,U8 ch);
public extern U0 I386TextWrite(CI386Text *text,U8 *string);
#endif
