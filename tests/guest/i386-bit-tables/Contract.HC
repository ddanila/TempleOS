U8 bt_reverse[256],bt_count[256];
U0 BitTablesCheck()
{
  I64 i;
  for(i=0;i<256;i++) {
    bt_reverse[i]=rev_bits_table[i];
    bt_count[i]=set_bits_table[i];
  }
  "BIT TABLES READY\n";
  U8 *s=MStrPrint("EXPORT reverse.bin %X 100\nEXPORT count.bin %X 100\nBIT TABLES DONE\n",bt_reverse,bt_count);
  U8 *p=s;while(*p)OutU8(0xE9,*p++);Free(s);
}
