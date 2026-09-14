Bool BitmapTestBit(U32 *table,I64 ch) { return (table[ch>>5]>>(ch&31))&1; }
// Golden FNV32 captured from the original StrA bitmap bytes before extraction.
I64 CharBitmapsTest()
{
  U32 *tables[17];
  U8 *bytes;
  U32 hash=2166136261;
  I64 i,j,ch;
  tables[0]=char_bmp_alpha;
  tables[1]=char_bmp_alpha_numeric;
  tables[2]=char_bmp_alpha_numeric_no_at;
  tables[3]=char_bmp_word;
  tables[4]=char_bmp_filename;
  tables[5]=char_bmp_dec_numeric;
  tables[6]=char_bmp_hex_numeric;
  tables[7]=char_bmp_white_space;
  tables[8]=char_bmp_non_eol_white_space;
  tables[9]=char_bmp_zero_cr_nl_cursor;
  tables[10]=char_bmp_zero_tab_cr_nl_cursor;
  tables[11]=char_bmp_zero_tab_cr_nl_cursor_dollar;
  tables[12]=char_bmp_macro;
  tables[13]=char_bmp_printable;
  tables[14]=char_bmp_displayable;
  tables[15]=char_bmp_safe_dollar;
  tables[16]=char_bmp_non_eol;
  for(i=0;i<17;i++) {
    bytes=tables[i];
    for(j=0;j<64;j++) hash=((hash^bytes[j])*16777619)&0xFFFFFFFF;
  }
  if(hash!=0x778A63C3) return 79;
  for(ch=0;ch<512;ch++) {
    if(BitmapTestBit(char_bmp_dec_numeric,ch)!=(ch>='0' && ch<='9')) return 80;
    if(BitmapTestBit(char_bmp_hex_numeric,ch)!=((ch>='0' && ch<='9') ||
        (ch>='A' && ch<='F') || (ch>='a' && ch<='f'))) return 81;
    if(ch>=256) {
      for(i=0;i<16;i++) if(BitmapTestBit(tables[i],ch)) return 82;
      if(!BitmapTestBit(char_bmp_non_eol,ch)) return 83;
    }
  }
  if(!BitmapTestBit(char_bmp_alpha_numeric,'@') || BitmapTestBit(char_bmp_alpha_numeric_no_at,'@') ||
      !BitmapTestBit(char_bmp_alpha,128) || !BitmapTestBit(char_bmp_alpha,255)) return 84;
  return 0;
}
