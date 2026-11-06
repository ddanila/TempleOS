U8 wb_bits[64];
U0 BitTablesCheck()
{
  MemCpy(wb_bits,char_bmp_word,sizeof(wb_bits));
  U8 *s=MStrPrint("EXPORT word.bin %X 40\nBIT TABLES DONE\n",wb_bits);
  U8 *p=s;while(*p)OutU8(0xE9,*p++);Free(s);
}
