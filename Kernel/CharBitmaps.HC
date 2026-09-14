//These bitmaps go to 0-511 so that $LK,"Lex",A="MN:Lex"$() can use them with $LK,"Token Codes",A="MN:TK_EOF"$.
U32
  char_bmp_alpha[16]=
  {0x0000000,0x00000000,0x87FFFFFF,0x07FFFFFE,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_alpha_numeric[16]=
  {0x0000000,0x03FF0000,0x87FFFFFF,0x07FFFFFE,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_alpha_numeric_no_at[16]=
  {0x0000000,0x03FF0000,0x87FFFFFE,0x07FFFFFE,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_word[16]=
  {0x0000000,0x03FF0080,0x87FFFFFE,0x07FFFFFE,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_filename[16]=
  {0x0000000,0x03FF73FB,0xEFFFFFFF,0x6FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_dec_numeric[16]=
  {0x0000000,0x03FF0000,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_hex_numeric[16]=
  {0x0000000,0x03FF0000,0x7E,0x7E,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_white_space[16]=
  {0x80002600,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_non_eol_white_space[16]=
  {0x80000200,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_zero_cr_nl_cursor[16]=
  {0x00002421,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_zero_tab_cr_nl_cursor[16]=
  {0x00002621,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_zero_tab_cr_nl_cursor_dollar[16]=
  {0x00002621,0x10,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  char_bmp_macro[16]=
  {0x80002600,0xFFFFFFDF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_printable[16]=
  {0x80002600,0xFFFFFFFF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_displayable[16]=
  {0x80000000,0xFFFFFFFF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},

  char_bmp_safe_dollar[16]=
  {0x80000000,0xFFFFFFEF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0},//same but no dollar sign

  char_bmp_non_eol[16]=
  {0xFFFFDBFE,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF};
