#ifndef TEXT_GLOBALS_TYPES_INCLUDED
#define TEXT_GLOBALS_TYPES_INCLUDED
#help_index "Char;Debugging/Raw Output;TextBase Layer/Char"
//text.raw_flags
#define RWF_IN_DOLLAR	1
#define RWF_LAST_DOLLAR	2
#define RWF_SHOW_DOLLAR	4
#define RWF_SCROLL	8

public class CTextGlbls
{
  I64	raw_col,raw_flags;
  U8	*raw_scrn_image;
  I64	rows,cols;		//Use TEXT_ROWS,TEXT_COLS
  U64	*font,*aux_font;
  U8	*vga_alias,*vga_text_alias;
  U8	border_chars[16];
};

#define FONT_WIDTH	8
#define FONT_HEIGHT	8

#endif
