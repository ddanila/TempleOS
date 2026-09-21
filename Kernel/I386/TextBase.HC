#include "/Kernel/TextGlobalsTypes.HH"
#include "/Kernel/FontCyrillic.HC"
public CTextGlbls text;
#define TEXT_COLS 80
#define TEXT_ROWS 60
#include "/Kernel/TextBaseCore.HC"
//Native hardware text-base staging surface; presentation integration is separate.
U32 i386_text_storage[4802];
U32 *i386_text_base;
U0 NativeTextBaseInit()
{
  text.cols=TEXT_COLS; text.rows=TEXT_ROWS;
  text.font=sys_font_std; text.aux_font=sys_font_cyrillic;
  text.vga_alias=0xA0000; text.vga_text_alias=0xB8000;
  text.border_chars[2](I64)=0x0908070605040302;
  text.border_chars[10](U32)=0x0D0C0B0A;
  i386_text_base=i386_text_storage+1;
  i386_text_storage[0]=0xAB1234CD;
  i386_text_storage[4801]=0xEF567890;
}
Bool TextChar(CTask *task,Bool border=FALSE,I64 x,I64 y,I64 value)
{ return TextBaseCharCore(gr.text_base,80,60,task,border,x,y,value); }
Bool TextLenStr(CTask *task,I64 x,I64 y,I64 length,I64 attr,U8 *str)
{ return TextBaseStrCore(gr.text_base,80,60,task,x,y,length,attr,str); }
Bool TextLenAttrStr(CTask *task,I64 x,I64 y,I64 length,U32 *attrs)
{ return TextBaseAttrStrCore(gr.text_base,80,60,task,x,y,length,attrs); }
Bool TextLenAttr(CTask *task,I64 x,I64 y,I64 length,I64 attr)
{ return TextBaseAttrCore(gr.text_base,80,60,task,x,y,length,attr); }
